extension MySQLConnection {
    public func requestTLS(
        config tlsConfig: TLSConfiguration = .forClient()
    ) -> EventLoopFuture<Void> {
        return self.send(MySQLTLSRequest()).flatMapThrowing {
            let sslContext = try SSLContext(configuration: tlsConfig)
            let handler = try OpenSSLClientHandler(context: sslContext)
            _ = self.channel.pipeline.add(handler: handler, first: true)
        }
    }
}

private final class MySQLTLSRequest: MySQLRequestHandler {
    enum State {
        case nascent
        case waiting(MySQLCapabilityFlags)
    }
    
    var state: State
    
    init() {
        self.state = .nascent
    }
    
    func handle(packet: inout MySQLPacket, ctx: MySQLRequestContext) throws {
        switch self.state {
        case .nascent:
            #warning("TODO: make character set configurable")
            let handshake = try packet.handshake()
            let sslRequest = MySQLPacket.SSLRequest(
                capabilities: handshake.capabilities,
                maxPacketSize: 0,
                characterSet: .utf8mb4
            )
            self.state = .waiting(handshake.capabilities)
            ctx.write(.init(sslRequest))
            ctx.succeed()
        case .waiting(let capabilities):
            guard !packet.isError else {
                let err = try packet.err(capabilities: capabilities)
                throw MySQLError.server(err)
            }
        }
    }
}
