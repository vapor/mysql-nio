import NIOSSL

internal struct MySQLCommandContext {
    var handler: MySQLCommand
    var promise: EventLoopPromise<Void>
}

final class MySQLConnectionHandler: ChannelDuplexHandler {
    typealias InboundIn = MySQLPacket
    typealias OutboundIn = MySQLCommandContext
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
        let tlsConfiguration: TLSConfiguration?
        let done: EventLoopPromise<Void>
    }
    
    struct AuthenticationState {
        var authPluginName: String
        var password: String?
        var isTLS: Bool
        var done: EventLoopPromise<Void>
    }
    
    enum CommandState {
        case ready
        case busy
    }

    let logger: Logger
    var state: State
    var serverCapabilities: MySQLProtocol.CapabilityFlags?
    var queue: CircularBuffer<MySQLCommandContext>
    let sequence: MySQLPacketSequence
    var commandState: CommandState
    
    init(logger: Logger, state: State, sequence: MySQLPacketSequence) {
        self.logger = logger
        self.state = state
        self.queue = .init()
        self.sequence = sequence
        self.commandState = .ready
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
                    self.commandState = .ready
                    current.promise.fail(error)
                    self.sendEnqueuedCommandIfReady(context: context)
                }
            } else {
                assertionFailure("unhandled packet: \(packet.payload.debugDescription)")
            }
        }
    }
    
    func handleHandshake(context: ChannelHandlerContext, packet: inout MySQLPacket, state: HandshakeState) throws {
        let handshakeRequest = try packet.decode(MySQLProtocol.HandshakeV10.self, capabilities: [])
        self.logger.trace("Handling MySQL handshake \(handshakeRequest)")
        assert(handshakeRequest.capabilities.contains(.CLIENT_PROTOCOL_41), "Client protocol 4.1 required")
        self.serverCapabilities = handshakeRequest.capabilities
        if let tlsConfiguration = state.tlsConfiguration, handshakeRequest.capabilities.contains(.CLIENT_SSL) {
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

            let sslContext = try NIOSSLContext(configuration: tlsConfiguration)
            let handler = try NIOSSLClientHandler(context: sslContext, serverHostname: nil)
            promise.futureResult.flatMap {
                return context.channel.pipeline.addHandler(handler, position: .first).flatMapThrowing {
                    try self.writeHandshakeResponse(context: context, handshakeRequest: handshakeRequest, state: state, isTLS: true)
                }
            }.whenFailure { error in
                state.done.fail(error)
            }
        } else {
            try self.writeHandshakeResponse(context: context, handshakeRequest: handshakeRequest, state: state, isTLS: false)
        }
    }
    
    func writeHandshakeResponse(
        context: ChannelHandlerContext,
        handshakeRequest: MySQLProtocol.HandshakeV10,
        state: HandshakeState,
        isTLS: Bool
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

        self.logger.trace("Writing handshake response with auth plugin: \(authPluginName) tls: \(isTLS)")

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
            isTLS: isTLS,
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
                    guard state.isTLS else {
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
        let command = self.unwrapOutboundIn(data)
        self.queue.append(command)
        self.sendEnqueuedCommandIfReady(context: context)
        promise?.succeed(())
    }
    
    func sendEnqueuedCommandIfReady(context: ChannelHandlerContext) {
        guard case .ready = self.commandState else {
            return
        }
        guard let command = self.queue.first else {
            return
        }
        self.commandState = .busy
        
        // send initial
        do {
            self.sequence.current = nil
            let commandState = try command.handler.activate(capabilities: self.serverCapabilities!)
            self.handleCommandState(context: context, commandState)
        } catch {
            self.queue.removeFirst()
            self.commandState = .ready
            command.promise.fail(error)
            self.sendEnqueuedCommandIfReady(context: context)
        }
    }
    
    func handleCommandState(context: ChannelHandlerContext, _ commandState: MySQLCommandState) {
        if commandState.done {
            let current = self.queue.removeFirst()
            self.commandState = .ready
            current.promise.succeed(())
            self.sendEnqueuedCommandIfReady(context: context)
        }
        if commandState.resetSequence {
            self.sequence.reset()
        }
        if !commandState.response.isEmpty {
            for packet in commandState.response {
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
        self.sequence.reset()
        let quit = MySQLProtocol.COM_QUIT()
        try context.write(self.wrapOutboundOut(.encode(quit, capabilities: self.serverCapabilities!)), promise: nil)
        context.flush()
        
        if let promise = promise {
            // we need to do some error mapping here, so create a new promise
            let p = context.eventLoop.makePromise(of: Void.self)
            
            // forward the close request with our new promise
            context.close(mode: mode, promise: p)
            
            // forward close future results based on whether
            // the close was successful
            p.futureResult.whenSuccess { promise.succeed(()) }
            p.futureResult.whenFailure { error in
                if
                    let sslError = error as? NIOSSLError,
                    case .uncleanShutdown = sslError,
                    self.queue.isEmpty
                {
                    // we can ignore unclear shutdown errors
                    // since no requests are pending
                    promise.succeed(())
                } else {
                    promise.fail(error)
                }
            }
        } else {
            // no close promise anyway, just forward request
            context.close(mode: mode, promise: nil)
        }
    }
    
    func channelInactive(context: ChannelHandlerContext) {
        while let next = self.queue.popLast() {
            next.promise.fail(MySQLError.closed)
        }
    }
    
    func errorCaught(context: ChannelHandlerContext, error: Error) {
        switch self.state {
        case .handshake(let state):
            state.done.fail(error)
        case .authenticating(let state):
            state.done.fail(error)
        case .commandPhase:
            if let current = self.queue.first {
                self.queue.removeFirst()
                current.promise.fail(error)
            }
        }
    }
}
