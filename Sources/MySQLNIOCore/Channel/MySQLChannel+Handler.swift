import Foundation
import Logging
import NIOConcurrencyHelpers
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
            
            /// True if the state is alive (e.g. neither ``startup`` nor ``closed(reason:)``).
            var isAlive: Bool {
                switch self {
                case .startup, .closed: return false
                default: return true
                }
            }
            
            /// True if the state is in the authentication phase.
            var isAuthenticating: Bool {
                switch self {
                case .awaitingGreeting, .waitingForTLSReady, .awaitingAuthReply: return true
                default: return false
                }
            }
            
            /// True if the state is in the connection phase (able to execute commands).
            var isConnected: Bool { self.isAlive && !self.isAuthenticating }
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
            /// Proceed to the next queued request, if any.
            case startNextRequest
            /// Send a ping.
            case sendPing
            /// Request server statistics.
            case sendRequestStatistics
            /// Issue a connection reset command.
            case sendResetConnectionState
            /// Perform a plain query.
            case sendPlainQuery(MySQLPackets.PlainQueryCommand)
            /// Perform a statement prepare.
            case sendStatementPrepare(()/*PrepareStatement.Context*/)
            /// Perform a prepared statement execute.
            case sendPreparedStatementExecute(()/*ExecuteStatement.Context*/)
            /// Perform a statement reset.
            case sendStatementReset(()/*ResetStatement.Context*/)
            /// Perform a statement deallocate.
            case sendStatementDeallocate(()/*DeallocateStatement.Context*/)
            /// Perform a cursor data fetch.
            case sendCursorDataFetch(()/*FetchCursorData.Context*/)
            /// Initiate an orderly connection teardown.
            case sendQuit
            /// Update the server status flags, then handle the nested reaction.
            indirect case updateStatusFlags(MySQLServerStatusFlags, then: Reaction)
            /// Trigger a client-side close of the connection, if the server hasn't already closed it.
            case haltAndCatchFire
            /// Handle an error.
            case handleError(any Swift.Error)
            /// Re-raise an error.
            case fireErrorCaught(any Swift.Error)
            
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
        
        private static let localIdGenerator = NIOLockedValueBox<UInt32>(0)
        
        private var logger: Logger
        private let configuration: Configuration
        private let localId: UInt32
        
        private var capabilities: MySQLCapabilities = .baselineClientCapabilities
        private var statusFlags: MySQLServerStatusFlags = []
        
        // private var currentSchema: String? { get set }
        // private var lastReportedSessionStatus: String? { get set }
        // private var lastKnownQueryMetadata: MySQLQueryMetadata? { get set }
        
        private var requestQueue: Deque<ClientRequest> = []
        private var state: State = .startup
        private var transcoder: NonThrowingMessageByteTranscodingProcessor<MySQLRawPacketCodec>!
        private var readyPromise: EventLoopPromise<(serverVersion: String, connectionIdentifier: UInt32)>!
        
        init(configuration: Configuration, logger: Logger) {
            var logger = logger
            let localId = Self.localIdGenerator.withLockedValue { ($0 &+= 1, $0).1 }
            
            logger[metadataKey: "local-id"] = .stringConvertible(localId)

            self.configuration = configuration
            self.logger = logger
            self.localId = localId
        }
        
        // MARK: - Channel handler
        
        // MARK: Bringup
        
        func handlerAdded(context: ChannelHandlerContext) {
            stateCheck(self.state.isStartup, "handler already started before being added")
            
            self.transcoder = .init(MySQLRawPacketCodec(), maximumDecodeBufferSize: nil, encodeBuffer: context.channel.allocator.buffer(capacity: 16384))
            self.readyPromise = context.eventLoop.makePromise()
            
            self.logger.trace("MySQL channel handler starting up")

            if context.channel.isActive {
                self.channelActive(context: context)
            }
        }
        
        func channelActive(context: ChannelHandlerContext) {
            stateCheck(self.state.isStartup, "channel active but handler already started")
            
            self.state = .awaitingGreeting
            self.logger.debug("MySQL channel now active")
        }

        // MARK: Incoming/Outgoing

        func channelRead(context: ChannelHandlerContext, data: NIOAny) {
            let data = self.unwrapInboundIn(data)
            
            do {
                try self.transcoder.process(buffer: data) { buffer in
                    self.logger.trace("MySQL channel processing buffer: \(buffer.readableBytesView.prefix(32))")
                    self.react(to: self.handlePacketRead(buffer), context: context)
                }
            } catch let error as MySQLRawPacketCodec.Error {
                self.react(to: .handleError(MySQLCoreError.protocolViolation(debugDescription: "Low-level packet framing error: \(error)")), context: context)
            } catch {
                preconditionFailure("Inappropriate error received by channel handler. Please report a bug.")
            }
        }
        
        func write(context: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
            let message = self.unwrapOutboundIn(data)
            
            self.logger.trace("MySQL channel queuing request \(message)")
            switch self.state {
            case .startup, .awaitingGreeting, .waitingForTLSReady, .awaitingAuthReply:
                stateCheckFailure("request written before handshake complete")
            case .idle:
                self.requestQueue.prepend(message)
                self.react(to: .startNextRequest, context: context)
            case .awaitingOK, .gettingStatistics, .runningPlainQuery, .preparingStatement, .executingStatement, .fetchingCursorData:
                self.requestQueue.prepend(message)
            case .closed:
                stateCheckFailure("request written after connection closed")
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
        
        // MARK: Takedown

        func close(context: ChannelHandlerContext, mode: CloseMode, promise: EventLoopPromise<Void>?) {
            guard mode == .all else {
                return promise?.fail(ChannelError.operationUnsupported) ?? ()
            }
            self.logger.trace("MySQL channel got close request in mode \(mode)")
            self.react(to: self.handleConnectionClose(reason: ChannelError.inputClosed), context: context)
        }
        
        func channelInactive(context: ChannelHandlerContext) {
            self.logger.trace("MySQL channel inactive, finishing processing")
            do {
                try self.transcoder.finishProcessing(seenEOF: true) { buffer in
                    self.react(to: self.handlePacketRead(buffer), context: context)
                }
            } catch let error as MySQLRawPacketCodec.Error {
                self.react(to: .handleError(MySQLCoreError.protocolViolation(debugDescription: "Low-level packet framing error: \(error)")), context: context)
            } catch {
                preconditionFailure("Inappropriate error received by channel handler. Please report a bug.")
            }

            self.teardownState(reason: MySQLCoreError.connection(debugDescription: "server closed connection"))
            context.fireChannelInactive()
        }

        func handlerRemoved(context: ChannelHandlerContext) {
            stateCheck(self.state.isClosed, "channel not closed when handler removed")
            
            self.logger.trace("MySQL channel handler fully shut down")
        }

        // MARK: Error

        func errorCaught(context: ChannelHandlerContext, error: any Swift.Error) {
            self.logger.debug("MySQL channel got connection error: \(String(reflecting: error))")
            self.react(to: .handleError(MySQLCoreError.connection(underlying: error)), context: context)
        }
        
        // MARK: - Utility
        
        private func teardownState(reason: any Swift.Error) {
            self.readyPromise.fail(reason)
            switch self.state {
            case .startup:                         stateCheckFailure("can't tear down without setting up")
            case .awaitingGreeting:                break
            case .waitingForTLSReady:              break
            case .awaitingAuthReply:               break
            case .idle:                            break
            case .awaitingOK(let promise):         promise?.fail(reason)
            case .gettingStatistics(let promise):  promise.fail(reason)
            case .runningPlainQuery(var machine):  machine.teardownState(reason: reason)
            case .preparingStatement(var machine): machine.teardownState(reason: reason)
            case .executingStatement(var machine): machine.teardownState(reason: reason)
            case .fetchingCursorData(var machine): machine.teardownState(reason: reason)
            case .closed:                          stateCheckFailure("can't tear down if already torn down")
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
            self.state = .closed(reason: reason)
        }
        
        private func writeAndFlush(context: ChannelHandlerContext, message: ByteBuffer, promise: EventLoopPromise<Void>?) {
            context.writeAndFlush(self.wrapOutboundOut(self.transcoder.processAndFlush(message: message)), promise: promise)
        }

        private func writeAndFlush(context: ChannelHandlerContext, message: ByteBuffer) -> EventLoopFuture<Void> {
            context.writeAndFlush(self.wrapOutboundOut(self.transcoder.processAndFlush(message: message)))
        }

        // MARK: - Reactions

        private func react(to reaction: Reaction, context: ChannelHandlerContext) {
            self.logger.trace("MySQL channel acting on \(reaction)")
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
                        preconditionFailure("MySQL channel was asked to initiate TLS but no TLS context is configured")
                    }

                    self.writeAndFlush(context: context, message: request.build(allocator: context.channel.allocator), promise: nil)
                    try context.pipeline.syncOperations.addHandler(NIOSSLClientHandler(context: sslContext, serverHostname: self.configuration.options.tlsServerName), position: .first)
                } catch {
                    self.react(to: .handleError(MySQLCoreError.connection(underlying: error)), context: context)
                }
            case .replyToHandshake(response: let response):
                self.writeAndFlush(context: context, message: response.build(allocator: context.channel.allocator), promise: nil)
            case .singleStepAuth(data: let data):
                if let data {
                    self.writeAndFlush(context: context, message: data, promise: nil)
                }
                context.read()
            case .signalSuccessfulHandshake(serverVersion: let serverVersion, connectionIdentifier: let connectionIdentifier):
                self.readyPromise.succeed((serverVersion: serverVersion, connectionIdentifier: connectionIdentifier))
            case .startNextRequest:
                if let nextRequest = self.requestQueue.popFirst() {
                    self.react(to: self.handleStartRequest(nextRequest), context: context)
                } else {
                    self.state = .idle
                }
            case .sendPing:
                break
            case .sendRequestStatistics:
                break
            case .sendResetConnectionState:
                break
            case .sendPlainQuery(let packet):
                self.writeAndFlush(context: context, message: packet.build(allocator: context.channel.allocator, activeCapabilities: self.capabilities), promise: nil)
            case .sendStatementPrepare(_):
                break
            case .sendStatementReset(_):
                break
            case .sendStatementDeallocate(_):
                break
            case .sendPreparedStatementExecute(_):
                break
            case .sendCursorDataFetch(_):
                break
            case .sendQuit:
                break
            case .updateStatusFlags(let flags, then: let nextReaction):
                self.statusFlags = flags
                self.react(to: nextReaction, context: context)
            case .haltAndCatchFire:
                context.close(mode: .all, promise: nil)
            case .handleError(let error):
                self.react(to: self.handleError0(error), context: context)
            case .fireErrorCaught(let error):
                context.fireErrorCaught(error)
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
                stateCheckFailure("received packet before being initialized")
                
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
                        self.logger.trace("MySQL channel handling OK packet while waiting for one")
                        let packet = try MySQLPackets.OKPacket(from: packet, activeCapabilities: self.capabilities)
                        self.logger.debug("MySQL channel got success for last command")
                        self.logger.trace("MySQL channel read OK packet: \(packet)")
                        self.statusFlags = packet.statusFlags
                        promise?.succeed()
                        return .startNextRequest
                    } catch {
                        return .handleError(error)
                    }
                } else {
                    return .handleError(MySQLCoreError.protocolViolation(debugDescription: "unexpected packet while waiting for OK"))
                }
            
            case .gettingStatistics(promise: let promise):
                if packet.mysql_marker() == MySQLPackets.ERRPacket.markerByte {
                    return .handleError { MySQLCoreError.server(errorPacket: try .init(from: packet)) }
                } else if [9...10, 13...13, 32...126].flatMap({$0}).contains(packet.mysql_marker() ?? 0) {
                    let statisticsString = packet.mysql_string()!
                    
                    self.logger.debug("MySQL channel received statistics: \(statisticsString)")
                    promise.succeed(statisticsString)
                    return .startNextRequest
                } else {
                    return .handleError(MySQLCoreError.protocolViolation(debugDescription: "invalid data in statistics reply"))
                }
            
            case .runningPlainQuery(stateMachine: var stateMachine):
                return stateMachine.handlePacketRead(packet)
            
            case .preparingStatement(stateMachine: var stateMachine):
                return stateMachine.handlePacketRead(packet)
            
            case .executingStatement(stateMachine: var stateMachine):
                return stateMachine.handlePacketRead(packet)
            
            case .fetchingCursorData(stateMachine: var stateMachine):
                return stateMachine.handlePacketRead(packet)
            
            case .closed:
                // This might happen if there's still buffered data to process after a close event, ignore
                self.logger.debug("Ignoring packet with marker \(packet.mysql_marker().map { "\($0)" } ?? "<none>") on closed connection")
                return .wait
            }
        }
        
        /// Some kind of error happened. This is the callout made by the `.handleError` reaction, and should not be
        /// called directly from anywhere else.
        ///
        /// > Warning: This method must never return ``Reaction/handleError(_:)`` unless it is absolutely certain that
        ///   doing so will not trigger an infinite recursion.
        private func handleError0(_ error: any Swift.Error) -> Reaction {
            /// Once we're reacting to an error here in the channel handler state machine, any error handling that
            /// may have been the purview of nested state machines has already happened; a non-fatal error executing
            /// a query, for example, was already translated into failing the query and triggering a
            /// `.startNextRequest` reaction, and would not get here.
            guard let serverError = error as? MySQLCoreError.server, case let .error(code, sqlState, message, context) = serverError else {
                /// Any non-server error is always connection-fatal.
                self.teardownState(reason: error)
                return .haltAndCatchFire
            }
            
            /// If we get this far, we have to try to work out the difference between connection-fatal and connection-
            /// preserving server errors, as listed in chapter 2 of the MySQL [Error Reference]. Fortunately, we
            /// don't need to also be concerned with any of the client or common errors in chapters 3 and 4, as those
            /// are invariably fatal (or can never occur at all) from our perspective.
            ///
            /// Surprisingly few error codes are actually fatal as far as this logic is concerned; there are many
            /// error codes which indicate catastrophic failures on the server side, but in most of those cases the
            /// server will terminate the connection on its own or the connection is still viable for issuing, for
            /// example, admin commands in an attempt to recover.
            switch code {
            case 1047, // ER_UNKNOWN_COM_ERROR (protocol violation)
            //   1105, // ER_UNKNOWN_ERROR (it is questionable whether or not this should be considered fatal)
                 1153, // ER_NET_PACKET_TOO_LARGE (if we get this error, our packet framing state is probably corrupted)
                 1154, // ER_NET_READ_ERROR_FROM_PIPE (the connection is left in an indeterminate state at this point)
                 1156, // ER_NET_PACKETS_OUT_OF_ORDER (protocol violation)
                 1157, // ER_NET_UNCOMPRESS_ERROR (protocol violation)
                 1158, // ER_NET_READ_ERROR (the connection is left in an indeterminate state at this point)
                 1159, // ER_NET_READ_INTERRUPTED (the connection is left in an indeterminate state at this point)
                 1160, // ER_NET_ERROR_ON_WRITE (the connection is left in an indeterminate state at this point)
                 1161, // ER_NET_WRITE_INTERRUPTED (the connection is left in an indeterminate state at this point)
                 _:
                break
            }
            return .wait
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
            fatalError()
        }
        
        /// A request is ready to start, even if current state says another request is still in progress.
        private func handleStartRequest(_ request: ClientRequest) -> Reaction {
            stateCheck(self.state.isConnected, "can't run requests if not in active state")
            
            switch request {
            case .ping(let promise):
                self.state = .awaitingOK(promise: promise)
                return .sendPing
            case .getStatistics(let promise):
                self.state = .gettingStatistics(promise: promise)
                return .sendRequestStatistics
            case .resetAllState(let promise):
                self.state = .awaitingOK(promise: promise)
                return .sendResetConnectionState
            case .plainQuery(let context):
                let stateMachine = PlainQuery.StateMachine(capabilities: self.capabilities, context: context)
                self.state = .runningPlainQuery(stateMachine: stateMachine)
                return .sendPlainQuery(stateMachine.start())
            case .prepareStatement(let context):
                context.promise.fail(MySQLCoreError.connection(underlying: ChannelError.operationUnsupported))
                return .handleError(MySQLCoreError.connection(underlying: ChannelError.operationUnsupported))
            case .executeStatement(let context):
                context.promise.fail(MySQLCoreError.connection(underlying: ChannelError.operationUnsupported))
                return .handleError(MySQLCoreError.connection(underlying: ChannelError.operationUnsupported))
            case .fetchCursorData(let context):
                context.promise.fail(MySQLCoreError.connection(underlying: ChannelError.operationUnsupported))
                return .handleError(MySQLCoreError.connection(underlying: ChannelError.operationUnsupported))
            case .resetStatement(let context):
                context.promise.fail(MySQLCoreError.connection(underlying: ChannelError.operationUnsupported))
                return .handleError(MySQLCoreError.connection(underlying: ChannelError.operationUnsupported))
            case .deallocateStatement(let context):
                context.promise.fail(MySQLCoreError.connection(underlying: ChannelError.operationUnsupported))
                return .handleError(MySQLCoreError.connection(underlying: ChannelError.operationUnsupported))
            case .quit:
                return .sendQuit
            }
        }
        
        // MARK: - Handshake and authentication

        /// Handles an incoming `HandshakeV10` packet.
        private func handleGreeting(_ packet: ByteBuffer) -> Reaction {
            do {
                let handshake = try MySQLPackets.HandshakeV10(from: packet)
                
                self.capabilities = try self.negotiateCapabilities(serverCapabilities: handshake.serverCapabilities)

                if self.capabilities.contains(.tls) { // Client asked for TLS and server supports it
                    self.state = .waitingForTLSReady(handshake: handshake)
                    return .updateStatusFlags(handshake.statusFlags, then: .initiateTLS(request: .init(
                        clientCapabilities: self.capabilities,
                        collation: MySQLTextCollation.bestCollation(forVersion: handshake.serverVersion, capabilities: self.capabilities).idForHandshake
                    )))
                } else { // No TLS, skip straight to auth in insecure mode
                    return .updateStatusFlags(handshake.statusFlags, then: self.startAuthentication(handshake: handshake, secureConnection: false))
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
                connectionAttributes: Self.builtinConnectionAttributes.merging(
                                          Self.sensitiveBuiltinConnectionAttributes.merging(
                                              self.configuration.options.connectionAttributes
                                          ) { $1 }
                                      ) { $1 },                                                                                                                                                                                                           
                initialDatabase: self.configuration.database,
                zstdCompressionLevel: nil
            )
            
            self.state = .awaitingAuthReply(handshake: handshake, authHandler: newHandler, secureConnection: secureConnection)
            return .replyToHandshake(response: response)
        }
        
        private static let builtinConnectionAttributes: OrderedDictionary<String, String> = { [
            //"_client_name":     "mysql-nio",
            //"_client_version":  "2.0.0",
            "_os":                ProcessInfo.processInfo.operatingSystemPlainName.lowercased(),
            "_platform":          ProcessInfo.processInfo.hostArchitectureName,
            "_client_license":    "MIT",
            "_runtime_vendor":    "Apple",
            "_runtime_version":   ProcessInfo.processInfo.swiftRuntimeVersion,
            "_connector_version": "2.0.0",
            "_connector_name":    "mysql-nio",
        ] }()
        
        private static let sensitiveBuiltinConnectionAttributes: OrderedDictionary<String, String> = {
            #if DEBUG
            [
                "_pid":               "\(ProcessInfo.processInfo.processIdentifier)",
                "_source_host":       ProcessInfo.processInfo.hostName,
                "os_user":            ProcessInfo.processInfo.userName,
                "program_name":       ProcessInfo.processInfo.processName,
            ]
            #else
            [
                "_pid":               "-1",
                "_source_host":       "localhost",
                "os_user":            "user",
                "program_name":       "sh",
            ]
            #endif
        }()

        /// Handles an incoming `AuthMoreData` packet.
        private func handleMoreAuthData(packet: ByteBuffer, handshake: MySQLPackets.HandshakeV10, authHandler: any MySQLBuiltinAuthHandler, secureConnection: Bool) -> Reaction {
            do {
                var authHandler = authHandler
                let packet = try MySQLPackets.AuthMoreDataPacket(from: packet)
                let reply = try authHandler.processData(packet.data, configuration: self.configuration, connectionIsSecure: secureConnection)
                
                self.state = .awaitingAuthReply(handshake: handshake, authHandler: authHandler, secureConnection: secureConnection)
                return .singleStepAuth(data: reply)
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
                
                self.state = .awaitingAuthReply(handshake: handshake, authHandler: newHandler, secureConnection: secureConnection)
                return .singleStepAuth(data: reply)
            } catch {
                return .handleError(error)
            }
        }
        
        /// Handles an incoming `OKPacket` while authenticating.
        private func handleAuthSuccess(packet: ByteBuffer, handshake: MySQLPackets.HandshakeV10) -> Reaction {
            do {
                let packet = try MySQLPackets.OKPacket(from: packet, activeCapabilities: self.capabilities)
                
                self.state = .idle
                return .updateStatusFlags(packet.statusFlags, then: .signalSuccessfulHandshake(serverVersion: handshake.serverVersion, connectionIdentifier: handshake.threadId))
            } catch {
                return .handleError(error)
            }
        }
    }
}

// MARK: - State management

extension MySQLChannel.Handler {
    private func stateCheck(_ check: @autoclosure () -> Bool, _ message: @autoclosure () -> String, file: StaticString = #file, line: UInt = #line) {
        guard check() else {
            stateCheckFailure(message(), file: file, line: line)
        }
    }
    
    private func stateCheckFailure(_ message: @autoclosure () -> String, file: StaticString = #file, line: UInt = #line) -> Never {
        preconditionFailure("State violation in connection state machine (\(message())). Please report a bug.", file: file, line: line)
    }
}

#if compiler(<5.9) || !$AttachedMacros

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
}

#endif
