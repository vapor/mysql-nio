import NIOConcurrencyHelpers

/// A type conforming to this protocol may be registered under one or more authentication plugin
/// names to be invoked when a MySQL server requests authentication with one of the named methods.
public protocol MySQLAuthPluginResponder {
    /// Called with auth data sent by the server. May be data from the initial handshake packet,
    /// the initial data from auth method switch packet, or the data from any arbitrary packet
    /// received during the auth phase. May be empty if the initial data for the auth method was
    /// not provided. Any data returned is encapsulated in the wire format for data packets and
    /// sent to the server (unless the incoming data was from the initial handshake packet, in
    /// which case the returned data is included in the handshake response). If any error is thrown,
    /// the connection fails. The provided name is the actual auth plugin name most recently
    /// received from the server in the handshake packet or an auth method switch packet; it is
    /// provided to allow responders that handle multiple plugin names to distinguish specific
    /// methods as needed. Returning `nil` means "don't send anything at all in response"; returning
    /// an empty array means "send the next appropriate packet but without any auth data".
    func handle(pluginName: String, configuration: MySQLConnection.Configuration, isSecureConnection: Bool, data: [UInt8]) throws -> [UInt8]?
}

/// Acts as a global registry of MySQL auth plugin implementations. Registering the same plugin
/// name multiple times results in the last responder registered at the time of a connection
/// requesting it being used. The registry is thread-safe and may be updated at any time, but it
/// is **strongly** recommended that it only be updated _before_ opening any MySQL connections.
/// The default responders for the plugins implemented by this package are effectively pre-
/// registered and therefore may be overridden by a client wishing to substitute its own version.
///
/// Rather than registering individual responder instances, clients register responder factories.
/// A new instance of the appropriate responder is created for each usage.
public enum MySQLAuthPluginResponderRegistry {
    private static var storage: [String: (String) -> any MySQLAuthPluginResponder] = [:]
    private static var lock = Lock()
    
    public static func handle(pluginName: String, using responderFactory: (_ authPluginName: String) -> any MySQLAuthPluginResponder) {
        self.lock.withLock {
            self.storage[pluginName] = responderFactory
        }
    }
    
    internal static func responder(for pluginName: String) -> Optional<any MySQLAuthPluginResponder> {
        self.lock.withLock {
            self.storage[pluginName]?(pluginName)
        }
    }
}
