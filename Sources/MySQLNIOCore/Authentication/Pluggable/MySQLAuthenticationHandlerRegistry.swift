import NIOCore

// The support for this registry has not yet been implemented. It will be made public when that support is ready.
// Until that time, this actor is unused.

/// Provides a publicly accessible registry of factory closures for MySQL authentication handlers
///
/// Ultimately, each MySQL connection has its own auth handler registry which is consulted for that
/// connection. However, by default all connections will use the "shared" registry unless explicitly
/// overridden. This allows registering handlers on a "global" basis while simultaneously providing
/// fine-grained control over the handlers any given connection can use.
/*public*/ actor MySQLAuthenticationRegistry {
    /// A reference to the "shared" registry that all connections use by default.
    ///
    /// > Warning: Changes made to the shared registry only affect connections which have not been
    ///   created yet. A connection which uses the shared registry copies it at initialization time.
    ///
    /// In general, it is strongly recommended that external code make all desired changes to the
    /// shared registry before creating _any_ connections, and leave it alone thereafter.
    public static let shared: MySQLAuthenticationRegistry = ._shared()
    
    /// Add an authentication handler to the registry.
    ///
    /// Provide a closure or function reference which returns a new instance of the handler's type.
    /// This factory will be called each time the handler is needed.
    ///
    /// If an existing handler claims the same plugin name as that of the type returned by the factory,
    /// the new one replaces it.
    ///
    /// > Important: Most often the factory closure will be a refererence to a parameter-less `init()`
    ///   method of the handler type. The factory can be used to specify configuration for a handler,
    ///   but as only one handler can claim a given plugin name at a time, this can not be used to
    ///   provide multiple alternate configurations for the same plugin. Finally, authentication
    ///   handlers have an asynchronous `handlerChosen()` method intended to provide an opportunity for
    ///   complex/expensive initialization (such as loading a root certificate store); whenever possible,
    ///   defer any non-configuration initialization to that method rather than doing it in the factory.
    public func register<H: MySQLAuthenticationHandler>(_ factory: @escaping @Sendable () -> H) async {
        self.registeredHandlers[H.pluginName] = factory
    }
    
    /// Remove the handler for the given plugin name from the registry, if one exists.
    ///
    /// This allows callers to explicitly disable authentication handlers, including the builtin ones.
    /// A removed handler may be registered again at any time.
    ///
    /// Returns `true` if a registered handler was removed, false otherwise.
    ///
    /// > Note: Whenever possible, use the `pluginName` property of the appropriate authentication handler
    ///   when calling this method, rather than hardcoding the string directly. For example:
    /// > ```swift
    /// > registry.unregister(
    /// >     name: MySQLBuiltinAuthenticationHandlers.NativePassword.pluginName
    /// > )
    @discardableResult
    public func unregister(name: String) async -> Bool {
        self.registeredHandlers.removeValue(forKey: name) != nil
    }
    
    /// Return a copy of the registry. Modifications to the copy will not affect the original registry.
    ///
    /// Primarily used for creating connection-specific registries.
    public func copyRegistry() async -> MySQLAuthenticationRegistry {
        .init(preregisteredHandlers: self.registeredHandlers)
    }
    
    // MARK: - Internal methods
    
    /// Return a new instance of a handler for the given plugin name, if one is registered
    func lookupAndCreateHandler(for name: String) async -> (any MySQLAuthenticationHandler)? {
        self.registeredHandlers[name]?()
    }
    
    // MARK: - Primitives
    
    /// Create a registry with an arbitrary predefined set of handlers. Designated initializer.
    private init(preregisteredHandlers: [String: @Sendable () -> any MySQLAuthenticationHandler]) {
        self.registeredHandlers = preregisteredHandlers
    }

    private var registeredHandlers: [String: @Sendable () -> any MySQLAuthenticationHandler]
        
    // MARK: - Builtin handlers
    
    private static func _shared() -> MySQLAuthenticationRegistry {
//        .init(builtinHandlers:
//            MySQLBuiltinAuthenticationHandlers.NativePassword.init,
//            MySQLBuiltinAuthenticationHandlers.SimpleSHA256.init,
//            MySQLBuiltinAuthenticationHandlers.CachingSHA256.init,
//            MySQLBuiltinAuthenticationHandlers.MariaDBEd25519.init
//        )
        .init(preregisteredHandlers: [:])
    }
    
#if swift(>=5.9)
    /// The purpose of this initializer is to make maintaining the builtin handlers list simple and clean.
    /// Using the designated initializer would be repetitive at best.
    private init<each H: MySQLAuthenticationHandler>(builtinHandlers: repeat (@Sendable @escaping () -> each H)) {
        var intermediate: [String: @Sendable () -> any MySQLAuthenticationHandler] = [:]
        repeat (intermediate[(each H).pluginName] = (each builtinHandlers))
        
        self.init(preregisteredHandlers: intermediate)
    }
#else
    /// The purpose of this initializer is to make maintaining the builtin handlers list simple and clean.
    /// Using the designated initializer instead would be repetitive at best. Of course, before Swift 5.9
    /// we don't have variadic generics, so we have to do it the ugliest possible way. There's no point
    /// providing all the different versions of this implementation that accept more or fewer parameters,
    /// we can tweak it when the builtins list gets tweaked and then ditch it completely when 5.9 becomes
    /// a minimum requirement.
    private init(builtinHandlers
          factory1: @Sendable @escaping () -> some MySQLAuthenticationHandler,
        _ factory2: @Sendable @escaping () -> some MySQLAuthenticationHandler,
        _ factory3: @Sendable @escaping () -> some MySQLAuthenticationHandler,
        _ factory4: @Sendable @escaping () -> some MySQLAuthenticationHandler
    ) {
        self.init(preregisteredHandlers: [
            type(of: factory1()).pluginName: factory1,
            type(of: factory2()).pluginName: factory2,
            type(of: factory3()).pluginName: factory3,
            type(of: factory4()).pluginName: factory4,
        ])
    }
#endif
}

/// A namespacing container for the builtin authentication handlers provided by this package.
///
/// This type ~is~ will be made public to allow users to work with the builtin handlers.
//public enum MySQLBuiltinAuthenticationHandlers {}
