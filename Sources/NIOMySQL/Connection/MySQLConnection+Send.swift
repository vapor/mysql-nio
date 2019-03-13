extension MySQLConnection {
    func send(_ command: MySQLCommandHandler) -> EventLoopFuture<Void> {
        let promise = self.eventLoop.makePromise(of: Void.self)
        let c = MySQLCommand(
            handler: command,
            promise: promise
        )
        return self.channel.write(c)
            .flatMap { promise.futureResult }
    }
}

struct MySQLCommandState {
    static var noResponse: MySQLCommandState {
        return .init()
    }
    
    static var done: MySQLCommandState {
        return .init(done: true)
    }
    
    static func response(_ packets: [MySQLPacket]) -> MySQLCommandState {
        return .init(response: packets)
    }
    
    var response: [MySQLPacket]
    var done: Bool
    var resetSequence: Bool
    
    init(response: [MySQLPacket] = [], done: Bool = false, resetSequence: Bool = false) {
        self.response = response
        self.done = done
        self.resetSequence = resetSequence
    }
}

protocol MySQLCommandHandler {
    func handle(packet: inout MySQLPacket, capabilities: MySQLProtocol.CapabilityFlags) throws -> MySQLCommandState
    func activate(capabilities: MySQLProtocol.CapabilityFlags) throws -> MySQLCommandState
}

struct MySQLCommand {
    var handler: MySQLCommandHandler
    var promise: EventLoopPromise<Void>
}
