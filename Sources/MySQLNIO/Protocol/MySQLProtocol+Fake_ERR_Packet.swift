extension MySQLProtocol {
    /// 14.1.3.2 `ERR_Packet`
    ///
    /// This packet signals that an error occurred. It contains a SQL state value if `CLIENT_PROTOCOL_41` is enabled.
    ///
    /// This definition was previously used as `ERR_Packet`, but it was unfortunately exposed as public API via
    /// `MySQLError` in a form that caused it to be directly visible to clients of Fluent, so despite several
    /// issues, it can't go away completely yet. It has been renamed and can be typealiased on import to prevent
    /// breaking upstream API; the new `ERR_Packet` type is strictly `internal` and will not conflict.
    public struct ServerErrorDetails: MySQLPacketDecodable {
        public enum DecodeError: Swift.Error {
            case missingFlag
            case invalidFlag(UInt8)
            case missingErrorCode
            case missingSQLStateMarker
            case missingSQLState
            case missingErrorMessage
        }
        
        public var errorCode: ErrorCode
        public var sqlStateMarker: String? { "#" }
        public var sqlState: String?
        public var errorMessage: String
        
        internal static func synthesize(from realPacket: ERR_Packet) -> Self {
            guard case .error(let serverError) = realPacket.contents else {
                return .init(errorCode: .UNKNOWN_COM_ERROR, sqlStateMarker: "#", sqlState: "0000", errorMessage: "Mishandled error response")
            }
            return .init(errorCode: serverError.errorCode, sqlState: serverError.sqlState, errorMessage: serverError.errorMessage)
        }
    }
}
