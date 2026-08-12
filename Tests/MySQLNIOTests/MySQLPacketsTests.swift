import NIOCore
import OrderedCollections
import Testing

@testable import MySQLNIO

@Suite("MySQL Packets Tests")
struct MySQLPacketsTests {
    @Suite("Connection Phase Packets")
    struct ConnectionPhasePackets {
        let transcoder = MySQLRawPacketCodec()

        @Test("Initial Handshake Packet")
        func initialHandshakePacket() throws {
            let packet = InitialHandshakePacket(
                protocolVersion: 10,
                serverVersion: "5.7.31",
                connectionID: 12345,
                serverCapabilities: [.clientProtocol41, .secureConnection, .pluginAuth],
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
            var buffer = ByteBuffer()
            packet.write(to: &buffer)
            let decodedPacket = try #require(InitialHandshakePacket(from: &buffer))
            #expect(decodedPacket == packet)
        }

        @Test("Handshake Response Packet")
        func handshakeResponsePacket() throws {
            let buffer = ByteBuffer(
                bytes: [
                    0xb2, 0x00, 0x00, 0x00, 0x85, 0xa2, 0x1e, 0x00, 0x00, 0x00, 0x00, 0x40, 0x08, 0x00, 0x00, 0x00,
                    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                    0x00, 0x00, 0x00, 0x00, 0x72, 0x6f, 0x6f, 0x74, 0x00, 0x14, 0x22, 0x50, 0x79, 0xa2, 0x12, 0xd4,
                    0xe8, 0x82, 0xe5, 0xb3, 0xf4, 0x1a, 0x97, 0x75, 0x6b, 0xc8, 0xbe, 0xdb, 0x9f, 0x80, 0x6d, 0x79,
                    0x73, 0x71, 0x6c, 0x5f, 0x6e, 0x61, 0x74, 0x69, 0x76, 0x65, 0x5f, 0x70, 0x61, 0x73, 0x73, 0x77,
                    0x6f, 0x72, 0x64, 0x00, 0x61, 0x03, 0x5f, 0x6f, 0x73, 0x09, 0x64, 0x65, 0x62, 0x69, 0x61, 0x6e,
                    0x36, 0x2e, 0x30, 0x0c, 0x5f, 0x63, 0x6c, 0x69, 0x65, 0x6e, 0x74, 0x5f, 0x6e, 0x61, 0x6d, 0x65,
                    0x08, 0x6c, 0x69, 0x62, 0x6d, 0x79, 0x73, 0x71, 0x6c, 0x04, 0x5f, 0x70, 0x69, 0x64, 0x05, 0x32,
                    0x32, 0x33, 0x34, 0x34, 0x0f, 0x5f, 0x63, 0x6c, 0x69, 0x65, 0x6e, 0x74, 0x5f, 0x76, 0x65, 0x72,
                    0x73, 0x69, 0x6f, 0x6e, 0x08, 0x35, 0x2e, 0x36, 0x2e, 0x36, 0x2d, 0x6d, 0x39, 0x09, 0x5f, 0x70,
                    0x6c, 0x61, 0x74, 0x66, 0x6f, 0x72, 0x6d, 0x06, 0x78, 0x38, 0x36, 0x5f, 0x36, 0x34, 0x03, 0x66,
                    0x6f, 0x6f, 0x03, 0x62, 0x61, 0x72,
                ]
            )

            let capabilities: MySQLCapabilities = [
                .clientProtocol41,
                .pluginAuth,
                .secureConnection,
                .connectAttrs,
                .clientMySQL,
                .longFlag,
                .localFiles,
                .transactions,
                .multiResults,
                .psMultiResults,
            ]

            let handshakeResponse = HandshakeResponsePacket(
                clientCapabilities: capabilities,
                maxPacketSize: 0x4000_0000,
                clientDefaultCharacterSetAndCollation: .init(name: "latin1_swedish_ci", characterSetName: "latin1", id: 8),
                username: "root",
                authResponse: .init(
                    bytes: [0x22, 0x50, 0x79, 0xa2, 0x12, 0xd4, 0xe8, 0x82, 0xe5, 0xb3, 0xf4, 0x1a, 0x97, 0x75, 0x6b, 0xc8, 0xbe, 0xdb, 0x9f, 0x80]
                ),
                defaultDatabaseName: nil,
                authenticationPluginName: "mysql_native_password",
                connectionAttributes: [
                    "_os": "debian6.0",
                    "_client_name": "libmysql",
                    "_pid": "22344",
                    "_client_version": "5.6.6-m9",
                    "_platform": "x86_64",
                    "foo": "bar",
                ],
                zstdCompressionLevel: nil
            )
            var packet = ByteBuffer(bytes: [UInt8](repeating: 0x00, count: 4))
            handshakeResponse.write(
                to: &packet,
                capabilities: capabilities,
                password: true
            )

            var encodedPacket = ByteBuffer()
            self.transcoder.encode(data: packet, out: &encodedPacket)
            #expect(encodedPacket == buffer)

            var copy = buffer
            // Skip packet header
            copy.moveReaderIndex(forwardBy: 4)
            let decodedHandshakeResponse = try #require(
                HandshakeResponsePacket(
                    from: &copy,
                    serverCapabilities: capabilities,
                    password: true
                )
            )
            #expect(decodedHandshakeResponse == handshakeResponse)
        }
    }

    @Suite("Generic Response Packets")
    struct GenericResponsePackets {
        let transcoder = MySQLRawPacketCodec()

        @Test("EOF_Packet")
        func eofPacket() throws {
            var buffer = ByteBuffer(bytes: [0x05, 0x00, 0x00, 0x00, 0xfe, 0x00, 0x00, 0x02, 0x00])

            var packet = try #require(try self.transcoder.decode(buffer: &buffer))
            #expect(packet.readableBytes == 0x05)

            let eofPacket = try #require(EOFPacket(from: &packet))
            #expect(eofPacket.warningCount == 0)
            #expect(eofPacket.serverStatus == [.serverStatusAutocommit])
        }

        @Test("ERR_Packet")
        func errorPacket() throws {
            var buffer = ByteBuffer(
                bytes: [
                    0x17, 0x00, 0x00, 0x00, 0xff, 0x48, 0x04, 0x23, 0x48, 0x59, 0x30, 0x30, 0x30, 0x4e, 0x6f, 0x20,
                    0x74, 0x61, 0x62, 0x6c, 0x65, 0x73, 0x20, 0x75, 0x73, 0x65, 0x64,
                ]
            )

            var packet = try #require(try self.transcoder.decode(buffer: &buffer))
            #expect(packet.readableBytes == 0x17)

            let errorPacket = try #require(ErrorPacket(from: &packet))
            guard case .error(let error) = errorPacket.kind else {
                Issue.record("Expected error packet")
                return
            }
            #expect(error.sqlState == "HY000")
            #expect(error.errorMessage == "No tables used")

            // TODO: progress reporting
        }

        @Test("LOCAL_INFILE_Packet")
        func localInfilePacket() throws {
            var buffer = ByteBuffer(bytes: [0x09, 0x00, 0x00, 0x00, 0xfb, 0x74, 0x65, 0x73, 0x74, 0x2e, 0x74, 0x78, 0x74])

            var packet = try #require(try self.transcoder.decode(buffer: &buffer))
            #expect(packet.readableBytes == 0x09)

            let localInfilePacket = try #require(LocalInfilePacket(from: &packet))
            #expect(localInfilePacket.fileName == "test.txt")
        }

        @Test("OK_Packet")
        func okPacket() throws {
            let buffer = ByteBuffer(bytes: [0x07, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00])

            var decodingBuffer = buffer
            var packet = try #require(try self.transcoder.decode(buffer: &decodingBuffer))
            #expect(packet.readableBytes == 0x07)

            let okPacket = try OKPacket(from: &packet, capabilities: [.clientProtocol41])
            #expect(okPacket.affectedRows == 0)
            #expect(okPacket.lastInsertID == 0)
            #expect(okPacket.serverStatus == [.serverStatusAutocommit])
            #expect(okPacket.warningCount == 0)

            var encodingPacket = ByteBuffer(bytes: [0x07, 0x00, 0x00, 0x00])
            okPacket.write(to: &encodingPacket, capabilities: [.clientProtocol41])
            #expect(encodingPacket == buffer)
        }
    }
}

extension InitialHandshakePacket: Equatable {
    static func == (lhs: InitialHandshakePacket, rhs: InitialHandshakePacket) -> Bool {
        lhs.protocolVersion == rhs.protocolVersion && lhs.serverVersion == rhs.serverVersion && lhs.connectionID == rhs.connectionID
            && lhs.serverCapabilities == rhs.serverCapabilities && lhs.serverDefaultCollation == rhs.serverDefaultCollation
            && lhs.statusFlags == rhs.statusFlags && lhs.pluginDataLength == rhs.pluginDataLength
            && lhs.authenticationPluginData == rhs.authenticationPluginData && lhs.authenticationPluginName == rhs.authenticationPluginName
    }
}

extension HandshakeResponsePacket: Equatable {
    static func == (lhs: HandshakeResponsePacket, rhs: HandshakeResponsePacket) -> Bool {
        lhs.clientCapabilities == rhs.clientCapabilities && lhs.maxPacketSize == rhs.maxPacketSize
            && lhs.clientDefaultCharacterSetAndCollation == rhs.clientDefaultCharacterSetAndCollation && lhs.username == rhs.username
            && lhs.authResponse == rhs.authResponse && lhs.defaultDatabaseName == rhs.defaultDatabaseName
            && lhs.authenticationPluginName == rhs.authenticationPluginName && lhs.connectionAttributes == rhs.connectionAttributes
            && lhs.zstdCompressionLevel == rhs.zstdCompressionLevel
    }
}
