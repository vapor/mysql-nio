import NIOCore

/// The "top-level" state machine covering the lifecycle of a MySQL server connection.
///
/// Unlike the "official documentation" (which is difficult to consider worthy of the name), we do not treat the
/// entire "connection phase" as a single top-level state; instead, the various "sub-states" of the connection phase
/// are individual states in this machine, and only the text resultset and binary resultset subprotocols get their
/// own state machines, being the only complex non-authentication logic in the protocol.
///
/// ## See Also
///
/// - [MySQL Client/Server Protocol documentation](https://dev.mysql.com/doc/dev/mysql-server/latest/PAGE_PROTOCOL.html)
/// - [MariaDB Client/Server Protocol documentation](https://mariadb.com/kb/en/clientserver-protocol/)
struct MySQLConnectionProtocolStateMachine {
    /// States and their transitions.
    enum State {
        /// Initial state - waiting for a server handshake
        ///
        /// ##### Transitions
        /// ||||
        /// -|:-:|-
        /// ||_initial_|||
        /// `awaitingGreeting`|→|``waitingForTLSReady(authMethod:authData:)``
        /// `awaitingGreeting`|→|``awaitingAuthReply(authHandler:secureConnection:)``
        /// `awaitingGreeting`|→|``terminated(error:)``
        /// ||||
        ///
        /// ##### Valid packets
        /// - `HandshakeV10`
        /// - `ERR_Packet`
        case awaitingGreeting
        
        /// TLS establishment pending
        ///
        /// This state indicates that a TLS connection was configured, the appropriate request has been sent to the
        /// server, and the connection is awaiting confirmation from the TLS implementation layer.
        ///
        /// The auth data from the server handshake is preserved during this state, as it is needed in order to
        /// send the handshake reply once TLS setup is complete but is not suitable for long-term retention. Other
        /// interesting data from the server handshake - including the _filtered_ set of capability flags - is passed
        /// on to the owning connection before reaching this state.
        ///
        /// - Parameters:
        ///   - authMethod: The preserved auth method which issued the `authData`
        ///   - authData: Preserved auth "challenge" data
        ///
        /// ##### Transitions
        /// ||||
        /// -|:-:|-
        /// `waitingForTLSReady`|→|``awaitingAuthReply(authHandler:secureConnection:)``
        /// `waitingForTLSReady`|→|``terminated(error:)``
        /// ||||
        ///
        /// ##### Valid packets
        /// - `ERR_Packet`
        case waitingForTLSReady(authMethod: String, authData: ByteBuffer)
        
        /// Waiting for a reply during the authentication process
        ///
        /// This state can occur multiple times during the auth process:
        ///
        ///  - After sending a handshake reply (expecting more auth steps or OK)
        ///  - After sending an auth switch response (expecting more auth steps or OK)
        ///  - After sending a "more data" reply (expecting more auth steps or OK)
        ///  - After sending a "next factor" reply (expecting more auth steps or OK)
        ///
        /// - Parameters:
        ///   - authHandler: The active "handler" for the current step of authentication. May change between auth
        ///     steps if the multi-factor auth capability is in use or the server requests a method switch. Auth
        ///     handlers contain any additional state data they require.
        ///
        /// ##### Transitions
        /// ||||
        /// -|:-:|-
        /// `awaitingAuthReply`|→|`awaitingAuthReply`
        /// `awaitingAuthReply`|→|``ready``
        /// `awaitingAuthReply`|→|``terminated(error:)``
        /// ||||
        ///
        /// ##### Valid packets
        /// - `AuthMoreData`
        /// - `AuthSwitchRequest`
        /// - `AuthNexFactor`
        /// - `OK_Packet`
        /// - `ERR_Packet`
        case awaitingAuthReply(authHandler: any MySQLBuiltinAuthHandler, secureConnection: Bool)
        
        /// Command mode with no commands running or queued
        ///
        /// This is effectively a connection's "idle" state. It may or may not occur between commands if
        /// multiple commands are queued.
        ///
        /// > Note: This is the only state with outgoing transitions triggered solely by client-side actions.
        ///
        /// ##### Transitions
        /// ||||
        /// -|:-:|-
        /// `ready`|→|``awaitingReply``
        /// `ready`|→|``processingQuery(state:)``
        /// `ready`|→|``processingPreparedStatement(state:)``
        /// `ready`|→|``closed``
        /// `ready`|→|``terminated(error:)``
        /// ||||
        ///
        /// ##### Valid packets
        /// - `ERR_Packet`
        case ready
        
        /// An active command is in progress
        ///
        /// This state encapsulates the various implementations of ``MySQLActiveCommandStateMachine``; it is
        /// entered when a command handler's ``MySQLActiveCommandStateMachine/handlerActive(context:)`` method
        /// is called and one of its outgoing transitions takes place when the handler invokes
        /// ``MySQLChannelContext/markCommandComplete()`` (or when the connection is abnormally terminated).
        ///
        /// - Parameters:
        ///   - handler: The handler for the active command.
        ///
        /// ##### Transitions
        /// ||||
        /// -|:-:|-
        /// `commandActive`|→|``ready``
        /// `commandActive`|→|`commandActive`
        /// `awaitingReply`|→|``closed``
        /// `awaitingReply`|→|``terminated(error:)``
        /// ||||
        ///
        /// ##### Valid packets
        /// - _arbitrary_
        case commandActive(handler: any MySQLActiveCommandHandler)
        
        /// The connection was closed gracefully
        ///
        /// Typically this state is reached from the reply to a `COM_QUIT` command. It specifically indicates
        /// a connection which experienced no errors and was gracefully shut down from the client side.
        ///
        /// Once in this state, a connection is no longer usable.
        ///
        /// ##### Transitions
        /// ||||
        /// -|:-:|-
        /// ||_terminal_|||
        /// ||||
        case closed
        
        /// The connection was closed due to an unrecoverable error
        ///
        /// This state occurs when, in any other state, any error which leaves the connection unusable occurs.
        /// This includes "connection closed" errors, server ERR packets with certain error codes, etc. It does
        /// _not_ include transient failures such as query parsing errors or constraint violations, nor does it
        /// occur as a result of "normal" client connection termination (such as by a `COM_QUIT` command).
        ///
        /// Once in this state, a connection is no longer usable.
        ///
        /// - Parameters:
        ///   - error: The error responsible for the connection loss
        ///
        /// ##### Transitions
        /// ||||
        /// -|:-:|-
        /// ||_terminal_|||
        /// ||||
        case terminated(error: any Error)
    }
    
    private var state: State

    // MARK: - Packet dispatcher
    
    /// Handles an arbitrary incoming packet.
    ///
    /// Note that we can not factor OK and ERR packet handling out of the state machines due to several scenarios
    /// where distinguishing either of these and other packets (for example, the numerous possible encodings of
    /// the first packet received as a `COM_QUERY` response) is both highly state-dependent and very complicated.
    mutating func packetReceived(context: MySQLChannelHandlerContext, _ packet: ByteBuffer) throws {
        switch self.state {
        case .awaitingGreeting:
            try context.decodeERRPacketAndReport(from: packet)

            if let handshake = try MySQLPacketDescriptions.HandshakeV10(from: packet) {
                return try self.receivedGreeting(context: context, handshake)
            } else {
                throw MySQLChannel.Error.protocolViolation // we could throw incompatibleServer here, but that's hard to be sure of
            }

        case .waitingForTLSReady(_, _):
            // Possible valid packets: ERR
            try context.decodeERRPacketAndReport(from: packet)
            throw MySQLChannel.Error.protocolViolation

        case .awaitingAuthReply(let authHandler, let secureConnection):
            // Possible valid packets: AuthSwitchRequest, AuthMoreData, AuthNextFactor, OK, ERR
            try context.decodeERRPacketAndReport(from: packet)

            if let _ = try context.decodeOKPacketAndUpdateConnection(from: packet) {
                self.state = .ready
            } else if let switchRequest = try MySQLPacketDescriptions.AuthSwitchPacket(from: packet) {
                try self.receivedAuthSwitch(context: context, switchRequest.newPluginName, data: switchRequest.newPluginData, secureConnection: secureConnection)
            } else if let data = try MySQLPacketDescriptions.AuthMoreDataPacket(from: packet) {
                try self.receivedMoreAuthData(context: context, authHandler, data.data, secureConnection: secureConnection)
            } else {
                throw MySQLChannel.Error.protocolViolation
            }
        
        case .ready:
            // Possible valid packets: ERR
            try context.decodeERRPacketAndReport(from: packet)
            throw MySQLChannel.Error.protocolViolation

        case .commandActive(var handler):
            // Possible valid packets: any, pass to handler
            try handler.packetReceived(context: context, packet)
            self.state = .commandActive(handler: handler)

        case .closed, .terminated(_):
            // No packets are valid in this state. We should never get here.
            assertionFailure("MySQL connection state machine received a packet after connection shutdown")
        }
    }
    
    // MARK: - Lifecycle notifications
    
    /// Reports that a TLS establishment request is complete.
    mutating func tlsEstablished(context: MySQLChannelHandlerContext) throws {
        guard case let .waitingForTLSReady(authMethod: authMethod, authData: authData) = self.state else {
            preconditionFailure("State violation in connection state machine (unexpected TLS establishment notification). Please report a bug.")
        }

        try self.startAuthentication(context: context, plugin: authMethod, authData: authData, secureConnection: true)
    }
    
    /// Requests that a new command handler be made active.
    ///
    /// It is the state machine's responsibility to invoke the new handler's `handlerActive(context:)` method and
    /// perform other appropriate lifecycle handling.
    mutating func activateNewCommand(context: MySQLChannelHandlerContext, handler: any MySQLActiveCommandHandler) throws {
        var handler = handler
        switch self.state {
        case .ready:
            try handler.handlerActive(context: context)
            self.state = .commandActive(handler: handler)
        case .commandActive(handler: var origHandler):
            self.state = .ready // if inactivating old handler or activating new one fails, don't leave the old one in the state
            try origHandler.handlerInactive(context: context)
            try handler.handlerActive(context: context)
            self.state = .commandActive(handler: handler)
            break
        case .awaitingGreeting, .awaitingAuthReply(_, _), .waitingForTLSReady(_, _), .closed, .terminated(_):
            preconditionFailure("State violation in connection state machine (unexpected command activation). Please report a bug.")
        }
    }
    
    /// Reports that the connection has shut down.
    ///
    /// If the given `reason` is not `nil`, the connection was terminated due to an unrecoverable error.
    mutating func connectionClosed(context: MySQLChannelHandlerContext, reason: (any Error)?) {
        switch self.state {
        case .commandActive(handler: var handler):
            // Make sure handler gets closed; ignore any errors.
            try? handler.handlerInactive(context: context)
            fallthrough
        case .awaitingGreeting, .waitingForTLSReady(_, _), .awaitingAuthReply(_, _), .ready:
            if let reason = reason {
                self.state = .terminated(error: reason)
            } else {
                self.state = .closed
            }
        case .closed, .terminated(_):
            // Already closed. We could assert here, but for now just ignore it.
            break
        }
    }
    
    // MARK: - Handshake and authentication
    
    /// Handles an incoming `HandshakeV10` packet.
    private mutating func receivedGreeting(context: MySQLChannelHandlerContext, _ handshake: MySQLPacketDescriptions.HandshakeV10) throws {
        let negotiatedCapabilities = try self.negotiateCapabilities(serverCapabilities: handshake.serverCapabilities, configuration: context.configuration)

        context.storeInitialConnectionInfo(threadId: handshake.threadId, version: handshake.serverVersion, negotiatedCapabilities: negotiatedCapabilities)
        context.statusFlags = handshake.statusFlags
        
        if negotiatedCapabilities.contains(.tls) { // Client asked for TLS and server supports it
            try self.startTLSNegotiation(context: context, plugin: handshake.authPluginName, authData: handshake.authPluginData)
        } else { // No TLS, skip straight to auth in insecure modeosd
            try self.startAuthentication(context: context, plugin: handshake.authPluginName, authData: handshake.authPluginData, secureConnection: false)
        }
    }

    /// Validates a server's offered capability set, decides the client capability set to respond with,
    /// and determines whether TLS negotiation is needed.
    private func negotiateCapabilities(serverCapabilities: MySQLCapabilities, configuration: MySQLChannel.Configuration) throws -> MySQLCapabilities {
        // Make sure the hardcoded protocol flags are there and that our minimum support requirements are met.
        guard serverCapabilities.contains(.requiredCapabilities) else {
            throw MySQLChannel.Error.incompatibleServer
        }
        
        // If we require TLS, make sure the server offers it.
        if configuration.tls.isEnforced {
            guard serverCapabilities.contains(.tls) else {
                throw MySQLChannel.Error.incompatibleServer
            }
        }
        
        // Tweak the expected client capabilities to match the configuration.
        var chosenClientCapabilities = MySQLCapabilities.baselineClientCapabilities
        
        // If a default database is specified by our config, tell the server we're sending it.
        if configuration.database != nil {
            chosenClientCapabilities.insert(.connectWithDatabase)
        }
        
        // If we want TLS and the server offers it, specify it in return; we've already checked the
        // `isEnforced` flag.
        if configuration.tls.isAllowed, serverCapabilities.contains(.tls) {
            chosenClientCapabilities.insert(.tls)
        }
        
        // If the interactive configuration was requested, specify that too.
        if configuration.options.isInteractive {
            chosenClientCapabilities.insert(.interactivity)
        }
        
        // The final client capability set is the intersection of the client and server capabilities.
        // Since a MySQL server will never send "extended" capability flags, this will automatically
        // mask out any MariaDB capabilities we include in our baseline.
        return chosenClientCapabilities.intersection(serverCapabilities)
    }
    
    /// Send a TLS negotiation request packet and trigger TLS negotiation. The same capabilities and
    /// collation must be used for both the `SSLRequest` packet and the later `HandshakeResponse41`
    /// packet (see ``startAuthentication(context:plugin:authData:secureConnection:)``).
    private mutating func startTLSNegotiation(
        context: MySQLChannelHandlerContext,
        plugin authMethod: String,
        authData: ByteBuffer
    ) throws {
        var buffer = ByteBuffer()

        MySQLPacketDescriptions.SSLRequest(
            clientCapabilities: context.capabilities,
            collation: MySQLTextCollation.bestCollation(forVersion: context.serverVersion, capabilities: context.capabilities).idForHandshake
        ).write(to: &buffer)

        context.sendPacket(buffer)
        context.attemptTLSNegotiation()
        self.state = .waitingForTLSReady(authMethod: authMethod, authData: authData)
    }

    /// Begin the authentication process with a handshake reply packet; can be entered directly from
    /// handling the server handshake or after sucessfully enabling TLS.
    private mutating func startAuthentication(
        context: MySQLChannelHandlerContext,
        plugin authMethod: String,
        authData: ByteBuffer,
        secureConnection: Bool
    ) throws {
        guard var newHandler = MySQLBuiltinAuthHandlers.authHandler(for: authMethod) else {
            throw MySQLChannel.Error.unknownAuthMethod(authMethod)
        }
        let responseData = try newHandler.processData(authData, configuration: context.configuration, connectionIsSecure: secureConnection)
        var buffer = ByteBuffer()
        MySQLPacketDescriptions.HandshakeResponse41(
            clientCapabilities: context.capabilities,
            collation: MySQLTextCollation.bestCollation(forVersion: context.serverVersion, capabilities: context.capabilities).idForHandshake,
            username: context.configuration.username,
            clientAuthPluginName: authMethod,
            authPluginResponseData: responseData ?? .init(),
            connectionAttributes: .init(uniqueKeysWithValues: context.connectionAttributes),
            initialDatabase: context.configuration.database,
            zstdCompressionLevel: nil
        ).write(to: &buffer, activeCapabilities: context.capabilities)

        self.state = .awaitingAuthReply(authHandler: newHandler, secureConnection: secureConnection)
        context.sendPacket(buffer)
    }

    /// Handles an incoming `AuthMoreData` packet.
    private mutating func receivedMoreAuthData(context: MySQLChannelHandlerContext, _ authHandler: any MySQLBuiltinAuthHandler, _ data: ByteBuffer, secureConnection: Bool) throws {
        // State correctness already checked by caller
        var authHandler = authHandler
        if let packet = try authHandler.processData(data, configuration: context.configuration, connectionIsSecure: secureConnection) {
            context.sendPacket(packet)
        }
        self.state = .awaitingAuthReply(authHandler: authHandler, secureConnection: secureConnection)
    }
    
    /// Handles an incoming `AuthSwitchRequest`.
    private mutating func receivedAuthSwitch(
        context: MySQLChannelHandlerContext, _ method: String, data: ByteBuffer, secureConnection: Bool
    ) throws {
        // State correctness already checked by caller
        guard var newHandler = MySQLBuiltinAuthHandlers.authHandler(for: method) else {
            throw MySQLChannel.Error.unknownAuthMethod(method)
        }
        if let packet = try newHandler.processData(data, configuration: context.configuration, connectionIsSecure: secureConnection) {
            context.sendPacket(packet)
        }
        self.state = .awaitingAuthReply(authHandler: newHandler, secureConnection: secureConnection)
    }
    
}
