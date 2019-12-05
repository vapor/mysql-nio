import MySQLNIO
import NIOSSL

extension MySQLConnection {
    static func test(on eventLoop: EventLoop) -> EventLoopFuture<MySQLConnection> {
        do {
            return try self.connect(
                to: .makeAddressResolvingHost(env("MYSQL_HOSTNAME") ?? "localhost", port: 3306),
                username: "vapor_username",
                database: "vapor_database",
                password: "vapor_password",
                tlsConfiguration: .forClient(certificateVerification: .none),
                on: eventLoop
            )
        } catch {
            return eventLoop.makeFailedFuture(error)
        }
    }
}

private func env(_ name: String) -> String? {
    getenv(name).flatMap { String(cString: $0) }
}
