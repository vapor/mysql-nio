extension MySQLConnection {
    public static func connect(to socketAddress: SocketAddress, on eventLoop: EventLoop) -> EventLoopFuture<MySQLConnection> {
        let bootstrap = ClientBootstrap(group: eventLoop)
            .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
        
        return bootstrap.connect(to: socketAddress).flatMap { channel in
            let state = MySQLConnectionState()
            return channel.pipeline.addHandlers([
                ByteToMessageHandler(MySQLPacketDecoder(state: state)),
                MySQLPacketEncoder(state: state),
                MySQLConnectionHandler()
            ], first: false).map {
                return MySQLConnection(channel: channel)
            }
        }
    }
}

public final class MySQLConnectionState {
    public var currentSequenceID: UInt8
    
    public init() {
        self.currentSequenceID = 0
    }
    
    public func nextSequenceID() -> UInt8 {
        self.currentSequenceID = self.currentSequenceID &+ 1
        return self.currentSequenceID
    }
}
