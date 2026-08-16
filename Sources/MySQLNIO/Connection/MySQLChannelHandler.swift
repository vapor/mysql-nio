import DequeModule
import Logging
public import NIOCore
import NIOSSL

@usableFromInline
final class MySQLChannelHandler: ChannelDuplexHandler {
    @usableFromInline
    struct PendingCommand {
        @usableFromInline
        enum CommandKind {
            case utility
            case query(MySQLRowSequence.Continuation)
        }

        @usableFromInline
        let kind: CommandKind
        /// Optional because the connect promise doesn't have a single packet associated with it.
        @usableFromInline
        let packet: ByteBuffer?
        @usableFromInline
        var promise: MySQLPromise<ByteBuffer>
        @usableFromInline
        let requestID: Int
        /// Optional because in the connect promise we set the deadline directly.
        @usableFromInline
        let timeout: TimeAmount?
        /// Optional because the deadline is activated only when the command is sent, based on the `timeout`.
        @usableFromInline
        var deadline: NIODeadline?

        @usableFromInline
        init(kind: CommandKind, packet: ByteBuffer, promise: MySQLPromise<ByteBuffer>, requestID: Int, timeout: TimeAmount) {
            self.kind = kind
            self.packet = packet
            self.promise = promise
            self.requestID = requestID
            self.timeout = timeout
            self.deadline = nil
        }

        /// Used only for the connect promise in `setAwaitingGreeting(context:)`.
        @usableFromInline
        init(promise: MySQLPromise<ByteBuffer>, requestID: Int, deadline: NIODeadline) {
            self.kind = .utility
            self.packet = nil
            self.promise = promise
            self.requestID = requestID
            self.timeout = nil
            self.deadline = deadline
        }

        /// Sets the deadline as `.now() + timeout`. This should only be called once, when the command is sent.
        @usableFromInline
        mutating func activateDeadline() {
            guard let timeout else {
                preconditionFailure("The command timeout can be nil only for the connect promise.")
            }
            self.deadline = .now() + timeout
        }
    }

    struct MySQLDeadlineSchedule: NIOScheduledCallbackHandler {
        let channelHandler: NIOLoopBound<MySQLChannelHandler>

        func handleScheduledCallback(eventLoop: some EventLoop) {
            let channelHandler = self.channelHandler.value
            switch channelHandler.stateMachine.hitDeadline(now: .now()) {
            case .failPendingCommandsAndClose(let context, let commands):
                let error = MySQLClientError.timeout
                for command in commands {
                    command.promise.fail(error)
                }
                channelHandler.failPendingCommandsAndClose(with: error)
                context.fireErrorCaught(error)
                context.close(promise: nil)
            case .reschedule(let deadline):
                channelHandler.scheduleDeadlineCallback(deadline: deadline)
            case .clearCallback:
                channelHandler.deadlineCallback = nil
                break
            }
        }
    }

    @usableFromInline
    typealias InboundIn = ByteBuffer
    @usableFromInline
    typealias InboundOut = ByteBuffer
    @usableFromInline
    typealias OutboundIn = ByteBuffer
    @usableFromInline
    typealias OutboundOut = ByteBuffer

    @usableFromInline
    let eventLoop: any EventLoop
    @usableFromInline
    var stateMachine: StateMachine<ChannelHandlerContext>

    @usableFromInline
    private(set) var deadlineCallback: NIOScheduledCallback?

    /// We need the context to init the transcoder, but the context isn't available at init,
    /// so we have to make the transcoder implicitly unwrapped optional and initialize it in `handlerAdded(context:)`.
    private var transcoder: NonThrowingMessageByteTranscodingProcessor<MySQLRawPacketCodec>!
    private let logger: Logger
    @usableFromInline
    let configuration: MySQLConnectionConfiguration

    private var statusFlags: ServerStatusFlags = []

    init(configuration: MySQLConnectionConfiguration, eventLoop: any EventLoop, logger: Logger) {
        self.configuration = configuration
        self.eventLoop = eventLoop
        self.stateMachine = .init()
        self.logger = logger
    }

    @usableFromInline
    func setAwaitingGreeting(context: ChannelHandlerContext) {
        let promise = self.eventLoop.makePromise(of: ByteBuffer.self)

        let deadline = .now() + .init(self.configuration.connectTimeout)
        self.scheduleDeadlineCallback(deadline: deadline)

        self.stateMachine.setAwaitingGreeting(
            context: context,
            connectPromise: .init(promise: .nio(promise), requestID: 0, deadline: deadline),
            configuration: self.configuration
        )
    }

    @usableFromInline
    func waitOnConnected() -> EventLoopFuture<Void> {
        switch self.stateMachine.waitOnConnected() {
        case .waitForPromise(let promise):
            promise.futureResult.map { _ in return }
        case .reportedClosed(let error):
            self.eventLoop.makeFailedFuture(error ?? MySQLClientError.connectionClosed)
        case .done:
            self.eventLoop.makeSucceededVoidFuture()
        }
    }

    @usableFromInline
    func handlerAdded(context: ChannelHandlerContext) {
        self.transcoder = .init(MySQLRawPacketCodec(), maximumDecodeBufferSize: nil, encodeBuffer: context.channel.allocator.buffer(capacity: 16384))
        if context.channel.isActive {
            self.setAwaitingGreeting(context: context)
            self.logger.trace("MySQLChannelHandler added when channel is active.")
        }
    }

    @usableFromInline
    func channelActive(context: ChannelHandlerContext) {
        self.setAwaitingGreeting(context: context)
        self.logger.trace("Channel active.")
        context.fireChannelActive()
    }

    @usableFromInline
    func channelInactive(context: ChannelHandlerContext) {
        // channel is inactive so we should fail all pending commands in progress
        self.failPendingCommandsAndClose(with: MySQLClientError.connectionClosed)
        self.logger.trace("Channel inactive.")
        context.fireChannelInactive()
    }

    @usableFromInline
    func errorCaught(context: ChannelHandlerContext, error: any Error) {
        self.logger.debug("MySQLChannelHandler: ERROR", metadata: ["error": "\(error)"])
        // we caught an error so we should fail all pending commands
        self.failPendingCommandsAndClose(with: error)
    }

    @usableFromInline
    func write(context: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
        let buffer = self.unwrapOutboundIn(data)
        self.logger.trace("Sending MySQL packet")
        context.write(self.wrapOutboundOut(self.transcoder.processAndFlush(message: buffer)), promise: promise)
    }

    @usableFromInline
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let unwrappedData = self.unwrapInboundIn(data)
        do {
            try self.transcoder.process(buffer: unwrappedData) { buffer in
                try self.handlePacket(context: context, packet: buffer)
            }
        } catch {
            self.failPendingCommandsAndClose(with: error)
            context.fireErrorCaught(error)
            context.close(promise: nil)
        }
    }

    @usableFromInline
    func cancel(requestID: Int) {
        self.eventLoop.assertInEventLoop()
        switch self.stateMachine.cancel(requestID: requestID) {
        case .cancelCommand(let command):
            command.promise.fail(MySQLClientError.cancelled)
        case .doNothing:
            break
        }
    }

    func handlePacket(context: ChannelHandlerContext, packet: ByteBuffer) throws {
        self.logger.trace("Received MySQL packet")

        var packet = packet
        switch try self.stateMachine.receivedResponse(packet: &packet) {
        case .closeWithError(let error):
            throw error
        case .handshakeRespond(let handshakeResponse, let sslRequest, let statusFlags):
            self.statusFlags = statusFlags
            if let sslRequest, let (sslContext, tlsServerName) = self.configuration.tls.sslContext {
                guard self.transcoder.unprocessedBytes == 0 else {
                    throw MySQLClientError.unsolicitedPacket("Extra data received during TLS setup")
                }
                _ = context.channel.writeAndFlush(sslRequest)
                try context.channel.pipeline.syncOperations.addHandler(
                    NIOSSLClientHandler(context: sslContext, serverHostname: tlsServerName),
                    position: .first
                )
            }
            _ = context.channel.writeAndFlush(handshakeResponse)
        case .authRespond(let responsePacket):
            if let responsePacket {
                // See ``MySQLRawPacketCodec`` for why we need to reserve 4 bytes at the start of the buffer.
                var framedResponsePacket = ByteBuffer(bytes: [UInt8](repeating: 0, count: 4))
                framedResponsePacket.writeImmutableBuffer(responsePacket)
                _ = context.channel.writeAndFlush(framedResponsePacket)
            }
        case .succeedPromise(let command, let deadlineAction, let nextCommand, let statusFlags):
            self.processDeadlineCallbackAction(action: deadlineAction)
            command.promise.succeed(packet)
            if let nextCommand { _ = context.channel.writeAndFlush(nextCommand.packet) }
            if let statusFlags { self.statusFlags = statusFlags }
        case .succeedPromiseAndClose(let command, let statusFlags):
            if let statusFlags { self.statusFlags = statusFlags }
            command.promise.succeed(packet)
            context.close(promise: nil)
        case .failPromise(let command, let error):
            command.promise.fail(error)
            throw error
        case .doNothing:
            break
        }
    }

    @usableFromInline
    func scheduleDeadlineCallback(deadline: NIODeadline) {
        self.deadlineCallback?.cancel()
        self.deadlineCallback = try? self.eventLoop.scheduleCallback(
            at: deadline,
            handler: MySQLDeadlineSchedule(channelHandler: .init(self, eventLoop: self.eventLoop))
        )
    }

    func processDeadlineCallbackAction(action: StateMachine<ChannelHandlerContext>.DeadlineCallbackAction) {
        switch action {
        case .cancel:
            self.deadlineCallback?.cancel()
            self.deadlineCallback = nil
        case .reschedule(let deadline):
            self.scheduleDeadlineCallback(deadline: deadline)
        case .doNothing:
            break
        }
    }

    private func failPendingCommandsAndClose(with error: any Error) {
        switch self.stateMachine.close() {
        case .failPendingCommandsAndClose(let commands):
            for command in commands {
                command.promise.fail(error)
            }
            self.deadlineCallback?.cancel()
        case .doNothing:
            break
        }
    }

    func triggerGracefulShutdown() {
        switch self.stateMachine.triggerGracefulShutdown() {
        case .closeConnection(let context):
            context.close(mode: .all, promise: nil)
        case .doNothing:
            break
        }
    }

    /// Used to send `COM_QUIT`
    ///
    /// > Important: The buffer must have 4 bytes of space reserved starting at the buffer's `readerIndex`. See ``MySQLRawPacketCodec``.
    @usableFromInline
    func sendUtilityCommandNoWait(_ packet: ByteBuffer) throws {
        self.eventLoop.assertInEventLoop()
        var command = PendingCommand(
            kind: .utility,
            packet: packet,
            promise: .forget,
            requestID: 0,
            timeout: .init(self.configuration.commandTimeout)
        )
        switch self.stateMachine.sendUtilityCommand(&command) {
        case .sendCommand(let context, let pendingCommand):
            // Packet can be nil only for the connect promise, and we just provided a packet above, so it's safe to force unwrap here.
            _ = context.channel.writeAndFlush(pendingCommand.packet!)
            if self.deadlineCallback == nil, let deadline = pendingCommand.deadline {
                self.scheduleDeadlineCallback(deadline: deadline)
            }
        case .doNothing:
            break
        case .throwError(let error):
            throw error
        }
    }

    /// Used to send utility commands, such as `COM_PING` and `COM_RESET_CONNECTION`
    ///
    /// > Important: The buffer must have 4 bytes of space reserved starting at the buffer's `readerIndex`. See ``MySQLRawPacketCodec``.
    @usableFromInline
    func sendUtilityCommand(
        _ packet: ByteBuffer,
        promise: MySQLPromise<ByteBuffer>,
        requestID: Int
    ) {
        self.eventLoop.assertInEventLoop()
        var command = PendingCommand(
            kind: .utility,
            packet: packet,
            promise: promise,
            requestID: requestID,
            timeout: .init(self.configuration.commandTimeout)
        )
        switch self.stateMachine.sendUtilityCommand(&command) {
        case .sendCommand(let context, let pendingCommand):
            // Packet can be nil only for the connect promise, and we just provided a packet above, so it's safe to force unwrap here.
            _ = context.channel.writeAndFlush(pendingCommand.packet!)
            if self.deadlineCallback == nil {
                guard let deadline = pendingCommand.deadline else {
                    preconditionFailure("The command deadline cannot be nil when the command is sent.")
                }
                self.scheduleDeadlineCallback(deadline: deadline)
            }
        case .doNothing:
            break
        case .throwError(let error):
            command.promise.fail(error)
        }
    }

    @usableFromInline
    func sendQueryCommand(
        _ packet: ByteBuffer,
        promise: MySQLPromise<ByteBuffer>,
        requestID: Int,
        continuation: MySQLRowSequence.Continuation
    ) {
        self.eventLoop.assertInEventLoop()
        var command = PendingCommand(
            kind: .query(continuation),
            packet: packet,
            promise: promise,
            requestID: requestID,
            timeout: .init(self.configuration.commandTimeout)
        )
        switch self.stateMachine.sendQueryCommand(&command) {
        case .sendCommand(let context, let pendingCommand):
            // Packet can be nil only for the connect promise, and we just provided a packet above, so it's safe to force unwrap here.
            _ = context.channel.writeAndFlush(pendingCommand.packet!)
            if self.deadlineCallback == nil {
                guard let deadline = pendingCommand.deadline else {
                    preconditionFailure("The command deadline cannot be nil when the command is sent.")
                }
                self.scheduleDeadlineCallback(deadline: deadline)
            }
        case .doNothing:
            break
        case .throwError(let error):
            command.promise.fail(error)
        }
    }
}
