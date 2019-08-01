extension MySQLProtocol {
    /// Protocol::ColumnDefinition41
    ///
    /// Column Definition
    /// if CLIENT_PROTOCOL_41 is set Protocol::ColumnDefinition41 is used, Protocol::ColumnDefinition320 otherwise
    ///
    /// https://dev.mysql.com/doc/internals/en/com-query-response.html#packet-Protocol::ColumnDefinition
    public struct ColumnDefinition41: MySQLPacketDecodable {
        /// catalog (lenenc_str) -- catalog (always "def")
        public var catalog: String
        
        /// schema (lenenc_str) -- schema-name
        public var schema: String
        
        /// table (lenenc_str) -- virtual table-name
        public var table: String
        
        /// org_table (lenenc_str) -- physical table-name
        public var orgTable: String
        
        /// name (lenenc_str) -- virtual column name
        public var name: String
        
        /// org_name (lenenc_str) -- physical column name
        public var orgName: String
        
        /// character_set (2) -- is the column character set and is defined in Protocol::CharacterSet.
        public var characterSet: CharacterSet
        
        /// column_length (4) -- maximum length of the field
        public var columnLength: UInt32
        
        /// column_type (1) -- type of the column as defined in Column Type
        public var columnType: DataType
        
        /// flags (2) -- flags
        public var flags: ColumnFlags
        
        /// decimals (1) -- max shown decimal digits
        /// - 0x00 for integers and static strings
        /// - 0x1f for dynamic strings, double, float
        /// - 0x00 to 0x51 for decimals
        /// note: decimals and column_length can be used for text-output formatting.
        public var decimals: UInt8
        
        /// `MySQLPacketDecodable` conformance.
        public static func decode(from packet: inout MySQLPacket, capabilities: MySQLProtocol.CapabilityFlags) throws -> ColumnDefinition41 {
            guard let catalog = packet.payload.readLengthEncodedString() else {
                fatalError()
            }
            guard let schema = packet.payload.readLengthEncodedString() else {
                fatalError()
            }
            guard let table = packet.payload.readLengthEncodedString() else {
                fatalError()
            }
            guard let orgTable = packet.payload.readLengthEncodedString() else {
                fatalError()
            }
            guard let name = packet.payload.readLengthEncodedString() else {
                fatalError()
            }
            guard let orgName = packet.payload.readLengthEncodedString() else {
                fatalError()
            }
            /// next_length (lenenc_int) -- length of the following fields (always 0x0c)
            guard let fixedLength = packet.payload.readLengthEncodedInteger() else {
                fatalError()
            }
            assert(fixedLength == 0x0C, "invalid fixed length: \(fixedLength)")
            #warning("TODO: check if character set > 255")
            guard let characterSet = packet.payload.readInteger(endianness: .little, as: CharacterSet.self) else {
                fatalError()
            }
            guard let collate = packet.payload.readInteger(endianness: .little, as: UInt8.self) else {
                fatalError()
            }
            assert(collate == 0)
            
            guard let columnLength = packet.payload.readInteger(endianness: .little, as: UInt32.self) else {
                fatalError()
            }
            guard let columnType = packet.payload.readInteger(endianness: .little, as: DataType.self) else {
                fatalError()
            }
            guard let flags = packet.payload.readInteger(endianness: .little, as: ColumnFlags.self) else {
                fatalError()
            }
            guard let decimals = packet.payload.readInteger(endianness: .little, as: UInt8.self) else {
                fatalError()
            }
            /// 2              filler [00] [00]
            guard let filler = packet.payload.readBytes(length: 2) else {
                fatalError()
            }
            assert(filler == [0, 0])
            assert(packet.payload.readableBytes == 0)
            
            /// FIXME: check if `if command was COM_FIELD_LIST {` for default values
            
            return .init(
                catalog: catalog,
                schema: schema,
                table: table,
                orgTable: orgTable,
                name: name,
                orgName: orgName,
                characterSet: characterSet,
                columnLength: columnLength,
                columnType: columnType,
                flags: flags,
                decimals: decimals
            )
        }
    }
}
