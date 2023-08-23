import Foundation
import Logging
import NIOCore
import NIOSSL
import NIOTLS
import Collections

extension MySQLChannel {
    /// Serves as both the primary channel handler for MySQL channels and as the "top-level" state machine covering
    /// the lifecycle of a MySQL server connection.
    ///
    /// Unlike the "official documentation" (which is difficult to consider worthy of the name), we do not treat the
    /// entire "connection phase" as a single top-level state; instead, the various "sub-states" of the connection phase
    /// are individual states in this machine.
    ///
    /// ## See Also
    ///
    /// - [MySQL Client/Server Protocol documentation](https://dev.mysql.com/doc/dev/mysql-server/latest/PAGE_PROTOCOL.html)
    /// - [MariaDB Client/Server Protocol documentation](https://mariadb.com/kb/en/clientserver-protocol/)
    final class Handler: ChannelDuplexHandler {
        typealias OutboundIn = ClientRequest
        typealias OutboundOut = ByteBuffer
        typealias InboundIn = ByteBuffer
        
        // MARK:  - States

        /// The defined states and transitions for the overall connection lifecycle
#if swift(>=5.9) && $AttachedMacros
        @StateMachineStateConditions
#endif
        enum State {
            /// Initial state, waiting for active channel
            case startup
            /// Channel active, waiting for server handshake
            case awaitingGreeting
            /// TLS establishment pending
            case waitingForTLSReady(handshake: MySQLPackets.HandshakeV10)
            /// Waiting for a reply during the authentication process
            case awaitingAuthReply(handshake: MySQLPackets.HandshakeV10, authHandler: any MySQLBuiltinAuthHandler, secureConnection: Bool)
            /// Command mode with no commands running or queued
            case idle
            /// A ping or reset command is in progress
            case awaitingOK(promise: EventLoopPromise<Void>?)
            /// A statistics request is waiting for a result
            case gettingStatistics(promise: EventLoopPromise<String>)
            /// A plain query is in progress
            case runningPlainQuery(stateMachine: PlainQuery.StateMachine)
            /// A prepared statement is being prepared
            case preparingStatement(stateMachine: PrepareStatement.StateMachine)
            /// A prepared statement is being executed
            case executingStatement(stateMachine: ExecuteStatement.StateMachine)
            /// Data is being fetched from a cursor after a prepared statement was executed
            case fetchingCursorData(stateMachine: FetchCursorData.StateMachine)
            /// The connection was closed, possibly due to an error
            case closed(reason: (any Swift.Error)?)
            /// CoW-prevention pseudo-state
            case modifyingState
        }
        
        /// The defined set of reactions which may occur in response to any given event in any particular state.
        enum Reaction {
            /// Generic reaction: Do nothing, just wait.
            case wait
            /// Generic reaction: Issue an explicit read.
            case read
            /// Send the provided `SSLRequest` and start TLS.
            case initiateTLS(request: MySQLPackets.SSLRequest)
            /// Use the given attributes and auth handler to send a `HandshakeResponse41`.
            case replyToHandshake(response: MySQLPackets.HandshakeResponse41)
            /// Send the given auth data and wait for more.
            case singleStepAuth(data: ByteBuffer?)
            /// Signal authentication success and readiness to begin processing requests.
            case signalSuccessfulHandshake(serverVersion: String, connectionIdentifier: UInt32)
            /// Send a ping.
            case sendPing
            /// Request server statistics.
            case sendRequestStatistics
            /// Issue a connection reset command.
            case sendResetConnectionState
            /// Perform a statement prepare.
            case sendStatementPrepare(PrepareStatement.Context)
            /// Perform a statement reset.
            case sendStatementReset(ResetStatement.Context)
            /// Perform a statement deallocate.
            case sendStatementDeallocate(DeallocateStatement.Context)
            /// Perform a plain query.
            case sendPlainQuery(PlainQuery.Context)
            /// Perform a prepared statement execute.
            case sendPreparedStatementExecute(ExecuteStatement.Context)
            /// Perform a cursor data fetch.
            case sendCursorDataFetch(FetchCursorData.Context)
            /// Initiate an orderly connection teardown.
            case sendQuit
            /// Handle an error.
            case handleError(_ error: any Swift.Error)
            
            static func handleError(thrownOrReturnedBy: () throws -> some Swift.Error) -> Reaction {
                do {
                    return .handleError(try thrownOrReturnedBy())
                } catch {
                    return .handleError(error)
                }
            }
        }
    
        // MARK: - Implementation

        var readyFuture: EventLoopFuture<(serverVersion: String, connectionIdentifier: UInt32)> { self.readyPromise.futureResult }
        
        private let logger: Logger
        private let lowLevelTracingLogger: Logger?
        private let configuration: Configuration
        
        private var capabilities: MySQLCapabilities = .baselineClientCapabilities
        private var statusFlags: MySQLServerStatusFlags = []
        
        // private var currentSchema: String? { get set }
        // private var lastReportedSessionStatus: String? { get set }
        // private var lastKnownQueryMetadata: MySQLQueryMetadata? { get set }
        
        private var requestQueue: Deque<ClientRequest> = []
        private var state: State = .startup
        private var transcoder: NonThrowingMessageByteTranscodingProcessor<MySQLRawPacketCodec>!
        private var readyPromise: EventLoopPromise<(serverVersion: String, connectionIdentifier: UInt32)>!
        
        init(configuration: Configuration, logger: Logger, lowLevelTracingLogger: Logger? = nil) {
            self.configuration = configuration
            self.logger = logger
            self.lowLevelTracingLogger = lowLevelTracingLogger
        }
        
        // MARK: - Channel handler

        func handlerAdded(context: ChannelHandlerContext) {
            guard self.state.isStartup else {
                stateViolation("handler already started before being added")
            }
            
            self.transcoder = .init(MySQLRawPacketCodec(), maximumDecodeBufferSize: nil, encodeBuffer: context.channel.allocator.buffer(capacity: 16384))
            self.readyPromise = context.eventLoop.makePromise()

            if context.channel.isActive {
                self.channelActive(context: context)
            }
        }
        
        func handlerRemoved(context: ChannelHandlerContext) {
            guard self.state.isClosed else {
                stateViolation("channel not closed when handler removed")
            }
            // Nothing to do here
        }

        func channelActive(context: ChannelHandlerContext) {
            guard self.state.isStartup else {
                stateViolation("channel active but handler already started")
            }
            
            self.react(to: self.updateStateSafely { state in
                state = .awaitingGreeting
                return .read
            }, context: context)
        }

        func teardownState(reason: any Swift.Error) {
            switch self.state {
            case .startup:
                stateViolation("can't tear down without setting up")
            case .awaitingGreeting, .waitingForTLSReady, .awaitingAuthReply:
                self.readyPromise.fail(reason)
            case .idle:
                break
            case .awaitingOK(let promise):
                promise?.fail(reason)
            case .gettingStatistics(let promise):
                promise.fail(reason)
            case .runningPlainQuery(var stateMachine):
                stateMachine.teardownState(reason: reason)
            case .preparingStatement(var stateMachine):
                stateMachine.teardownState(reason: reason)
            case .executingStatement(var stateMachine):
                stateMachine.teardownState(reason: reason)
            case .fetchingCursorData(var stateMachine):
                stateMachine.teardownState(reason: reason)
            case .closed:
                stateViolation("can't tear down multiple times")
            case .modifyingState:
                stateViolation("broken state update")
            }
            while let request = self.requestQueue.popLast() {
                switch request {
                case .ping(let promise):                promise.fail(reason)
                case .resetAllState(let promise):       promise.fail(reason)
                case .getStatistics(let promise):       promise.fail(reason)
                case .plainQuery(let context):          context.promise.fail(reason)
                case .prepareStatement(let context):    context.promise.fail(reason)
                case .executeStatement(let context):    context.promise.fail(reason)
                case .fetchCursorData(let context):     context.promise.fail(reason)
                case .resetStatement(let context):      context.promise.fail(reason)
                case .deallocateStatement(let context): context.promise.fail(reason)
                case .quit:                             break
                }
            }
            _ = self.updateStateSafely { state in
                state = .closed(reason: reason)
                return .wait
            }
        }

        func channelInactive(context: ChannelHandlerContext) {
            guard !self.state.isStartup else {
                stateViolation("channel deactivated without being active")
            }
            
            do {
                try self.transcoder.finishProcessing(seenEOF: true) { buffer in
                    self.react(to: self.handlePacketRead(buffer), context: context)
                }
            } catch let error as MySQLRawPacketCodec.Error {
                self.react(to: self.handleError(error), context: context)
            } catch {
                preconditionFailure("Inappropriate error received by channel handler. Please report a bug.")
            }
            self.react(to: self.handleConnectionClose(reason: nil), context: context)
        }

        func errorCaught(context: ChannelHandlerContext, error: any Swift.Error) {
            self.react(to: self.handleError(MySQLCoreError.connection(underlying: error)), context: context)
        }
        
        func channelRead(context: ChannelHandlerContext, data: NIOAny) {
            let data = self.unwrapInboundIn(data)
            
            do {
                try self.transcoder.process(buffer: data) { buffer in
                    self.react(to: self.handlePacketRead(buffer), context: context)
                }
            } catch let error as MySQLRawPacketCodec.Error {
                self.react(to: self.handleError(error), context: context)
            } catch {
                preconditionFailure("Inappropriate error received by channel handler. Please report a bug.")
            }
        }
        
        func userInboundEventTriggered(context: ChannelHandlerContext, event: Any) {
            switch (event, self.state) {
                case (TLSUserEvent.handshakeCompleted, .waitingForTLSReady(handshake: let handshake)):
                    self.react(to: self.handleTLSHandshakeCompleted(handshake), context: context)
                default:
                    context.fireUserInboundEventTriggered(event)
            }
        }
        
        func write(context: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
            let message = self.unwrapOutboundIn(data)
            
            switch self.state {
            case .startup, .awaitingGreeting, .waitingForTLSReady, .awaitingAuthReply:
                stateViolation("request written before handshake complete")
            case .idle:
                break
            case .awaitingOK, .gettingStatistics, .runningPlainQuery, .preparingStatement, .executingStatement, .fetchingCursorData:
                self.requestQueue.prepend(message)
            case .inactivating, .closed:
                fatalError()
            case .modifyingState:
                stateViolation("broken state update")
            }
        }
        
        func close(context: ChannelHandlerContext, mode: CloseMode, promise: EventLoopPromise<Void>?) {
            guard mode == .all else {
                return promise?.fail(ChannelError.operationUnsupported) ?? ()
            }
            self.react(to: self.handleConnectionClose(reason: ChannelError.inputClosed), context: context)
        }
        
        // MARK: - Reactions
        
        private func react(to reaction: Reaction, context: ChannelHandlerContext) {
            switch reaction {
            case .wait:
                break
            case .read:
                context.read()
            case .initiateTLS(request: let request):
                do {
                    guard self.transcoder.unprocessedBytes == 0 else {
                        return self.react(to: .handleError(MySQLCoreError.protocolViolation(debugDescription: "Extra data received during TLS setup")), context: context)
                    }
                    guard let sslContext = self.configuration.tls.sslContext else {
                        stateViolation("asked to initiate TLS but no context configured")
                    }

                    let handlerBox = UnsafeTransfer(try NIOSSLClientHandler(context: sslContext, serverHostname: self.configuration.options.tlsServerName))
                    let contextBox = UnsafeTransfer(context)
                    context.writeAndFlush(self.wrapOutboundOut(self.transcoder.processAndFlush(message: request.build()))).whenSuccess {
                        // TODO: Is there any point to catching and reporting errors, either from this try or from the writeAndFlush() operation?
                        try? contextBox.wrappedValue.channel.pipeline.syncOperations.addHandler(handlerBox.wrappedValue, position: .first)
                    }
                } catch {
                    self.react(to: self.handleError(MySQLCoreError.connection(underlying: error)), context: context)
                }
            case .replyToHandshake(response: let response):
                context.writeAndFlush(self.wrapOutboundOut(response.build(allocator: context.channel.allocator)), promise: nil)
            case .singleStepAuth(data: let data):
                if let data {
                    context.writeAndFlush(self.wrapOutboundOut(data), promise: nil)
                }
            case .signalSuccessfulHandshake(serverVersion: let serverVersion, connectionIdentifier: let connectionIdentifier):
                self.readyPromise.succeed((serverVersion: serverVersion, connectionIdentifier: connectionIdentifier))
            case .sendPing:
                break
            case .sendRequestStatistics:
                break
            case .sendResetConnectionState:
                break
            case .sendStatementPrepare(let _):
                break
            case .sendStatementReset(let _):
                break
            case .sendStatementDeallocate(let _):
                break
            case .sendPlainQuery(let plainQueryContext):
                break
            case .sendPreparedStatementExecute(let _):
                break
            case .sendCursorDataFetch(let _):
                break
            case .sendQuit:
                break
            case .handleError/*(let error)*/:
                break
            }
        }
        
        // MARK: - Primary event handling
        
        /// Handles an arbitrary incoming packet.
        ///
        /// Per <doc:Packet-Decoding-Matrix>, the only packet type that can be handled 100% generically is the error
        /// packet; it's the only one that is valid in every nonterminal state. However, we don't do exactly that;
        /// in states that have their own state machines, we pass such packets on to those state machines. This allows
        /// the error to include more detailed and accurate context information.
        private func handlePacketRead(_ packet: ByteBuffer) -> Reaction {
            switch self.state {
            case .startup:
                stateViolation("received packet before being initialized")
                
            case .awaitingGreeting:
                if packet.mysql_marker() == MySQLPackets.ERRPacket.markerByte {
                    return .handleError { MySQLCoreError.server(errorPacket: try .init(from: packet)) }
                }
                return self.handleGreeting(packet)
            
            case .waitingForTLSReady:
                if packet.mysql_marker() == MySQLPackets.ERRPacket.markerByte {
                    return .handleError { MySQLCoreError.server(errorPacket: try .init(from: packet)) }
                } else {
                    return .handleError(MySQLCoreError.protocolViolation(debugDescription: "non-error packet while waiting for TLS negotiation"))
                }
            
            case .awaitingAuthReply(let handshake, let authHandler, let secureConnection):
                switch packet.mysql_marker() {
                case MySQLPackets.AuthMoreDataPacket.markerByte:
                    return self.handleMoreAuthData(packet: packet, handshake: handshake, authHandler: authHandler, secureConnection: secureConnection)
                case MySQLPackets.AuthSwitchPacket.markerByte:
                    return self.handleAuthSwitchRequest(packet: packet, handshake: handshake, secureConnection: secureConnection)
                case MySQLPackets.OKPacket.markerByteOK:
                    return self.handleAuthSuccess(packet: packet, handshake: handshake)
                case MySQLPackets.ERRPacket.markerByte:
                    return .handleError { MySQLCoreError.server(errorPacket: try .init(from: packet)) }
                default:
                    return .handleError(MySQLCoreError.protocolViolation(debugDescription: "unknown packet during authentication"))
                }
            
            case .idle:
                if packet.mysql_marker() == MySQLPackets.ERRPacket.markerByte {
                    return .handleError { MySQLCoreError.server(errorPacket: try .init(from: packet)) }
                } else {
                    return .handleError(MySQLCoreError.protocolViolation(debugDescription: "non-error packet while idle"))
                }
            
            case .awaitingOK(promise: let promise):
                if packet.mysql_marker() == MySQLPackets.ERRPacket.markerByte {
                    return .handleError { MySQLCoreError.server(errorPacket: try .init(from: packet)) }
                } else if packet.mysql_marker() == MySQLPackets.OKPacket.markerByteOK {
                    do {
                        let packet = try MySQLPackets.OKPacket(from: packet, activeCapabilities: self.capabilities)
                        self.statusFlags = packet.statusFlags
                        promise?.succeed()
                        return self.handleRequestComplete()
                    } catch {
                        return .handleError(error)
                    }
                }
            
            case .gettingStatistics(promise: let promise):
                if packet.mysql_marker() == MySQLPackets.ERRPacket.markerByte {
                    return .handleError { MySQLCoreError.server(errorPacket: try .init(from: packet)) }
                } else if [9...10, 13...13, 32...126].flatMap({$0}).contains(packet.mysql_marker() ?? 0) {
                    promise.succeed(packet.mysql_string()!)
                    return self.handleRequestComplete()
                } else {
                    return .handleError(MySQLCoreError.protocolViolation(debugDescription: "invalid data in statistics reply"))
                }
            
            case .runningPlainQuery(stateMachine: var stateMachine):
                return stateMachine.handlePacketRead(packet)
            
            case .preparingStatement(stateMachine: let stateMachine):
                <#code#>
            
            case .executingStatement(stateMachine: let stateMachine):
                <#code#>
            
            case .fetchingCursorData(stateMachine: let stateMachine):
                <#code#>
            
            case .inactivating(reason: let reason):
                <#code#>
            
            case .closed:
                // This might happen if there's still buffered data to process after a close event, ignore
                self.logger.debug("Ignoring packet with marker \(packet.mysql_marker().map { "\($0)" } ?? "<none>") on closed connection")
            
            case .modifyingState:
                stateViolation("broken state update")
            }
            /*
        
            switch self.state {
            case .awaitingOK(statistics: _, promise: let promise):
                try context.decodeERRPacketAndReport(from: packet)
                
                guard try context.decodeOKPacketAndUpdateConnection(from: packet) != nil else {
                    throw MySQLChannel.Error.protocolViolation
                }
                promise?.succeed()
                self.state = .idle
            
            case .runningPlainQuery(stateMachine: var stateMachine):
                try stateMachine.packetReceived(context: context, packet)
                self.state = .runningPlainQuery(stateMachine: stateMachine)

            case .preparingStatement(stateMachine: var stateMachine):
                try stateMachine.packetReceived(context: context, packet)
                self.state = .preparingStatement(stateMachine: stateMachine)

            case .executingStatement(stateMachine: var stateMachine):
                try stateMachine.packetReceived(context: context, packet)
                self.state = .executingStatement(stateMachine: stateMachine)

            case .fetchingCursorData(stateMachine: var stateMachine):
                try stateMachine.packetReceived(context: context, packet)
                self.state = .fetchingCursorData(stateMachine: stateMachine)

            case .closed:
                // No packets are valid in this state. We should never get here.
                assertionFailure("MySQL connection state machine received a packet after connection shutdown")
            }
            */
        }
        
        /// Some kind of error happened.
        private func handleError(_ error: any Swift.Error) -> Reaction {
        
        }
        
        /// A TLS establishment request is complete.
        private func handleTLSHandshakeCompleted(_ handshake: MySQLPackets.HandshakeV10) -> Reaction {
            guard self.transcoder.unprocessedBytes == 0 else {
                return .handleError(MySQLCoreError.protocolViolation(debugDescription: "Extra data received during TLS setup"))
            }

            return self.startAuthentication(handshake: handshake, secureConnection: true)
        }
        
        /// The connection has shut down or wants to shut down.
        ///
        /// If the given `reason` is not `nil`, the connection was terminated due to an unrecoverable error.
        private func handleConnectionClose(reason: (any Error)?) -> Reaction {
/*            switch self.state {
            case .awaitingOK(statistics: _, promise: _), .runningPlainQuery(stateMachine: _), .preparingStatement(stateMachine: _), .executingStatement(stateMachine: _), .fetchingCursorData(stateMachine: _):
                fatalError()
            case .awaitingGreeting, .waitingForTLSReady(_, _), .awaitingAuthReply(_, _), .idle:
                if let reason = reason {
                    self.state = .terminated(error: reason)
                } else {
                    self.state = .closed
                }
            case .closed, .terminated(_):
                // Already closed. We could assert here, but for now just ignore it.
                break
            }
 */
        }
        
        /// The most recent request is complete. Update state accordingly.
        private func handleRequestComplete() -> Reaction {
            fatalError()
        }
        
        // MARK: - Handshake and authentication

        /// Handles an incoming `HandshakeV10` packet.
        private func handleGreeting(_ packet: ByteBuffer) -> Reaction {
            do {
                let handshake = try MySQLPackets.HandshakeV10(from: packet)
                
                self.capabilities = try self.negotiateCapabilities(serverCapabilities: handshake.serverCapabilities)
                self.statusFlags = handshake.statusFlags

                if self.capabilities.contains(.tls) { // Client asked for TLS and server supports it
                    return self.updateStateSafely { state in
                        state = .waitingForTLSReady(handshake: handshake)
                        return .initiateTLS(request: .init(
                            clientCapabilities: self.capabilities,
                            collation: MySQLTextCollation.bestCollation(forVersion: handshake.serverVersion, capabilities: self.capabilities).idForHandshake
                        ))
                    }
                } else { // No TLS, skip straight to auth in insecure mode
                    return self.startAuthentication(handshake: handshake, secureConnection: false)
                }
            } catch {
                return .handleError(error)
            }
        }

        /// Validates a server's offered capability set, decides the client capability set to respond with,
        /// and determines whether TLS negotiation is needed.
        private func negotiateCapabilities(serverCapabilities: MySQLCapabilities) throws -> MySQLCapabilities {
            // Make sure the hardcoded protocol flags are there and that our minimum support requirements are met.
            guard serverCapabilities.contains(.requiredCapabilities) else {
                throw MySQLCoreError.incompatibleServer(debugDescription: "Required capabilities not available")
            }
            
            // If we require TLS, make sure the server offers it.
            if self.configuration.tls.isEnforced {
                guard serverCapabilities.contains(.tls) else {
                    throw MySQLCoreError.incompatibleServer(debugDescription: "TLS required but not supported by server")
                }
            }
            
            // Use the context's initial capability flags as the starting point for the client's capabilities,
            // then tweak those capabilities to match the configuration.
            var chosenClientCapabilities = self.capabilities
            
            // If a default database is specified by our config, tell the server we're sending it.
            if self.configuration.database != nil {
                chosenClientCapabilities.insert(.connectWithDatabase)
            }
            
            // If we want TLS and the server offers it, specify it in return; we've already checked the
            // `isEnforced` flag.
            if self.configuration.tls.isAllowed, serverCapabilities.contains(.tls) {
                chosenClientCapabilities.insert(.tls)
            }
            
            // If the interactive configuration was requested, specify that too.
            if self.configuration.options.isInteractive {
                chosenClientCapabilities.insert(.interactivity)
            }
            
            // The final client capability set is the intersection of the client and server capabilities.
            // Since a MySQL server will never send "extended" capability flags, this will automatically
            // mask out any MariaDB capabilities we include in our baseline.
            return chosenClientCapabilities.intersection(serverCapabilities)
        }
        
        /// Begin the authentication process with a handshake reply packet; can be entered directly from
        /// handling the server handshake or after sucessfully enabling TLS.
        private func startAuthentication(
            handshake: MySQLPackets.HandshakeV10,
            secureConnection: Bool
        ) -> Reaction {
            guard var newHandler = MySQLBuiltinAuthHandlers.authHandler(for: handshake.authPluginName) else {
                return .handleError(MySQLCoreError.unknownAuthMethod(name: handshake.authPluginName))
            }
            
            let responseData: ByteBuffer?
            do {
                responseData = try newHandler.processData(handshake.authPluginData, configuration: self.configuration, connectionIsSecure: secureConnection)
            } catch {
                return .handleError(MySQLCoreError.authenticationFailure(underlying: error))
            }
            
            let response = MySQLPackets.HandshakeResponse41(
                clientCapabilities: self.capabilities,
                collation: MySQLTextCollation.bestCollation(forVersion: handshake.serverVersion, capabilities: self.capabilities).idForHandshake,
                username: self.configuration.username,
                clientAuthPluginName: handshake.authPluginName,
                authPluginResponseData: responseData ?? .init(),
                connectionAttributes: Self.builtinConnectionAttributes.merging(self.configuration.options.connectionAttributes) { $1 },
                initialDatabase: self.configuration.database,
                zstdCompressionLevel: nil
            )
            
            return self.updateStateSafely { state in
                state = .awaitingAuthReply(handshake: handshake, authHandler: newHandler, secureConnection: secureConnection)
                return .replyToHandshake(response: response)
            }
        }
        
        private static let builtinConnectionAttributes: OrderedDictionary<String, String> = { [
            //"_client_name":     "mysql-nio",
            //"_client_version":  "2.0.0",
            "_os":                ProcessInfo.processInfo.operatingSystemPlainName.lowercased(),
            "_pid":               _isDebugAssertConfiguration() ? "\(ProcessInfo.processInfo.processIdentifier)" : "-1",
            "_platform":          ProcessInfo.processInfo.hostArchitectureName,
            "_client_license":    "MIT",
            "_source_host":       _isDebugAssertConfiguration() ? ProcessInfo.processInfo.hostName : "localhost",
            "_runtime_vendor":    "Apple",
            "_runtime_version":   ProcessInfo.processInfo.swiftRuntimeVersion,
            "_connector_version": "2.0.0",
            "_connector_name":    "mysql-nio",
            "os_user":            _isDebugAssertConfiguration() ? ProcessInfo.processInfo.userName : "user",
            "program_name":       _isDebugAssertConfiguration() ? ProcessInfo.processInfo.processName : "sh",
        ] }()

        /// Handles an incoming `AuthMoreData` packet.
        private func handleMoreAuthData(packet: ByteBuffer, handshake: MySQLPackets.HandshakeV10, authHandler: any MySQLBuiltinAuthHandler, secureConnection: Bool) -> Reaction {
            do {
                var authHandler = authHandler
                let packet = try MySQLPackets.AuthMoreDataPacket(from: packet)
                let reply = try authHandler.processData(packet.data, configuration: self.configuration, connectionIsSecure: secureConnection)
                
                return self.updateStateSafely { state in
                    state = .awaitingAuthReply(handshake: handshake, authHandler: authHandler, secureConnection: secureConnection)
                    return .singleStepAuth(data: reply)
                }
            } catch {
                return .handleError(error)
            }
        }
        
        /// Handles an incoming `AuthSwitchRequest`.
        private func handleAuthSwitchRequest(packet: ByteBuffer, handshake: MySQLPackets.HandshakeV10, secureConnection: Bool) -> Reaction {
            do {
                let packet = try MySQLPackets.AuthSwitchPacket(from: packet)
                guard var newHandler = MySQLBuiltinAuthHandlers.authHandler(for: packet.newPluginName) else {
                    throw MySQLCoreError.unknownAuthMethod(name: packet.newPluginName)
                }
                let reply = try newHandler.processData(packet.newPluginData, configuration: self.configuration, connectionIsSecure: secureConnection)
                
                return self.updateStateSafely { state in
                    state = .awaitingAuthReply(handshake: handshake, authHandler: newHandler, secureConnection: secureConnection)
                    return .singleStepAuth(data: reply)
                }
            } catch {
                return .handleError(error)
            }
        }
        
        /// Handles an incoming `OKPacket` while authenticating.
        private func handleAuthSuccess(packet: ByteBuffer, handshake: MySQLPackets.HandshakeV10) -> Reaction {
            do {
                let packet = try MySQLPackets.OKPacket(from: packet, activeCapabilities: self.capabilities)
                
                self.statusFlags = packet.statusFlags
                return self.updateStateSafely { state in
                    state = .idle
                    return .signalSuccessfulHandshake(serverVersion: handshake.serverVersion, connectionIdentifier: handshake.threadId)
                }
            } catch {
                return .handleError(error)
            }
        }
    }
}

// MARK: - State management

extension MySQLChannel.Handler {
    private func stateViolation(_ message: @autoclosure () -> String, file: StaticString = #file, line: UInt = #line) -> Never {
        preconditionFailure("State violation in connection state machine (\(message())). Please report a bug.", file: file, line: line)
    }

    private func updateStateSafely(_ body: (inout State) -> Reaction) -> Reaction {
        self.state = .modifyingState
        defer { assert(!self.state.isModifyingState) }
        return body(&self.state)
    }
}

#if compiler(>=5.9) && $AttachedMacros

@attached(member, names: arbitrary)
public macro StateMachineStateConditions() = #externalMacro(module: "MySQLNIOCoreMacros", type: "StateMachineStateConditions")

#else

extension MySQLChannel.Handler.State {
    var isStartup: Bool            { guard case .startup            = self else { return false }; return true }
    var isAwaitingGreeting: Bool   { guard case .awaitingGreeting   = self else { return false }; return true }
    var isWaitingForTLSReady: Bool { guard case .waitingForTLSReady = self else { return false }; return true }
    var isAwaitingAuthReply: Bool  { guard case .awaitingAuthReply  = self else { return false }; return true }
    var isIdle: Bool               { guard case .idle               = self else { return false }; return true }
    var isAwaitingOK: Bool         { guard case .awaitingOK         = self else { return false }; return true }
    var isGettingStatistics: Bool  { guard case .gettingStatistics  = self else { return false }; return true }
    var isRunningPlainQuery: Bool  { guard case .runningPlainQuery  = self else { return false }; return true }
    var isPreparingStatement: Bool { guard case .preparingStatement = self else { return false }; return true }
    var isExecutingStatement: Bool { guard case .executingStatement = self else { return false }; return true }
    var isFetchingCursorData: Bool { guard case .fetchingCursorData = self else { return false }; return true }
    var isClosed: Bool             { guard case .closed             = self else { return false }; return true }
    var isModifyingState: Bool     { guard case .modifyingState     = self else { return false }; return true }
}

#endif
