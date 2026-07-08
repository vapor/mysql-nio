public import NIOCore

@usableFromInline
protocol AuthenticationMethod: ~Copyable {
    static var name: String { get }
    mutating func processData(_ data: ByteBuffer, password: String?, connectionIsSecure: Bool) throws -> ByteBuffer?
}

enum AuthenticationMethods {
    static func fromName(_ name: String?, capabilities: MySQLCapabilities?) -> any AuthenticationMethod & ~Copyable {
        switch name {
        case CachingSHA2Password.name:
            CachingSHA2Password()
        case MySQLNativePassword.name:
            MySQLNativePassword()
        case .none:
            if let capabilities {
                if !capabilities.contains(.pluginAuth)  // Double check that CLIENT_PLUGIN_AUTH is not set
                    && capabilities.contains(.clientProtocol41)
                    && capabilities.contains(.secureConnection)
                {
                    MySQLNativePassword()
                } else {
                    fatalError("Old Password Authentication is not supported.")
                }
            } else {
                preconditionFailure("capabilities can be nil only if the authentication plugin name is provided, but it was not")
            }
        case .some(let name):
            fatalError("Unsupported authentication method: \(name)")
        }
    }
}
