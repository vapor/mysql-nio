import NIOMySQL
import NIOSSL

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
            let tlsConfiguration: TLSConfiguration?
            #if TEST_TLS
            tlsConfiguration = .forClient(certificateVerification: .none)
            #else
            tlsConfiguration = nil
            #endif
            return self.connect(
                to: address,
                username: "vapor_username",
                database: "vapor_database",
                password: "vapor_password",
                tlsConfiguration: tlsConfiguration,
                on: eventLoop
            )
        } catch {
            return eventLoop.makeFailedFuture(error)
        }
    }
}
