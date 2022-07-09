import NIOCore
import NIOSSL
import NIOPosix
#if canImport(Network)
import NIOTransportServices
#endif

extension MySQLConnection {

    /// The concept for this particular setup of configuration details was shamelessly ripped off from PostgresNIO.
    /// Just chalk it up to wanting the wire protocol drivers to have similar public interfaces.
    public struct Configuration {
        /// This particular part is, in fact copy-pasted verbatim from PostgresNIO, give or take a few code style changes.
        public struct TLS {
            enum Base {
                case disable
                case prefer(NIOSSLContext)
                case require(NIOSSLContext)
            }

            let base: Base

            private init(_ base: Base) { self.base = base }

            /// Do not try to create a TLS connection to the server.
            public static var disable: Self { .init(.disable) }

            /// Try to create a TLS connection to the server. If the server supports TLS, create a TLS connection.
            /// If the server does not support TLS, create an insecure connection.
            public static func prefer(_ sslContext: NIOSSLContext) -> Self { .init(.prefer(sslContext)) }

            /// Try to create a TLS connection to the server. If the server supports TLS, create a TLS connection.
            /// If the server does not support TLS, fail the connection creation.
            public static func require(_ sslContext: NIOSSLContext) -> Self { .init(.require(sslContext)) }
        }

        /// Basic authentication properties for a connection.
        public struct Authentication {
            /// The username to authenticate with.
            public var username: String

            /// A password for the specified username. May be `nil` to explicitly log in without a password.
            public var password: String?

            /// The name of a database to request access to. May be `nil` to connect to no initial database at all.
            public var database: String?
            
            /// Arbitary key-value pairs to specify additional authentication data that may be used by plugins.
            public var extraAuthData: [String: [UInt8]]

            public init(username: String, password: String?, database: String?, extraAuthData: [String: [UInt8]] = [:]) {
                self.username = username
                self.password = password
                self.database = database
                self.extraAuthData = extraAuthData
            }
        }

        public struct Connection {
            // Embed enum in struct so new cases can be added without causing a semver-major break.
            enum Base {
                case existingChannel(Channel)
                case socketAddress(SocketAddress)
                case networkHost(hostname: String, port: Int)
                case unixSocket(path: String)
            }
            
            let base: Base
            
            private init(_ base: Base) { self.base = base }
            
            /// Set up MySQL channel handlers on an existing NIO channel and wait for a server handshake packet.
            public static func existingChannel(_ channel: Channel) -> Self { .init(.existingChannel(channel)) }
            
            /// Connect to a raw `SocketAddress`. (Warning: TLS is never enabled for raw address connections.)
            public static func socketAddress(_ address: SocketAddress) -> Self { .init(.socketAddress(address)) }
            
            /// Connect to a given hostname on the given port.
            public static func networkHost(_ hostname: String, port: Int) -> Self { .init(.networkHost(hostname: hostname, port: port)) }
            
            /// Connect to a local UNIX socket at the given path.
            public static func unixSocket(path: String) -> Self { .init(.unixSocket(path: path)) }
        }
        
        public let connection: Connection
        public let tls: TLS
        public let authentication: Authentication
    }
    
    public static func connect(
        on eventLoop: EventLoop,
        configuration: MySQLConnection.Configuration,
        logger: Logger
    ) -> EventLoopFuture<MySQLConnection> {
        // Hop to the event loop before we start to avoid extra context switching.
        return eventLoop.flatSubmit {
            let channelFuture: EventLoopFuture<Channel>

            switch configuration.connection {
                case .existingChannel(let channel): channelFuture = eventLoop.makeSucceededFuture(channel)
                case .socketAddress(let address): channelFuture = self.makeBootstrap(on: eventLoop).connect(to: address)
                case .networkHost(let host, let port): channelFuture = self.makeBootstrap(on: eventLoop).connect(host: host, port: port)
                case .unixSocket(let path): channelFuture = self.makeBootstrap(on: eventLoop).connect(unixDomainSocketPath: path)
            }
            
            return channelFuture.flatMap { channel -> EventLoopFuture<MySQLConnection> in
                let connection = MySQLConnection(channel: channel, logger: logger)
                
                return connection.start(configuration: configuration).map { _ in connection }
            }.flatMapErrorThrowing { error -> MySQLConnection in
                switch error {
                    case is MySQLError: throw error
                    default: throw MySQLError.connection(underlying: error)
                }
            }
        }
    }
    
    public func start(configuration: MySQLConnection.Configuration) -> EventLoopFuture<Void> {
        let sequence = MySQLPacketSequence()
        let decoder = ByteToMessageHandler(MySQLPacketDecoder(sequence: sequence, logger: self.logger))
        let encoder = MessageToByteHandler(MySQLPacketEncoder(sequence: sequence, logger: self.logger))
        let handler = MySQLConnectionHandler.newClientHandler(sequence: sequence, configuration: configuration, handshakeCompletion: self.channel.eventLoop.makePromise(), logger: logger)
        
        do {
            try self.channel.pipeline.syncOperations.addHandlers(decoder, encoder, handler, ErrorHandler(), position: .last)
        } catch {
            return self.eventLoop.makeFailedFuture(error)
        }
    }

    private static func makeBootstrap(on eventLoop: EventLoop) -> NIOClientTCPBootstrapProtocol {
        #if canImport(Network)
        if let tsBootstrap = NIOTSConnectionBootstrap(validatingGroup: eventLoop) {
            return tsBootstrap
        }
        #endif

        if let nioBootstrap = ClientBootstrap(validatingGroup: eventLoop) {
            return nioBootstrap.channelOption(ChannelOptions.socket(SOL_SOCKET, SO_REUSEADDR), value: 1)
        }

        fatalError("Neither Network.framework nor traditional BSD sockets are available; this indicates a problem in your build configuration.")
    }
}
