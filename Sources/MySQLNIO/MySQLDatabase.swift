import Logging
import NIOCore

public protocol MySQLDatabase {
    var eventLoop: any EventLoop { get }
    var logger: Logger { get }
    func send(_ command: any MySQLCommand, logger: Logger) -> EventLoopFuture<Void>
    func withConnection<T>(_ closure: @escaping (MySQLConnection) -> EventLoopFuture<T>) -> EventLoopFuture<T>
}

public struct MySQLCommandState {
    static var noResponse: MySQLCommandState {
        return .init()
    }
    
    static var done: MySQLCommandState {
        return .init(done: true)
    }
    
    static func response(_ packets: [MySQLPacket]) -> MySQLCommandState {
        return .init(response: packets)
    }
    
    let response: [MySQLPacket]
    let done: Bool
    let resetSequence: Bool
    var error: Error?
    
    public init(
        response: [MySQLPacket] = [],
        done: Bool = false,
        resetSequence: Bool = false,
        error: Error? = nil
    ) {
        self.response = response
        self.done = done
        self.resetSequence = resetSequence
        self.error = error
    }
}

public protocol MySQLCommand: Sendable {
    func handle(packet: inout MySQLPacket, capabilities: MySQLProtocol.CapabilityFlags) throws -> MySQLCommandState
    func activate(capabilities: MySQLProtocol.CapabilityFlags) throws -> MySQLCommandState
}


extension MySQLDatabase {
    public func logging(to logger: Logger) -> any MySQLDatabase {
        _MySQLDatabaseWithLogger(database: self, logger: logger)
    }
}

private struct _MySQLDatabaseWithLogger {
    let database: any MySQLDatabase
    let logger: Logger
}

extension _MySQLDatabaseWithLogger: MySQLDatabase {
    var eventLoop: any EventLoop {
        self.database.eventLoop
    }
    
    func send(_ command: any MySQLCommand, logger: Logger) -> EventLoopFuture<Void> {
        self.database.send(command, logger: logger)
    }
    
    func withConnection<T>(_ closure: @escaping (MySQLConnection) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        self.database.withConnection(closure)
    }
}
