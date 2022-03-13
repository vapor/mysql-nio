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
        public var sqlStateMarker: String?
        public var sqlState: String?
        public var errorMessage: String
        
        public static func decode(from packet: inout MySQLPacket, capabilities: CapabilityFlags) throws -> ERR_Packet {
            guard let flag = packet.payload.readInteger(endianness: .little, as: UInt8.self) else { throw DecodeError.missingFlag }
            guard flag == 0xFF else { throw DecodeError.invalidFlag(flag) }
            guard let errorCode = packet.payload.readInteger(endianness: .little, as: ErrorCode.self) else { throw DecodeError.missingErrorCode }
            
            var sqlStateMarker: String? = nil, sqlState: String? = nil
            if capabilities.contains(.CLIENT_PROTOCOL_41) {
                guard let marker = packet.payload.readString(length: 1) else { throw DecodeError.missingSQLStateMarker }
                sqlStateMarker = marker
                guard let state = packet.payload.readString(length: 5) else { throw DecodeError.missingSQLState }
                sqlState = state
            }
            guard let errorMessage = packet.payload.readString(length: packet.payload.readableBytes) else { throw DecodeError.missingErrorMessage }
            return .init(errorCode: errorCode, sqlStateMarker: sqlStateMarker, sqlState: sqlState, errorMessage: errorMessage)
        }
        
        internal static func synthesize(from realPacket: ERR_Packet) -> Self {
        
        }
    }
}
