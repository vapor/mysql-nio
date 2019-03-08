extension MySQLProtocol {
    /// 14.1.3.2 ERR_Packet
    ///
    /// This packet signals that an error occurred. It contains a SQL state value if CLIENT_PROTOCOL_41 is enabled.
    ///
    /// https://dev.mysql.com/doc/internals/en/packet-ERR_Packet.html
    public struct ERR_Packet: MySQLPacketDecodable {
        public enum Error: Swift.Error {
            case missingFlag
            case invalidFlag(UInt8)
            case missingErrorCode
            case missingSQLStateMarker
            case missingSQLState
            case missingErrorMessage
        }
        
        /// error_code    error-code
        public var errorCode: UInt16
        
        /// string[1] sql_state_marker    # marker of the SQL State
        public var sqlStateMarker: String?
        
        /// string[5] sql_state    SQL State
        public var sqlState: String?
        
        /// string<EOF>    error_message    human readable error message
        public var errorMessage: String
        
        /// `MySQLPacketDecodable` conformance.
        public static func decode(from packet: inout MySQLPacket, capabilities: CapabilityFlags) throws -> ERR_Packet {
            guard let flag = packet.payload.readInteger(endianness: .little, as: UInt8.self) else {
                throw Error.missingFlag
            }
            guard flag == 0xFF else {
                throw Error.invalidFlag(flag)
            }
            guard let errorCode = packet.payload.readInteger(endianness: .little, as: UInt16.self) else {
                throw Error.missingErrorCode
            }
            
            let sqlStateMarker: String?
            let sqlState: String?
            if capabilities.contains(.CLIENT_PROTOCOL_41) {
                guard let marker = packet.payload.readString(length: 1) else {
                    throw Error.missingSQLStateMarker
                }
                sqlStateMarker = marker
                guard let state = packet.payload.readString(length: 5) else {
                    throw Error.missingSQLState
                }
                sqlState = state
            } else {
                sqlStateMarker = nil
                sqlState = nil
            }
            guard let errorMessage = packet.payload.readString(length: packet.payload.readableBytes) else {
                throw Error.missingErrorMessage
            }
            return .init(errorCode: errorCode, sqlStateMarker: sqlStateMarker, sqlState: sqlState, errorMessage: errorMessage)
        }
    }
}
