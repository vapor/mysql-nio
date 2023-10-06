import Logging
import NIOCore
import NIOEmbedded
import NIOPosix
import NIOSSL
#if canImport(Network)
import NIOTransportServices
#endif

public final class MySQLChannel {
    let channel: any Channel
    
    public let serverVersion: String
    public let connectionIdentifier: UInt32
    public let logger: Logger
    
    public var eventLoop: any EventLoop { self.channel.eventLoop }
    public var isClosed: Bool { !self.channel.isActive }
    
    init(channel: any Channel, serverVersion: String, connectionIdentifier: UInt32, logger: Logger) {
        self.channel = channel
        self.serverVersion = serverVersion
        self.connectionIdentifier = connectionIdentifier
        self.logger = logger
    }
    
    deinit {
        assert(!self.channel.isActive, "MySQL channel was not properly shut down.")
        if self.channel.isActive {
            self.logger.warning("MySQL channel was not properly shut down. This probably indicates a bug.")
        }
    }
    
    private static func start(channel: any Channel, configuration: Configuration, logger: Logger) -> EventLoopFuture<MySQLChannel> {
        let channelHandler = Handler(configuration: configuration, logger: logger)
        
        do {
            try channel.pipeline.syncOperations.addHandler(channelHandler)
        } catch {
            return channel.eventLoop.makeFailedFuture(error)
        }
        
        return channelHandler.readyFuture.flatMapError { error in
            channel.closeFuture.flatMapThrowing { _ in throw error }
        }.map {
            MySQLChannel(channel: channel, serverVersion: $0, connectionIdentifier: $1, logger: logger)
        }
    }

    static func connect(
        configuration: Configuration,
        logger: Logger,
        on eventLoop: any EventLoop
    ) -> EventLoopFuture<MySQLChannel> {
        eventLoop.flatSubmit {
            switch configuration.endpointInfo {
            case .configureChannel(let channel):
                guard channel.isActive else {
                    return eventLoop.makeFailedFuture(MySQLCoreError.connection(underlying: ChannelError.inappropriateOperationForState))
                }
                return self.start(channel: channel, configuration: configuration, logger: logger)
            case .bindUnixDomainSocket(let path):
                return self.makeBootstrap(on: eventLoop, configuration: configuration)
                    .connect(unixDomainSocketPath: path)
                    .flatMap { self.start(channel: $0, configuration: configuration, logger: logger) }
            case .connectTCP(let host, let port):
                return self.makeBootstrap(on: eventLoop, configuration: configuration)
                    .connect(host: host, port: port)
                    .flatMap { self.start(channel: $0, configuration: configuration, logger: logger) }
            }
        }
    }

    static func makeBootstrap(
        on eventLoop: any EventLoop,
        configuration: Configuration
    ) -> any NIOClientTCPBootstrapProtocol {
        #if canImport(Network)
        if let tsBootstrap = NIOTSConnectionBootstrap(validatingGroup: eventLoop) {
            return tsBootstrap.connectTimeout(configuration.options.connectTimeout)
        }
        #endif

        if let nioBootstrap = ClientBootstrap(validatingGroup: eventLoop) {
            return nioBootstrap.connectTimeout(configuration.options.connectTimeout)
        }

        fatalError("No bootstrap compatible with \(type(of: eventLoop)) available.")
    }
}
