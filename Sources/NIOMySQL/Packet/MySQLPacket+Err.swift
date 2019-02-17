extension MySQLPacket {
    public mutating func err(capabilities: MySQLCapabilityFlags) throws -> Err {
        return try Err(payload: &self.payload, capabilities: capabilities)
    }
    
    /// 14.1.3.2 ERR_Packet
    ///
    /// This packet signals that an error occurred. It contains a SQL state value if CLIENT_PROTOCOL_41 is enabled.
    ///
    /// https://dev.mysql.com/doc/internals/en/packet-ERR_Packet.html
    public struct Err {
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
        
        public init(payload: inout ByteBuffer, capabilities: MySQLCapabilityFlags) throws {
            guard let flag = payload.readInteger(endianness: .little, as: UInt8.self) else {
                throw Error.missingFlag
            }
            guard flag == 0xFF else {
                throw Error.invalidFlag(flag)
            }
            guard let errorCode = payload.readInteger(endianness: .little, as: UInt16.self) else {
                throw Error.missingErrorCode
            }
            self.errorCode = errorCode
            
            if capabilities.contains(.CLIENT_PROTOCOL_41) {
                guard let sqlStateMarker = payload.readString(length: 1) else {
                    throw Error.missingSQLStateMarker
                }
                self.sqlStateMarker = sqlStateMarker
                guard let sqlState = payload.readString(length: 5) else {
                    throw Error.missingSQLState
                }
                self.sqlState = sqlState
            }
            guard let errorMessage = payload.readString(length: payload.readableBytes) else {
                throw Error.missingErrorMessage
            }
            self.errorMessage = errorMessage
        }
    }
}
