import MySQLNIO
import NIOSSL
import NIOCore
import Logging
import class Foundation.ProcessInfo

extension MySQLConnection {
    static func test(on eventLoop: any EventLoop) -> EventLoopFuture<MySQLConnection> {
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
            username: env("MYSQL_USERNAME") ?? "test_username",
            database: env("MYSQL_DATABASE") ?? "test_database",
            password: env("MYSQL_PASSWORD") ?? "test_password",
            tlsConfiguration: tls,
            on: eventLoop
        )
    }
    
    static func connect(
            to socketAddress: SocketAddress,
            username: String,
            database: String,
            password: String? = nil,
            tlsConfiguration: TLSConfiguration? = .makeClientConfiguration(),
            serverHostname: String? = nil,
            logger: Logger = .init(label: "codes.vapor.mysql")
        ) -> EventLoopFuture<MySQLConnection> {
            Self.connect(
                to: socketAddress,
                username: username,
                database: database,
                password: password,
                tlsConfiguration: tlsConfiguration,
                serverHostname: serverHostname,
                on: MultiThreadedEventLoopGroup.singleton.any()
            )
        }
}

let isLoggingConfigured: Bool = {
    LoggingSystem.bootstrap { label in
        var handler = StreamLogHandler.standardOutput(label: label)
        handler.logLevel = env("LOG_LEVEL").flatMap { Logger.Level(rawValue: $0) } ?? .info
        return handler
    }
    return true
}()

func env(_ name: String) -> String? {
    ProcessInfo.processInfo.environment[name]
}
