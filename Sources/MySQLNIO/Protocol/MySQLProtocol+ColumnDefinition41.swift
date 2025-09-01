extension MySQLProtocol {
    /// `Protocol::ColumnDefinition41`
    ///
    /// https://dev.mysql.com/doc/internals/en/com-query-response.html#packet-Protocol::ColumnDefinition
    public struct ColumnDefinition41: MySQLPacketDecodable, Sendable {
        /// `catalog` (`lenenc_str`) -- catalog (always "def")
        public var catalog: String
        
        /// `schema` (`lenenc_str`) -- schema-name
        public var schema: String
        
        /// `table` (`lenenc_str`) -- virtual table-name
        public var table: String
        
        /// `org_table` (`lenenc_str`) -- physical table-name
        public var orgTable: String
        
        /// `name` (`lenenc_str`) -- virtual column name
        public var name: String
        
        /// `org_name` (`lenenc_str`) -- physical column name
        public var orgName: String
        
        /// `character_set` (2) -- the column character set, defined in `Protocol::CharacterSet`.
        public var characterSet: CharacterSet
        
        /// `column_length` (4) -- maximum length of the field
        public var columnLength: UInt32
        
        /// `column_type` (1) -- type of the column as defined in Column Type
        public var columnType: DataType
        
        /// `flags` (2) -- flags
        public var flags: ColumnFlags
        
        /// `decimals` (1) -- max shown decimal digits
        /// - `0x00` for integers and static strings
        /// - `0x1f` for dynamic strings, double, float
        /// - `0x00` to `0x51` for decimals
        /// note: decimals and column_length can be used for text-output formatting.
        public var decimals: UInt8
        
        /// See ``MySQLPacketDecodable/decode(from:capabilities:)``.
        public static func decode(from packet: inout MySQLPacket, capabilities: MySQLProtocol.CapabilityFlags) throws -> ColumnDefinition41 {
            guard let catalog = packet.payload.readLengthEncodedString(),
                  let schema = packet.payload.readLengthEncodedString(),
                  let table = packet.payload.readLengthEncodedString(),
                  let orgTable = packet.payload.readLengthEncodedString(),
                  let name = packet.payload.readLengthEncodedString(),
                  let orgName = packet.payload.readLengthEncodedString(),
                  /// `next_length` (`lenenc_int`) -- length of the following fields (always `0x0c`)
                  let fixedLength = packet.payload.readLengthEncodedInteger(), fixedLength == 0x0c,
                  // TODO: check if character set > 255
                  let characterSet = packet.payload.readInteger(endianness: .little, as: CharacterSet.self),
                  let collate = packet.payload.readInteger(endianness: .little, as: UInt8.self), collate == 0,
                  let columnLength = packet.payload.readInteger(endianness: .little, as: UInt32.self),
                  let columnType = packet.payload.readInteger(endianness: .little, as: DataType.self),
                  let flags = packet.payload.readInteger(endianness: .little, as: ColumnFlags.self),
                  let decimals = packet.payload.readInteger(endianness: .little, as: UInt8.self),
                  let filler = packet.payload.readInteger(as: UInt16.self), filler == 0x0000,
                  packet.payload.readableBytes == 0
            else {
                throw MySQLError.protocolError
            }
            /// FIXME: check if command was `COM_FIELD_LIST` for default values
            
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
