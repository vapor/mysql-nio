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
}
