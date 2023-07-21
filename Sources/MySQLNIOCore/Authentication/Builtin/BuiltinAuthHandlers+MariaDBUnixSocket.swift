import NIOCore

extension MySQLBuiltinAuthHandlers {
    struct MariaDBUnixSocket: MySQLBuiltinAuthHandler {
        static var pluginName: String { "unix_socket" }
        
        mutating func processData(_ data: ByteBuffer, configuration: MySQLChannel.Configuration, connectionIsSecure: Bool) throws -> ByteBuffer? {
            nil
        }
    }
}
