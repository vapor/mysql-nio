import XCTest
@testable import MySQLNIO
import Logging
import NIOCore
import NIOPosix

final class MySQLNIOTests: XCTestCase {
    private var eventLoopGroup: (any EventLoopGroup)!
    private var eventLoop: any EventLoop { self.eventLoopGroup.any() }
    
    override func setUpWithError() throws {
        XCTAssert(isLoggingConfigured)
        self.eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    }
    
    override func tearDownWithError() throws {
        try self.eventLoopGroup.syncShutdownGracefully()
    }

    func testDecodingSumOfIntsWithNoRows() throws {
        let conn = try MySQLConnection.test(on: self.eventLoop).wait()
        defer { try! conn.close().wait() }
        let dropResults = try conn.simpleQuery("DROP TABLE IF EXISTS foos").wait()
        XCTAssertEqual(dropResults.count, 0)
        let createResults = try conn.simpleQuery("CREATE TABLE foos (`item_count` int(11))").wait()
        XCTAssertEqual(createResults.count, 0)
        defer { _ = try! conn.simpleQuery("DROP TABLE IF EXISTS foos").wait() }
        let rows = try conn.simpleQuery("SELECT sum(`item_count`) as sum from foos").wait()
        guard rows.count == 1 else {
            return XCTFail("invalid row count")
        }
        if let sqlData = rows[0].column("sum") {
            XCTAssertEqual(sqlData.string, nil)
            XCTAssertEqual(sqlData.float, nil)
            XCTAssertEqual(sqlData.double, nil)
            XCTAssertEqual(sqlData.int, nil)
            XCTAssertEqual(sqlData.decimal, nil)
        } else {
            XCTAssert(false, "rows[0].column(\"sum\") was nil")
        }
    }

    func testDecodingSumOfIntsWithRows() throws {
        let conn = try MySQLConnection.test(on: self.eventLoop).wait()
        defer { try! conn.close().wait() }
        let dropResults = try conn.simpleQuery("DROP TABLE IF EXISTS foos").wait()
        XCTAssertEqual(dropResults.count, 0)
        let createResults = try conn.simpleQuery("CREATE TABLE foos (`item_count` int(11))").wait()
        XCTAssertEqual(createResults.count, 0)
        defer { _ = try! conn.simpleQuery("DROP TABLE IF EXISTS foos").wait() }
        let _ = try conn.simpleQuery("insert into foos (`item_count`) values (0)").wait()
        let rows = try conn.simpleQuery("SELECT sum(`item_count`) as sum from foos").wait()
        guard rows.count == 1 else {
            return XCTFail("invalid row count")
        }
        if let sqlData = rows[0].column("sum") {
            XCTAssertEqual(sqlData.string, "0")
            XCTAssertEqual(sqlData.float, 0)
            XCTAssertEqual(sqlData.double, 0)
            XCTAssertEqual(sqlData.int, 0)
            XCTAssertEqual(sqlData.decimal, 0)
        } else {
            XCTAssert(false, "rows[0].column(\"sum\") was nil")
        }
        let _ = try conn.simpleQuery("insert into foos (`item_count`) values (199)").wait()
        let rows2 = try conn.simpleQuery("SELECT sum(`item_count`) as sum from foos").wait()
        guard rows2.count == 1 else {
            return XCTFail("invalid row count")
        }
        if let sqlData = rows2[0].column("sum") {
            XCTAssertEqual(sqlData.string, "199")
            XCTAssertEqual(sqlData.float, 199)
            XCTAssertEqual(sqlData.double, 199)
            XCTAssertEqual(sqlData.int, 199)
            XCTAssertEqual(sqlData.decimal, Decimal(string: "199"))
        } else {
            XCTAssert(false, "rows[0].column(\"sum\") was nil")
        }
    }

    func testSimpleQuery_selectVersion() throws {
        let conn = try MySQLConnection.test(on: self.eventLoop).wait()
        defer { try! conn.close().wait() }
        let rows = try conn.simpleQuery("SELECT @@version").wait()
        guard rows.count == 1 else {
            return XCTFail("invalid row count")
        }
        XCTAssert(rows[0].column("@@version")?.string?.contains(".") == true)
    }
    
    func testSimpleQuery_selectString() throws {
        let conn = try MySQLConnection.test(on: self.eventLoop).wait()
        defer { try! conn.close().wait() }
        let rows = try conn.simpleQuery("SELECT 'foo' as bar").wait()
        guard rows.count == 1 else {
            return XCTFail("invalid row count")
        }
        XCTAssertEqual(rows.description, #"[["bar": "foo"]]"#)
        XCTAssertEqual(rows[0].column("bar")?.string, "foo")
    }
    
    func testSimpleQuery_selectIntegers() throws {
        let conn = try MySQLConnection.test(on: self.eventLoop).wait()
        defer { try! conn.close().wait() }
        let rows = try conn.simpleQuery("SELECT 1 as one, 2 as two").wait()
        guard rows.count == 1 else {
            return XCTFail("invalid row count")
        }
        XCTAssertEqual(rows[0].column("one")?.string, "1")
        XCTAssertEqual(rows[0].column("two")?.string, "2")
    }
    
    func testSimpleQuery_syntaxError() throws {
        let conn = try MySQLConnection.test(on: self.eventLoop).wait()
        defer { try! conn.close().wait() }
        XCTAssertThrowsError(try conn.simpleQuery("SELECT &").wait()) { error in
            guard case .invalidSyntax = error as? MySQLError else {
                return XCTFail("Exected MySQLError.invalidSyntax, but found \(error)")
            }
        }
    }
    
    func testQuery_syntaxError() throws {
        let conn = try MySQLConnection.test(on: self.eventLoop).wait()
        defer { try! conn.close().wait() }
        XCTAssertThrowsError(try conn.query("SELECT &").wait()) { error in
            guard case .invalidSyntax = error as? MySQLError else {
                return XCTFail("Exected MySQLError.invalidSyntax, but found \(error)")
            }
        }
    }
    
    func testSimpleQuery_duplicateEntry() throws {
        let conn = try MySQLConnection.test(on: self.eventLoop).wait()
        defer { try! conn.close().wait() }
        let dropResults = try conn.simpleQuery("DROP TABLE IF EXISTS foos").wait()
        XCTAssertEqual(dropResults.count, 0)
        let createResults = try conn.simpleQuery("CREATE TABLE foos (id BIGINT SIGNED unique, name VARCHAR(64))").wait()
        XCTAssertEqual(createResults.count, 0)
        defer { _ = try! conn.simpleQuery("DROP TABLE IF EXISTS foos").wait() }
        let insertResults = try conn.simpleQuery("INSERT INTO foos VALUES (1, 'one')").wait()
        XCTAssertEqual(insertResults.count, 0)
        XCTAssertThrowsError(try conn.query("INSERT INTO foos VALUES (1, 'two')").wait()) { error in
            guard case .duplicateEntry = error as? MySQLError else {
                return XCTFail("Expected MySQLError.duplicateEntry, but found \(error)")
            }
        }
    }

    func testQuery_duplicateEntry() throws {
        let conn = try MySQLConnection.test(on: self.eventLoop).wait()
        defer { try! conn.close().wait() }
        let dropResults = try conn.simpleQuery("DROP TABLE IF EXISTS foos").wait()
        XCTAssertEqual(dropResults.count, 0)
        let createResults = try conn.simpleQuery("CREATE TABLE foos (id BIGINT SIGNED unique, name VARCHAR(64))").wait()
        XCTAssertEqual(createResults.count, 0)
        defer { _ = try! conn.simpleQuery("DROP TABLE IF EXISTS foos").wait() }
        let insertResults = try conn.query("INSERT INTO foos VALUES (?, ?)", [1, "one"]).wait()
        XCTAssertEqual(insertResults.count, 0)
        XCTAssertThrowsError(try conn.query("INSERT INTO foos VALUES (?, ?)", [1, "two"]).wait()) { (inError) in
            guard case .duplicateEntry = inError as? MySQLError else {
                return XCTFail("Expected MySQLError.duplicateEntry, but found \(inError)")
            }
        }
    }
    
    func testQuery_selectMixed() throws {
        let conn = try MySQLConnection.test(on: self.eventLoop).wait()
        defer { try! conn.close().wait() }
        let rows = try conn.query("SELECT '1' as one, 2 as two").wait()
        guard rows.count == 1 else {
            return XCTFail("invalid row count")
        }
        XCTAssertEqual(rows[0].column("one")?.string, "1")
        XCTAssertEqual(rows[0].column("two")?.string, "2")
    }
    
    func testQuery_selectBoundParams() throws {
        let conn = try MySQLConnection.test(on: self.eventLoop).wait()
        defer { try! conn.close().wait() }
        let rows = try conn.query("SELECT ? as one, ? as two", ["1", "2"]).wait()
        guard rows.count == 1 else {
            return XCTFail("invalid row count")
        }
        XCTAssertEqual(rows[0].column("one")?.string, "1")
        XCTAssertEqual(rows[0].column("two")?.string, "2")
    }
    
    func testQuery_selectConcat() throws {
        let conn = try MySQLConnection.test(on: self.eventLoop).wait()
        defer { try! conn.close().wait() }
        let rows = try conn.query("SELECT CONCAT(?, ?) as test;", ["hello", "world"]).wait()
        guard rows.count == 1 else {
            return XCTFail("invalid row count")
        }
        XCTAssertEqual(rows[0].column("test")?.string, "helloworld")
    }
    
    func testQuery_insert() throws {
        let conn = try MySQLConnection.test(on: self.eventLoop).wait()
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
        let conn = try MySQLConnection.test(on: self.eventLoop).wait()
        defer { try! conn.close().wait() }
        let rows = try conn.query("SET @foo = 'bar'").wait()
        XCTAssertEqual(rows.count, 0)
    }
    
    func testQuery_metadata() throws {
        let conn = try MySQLConnection.test(on: self.eventLoop).wait()
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
        let conn = try MySQLConnection.test(on: self.eventLoop).wait()
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
    
    func testDate_conversion() throws {
        let date = Date(timeIntervalSinceReferenceDate: 0.001)
        let mysqlDate = MySQLTime(date: date)
        let time = mysqlDate.date!
        XCTAssertNotEqual(mysqlDate.microsecond, 0)
        
        XCTAssertEqual(
            Double(date.timeIntervalSinceReferenceDate),
            Double(time.timeIntervalSinceReferenceDate),
            accuracy: 5
        )
    }
 
    func testDate_before1970() throws {
        let time = MySQLTime(date: MySQLTime(date: Date(timeIntervalSince1970: 1.1)).date!)
        let time2 = MySQLTime(date: MySQLTime(date: Date(timeIntervalSince1970: -1.1)).date!)
        XCTAssert(time.microsecond == UInt32(100000))
        XCTAssert(time2.microsecond == UInt32(100000))
    }
    
    func testDate_zeroIsInvalidButMySQLReturnsIt() throws {
        let zeroTime = MySQLTime()
        let data = MySQLData(time: zeroTime)

        XCTAssertEqual(data.description, "1970-01-01 00:00:00 +0000")
    }

    func testString_lengthEncoded_uint8() throws {
        let conn = try MySQLConnection.test(on: self.eventLoop).wait()
        defer { try! conn.close().wait() }
        let string = String(repeating: "a", count: 128)
        let rows = try conn.query("SELECT ? as s", [MySQLData(string: string)]).wait()
        XCTAssertEqual(rows[0].column("s")?.string, string)
    }

    func testString_lengthEncoded_fc() throws {
        let conn = try MySQLConnection.test(on: self.eventLoop).wait()
        defer { try! conn.close().wait() }
        let string = String(repeating: "a", count: 512)
        let rows = try conn.query("SELECT ? as s", [MySQLData(string: string)]).wait()
        XCTAssertEqual(rows[0].column("s")?.string, string)
    }

    func testString_lengthEncoded_fd() throws {
        let conn = try MySQLConnection.test(on: self.eventLoop).wait()
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
        
        let conn = try MySQLConnection.test(on: self.eventLoop).wait()
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
    
    func testPerformance_simpleSelects() throws {
        try XCTSkipIf(env("PERFORMANCE_TESTS") == nil)
        let conn = try MySQLConnection.test(on: self.eventLoop).wait()
        defer { try! conn.close().wait() }
        for _ in 0..<1_000 {
            _ = try conn.simpleQuery("SELECT 1").wait()
        }
    }
    
    func testPerformance_parseDatetime() throws {
        try XCTSkipIf(env("PERFORMANCE_TESTS") == nil)
        let conn = try MySQLConnection.test(on: self.eventLoop).wait()
        defer { try! conn.close().wait() }
        
        measure {
            for _ in 0..<100 {
                let rows = try? conn.query("SELECT CAST('2016-01-18' AS DATETIME) as datetime").wait()
                XCTAssertEqual(rows?[0].column("datetime")?.date?.description, "2016-01-18 00:00:00 +0000")
            }
        }
    }
    
    func testSHA2() throws {
        var message = ByteBufferAllocator().buffer(capacity: 0)
        message.writeString("test")
        var digest = sha256(message)
        XCTAssertEqual(digest.readBytes(length: 32), [
            0x9f, 0x86, 0xd0, 0x81, 0x88, 0x4c, 0x7d, 0x65, 0x9a, 0x2f, 0xea, 0xa0, 0xc5, 0x5a, 0xd0, 0x15,
            0xa3, 0xbf, 0x4f, 0x1b, 0x2b, 0x0b, 0x82, 0x2c, 0xd1, 0x5d, 0x6c, 0x15, 0xb0, 0xf0, 0x0a, 0x08,
        ])
    }

    func testQuery_decimal() throws {
        let conn = try MySQLConnection.test(on: self.eventLoop).wait()
        defer { try! conn.close().wait() }
        do {
            let rows = try conn.query("SELECT CAST('3.1415926' as DECIMAL(12,3)) as d").wait()
            XCTAssertEqual(rows[0].column("d").flatMap { Decimal(mysqlData: $0) }?.description, "3.142")
        }
    }

    // https://github.com/vapor/mysql-nio/issues/30
    func testPreparedStatement_maxOpen() throws {
        try XCTSkipIf(env("PERFORMANCE_TESTS") == nil)
        let conn = try MySQLConnection.test(on: self.eventLoop).wait()
        defer { try! conn.close().wait() }

        let result = try conn.simpleQuery("SHOW VARIABLES LIKE 'max_prepared_stmt_count';").wait()
        let max = result[0].column("Value")!.int!
        conn.logger.info("max_prepared_stmt_count=\(max)")

        struct TestError: Error { }
        for i in 0..<(max + 1) {
            if i % (max / 10) == 0 {
                conn.logger.info("max_prepared_stmt_count iteration \(i)/\(max + 1)")
            }
            do {
                _ = try conn.query("SELECT @@version", onRow: { row in
                    throw TestError()
                }).wait()
                XCTFail("Query should have errored")
            } catch is TestError {
                // expected
            }
        }
    }

    func testPreparedStatement_invalidParams() throws {
        let conn = try MySQLConnection.test(on: self.eventLoop).wait()
        defer { try! conn.close().wait() }

        do {
            _ = try conn.query("SELECT ?", []).wait()
        } catch MySQLError.server {
            // Pass
        }
    }

    // https://github.com/vapor/mysql-nio/issues/47
    func testValidQueryTimeout() throws {
        let conn = try MySQLConnection.test(on: self.eventLoop).wait()
        defer { try! conn.close().wait() }

        _ = try conn.query("CREATE TABLE `Phrase` (id INT(11), views INT(11))").wait()
        defer { _ = try! conn.query("DROP TABLE IF EXISTS `Phrase`").wait() }

        _ = try conn.query("UPDATE `Phrase` SET `views` = CASE WHEN `id` = 1 THEN `views` + 6 WHEN `id` = 2 THEN `views` + 2 END WHERE `id` IN (1,2)").wait()
    }

    func test4ByteMySQLTimeSerialize() throws {
        let conn = try MySQLConnection.test(on: self.eventLoop).wait()
        defer { try! conn.close().wait() }

        let rows = try conn.query(#"SELECT DATE_FORMAT(?, "%M %D %Y %H:%i:%s.%f")as x"#, [.init(time: .init(year: 2020, month: 5, day: 23))]).wait()
        XCTAssertEqual(rows[0].column("x")?.string, "May 23rd 2020 00:00:00.000000")
    }

    func test4ByteMySQLTimeParse() throws {
        let conn = try MySQLConnection.test(on: self.eventLoop).wait()
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
        let conn = try MySQLConnection.test(on: self.eventLoop).wait()
        defer { try! conn.close().wait() }

        let rows = try conn.query(#"SELECT DATE_FORMAT(?, "%M %D %Y %H:%i:%s.%f")as x"#, [
            .init(time: .init(year: 2020, month: 5, day: 23, hour: 2, minute: 58, second: 42))
        ]).wait()
        XCTAssertEqual(rows[0].column("x")?.string, "May 23rd 2020 02:58:42.000000")
    }

    func test7ByteMySQLTimeParse() throws {
        let conn = try MySQLConnection.test(on: self.eventLoop).wait()
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
        let conn = try MySQLConnection.test(on: self.eventLoop).wait()
        defer { try! conn.close().wait() }

        let rows = try conn.query(#"SELECT DATE_FORMAT(?, "%H:%i:%s.%f") as x"#, [
            .init(time: .init(hour: 2, minute: 58, second: 42))
        ]).wait()
        XCTAssertEqual(rows[0].column("x")?.string, "02:58:42.000000")
    }

    // https://github.com/vapor/mysql-nio/issues/49
    func test8ByteMySQLTimeParse() throws {
        let conn = try MySQLConnection.test(on: self.eventLoop).wait()
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
        let conn = try MySQLConnection.test(on: self.eventLoop).wait()
        defer { try! conn.close().wait() }

        let rows = try conn.query(#"SELECT DATE_FORMAT(?, "%M %D %Y %H:%i:%s.%f") as x"#, [
            .init(time: .init(year: 2038, month: 1, day: 19, hour: 3, minute: 14, second: 7, microsecond: 123456))
        ]).wait()
        XCTAssertEqual(rows[0].column("x")?.string, "January 19th 2038 03:14:07.123456")
    }

    func test11ByteMySQLTimeParse() throws {
        let conn = try MySQLConnection.test(on: self.eventLoop).wait()
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
        let conn = try MySQLConnection.test(on: self.eventLoop).wait()
        defer { try! conn.close().wait() }

        let rows = try conn.query(#"SELECT DATE_FORMAT(?, "%H:%i:%s.%f") as x"#, [
            .init(time: .init(hour: 3, minute: 14, second: 7, microsecond: 123456))
        ]).wait()
        XCTAssertEqual(rows[0].column("x")?.string, "03:14:07.123456")
    }

    func test12ByteMySQLTimeParse() throws {
        let conn = try MySQLConnection.test(on: self.eventLoop).wait()
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
    
    func testNull() throws {
        let conn = try MySQLConnection.test(on: self.eventLoop).wait()
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
    
    // https://github.com/vapor/mysql-nio/issues/87
    func testUnexpectedPacketHandling() async throws {
        struct PingCommand: MySQLCommand {
            func handle(packet: inout MySQLPacket, capabilities: MySQLProtocol.CapabilityFlags) throws -> MySQLCommandState { preconditionFailure("") }
            func activate(capabilities: MySQLProtocol.CapabilityFlags) throws -> MySQLCommandState { .init(response: [.init(payload: .init(bytes: [0x0e]))], done: true) }
        }
        let conn = try await MySQLConnection.test(on: self.eventLoop).get()
        do {
            try await conn.send(PingCommand(), logger: conn.logger).get()
            try await Task.sleep(nanoseconds: 100_000_000) // to let the reply come in without any other command queued
            do {
                _ = try await conn.simpleQuery("SELECT 1").get()
                XCTFail("did not throw an error")
            } catch MySQLError.closed {
                // pass
            }
        } catch {
            XCTFail("threw an error: \(String(reflecting: error))")
        }
        try? await conn.close().get()
    }
    
    // https://github.com/vapor/mysql-nio/issues/91
    func testBeforeHandshakeErrorHandling() async throws {
        // There's no way to force a real server to throw a pre-handshake error, fake it with a mock server and a handcrafted ERR_Packet.
        let serverChannel = try await ServerBootstrap(group: self.eventLoopGroup)
            .serverChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SocketOptionName(SO_REUSEADDR)), value: SocketOptionValue(1))
            .childChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SocketOptionName(SO_REUSEADDR)), value: SocketOptionValue(1))
            .childChannelInitializer { channel in
                final class Handler: ChannelInboundHandler {
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
        do {
            let connection = try await MySQLConnection.connect(to: .init(ipAddress: "127.0.0.1", port: 3307), username: "", database: "", tlsConfiguration: nil, on: self.eventLoop).get()
            XCTFail("Should have thrown a server error.")
            try? await connection.close().get() // connection is *only* open if we get to this point
        } catch MySQLError.server(let err) {
            XCTAssertEqual(err.errorCode, .SERVER_GONE_ERROR)
            XCTAssertEqual(err.sqlStateMarker, "#")
            XCTAssertEqual(err.sqlState, "HY000")
            XCTAssertEqual(err.errorMessage, "Server gone")
        } catch {
            XCTFail("Threw something other than the expected error: \(String(reflecting: error))")
        }
        try? await serverChannel.close(mode: .all)
    }
}
