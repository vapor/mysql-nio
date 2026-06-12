/// Errors returned by a MySQL client.
public struct MySQLClientError: Error, Sendable, Equatable {
    public struct ErrorType: Sendable, Hashable, CustomStringConvertible, Equatable {
        enum Base: String, Sendable, Equatable {
            case connectionClosing
            case connectionClosed
            /// An ERR_Packet was received from the server
            case errorPacket
            /// The Task was cancelled
            case cancelled
            /// Connection closed because another command was cancelled.
            case connectionClosedDueToCancellation
            /// Connection closed because it timed out while waiting for response packet
            case timeout
            /// The server's protocol version is too old or too new, or the server doesn't support the minimum required capabilities.
            case incompatibleServer
            /// Received an unsolicited packet from the server.
            case unsolicitedPacket
            /// Received a packet that cannot be parsed
            case invalidPacket
        }

        let base: Base

        private init(_ base: Base) {
            self.base = base
        }

        public static let connectionClosing = Self(.connectionClosing)
        public static let connectionClosed = Self(.connectionClosed)
        /// An ERR_Packet was received from the server
        public static let errorPacket = Self(.errorPacket)
        /// The Task was cancelled
        public static let cancelled = Self(.cancelled)
        /// Connection closed because another command was cancelled.
        public static let connectionClosedDueToCancellation = Self(.connectionClosedDueToCancellation)
        /// Connection closed because it timed out while waiting for response packet
        public static let timeout = Self(.timeout)
        /// The server's protocol version is too old or too new, or the server doesn't support the minimum required capabilities.
        public static let incompatibleServer = Self(.incompatibleServer)
        /// Received an unsolicited packet from the server.
        public static let unsolicitedPacket = Self(.unsolicitedPacket)
        /// Received a packet that cannot be parsed
        public static let invalidPacket = Self(.invalidPacket)

        public var description: String {
            self.base.rawValue
        }
    }

    private struct Backing: Sendable, Equatable {
        fileprivate let errorType: ErrorType
        fileprivate let errorCode: UInt16?
        fileprivate let errorMessage: String?
        fileprivate let reason: String?

        init(
            errorType: ErrorType,
            errorCode: UInt16? = nil,
            errorMessage: String? = nil,
            reason: String? = nil
        ) {
            self.errorType = errorType
            self.errorCode = errorCode
            self.errorMessage = errorMessage
            self.reason = reason
        }

        static func == (lhs: Backing, rhs: Backing) -> Bool {
            lhs.errorType == rhs.errorType
        }
    }

    private let backing: Backing

    public var errorType: ErrorType { backing.errorType }
    /// The error code from the ERR_Packet, if the error is of type `.errorPacket`
    public var errorCode: UInt16? { backing.errorCode }
    /// The error message from the ERR_Packet, if the error is of type `.errorPacket`
    public var errorMessage: String? { backing.errorMessage }
    /// Generic reason for the error
    public var reason: String? { backing.reason }

    private init(backing: Backing) {
        self.backing = backing
    }

    private init(errorType: ErrorType) {
        self.backing = .init(errorType: errorType)
    }

    public static let connectionClosing = Self(errorType: .connectionClosing)

    public static let connectionClosed = Self(errorType: .connectionClosed)

    /// An ERR_Packet was received from the server
    ///
    /// - Parameters:
    ///   - errorCode: The error code from the ERR_Packet
    ///   - errorMessage: The error message from the ERR_Packet
    public static func errorPacket(errorCode: UInt16? = nil, errorMessage: String? = nil) -> Self {
        .init(backing: .init(errorType: .errorPacket, errorCode: errorCode, errorMessage: errorMessage))
    }

    /// The Task was cancelled
    public static let cancelled = Self(errorType: .cancelled)

    /// Connection closed because another command was cancelled.
    public static let connectionClosedDueToCancellation = Self(errorType: .connectionClosedDueToCancellation)

    /// Connection closed because it timed out while waiting for response packet
    public static let timeout = Self(errorType: .timeout)

    /// The server's protocol version is too old or too new, or the server doesn't support the minimum required capabilities.
    public static func incompatibleServer(_ reason: String) -> Self {
        .init(backing: .init(errorType: .incompatibleServer, reason: reason))
    }

    /// Received an unsolicited packet from the server.
    public static func unsolicitedPacket(_ reason: String) -> Self {
        .init(backing: .init(errorType: .unsolicitedPacket, reason: reason))
    }

    /// Received a packet that cannot be parsed
    public static func invalidPacket(_ reason: String) -> Self {
        .init(backing: .init(errorType: .invalidPacket, reason: reason))
    }

    public static func == (lhs: MySQLClientError, rhs: MySQLClientError) -> Bool {
        lhs.backing == rhs.backing
    }
}

extension MySQLClientError: CustomStringConvertible {
    public var description: String {
        var result = "MySQLClientError(errorType: \(self.errorType)"
        if let errorCode { result += ", errorCode: \(errorCode)" }
        if let errorMessage { result += ", errorMessage: \(errorMessage)" }
        if let reason { result += ", reason: \(reason)" }
        result += ")"
        return result
    }
}
