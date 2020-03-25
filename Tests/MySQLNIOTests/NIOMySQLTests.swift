import XCTest
import Logging
@testable import MySQLNIO

final class NIOMySQLTests: XCTestCase {
    private var group: EventLoopGroup!
    private var eventLoop: EventLoop {
        return self.group.next()
    }
    
    func testDecodingSumOfIntsWithNoRows() throws {
        let conn = try MySQLConnection.test(on: self.eventLoop).wait()
        defer { try! conn.close().wait() }
        let dropResults = try conn.simpleQuery("DROP TABLE IF EXISTS foos").wait()
        XCTAssertEqual(dropResults.count, 0)
        let createResults = try conn.simpleQuery("CREATE TABLE foos (`item_count` int(11))").wait()
        XCTAssertEqual(createResults.count, 0)
        let rows = try conn.simpleQuery("SELECT sum(`item_count`) as sum from foos").wait()
        guard rows.count == 1 else {
            XCTFail("invalid row count")
            return
        }
        if let sqlData = rows[0].column("sum") {
            XCTAssertEqual(sqlData.string, nil)
            XCTAssertEqual(sqlData.float, nil)
            XCTAssertEqual(sqlData.double, nil)
            XCTAssertEqual(sqlData.int, nil)
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
        let _ = try conn.simpleQuery("insert into foos (`item_count`) values (0)").wait()
        let rows = try conn.simpleQuery("SELECT sum(`item_count`) as sum from foos").wait()
        guard rows.count == 1 else {
            XCTFail("invalid row count")
            return
        }
        if let sqlData = rows[0].column("sum") {
            XCTAssertEqual(sqlData.string, "0")
            XCTAssertEqual(sqlData.float, 0)
            XCTAssertEqual(sqlData.double, 0)
            XCTAssertEqual(sqlData.int, 0)
        } else {
            XCTAssert(false, "rows[0].column(\"sum\") was nil")
        }
        let _ = try conn.simpleQuery("insert into foos (`item_count`) values (199)").wait()
        let rows2 = try conn.simpleQuery("SELECT sum(`item_count`) as sum from foos").wait()
        guard rows2.count == 1 else {
            XCTFail("invalid row count")
            return
        }
        if let sqlData = rows2[0].column("sum") {
            XCTAssertEqual(sqlData.string, "199")
            XCTAssertEqual(sqlData.float, 199)
            XCTAssertEqual(sqlData.double, 199)
            XCTAssertEqual(sqlData.int, 199)
        } else {
            XCTAssert(false, "rows[0].column(\"sum\") was nil")
        }
    }

    func testSimpleQuery_selectVersion() throws {
        let conn = try MySQLConnection.test(on: self.eventLoop).wait()
        defer { try! conn.close().wait() }
        let rows = try conn.simpleQuery("SELECT @@version").wait()
        guard rows.count == 1 else {
            XCTFail("invalid row count")
            return
        }
        XCTAssert(rows[0].column("@@version")?.string?.contains(".") == true)
    }
    
    func testSimpleQuery_selectString() throws {
        let conn = try MySQLConnection.test(on: self.eventLoop).wait()
        defer { try! conn.close().wait() }
        let rows = try conn.simpleQuery("SELECT 'foo' as bar").wait()
        guard rows.count == 1 else {
            XCTFail("invalid row count")
            return
        }
        XCTAssertEqual(rows.description, #"[["bar": "foo"]]"#)
        XCTAssertEqual(rows[0].column("bar")?.string, "foo")
    }
    
    func testSimpleQuery_selectIntegers() throws {
        let conn = try MySQLConnection.test(on: self.eventLoop).wait()
        defer { try! conn.close().wait() }
        let rows = try conn.simpleQuery("SELECT 1 as one, 2 as two").wait()
        guard rows.count == 1 else {
            XCTFail("invalid row count")
            return
        }
        XCTAssertEqual(rows[0].column("one")?.string, "1")
        XCTAssertEqual(rows[0].column("two")?.string, "2")
    }
    
    func testSimpleQuery_syntaxError() throws {
        let conn = try MySQLConnection.test(on: self.eventLoop).wait()
        defer { try! conn.close().wait() }
        do {
            _ = try conn.simpleQuery("SELECT &").wait()
            XCTFail("should have thrown")
        } catch let error as MySQLError {
            switch error {
            case .server(let packet):
                XCTAssertEqual(packet.errorCode, .PARSE_ERROR)
            default:
                XCTFail("unexpected error type")
            }
        }
    }
    
    func testQuery_syntaxError() throws {
        let conn = try MySQLConnection.test(on: self.eventLoop).wait()
        defer { try! conn.close().wait() }
        do {
            _ = try conn.query("SELECT &").wait()
            XCTFail("should have thrown")
        } catch let error as MySQLError {
            switch error {
            case .server(let packet):
                XCTAssertEqual(packet.errorCode, .PARSE_ERROR)
            default:
                XCTFail("unexpected error type")
            }
        }
    }
    
    func testQuery_selectMixed() throws {
        let conn = try MySQLConnection.test(on: self.eventLoop).wait()
        defer { try! conn.close().wait() }
        let rows = try! conn.query("SELECT '1' as one, 2 as two").wait()
        guard rows.count == 1 else {
            XCTFail("invalid row count")
            return
        }
        XCTAssertEqual(rows[0].column("one")?.string, "1")
        XCTAssertEqual(rows[0].column("two")?.string, "2")
    }
    
    func testQuery_selectBoundParams() throws {
        let conn = try MySQLConnection.test(on: self.eventLoop).wait()
        defer { try! conn.close().wait() }
        let rows = try! conn.query("SELECT ? as one, ? as two", ["1", "2"]).wait()
        guard rows.count == 1 else {
            XCTFail("invalid row count")
            return
        }
        XCTAssertEqual(rows[0].column("one")?.string, "1")
        XCTAssertEqual(rows[0].column("two")?.string, "2")
    }
    
    func testQuery_selectConcat() throws {
        let conn = try MySQLConnection.test(on: self.eventLoop).wait()
        defer { try! conn.close().wait() }
        let rows = try conn.query("SELECT CONCAT(?, ?) as test;", ["hello", "world"]).wait()
        guard rows.count == 1 else {
            XCTFail("invalid row count")
            return
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
        let insertResults = try conn.query("INSERT INTO foos VALUES (?, ?)", [-1, "vapor"]).wait()
        XCTAssertEqual(insertResults.count, 0)
        let selectResults = try conn.query("SELECT * FROM foos WHERE name = ?", ["vapor"]).wait()
        guard selectResults.count == 1 else {
            XCTFail("invalid row count")
            return
        }
        XCTAssertEqual(selectResults[0].column("id")?.int, -1)
        XCTAssertEqual(selectResults[0].column("name")?.string, "vapor")
        
        // test double parameterized query
        let selectResults2 = try conn.query("SELECT * FROM foos WHERE name = ?", ["vapor"]).wait()
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
        let insertResults = try conn.query("INSERT INTO foos (name) VALUES (?)", ["vapor"]) { metadata in
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
        let time = mysqlDate.date
        XCTAssertNotEqual(mysqlDate.microsecond, 0)
        
        XCTAssertEqual(
            Double(date.timeIntervalSinceReferenceDate),
            Double(time.timeIntervalSinceReferenceDate),
            accuracy: 5
        )
    }
 
    func testDate_before1970() throws {
        let time = MySQLTime(date: MySQLTime(date: Date(timeIntervalSince1970: 1.1)).date)
        let time2 = MySQLTime(date: MySQLTime(date: Date(timeIntervalSince1970: -1.1)).date)
        
        XCTAssert(time.microsecond == UInt32(100000))
        XCTAssert(time2.microsecond == UInt32(100000))
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
                        XCTAssertEqual(data.description, value.description, name, file: file, line: line)
                    } else {
                        XCTFail("Data null", file: file, line: line)
                    }
                }
            }
        }
        var hello3 = ByteBufferAllocator().buffer(capacity: 0)
        hello3.writeString("hello3")
        let tests: [TestColumn] = [
            .init("xchar", "CHAR(60)", "hello1"),
            .init("xvarchar", "VARCHAR(61)", "hello2"),
            .init("xtext", "TEXT(62)", MySQLData(type: .blob, buffer: hello3)),
            .init("xbinary", "BINARY(6)", "hello4"),
            .init("xvarbinary", "VARBINARY(66)", "hello5"),
            .init("xbit", "BIT", true),
            .init("xtinyint", "TINYINT(1)", 5),
            .init("xsmallint", "SMALLINT(1)", 252),
            .init("xvarcharnull", "VARCHAR(10)", MySQLData(type: .varString, buffer: nil)),
            .init("xmediumint", "MEDIUMINT(1)", 1024),
            .init("xinteger", "INTEGER(1)", 1024293),
            .init("xbigint", "BIGINT(1)", 234234234),
            .init("name", "VARCHAR(10) NOT NULL", "vapor"),
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
        
        /// insert data
        let placeholders = tests.map { _ in "?" }.joined(separator: ", ")
        let insertResults = try conn.query("INSERT INTO kitchen_sink VALUES (\(placeholders));", tests.map { $0.data }).wait()
        XCTAssertEqual(insertResults.count, 0)
        
        // select data
        let selectResults = try conn.query("SELECT * FROM kitchen_sink WHERE name = ?;", ["vapor"]).wait()
        XCTAssertEqual(selectResults.count, 1)
        
        for test in tests {
            try test.match(selectResults[0].column(test.name), #file, #line)
        }
    }
    
    func testPerformance_simpleSelects() throws {
        let conn = try MySQLConnection.test(on: self.eventLoop).wait()
        defer { try! conn.close().wait() }
        for _ in 0..<1_000 {
            _ = try! conn.simpleQuery("SELECT 1").wait()
        }
    }
    
    func testPerformance_parseDatetime() throws {
        let conn = try MySQLConnection.test(on: self.eventLoop).wait()
        defer { try! conn.close().wait() }
        
        measure {
            for _ in 0..<100 {
                let rows = try! conn.query("SELECT CAST('2016-01-18' AS DATETIME) as datetime").wait()
                XCTAssertEqual(rows[0].column("datetime")?.date?.description, "2016-01-18 00:00:00 +0000")
            }
        }
    }
    
    func testSHA2() throws {
        var message = ByteBufferAllocator().buffer(capacity: 0)
        message.writeString("vapor")
        var digest = sha256(message)
        XCTAssertEqual(digest.readBytes(length: 32), [
            0xFB, 0x7A, 0xE6, 0x94, 0xBA, 0x3F, 0xD9, 0x0A, 0xE3, 0x90, 0x9C, 0xCC, 0xCD, 0x0B, 0xE0, 0xDA,
            0xE9, 0x88, 0xE7, 0x02, 0x96, 0xD7, 0x09, 0x9B, 0xC5, 0x70, 0x8A, 0x87, 0x2F, 0x4C, 0xC1, 0x72
        ])
    }

    func testQuery_decimal() throws {
        let conn = try MySQLConnection.test(on: self.eventLoop).wait()
        defer { try! conn.close().wait() }
        do {
            let rows = try conn.query("SELECT '3.1415926' as d").wait()
            XCTAssertEqual(rows[0].column("d").flatMap { Decimal(mysqlData: $0) }?.description, "3.1415926")
        }
    }
    
    override func setUpWithError() throws {
        XCTAssert(isLoggingConfigured)
        self.group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    }
    
    override func tearDownWithError() throws {
        try self.group.syncShutdownGracefully()
    }
}

let isLoggingConfigured: Bool = {
    LoggingSystem.bootstrap { label in
        var handler = StreamLogHandler.standardOutput(label: label)
        handler.logLevel = .debug
        return handler
    }
    return true
}()
