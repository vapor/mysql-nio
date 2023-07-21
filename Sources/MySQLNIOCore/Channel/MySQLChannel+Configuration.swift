import NIOCore
import NIOSSL

extension MySQLChannel {
    /// A configuration object for a connection
    public struct Configuration: Sendable {
        // MARK: - TLS
        
        /// The possible modes of operation for TLS encapsulation of a connection.
        public struct TLS: Sendable {
            /// Do not try to create a TLS connection to the server.
            public static var disable: Self { .init(base: .disable) }

            /// Try to create a TLS connection to the server. If the server supports TLS, create a TLS connection.
            /// If the server does not support TLS, create an insecure connection.
            public static func prefer(_ sslContext: NIOSSLContext) -> Self { self.init(base: .prefer(sslContext)) }

            /// Try to create a TLS connection to the server. If the server supports TLS, create a TLS connection.
            /// If the server does not support TLS, fail the connection creation.
            public static func require(_ sslContext: NIOSSLContext) -> Self { self.init(base: .require(sslContext)) }
            
            /// Whether TLS will be attempted on the connection (`false` only when mode is ``disable``).
            public var isAllowed: Bool { if case .disable = self.base { return false } else { return true } }
            
            /// Whether TLS will be enforced on the connection (`true` only when mode is ``require(_:)``).
            public var isEnforced: Bool { if case .require(_) = self.base { return true } else { return false } }
            
            /// The `NIOSSLContext` that will be used. `nil` when TLS is disabled.
            public var sslContext: NIOSSLContext? {
                switch self.base {
                case .prefer(let context), .require(let context): return context
                case .disable: return nil
                }
            }

            enum Base { case disable, prefer(NIOSSLContext), require(NIOSSLContext) }
            let base: Base
            private init(base: Base) { self.base = base }
        }
        
        // MARK: - Connection options
        
        /// Describes options affecting how the underlying connection is made.
        public struct Options: Sendable {
            /// A timeout for connection attempts. Defaults to ten seconds.
            ///
            /// Ignored when using a preexisting communcation channel.
            public var connectTimeout: TimeAmount
            
            /// The server name to use for certificate validation and SNI (Server Name Indication) when TLS is enabled.
            /// Defaults to none (but see below).
            ///
            /// > When set to `nil`:
            /// If the connection is made to a server over TCP, the given hostname is used, unless it was an IP address
            /// string. If it _was_ an IP, or the connection is made by any other method, SNI is disabled.
            public var tlsServerName: String?
            
            /// Custom attributes to set on the connection.
            ///
            /// The attributes provided here are combined with those set by the package by default; in cases of name
            /// collision, this dictionary's entry takes precedence over any default value.
            ///
            /// > Warning: The combined size of the keys and values of _all_ connection attributes, including the
            ///   package-provided defaults, may not excede 64K. This is a hard protocol limit set by the MySQL server.
            public var connectionAttributes: [String: String]
            
            /// Additional authentication data for the connection.
            ///
            /// These key-value pairs are made available to custom authentication handlers which need additional data
            /// beyond the standard username and password combination. None of the built-in handlers require such data.
            public var additionalAuthenticationData: [String: [UInt8]]
            
            /// Mark the connection as "interactive".
            ///
            /// This flag's only effect is to determine whether MySQL uses the `wait_timeout` or `interactive_timeout`
            /// system variable to determine the inactivity timeout for the connection. You probably don't need this.
            /// Defaults to `false`.
            public var isInteractive: Bool

            /// Create an options structure with default values.
            ///
            /// Most users should not need to adjust the defaults.
            public init() {
                self.connectTimeout = .seconds(10)
                self.tlsServerName = nil
                self.connectionAttributes = [:]
                self.additionalAuthenticationData = [:]
                self.isInteractive = false
            }
        }
        
        // MARK: - Accessors

        /// The hostname to connect to for TCP configurations.
        ///
        /// Always `nil` for other configurations.
        public var host: String? {
            if case let .connectTCP(host, _) = self.endpointInfo { return host }
            else { return nil }
        }
        
        /// The port to connect to for TCP configurations.
        ///
        /// Always `nil` for other configurations.
        public var port: Int? {
            if case let .connectTCP(_, port) = self.endpointInfo { return port }
            else { return nil }
        }
        
        /// The socket path to connect to for Unix domain socket connections.
        ///
        /// Always `nil` for other configurations.
        public var unixSocketPath: String? {
            if case let .bindUnixDomainSocket(path) = self.endpointInfo { return path }
            else { return nil }
        }
        
        /// The `Channel` to use in existing-channel configurations.
        ///
        /// Always `nil` for other configurations.
        public var establishedChannel: (any Channel)? {
            if case let .configureChannel(channel) = self.endpointInfo { return channel }
            else { return nil }
        }
        
        /// The TLS mode to use for the connection. Valid for all configurations.
        ///
        /// See ``TLS-swift.struct``.
        public var tls: TLS
        
        /// Options for handling the communication channel. Most users don't need to change these.
        ///
        /// See ``Options-swift.struct``.
        public var options: Options = .init()
        
        /// The username to connect with.
        public var username: String

        /// The password, if any, for the user specified by ``username``.
        ///
        /// > Note: In MySQL, `nil` (meaning "no password provided") and `""` (meaning "empty password") are treated
        ///   identically at the protocol level. The distinction is maintained here for the sake of alternate
        ///   authentication plugins which may differentiate where the default builtin methods do not.
        public var password: String?

        /// The name of the database to open.
        ///
        /// > Note: If set to `nil`, the connection will have no default database until and unless one is later
        ///   selected by a `USE` query.
        public var database: String?

        // MARK: - Initializers

        /// Create a configuration for connecting to a server with a hostname and optional port.
        ///
        /// This specifies a TCP connection. If you're unsure which kind of connection you want, you almost
        /// definitely want this one.
        ///
        /// - Parameters:
        ///   - host: The hostname to connect to.
        ///   - port: The TCP port to connect to (defaults to 3306).
        ///   - username: The username to connect as.
        ///   - password: The optional password to authenticate with.
        ///   - database: The optional database to use as the connection's default.
        ///   - tls: The TLS mode to use.
        public init(host: String, port: Int = 3306, username: String, password: String?, database: String?, tls: TLS) {
            self.init(endpointInfo: .connectTCP(host: host, port: port), tls: tls, username: username, password: password, database: database)
        }
            
        /// Create a configuration for connecting to a server through a UNIX domain socket.
        ///
        /// - Parameters:
        ///   - path: The filesystem path of the socket to connect to.
        ///   - tls: The TLS mode to use. Defaults to ``TLS-swift.struct/disable``.
        ///   - username: The username to connect as.
        ///   - password: The optional password to authenticate with.
        ///   - database: The optional database to use as the connection's default.
        public init(unixSocketPath: String, username: String, password: String?, database: String?) {
            self.init(endpointInfo: .bindUnixDomainSocket(path: unixSocketPath), tls: .disable, username: username, password: password, database: database)
        }
            
        /// Create a configuration for establishing a connection to a Postgres server over a preestablished
        /// `NIOCore/Channel`.
        ///
        /// This is provided for calling code which wants to manage the underlying connection transport on its
        /// own, such as when tunneling a connection through SSH.
        ///
        /// - Parameters:
        ///   - channel: The `NIOCore/Channel` to use. The channel must already be active and connected to an
        ///     endpoint (i.e. `NIOCore/Channel/isActive` must be `true`).
        ///   - tls: The TLS mode to use. Defaults to ``TLS-swift.struct/disable``.
        ///   - username: The username to connect as.
        ///   - password: The optional password to authenticate with.
        ///   - database: The optional database to use as the connection's default.
        public init(establishedChannel channel: any Channel, username: String, password: String?, database: String?) {
            self.init(endpointInfo: .configureChannel(channel), tls: .disable, username: username, password: password, database: database)
        }

        // MARK: - Implementation details

        enum EndpointInfo {
            case configureChannel(any Channel)
            case bindUnixDomainSocket(path: String)
            case connectTCP(host: String, port: Int)
        }

        var endpointInfo: EndpointInfo

        init(endpointInfo: EndpointInfo, tls: TLS, username: String, password: String?, database: String?) {
            self.endpointInfo = endpointInfo
            self.tls = tls
            self.username = username
            self.password = password
            self.database = database
        }
    }
}
