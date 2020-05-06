import Foundation

public enum MySQLError: Error, CustomStringConvertible, LocalizedError {
    case secureConnectionRequired
    case unsupportedAuthPlugin(name: String)
    case unsupportedServer(message: String)
    case protocolError
    case server(MySQLProtocol.ERR_Packet)
    case closed
    
    /// A uniqueness constraint violated. Associated value is message from server with details.
    case duplicateEntry(String)
    
    public var message: String {
        switch self {
        case .secureConnectionRequired:
            return "A secure connection to the server is required for authentication."
        case .unsupportedAuthPlugin(let name):
            return "Unsupported auth plugin name: \(name)"
        case .unsupportedServer(let message):
            return "Unsupported server: \(message)"
        case .protocolError:
            return "Unknown protocol error"
        case .server(let error):
            return "Server error: \(error.errorMessage)"
        case .closed:
            return "Connection closed."
        case .duplicateEntry(let message):
            return "Duplicate entry: \(message)"
        }
    }
    
    public var description: String {
        return "MySQL error: \(self.message)"
    }
    
    public var errorDescription: String? {
        return self.description
    }
}
