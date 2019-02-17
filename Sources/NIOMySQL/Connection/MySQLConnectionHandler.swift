extension MySQLConnection {
    public func send(_ delegate: MySQLConnectionRequestDelegate) -> EventLoopFuture<Void> {
        let promise = self.eventLoop.makePromise(of: Void.self)
        let req = MySQLConnectionRequest(
            delegate: delegate,
            promise: promise
        )
        return self.channel.write(req)
            .flatMap { promise.futureResult }
    }
}

final class MySQLConnectionHandler: ChannelDuplexHandler {
    typealias InboundIn = MySQLPacket
    typealias OutboundIn = MySQLConnectionRequest
    typealias OutboundOut = MySQLPacket
    
    var queue: CircularBuffer<MySQLConnectionRequest>
    var buffer: [MySQLPacket]

    
    init() {
        self.queue = .init()
        self.buffer = .init()
    }
    
    func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {
        do {
            try self.channelReadThrowing(ctx: ctx, data: data)
        } catch {
            self.errorCaught(ctx: ctx, error: error)
        }
    }
    
    func channelReadThrowing(ctx: ChannelHandlerContext, data: NIOAny) throws {
        var packet = self.unwrapInboundIn(data)
        if let current = self.queue.first {
            if let output = try current.delegate.handle(&packet) {
                for packet in output {
                    ctx.write(self.wrapOutboundOut(packet), promise: nil)
                }
                ctx.flush()
            } else {
                self.queue.removeFirst()
                current.promise.succeed(())
            }
        } else {
            self.buffer.append(packet)
        }
    }
    
    func write(ctx: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
        let request = self.unwrapOutboundIn(data)
        self.queue.append(request)
        
        // replay
        let buffer = self.buffer
        self.buffer = []
        for packet in buffer {
            self.channelRead(ctx: ctx, data: self.wrapOutboundOut(packet))
        }
        
        // send initial
        for packet in request.delegate.initial() {
            ctx.write(self.wrapOutboundOut(packet), promise: nil)
            ctx.flush()
        }
        
        // special quite case
        if request.delegate.isQuit {
            self.queue.removeFirst()
            request.promise.succeed(())
        }

        // write is complete
        promise?.succeed(())
    }
    
    func errorCaught(ctx: ChannelHandlerContext, error: Error) {
        if let current = self.queue.first {
            self.queue.removeFirst()
            current.promise.fail(error)
        }
    }
}


public protocol MySQLConnectionRequestDelegate {
    func handle(_ packet: inout MySQLPacket) throws -> [MySQLPacket]?
    func initial() -> [MySQLPacket]
    var isQuit: Bool { get }
}

extension MySQLConnectionRequestDelegate {
    public var isQuit: Bool { return false }
}

struct MySQLConnectionRequest {
    var delegate: MySQLConnectionRequestDelegate
    var promise: EventLoopPromise<Void>
}
