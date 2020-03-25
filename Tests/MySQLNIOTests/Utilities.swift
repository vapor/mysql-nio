import MySQLNIO
import NIOSSL

extension MySQLConnection {
    static func test(on eventLoop: EventLoop) -> EventLoopFuture<MySQLConnection> {
        let addr: SocketAddress
        do {
            addr = try SocketAddress.makeAddressResolvingHost(env("MYSQL_HOSTNAME") ?? "localhost", port: 3306)
        } catch {
            return eventLoop.makeFailedFuture(error)
        }
        return self.connect(
            to: addr,
            username: "vapor_username",
            database: "vapor_database",
            password: "vapor_password",
            tlsConfiguration: .forClient(certificateVerification: .none),
            on: eventLoop
        )
    }
}

private func env(_ name: String) -> String? {
    getenv(name).flatMap { String(cString: $0) }
}
