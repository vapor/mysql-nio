import MySQLNIO
import NIOSSL

extension MySQLConnection {
    static func test(on eventLoop: EventLoop) -> EventLoopFuture<MySQLConnection> {
        let addr: SocketAddress
        do {
            addr = try SocketAddress.makeAddressResolvingHost(
                env("MYSQL_HOSTNAME") ?? "localhost",
                port: env("MYSQL_PORT").flatMap(Int.init) ?? 3306
            )
        } catch {
            return eventLoop.makeFailedFuture(error)
        }
        var tls = TLSConfiguration.makeClientConfiguration()
        tls.certificateVerification = .none
        return self.connect(
            to: addr,
            username: env("MYSQL_USERNAME") ?? "vapor_username",
            database: env("MYSQL_DATABASE") ?? "vapor_database",
            password: env("MYSQL_PASSWORD") ?? "vapor_password",
            tlsConfiguration: tls,
            on: eventLoop
        )
    }
}
