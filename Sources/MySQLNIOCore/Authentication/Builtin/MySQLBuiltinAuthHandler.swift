import NIOCore

protocol MySQLBuiltinAuthHandler {
    static var pluginName: String { get }
    mutating func processData(_ data: ByteBuffer, configuration: MySQLChannel.Configuration, connectionIsSecure: Bool) throws -> ByteBuffer?
}

enum MySQLBuiltinAuthHandlers {
    static func authHandler(for pluginName: String) -> (any MySQLBuiltinAuthHandler)? {
        switch pluginName {
        case CachingSHA2.pluginName: return CachingSHA2()
        case MariaDBEd25519.pluginName: return MariaDBEd25519()
        case MariaDBUnixSocket.pluginName: return MariaDBUnixSocket()
        case NativePassword.pluginName: return NativePassword()
        case SimpleSHA256.pluginName: return SimpleSHA256()
        default: return nil
        }
    }
}
