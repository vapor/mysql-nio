import Logging
import NIOCore
import NIOEmbedded
import NIOPosix
import OrderedCollections
import Testing

@testable import MySQLNIO

@Suite("MySQLConnection Tests")
struct MySQLConnectionTests {
    @Test("Ping")
    func ping() async throws {
        try await withTestMySQLServer { connection in
            try await connection.ping()
        } server: { channel in
            try await channel.processPing()
        }
    }

    @Test("Query")
    func query() async throws {
        try await withTestMySQLServer { connection in
            try await connection.query("test") { rows in
                var iterator = rows.makeAsyncIterator()

                let firstRow = try #require(await iterator.next())
                #expect(firstRow.columns.count == 1)
                #expect(String(buffer: try #require(firstRow.first?.bytes)) == "row1")

                let secondRow = try #require(await iterator.next())
                #expect(secondRow.columns.count == 1)
                #expect(String(buffer: try #require(secondRow.first?.bytes)) == "row2")

                let thirdRow = try #require(await iterator.next())
                #expect(thirdRow.columns.count == 1)
                #expect(String(buffer: try #require(thirdRow.first?.bytes)) == "row3")
            }
        } server: { channel in
            try await channel.processQuery(
                "test",
                columns: [
                    .init(
                        schema: "schema",
                        table: "table",
                        orgTable: "orgTable",
                        name: "name",
                        orgName: "orgName",
                        extendedMetadata: nil,
                        characterSet: .utf8Unicode14AICI,
                        columnLength: 255,
                        dataType: .varchar,
                        flags: 0,
                        decimals: 0,
                        format: .text
                    )
                ],
                rows: ["row1", "row2", "row3"]
            )
        }
    }

    @Test("Row Error")
    func rowError() async throws {
        try await withTestMySQLServer { connection in
            try await connection.query("test") { rows in
                var iterator = rows.makeAsyncIterator()

                let firstRow = try #require(await iterator.next())
                #expect(firstRow.columns.count == 1)
                #expect(String(buffer: try #require(firstRow.first?.bytes)) == "row1")

                await #expect(throws: MySQLClientError.errorPacket(errorCode: 21, errorMessage: "test")) {
                    try await iterator.next()
                }
            }
        } server: { channel in
            let queryPacket = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
            #expect(queryPacket.getBytes(at: queryPacket.readerIndex + 4, length: 1) == [0x03])  // COM_QUERY command
            let queryString = queryPacket.getString(at: queryPacket.readerIndex + 5, length: queryPacket.readableBytes - 5)
            #expect(queryString == "test")
            let resultsetMetadataPacket = NIOAsyncTestingChannel.makeMySQLPacket(sequenceID: 1) { buffer in
                buffer.writeEncodedInteger(1, strategy: .mySQL)  // column count
                // TODO: Fix crash when there is no column definitions (i.e. when `metadata_follows = 0`)
                buffer.writeInteger(1, as: UInt8.self)  // metadata follows
            }
            try await channel.writeInbound(resultsetMetadataPacket)
            let columnDefinitionPacket = NIOAsyncTestingChannel.makeMySQLPacket(sequenceID: 2) { buffer in
                let columnDefinition = ColumnDefinition(
                    schema: "schema",
                    table: "table",
                    orgTable: "orgTable",
                    name: "name",
                    orgName: "orgName",
                    extendedMetadata: nil,
                    characterSet: .utf8Unicode14AICI,
                    columnLength: 255,
                    dataType: .varchar,
                    flags: 0,
                    decimals: 0,
                    format: .text
                )
                columnDefinition.write(to: &buffer, capabilities: .baselineClientCapabilities)
            }
            try await channel.writeInbound(columnDefinitionPacket)
            let row1Packet = NIOAsyncTestingChannel.makeMySQLPacket(sequenceID: 3) { buffer in
                buffer.writeLengthPrefixedString("row1", strategy: .mySQL)
            }
            try await channel.writeInbound(row1Packet)

            let errorPacket = ErrorPacket(errorCode: 21, kind: .error(.init(sqlState: nil, errorMessage: "test")))
            let errorPacketBuffer = NIOAsyncTestingChannel.makeMySQLPacket(sequenceID: 4) { buffer in
                errorPacket.write(to: &buffer)
            }
            try await channel.writeInbound(errorPacketBuffer)
        }
    }

    @Test("Graceful Shutdown")
    func gracefulShutdown() async throws {
        let (receivedStream, receivedContinuation) = AsyncStream<Void>.makeStream()
        let (shutdownStream, shutdownContinuation) = AsyncStream<Void>.makeStream()
        try await withTestMySQLServer { connection in
            async let response = connection.statistics()
            await receivedStream.first { _ in true }
            await connection.triggerGracefulShutdown()
            shutdownContinuation.yield()
            try await #expect(response == "Test")
        } server: { channel in
            let statisticsCommandPacket = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
            #expect(statisticsCommandPacket == ByteBuffer(bytes: [0x01, 0x00, 0x00, 0x00, 0x09]))

            receivedContinuation.yield()
            await shutdownStream.first { _ in true }
            #expect(channel.isActive)

            let response = NIOAsyncTestingChannel.makeMySQLPacket(sequenceID: 1) {
                $0.writeString("Test")
            }
            try await channel.writeInbound(response)

            #expect(!channel.isActive)

            try await channel.closeFuture.get()
        }
    }

    @Test("Graceful Shutdown during Handshake")
    func gracefulShutdownDuringHandshake() async throws {
        let channel = NIOAsyncTestingChannel()
        let logger = Logger(label: #function).withLogLevel(.trace)
        let configuration = MySQLConnectionConfiguration(username: "test_username")
        let connection = try await MySQLConnection.setupChannelAndConnect(channel, configuration: configuration, logger: logger)

        await connection.triggerGracefulShutdown()
        #expect(channel.isActive)

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
        let initialHandshakeBuffer = NIOAsyncTestingChannel.makeMySQLPacket(sequenceID: 0) {
            initialHandshakePacket.write(to: &$0)
        }
        try await channel.writeInbound(initialHandshakeBuffer)

        #expect(channel.isActive)

        let responseBuffer = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
        let expectedBuffer = NIOAsyncTestingChannel.makeMySQLPacket(sequenceID: 1) {
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

        #expect(channel.isActive)

        let okPacket = OKPacket(
            affectedRows: 0,
            lastInsertID: 0,
            serverStatus: [],
            warningCount: 0,
            info: "",
            newSchema: nil,
            updatedSettings: [:],
            generalStateChange: false
        )
        let okPacketBuffer = NIOAsyncTestingChannel.makeMySQLPacket(sequenceID: 2) {
            okPacket.write(to: &$0, capabilities: .baselineClientCapabilities)
        }
        try await channel.writeInbound(okPacketBuffer)

        #expect(!channel.isActive)

        // The connection was already closed by the graceful shutdown, so this is a no-op and no COM_QUIT is sent.
        connection.close()

        try await channel.closeFuture.get()
    }

    @Test("Graceful Shutdown during Query")
    func gracefulShutdownDuringQuery() async throws {
        try await withTestMySQLServer { connection in
            try await connection.query("test") { rows in
                var iterator = rows.makeAsyncIterator()

                let firstRow = try #require(await iterator.next())
                #expect(firstRow.columns.count == 1)
                #expect(String(buffer: try #require(firstRow.first?.bytes)) == "row1")

                // Trigger graceful shutdown mid query, which will close the connection after the current command is completed
                await connection.triggerGracefulShutdown()

                let secondRow = try #require(await iterator.next())
                #expect(secondRow.columns.count == 1)
                #expect(String(buffer: try #require(secondRow.first?.bytes)) == "row2")
            }

            await #expect(throws: MySQLClientError.connectionClosed) {
                try await connection.ping()
            }
        } server: { channel in
            let queryPacket = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
            #expect(queryPacket.getBytes(at: queryPacket.readerIndex + 4, length: 1) == [0x03])  // COM_QUERY command
            let queryString = queryPacket.getString(at: queryPacket.readerIndex + 5, length: queryPacket.readableBytes - 5)
            #expect(queryString == "test")
            let resultsetMetadataPacket = NIOAsyncTestingChannel.makeMySQLPacket(sequenceID: 1) { buffer in
                buffer.writeEncodedInteger(1, strategy: .mySQL)  // column count
                // TODO: Fix crash when there is no column definitions (i.e. when `metadata_follows = 0`)
                buffer.writeInteger(1, as: UInt8.self)  // metadata follows
            }
            try await channel.writeInbound(resultsetMetadataPacket)
            let columnDefinitionPacket = NIOAsyncTestingChannel.makeMySQLPacket(sequenceID: 2) { buffer in
                let columnDefinition = ColumnDefinition(
                    schema: "schema",
                    table: "table",
                    orgTable: "orgTable",
                    name: "name",
                    orgName: "orgName",
                    extendedMetadata: nil,
                    characterSet: .utf8Unicode14AICI,
                    columnLength: 255,
                    dataType: .varchar,
                    flags: 0,
                    decimals: 0,
                    format: .text
                )
                columnDefinition.write(to: &buffer, capabilities: .baselineClientCapabilities)
            }
            try await channel.writeInbound(columnDefinitionPacket)
            let row1Packet = NIOAsyncTestingChannel.makeMySQLPacket(sequenceID: 3) { buffer in
                buffer.writeLengthPrefixedString("row1", strategy: .mySQL)
            }
            try await channel.writeInbound(row1Packet)

            #expect(channel.isActive)

            let row2Packet = NIOAsyncTestingChannel.makeMySQLPacket(sequenceID: 4) { buffer in
                buffer.writeLengthPrefixedString("row2", strategy: .mySQL)
            }
            try await channel.writeInbound(row2Packet)
            let okPacket = OKPacket(
                affectedRows: 0,
                lastInsertID: 0,
                serverStatus: [],
                warningCount: 0,
                info: "",
                newSchema: nil,
                updatedSettings: [:],
                generalStateChange: false
            )
            let okPacketBuffer = NIOAsyncTestingChannel.makeMySQLPacket(sequenceID: 5) { buffer in
                okPacket.write(to: &buffer, capabilities: .baselineClientCapabilities)
            }
            try await channel.writeInbound(okPacketBuffer)

            #expect(!channel.isActive)

            try await channel.closeFuture.get()
        }
    }

    @Test("Cancellation")
    func cancellation() async throws {
        let (stream, continuation) = AsyncStream<Void>.makeStream()
        try await withTestMySQLServer { connection in
            try await withThrowingTaskGroup { group in
                group.addTask {
                    await #expect(throws: MySQLClientError.cancelled) {
                        // This will be sent and become the active command
                        async let firstCommand = connection.ping()

                        try await Task.sleep(for: .milliseconds(50))

                        // No need to process this second command from the server, as it will be cancelled before it is sent
                        async let secondCommand = connection.ping()
                        _ = try await (firstCommand, secondCommand)
                    }
                }

                try await Task.sleep(for: .milliseconds(100))
                // This is put in the command queue before the cancellation,
                // but will not be cancelled and sent to the server after the first command is completed
                async let thirdCommand = connection.ping()

                // Wait until the server is in the middle of processing the command
                await stream.first { _ in true }
                group.cancelAll()

                // Even after cancellation, the server can still process the third command
                _ = try await thirdCommand

                // The connection is still active so we can send more commands after the cancellation
                await #expect(throws: Never.self) {
                    try await connection.ping()
                }
            }
        } server: { channel in
            // Wait for all three commands to be sent
            try await Task.sleep(for: .milliseconds(150))

            let pingCommandPacket = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
            #expect(pingCommandPacket == ByteBuffer(bytes: [0x01, 0x00, 0x00, 0x00, 0x0E]))

            // In the middle of processing the command, we cancel the task
            continuation.yield()

            // The server continues to process the command as it has no knowledge of the cancellation
            let okPacket = OKPacket(
                affectedRows: 0,
                lastInsertID: 0,
                serverStatus: [],
                warningCount: 0,
                info: "",
                newSchema: nil,
                updatedSettings: [:],
                generalStateChange: false
            )
            let okPacketBuffer = NIOAsyncTestingChannel.makeMySQLPacket(sequenceID: 1) { buffer in
                okPacket.write(to: &buffer, capabilities: .baselineClientCapabilities)
            }
            try await channel.writeInbound(okPacketBuffer)

            // Connection is still active
            #expect(channel.isActive)

            // This is the `thirdCommand` sent before the cancellation
            try await channel.processPing()

            // This is the command sent after everything
            try await channel.processPing()
        }
    }

    @Test("Query Cancellation")
    func queryCancellation() async throws {
        let (stream, continuation) = AsyncStream<Void>.makeStream()
        try await withTestMySQLServer { connection in
            try await withThrowingTaskGroup { group in
                group.addTask {
                    try await connection.query("test") { rows in
                        for try await row in rows {
                            #expect(row.columns.count == 1)
                            #expect(String(buffer: try #require(row.first?.bytes)) == "row1")
                        }
                    }
                }

                await stream.first { _ in true }
                group.cancelAll()

                try await group.waitForAll()

                try await connection.ping()  // Connection is still active after the cancellation
            }
        } server: { channel in
            let queryPacket = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
            #expect(queryPacket.getBytes(at: queryPacket.readerIndex + 4, length: 1) == [0x03])  // COM_QUERY command
            let queryString = queryPacket.getString(at: queryPacket.readerIndex + 5, length: queryPacket.readableBytes - 5)
            #expect(queryString == "test")
            let resultsetMetadataPacket = NIOAsyncTestingChannel.makeMySQLPacket(sequenceID: 1) { buffer in
                buffer.writeEncodedInteger(1, strategy: .mySQL)  // column count
                // TODO: Fix crash when there is no column definitions (i.e. when `metadata_follows = 0`)
                buffer.writeInteger(1, as: UInt8.self)  // metadata follows
            }
            try await channel.writeInbound(resultsetMetadataPacket)
            let columnDefinitionPacket = NIOAsyncTestingChannel.makeMySQLPacket(sequenceID: 2) { buffer in
                let columnDefinition = ColumnDefinition(
                    schema: "schema",
                    table: "table",
                    orgTable: "orgTable",
                    name: "name",
                    orgName: "orgName",
                    extendedMetadata: nil,
                    characterSet: .utf8Unicode14AICI,
                    columnLength: 255,
                    dataType: .varchar,
                    flags: 0,
                    decimals: 0,
                    format: .text
                )
                columnDefinition.write(to: &buffer, capabilities: .baselineClientCapabilities)
            }
            try await channel.writeInbound(columnDefinitionPacket)
            let row1Packet = NIOAsyncTestingChannel.makeMySQLPacket(sequenceID: 3) { buffer in
                buffer.writeLengthPrefixedString("row1", strategy: .mySQL)
            }
            try await channel.writeInbound(row1Packet)

            // Cancel the query task
            continuation.yield()
            try await Task.sleep(for: .milliseconds(100))

            // Send the second row anyway, the `MySQLRowSequence` will not return it
            let row2Packet = NIOAsyncTestingChannel.makeMySQLPacket(sequenceID: 4) { buffer in
                buffer.writeLengthPrefixedString("row2", strategy: .mySQL)
            }
            try await channel.writeInbound(row2Packet)
            let okPacket = OKPacket(
                affectedRows: 0,
                lastInsertID: 0,
                serverStatus: [],
                warningCount: 0,
                info: "",
                newSchema: nil,
                updatedSettings: [:],
                generalStateChange: false
            )
            let okPacketBuffer = NIOAsyncTestingChannel.makeMySQLPacket(sequenceID: 5) { buffer in
                okPacket.write(to: &buffer, capabilities: .baselineClientCapabilities)
            }
            try await channel.writeInbound(okPacketBuffer)

            // Connection is still active
            #expect(channel.isActive)

            try await channel.processPing()  // This is the command sent after everything
        }
    }
}
