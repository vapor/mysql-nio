import NIOCore

extension MySQLBuiltinAuthHandlers {
    struct SimpleSHA256: MySQLBuiltinAuthHandler {
        static var pluginName: String { "sha256_password" }
        
        mutating func processData(_ data: ByteBuffer, configuration: MySQLChannel.Configuration, connectionIsSecure: Bool) throws -> ByteBuffer? {
            nil
        }
    }
}
