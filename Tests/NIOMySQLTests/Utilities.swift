import NIOMySQL

extension MySQLConnection {
    static func test(on eventLoop: EventLoop) -> EventLoopFuture<MySQLConnection> {
        do {
            let address: SocketAddress
            // socket:
            // try .init(unixDomainSocketPath: "/tmp/mysqld.sock")
            #if os(Linux)
            address = try .makeAddressResolvingHost("mysql", port: 3306)
            #else
            address = try .init(ipAddress: "127.0.0.1", port: 3306)
            #endif
            return connect(to: address, on: eventLoop)
        } catch {
            return eventLoop.makeFailedFuture(error)
        }
    }
}
