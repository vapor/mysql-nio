public import NIOSSL
public import OrderedCollections

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

public struct MySQLConnectionConfiguration: Sendable {
    /// Configuration for TLS (Transport Layer Security) encryption.
    ///
    /// This structure allows you to enable or disable encrypted connections to the MySQL server.
    /// When enabled, it requires an `NIOSSLContext` and optionally a server name for SNI (Server Name Indication).
    public struct TLS: Sendable {
        enum Base {
            case disable
            case prefer(NIOSSLContext, tlsServerName: String?)
            case require(NIOSSLContext, tlsServerName: String?)
        }
        let base: Base

        /// Indicates whether TLS is required for the connection.
        var isEnforced: Bool { if case .require = self.base { true } else { false } }

        var sslContext: (NIOSSLContext, tlsServerName: String?)? {
            switch self.base {
            case .disable:
                nil
            case .prefer(let sslContext, let tlsServerName):
                (sslContext, tlsServerName)
            case .require(let sslContext, let tlsServerName):
                (sslContext, tlsServerName)
            }
        }

        /// Disables TLS for the connection.
        ///
        /// Use this option when connecting to a MySQL server that doesn't require encryption.
        public static var disable: Self { .init(base: .disable) }

        /// Try to enable TLS for the connection.
        ///
        /// If the server supports TLS, create a TLS connection.
        /// If the server does not support TLS, create an insecure connection.
        ///
        /// - Parameters:
        ///   - sslContext: The SSL context used to establish the secure connection
        ///   - tlsServerName: Optional server name for SNI (Server Name Indication)
        /// - Returns: A configured TLS instance
        public static func prefer(_ sslContext: NIOSSLContext, tlsServerName: String?) throws -> Self {
            .init(base: .prefer(sslContext, tlsServerName: tlsServerName))
        }

        /// Require TLS for the connection.
        ///
        /// If the server supports TLS, create a TLS connection.
        /// If the server does not support TLS, fail the connection creation.
        ///
        /// - Parameters:
        ///   - sslContext: The SSL context used to establish the secure connection
        ///   - tlsServerName: Optional server name for SNI (Server Name Indication)
        /// - Returns: A configured TLS instance
        public static func require(_ sslContext: NIOSSLContext, tlsServerName: String?) throws -> Self {
            .init(base: .require(sslContext, tlsServerName: tlsServerName))
        }
    }

    /// The username to connect with.
    public var username: String

    /// The password, if any, for the user specified by ``MySQLConnectionConfiguration/username``.
    ///
    /// > Note: In MySQL, `nil` (meaning "no password provided") and `""` (meaning "empty password") are treated identically at the protocol level.
    /// The distinction is maintained here for the sake of alternate authentication plugins which may differentiate where the default builtin methods do not.
    public var password: String?

    /// TLS configuration for the connection.
    ///
    /// Use `.disable` for unencrypted connections or `.enable(...)` for secure connections.
    public var tls: TLS

    /// The name of the default database to open.
    ///
    /// > Note: If set to `nil`, the connection will have no default database until and unless one is later selected by a `USE` query.
    public var defaultDatabaseName: String?

    /// The maximum time to wait for the completion of the connection handshake after initiating a connection to the MySQL server.
    ///
    /// If the timeout is reached without successfully completing the handshake,
    /// the connection attempt will fail with a timeout error.
    ///
    /// Default value is 10 seconds.
    public var connectTimeout: Duration

    /// The maximum time to wait for a response to a command before considering the connection dead.
    ///
    /// This timeout applies to all standard commands sent to the MySQL server.
    ///
    /// Default value is 30 seconds.
    public var commandTimeout: Duration

    /// Custom attributes to set on the connection.
    ///
    /// The attributes provided here are combined with those set by the package by default; in cases of name
    /// collision, this dictionary's entry takes precedence over any default value.
    ///
    /// > Warning: The combined size of the keys and values of _all_ connection attributes, including the
    ///   package-provided defaults, may not excede 64K. This is a hard protocol limit set by the MySQL server.
    public var connectionAttributes: OrderedDictionary<String, String>

    /// Mark the connection as "interactive".
    ///
    /// This flag's only effect is to determine whether MySQL uses the `wait_timeout` or `interactive_timeout` system variable
    /// to determine the inactivity timeout for the connection.
    /// You probably don't need this.
    public var isInteractive: Bool

    /// Creates a new MySQL connection configuration.
    ///
    /// Use this initializer to create a configuration object that can be used to establish
    /// a connection to a MySQL server with the specified parameters.
    ///
    /// - Parameters:
    ///   - username: The username to connect with.
    ///   - password: The password, if any, for the user specified by ``MySQLConnectionConfiguration/username``.
    ///   - defaultDatabaseName: The name of the default database to open.
    ///   - connectTimeout: Maximum time to wait for the connection handshake. Defaults to 10 seconds.
    ///   - commandTimeout: Maximum time to wait for a response to a command. Defaults to 30 seconds.
    ///   - tls: TLS configuration for secure connections. Defaults to `.disable` for unencrypted connections.
    ///   - connectionAttributes: Custom attributes to set on the connection.
    ///   - isInteractive: Whether to mark the connection as "interactive". Defaults to `false`.
    public init(
        username: String,
        password: String? = nil,
        defaultDatabaseName: String? = nil,
        connectTimeout: Duration = .seconds(10),
        commandTimeout: Duration = .seconds(30),
        tls: TLS = .disable,
        connectionAttributes: OrderedDictionary<String, String> = [:],
        isInteractive: Bool = false
    ) {
        self.username = username
        self.password = password
        self.defaultDatabaseName = defaultDatabaseName
        self.connectTimeout = connectTimeout
        self.commandTimeout = commandTimeout
        self.tls = tls
        self.connectionAttributes = Self.builtinConnectionAttributes.merging(connectionAttributes) { $1 }
        self.isInteractive = isInteractive
    }
}

extension MySQLConnectionConfiguration {
    fileprivate static var builtinConnectionAttributes: OrderedDictionary<String, String> {
        [
            //"_client_name":     "mysql-nio",
            //"_client_version":  "2.0.0",
            "_os": ProcessInfo.processInfo.operatingSystemPlainName.lowercased(),
            "_platform": ProcessInfo.processInfo.hostArchitectureName,
            "_client_license": "MIT",
            "_runtime_vendor": "Apple",
            "_connector_version": "2.0.0",
            "_connector_name": "mysql-nio",
        ]
    }
}
