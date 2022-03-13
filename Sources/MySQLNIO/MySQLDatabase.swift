import Logging
import NIOCore

public protocol MySQLDatabase {
    var eventLoop: EventLoop { get }
    var logger: Logger { get }
    func send(_ command: MySQLCommand, logger: Logger) -> EventLoopFuture<Void>
    func withConnection<T>(_ closure: @escaping (MySQLConnection) -> EventLoopFuture<T>) -> EventLoopFuture<T>
}

extension MySQLDatabase {
    public func logging(to logger: Logger) -> MySQLDatabase {
        _MySQLDatabaseWithLogger(database: self, logger: logger)
    }
}

private struct _MySQLDatabaseWithLogger {
    let database: MySQLDatabase
    let logger: Logger
}

extension _MySQLDatabaseWithLogger: MySQLDatabase {
    var eventLoop: EventLoop {
        self.database.eventLoop
    }
    
    func send(_ command: MySQLCommand, logger: Logger) -> EventLoopFuture<Void> {
        self.database.send(command, logger: logger)
    }
    
    func withConnection<T>(_ closure: @escaping (MySQLConnection) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        self.database.withConnection(closure)
    }
}
