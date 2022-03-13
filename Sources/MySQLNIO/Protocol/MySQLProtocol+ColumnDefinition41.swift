extension MySQLProtocol {
    /// `Protocol::ColumnDefinition41`
    ///
    /// Column Definition
    /// if `CLIENT_PROTOCOL_41` is set `Protocol::ColumnDefinition41` is used, `Protocol::ColumnDefinition320` otherwise
    ///
    /// https://dev.mysql.com/doc/internals/en/com-query-response.html#packet-Protocol::ColumnDefinition
    struct ColumnDefinition41: MySQLPacketCodable {
        /// `catalog (lenenc_str)` -- catalog (always "def")
        let catalog: String
        
        /// `schema (lenenc_str)` -- schema name
        let schema: String
        
        /// `table (lenenc_str)` -- virtual table-name
        let table: String
        
        /// `org_table (lenenc_str)` -- physical table name
        let orgTable: String
        
        /// `name (lenenc_str)` -- virtual column name
        let name: String
        
        /// `org_name (lenenc_str)` -- physical column name
        let orgName: String
        
        
        
        /// `character_set (2)` -- the column character set, defined in `Protocol::CharacterSet`.
        let characterSet: CharacterSet
        
        /// `column_length (4)` -- maximum length of the field
        let columnLength: UInt32
        
        /// `column_type (1)` -- type of the column as defined in Column Type
        let columnType: DataType
        
        /// `flags (2)` -- flags
        let flags: ColumnFlags
        
        /// `decimals (1)` -- max shown decimal digits
        /// - `0x00` for integers and static strings
        /// - `0x1f` for dynamic strings, double, float
        /// - `0x00` to `0x51` for decimals
        /// note: decimals and `column_length` can be used for text-output formatting.
        let decimals: UInt8
        
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
            // TODO: check if character set > 255
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
