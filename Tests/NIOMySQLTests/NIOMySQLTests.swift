import XCTest
@testable import NIOMySQL

final class NIOMySQLTests: XCTestCase {
    private var group: EventLoopGroup!
    private var eventLoop: EventLoop {
        return self.group.next()
    }
    
    func testExample() throws {
        let conn = try MySQLConnection.test(on: self.eventLoop).wait()
        defer { try! conn.close().wait() }
        let rows = try conn.simpleQuery("SELECT 'foo' as bar").wait()
        XCTAssertEqual(rows.description, #"[["bar": "foo"]]"#)
        XCTAssertEqual(rows[0].column("bar")?.string, "foo")
    }
    
    func testExample2() throws {
        let conn = try MySQLConnection.test(on: self.eventLoop).wait()
        defer { try! conn.close().wait() }
        let rows = try conn.simpleQuery("SELECT 1 as one, 2 as two").wait()
        XCTAssertEqual(rows[0].column("one")?.string, "1")
        XCTAssertEqual(rows[0].column("two")?.string, "2")
    }
    
    func testPerformance() throws {
        let conn = try! MySQLConnection.test(on: self.eventLoop).wait()
        defer { try! conn.close().wait() }
        for _ in 0..<1_000 {
            _ = try! conn.simpleQuery("SELECT 1").wait()
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
    
    static var allTests = [
        ("testExample", testExample),
        ("testSHA2", testSHA2),
    ]
    
    override func setUp() {
        self.group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    }
    
    override func tearDown() {
        try! self.group.syncShutdownGracefully()
    }
}
