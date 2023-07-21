extension MySQLChannel {
    public struct Error: Swift.Error {
        enum Code {
            case protocolViolation
            case incompatibleServer
            case unknownAuthMethod(String)
            case serverError(serverCode: UInt16, sqlState: String, message: String)
            case connectionTerminated
        }
        
        private let code: Code
        
        public static var protocolViolation: Error { .init(code: .protocolViolation) }
        public static var incompatibleServer: Error { .init(code: .incompatibleServer) }
        public static func unknownAuthMethod(_ method: String) -> Error { .init(code: .unknownAuthMethod(method)) }
        public static func serverError(serverCode: UInt16, sqlState: String, message: String) -> Error {
            .init(code: .serverError(serverCode: serverCode, sqlState: sqlState, message: message))
        }
        public static var connectionTerminated: Error { .init(code: .connectionTerminated) }
    }
}
