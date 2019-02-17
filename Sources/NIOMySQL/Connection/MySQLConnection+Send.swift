extension MySQLConnection {
    public func send(_ command: MySQLCommandHandler) -> EventLoopFuture<Void> {
        let promise = self.eventLoop.makePromise(of: Void.self)
        let c = MySQLCommand(
            handler: command,
            promise: promise
        )
        return self.channel.write(c)
            .flatMap { promise.futureResult }
    }
}

public protocol MySQLCommandHandler {
    func handle(packet: inout MySQLPacket, ctx: MySQLRequestContext) throws
    func activate(ctx: MySQLRequestContext) throws
}

extension MySQLCommandHandler {
    public func activate(ctx: MySQLRequestContext) { }
}

struct MySQLCommand {
    var handler: MySQLCommandHandler
    var promise: EventLoopPromise<Void>
}

public struct MySQLRequestContext {
    let ctx: ChannelHandlerContext
    let handler: MySQLConnectionHandler
    
    init(_ ctx: ChannelHandlerContext, _ handler: MySQLConnectionHandler) {
        self.ctx = ctx
        self.handler = handler
    }
    
    public func succeed() {
        let current = self.handler.queue.removeFirst()
        current.promise.succeed(())
    }
    
    public func flush() {
        ctx.flush()
    }
    
    public func write(_ packet: MySQLPacket) {
        self.ctx.write(NIOAny(packet), promise: nil)
        self.ctx.flush()
    }
}
