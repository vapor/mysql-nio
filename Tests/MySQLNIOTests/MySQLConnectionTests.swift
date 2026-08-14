import Logging
import NIOCore
import NIOEmbedded
import NIOPosix
import Testing

@testable import MySQLNIO

@Suite("MySQLConnection Tests", .defaultLogger(logLevel: .trace))
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
            for (i, row) in ["row1", "row2", "row3"].enumerated() {
                let rowPacket = NIOAsyncTestingChannel.makeMySQLPacket(sequenceID: 3 + UInt8(i)) { buffer in
                    buffer.writeLengthPrefixedString(row, strategy: .mySQL)
                }
                try await channel.writeInbound(rowPacket)
            }
            let okPacket = OKPacket(
                affectedRows: 0,
                lastInsertID: 0,
                serverStatus: [],
                warningCount: 0,
                info: nil,
                sessionStateInfo: nil
            )
            let okPacketBuffer = NIOAsyncTestingChannel.makeMySQLPacket(sequenceID: 6) { buffer in
                okPacket.write(to: &buffer, capabilities: .baselineClientCapabilities)
            }
            try await channel.writeInbound(okPacketBuffer)
        }
    }
}
