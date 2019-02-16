extension MySQLConnection {
    public static func connect(to socketAddress: SocketAddress, on eventLoop: EventLoop) -> EventLoopFuture<MySQLConnection> {
        let bootstrap = ClientBootstrap(group: eventLoop)
            .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
        
        return bootstrap.connect(to: socketAddress).flatMap { channel in
            let sequence = MySQLPacketSequencer()
            return channel.pipeline.addHandlers([
                ByteToMessageHandler(MySQLPacketDecoder(sequence: sequence)),
                MySQLPacketEncoder(sequence: sequence),
                MySQLConnectionHandler()
            ], first: false).map {
                return MySQLConnection(channel: channel)
            }
        }
    }
}
