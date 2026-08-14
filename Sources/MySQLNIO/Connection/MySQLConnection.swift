public import Logging
public import NIOCore
public import NIOPosix
import NIOSSL
import Synchronization

#if canImport(Network)
import Network
import NIOTransportServices
#endif

/// A single connection to a MySQL server.
public final actor MySQLConnection: Sendable {
    nonisolated public let unownedExecutor: UnownedSerialExecutor

    /// Request ID generator
    @usableFromInline
    static let requestIDGenerator: IDGenerator = .init()
    /// Logger used by the connection.
    @usableFromInline
    let logger: Logger
    @usableFromInline
    let channel: any Channel
    @usableFromInline
    let channelHandler: MySQLChannelHandler
    @usableFromInline
    let configuration: MySQLConnectionConfiguration
    let isClosed: Atomic<Bool>

    init(
        channel: any Channel,
        channelHandler: MySQLChannelHandler,
        configuration: MySQLConnectionConfiguration,
        logger: Logger
    ) {
        self.unownedExecutor = channel.eventLoop.executor.asUnownedSerialExecutor()
        self.channel = channel
        self.channelHandler = channelHandler
        self.configuration = configuration
        self.logger = logger
        self.isClosed = .init(false)
    }

    /// Connect to the MySQL server and run operations using the connection, then it automatically closes the connection.
    ///
    /// - Parameters:
    ///   - address: Internet address of the MySQL server
    ///   - configuration: Configuration of the MySQL connection
    ///   - eventLoop: EventLoop to run connection on
    ///   - logger: Logger to use for the connection. Defaults to the current task-local logger.
    ///   - operation: Closure where MySQL operations using the connection are performed
    ///
    /// - Returns: The value returned by the `operation` closure
    public static func withConnection<Value>(
        address: MySQLServerAddress,
        configuration: MySQLConnectionConfiguration,
        eventLoop: any EventLoop = MultiThreadedEventLoopGroup.singleton.any(),
        logger: Logger = Logger.current,
        operation: (MySQLConnection) async throws -> Value
    ) async throws -> Value {
        let connection = try await self.connect(
            address: address,
            configuration: configuration,
            eventLoop: eventLoop,
            logger: logger
        )
        defer { connection.close() }
        return try await operation(connection)
    }

    /// Close the connection.
    public nonisolated func close() {
        guard self.isClosed.compareExchange(expected: false, desired: true, successOrdering: .relaxed, failureOrdering: .relaxed).exchanged
        else {
            return
        }
        self.channel.eventLoop.execute {
            self.assumeIsolated {
                try? $0.triggerGracefulShutdown()
                $0.channel.close(mode: .all, promise: nil)
            }
        }
    }

    public func query<Value>(
        _ query: String,
        handler: (MySQLRowSequence) async throws -> Value
    ) async throws -> Value {
        var payload = self.channel.allocator.buffer(capacity: 4 + 1 + query.utf8.count)
        payload.writeBytes([0x00, 0x00, 0x00, 0x00])
        payload.writeInteger(UInt8(0x03))
        payload.writeString(query)
        let (stream, continuation) = MySQLRowSequence.makeStream()
        try await self.sendQueryCommand(payload, streamContinuation: continuation)
        return try await handler(stream)
    }

    /// Checks if the server is alive and reachable.
    public func ping() async throws {
        _ = try await self.sendUtilityCommand(.init(bytes: [0x00, 0x00, 0x00, 0x00, 0x0E]))
    }

    /// This command resets the session state (variables, tables, etc.) to its initial values without closing the connection.
    public func resetConnection() async throws {
        _ = try await self.sendUtilityCommand(.init(bytes: [0x00, 0x00, 0x00, 0x00, 0x1F]))
    }

    /// Change the default schema of the connection.
    ///
    /// - Parameter schema: Name of the schema to change to
    public func initDB(schema: String) async throws {
        var payload = ByteBufferAllocator().buffer(capacity: 4 + 1 + schema.utf8.count)
        payload.writeBytes([0x00, 0x00, 0x00, 0x00])
        payload.writeInteger(UInt8(0x02))
        payload.writeString(schema)
        _ = try await self.sendUtilityCommand(.init(buffer: payload))
    }

    /// Retrieve a human-readable string containing internal server statistics like uptime and thread counts.
    ///
    /// - Returns: A human readable string of some internal status vars.
    public func statistics() async throws -> String {
        String(buffer: try await self.sendUtilityCommand(.init(bytes: [0x00, 0x00, 0x00, 0x00, 0x09])))
    }
}

// MARK: - Connect
extension MySQLConnection {
    static func connect(
        address: MySQLServerAddress,
        configuration: MySQLConnectionConfiguration,
        eventLoop: any EventLoop = MultiThreadedEventLoopGroup.singleton.any(),
        logger: Logger
    ) async throws -> MySQLConnection {
        let future =
            if eventLoop.inEventLoop {
                self._makeConnection(
                    address: address,
                    eventLoop: eventLoop,
                    configuration: configuration,
                    logger: logger
                )
            } else {
                eventLoop.flatSubmit {
                    self._makeConnection(
                        address: address,
                        eventLoop: eventLoop,
                        configuration: configuration,
                        logger: logger
                    )
                }
            }
        let connection = try await future.get()
        try await connection.waitOnConnected()
        return connection
    }

    func waitOnConnected() async throws {
        try await self.channelHandler.waitOnConnected().get()
    }

    /// Trigger graceful shutdown of connection
    ///
    /// The connection will wait until all pending commands have been processed before closing the connection.
    func triggerGracefulShutdown() throws {
        _ = try self.channelHandler.sendUtilityCommandNoWait(.init(bytes: [0x00, 0x00, 0x00, 0x00, 0x01]))
        self.channelHandler.triggerGracefulShutdown()
    }

    private static func _makeConnection(
        address: MySQLServerAddress,
        eventLoop: any EventLoop,
        configuration: MySQLConnectionConfiguration,
        logger: Logger
    ) -> EventLoopFuture<MySQLConnection> {
        eventLoop.assertInEventLoop()

        let bootstrap: any NIOClientTCPBootstrapProtocol
        #if canImport(Network)
        if let tsBootstrap = createTSBootstrap(eventLoopGroup: eventLoop, tlsOptions: nil) {
            bootstrap = tsBootstrap
        } else {
            #if os(iOS) || os(tvOS)
            logger.warning(
                "Running BSD sockets on iOS or tvOS is not recommended. Please use NIOTSEventLoopGroup to run with the Network framework"
            )
            #endif
            bootstrap = self.createSocketsBootstrap(eventLoopGroup: eventLoop)
        }
        #else
        bootstrap = self.createSocketsBootstrap(eventLoopGroup: eventLoop)
        #endif

        let connect = bootstrap.channelInitializer { channel in
            do {
                try self._setupChannel(channel, configuration: configuration, logger: logger)
                return eventLoop.makeSucceededVoidFuture()
            } catch {
                return eventLoop.makeFailedFuture(error)
            }
        }

        let future: EventLoopFuture<any Channel>
        switch address.value {
        case .hostname(let host, let port):
            future = connect.connect(host: host, port: port)
            future.whenSuccess { _ in
                logger.debug("Client connected to \(host):\(port)")
            }
        case .unixDomainSocket(let path):
            future = connect.connect(unixDomainSocketPath: path)
            future.whenSuccess { _ in
                logger.debug("Client connected to socket path \(path)")
            }
        }

        return future.flatMapThrowing { channel in
            let handler = try channel.pipeline.syncOperations.handler(type: MySQLChannelHandler.self)
            return MySQLConnection(
                channel: channel,
                channelHandler: handler,
                configuration: configuration,
                logger: logger
            )
        }
    }

    package static func setupChannelAndConnect(
        _ channel: any Channel,
        configuration: MySQLConnectionConfiguration,
        logger: Logger = Logger.current
    ) async throws -> MySQLConnection {
        if !channel.eventLoop.inEventLoop {
            return try await channel.eventLoop.flatSubmit {
                self._setupChannelAndConnect(channel, configuration: configuration, logger: logger)
            }.get()
        }
        return try await self._setupChannelAndConnect(channel, configuration: configuration, logger: logger).get()
    }

    private static func _setupChannelAndConnect(
        _ channel: any Channel,
        configuration: MySQLConnectionConfiguration,
        logger: Logger
    ) -> EventLoopFuture<MySQLConnection> {
        do {
            return channel.connect(to: try SocketAddress(ipAddress: "127.0.0.1", port: 3306)).flatMap {
                channel.eventLoop.makeCompletedFuture {
                    let handler = try self._setupChannel(
                        channel,
                        configuration: configuration,
                        logger: logger
                    )
                    return MySQLConnection(
                        channel: channel,
                        channelHandler: handler,
                        configuration: configuration,
                        logger: logger
                    )
                }
            }
        } catch {
            return channel.eventLoop.makeFailedFuture(error)
        }
    }

    @discardableResult
    static func _setupChannel(
        _ channel: any Channel,
        configuration: MySQLConnectionConfiguration,
        logger: Logger
    ) throws -> MySQLChannelHandler {
        channel.eventLoop.assertInEventLoop()
        let mySQLChannelHandler = MySQLChannelHandler(
            configuration: configuration,
            eventLoop: channel.eventLoop,
            logger: logger
        )
        try channel.pipeline.syncOperations.addHandler(mySQLChannelHandler)
        return mySQLChannelHandler
    }

    /// Create a BSD sockets based bootstrap
    private static func createSocketsBootstrap(eventLoopGroup: any EventLoopGroup) -> ClientBootstrap {
        ClientBootstrap(group: eventLoopGroup)
    }

    #if canImport(Network)
    /// Create a NIOTransportServices bootstrap using Network.framework
    private static func createTSBootstrap(eventLoopGroup: any EventLoopGroup, tlsOptions: NWProtocolTLS.Options?) -> NIOTSConnectionBootstrap? {
        guard
            let bootstrap = NIOTSConnectionBootstrap(validatingGroup: eventLoopGroup)
        else {
            return nil
        }
        if let tlsOptions {
            return bootstrap.tlsOptions(tlsOptions)
        }
        return bootstrap
    }
    #endif
}

// MARK: - Send
extension MySQLConnection {
    /// Used to send utility commands, such as COM_PING and COM_RESET_CONNECTION
    ///
    /// > Important: The buffer must have 4 bytes of space reserved starting at the buffer's `readerIndex`. See ``MySQLRawPacketCodec``.
    ///
    /// - Parameter packet: The packet to send, with 4 bytes of space reserved at the start of the buffer
    ///
    /// - Returns: The server's response to the command, if applicable
    @usableFromInline
    func sendUtilityCommand(_ packet: ByteBuffer) async throws -> ByteBuffer {
        let requestID = Self.requestIDGenerator.next()
        return try await withTaskCancellationHandler {
            if Task.isCancelled {
                throw MySQLClientError.cancelled
            }
            return try await withCheckedThrowingContinuation { continuation in
                self.channelHandler.sendUtilityCommand(packet, promise: .swift(continuation), requestID: requestID)
            }
        } onCancel: {
            self.cancel(requestID: requestID)
        }
    }

    @usableFromInline
    func sendQueryCommand(_ packet: ByteBuffer, streamContinuation: MySQLRowSequence.Continuation) async throws {
        let requestID = Self.requestIDGenerator.next()
        try await withTaskCancellationHandler {
            if Task.isCancelled {
                throw MySQLClientError.cancelled
            }
            _ = try await withCheckedThrowingContinuation { continuation in
                self.channelHandler.sendQueryCommand(packet, promise: .swift(continuation), requestID: requestID, continuation: streamContinuation)
            }
        } onCancel: {
            self.cancel(requestID: requestID)
        }
    }

    @usableFromInline
    nonisolated func cancel(requestID: Int) {
        self.channel.eventLoop.execute {
            self.assumeIsolated { this in
                this.channelHandler.cancel(requestID: requestID)
            }
        }
    }
}
