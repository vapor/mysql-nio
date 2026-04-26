import NIOCore
import Logging
import NIOSSL
import NIOPosix

public final class MySQLConnection: MySQLDatabase, Sendable {
    public static func connect(
        to socketAddress: SocketAddress,
        username: String,
        database: String,
        password: String? = nil,
        tlsConfiguration: TLSConfiguration? = .makeClientConfiguration(),
        serverHostname: String? = nil,
        logger: Logger = .init(label: "codes.vapor.mysql"),
        on eventLoop: any EventLoop
    ) -> EventLoopFuture<MySQLConnection> {
        let sequence = MySQLPacketSequence()
        let done = eventLoop.makePromise(of: Void.self)

        let bootstrap = ClientBootstrap(group: eventLoop)
            .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .channelInitializer { channel in
                done.futureResult.whenFailure { _ in
                    channel.close(mode: .all, promise: nil)
                }
                return channel.eventLoop.makeCompletedFuture {
                    try channel.pipeline.syncOperations.addHandlers([
                        ByteToMessageHandler(MySQLPacketDecoder(
                            sequence: sequence,
                            logger: logger
                        )),
                        MessageToByteHandler(MySQLPacketEncoder(
                            sequence: sequence,
                            logger: logger
                        )),
                        MySQLConnectionHandler(logger: logger, state: .handshake(.init(
                            username: username,
                            database: database,
                            password: password,
                            tlsConfiguration: tlsConfiguration,
                            serverHostname: serverHostname,
                            done: done
                        )), sequence: sequence),
                        ErrorHandler()
                    ], position: .last)
                }
            }

        logger.debug("Opening new connection to \(socketAddress)")

        return bootstrap.connect(to: socketAddress).flatMap { channel in
            return done.futureResult.map { MySQLConnection(channel: channel, logger: logger) }
        }
    }
    
    public let channel: any Channel
    
    public var eventLoop: any EventLoop {
        self.channel.eventLoop
    }
    
    public let logger: Logger
    
    public var isClosed: Bool {
        !self.channel.isActive
    }
    
    internal init(channel: any Channel, logger: Logger) {
        self.channel = channel
        self.logger = logger
    }
    
    public func close() -> EventLoopFuture<Void> {
        guard self.channel.isActive else {
            return self.channel.eventLoop.makeSucceededFuture(())
        }
        return self.channel.close(mode: .all)
    }
    
    public func send(_ command: any MySQLCommand, logger: Logger) -> EventLoopFuture<Void> {
        guard self.channel.isActive else {
            return self.channel.eventLoop.makeFailedFuture(MySQLError.closed)
        }

        let promise = self.eventLoop.makePromise(of: Void.self)
        
        let c = MySQLCommandContext(
            handler: command,
            promise: promise
        )
        return self.channel.write(c)
            .flatMap { promise.futureResult }
    }
    
    public func withConnection<T>(_ closure: @escaping (MySQLConnection) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        closure(self)
    }
    
    deinit {
        assert(!self.channel.isActive, "MySQLConnection not closed before deinit.")
    }
}

final class ErrorHandler: ChannelInboundHandler {
    typealias InboundIn = Never
    
    init() { }
    
    func errorCaught(context: ChannelHandlerContext, error: any Error) {
        assertionFailure("uncaught error: \(error)")
    }
}
