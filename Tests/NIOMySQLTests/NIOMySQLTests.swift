import XCTest
import NIOMySQL

final class NIOMySQLTests: XCTestCase {
    private var group: EventLoopGroup!
    private var eventLoop: EventLoop {
        return self.group.next()
    }
    
    func testExample() throws {
        let conn = try MySQLConnection.test(on: self.eventLoop).wait()
        sleep(1)
        try conn.close().wait()
    }
    
    static var allTests = [
        ("testExample", testExample),
    ]
    
    override func setUp() {
        self.group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    }
    
    override func tearDown() {
        try! self.group.syncShutdownGracefully()
    }
}
