@_exported import struct NIOSSL.TLSConfiguration

public final class MySQLConnection: MySQLDatabase {
    public static func connect(
        to socketAddress: SocketAddress,
        username: String,
        database: String,
        password: String? = nil,
        tlsConfiguration: TLSConfiguration? = nil,
        on eventLoop: EventLoop
    ) -> EventLoopFuture<MySQLConnection> {
        let bootstrap = ClientBootstrap(group: eventLoop)
            .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
        
        return bootstrap.connect(to: socketAddress).flatMap { channel in
            let sequence = MySQLPacketSequence()
            let done = channel.eventLoop.makePromise(of: Void.self)
            done.futureResult.whenFailure { _ in
                channel.close(mode: .all, promise: nil)
            }
            return channel.pipeline.addHandlers([
                ByteToMessageHandler(MySQLPacketDecoder(sequence: sequence)),
                MessageToByteHandler(MySQLPacketEncoder(sequence: sequence)),
                MySQLConnectionHandler(state: .handshake(.init(
                    username: username,
                    database: database,
                    password: password,
                    tlsConfiguration: tlsConfiguration,
                    done: done
                )), sequence: sequence),
                ErrorHandler()
                ], position: .last).map {
                    return MySQLConnection(channel: channel)
                }.flatMap { conn in
                    return done.futureResult.map { conn }
            }
        }
    }
    
    public let channel: Channel
    
    public var eventLoop: EventLoop {
        return self.channel.eventLoop
    }
    
    public var isClosed: Bool {
        return !self.channel.isActive
    }
    
    internal init(channel: Channel) {
        self.channel = channel
    }
    
    public func close() -> EventLoopFuture<Void> {
        guard self.channel.isActive else {
            return self.channel.eventLoop.makeSucceededFuture(())
        }
        return self.channel.close(mode: .all)
    }
    
    public func send(_ command: MySQLCommand) -> EventLoopFuture<Void> {
        let promise = self.eventLoop.makePromise(of: Void.self)
        let c = MySQLCommandContext(
            handler: command,
            promise: promise
        )
        return self.channel.write(c)
            .flatMap { promise.futureResult }
    }
    
    deinit {
        assert(!self.channel.isActive, "MySQLConnection not closed before deinit.")
    }
}

final class ErrorHandler: ChannelInboundHandler {
    typealias InboundIn = Never
    
    init() { }
    
    func errorCaught(context: ChannelHandlerContext, error: Error) {
        assertionFailure("uncaught error: \(error)")
    }
}
