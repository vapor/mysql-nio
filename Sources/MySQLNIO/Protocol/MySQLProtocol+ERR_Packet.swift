extension MySQLProtocol {
    /// 14.1.3.2 `ERR_Packet`
    ///
    /// This packet signals that an error occurred. It contains a SQL state value if `CLIENT_PROTOCOL_41` is enabled.
    ///
    /// If the server is MariaDB 5.3 or later and the `MARIADB_CLIENT_PROGRESS` capability is set, an `ERR_Packet`
    /// with error number `0xffff` represents a progress report packet with a different format.
    ///
    /// - Note: Due to limitations of the current internal design of this package, while progress report packets can
    ///   be correctly decoded, they can not be fully processed; at the time of this writing, this implementation
    ///   just barely manages to ignore progress reports instead of incorrectly reporting them as errors. It is
    ///   recommended that clients simply do not set the `CLIENT_PROGRESS` capability in the first place.
    ///
    /// https://dev.mysql.com/doc/internals/en/packet-ERR_Packet.html
    /// https://mariadb.com/kb/en/err_packet/
    struct ERR_Packet: MySQLPacketCodable {
        enum DecodeError: Swift.Error {
            case missingFlag
            case missingErrorCode
            case missingSQLState
            case missingErrorMessage
            case missingProgressInfo
        }
        
        /// `error_code     error-code`
        /// see below
        let contents: Contents
        
        /// When `error_code` != `0xffff`:
        /// `string[1]      sql_state_marker    # marker`
        /// `string[5]      sql_state           SQL State`
        /// `string<EOF>    error_message       human readable error message`
        struct ServerError {
            let errorCode: ErrorCode
            let sqlState: String
            let errorMessage: String
        }
        
        /// When `error_code` == `0xffff`:
        /// `int<1>         num_strings   number of status strings (for future, always 1)`
        /// `int<1>         stage         progress stage`
        /// `int<1>         max_stage     number of stages`
        /// `int<3>         progress      % done * 1000`
        /// `string<lenenc> status  status / stage name`
        struct ServerProgress {
            let stage: UInt8
            let maxStage: UInt8
            let percentDone: Double
            let status: String
        }
        
        enum Contents {
            case error(ServerError)
            case progress(ServerProgress)
        }
        
        /// `MySQLPacketDecodable` conformance.
        static func decode(from packet: inout MySQLPacket, capabilities: CapabilityFlags) throws -> ERR_Packet {
            guard try packet.readInteger(endianness: .little, as: UInt8.self) == 0xff else { throw MySQLError.protocolError }
            
            let errorCode = try packet.readInteger(endianness: .little, as: ErrorCode.self)
            
            if errorCode < .max || !capabilities.contains(.MARIADB_CLIENT_PROGRESS) {
                let sqlState = try packet.readString(length: 6)
                guard sqlState.first == "#" else { throw MySQLError.protocolError }
                let errorMessage = try packet.readString(length: packet.payload.readableBytes)
                
                return .init(contents: .error(.init(errorCode: errorCode, sqlState: .init(sqlState.dropFirst()), errorMessage: errorMessage)))
            } else {
                guard try packet.readInteger(endianness: .little, as: UInt8.self) == 1 else { throw MySQLError.protocolError }
                
                return .init(contents: .progress(.init(
                    stage: try packet.readInteger(endianness: .little, as: UInt8.self),
                    maxStage: try packet.readInteger(endianness: .little, as: UInt8.self),
                    percentDone: Double(try packet.readUInt24(endianness: .little)) / 1000.0,
                    status: try packet.readLengthEncodedString()
                )))
            }
        }
        
        /// `MySQLPacketEncodable` conformance.
        func encode(to packet: inout MySQLPacket, capabilities: MySQLProtocol.CapabilityFlags) throws {
            packet.payload.writeInteger(0xff, endianness: .little, as: UInt8.self)
            switch self.contents {
                case .error(let info):
                    packet.payload.writeInteger(info.errorCode, endianness: .little, as: ErrorCode.self)
                    packet.payload.writeString("#\(info.sqlState)")
                    packet.payload.writeString(info.errorMessage)
                case .progress(let info):
                    let progress = UInt32(info.percentDone * 1000.0)
                    packet.payload.writeInteger(0xffff, endianness: .little, as: ErrorCode.self)
                    packet.payload.writeInteger(1, endianness: .little, as: UInt8.self)
                    packet.payload.writeInteger(info.stage, endianness: .little, as: UInt8.self)
                    packet.payload.writeInteger(info.maxStage, endianness: .little, as: UInt8.self)
                    packet.payload.writeUInt24(progress, endianness: .little)
                    packet.payload.writeLengthEncodedString(info.status)
            }
        }
    }
}
