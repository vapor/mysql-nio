import Logging
@testable import MySQLNIO
import NIOCore
import NIOPosix
import Testing
import XCTest

extension MySQLError: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.secureConnectionRequired, .secureConnectionRequired): true
        case (.unsupportedAuthPlugin(let l), .unsupportedAuthPlugin(let r)) where l == r: true
        case (.authPluginDataError(let l), .authPluginDataError(let r)) where l == r: true
        case (.missingOrInvalidAuthMoreDataStatusTag, .missingOrInvalidAuthMoreDataStatusTag): true
        case (.missingOrInvalidAuthPluginInlineCommand(let l), .missingOrInvalidAuthPluginInlineCommand(let r)) where l == r: true
        case (.missingAuthPluginInlineData, .missingAuthPluginInlineData): true
        case (.unsupportedServer(let l), .unsupportedServer(let r)) where l == r: true
        case (.protocolError, .protocolError): true
        case (.server(let l), .server(let r)) where l.errorCode == r.errorCode && l.sqlStateMarker == r.sqlStateMarker && l.sqlState == r.sqlState && l.errorMessage == r.errorMessage: true
        case (.closed, .closed): true
        case (.duplicateEntry(let l), .duplicateEntry(let r)) where l == r: true
        case (.invalidSyntax(let l), .invalidSyntax(let r)) where l == r: true
        default: false
        }
    }
}

@Suite(.serialized)
struct MySQLNIOTests {
    init() {
        #expect(isLoggingConfigured)
    }
    
    @Test
    func decodingSumOfIntsWithNoRows() async throws {
        let conn = try await MySQLConnection.test()

        do {
            let dropResults = try await conn.simpleQuery("DROP TABLE IF EXISTS foos").get()
            #expect(dropResults.count == 0)
            let createResults = try await conn.simpleQuery("CREATE TABLE foos (`item_count` int(11))").get()
            #expect(createResults.count == 0)
            let rows = try await conn.simpleQuery("SELECT sum(`item_count`) as sum from foos").get()
            try #require(rows.count == 1)

            let sqlData = try #require(rows[0].column("sum"))

            #expect(sqlData.string == nil)
            #expect(sqlData.float == nil)
            #expect(sqlData.double == nil)
            #expect(sqlData.int == nil)
            #expect(sqlData.decimal == nil)

            _ = try await conn.simpleQuery("DROP TABLE IF EXISTS foos").get()
        } catch {
            _ = try? await conn.simpleQuery("DROP TABLE IF EXISTS foos").get()
            try? await conn.close().get()
            throw error
        }
        try await conn.close().get()
    }

    @Test
    func decodingSumOfIntsWithRows() async throws {
        let conn = try await MySQLConnection.test()

        do {
            #expect(try await conn.simpleQuery("DROP TABLE IF EXISTS foos").get().count == 0)
            #expect(try await conn.simpleQuery("CREATE TABLE foos (`item_count` int(11))").get().count == 0)
            _ = try await conn.simpleQuery("insert into foos (`item_count`) values (0)").get()
            let rows1 = try await conn.simpleQuery("SELECT sum(`item_count`) as sum from foos").get()
            try #require(rows1.count == 1)
            let sqlData1 = try #require(rows1[0].column("sum"))
            #expect(sqlData1.string == "0")
            #expect(sqlData1.float == 0)
            #expect(sqlData1.double == 0)
            #expect(sqlData1.int == 0)
            #expect(sqlData1.decimal == 0)
            _ = try await conn.simpleQuery("insert into foos (`item_count`) values (199)").get()
            let rows2 = try await conn.simpleQuery("SELECT sum(`item_count`) as sum from foos").get()
            try #require(rows2.count == 1)
            let sqlData2 = try #require(rows2[0].column("sum"))
            #expect(sqlData2.string == "199")
            #expect(sqlData2.float == 199)
            #expect(sqlData2.double == 199)
            #expect(sqlData2.int == 199)
            #expect(sqlData2.decimal == Decimal(string: "199"))
            _ = try await conn.simpleQuery("DROP TABLE IF EXISTS foos").get()
        } catch {
            _ = try? await conn.simpleQuery("DROP TABLE IF EXISTS foos").get()
            try? await conn.close().get()
            throw error
        }
        try await conn.close().get()
    }

    @Test
    func simpleQuery_selectVersion() async throws {
        let conn = try await MySQLConnection.test()

        do {
            let rows = try await conn.simpleQuery("SELECT @@version").get()
            try #require(rows.count == 1)
            #expect(rows[0].column("@@version")?.string?.contains(".") ?? false)
        } catch {
            try? await conn.close().get()
            throw error
        }
        try await conn.close().get()
    }

    @Test
    func queryWithExecuteColumnMismatchingPrepareColumnType() async throws {
        let conn = try await MySQLConnection.test()

        do {
            _ = try await conn.simpleQuery("DROP TABLE IF EXISTS `t1`").get()
            _ = try await conn.simpleQuery("DROP TABLE IF EXISTS `t2`").get()
            _ = try await conn.simpleQuery("""
                CREATE TABLE `t1` (
                  `id` int unsigned NOT NULL AUTO_INCREMENT,
                  `group_id` int DEFAULT NULL,
                  `text` varchar(150) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
                  PRIMARY KEY (`id`)
                ) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 /*!80000 COLLATE=utf8mb4_0900_ai_ci */
                """).get()
            _ = try await conn.simpleQuery("""
                CREATE TABLE `t2` (
                  `id` int unsigned NOT NULL AUTO_INCREMENT,
                  `t1_id` int DEFAULT NULL,
                  `status` enum('1','0') DEFAULT NULL,
                  `number` int DEFAULT NULL,
                  PRIMARY KEY (`id`)
                ) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 /*!80000 COLLATE=utf8mb4_0900_ai_ci */
                """).get()
            _ = try await conn.simpleQuery("INSERT INTO `t1` (`id`, `group_id`, `text`) VALUES ('1', '1', 'something')").get()
            _ = try await conn.simpleQuery("INSERT INTO `t2` (`id`, `t1_id`, `status`, `number`) VALUES ('1', '1', '1', '0')").get()
            _ = try await conn.query("""
                SELECT
                    c.id = 1 -- comparing with one, or almost, any other comparison.
                FROM
                    t1 as a
                    JOIN (SELECT * FROM t2 WHERE status = '1' AND number = 0) as b ON a.id = b.t1_id
                    JOIN (SELECT * FROM t1) as c ON c.group_id = a.group_id
                ORDER BY
                    (a.text LIKE "") DESC
                """, onMetadata: { metadata in conn.logger.info("\(metadata.affectedRows), \(metadata.lastInsertID ?? 0)") }).get()

            _ = try await conn.simpleQuery("DROP TABLE IF EXISTS `t1`").get()
            _ = try await conn.simpleQuery("DROP TABLE IF EXISTS `t2`").get()
        } catch {
            _ = try? await conn.simpleQuery("DROP TABLE IF EXISTS `t1`").get()
            _ = try? await conn.simpleQuery("DROP TABLE IF EXISTS `t2`").get()
            try? await conn.close().get()
            throw error
        }
        try await conn.close().get()
    }

    @Test
    func simpleQuery_selectString() async throws {
        let conn = try await MySQLConnection.test()

        do {
            let rows = try await conn.simpleQuery("SELECT 'foo' as bar").get()
            try #require(rows.count == 1)
            #expect(rows.description == #"[["bar": "foo"]]"#)
            #expect(rows[0].column("bar")?.string == "foo")
        } catch {
            try? await conn.close().get()
            throw error
        }
        try await conn.close().get()
    }

    @Test
    func simpleQuery_selectIntegers() async throws {
        let conn = try await MySQLConnection.test()

        do {
            let rows = try await conn.simpleQuery("SELECT 1 as one, 2 as two").get()
            try #require(rows.count == 1)
            #expect(rows[0].column("one")?.string == "1")
            #expect(rows[0].column("two")?.string == "2")
        } catch {
            try? await conn.close().get()
            throw error
        }
        try await conn.close().get()
    }

    @Test
    func simpleQuery_syntaxError() async throws {
        let conn = try await MySQLConnection.test()

        do {
            let isMariaDB = try await conn.simpleQuery("SELECT version() v").get().first?.column("v")?.string?.contains("MariaDB") ?? false
            try await #require(throws: MySQLError.invalidSyntax("You have an error in your SQL syntax; check the manual that corresponds to your \(isMariaDB ? "MariaDB" : "MySQL") server version for the right syntax to use near '&' at line 1")) { _ = try await conn.simpleQuery("SELECT &").get() }
        } catch {
            try? await conn.close().get()
            throw error
        }
        try await conn.close().get()
    }
    
    @Test
    func query_syntaxError() async throws {
        let conn = try await MySQLConnection.test()

        do {
            let isMariaDB = try await conn.simpleQuery("SELECT version() v").get().first?.column("v")?.string?.contains("MariaDB") ?? false
            try await #require(throws: MySQLError.invalidSyntax("You have an error in your SQL syntax; check the manual that corresponds to your \(isMariaDB ? "MariaDB" : "MySQL") server version for the right syntax to use near '&' at line 1")) { _ = try await conn.query("SELECT &").get() }
        } catch {
            try? await conn.close().get()
            throw error
        }
        try await conn.close().get()
    }

    @Test
    func simpleQuery_duplicateEntry() async throws {
        let conn = try await MySQLConnection.test()

        do {
            let v = try await conn.simpleQuery("SELECT version() v").get().first?.column("v")?.string
            let isNewMySQL = v?.split(separator: ".").first.flatMap { Int(String($0)) } ?? 0 > 5 && !(v?.contains("MariaDB") ?? false)
            _ = try await conn.simpleQuery("DROP TABLE IF EXISTS foos").get()
            #expect(try await conn.simpleQuery("DROP TABLE IF EXISTS foos").get().isEmpty)
            #expect(try await conn.simpleQuery("CREATE TABLE foos (id BIGINT SIGNED unique, name VARCHAR(64))").get().isEmpty)
            #expect(try await conn.simpleQuery("INSERT INTO foos VALUES (1, 'one')").get().isEmpty)
            try await #require(throws: MySQLError.duplicateEntry("Duplicate entry '1' for key '\(isNewMySQL ? "foos." : "")id'")) { _ = try await conn.simpleQuery("INSERT INTO foos VALUES (1, 'two')").get() }
            _ = try await conn.simpleQuery("DROP TABLE IF EXISTS foos").get()
        } catch {
            _ = try? await conn.simpleQuery("DROP TABLE IF EXISTS foos").get()
            try? await conn.close().get()
            throw error
        }
        try await conn.close().get()
    }

    @Test
    func query_duplicateEntry() async throws {
        let conn = try await MySQLConnection.test()

        do {
            let v = try await conn.simpleQuery("SELECT version() v").get().first?.column("v")?.string
            let isNewMySQL = v?.split(separator: ".").first.flatMap { Int(String($0)) } ?? 0 > 5 && !(v?.contains("MariaDB") ?? false)
            _ = try await conn.simpleQuery("DROP TABLE IF EXISTS foos").get()
            #expect(try await conn.simpleQuery("DROP TABLE IF EXISTS foos").get().isEmpty)
            #expect(try await conn.simpleQuery("CREATE TABLE foos (id BIGINT SIGNED unique, name VARCHAR(64))").get().isEmpty)
            #expect(try await conn.simpleQuery("INSERT INTO foos VALUES (1, 'one')").get().isEmpty)
            try await #require(throws: MySQLError.duplicateEntry("Duplicate entry '1' for key '\(isNewMySQL ? "foos." : "")id'")) { _ = try await conn.query("INSERT INTO foos VALUES (1, 'two')").get() }
            _ = try await conn.simpleQuery("DROP TABLE IF EXISTS foos").get()
        } catch {
            _ = try? await conn.simpleQuery("DROP TABLE IF EXISTS foos").get()
            try? await conn.close().get()
            throw error
        }
        try await conn.close().get()
    }

    @Test
    func query_selectMixed() async throws {
        let conn = try await MySQLConnection.test()

        do {
            let rows = try await conn.query("SELECT '1' as one, 2 as two").get()
            try #require(rows.count == 1)
            #expect(rows[0].column("one")?.string == "1")
            #expect(rows[0].column("two")?.string == "2")
        } catch {
            try? await conn.close().get()
            throw error
        }
        try await conn.close().get()
    }

    @Test
    func query_selectBoundParams() async throws {
        let conn = try await MySQLConnection.test()

        do {
            let rows = try await conn.query("SELECT ? as one, ? as two", ["1", "2"]).get()
            try #require(rows.count == 1)
            #expect(rows[0].column("one")?.string == "1")
            #expect(rows[0].column("two")?.string == "2")
        } catch {
            try? await conn.close().get()
            throw error
        }
        try await conn.close().get()
    }

    @Test
    func query_selectConcat() async throws {
        let conn = try await MySQLConnection.test()

        do {
            let rows = try await conn.query("SELECT CONCAT(?, ?) as test;", ["hello", "world"]).get()
            try #require(rows.count == 1)
            #expect(rows[0].column("test")?.string == "helloworld")
        } catch {
            try? await conn.close().get()
            throw error
        }
        try await conn.close().get()
    }

    @Test
    func textWithMicrosecondsMySQLTimeParse() throws {
        let dateString = "2024-04-15 22:38:12.392812"
        
        let time = MySQLTime(dateString)
        
        #expect(time != nil)
        #expect(time?.year == 2024)
        #expect(time?.month == 4)
        #expect(time?.day == 15)
        #expect(time?.hour == 22)
        #expect(time?.minute == 38)
        #expect(time?.second == 12)
        #expect(time?.microsecond == 392812)
    }

    @Test
    func date_conversion() throws {
        let date = Date(timeIntervalSinceReferenceDate: 0.001)
        let mysqlDate = MySQLTime(date: date)
        let time = mysqlDate.date!
        #expect(mysqlDate.microsecond != 0)

        #expect(Int(exactly: Double(date.timeIntervalSinceReferenceDate) * 100000) == Int(exactly: Double(time.timeIntervalSinceReferenceDate) * 100000))
    }

    @Test
    func date_before1970() throws {
        let time = MySQLTime(date: MySQLTime(date: Date(timeIntervalSince1970: 1.1)).date!)
        let time2 = MySQLTime(date: MySQLTime(date: Date(timeIntervalSince1970: -1.1)).date!)
        #expect(time.microsecond == UInt32(100000))
        #expect(time2.microsecond == UInt32(100000))
    }

    @Test
    func date_zeroIsInvalidButMySQLReturnsIt() throws {
        let zeroTime = MySQLTime()
        let data = MySQLData(time: zeroTime)

        #expect(data.description == "1970-01-01 00:00:00 +0000")
    }

    @Test
    func sha2() throws {
        var message = ByteBufferAllocator().buffer(capacity: 0)
        message.writeString("test")
        var digest = sha256(message)
        #expect(digest.readBytes(length: 32) == [
            0x9f, 0x86, 0xd0, 0x81, 0x88, 0x4c, 0x7d, 0x65, 0x9a, 0x2f, 0xea, 0xa0, 0xc5, 0x5a, 0xd0, 0x15,
            0xa3, 0xbf, 0x4f, 0x1b, 0x2b, 0x0b, 0x82, 0x2c, 0xd1, 0x5d, 0x6c, 0x15, 0xb0, 0xf0, 0x0a, 0x08,
        ])
    }

    // https://github.com/vapor/mysql-nio/issues/87
    @Test
    func unexpectedPacketHandling() async throws {
        struct PingCommand: MySQLCommand {
            func handle(packet: inout MySQLPacket, capabilities: MySQLProtocol.CapabilityFlags) throws -> MySQLCommandState { preconditionFailure("") }
            func activate(capabilities: MySQLProtocol.CapabilityFlags) throws -> MySQLCommandState { .init(response: [.init(payload: .init(bytes: [0x0e]))], done: true) }
        }
        let conn = try await MySQLConnection.test(on: .singletonMultiThreadedEventLoopGroup.any()).get()
        try await conn.send(PingCommand(), logger: conn.logger).get()
        try await Task.sleep(nanoseconds: 100_000_000) // to let the reply come in without any other command queued
        try await #require(throws: MySQLError.closed) { _ = try await conn.simpleQuery("SELECT 1").get() }
        try? await conn.close().get()
    }
    
    // https://github.com/vapor/mysql-nio/issues/91
    @Test
    func beforeHandshakeErrorHandling() async throws {
        // There's no way to force a real server to throw a pre-handshake error, fake it with a mock server and a handcrafted ERR_Packet.
        let serverChannel = try await ServerBootstrap(group: .singletonMultiThreadedEventLoopGroup)
            .serverChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SocketOptionName(SO_REUSEADDR)), value: SocketOptionValue(1))
            .childChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SocketOptionName(SO_REUSEADDR)), value: SocketOptionValue(1))
            .childChannelInitializer { channel in
                final class Handler: ChannelInboundHandler, Sendable {
                    typealias InboundIn = ByteBuffer; typealias OutboundOut = ByteBuffer
                    func channelActive(context: ChannelHandlerContext) {
                        var packet = MySQLPacket(), buf = ByteBuffer()
                        let context = NIOLoopBound(context, eventLoop: context.eventLoop)
                        packet.payload.writeMultipleIntegers(0xff/*flag*/, 2006/*CR_SERVER_GONE_ERROR*/, endianness: .little, as: (UInt8, UInt16).self)
                        packet.payload.writeString("#HY000Server gone")
                        try! MySQLPacketEncoder(sequence: .init(), logger: .init(label: "") { _ in SwiftLogNoOpLogHandler() }).encode(data: packet, out: &buf) // Never actually throws
                        context.value.writeAndFlush(wrapOutboundOut(buf)).whenComplete { _ in context.value.close(mode: .all, promise: nil) }
                    }
                }
                return channel.pipeline.addHandler(Handler())
            }
            .bind(host: "127.0.0.1", port: 3307).get()
        try await #require(throws: MySQLError.server(.init(errorCode: .SERVER_GONE_ERROR, sqlStateMarker: "#", sqlState: "HY000", errorMessage: "Server gone"))) {
            let connection = try await MySQLConnection.connect(to: .init(ipAddress: "127.0.0.1", port: 3307), username: "", database: "", tlsConfiguration: nil, on: .singletonMultiThreadedEventLoopGroup.any()).get()
            try? await connection.close().get() // connection is *only* open if we get to this point
        }
        try? await serverChannel.close(mode: .all)
    }
}

final class MySQLNIOXCTests: XCTestCase {
    override func setUp() async throws {
        XCTAssert(isLoggingConfigured)
    }

    func testQuery_insert() throws {
        let conn = try MySQLConnection.test(on: .singletonMultiThreadedEventLoopGroup.any()).wait()
        defer { try! conn.close().wait() }
        let dropResults = try conn.simpleQuery("DROP TABLE IF EXISTS foos").wait()
        XCTAssertEqual(dropResults.count, 0)
        let createResults = try conn.simpleQuery("CREATE TABLE foos (id BIGINT SIGNED, name VARCHAR(64))").wait()
        XCTAssertEqual(createResults.count, 0)
        defer { _ = try! conn.simpleQuery("DROP TABLE IF EXISTS foos").wait() }
        let insertResults = try conn.query("INSERT INTO foos VALUES (?, ?)", [-1, "test"]).wait()
        XCTAssertEqual(insertResults.count, 0)
        let selectResults = try conn.query("SELECT * FROM foos WHERE name = ?", ["test"]).wait()
        guard selectResults.count == 1 else {
            return XCTFail("invalid row count")
        }
        XCTAssertEqual(selectResults[0].column("id")?.int, -1)
        XCTAssertEqual(selectResults[0].column("name")?.string, "test")
        
        // test double parameterized query
        let selectResults2 = try conn.query("SELECT * FROM foos WHERE name = ?", ["test"]).wait()
        XCTAssertEqual(selectResults2.count, 1)
    }
    
    func testQuery_noResponse() throws {
        let conn = try MySQLConnection.test(on: .singletonMultiThreadedEventLoopGroup.any()).wait()
        defer { try! conn.close().wait() }
        let rows = try conn.query("SET @foo = 'bar'").wait()
        XCTAssertEqual(rows.count, 0)
    }
    
    func testQuery_metadata() throws {
        let conn = try MySQLConnection.test(on: .singletonMultiThreadedEventLoopGroup.any()).wait()
        defer { try! conn.close().wait() }
        let dropResults = try conn.simpleQuery("DROP TABLE IF EXISTS foos").wait()
        XCTAssertEqual(dropResults.count, 0)
        let createResults = try conn.simpleQuery("CREATE TABLE foos (id BIGINT PRIMARY KEY AUTO_INCREMENT, name VARCHAR(64))").wait()
        XCTAssertEqual(createResults.count, 0)
        defer { _ = try! conn.simpleQuery("DROP TABLE IF EXISTS foos").wait() }
        let insertResults = try conn.query("INSERT INTO foos (name) VALUES (?)", ["test"]) { metadata in
            XCTAssertEqual(metadata.affectedRows, 1)
            XCTAssertEqual(metadata.lastInsertID, 1)
        }.wait()
        XCTAssertEqual(insertResults.count, 0)
    }
    
    func testQuery_datetime() throws {
        let conn = try MySQLConnection.test(on: .singletonMultiThreadedEventLoopGroup.any()).wait()
        defer { try! conn.close().wait() }
        do {
            let rows = try conn.query("SELECT CAST('2016-01-18' AS DATETIME) as datetime").wait()
            XCTAssertEqual(rows[0].column("datetime")?.date?.description, "2016-01-18 00:00:00 +0000")
        }
        do {
            let date = Date(timeIntervalSince1970: 1453075200)
            let rows = try conn.query("SELECT CAST(? AS DATETIME) as datetime", [.init(date: date)]).wait()
            XCTAssertEqual(rows[0].column("datetime")?.date?.description, "2016-01-18 00:00:00 +0000")
        }
    }

    func testString_lengthEncoded_uint8() throws {
        let conn = try MySQLConnection.test(on: .singletonMultiThreadedEventLoopGroup.any()).wait()
        defer { try! conn.close().wait() }
        let string = String(repeating: "a", count: 128)
        let rows = try conn.query("SELECT ? as s", [MySQLData(string: string)]).wait()
        XCTAssertEqual(rows[0].column("s")?.string, string)
    }

    func testString_lengthEncoded_fc() throws {
        let conn = try MySQLConnection.test(on: .singletonMultiThreadedEventLoopGroup.any()).wait()
        defer { try! conn.close().wait() }
        let string = String(repeating: "a", count: 512)
        let rows = try conn.query("SELECT ? as s", [MySQLData(string: string)]).wait()
        XCTAssertEqual(rows[0].column("s")?.string, string)
    }

    func testString_lengthEncoded_fd() throws {
        let conn = try MySQLConnection.test(on: .singletonMultiThreadedEventLoopGroup.any()).wait()
        defer { try! conn.close().wait() }
        let string = String(repeating: "a", count: 1<<17)
        let rows = try conn.query("SELECT ? as s", [MySQLData(string: string)]).wait()
        XCTAssertEqual(rows[0].column("s")?.string, string)
    }
    
    func testTypes() throws {
        /// support
        struct TestColumn {
            let name: String
            let columnType: String
            let data: MySQLData
            let match: (MySQLData?, StaticString, UInt) throws -> ()
            init(_ name: String, _ columnType: String, _ value: MySQLData) {
                self.name = name
                self.columnType = columnType
                self.data = value
                self.match = { data, file, line in
                    if let data = data {
                        if data.type == .bit {
                            XCTAssertEqual(data.bool, value.bool, name, file: file, line: line)
                        } else {
                            XCTAssertEqual(data.description, value.description, name, file: file, line: line)
                        }
                    } else {
                        XCTFail("Data null", file: file, line: line)
                    }
                }
            }
        }

        let tests: [TestColumn] = [
            .init("xchar", "CHAR(60)", "hello1"),
            .init("xvarchar", "VARCHAR(61)", "hello2"),
            .init("xtext", "TEXT(62)", MySQLData(type: .blob, buffer: .init(string: "hello3"))),
            .init("xbinary", "BINARY(6)", "hello4"),
            .init("xvarbinary", "VARBINARY(66)", "hello5"),
            .init("xbit", "BIT", MySQLData(bool: true)),
            .init("xtinyint", "TINYINT(1)", 127),
            .init("xsmallint", "SMALLINT(1)", 32767),
            .init("xvarcharnull", "VARCHAR(10)", MySQLData(type: .null, buffer: nil)),
            .init("xmediumint", "MEDIUMINT(1)", 8388607),
            .init("xinteger", "INTEGER(1)", 2147483647),
            .init("xbigint", "BIGINT(1)", MySQLData(int: .max)),
            .init("xdecimal", "DECIMAL(12,5)", MySQLData(decimal: Decimal(string:"-12.34567")!)),
            .init("xname", "VARCHAR(10) NOT NULL", "test"),
        ]
        
        let conn = try MySQLConnection.test(on: .singletonMultiThreadedEventLoopGroup.any()).wait()
        defer { try! conn.close().wait() }
        /// create table
        let columns = tests.map { test in
            return "`\(test.name)` \(test.columnType)"
        }.joined(separator: ", ")
        let dropResults = try conn.simpleQuery("DROP TABLE IF EXISTS kitchen_sink;").wait()
        XCTAssertEqual(dropResults.count, 0)
        let createResults = try conn.simpleQuery("CREATE TABLE kitchen_sink (\(columns));").wait()
        XCTAssertEqual(createResults.count, 0)
        defer { _ = try! conn.simpleQuery("DROP TABLE IF EXISTS kitchen_sink").wait() }
        
        /// insert data
        let placeholders = tests.map { _ in "?" }.joined(separator: ", ")
        let insertResults = try conn.query("INSERT INTO kitchen_sink VALUES (\(placeholders));", tests.map { $0.data }).wait()
        XCTAssertEqual(insertResults.count, 0)
        
        // select data
        let selectResults = try conn.query("SELECT * FROM kitchen_sink WHERE xname = ?;", ["test"]).wait()
        XCTAssertEqual(selectResults.count, 1)
        
        for test in tests {
            try test.match(selectResults[0].column(test.name), #file, #line)
        }
    }

    func testQuery_decimal() throws {
        let conn = try MySQLConnection.test(on: .singletonMultiThreadedEventLoopGroup.any()).wait()
        defer { try! conn.close().wait() }
        do {
            let rows = try conn.query("SELECT CAST('3.1415926' as DECIMAL(12,3)) as d").wait()
            XCTAssertEqual(rows[0].column("d").flatMap { Decimal(mysqlData: $0) }?.description, "3.142")
        }
    }

    func testPreparedStatement_invalidParams() throws {
        let conn = try MySQLConnection.test(on: .singletonMultiThreadedEventLoopGroup.any()).wait()
        defer { try! conn.close().wait() }

        do {
            _ = try conn.query("SELECT ?", []).wait()
        } catch MySQLError.server {
            // Pass
        }
    }

    // https://github.com/vapor/mysql-nio/issues/47
    func testValidQueryTimeout() throws {
        let conn = try MySQLConnection.test(on: .singletonMultiThreadedEventLoopGroup.any()).wait()
        defer { try! conn.close().wait() }

        _ = try conn.query("CREATE TABLE `Phrase` (id INT(11), views INT(11))").wait()
        defer { _ = try! conn.query("DROP TABLE IF EXISTS `Phrase`").wait() }

        _ = try conn.query("UPDATE `Phrase` SET `views` = CASE WHEN `id` = 1 THEN `views` + 6 WHEN `id` = 2 THEN `views` + 2 END WHERE `id` IN (1,2)").wait()
    }

    func test4ByteMySQLTimeSerialize() throws {
        let conn = try MySQLConnection.test(on: .singletonMultiThreadedEventLoopGroup.any()).wait()
        defer { try! conn.close().wait() }

        let rows = try conn.query(#"SELECT DATE_FORMAT(?, "%M %D %Y %H:%i:%s.%f")as x"#, [.init(time: .init(year: 2020, month: 5, day: 23))]).wait()
        XCTAssertEqual(rows[0].column("x")?.string, "May 23rd 2020 00:00:00.000000")
    }

    func test4ByteMySQLTimeParse() throws {
        let conn = try MySQLConnection.test(on: .singletonMultiThreadedEventLoopGroup.any()).wait()
        defer { try! conn.close().wait() }

        _ = try conn.simpleQuery("DROP TABLE IF EXISTS foo").wait()
        _ = try conn.simpleQuery("CREATE TABLE foo (bar DATE)").wait()
        defer { _ = try! conn.simpleQuery("DROP TABLE IF EXISTS foo").wait() }
        _ = try conn.query("INSERT INTO foo (bar) VALUES ('2038-01-19')").wait()
        let rows = try conn.query("SELECT * FROM foo").wait()
        guard let time = rows[0].column("bar")?.time else {
            return XCTFail("Could not convert to time: \(rows[0])")
        }
        XCTAssertEqual(time.year, 2038)
        XCTAssertEqual(time.month, 1)
        XCTAssertEqual(time.day, 19)
        XCTAssertEqual(time.hour, nil)
        XCTAssertEqual(time.minute, nil)
        XCTAssertEqual(time.second, nil)
        XCTAssertEqual(time.microsecond, nil)
        XCTAssertEqual(time.date?.description, "2038-01-19 00:00:00 +0000")
    }

    func test7ByteMySQLTimeSerialize() throws {
        let conn = try MySQLConnection.test(on: .singletonMultiThreadedEventLoopGroup.any()).wait()
        defer { try! conn.close().wait() }

        let rows = try conn.query(#"SELECT DATE_FORMAT(?, "%M %D %Y %H:%i:%s.%f")as x"#, [
            .init(time: .init(year: 2020, month: 5, day: 23, hour: 2, minute: 58, second: 42))
        ]).wait()
        XCTAssertEqual(rows[0].column("x")?.string, "May 23rd 2020 02:58:42.000000")
    }

    func test7ByteMySQLTimeParse() throws {
        let conn = try MySQLConnection.test(on: .singletonMultiThreadedEventLoopGroup.any()).wait()
        defer { try! conn.close().wait() }

        _ = try conn.simpleQuery("DROP TABLE IF EXISTS foo").wait()
        _ = try conn.simpleQuery("CREATE TABLE foo (bar DATETIME)").wait()
        defer { _ = try! conn.simpleQuery("DROP TABLE IF EXISTS foo").wait() }
        _ = try conn.query("INSERT INTO foo (bar) VALUES ('2038-01-19 03:14:07')").wait()
        let rows = try conn.query("SELECT * FROM foo").wait()
        guard let time = rows[0].column("bar")?.time else {
            return XCTFail("Could not convert to time: \(rows[0])")
        }
        XCTAssertEqual(time.year, 2038)
        XCTAssertEqual(time.month, 1)
        XCTAssertEqual(time.day, 19)
        XCTAssertEqual(time.hour, 3)
        XCTAssertEqual(time.minute, 14)
        XCTAssertEqual(time.second, 7)
        XCTAssertEqual(time.microsecond, nil)
        XCTAssertEqual(time.date?.description, "2038-01-19 03:14:07 +0000")
    }

    func test8ByteMySQLTimeSerialize() throws {
        let conn = try MySQLConnection.test(on: .singletonMultiThreadedEventLoopGroup.any()).wait()
        defer { try! conn.close().wait() }

        let rows = try conn.query(#"SELECT DATE_FORMAT(?, "%H:%i:%s.%f") as x"#, [
            .init(time: .init(hour: 2, minute: 58, second: 42))
        ]).wait()
        XCTAssertEqual(rows[0].column("x")?.string, "02:58:42.000000")
    }

    // https://github.com/vapor/mysql-nio/issues/49
    func test8ByteMySQLTimeParse() throws {
        let conn = try MySQLConnection.test(on: .singletonMultiThreadedEventLoopGroup.any()).wait()
        defer { try! conn.close().wait() }

        _ = try conn.simpleQuery("DROP TABLE IF EXISTS foo").wait()
        _ = try conn.simpleQuery("CREATE TABLE foo (bar TIME)").wait()
        defer { _ = try! conn.simpleQuery("DROP TABLE IF EXISTS foo").wait() }
        _ = try conn.query("INSERT INTO foo (bar) VALUES ('12:34:56.123')").wait()
        let rows = try conn.query("SELECT * FROM foo").wait()
        guard let time = rows[0].column("bar")?.time else {
            return XCTFail("Could not convert to time: \(rows[0])")
        }
        XCTAssertEqual(time.year, nil)
        XCTAssertEqual(time.month, nil)
        XCTAssertEqual(time.day, nil)
        XCTAssertEqual(time.hour, 12)
        XCTAssertEqual(time.minute, 34)
        XCTAssertEqual(time.second, 56)
        XCTAssertEqual(time.microsecond, nil)
        XCTAssertEqual(time.date, nil)
    }

    func test11ByteMySQLTimeSerialize() throws {
        let conn = try MySQLConnection.test(on: .singletonMultiThreadedEventLoopGroup.any()).wait()
        defer { try! conn.close().wait() }

        let rows = try conn.query(#"SELECT DATE_FORMAT(?, "%M %D %Y %H:%i:%s.%f") as x"#, [
            .init(time: .init(year: 2038, month: 1, day: 19, hour: 3, minute: 14, second: 7, microsecond: 123456))
        ]).wait()
        XCTAssertEqual(rows[0].column("x")?.string, "January 19th 2038 03:14:07.123456")
    }

    func test11ByteMySQLTimeParse() throws {
        let conn = try MySQLConnection.test(on: .singletonMultiThreadedEventLoopGroup.any()).wait()
        defer { try! conn.close().wait() }

        _ = try conn.simpleQuery("DROP TABLE IF EXISTS foo").wait()
        _ = try conn.simpleQuery("CREATE TABLE foo (bar DATETIME(6))").wait()
        defer { _ = try! conn.simpleQuery("DROP TABLE IF EXISTS foo").wait() }
        _ = try conn.query("INSERT INTO foo (bar) VALUES ('2038-01-19 03:14:07.123456')").wait()
        let rows = try conn.query("SELECT * FROM foo").wait()
        guard let time = rows[0].column("bar")?.time else {
            return XCTFail("Could not convert to time: \(rows[0])")
        }
        XCTAssertEqual(time.year, 2038)
        XCTAssertEqual(time.month, 1)
        XCTAssertEqual(time.day, 19)
        XCTAssertEqual(time.hour, 3)
        XCTAssertEqual(time.minute, 14)
        XCTAssertEqual(time.second, 7)
        XCTAssertEqual(time.microsecond, 123456)
        XCTAssertEqual(time.date?.description, "2038-01-19 03:14:07 +0000")
    }

    func test12ByteMySQLTimeSerialize() throws {
        let conn = try MySQLConnection.test(on: .singletonMultiThreadedEventLoopGroup.any()).wait()
        defer { try! conn.close().wait() }

        let rows = try conn.query(#"SELECT DATE_FORMAT(?, "%H:%i:%s.%f") as x"#, [
            .init(time: .init(hour: 3, minute: 14, second: 7, microsecond: 123456))
        ]).wait()
        XCTAssertEqual(rows[0].column("x")?.string, "03:14:07.123456")
    }

    func test12ByteMySQLTimeParse() throws {
        let conn = try MySQLConnection.test(on: .singletonMultiThreadedEventLoopGroup.any()).wait()
        defer { try! conn.close().wait() }

        _ = try conn.simpleQuery("DROP TABLE IF EXISTS foo").wait()
        _ = try conn.simpleQuery("CREATE TABLE foo (bar TIME(6))").wait()
        defer { _ = try! conn.simpleQuery("DROP TABLE IF EXISTS foo").wait() }
        _ = try conn.query("INSERT INTO foo (bar) VALUES ('03:14:07.123456')").wait()
        let rows = try conn.query("SELECT * FROM foo").wait()
        guard let time = rows[0].column("bar")?.time else {
            return XCTFail("Could not convert to time: \(rows[0])")
        }
        XCTAssertEqual(time.year, nil)
        XCTAssertEqual(time.month, nil)
        XCTAssertEqual(time.day, nil)
        XCTAssertEqual(time.hour, 3)
        XCTAssertEqual(time.minute, 14)
        XCTAssertEqual(time.second, 7)
        XCTAssertEqual(time.microsecond, 123456)
        XCTAssertEqual(time.date, nil)
    }

    func testTextMySQLTimeParse() throws {
        let conn = try MySQLConnection.test(on: .singletonMultiThreadedEventLoopGroup.any()).wait()
        defer { try! conn.close().wait() }
        
        // The text protocol returns timestamp columns in text format.
        // Ensure these can be converted to MySQLTime without error.
        let rows = try conn.simpleQuery("SELECT CURRENT_TIMESTAMP() AS foo").wait()
        XCTAssertNotNil(rows[0].column("foo")?.time)
    }
    
    func testNull() throws {
        let conn = try MySQLConnection.test(on: .singletonMultiThreadedEventLoopGroup.any()).wait()
        defer { try! conn.close().wait() }
        
        _ = try conn.simpleQuery("DROP TABLE IF EXISTS foo").wait()
        _ = try conn.simpleQuery("CREATE TABLE foo (bar INT, baz INT, qux INT)").wait()
        defer { _ = try! conn.simpleQuery("DROP TABLE IF EXISTS foo").wait() }
        
        _ = try conn.simpleQuery("INSERT INTO foo (bar, baz, qux) VALUES (1, NULL, 3)").wait()
        let rows = try conn.simpleQuery("SELECT * FROM foo").wait()
        XCTAssertEqual(rows[0].column("bar")?.int, 1)
        XCTAssertNil(rows[0].column("baz")?.int)
        XCTAssertEqual(rows[0].column("qux")?.int, 3)
    }
}
