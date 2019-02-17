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
            return self.connect(
                to: address,
                username: "vapor_username",
                database: "vapor_database",
                password: "vapor_password",
                // tlsConfig: .forClient(certificateVerification: .none),
                on: eventLoop
            )
        } catch {
            return eventLoop.makeFailedFuture(error)
        }
    }
}
/*
 .flatMap {
 return conn.authenticate(
 username: "vapor_username",
 database: "vapor_database",
 password: "vapor_password"
 )
 }.map { conn }
 */
