internal final class MySQLHandshakeCommand: MySQLCommand {
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
    
    enum State {
        case awaitingServerGreeting
        case awaitingReactivation(MySQLProtocol.HandshakeV10)
        case preparingForAuthentication
    }

    let logger: Logger
    let configuration: MySQLConnection.Configuration
    let desiredClientCapabilities: MySQLProtocol.CapabilityFlags
    let desiredCharacterSet: MySQLProtocol.CharacterSet
    let commandPacketSizeLimit: UInt32
    let state: State
    
    init(
        logger: Logger,
        configuration: MySQLConnection.Configuration,
        desiredClientCapabilities: MySQLProtocol.CapabilityFlags,
        desiredCharacterSet: MySQLProtocol.CharacterSet,
        commandPacketSizeLimit: UInt32
    ) {
        precondition(
            desiredClientCapabilities.isDisjoint(with: Self.forbiddenClientCapabilities),
            "This implementation does not support ignoring SIGPIPE, returning found rows, the compressed wire protocol, or expired passwords."
        )
        
        self.logger = logger
        self.configuration = configuration
        self.desiredClientCapabilities = desiredClientCapabilities.union(Self.minimumServerCapabilities)
        self.desiredCharacterSet = desiredCharacterSet
        self.commandPacketSizeLimit = commandPacketSizeLimit
        self.state = .awaitingServerGreeting
    }
    
    /// The list of capabilities that _must_ not be requested by the client - i.e. the ones not supported
    /// by this implementation.
    private static let forbiddenClientCapabilities: MySQLProtocol.CapabilityFlags = [
        .CLIENT_IGNORE_SIGPIPE,               // has no meaning in this implementation
        .CLIENT_FOUND_ROWS,                   // currently unsupported, as there is no compelling reason to bother
        .CLIENT_COMPRESS,                     // the compressed wire protocol adds complexity for insufficient gain
        .CLIENT_ZSTD_COMPRESSION_ALGORITHM,   // still not worth it
        .CLIENT_CAN_HANDLE_EXPIRED_PASSWORDS, // handling expired passwords requires user interaction, for which we have no API
    ]
    
    /// A set of capabilities that all 5.7 servers support at minimum. The client might not enable all of
    /// these, but the server must at least claim to allow them.
    ///
    /// N.B.: We could require `CLIENT_SESSION_TRACK` and `CLIENT_DEPRECATE_EOF` too, but we choose not to
    /// in the name of fair play.
    private static let minimumServerCapabilities: MySQLProtocol.CapabilityFlags = [
        .CLIENT_CONNECT_WITH_DB,
        .CLIENT_IGNORE_SPACE,
        .CLIENT_PROTOCOL_41,
        .CLIENT_TRANSACTIONS,
        .CLIENT_SECURE_CONNECTION,
        .CLIENT_MULTI_STATEMENTS,
        .CLIENT_MULTI_RESULTS,
        .CLIENT_PS_MULTI_RESULTS,
        .CLIENT_PLUGIN_AUTH,
        .CLIENT_CONNECT_ATTRS,
        .CLIENT_PLUGIN_AUTH_LENENC_CLIENT_DATA,
    ]
    
    /// Verify that the server reports the required minimum capabilities, is a supported version,
    /// can handle any non-negotiable capabilities we intend to claim, supports TLS if it was
    /// required, and so on. Return the server version and the set of requested client capabilities
    /// that are supported by the server,
    private func validateServer(
        from handshake: MySQLProtocol.HandshakeV10
    ) throws -> (
        version: MySQLProtocol.ServerVersion,
        capabilities: MySQLProtocol.CapabilityFlags
    ) {
        // Check the actual version number first so we have a better chance of reporting something
        // comprehensible when encountering old servers.
        guard let serverVersion = MySQLProtocol.ServerVersion(string: handshake.serverVersion) else {
            self.logger.error("Unable to parse server version at all, probably means it didn't send one.")
            throw MySQLError.protocolError
        }
        
        if (serverVersion.major == 5 && serverVersion.minor == 7 && !serverVersion.isMariaDB) ||
           (serverVersion.major == 8 && serverVersion.minor == 0 && !serverVersion.isMariaDB) ||
           (serverVersion.major == 10 && (3...8).contains(serverVersion.minor) && serverVersion.isMariaDB)
        {
            self.logger.debug("Connected to server version \(serverVersion)")
        } else {
            self.logger.warning("Server version \(serverVersion.raw) may not be supported! Continuing...")
        }

        // Our minimum supported version of MySQL is 5.7 (with which MariaDB 10.3 is compatible). We can
        // therefore require all the modern capabilities instead of trying to emulate a half-dozen old
        // handshake formats and whatnot.
        guard handshake.capabilities.isSuperset(of: Self.minimumServerCapabilities) else {
            self.logger.error("Server does not support minimum requirements for compatibility, not continuing.")
            self.logger.debug("Server capabilities: \(handshake.capabilities)")
            self.logger.debug("Required capabilities: \(Self.minimumServerCapabilities)")
            self.logger.debug("Difference: \(Self.minimumServerCapabilities.subtracting(handshake.capabilities))")
            throw MySQLError.unsupportedServer(message: "Server missing required capabilities")
        }
        
        var effectiveCapabilities = self.desiredClientCapabilities.intersection(handshake.capabilities)
        
        // Check that if we require TLS, the server accepts it, and set the CLIENT_SSL capability appropriately.
        switch self.configuration.tls.base {
            case .require(_):
                guard handshake.capabilities.contains(.CLIENT_SSL) else {
                    self.logger.error("A TLS connection is required, but the server doesn't support it")
                    throw MySQLError.secureConnectionRequired
                }
            case .prefer(_):
                effectiveCapabilities.formUnion(handshake.capabilities.intersection([.CLIENT_SSL])) // enable TLS if server has it
            case .disable:
                effectiveCapabilities.remove(.CLIENT_SSL)
        }
        
        return (version: serverVersion, capabilities: effectiveCapabilities)
    }
    
    func handle(packet: inout MySQLPacket, capabilities: MySQLProtocol.CapabilityFlags) throws -> MySQLCommandAction {
        guard case .awaitingServerGreeting = self.state else {
            self.logger.debug("Packet sequencing error - handshake command still active after greeting received.")
            throw MySQLError.protocolError
        }
        
        // Initial error packet indicates server is not accepting connections.
        guard !packet.isError else {
            let errPacket = try packet.decode(MySQLProtocol.ERR_Packet.self, capabilities: [])
            self.logger.trace("MySQL server opened with error \(errPacket.asServerError?.errorMessage ?? "<invalid data>")")
            throw MySQLError.server(.synthesize(from: errPacket))
        }

        // Decode and validate the server's handshake.
        let serverHandshake = try packet.decode(MySQLProtocol.HandshakeV10.self, capabilities: [])
        self.logger.trace("Handling MySQL handshake \(serverHandshake)")
        let (serverVersion, checkedCapabilities) = try self.validateServer(from: serverHandshake)
        
        self.state = .awaitingReactivation(serverHandshake)
        
        // If TLS was configured and available (checked above), initiate it and wait, otherwise skip ahead.
        switch configuration.tls.base {
            case .require(let context),
                 .prefer(let context) where checkedCapabilities.contains(.CLIENT_SSL):
                let tlsRequest = MySQLProtocol.SSLRequest(capabilities: checkedCapabilities, maxPacketSize: self.commandPacketSizeLimit, characterSet: self.desiredCharacterSet)
                
                return .init(sendResponse: [tlsRequest], updateCapabilities: checkedCapabilities, initiateTLS: context)
                // resumes at `.activate(capabilities:)`
            default:
                // immediately skip to `.activate`
                return try self.activate(capabilities: checkedCapabilities)
        }
    }
    
    func activate(capabilities: MySQLProtocol.CapabilityFlags) throws -> MySQLCommandAction {
        if case .awaitingServerGreeting = self.state {
            // initial command activation; ignore
            return .init()
        }
        
        guard case .awaitingReactivation(let serverHandshake) = self.state else {
            self.logger.debug("Packet sequencing error - handshake command reactivated after handing off to authentication flow")
            throw MySQLError.protocolError
        }
        
        self.state = .preparingForAuthentication
        
        return .init(updateCapabilities: capabilities, queueCommands: [(MySQLAuthenticateCommand(
            logger: self.logger,
            configuration: self.configuration,
            desiredCharacterSet: self.desiredCharacterSet,
            commandPacketSizeLimit: self.commandPacketSizeLimit,
            serverHandshake: serverHandshake
        ), .next)], complete: .success(()))
    }
/*
            let promise = context.channel.eventLoop.makePromise(of: Void.self)
            try context.write(self.wrapOutboundOut(.encode(sslRequest, capabilities: [])), promise: promise)
            context.flush()

            let sslContext = try NIOSSLContext(configuration: tlsConfiguration)
            let handler = try NIOSSLClientHandler(context: sslContext, serverHostname: state.serverHostname)
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

        let res = MySQLProtocol.HandshakeResponse41(
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
*/
}
