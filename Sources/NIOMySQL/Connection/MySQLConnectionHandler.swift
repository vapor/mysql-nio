import NIOSSL

final class MySQLConnectionHandler: ChannelDuplexHandler {
    typealias InboundIn = MySQLPacket
    typealias OutboundIn = MySQLCommand
    typealias OutboundOut = MySQLPacket
    
    enum State {
        case handshake(HandshakeState)
        case authenticating(AuthenticationState)
        case commandPhase
    }
    
    struct HandshakeState {
        let username: String
        let database: String
        let password: String?
        let tlsConfig: TLSConfiguration?
        let done: EventLoopPromise<Void>
    }
    
    struct AuthenticationState {
        var authPluginName: String
        var password: String?
        var isSecure: Bool
        var done: EventLoopPromise<Void>
    }
    
    var state: State
    var serverCapabilities: MySQLProtocol.CapabilityFlags?
    var queue: CircularBuffer<MySQLCommand>
    let sequence: MySQLPacketSequence
    
    init(state: State, sequence: MySQLPacketSequence) {
        self.state = state
        self.queue = .init()
        self.sequence = sequence
    }
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        var packet = self.unwrapInboundIn(data)
        switch self.state {
        case .handshake(let state):
            do {
                try self.handleHandshake(context: context, packet: &packet, state: state)
            } catch {
                state.done.fail(error)
            }
        case .authenticating(let state):
            do {
                try self.handleAuthentication(context: context, packet: &packet, state: state)
            } catch {
                state.done.fail(error)
            }
        case .commandPhase:
            if let current = self.queue.first {
                do {
                    let commandState = try current.handler.handle(packet: &packet, capabilities: self.serverCapabilities!)
                    self.handleCommandState(context: context, commandState)
                } catch {
                    self.queue.removeFirst()
                    current.promise.fail(error)
                }
            } else {
                assertionFailure("unhandled packet: \(packet)")
            }
        }
    }
    
    func handleHandshake(context: ChannelHandlerContext, packet: inout MySQLPacket, state: HandshakeState) throws {
        let handshakeRequest = try packet.decode(MySQLProtocol.HandshakeV10.self, capabilities: [])
        assert(handshakeRequest.capabilities.contains(.CLIENT_PROTOCOL_41), "Client protocol 4.1 required")
        self.serverCapabilities = handshakeRequest.capabilities
        switch state.tlsConfig {
        case .some(let tlsConfig):
            var capabilities = MySQLProtocol.CapabilityFlags.clientDefault
            capabilities.insert(.CLIENT_SSL)
            let sslRequest = MySQLProtocol.SSLRequest(
                capabilities: capabilities,
                maxPacketSize: 0,
                characterSet: .utf8mb4
            )
            let promise = context.channel.eventLoop.makePromise(of: Void.self)
            try context.write(self.wrapOutboundOut(.encode(sslRequest, capabilities: [])), promise: promise)
            context.flush()
            
            let sslContext = try NIOSSLContext(configuration: tlsConfig)
            let handler = try NIOSSLClientHandler(context: sslContext)
            promise.futureResult.flatMap {
                return context.channel.pipeline.addHandler(handler, position: .first).flatMapThrowing {
                    try self.writeHandshakeResponse(context: context, handshakeRequest: handshakeRequest, state: state)
                }
            }.whenFailure { error in
                state.done.fail(error)
            }
        case .none:
            try self.writeHandshakeResponse(context: context, handshakeRequest: handshakeRequest, state: state)
        }
    }
    
    func writeHandshakeResponse(
        context: ChannelHandlerContext,
        handshakeRequest: MySQLProtocol.HandshakeV10,
        state: HandshakeState
    ) throws {
        guard handshakeRequest.capabilities.contains(.CLIENT_SECURE_CONNECTION) else {
            throw MySQLError.unsupportedServer(message: "Pre-4.1 auth protocol is not supported or safe.")
        }
        guard let authPluginName = handshakeRequest.authPluginName else {
            throw MySQLError.unsupportedAuthPlugin(name: "<none>")
        }
        
        var password = ByteBufferAllocator().buffer(capacity: 0)
        if let passwordString = state.password {
            password.writeString(passwordString)
        }
        
        let hash: ByteBuffer
        switch authPluginName {
        case "caching_sha2_password":
            let seed = handshakeRequest.authPluginData
            hash = xor(sha256(password), sha256(sha256(sha256(password)), seed))
        case "mysql_native_password":
            var copy = handshakeRequest.authPluginData
            guard let salt = copy.readSlice(length: 20) else {
                throw MySQLError.protocolError
            }
            hash = xor(sha1(salt, sha1(sha1(password))), sha1(password))
        default:
            throw MySQLError.unsupportedAuthPlugin(name: authPluginName)
        }
        self.state = .authenticating(.init(
            authPluginName: authPluginName,
            password: state.password,
            isSecure: state.tlsConfig != nil,
            done: state.done
        ))
        let res = MySQLPacket.HandshakeResponse41(
            capabilities: .clientDefault,
            maxPacketSize: 0,
            characterSet: .utf8mb4,
            username: state.username,
            authResponse: hash,
            database: state.database,
            authPluginName: authPluginName
        )
        try context.write(self.wrapOutboundOut(.encode(res, capabilities: self.serverCapabilities!)), promise: nil)
        context.flush()
    }
    
    func handleAuthentication(
        context: ChannelHandlerContext,
        packet: inout MySQLPacket,
        state: AuthenticationState
    ) throws {
        switch state.authPluginName {
        case "caching_sha2_password":
            guard !packet.isOK else {
                self.state = .commandPhase
                state.done.succeed(())
                return
            }
            guard !packet.isError else {
                let err = try packet.decode(MySQLProtocol.ERR_Packet.self, capabilities: self.serverCapabilities!)
                throw MySQLError.server(err)
            }
            guard let status = packet.payload.readInteger(endianness: .little, as: UInt8.self) else {
                throw MySQLError.protocolError
            }
            switch status {
            case 0x01:
                guard let name = packet.payload.readInteger(endianness: .little, as: UInt8.self) else {
                    throw MySQLError.protocolError
                }
                switch name {
                case 0x04:
                    guard state.isSecure else {
                        throw MySQLError.secureConnectionRequired
                    }
                    var payload = ByteBufferAllocator().buffer(capacity: 0)
                    payload.writeNullTerminatedString(state.password ?? "")
                    context.write(self.wrapOutboundOut(MySQLPacket(payload: payload)), promise: nil)
                    context.flush()
                default:
                    throw MySQLError.protocolError
                }
            default:
                throw MySQLError.protocolError
            }
        case "mysql_native_password":
            guard !packet.isError else {
                let error = try packet.decode(MySQLProtocol.ERR_Packet.self, capabilities: self.serverCapabilities!)
                throw MySQLError.server(error)
            }
            guard packet.isOK else {
                throw MySQLError.protocolError
            }
            self.state = .commandPhase
            state.done.succeed(())
        default:
            throw MySQLError.unsupportedAuthPlugin(name: state.authPluginName)
        }
    }
    
    func write(context: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
        let request = self.unwrapOutboundIn(data)
        self.queue.append(request)
        
        // send initial
        do {
            self.sequence.current = nil
            let commandState = try request.handler.activate(capabilities: self.serverCapabilities!)
            self.handleCommandState(context: context, commandState)
        } catch {
            self.queue.removeFirst()
            request.promise.fail(error)
        }
        
        // write is complete
        promise?.succeed(())
    }
    
    func handleCommandState(context: ChannelHandlerContext, _ commandState: MySQLCommandState) {
        switch commandState {
        case .done:
            let current = self.queue.removeFirst()
            current.promise.succeed(())
        case .noResponse:
            break
        case .response(let packets):
            for packet in packets {
                context.write(self.wrapOutboundOut(packet), promise: nil)
            }
            context.flush()
        }
    }
    
    func close(context: ChannelHandlerContext, mode: CloseMode, promise: EventLoopPromise<Void>?) {
        do {
            try self._close(context: context, mode: mode, promise: promise)
        } catch {
            self.errorCaught(context: context, error: error)
        }
    }
    
    private func _close(context: ChannelHandlerContext, mode: CloseMode, promise: EventLoopPromise<Void>?) throws {
        try context.write(self.wrapOutboundOut(.encode(MySQLProtocol.COM_QUIT(), capabilities: self.serverCapabilities!)), promise: nil)
        context.flush()
        context.close(mode: mode, promise: promise)
    }
    
    func channelInactive(context: ChannelHandlerContext) {
        while let next = self.queue.popLast() {
            next.promise.fail(MySQLError.closed)
        }
    }
    
    func errorCaught(context: ChannelHandlerContext, error: Error) {
        if let current = self.queue.first {
            self.queue.removeFirst()
            current.promise.fail(error)
        }
    }
}
