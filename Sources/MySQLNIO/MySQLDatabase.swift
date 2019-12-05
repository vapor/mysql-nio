public protocol MySQLDatabase {
    var eventLoop: EventLoop { get }
    var logger: Logger { get }
    func send(_ command: MySQLCommand, logger: Logger) -> EventLoopFuture<Void>
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
    
    public init(response: [MySQLPacket] = [], done: Bool = false, resetSequence: Bool = false) {
        self.response = response
        self.done = done
        self.resetSequence = resetSequence
    }
}

public protocol MySQLCommand {
    func handle(packet: inout MySQLPacket, capabilities: MySQLProtocol.CapabilityFlags) throws -> MySQLCommandState
    func activate(capabilities: MySQLProtocol.CapabilityFlags) throws -> MySQLCommandState
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
