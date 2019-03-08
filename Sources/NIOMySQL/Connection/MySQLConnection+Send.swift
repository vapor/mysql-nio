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

enum MySQLCommandState {
    case response([MySQLPacket])
    case noResponse
    case done
}

protocol MySQLCommandHandler {
    func handle(packet: inout MySQLPacket, capabilities: MySQLProtocol.CapabilityFlags) throws -> MySQLCommandState
    func activate(capabilities: MySQLProtocol.CapabilityFlags) throws -> MySQLCommandState
}

struct MySQLCommand {
    var handler: MySQLCommandHandler
    var promise: EventLoopPromise<Void>
}
