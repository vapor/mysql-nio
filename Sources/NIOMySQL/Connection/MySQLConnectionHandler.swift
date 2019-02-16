final class MySQLConnectionHandler: ChannelInboundHandler {
    typealias InboundIn = MySQLPacket
    typealias OutboundOut = MySQLPacket
    
    enum State {
        case nascent
        case ready
    }
    
    var state: State
    
    init() {
        self.state = .nascent
    }
    
    func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {
        var packet = self.unwrapInboundIn(data)
        switch self.state {
        case .nascent:
            let req = try! packet.handshake()
            print(req)
            let res = MySQLPacket.HandshakeResponse(
                capabilities: .clientDefault,
                maxPacketSize: 0,
                characterSet: .utf8mb4,
                username: "vapor_username",
                authResponse: ByteBufferAllocator().buffer(capacity: 0),
                database: "vapor_database",
                authPluginName: "foo"
            )
            self.state = .ready
            ctx.write(self.wrapOutboundOut(.init(res)), promise: nil)
            ctx.flush()
        case .ready:
            print("unimplemented: \(packet)")
        }
    }
}
