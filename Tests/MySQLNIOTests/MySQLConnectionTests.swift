import Logging
import NIOCore
import NIOEmbedded
import NIOPosix
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
                try #expect(await iterator.next() == "row1")
                try #expect(await iterator.next() == "row2")
                try #expect(await iterator.next() == "row3")
            }
        } server: { channel in
            let queryPacket = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
            #expect(queryPacket.getBytes(at: queryPacket.readerIndex + 4, length: 1) == [0x03])  // COM_QUERY command
            let queryString = queryPacket.getString(at: queryPacket.readerIndex + 5, length: queryPacket.readableBytes - 5)
            #expect(queryString == "test")
            let resultsetMetadataPacket = NIOAsyncTestingChannel.makeMySQLPacket(sequenceID: 1) { buffer in
                buffer.writeInteger(0, as: UInt8.self)  // metadata doesn't follow
                buffer.writeInteger(0, as: UInt8.self)  // column count
            }
            try await channel.writeInbound(resultsetMetadataPacket)
            for (i, row) in ["row1", "row2", "row3"].enumerated() {
                let rowPacket = NIOAsyncTestingChannel.makeMySQLPacket(sequenceID: 2 + UInt8(i)) { buffer in
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
            let okPacketBuffer = NIOAsyncTestingChannel.makeMySQLPacket(sequenceID: 5) { buffer in
                okPacket.write(to: &buffer, capabilities: .baselineClientCapabilities)
            }
            try await channel.writeInbound(okPacketBuffer)
        }
    }
}
