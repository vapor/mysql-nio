import Foundation

public enum MySQLError: Error, CustomStringConvertible, LocalizedError {
    case secureConnectionRequired
    case unsupportedAuthPlugin(name: String)
    case authPluginDataError(name: String)
    case missingOrInvalidAuthMoreDataStatusTag
    case missingOrInvalidAuthPluginInlineCommand(command: UInt8?)
    case missingAuthPluginInlineData
    case unsupportedServer(message: String)
    case packetDecodingError(type: String) // failed to read a packet of the given time (incomplete, corrupt, or unsupported)
    case packetEncodingError(type: String) // the configuration of an outgoing packet is invalid or unsupported by the server
    case protocolError // any generic protocol-level failure not covered elsewhere
    case server(MySQLProtocol.ServerErrorDetails)
    case closed
    case connection(underlying: Error)
    
    /// A uniqueness constraint was violated. Associated value is message from server with details.
    case duplicateEntry(String)
    
    /// A syntax error occurred in a query. Associated value is message from server with details.
    case invalidSyntax(String)
    
    public var message: String {
        switch self {
        case .secureConnectionRequired:
            return "A secure connection to the server is required for authentication."
        case .unsupportedAuthPlugin(let name):
            return "Unsupported auth plugin name: \(name)"
        case .authPluginDataError(let name):
            return "Auth plugin (name: \(name)) sent invalid authentication data."
        case .missingOrInvalidAuthMoreDataStatusTag:
            return "Auth plugin didn't send a correct status tag per protocol."
        case .missingOrInvalidAuthPluginInlineCommand(let byte):
            return "Auth plugin sent \(byte.map { "\($0)" } ?? "<nothing>"), which we can't interpret."
        case .missingAuthPluginInlineData:
            return "Auth plugin was supposed to send us some data."
        case .unsupportedServer(let message):
            return "Unsupported server: \(message)"
        case .packetDecodingError(type: _), .packetEncodingError(type: _), .protocolError:
            return "Unknown protocol error"
        case .server(let error):
            return "Server error: \(error.errorMessage)"
        case .closed:
            return "Connection closed."
        case .connection(let underlyingError):
            return "Underlying connection error: \(underlyingError)"
        case .duplicateEntry(let message):
            return "Duplicate entry: \(message)"
        case .invalidSyntax(let message):
            return "Invalid syntax: \(message)"
        }
    }
    
    public var description: String {
        return "MySQL error: \(self.message)"
    }
    
    public var errorDescription: String? {
        return self.description
    }
}
