extension MySQLConnection {
    public static func connect(to socketAddress: SocketAddress, on eventLoop: EventLoop) -> EventLoopFuture<MySQLConnection> {
        let bootstrap = ClientBootstrap(group: eventLoop)
            .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
        
        return bootstrap.connect(to: socketAddress).flatMap { channel in
            let sequence = MySQLPacketSequence()
            return channel.pipeline.addHandlers([
                ByteToMessageHandler(MySQLPacketDecoder(sequence: sequence)),
                MySQLPacketEncoder(sequence: sequence),
                MySQLConnectionHandler(),
                ErrorHandler()
            ], first: false).map {
                return MySQLConnection(channel: channel)
            }
        }
    }
}

final class ErrorHandler: ChannelInboundHandler {
    typealias InboundIn = Never
    
    init() { }
    
    func errorCaught(ctx: ChannelHandlerContext, error: Error) {
        fatalError("uncaught error: \(error)")
    }
}
