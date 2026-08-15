public import DequeModule
public import NIOCore

extension MySQLChannelHandler {
    @usableFromInline
    struct StateMachine<Context>: ~Copyable {
        @usableFromInline
        enum State: ~Copyable {
            /// Initial state, waiting for active channel
            case startup
            /// Channel active, waiting for Initial Handshake Packet
            case awaitingGreeting(ConnectingState)
            /// Waiting for OK_Packet or to complete authentication steps if needed
            case awaitingAuthReply(AuthState)
            /// Command Phase, idle with only commands awaiting OK_Packet response running
            case connected(ConnectedState)
            case query(QueryState)
            case closing(ConnectedState)
            case closed((any Error)?)
        }
        @usableFromInline
        var state: State

        /// See ``MySQLChannelHandler/StateMachine/State/awaitingGreeting-enum.case``.
        @usableFromInline
        struct ConnectingState {
            let context: Context
            let connectPromise: PendingCommand
            let configuration: MySQLConnectionConfiguration
        }

        /// See ``MySQLChannelHandler/StateMachine/State/awaitingAuthReply-enum.case``.
        @usableFromInline
        struct AuthState: ~Copyable {
            let context: Context
            let connectPromise: PendingCommand
            let capabilities: MySQLCapabilities
            var authMethod: any AuthenticationMethod & ~Copyable
            let password: String?
        }

        @usableFromInline
        struct ConnectedState {
            let context: Context
            /// The currently running command, if any.
            var activeCommand: PendingCommand?
            /// Commands waiting to be sent after the active command finishes.
            var pendingCommands: Deque<PendingCommand>
            let capabilities: MySQLCapabilities

            /// Returns all pending commands, including the active command if it exists.
            ///
            /// > Warning: This mutates the state by moving the active command (if it exists) into the pending commands,
            /// > so it should only be used when we want to fail all pending commands and close the connection,
            /// > such as when a deadline is hit or a cancel is requested.
            mutating func allPendingCommands() -> Deque<PendingCommand> {
                if let activeCommand { pendingCommands.append(activeCommand) }
                return pendingCommands
            }

            func cancel(requestID: Int) -> (cancel: [PendingCommand], connectionClosedDueToCancellation: [PendingCommand]) {
                var withRequestID = [PendingCommand]()
                var withoutRequestID = [PendingCommand]()
                if let activeCommand {
                    if activeCommand.requestID == requestID {
                        withRequestID.append(activeCommand)
                    } else {
                        withoutRequestID.append(activeCommand)
                    }
                }
                for command in pendingCommands {
                    if command.requestID == requestID {
                        withRequestID.append(command)
                    } else {
                        withoutRequestID.append(command)
                    }
                }
                return (withRequestID, withoutRequestID)
            }
        }

        init() {
            self.init(.startup)
        }

        private init(_ state: consuming State) {
            self.state = state
        }

        /// handler has become active
        @usableFromInline
        mutating func setAwaitingGreeting(context: Context, connectPromise: PendingCommand, configuration: MySQLConnectionConfiguration) {
            switch consume self.state {
            case .startup:
                self = .awaitingGreeting(.init(context: context, connectPromise: connectPromise, configuration: configuration))
            case .awaitingGreeting:
                preconditionFailure("Cannot set awaitingGreeting state when state is already awaitingGreeting")
            case .awaitingAuthReply:
                preconditionFailure("Cannot set awaitingGreeting state when state is awaitingAuthReply")
            case .connected:
                preconditionFailure("Cannot set awaitingGreeting state when state is connected")
            case .query:
                preconditionFailure("Cannot set awaitingGreeting state when state is query")
            case .closing:
                preconditionFailure("Cannot set awaitingGreeting state when state is closing")
            case .closed:
                preconditionFailure("Cannot set awaitingGreeting state when state is closed")
            }
        }

        @usableFromInline
        enum SendUtilityCommandAction {
            case sendCommand(Context, PendingCommand)
            case doNothing
            case throwError(MySQLClientError)
        }

        /// Handler wants to send a command
        ///
        /// - Parameter command: The command the handler wants to send.
        ///     It is passed inout so that the state machine can activate the command's deadline if needed.
        /// - Returns: An action describing what the handler should do to send the command, or an error if the command cannot be sent in the current state.
        @usableFromInline
        mutating func sendUtilityCommand(_ command: inout PendingCommand) -> SendUtilityCommandAction {
            switch consume self.state {
            case .startup:
                preconditionFailure("Cannot send command when in startup state")
            case .awaitingGreeting:
                preconditionFailure("Cannot send command when in awaitingGreeting state")
            case .awaitingAuthReply:
                preconditionFailure("Cannot send command when in awaitingAuthReply state")
            case .connected(var state):
                if state.activeCommand != nil {
                    state.pendingCommands.append(command)
                    self = .connected(state)
                    return .doNothing
                } else {
                    command.activateDeadline()
                    state.activeCommand = command
                    self = .connected(state)
                    return .sendCommand(state.context, command)
                }
            case .query(var state):
                if state.connectedState.activeCommand != nil {
                    state.connectedState.pendingCommands.append(command)
                    self = .query(state)
                    return .doNothing
                } else {
                    command.activateDeadline()
                    state.connectedState.activeCommand = command
                    let context = state.connectedState.context
                    self = .query(state)
                    return .sendCommand(context, command)
                }
            case .closing(let state):
                self = .closing(state)
                return .throwError(MySQLClientError.connectionClosing)
            case .closed(let error):
                self = .closed(error)
                return .throwError(MySQLClientError.connectionClosed)
            }
        }

        @usableFromInline
        mutating func sendQueryCommand(_ command: inout PendingCommand) -> SendUtilityCommandAction {
            switch consume self.state {
            case .startup:
                preconditionFailure("Cannot send command when in startup state")
            case .awaitingGreeting:
                preconditionFailure("Cannot send command when in awaitingGreeting state")
            case .awaitingAuthReply:
                preconditionFailure("Cannot send command when in awaitingAuthReply state")
            case .connected(var state):
                if state.activeCommand != nil {
                    state.pendingCommands.append(command)
                    self = .connected(state)
                    return .doNothing
                } else {
                    command.activateDeadline()
                    state.activeCommand = command
                    self = .query(.init(connectedState: state, stateMachine: .init(capabilities: state.capabilities), gracefulShutdown: false))
                    return .sendCommand(state.context, command)
                }
            case .query(var state):
                if state.connectedState.activeCommand != nil {
                    state.connectedState.pendingCommands.append(command)
                    self = .query(state)
                    return .doNothing
                } else {
                    command.activateDeadline()
                    state.connectedState.activeCommand = command
                    let context = state.connectedState.context
                    self = .query(state)
                    return .sendCommand(context, command)
                }
            case .closing(let state):
                self = .closing(state)
                return .throwError(MySQLClientError.connectionClosing)
            case .closed(let error):
                self = .closed(error)
                return .throwError(MySQLClientError.connectionClosed)
            }
        }

        @usableFromInline
        enum DeadlineCallbackAction {
            case cancel
            case reschedule(NIODeadline)
            case doNothing
        }

        @usableFromInline
        enum ReceivedResponseAction {
            case handshakeRespond(ByteBuffer, sslRequest: ByteBuffer?, statusFlags: ServerStatusFlags)
            case authRespond(ByteBuffer?)
            case succeedPromise(PendingCommand, DeadlineCallbackAction, nextCommand: PendingCommand?, statusFlags: ServerStatusFlags?)
            case succeedPromiseAndClose(PendingCommand, statusFlags: ServerStatusFlags?)
            case failPromise(PendingCommand, any Error)
            case closeWithError(any Error)
            case doNothing
        }

        @usableFromInline
        mutating func receivedResponse(packet: inout ByteBuffer) throws -> ReceivedResponseAction {
            switch consume self.state {
            case .startup:
                preconditionFailure("Cannot receive packet when in startup state")
            case .awaitingGreeting(let state):
                if packet.isErrorPacket {
                    guard let errorPacket = ErrorPacket(from: &packet),
                        case .error(let errorKind) = errorPacket.kind
                    else {
                        let error = MySQLClientError.errorPacket()
                        self = .closed(error)
                        return .failPromise(state.connectPromise, error)
                    }
                    let error = MySQLClientError.errorPacket(errorCode: errorPacket.errorCode, errorMessage: errorKind.errorMessage)
                    self = .closed(error)
                    return .failPromise(state.connectPromise, error)
                } else {
                    // Decode the Initial Handshake Packet
                    guard let initialHandshake = InitialHandshakePacket(from: &packet) else {
                        let error = MySQLClientError.invalidPacket("Received an invalid Initial Handshake Packet")
                        self = .closed(error)
                        return .failPromise(state.connectPromise, error)
                    }

                    let clientCapabilities: MySQLCapabilities
                    do {
                        clientCapabilities = try MySQLCapabilities.negotiateCapabilities(
                            serverCapabilities: initialHandshake.serverCapabilities,
                            configuration: state.configuration
                        )
                    } catch {
                        self = .closed(error)
                        return .failPromise(state.connectPromise, error)
                    }
                    let connectionIsSecure = clientCapabilities.contains(.ssl)

                    // Determine the authentication method and prepare the authentication response
                    var authMethod = AuthenticationMethods.fromName(
                        initialHandshake.authenticationPluginName,
                        capabilities: clientCapabilities
                    )
                    let authResponse: ByteBuffer
                    do {
                        guard
                            let response = try authMethod.processData(
                                initialHandshake.authenticationPluginData,
                                password: state.configuration.password,
                                connectionIsSecure: connectionIsSecure
                            )
                        else {
                            preconditionFailure("The auth response cannot be nil at this stage.")
                            // It cannot be nil because no authentication method currently returns nil at the first step of the authentication process,
                            // not because the server could be returning invalid data.
                            // If a method is added that returns nil, this precondition failure should be replaced with proper handling of that case.
                        }
                        authResponse = response
                    } catch {
                        self = .closed(error)
                        return .failPromise(state.connectPromise, error)
                    }

                    self = .awaitingAuthReply(
                        .init(
                            context: state.context,
                            connectPromise: state.connectPromise,
                            capabilities: clientCapabilities,
                            authMethod: authMethod,
                            password: state.configuration.password
                        )
                    )

                    // Prepare SSL Request
                    let sslRequestPacket: ByteBuffer?
                    if connectionIsSecure {
                        let sslRequest = SSLRequest(
                            clientCapabilities: clientCapabilities,
                            maxPacketSize: UInt32.max,
                            clientDefaultCharacterSetAndCollation: MySQLCollation.bestCollation(
                                forVersion: initialHandshake.serverVersion,
                                capabilities: clientCapabilities
                            ),
                        )
                        var sslPacket = ByteBuffer(bytes: [UInt8](repeating: 0x00, count: 4))
                        sslRequest.write(to: &sslPacket, capabilities: clientCapabilities)
                        sslRequestPacket = sslPacket
                    } else {
                        sslRequestPacket = nil
                    }

                    // Prepare Handshake Response
                    let handshakeResponse = HandshakeResponsePacket(
                        clientCapabilities: clientCapabilities,
                        maxPacketSize: .max,
                        clientDefaultCharacterSetAndCollation: .bestCollation(
                            forVersion: initialHandshake.serverVersion,
                            capabilities: clientCapabilities
                        ),
                        username: state.configuration.username,
                        authResponse: authResponse,
                        defaultDatabaseName: state.configuration.defaultDatabaseName,
                        authenticationPluginName: initialHandshake.authenticationPluginName,
                        connectionAttributes: state.configuration.connectionAttributes,
                        zstdCompressionLevel: nil
                    )
                    // See ``MySQLRawPacketCodec`` for why we need to reserve 4 bytes at the start of the buffer.
                    var handshakeResponsePacket = ByteBuffer(bytes: [UInt8](repeating: 0x00, count: 4))
                    handshakeResponse.write(
                        to: &handshakeResponsePacket,
                        capabilities: clientCapabilities,
                        password: state.configuration.password != nil
                    )

                    return .handshakeRespond(
                        handshakeResponsePacket,
                        sslRequest: sslRequestPacket,
                        statusFlags: initialHandshake.statusFlags
                    )
                }
            case .awaitingAuthReply(var state):
                if packet.isOKPacket(capabilities: state.capabilities) {
                    let okPacket: OKPacket
                    do {
                        okPacket = try OKPacket(from: &packet, capabilities: state.capabilities)
                    } catch {
                        self = .closed(error)
                        return .failPromise(state.connectPromise, error)
                    }
                    self = .connected(.init(context: state.context, activeCommand: nil, pendingCommands: .init(), capabilities: state.capabilities))
                    return .succeedPromise(state.connectPromise, .cancel, nextCommand: nil, statusFlags: okPacket.serverStatus)
                } else if packet.isErrorPacket {
                    guard let errorPacket = ErrorPacket(from: &packet),
                        case .error(let errorKind) = errorPacket.kind
                    else {
                        let error = MySQLClientError.errorPacket()
                        self = .closed(error)
                        return .failPromise(state.connectPromise, error)
                    }
                    let error = MySQLClientError.errorPacket(errorCode: errorPacket.errorCode, errorMessage: errorKind.errorMessage)
                    self = .closed(error)
                    return .failPromise(state.connectPromise, error)
                } else if packet.mySQLHeaderFlag == 0xFE {
                    guard let authSwitchRequest = AuthenticationSwitchRequest(from: &packet) else {
                        let error = MySQLClientError.invalidPacket("Received an invalid Authentication Switch Request Packet")
                        self = .closed(error)
                        return .failPromise(state.connectPromise, error)
                    }
                    // TODO: mysql_native_password in authentication switch in MariaDB doesn't work for root user with empty password
                    state.authMethod = AuthenticationMethods.fromName(authSwitchRequest.authenticationPluginName, capabilities: nil)
                    let responsePacket: ByteBuffer?
                    do {
                        responsePacket = try state.authMethod.processData(
                            authSwitchRequest.authenticationPluginData,
                            password: state.password,
                            connectionIsSecure: state.capabilities.contains(.ssl)
                        )
                    } catch {
                        self = .closed(error)
                        return .failPromise(state.connectPromise, error)
                    }
                    self = .awaitingAuthReply(state)
                    return .authRespond(responsePacket)
                } else if packet.mySQLHeaderFlag == 0x02 {
                    fatalError("TODO: Multi Factor Authentication is not yet supported")
                } else {
                    let responsePacket: ByteBuffer?
                    do {
                        responsePacket = try state.authMethod.processData(
                            packet,
                            password: state.password,
                            connectionIsSecure: state.capabilities.contains(.ssl)
                        )
                    } catch {
                        self = .closed(error)
                        return .failPromise(state.connectPromise, error)
                    }
                    self = .awaitingAuthReply(state)
                    return .authRespond(responsePacket)
                }
            case .connected(var state):
                guard let command = state.activeCommand else {
                    self = .closed(nil)
                    return .closeWithError(MySQLClientError.unsolicitedPacket("Received a packet without having sent a command"))
                }
                state.activeCommand = nil
                guard !packet.isErrorPacket else {
                    self = .connected(state)
                    guard let errorPacket = ErrorPacket(from: &packet),
                        case .error(let errorKind) = errorPacket.kind
                    else {
                        return .failPromise(command, MySQLClientError.errorPacket())
                    }
                    return .failPromise(command, MySQLClientError.errorPacket(errorCode: errorPacket.errorCode, errorMessage: errorKind.errorMessage))
                }
                let okPacket: OKPacket? =
                    if packet.isOKPacket(capabilities: state.capabilities) {
                        try? .init(from: &packet, capabilities: state.capabilities)
                    } else {
                        nil
                    }
                if let nextCommand = state.pendingCommands.popFirst() {
                    var nextCommand = nextCommand
                    nextCommand.activateDeadline()
                    state.activeCommand = nextCommand
                    switch nextCommand.kind {
                    case .utility:
                        self = .connected(state)
                    case .query:
                        self = .query(.init(connectedState: state, stateMachine: .init(capabilities: state.capabilities), gracefulShutdown: false))
                    }
                    guard let deadline = nextCommand.deadline else {
                        preconditionFailure("The command deadline cannot be nil when the command is sent.")
                    }
                    return .succeedPromise(command, .reschedule(deadline), nextCommand: nextCommand, statusFlags: okPacket?.serverStatus)
                } else {
                    self = .connected(state)
                    return .succeedPromise(command, .cancel, nextCommand: nil, statusFlags: okPacket?.serverStatus)
                }
            case .query(var state):
                switch state.stateMachine.receivedResponse(packet: &packet) {
                case .doNothing:
                    self = .query(state)
                    return .doNothing
                case .columnMetadata(_):
                    // TODO: handle column definitions
                    self = .query(state)
                    return .doNothing
                case .row(let row):
                    guard case .query(let continuation) = state.connectedState.activeCommand?.kind else {
                        preconditionFailure("The active command must be a query command when receiving rows.")
                    }
                    continuation.yield(row)
                    self = .query(state)
                    return .doNothing
                case .resultsetEnd:
                    guard let command = state.connectedState.activeCommand else {
                        preconditionFailure("Cannot complete query without an active command")
                    }
                    guard case .query(let continuation) = command.kind else {
                        preconditionFailure("The active command must be a query command when receiving the end of the result set.")
                    }
                    continuation.finish()
                    state.connectedState.activeCommand = nil
                    if let nextCommand = state.connectedState.pendingCommands.popFirst() {
                        var nextCommand = nextCommand
                        nextCommand.activateDeadline()
                        state.connectedState.activeCommand = nextCommand
                        switch nextCommand.kind {
                        case .utility:
                            if state.gracefulShutdown {
                                self = .closing(state.connectedState)
                            } else {
                                self = .connected(state.connectedState)
                            }
                        case .query:
                            self = .query(state)
                        }
                        guard let deadline = nextCommand.deadline else {
                            preconditionFailure("The command deadline cannot be nil when the command is sent.")
                        }
                        return .succeedPromise(command, .reschedule(deadline), nextCommand: nextCommand, statusFlags: nil)
                    } else {
                        if state.gracefulShutdown {
                            self = .closed(nil)
                            return .succeedPromiseAndClose(command, statusFlags: nil)
                        } else {
                            self = .connected(state.connectedState)
                            return .succeedPromise(command, .cancel, nextCommand: nil, statusFlags: nil)
                        }
                    }
                case .moreResultsExists:
                    // TODO: handle multiple result sets
                    guard case .query(let continuation) = state.connectedState.activeCommand?.kind else {
                        preconditionFailure("The active command must be a query command when receiving the more results flag.")
                    }
                    continuation.finish()
                    self = .query(state)
                    return .doNothing
                case .error(let error):
                    guard let command = state.connectedState.activeCommand else {
                        preconditionFailure("Cannot fail query without an active command")
                    }
                    guard case .query(let continuation) = command.kind else {
                        preconditionFailure("The active command must be a query command when receiving an error.")
                    }
                    continuation.finish(throwing: error)
                    state.connectedState.activeCommand = nil
                    self = .connected(state.connectedState)
                    return .failPromise(command, error)
                }
            case .closing(var state):
                guard let command = state.activeCommand else {
                    preconditionFailure("Cannot be in closing state with no active command")
                }
                state.activeCommand = nil
                guard !packet.isErrorPacket else {
                    guard let errorPacket = ErrorPacket(from: &packet),
                        case .error(let errorKind) = errorPacket.kind
                    else {
                        let error = MySQLClientError.errorPacket()
                        self = .closed(error)
                        return .failPromise(command, error)
                    }
                    let error = MySQLClientError.errorPacket(errorCode: errorPacket.errorCode, errorMessage: errorKind.errorMessage)
                    self = .closed(error)
                    return .failPromise(command, error)
                }
                let okPacket: OKPacket? =
                    if packet.isOKPacket(capabilities: state.capabilities) {
                        try? .init(from: &packet, capabilities: state.capabilities)
                    } else {
                        nil
                    }
                if let nextCommand = state.pendingCommands.popFirst() {
                    var nextCommand = nextCommand
                    nextCommand.activateDeadline()
                    state.activeCommand = nextCommand
                    switch nextCommand.kind {
                    case .utility:
                        self = .closing(state)
                    case .query:
                        self = .query(
                            .init(
                                connectedState: state,
                                stateMachine: .init(capabilities: state.capabilities),
                                gracefulShutdown: true
                            )
                        )
                    }
                    guard let deadline = nextCommand.deadline else {
                        preconditionFailure("The command deadline cannot be nil when the command is sent.")
                    }
                    return .succeedPromise(command, .reschedule(deadline), nextCommand: nextCommand, statusFlags: okPacket?.serverStatus)
                } else {
                    self = .closed(nil)
                    return .succeedPromiseAndClose(command, statusFlags: okPacket?.serverStatus)
                }
            case .closed(let error):
                guard let error else {
                    preconditionFailure("Cannot receive packet on closed connection with no error")
                }
                self = .closed(error)
                return .closeWithError(error)
            }
        }

        @usableFromInline
        enum WaitOnConnectedAction {
            case waitForPromise(EventLoopPromise<ByteBuffer>)
            case reportedClosed((any Error)?)
            case done
        }

        mutating func waitOnConnected() -> WaitOnConnectedAction {
            switch consume self.state {
            case .startup:
                preconditionFailure("Cannot wait until connection has succeeded")
            case .awaitingGreeting(let state):
                switch state.connectPromise.promise {
                case .nio(let promise):
                    self = .awaitingGreeting(state)
                    return .waitForPromise(promise)
                case .swift, .forget:
                    preconditionFailure("awaitingGreeting state cannot be setup with a Swift continuation")
                }
            case .awaitingAuthReply(let state):
                switch state.connectPromise.promise {
                case .nio(let promise):
                    self = .awaitingAuthReply(state)
                    return .waitForPromise(promise)
                case .swift, .forget:
                    preconditionFailure("awaitingAuthReply state cannot be setup with a Swift continuation")
                }
            case .connected(let state):
                self = .connected(state)
                return .done
            case .query(let state):
                self = .query(state)
                return .done
            case .closing(let state):
                self = .closing(state)
                return .reportedClosed(nil)
            case .closed(let error):
                self = .closed(error)
                return .reportedClosed(error)
            }
        }

        @usableFromInline
        enum HitDeadlineAction {
            case failPendingCommandsAndClose(Context, Deque<PendingCommand>)
            case reschedule(NIODeadline)
            case clearCallback
        }

        @usableFromInline
        mutating func hitDeadline(now: NIODeadline) -> HitDeadlineAction {
            switch consume self.state {
            case .startup:
                preconditionFailure("Cannot cancel when in startup state")
            case .awaitingGreeting(let state):
                guard let deadline = state.connectPromise.deadline else {
                    preconditionFailure("The connect promise deadline cannot be nil.")
                }
                if deadline <= now {
                    self = .closed(MySQLClientError.timeout)
                    return .failPendingCommandsAndClose(state.context, [state.connectPromise])
                } else {
                    self = .awaitingGreeting(state)
                    return .reschedule(deadline)
                }
            case .awaitingAuthReply(let state):
                guard let deadline = state.connectPromise.deadline else {
                    preconditionFailure("The connect promise deadline cannot be nil.")
                }
                if deadline <= now {
                    self = .closed(MySQLClientError.timeout)
                    return .failPendingCommandsAndClose(state.context, [state.connectPromise])
                } else {
                    self = .awaitingAuthReply(state)
                    return .reschedule(deadline)
                }
            case .connected(var state):
                guard let activeCommand = state.activeCommand else {
                    self = .connected(state)
                    return .clearCallback
                }
                guard let deadline = activeCommand.deadline else {
                    preconditionFailure("The active command deadline cannot be nil.")
                }
                if deadline <= now {
                    self = .closed(MySQLClientError.timeout)
                    return .failPendingCommandsAndClose(state.context, state.allPendingCommands())
                } else {
                    self = .connected(state)
                    return .reschedule(deadline)
                }
            case .query(var state):
                guard let activeCommand = state.connectedState.activeCommand else {
                    self = .query(state)
                    return .clearCallback
                }
                guard let deadline = activeCommand.deadline else {
                    preconditionFailure("The active command deadline cannot be nil.")
                }
                if deadline <= now {
                    self = .closed(MySQLClientError.timeout)
                    return .failPendingCommandsAndClose(state.connectedState.context, state.connectedState.allPendingCommands())
                } else {
                    self = .query(state)
                    return .reschedule(deadline)
                }
            case .closing(var state):
                guard let activeCommand = state.activeCommand else {
                    preconditionFailure("Cannot be in closing state with no active command")
                }
                guard let deadline = activeCommand.deadline else {
                    preconditionFailure("The active command deadline cannot be nil.")
                }
                if deadline <= now {
                    self = .closed(MySQLClientError.timeout)
                    return .failPendingCommandsAndClose(state.context, state.allPendingCommands())
                } else {
                    self = .closing(state)
                    return .reschedule(deadline)
                }
            case .closed(let error):
                self = .closed(error)
                return .clearCallback
            }
        }

        @usableFromInline
        enum CancelAction {
            case failPendingCommandsAndClose(cancel: [PendingCommand], closeConnectionDueToCancel: [PendingCommand])
            case doNothing
        }

        /// handler wants to cancel a command
        @usableFromInline
        mutating func cancel(requestID: Int) -> CancelAction {
            switch consume self.state {
            case .startup:
                preconditionFailure("Cannot cancel when in startup state")
            case .awaitingGreeting:
                preconditionFailure("Cannot cancel while in awaitingGreeting state")
            case .awaitingAuthReply:
                preconditionFailure("Cannot cancel while in awaitingAuthReply state")
            case .connected(let state):
                let (cancel, closeConnectionDueToCancel) = state.cancel(requestID: requestID)
                if cancel.count > 0 {
                    self = .closed(MySQLClientError.cancelled)
                    return .failPendingCommandsAndClose(
                        cancel: cancel,
                        closeConnectionDueToCancel: closeConnectionDueToCancel
                    )
                } else {
                    self = .connected(state)
                    return .doNothing
                }
            case .query(let state):
                let (cancel, closeConnectionDueToCancel) = state.connectedState.cancel(requestID: requestID)
                if cancel.count > 0 {
                    self = .closed(MySQLClientError.cancelled)
                    return .failPendingCommandsAndClose(
                        cancel: cancel,
                        closeConnectionDueToCancel: closeConnectionDueToCancel
                    )
                } else {
                    self = .query(state)
                    return .doNothing
                }
            case .closing(let state):
                let (cancel, closeConnectionDueToCancel) = state.cancel(requestID: requestID)
                if cancel.count > 0 {
                    self = .closed(MySQLClientError.cancelled)
                    return .failPendingCommandsAndClose(
                        cancel: cancel,
                        closeConnectionDueToCancel: closeConnectionDueToCancel
                    )
                } else {
                    self = .closing(state)
                    return .doNothing
                }
            case .closed(let error):
                self = .closed(error)
                return .doNothing
            }
        }

        @usableFromInline
        enum TriggerGracefulShutdownAction {
            case closeConnection(Context)
            case doNothing
        }

        /// Want to gracefully shutdown the handler
        @usableFromInline
        mutating func triggerGracefulShutdown() -> TriggerGracefulShutdownAction {
            switch consume self.state {
            case .startup:
                self = .closed(nil)
                return .doNothing
            case .awaitingGreeting(let state):
                self = .closing(.init(context: state.context, pendingCommands: .init([state.connectPromise]), capabilities: .requiredCapabilities))
                return .doNothing
            case .awaitingAuthReply(let state):
                self = .closing(.init(context: state.context, pendingCommands: .init([state.connectPromise]), capabilities: state.capabilities))
                return .doNothing
            case .connected(let state):
                if state.activeCommand != nil || !state.pendingCommands.isEmpty {
                    self = .closing(state)
                    return .doNothing
                } else {
                    self = .closed(nil)
                    return .closeConnection(state.context)
                }
            case .query(var state):
                if state.connectedState.activeCommand != nil || !state.connectedState.pendingCommands.isEmpty {
                    state.gracefulShutdown = true
                    self = .query(state)
                    return .doNothing
                } else {
                    self = .closed(nil)
                    return .closeConnection(state.connectedState.context)
                }
            case .closing(let state):
                self = .closing(state)
                return .doNothing
            case .closed(let error):
                self = .closed(error)
                return .doNothing
            }
        }

        @usableFromInline
        enum CloseAction {
            case doNothing
            case failPendingCommandsAndClose(Deque<PendingCommand>)
        }

        /// Want to close the connection
        @usableFromInline
        mutating func close() -> CloseAction {
            switch consume self.state {
            case .startup:
                self = .closed(nil)
                return .doNothing
            case .awaitingGreeting(let state):
                self = .closed(nil)
                return .failPendingCommandsAndClose([state.connectPromise])
            case .awaitingAuthReply(let state):
                self = .closed(nil)
                return .failPendingCommandsAndClose([state.connectPromise])
            case .connected(var state):
                self = .closed(nil)
                return .failPendingCommandsAndClose(state.allPendingCommands())
            case .query(var state):
                self = .closed(nil)
                return .failPendingCommandsAndClose(state.connectedState.allPendingCommands())
            case .closing(var state):
                self = .closed(nil)
                return .failPendingCommandsAndClose(state.allPendingCommands())
            case .closed(let error):
                self = .closed(error)
                return .doNothing
            }
        }

        private static func awaitingGreeting(_ state: ConnectingState) -> Self {
            StateMachine(.awaitingGreeting(state))
        }

        private static func awaitingAuthReply(_ state: consuming AuthState) -> Self {
            StateMachine(.awaitingAuthReply(state))
        }

        private static func connected(_ state: ConnectedState) -> Self {
            StateMachine(.connected(state))
        }

        private static func closing(_ state: ConnectedState) -> Self {
            StateMachine(.closing(state))
        }

        private static func closed(_ error: (any Error)?) -> Self {
            StateMachine(.closed(error))
        }
    }
}

// MARK: - COM_QUERY
extension MySQLChannelHandler.StateMachine {
    fileprivate static func query(_ state: consuming QueryState) -> Self {
        Self(.query(state))
    }

    @usableFromInline
    struct QueryState: ~Copyable {
        var connectedState: ConnectedState
        var stateMachine: QueryStateMachine
        /// Whether a graceful shutdown has been requested.
        var gracefulShutdown: Bool
    }

    @usableFromInline
    struct QueryStateMachine: ~Copyable {
        @usableFromInline
        enum State: ~Copyable {
            /// A `COM_QUERY` command was sent and no response has yet been received, or a new
            /// resultset has been signaled as incoming but not yet received.
            case awaitingResultsetStart
            /// Waiting for one or more column metadata packets
            case awaitingColumnMetadata(columnsRemaining: UInt64, columnMetadata: ColumnMetadata)
            /// Reading resultset rows
            case readingRows(columnMetadata: ColumnMetadata)
            /// All result sets received, or error stopped the query.
            case done(result: (any Error)?)
        }
        @usableFromInline
        var state: State

        @usableFromInline
        let capabilities: MySQLCapabilities

        @usableFromInline
        struct ColumnMetadata {
            var columns: [ColumnDefinition] = []
            var lookupTable: [String: Int] = [:]
        }

        init(capabilities: MySQLCapabilities) {
            self.state = .awaitingResultsetStart
            self.capabilities = capabilities
        }

        private init(_ state: consuming State, capabilities: MySQLCapabilities) {
            self.state = state
            self.capabilities = capabilities
        }

        @usableFromInline
        enum ReceivedResponseAction {
            case doNothing
            case columnMetadata(ColumnMetadata)
            case row(MySQLRow)
            case resultsetEnd
            case moreResultsExists
            case error(any Error)
        }

        @usableFromInline
        mutating func receivedResponse(packet: inout ByteBuffer) -> ReceivedResponseAction {
            if packet.isErrorPacket {
                guard let errorPacket = ErrorPacket(from: &packet), case .error(let errorKind) = errorPacket.kind else {
                    let error = MySQLClientError.errorPacket()
                    self = .done(result: error, capabilities: self.capabilities)
                    return .error(error)
                }
                let error = MySQLClientError.errorPacket(errorCode: errorPacket.errorCode, errorMessage: errorKind.errorMessage)
                self = .done(result: error, capabilities: self.capabilities)
                return .error(error)
            }
            switch consume self.state {
            case .awaitingResultsetStart:
                if packet.isOKPacket(capabilities: self.capabilities) {
                    guard let okPacket = try? OKPacket(from: &packet, capabilities: self.capabilities) else {
                        let error = MySQLClientError.invalidPacket("Received an invalid OK Packet")
                        self = .done(result: error, capabilities: self.capabilities)
                        return .error(error)
                    }
                    if okPacket.serverStatus.contains(.serverMoreResultsExists) {
                        self = .awaitingResultsetStart(capabilities: self.capabilities)
                        return .moreResultsExists
                    }
                    self = .done(result: nil, capabilities: self.capabilities)
                    return .resultsetEnd
                }
                guard let columnCount = packet.readEncodedInteger(as: UInt64.self, strategy: .mySQL) else {
                    let error = MySQLClientError.invalidPacket("Received an invalid Result Set Header Packet")
                    self = .done(result: error, capabilities: self.capabilities)
                    return .error(error)
                }
                var metadataFollows = false
                if self.capabilities.metadataFlagAvailable {
                    guard let metadataFollowsFlag = packet.readInteger(as: UInt8.self) else {
                        let error = MySQLClientError.invalidPacket("Received an invalid Result Set Header Packet")
                        self = .done(result: error, capabilities: self.capabilities)
                        return .error(error)
                    }
                    metadataFollows = metadataFollowsFlag == 1
                }
                if !self.capabilities.metadataFlagAvailable || metadataFollows {
                    if columnCount == 0 {
                        self = .readingRows(columnMetadata: .init(), capabilities: self.capabilities)
                        return .doNothing
                    } else {
                        self = .awaitingColumnMetadata(
                            columnsRemaining: columnCount,
                            columnMetadata: .init(),
                            capabilities: self.capabilities
                        )
                        return .doNothing
                    }
                } else {
                    self = .readingRows(columnMetadata: .init(), capabilities: self.capabilities)
                    return .doNothing
                }
            case .awaitingColumnMetadata(let columnsRemaining, var columnMetadata):
                guard let columnDefinition = ColumnDefinition(from: &packet, capabilities: self.capabilities, format: .text) else {
                    let error = MySQLClientError.invalidPacket("Received an invalid Column Definition Packet")
                    self = .done(result: error, capabilities: self.capabilities)
                    return .error(error)
                }
                let nextColumnIndex = columnMetadata.columns.count
                columnMetadata.columns.append(columnDefinition)
                columnMetadata.lookupTable[columnDefinition.name] = nextColumnIndex
                if columnsRemaining == 1 {
                    self = .readingRows(columnMetadata: columnMetadata, capabilities: self.capabilities)
                    return .columnMetadata(columnMetadata)
                } else {
                    self = .awaitingColumnMetadata(
                        columnsRemaining: columnsRemaining - 1,
                        columnMetadata: columnMetadata,
                        capabilities: self.capabilities
                    )
                    return .doNothing
                }
            case .readingRows(let columnMetadata):
                if packet.isEOFPacket {
                    guard let eofPacket = EOFPacket(from: &packet) else {
                        let error = MySQLClientError.invalidPacket("Received an invalid EOF Packet")
                        self = .done(result: error, capabilities: self.capabilities)
                        return .error(error)
                    }
                    if eofPacket.serverStatus.contains(.serverMoreResultsExists) {
                        self = .awaitingResultsetStart(capabilities: self.capabilities)
                        return .moreResultsExists
                    }
                    self = .done(result: nil, capabilities: self.capabilities)
                    return .resultsetEnd
                } else if packet.isOKPacket(capabilities: self.capabilities) {
                    guard let okPacket = try? OKPacket(from: &packet, capabilities: self.capabilities) else {
                        let error = MySQLClientError.invalidPacket("Received an invalid OK Packet")
                        self = .done(result: error, capabilities: self.capabilities)
                        return .error(error)
                    }
                    if okPacket.serverStatus.contains(.serverMoreResultsExists) {
                        self = .awaitingResultsetStart(capabilities: self.capabilities)
                        return .moreResultsExists
                    }
                    self = .done(result: nil, capabilities: self.capabilities)
                    return .resultsetEnd
                } else {
                    self = .readingRows(columnMetadata: columnMetadata, capabilities: self.capabilities)
                    return .row(
                        MySQLRow(
                            data: .init(columnCount: UInt64(columnMetadata.columns.count), bytes: packet),
                            lookupTable: columnMetadata.lookupTable,
                            columns: columnMetadata.columns
                        )
                    )
                }
            case .done:
                preconditionFailure("Should not receive packets when query state machine is done")
            }
        }

        private static func awaitingResultsetStart(capabilities: MySQLCapabilities) -> Self {
            Self(.awaitingResultsetStart, capabilities: capabilities)
        }

        private static func awaitingColumnMetadata(
            columnsRemaining: UInt64,
            columnMetadata: ColumnMetadata,
            capabilities: MySQLCapabilities
        ) -> Self {
            Self(.awaitingColumnMetadata(columnsRemaining: columnsRemaining, columnMetadata: columnMetadata), capabilities: capabilities)
        }

        private static func readingRows(columnMetadata: ColumnMetadata, capabilities: MySQLCapabilities) -> Self {
            Self(.readingRows(columnMetadata: columnMetadata), capabilities: capabilities)
        }

        private static func done(result: (any Error)?, capabilities: MySQLCapabilities) -> Self {
            Self(.done(result: result), capabilities: capabilities)
        }
    }
}
