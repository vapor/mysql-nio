import Logging
import NIOCore
import NIOPosix
import NIOSSL
#if canImport(Network)
import NIOTransportServices
#endif

public final class MySQLChannel {
    let channel: any Channel
    var eventLoop: any EventLoop { self.channel.eventLoop }
    var logger: Logger
    
    init(channel: any Channel, logger: Logger) {
        self.channel = channel
        self.logger = logger
    }

    static func makeBootstrap(
        on eventLoop: EventLoop,
        configuration: PostgresConnection.InternalConfiguration
    ) -> NIOClientTCPBootstrapProtocol {
        #if canImport(Network)
        if let tsBootstrap = NIOTSConnectionBootstrap(validatingGroup: eventLoop) {
            return tsBootstrap.connectTimeout(configuration.options.connectTimeout)
        }
        #endif

        if let nioBootstrap = ClientBootstrap(validatingGroup: eventLoop) {
            return nioBootstrap.connectTimeout(configuration.options.connectTimeout)
        }

        fatalError("No matching bootstrap found")
    }
}
