final class MySQLConnectionHandler: ChannelDuplexHandler {
    typealias InboundIn = MySQLPacket
    typealias OutboundIn = MySQLCommand
    typealias OutboundOut = MySQLPacket
    
    enum State {
        case handshake(HandshakeState)
        case authenticating(AuthenticationState)
        case commandPhase(MySQLCapabilityFlags)
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
        var capabilities: MySQLCapabilityFlags
        var isSecure: Bool
        var done: EventLoopPromise<Void>
    }
    
    var state: State
    var queue: CircularBuffer<MySQLCommand>
    let sequence: MySQLPacketSequence
    
    init(state: State, sequence: MySQLPacketSequence) {
        self.state = state
        self.queue = .init()
        self.sequence = sequence
    }
    
    func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {
        var packet = self.unwrapInboundIn(data)
        switch self.state {
        case .handshake(let state):
            do {
                try self.handleHandshake(ctx: ctx, packet: &packet, state: state)
            } catch {
                state.done.fail(error)
            }
        case .authenticating(let state):
            do {
                try self.handleAuthentication(ctx: ctx, packet: &packet, state: state)
            } catch {
                state.done.fail(error)
            }
        case .commandPhase(let capabilities):
            if let current = self.queue.first {
                do {
                    let commandState = try current.handler.handle(packet: &packet)
                    self.handleCommandState(ctx: ctx, commandState)
                } catch {
                    self.queue.removeFirst()
                    current.promise.fail(error)
                }
            } else {
                assertionFailure("unhandled packet: \(packet)")
            }
        }
    }
    
    func handleHandshake(ctx: ChannelHandlerContext, packet: inout MySQLPacket, state: HandshakeState) throws {
        let handshakeRequest = try packet.handshake()
        switch state.tlsConfig {
        case .some(let tlsConfig):
            var capabilities = MySQLCapabilityFlags.clientDefault
            capabilities.insert(.CLIENT_SSL)
            let sslRequest = MySQLPacket.SSLRequest(
                capabilities: capabilities,
                maxPacketSize: 0,
                characterSet: .utf8mb4
            )
            let promise = ctx.channel.eventLoop.makePromise(of: Void.self)
            ctx.write(self.wrapOutboundOut(.init(sslRequest)), promise: promise)
            ctx.flush()
            
            let sslContext = try SSLContext(configuration: tlsConfig)
            let handler = try OpenSSLClientHandler(context: sslContext)
            promise.futureResult.flatMap {
                return ctx.channel.pipeline.add(handler: handler, first: true).flatMapThrowing {
                    try self.writeHandshakeResponse(ctx: ctx, handshakeRequest: handshakeRequest, state: state)
                }
            }.whenFailure { error in
                state.done.fail(error)
            }
        case .none:
            try self.writeHandshakeResponse(ctx: ctx, handshakeRequest: handshakeRequest, state: state)
        }
    }
    
    func writeHandshakeResponse(
        ctx: ChannelHandlerContext,
        handshakeRequest: MySQLPacket.Handshake,
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
            capabilities: handshakeRequest.capabilities,
            isSecure: state.tlsConfig != nil,
            done: state.done
        ))
        let res = MySQLPacket.HandshakeResponse(
            capabilities: .clientDefault,
            maxPacketSize: 0,
            characterSet: .utf8mb4,
            username: state.username,
            authResponse: hash,
            database: state.database,
            authPluginName: authPluginName
        )
        ctx.write(self.wrapOutboundOut(.init(res)), promise: nil)
        ctx.flush()
    }
    
    func handleAuthentication(
        ctx: ChannelHandlerContext,
        packet: inout MySQLPacket,
        state: AuthenticationState
    ) throws {
        switch state.authPluginName {
        case "caching_sha2_password":
            guard !packet.isOK else {
                self.state = .commandPhase(state.capabilities)
                state.done.succeed(())
                return
            }
            guard !packet.isError else {
                let err = try packet.err(capabilities: state.capabilities)
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
                    ctx.write(self.wrapOutboundOut(MySQLPacket(payload: payload)), promise: nil)
                    ctx.flush()
                default:
                    throw MySQLError.protocolError
                }
            default:
                throw MySQLError.protocolError
            }
        case "mysql_native_password":
            guard !packet.isError else {
                let error = try packet.err(capabilities: state.capabilities)
                throw MySQLError.server(error)
            }
            guard packet.isOK else {
                throw MySQLError.protocolError
            }
            self.state = .commandPhase(state.capabilities)
            state.done.succeed(())
        default:
            throw MySQLError.unsupportedAuthPlugin(name: state.authPluginName)
        }
    }
    
    func write(ctx: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
        let request = self.unwrapOutboundIn(data)
        self.queue.append(request)
        
        // send initial
        do {
            self.sequence.current = nil
            let commandState = try request.handler.activate()
            self.handleCommandState(ctx: ctx, commandState)
        } catch {
            self.queue.removeFirst()
            request.promise.fail(error)
        }
        
        // write is complete
        promise?.succeed(())
    }
    
    func handleCommandState(ctx: ChannelHandlerContext, _ commandState: MySQLCommandState) {
        switch commandState {
        case .done:
            let current = self.queue.removeFirst()
            current.promise.succeed(())
        case .noResponse:
            break
        case .response(let packets):
            for packet in packets {
                ctx.write(self.wrapOutboundOut(packet), promise: nil)
            }
            ctx.flush()
        }
    }
    
    func close(ctx: ChannelHandlerContext, mode: CloseMode, promise: EventLoopPromise<Void>?) {
        ctx.write(self.wrapOutboundOut(.quit), promise: nil)
        ctx.flush()
        ctx.close(mode: .all, promise: promise)
    }
    
    func errorCaught(ctx: ChannelHandlerContext, error: Error) {
        if let current = self.queue.first {
            self.queue.removeFirst()
            current.promise.fail(error)
        }
    }
}
