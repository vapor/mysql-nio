import NIOCore

// The support for this protocol has not yet been implemented. It will be made public when that support is ready.
// Until that time, this protocol is unused.

/// Defines a handler for a specific MySQL authentication "method" (also called a plugin)
///
/// This protocol is public so that external callers may provide additional authentication
/// methods not yet supported natively by this package.
///
/// > Important: All of the methods defined by this protocol are provided with the channel's
///   configuration information in order to enable access to authentication parameters.
///   However, implementations MUST NOT use the value of ``MySQLChannel/Configuration/tls``
///   to detemrine whether the connection is secure; the TLS configuration represents only
///   what setup the calling code originally requested, not what actually happened (especially
///   in the ``MySQLChannel/Configuration/TLS/prefer(_:)`` case, for example). A separate
///   `connectionIsSecure` parameter provides an indicator of the actual security status.
/*public*/ protocol MySQLAuthenticationHandler: Sendable {
    /// The name of a MySQL/MariaDB authentication plugin this handler implements
    ///
    /// Plugin names are used to match handlers with authentication methods requested by servers. They must
    /// match the regex `/^[A-Za-z][A-Za-z0-9_\-]*$/`; comparison is a simple byte-by-byte equality test.
    ///
    /// > Warning: If multiple authentication handlers are registered for the same plugin name, the _last_
    ///   one registered wins.
    ///
    /// > Note: Built-in handlers never overwrite caller-registered handlers; this allows external callers
    ///   to provide alternate implementations for built-in handlers.
    static var pluginName: String { get }
    
    /// Called to inform an authentication handler that it has been chosen to provide auth responses.
    ///
    /// If this method throws, the entire connection is terminated. (This is provided for cases
    /// such as, for example, a failure to load required root certificates.)
    ///
    /// - Parameters:
    ///   - configuration: The MySQL channel configuration. Contains authentication parameters.
    ///   - connectionIsSecure: If `true`, the connection is considered "secure" (e.g. it is safe, at
    ///     least by the standards of MySQL's auth system, to send sensitive data such as passwords in
    ///     the clear). This is set when the underlying connection is TLS-enabled or otherwise proof
    ///     against eavesdropping (such as UNIX domain socket or Windows shared memory connections).
    mutating func handlerChosen(configuration: MySQLChannel.Configuration, connectionIsSecure: Bool) async throws
    
    /// Provides the first or next buffer of incoming authentication data.
    ///
    /// This method may be called with data from a `HandshakeV10` packet, an `AuthSwitchRequest` packet, an
    /// `AuthMoreData` packet, or an `AuthNextFactor` packet. In all cases, the input buffer may be empty if
    /// the server included no additional data.
    ///
    /// > Important: This method return an _optional_ `ByteBuffer`. There is an explicit protocol difference
    ///   between returning `nil` and returning an empty buffer. See below for details.
    ///
    /// ## What to return
    ///
    /// - `nil`: The handler is expecting more incoming data without needing to send a reply at this time.
    /// - Empty buffer: Send a zero-length packet to the server as a reply and wait for more data.
    /// - Filled buffer: Send authentication data as the reply to the server and wait for more data.
    ///
    /// If an error is thrown, the connection is terminated without further attempts at authentication.
    ///
    /// - Parameters:
    ///   - data: The incoming authentication data, stripped of any protocol-specific wrapping.
    ///   - configuration: The MySQL channel configuration. Contains authentication parameters.
    ///   - connectionIsSecure: If `true`, the connection is considered "secure" (e.g. it is safe, at
    ///     least by the standards of MySQL's auth system, to send sensitive data such as passwords in
    ///     the clear). This is set when the underlying connection is TLS-enabled or otherwise proof
    ///     against eavesdropping (such as UNIX domain socket or Windows shared memory connections).
    mutating func processData(_ data: ByteBuffer, configuration: MySQLChannel.Configuration, connectionIsSecure: Bool) async throws -> ByteBuffer?
    
    /// Called to inform an authentication handler that the authentication process has ended
    ///
    /// This method is called regardless of _why_ the process is ended - whether it succeeded, failed, was
    /// stopped due to a connection error, etc. A handler is guaranteed to receive exactly one call to this
    /// method for each call it receives to ``handlerChosen()``, even if that method ithrows an error.
    ///
    /// This method is async for the benefit of handlers which may need to perform asynchronous cleanup. It
    /// may not throw (since the only option for such an error would be to discard it anyway).
    ///
    /// - Parameters:
    ///   - configuration: The MySQL channel configuration. Contains authentication parameters.
    ///   - connectionIsSecure: If `true`, the connection is considered "secure" (e.g. it is safe, at
    ///     least by the standards of MySQL's auth system, to send sensitive data such as passwords in
    ///     the clear). This is set when the underlying connection is TLS-enabled or otherwise proof
    ///     against eavesdropping (such as UNIX domain socket or Windows shared memory connections).
    mutating func closeHandler(configuration: MySQLChannel.Configuration, connectionIsSecure: Bool) async
}
