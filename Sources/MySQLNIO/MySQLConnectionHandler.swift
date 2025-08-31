import _CryptoExtras
import Algorithms
import NIOSSL
import NIOCore
import Logging

internal struct MySQLCommandContext: Sendable {
    var handler: any MySQLCommand
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
        let serverHostname: String?
        let done: EventLoopPromise<Void>
    }
    
    struct AuthenticationState {
        var authPluginName: String
        var password: String?
        var isTLS: Bool
        var savedSeedValue: [UInt8]
        var awaitingCachingSha2PluginPublicKey: Bool
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
                self.logger.trace("Handle handshake packet")
                try self.handleHandshake(context: context, packet: &packet, state: state)
            } catch {
                state.done.fail(error)
            }
        case .authenticating(let state):
            do {
                self.logger.trace("Handle authentication packet")
                try self.handleAuthentication(context: context, packet: &packet, state: state)
            } catch {
                state.done.fail(error)
            }
        case .commandPhase:
            if let current = self.queue.first {
                do {
                    guard let capabilities = self.serverCapabilities else {
                        throw MySQLError.protocolError
                    }
                    let commandState = try current.handler.handle(packet: &packet, capabilities: capabilities)
                    self.handleCommandState(context: context, commandState)
                } catch {
                    self.queue.removeFirst()
                    self.commandState = .ready
                    current.promise.fail(error)
                    self.sendEnqueuedCommandIfReady(context: context)
                }
            } else {
                if packet.isError, let errorPacket = try? packet.decode(MySQLProtocol.ERR_Packet.self, capabilities: serverCapabilities ?? .init()) {
                    self.errorCaught(context: context, error: MySQLError.server(errorPacket))
                    self.close(context: context, mode: .all, promise: nil)
                } else {
                    self.errorCaught(context: context, error: MySQLError.protocolError)
                    context.close(mode: .all, promise: nil) // Don't send a COM_QUIT, this is a protocol error anyway
                }
            }
        }
    }
    
    func handleHandshake(context: ChannelHandlerContext, packet: inout MySQLPacket, state: HandshakeState) throws {
        // https://github.com/vapor/mysql-nio/issues/91
        guard !packet.isError else {
            let errorPacket = try packet.decode(MySQLProtocol.ERR_Packet.self, capabilities: [])
            self.logger.trace("Received early server error before handshake: \(errorPacket)")
            throw MySQLError.server(errorPacket)
        }
        let handshakeRequest = try packet.decode(MySQLProtocol.HandshakeV10.self, capabilities: [])
        self.logger.trace("Handling MySQL handshake \(handshakeRequest)")
        guard handshakeRequest.capabilities.contains(.CLIENT_PROTOCOL_41) else {
            throw MySQLError.unsupportedServer(message: "Client protocol 4.1 required")
        }
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

            promise.futureResult.assumeIsolated().flatMapThrowing {
                let sslContext = try NIOSSLContext(configuration: tlsConfiguration)
                let handler = try NIOSSLClientHandler(context: sslContext, serverHostname: state.serverHostname)

                try context.channel.pipeline.syncOperations.addHandler(handler, position: .first)
                try self.writeHandshakeResponse(context: context, handshakeRequest: handshakeRequest, state: state, isTLS: true)
            }.whenFailure { error in
                state.done.fail(error)
            }
        } else {
            try self.writeHandshakeResponse(context: context, handshakeRequest: handshakeRequest, state: state, isTLS: false)
        }
    }
    
    func doInitialAuthPluginHandling(
        authPluginName: String,
        isTLS: Bool,
        passwordInput: String?,
        authPluginData: ByteBuffer,
        done: EventLoopPromise<Void>
    ) throws -> ByteBuffer {
        var password = ByteBufferAllocator().buffer(capacity: 0)
        if let passwordString = passwordInput {
            password.writeString(passwordString)
        }

        self.logger.trace("Generating initial auth response with auth plugin: \(authPluginName) tls: \(isTLS)")

        var saveSeed: [UInt8] = []
        let hash: ByteBuffer
        switch authPluginName {
        case "caching_sha2_password":
            let seed = authPluginData
            hash = xor(sha256(password), sha256(sha256(sha256(password)), seed))
            saveSeed = seed.getBytes(at: 0, length: seed.readableBytes) ?? []
            self.logger.trace("Generated scrambled hash for caching_sha2_password")
        case "mysql_native_password":
            if let passwordValue = passwordInput, !passwordValue.isEmpty {
                var copy = authPluginData
                guard let salt = copy.readSlice(length: 20) else {
                    throw MySQLError.authPluginDataError(name: authPluginName)
                }
                hash = xor(sha1(salt, sha1(sha1(password))), sha1(password))
                saveSeed = salt.getBytes(at: 0, length: 20) ?? []
                self.logger.trace("Generated salted hash for mysql_native_password")
            } else {
                hash = .init()
                // No need to save any seed; we don't reuse it for this plugin anyway.
                self.logger.trace("Generated empty reponse for mysql_native_password with empty password input")
            }
        default:
            throw MySQLError.unsupportedAuthPlugin(name: authPluginName)
        }
        self.state = .authenticating(.init(
            authPluginName: authPluginName,
            password: passwordInput,
            isTLS: isTLS,
            savedSeedValue: saveSeed,
            awaitingCachingSha2PluginPublicKey: false,
            done: done
        ))
        return hash
    }

    func writeHandshakeResponse(
        context: ChannelHandlerContext,
        handshakeRequest: MySQLProtocol.HandshakeV10,
        state: HandshakeState,
        isTLS: Bool
    ) throws {
        struct SemanticVersion {
            let major: Int
            let minor: Int
            let patch: Int

            init?<S>(string: S) where S: StringProtocol {
                let parts = string.split(separator: ".", maxSplits: 2, omittingEmptySubsequences: false)
                guard parts.count == 3, let major = Int(parts[0]), let minor = Int(parts[1]), let patch = Int(parts[2]) else {
                    return nil
                }
                self.major = major
                self.minor = minor
                self.patch = patch
            }
        }

        guard let versionString = handshakeRequest.serverVersion.split(separator: "-").first else {
            throw MySQLError.protocolError
        }
        if let version = SemanticVersion(string: versionString) {
            if !handshakeRequest.serverVersion.contains("MariaDB") {
                switch (version.major, version.minor) {
                case (5..., 7...), (8..., _): // >= 5.7, or >= 8.0
                    break
                default:
                    self.logger.error("Unsupported MySQL version: \(handshakeRequest.serverVersion)")
                    self.logger.info("MySQL 5.7 or higher is required")
                }
            }
        } else {
            self.logger.error("Unrecognized MySQL version: \(handshakeRequest.serverVersion)")
        }
        
        guard handshakeRequest.capabilities.contains(.CLIENT_SECURE_CONNECTION) else {
            throw MySQLError.unsupportedServer(message: "Pre-4.1 auth protocol is not supported or safe.")
        }
        guard let authPluginName = handshakeRequest.authPluginName else {
            throw MySQLError.unsupportedAuthPlugin(name: "<none>")
        }

        let hash = try doInitialAuthPluginHandling(authPluginName: authPluginName, isTLS: isTLS, passwordInput: state.password, authPluginData: handshakeRequest.authPluginData, done: state.done)

        let res = MySQLPacket.HandshakeResponse41(
            capabilities: .clientDefault,
            maxPacketSize: 0,
            characterSet: .utf8mb4,
            username: state.username,
            authResponse: hash,
            database: state.database,
            authPluginName: authPluginName
        )
        guard let capabilities = self.serverCapabilities else {
            throw MySQLError.protocolError
        }
        try context.write(self.wrapOutboundOut(.encode(res, capabilities: capabilities)), promise: nil)
        context.flush()
    }
    
    func handleSwitchPlugins(
        context: ChannelHandlerContext,
        packet: inout MySQLPacket,
        state: AuthenticationState
    ) throws {
        self.logger.trace("Got request to switch auth methods (currently \(state.authPluginName)")
        guard let newPluginName = packet.payload.readNullTerminatedString() else {
            throw MySQLError.missingAuthPluginInlineData
        }
        self.logger.trace("New plugin is \(newPluginName)")
        guard let newAuthData = packet.payload.readSlice(length: 20) else { // WARNING: This might be wrong for plugins we don't yet support...
            throw MySQLError.missingAuthPluginInlineData
        }
        let newHash = try doInitialAuthPluginHandling(authPluginName: newPluginName, isTLS: state.isTLS, passwordInput: state.password, authPluginData: newAuthData, done: state.done)
        // Send an AuthSwitchResponse (which is just the plugin auth data by itself)
        context.write(self.wrapOutboundOut(MySQLPacket(payload: newHash)), promise: nil)
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
                self.logger.trace("caching_sha2_password replied OK, going to command phase")
                self.state = .commandPhase
                state.done.succeed(())
                return
            }
            guard !packet.isError else {
                self.logger.trace("caching_sha2_password replied ERR, decoding")
                guard let capabilities = self.serverCapabilities else {
                    throw MySQLError.protocolError
                }
                let err = try packet.decode(MySQLProtocol.ERR_Packet.self, capabilities: capabilities)
                throw MySQLError.server(err)
            }
            guard let status = packet.payload.readInteger(endianness: .little, as: UInt8.self) else {
                throw MySQLError.missingOrInvalidAuthMoreDataStatusTag
            }
            self.logger.trace("caching_sha2_password sent packet tagged \(status)")
            switch status {
            case 0xfe: // auth switch request
                try self.handleSwitchPlugins(context: context, packet: &packet, state: state)
            case 0x01:
                self.logger.trace("caching_sha2_password sent AuthMoreData, processing")
                let name: UInt8?
                if state.awaitingCachingSha2PluginPublicKey {
                    self.logger.trace("Waiting for caching_sha2_password to send an RSA key")
                    name = nil
                } else {
                    guard let pName = packet.payload.readInteger(endianness: .little, as: UInt8.self) else {
                        throw MySQLError.missingOrInvalidAuthPluginInlineCommand(command: nil)
                    }
                    name = pName
                    self.logger.trace("caching_sha2_password sent command \(pName)")
                }
                self.state = .authenticating(AuthenticationState(authPluginName: state.authPluginName, password: state.password, isTLS: state.isTLS, savedSeedValue: state.savedSeedValue, awaitingCachingSha2PluginPublicKey: false, done: state.done)) // make sure to reset

                switch name {
                case .none: // our internal sentinel for "here's the public key" for non-TLS connections
                    // data will be the PEM form of the server's RSA public key
                    guard let pemKey = packet.payload.readString(length: packet.payload.readableBytes) else {
                        throw MySQLError.missingAuthPluginInlineData
                    }
                    self.logger.trace("caching_sha2_password sent RSA key, sending the encrypted password")
                    let rsaKey = try _RSA.Encryption.PublicKey(pemRepresentation: pemKey)
                    let saltedPassword = Array(zip(chain((state.password ?? "").utf8, [0]), state.savedSeedValue.cycled()).map(^))
                    let encryptedData = ByteBuffer(bytes: try rsaKey.encrypt(saltedPassword, padding: .PKCS1_OAEP))

                    context.writeAndFlush(self.wrapOutboundOut(MySQLPacket(payload: encryptedData)), promise: nil)
                case 0x03: // fast_auth_success
                    // Next packet will be OK, wait for more data
                    self.logger.trace("caching_sha2_password sent fast_auth_success, just waiting for OK now")
                    return
                case 0x04: // perform_full_authentication
                    var payload = ByteBufferAllocator().buffer(capacity: 0)
                    if state.isTLS {
                        // TLS connection, send password in the "clear"
                        self.logger.trace("caching_sha2_password sent perform_full_authentication on TLS, sending password in cleartext")
                        payload.writeNullTerminatedString(state.password ?? "")
                    } else {
                        // send a public key request and wait
                        self.logger.trace("caching_sha2_password sent perform_full_authentication on insecure, sending request_public_key")
                        payload.writeBytes([0x02])
                        self.state = .authenticating(AuthenticationState(authPluginName: state.authPluginName, password: state.password, isTLS: state.isTLS, savedSeedValue: state.savedSeedValue, awaitingCachingSha2PluginPublicKey: true, done: state.done))
                    }
                    context.writeAndFlush(self.wrapOutboundOut(MySQLPacket(payload: payload)), promise: nil)
                default:
                    throw MySQLError.missingOrInvalidAuthPluginInlineCommand(command: name)
                }
            default:
                throw MySQLError.missingOrInvalidAuthMoreDataStatusTag
            }
        case "mysql_native_password":
            guard !packet.isError else {
                self.logger.trace("mysql_native_password sent ERR, decoding")
                guard let capabilities = self.serverCapabilities else {
                    throw MySQLError.protocolError
                }
                let error = try packet.decode(MySQLProtocol.ERR_Packet.self, capabilities: capabilities)
                throw MySQLError.server(error)
            }
            guard !packet.isOK else {
                self.logger.trace("mysql_native_password sent OK, going to command phase")
                self.state = .commandPhase
                state.done.succeed(())
                return
            }
            guard let tag = packet.payload.readInteger(endianness: .little, as: UInt8.self) else {
                throw MySQLError.missingOrInvalidAuthMoreDataStatusTag
            }
            self.logger.trace("mysql_native_password sent packet tagged \(tag)")
            switch tag {
            case 0xfe: // auth switch request
                try self.handleSwitchPlugins(context: context, packet: &packet, state: state)
            default:
                throw MySQLError.missingOrInvalidAuthPluginInlineCommand(command: tag)
            }
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
        guard let capabilities = self.serverCapabilities else {
            command.promise.fail(MySQLError.protocolError)
            return
        }
        self.commandState = .busy
        
        // send initial
        do {
            self.sequence.current = nil
            let commandState = try command.handler.activate(capabilities: capabilities)
            self.handleCommandState(context: context, commandState)
        } catch {
            self.queue.removeFirst()
            self.commandState = .ready
            command.promise.fail(error)
            self.sendEnqueuedCommandIfReady(context: context)
        }
    }
    
    func handleCommandState(context: ChannelHandlerContext, _ commandState: MySQLCommandState) {
        if commandState.resetSequence {
            self.sequence.reset()
        }
        if !commandState.response.isEmpty {
            for packet in commandState.response {
                context.write(self.wrapOutboundOut(packet), promise: nil)
            }
            context.flush()
        }
        if commandState.done {
            let current = self.queue.removeFirst()
            self.commandState = .ready
            if let error = commandState.error {
                current.promise.fail(error)
            } else {
                current.promise.succeed(())
            }
            self.sendEnqueuedCommandIfReady(context: context)
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
        // N.B.: It is possible to get here without having processed a handshake packet yet, in which case there will
        // not be any serverCapabilities. Since COM_QUIT doesn't care about any of those anyway, don't crash if they're
        // not there!
        try context.write(self.wrapOutboundOut(.encode(quit, capabilities: self.serverCapabilities ?? .init())), promise: nil)
        context.flush()
        
        if let promise = promise {
            // we need to do some error mapping here, so create a new promise
            let p = context.eventLoop.makePromise(of: Void.self)
            
            // forward the close request with our new promise
            context.close(mode: mode, promise: p)
            
            // forward close future results based on whether
            // the close was successful
            let queueEmpty = self.queue.isEmpty

            p.futureResult.whenSuccess { promise.succeed(()) }
            p.futureResult.whenFailure { error in
                if
                    let sslError = error as? NIOSSLError,
                    case .uncleanShutdown = sslError,
                    queueEmpty
                {
                    // we can ignore unclean shutdown errors
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
    
    func errorCaught(context: ChannelHandlerContext, error: any Error) {
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
