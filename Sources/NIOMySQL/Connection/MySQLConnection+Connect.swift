import NIOSSL

extension MySQLConnection {
    public static func connect(
        to socketAddress: SocketAddress,
        username: String,
        database: String,
        password: String? = nil,
        tlsConfig: TLSConfiguration? = nil,
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
                    tlsConfig: tlsConfig,
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
}

final class ErrorHandler: ChannelInboundHandler {
    typealias InboundIn = Never
    
    init() { }
    
    func errorCaught(context: ChannelHandlerContext, error: Error) {
        assertionFailure("uncaught error: \(error)")
    }
}
