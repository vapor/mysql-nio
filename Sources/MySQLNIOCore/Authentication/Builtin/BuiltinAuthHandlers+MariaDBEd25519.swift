import NIOCore

extension MySQLBuiltinAuthHandlers {
    struct MariaDBEd25519: MySQLBuiltinAuthHandler {
        static var pluginName: String { "ed25519" }
        
        mutating func processData(_ data: ByteBuffer, configuration: MySQLChannel.Configuration, connectionIsSecure: Bool) throws -> ByteBuffer? {
            nil
        }
    }
}
