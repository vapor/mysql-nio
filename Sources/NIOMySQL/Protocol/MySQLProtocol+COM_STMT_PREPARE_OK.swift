extension MySQLProtocol {
    /// 14.7.4.1 COM_STMT_PREPARE Response
    ///
    /// If the COM_STMT_PREPARE succeeded, it sends a COM_STMT_PREPARE_OK
    ///
    /// https://dev.mysql.com/doc/internals/en/com-stmt-prepare-response.html#packet-COM_STMT_PREPARE_OK
    public struct COM_STMT_PREPARE_OK: MySQLPacketDecodable {
        public enum Error: Swift.Error {
            case missingStatus
            case missingStatementID
            case missingNumColumns
            case missingNumParams
            case missingReserved1
            case missingWarningCount
        }
        /// statement_id (4) -- statement-id
        public var statementID: UInt32
        
        /// num_columns (2) -- number of columns
        public var numColumns: UInt16
        
        /// num_params (2) -- number of params
        public var numParams: UInt16
        
        /// warning_count (2) -- number of warnings
        public var warningCount: UInt16
        
        public static func decode(from packet: inout MySQLPacket, capabilities: CapabilityFlags) throws -> COM_STMT_PREPARE_OK {
            guard let status = packet.payload.readInteger(endianness: .little, as: UInt8.self) else {
                throw Error.missingStatus
            }
            
            assert(status == 0x00, "COM_STMT_PREPARE_OK has invalid status")
            guard let statementID = packet.payload.readInteger(endianness: .little, as: UInt32.self) else {
                throw Error.missingStatementID
            }
            guard let numColumns = packet.payload.readInteger(endianness: .little, as: UInt16.self) else {
                throw Error.missingNumColumns
            }
            guard let numParams = packet.payload.readInteger(endianness: .little, as: UInt16.self) else {
                throw Error.missingNumParams
            }
            
            /// reserved_1 (1) -- [00] filler
            guard let reserved_1 = packet.payload.readInteger(endianness: .little, as: UInt8.self) else {
                throw Error.missingReserved1
            }
            assert(reserved_1 == 0x00)
            
            guard let warningCount = packet.payload.readInteger(endianness: .little, as: UInt16.self) else {
                throw Error.missingWarningCount
            }
            assert(packet.payload.readableBytes == 0, "COM_STMT_PREPARE_OK has unread bytes")
            return .init(statementID: statementID, numColumns: numColumns, numParams: numParams, warningCount: warningCount)
        }
    }
}
