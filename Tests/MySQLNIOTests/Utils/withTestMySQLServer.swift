import NIOCore
import NIOEmbedded
import Testing

@testable import MySQLNIO

/// Helper function to test a ``MySQLConnection`` with a test MySQL server using `NIOAsyncTestingChannel`.
///
/// This function sets up a test MySQL server and establishes a connection using the provided configuration.
/// It then performs the specified client and server operations concurrently, allowing for testing of various MySQL interactions.
///
/// - Parameters:
///   - configuration: The configuration to use for the MySQL connection.
///   - clientOperation: An async operation to perform for the client side of the test.
///         The ``MySQLConnection`` will be passed as a parameter to this operation.
///   - serverOperation: An async operation to perform for the server side of the test.
///         The test MySQL server channel will be passed as a parameter to this operation.
func withTestMySQLServer(
    configuration: MySQLConnectionConfiguration = .init(username: "test_username"),
    client clientOperation: @Sendable @escaping (MySQLConnection) async throws -> Void,
    server serverOperation: @Sendable @escaping (NIOAsyncTestingChannel) async throws -> Void
) async throws {
    let channel = NIOAsyncTestingChannel()
    let connection = try await MySQLConnection.setupChannelAndConnect(channel, configuration: configuration)
    try await channel.processHandshake(configuration: configuration)
    try await withThrowingTaskGroup { group in
        group.addTask {
            defer { connection.close() }
            try await clientOperation(connection)
        }
        group.addTask {
            try await serverOperation(channel)
            let quitPacket = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
            #expect(quitPacket == ByteBuffer(bytes: [0x01, 0x00, 0x00, 0x00, 0x01]))
        }
        try await group.waitForAll()
    }
}

extension NIOAsyncTestingChannel {
    /// Helper function to create a `ByteBuffer` formatted as a MySQL packet with the given sequence ID and payload.
    /// - Parameters:
    ///   - sequenceID: The sequence ID of the packet.
    ///   - writePayload: A closure that writes the payload to the provided `ByteBuffer`.
    /// - Returns: A `ByteBuffer` containing the MySQL packet.
    static func makeMySQLPacket(sequenceID: UInt8, writePayload: (inout ByteBuffer) -> Void) -> ByteBuffer {
        var buffer = ByteBuffer(bytes: [0x00, 0x00, 0x00, sequenceID])
        writePayload(&buffer)
        buffer.setInteger(UInt32(buffer.readableBytes - 4) | (UInt32(sequenceID) << 24), at: buffer.readerIndex, endianness: .little)
        return buffer
    }

    /// Processes the server-side MySQL handshake by sending an initial handshake packet to the client and validating the client's response.
    /// - Parameter configuration: The configuration to use for the MySQL connection.
    func processHandshake(configuration: MySQLConnectionConfiguration) async throws {
        let initialHandshakePacket = InitialHandshakePacket(
            protocolVersion: 10,
            serverVersion: "9.7.0",
            connectionID: 12345,
            serverCapabilities: .baselineClientCapabilities,
            serverDefaultCollation: 255,
            statusFlags: [.serverStatusAutocommit],
            pluginDataLength: 21,
            authenticationPluginData: ByteBuffer(
                bytes: [
                    0x01, 0x02, 0x03, 0x04, 0x05,
                    0x06, 0x07, 0x08, 0x09, 0x0A,
                    0x0B, 0x0C, 0x0D, 0x0E, 0x0F,
                    0x10, 0x11, 0x12, 0x13, 0x14,
                ]
            ),
            authenticationPluginName: "mysql_native_password"
        )
        let initialHandshakeBuffer = Self.makeMySQLPacket(sequenceID: 0) {
            initialHandshakePacket.write(to: &$0)
        }
        try await self.writeInbound(initialHandshakeBuffer)

        let responseBuffer = try await self.waitForOutboundWrite(as: ByteBuffer.self)
        let expectedBuffer = Self.makeMySQLPacket(sequenceID: 1) {
            let handshakeResponsePacket = HandshakeResponsePacket(
                clientCapabilities: .baselineClientCapabilities,
                maxPacketSize: .max,
                clientDefaultCharacterSetAndCollation: .bestCollation(
                    forVersion: "9.7.0",
                    capabilities: .baselineClientCapabilities
                ),
                username: configuration.username,
                authResponse: ByteBuffer(bytes: [
                    0x14, 0x22, 0x50, 0x79, 0xa2, 0x12, 0xd4, 0xe8, 0x82, 0xe5, 0xb3, 0xf4, 0x1a, 0x97, 0x75, 0x6b, 0xc8, 0xbe, 0xdb, 0x9f,
                ]),
                defaultDatabaseName: configuration.defaultDatabaseName,
                authenticationPluginName: "mysql_native_password",
                connectionAttributes: configuration.connectionAttributes,
                zstdCompressionLevel: nil
            )
            handshakeResponsePacket.write(to: &$0, capabilities: .baselineClientCapabilities, password: configuration.password != nil)
        }
        #expect(responseBuffer == expectedBuffer)

        let okPacket = OKPacket(
            affectedRows: 0,
            lastInsertID: 0,
            serverStatus: [],
            warningCount: 0,
            info: nil,
            sessionStateInfo: nil
        )
        let okPacketBuffer = Self.makeMySQLPacket(sequenceID: 2) {
            okPacket.write(to: &$0, capabilities: .baselineClientCapabilities)
        }
        try await self.writeInbound(okPacketBuffer)
    }

    /// Helper function to process a MySQL ping command from the client and respond with an OK packet.
    func processPing() async throws {
        let pingCommandPacket = try await self.waitForOutboundWrite(as: ByteBuffer.self)
        #expect(pingCommandPacket == ByteBuffer(bytes: [0x01, 0x00, 0x00, 0x00, 0x0e]))

        let okPacket = OKPacket(
            affectedRows: 0,
            lastInsertID: 0,
            serverStatus: [],
            warningCount: 0,
            info: nil,
            sessionStateInfo: nil
        )
        let okPacketBuffer = Self.makeMySQLPacket(sequenceID: 1) {
            okPacket.write(to: &$0, capabilities: .baselineClientCapabilities)
        }
        try await self.writeInbound(okPacketBuffer)
    }
}
