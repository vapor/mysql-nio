extension MySQLPacket {
    public mutating func columnDefinition() throws -> ColumnDefinition {
        return try .init(payload: &self.payload)
    }
    
    /// Protocol::ColumnDefinition41
    ///
    /// Column Definition
    /// if CLIENT_PROTOCOL_41 is set Protocol::ColumnDefinition41 is used, Protocol::ColumnDefinition320 otherwise
    ///
    /// https://dev.mysql.com/doc/internals/en/com-query-response.html#packet-Protocol::ColumnDefinition
    public struct ColumnDefinition {
        /// These don't seem to be documented anywhere.
        public struct ColumnFlags: OptionSet {
            /// This column is unsigned.
            public static let COLUMN_UNSIGNED = ColumnFlags(rawValue: 0b000_0000_0010_0000)
            
            /// This column is the primary key.
            public static let PRIMARY_KEY = ColumnFlags(rawValue: 0b000_0000_0000_0010)
            
            /// This column is not null.
            public static let COLUMN_NOT_NULL = ColumnFlags(rawValue: 0b000_0000_0000_0001)
            
            /// The raw status value.
            public var rawValue: UInt16
            
            /// Create a new `MySQLStatusFlags` from the raw value.
            public init(rawValue: UInt16) {
                self.rawValue = rawValue
            }
        }
        
        /// catalog (lenenc_str) -- catalog (always "def")
        var catalog: String
        
        /// schema (lenenc_str) -- schema-name
        var schema: String
        
        /// table (lenenc_str) -- virtual table-name
        var table: String
        
        /// org_table (lenenc_str) -- physical table-name
        var orgTable: String
        
        /// name (lenenc_str) -- virtual column name
        var name: String
        
        /// org_name (lenenc_str) -- physical column name
        var orgName: String
        
        /// character_set (2) -- is the column character set and is defined in Protocol::CharacterSet.
        var characterSet: MySQLCharacterSet
        
        /// column_length (4) -- maximum length of the field
        var columnLength: UInt32
        
        /// column_type (1) -- type of the column as defined in Column Type
        var columnType: MySQLBinaryDataType
        
        /// flags (2) -- flags
        var flags: ColumnFlags
        
        /// decimals (1) -- max shown decimal digits
        /// - 0x00 for integers and static strings
        /// - 0x1f for dynamic strings, double, float
        /// - 0x00 to 0x51 for decimals
        /// note: decimals and column_length can be used for text-output formatting.
        var decimals: UInt8
        
        /// Parses a `MySQLColumnDefinition41` from the `ByteBuffer`.
        init(payload: inout ByteBuffer) throws {
            guard let catalog = payload.readLengthEncodedString() else {
                fatalError()
            }
            self.catalog = catalog
            guard let schema = payload.readLengthEncodedString() else {
                fatalError()
            }
            self.schema = schema
            guard let table = payload.readLengthEncodedString() else {
                fatalError()
            }
            self.table = table
            guard let orgTable = payload.readLengthEncodedString() else {
                fatalError()
            }
            self.orgTable = orgTable
            guard let name = payload.readLengthEncodedString() else {
                fatalError()
            }
            self.name = name
            guard let orgName = payload.readLengthEncodedString() else {
                fatalError()
            }
            self.orgName = orgName
            /// next_length (lenenc_int) -- length of the following fields (always 0x0c)
            guard let fixedLength = payload.readLengthEncodedInteger() else {
                fatalError()
            }
            assert(fixedLength == 0x0C, "invalid fixed length: \(fixedLength)")
            guard let characterSetRaw = payload.readInteger(endianness: .little, as: UInt16.self) else {
                fatalError()
            }
            self.characterSet = .init(rawValue: characterSetRaw)
            guard let columnLength = payload.readInteger(endianness: .little, as: UInt32.self) else {
                fatalError()
            }
            self.columnLength = columnLength
            guard let columnTypeRaw = payload.readInteger(endianness: .little, as: UInt8.self) else {
                fatalError()
            }
            self.columnType = .init(rawValue: columnTypeRaw)
            guard let flagsRaw = payload.readInteger(endianness: .little, as: UInt16.self) else {
                fatalError()
            }
            self.flags = .init(rawValue: flagsRaw)
            guard let decimals = try payload.readInteger(endianness: .little, as: UInt8.self) else {
                fatalError()
            }
            self.decimals = decimals
            
            /// 2              filler [00] [00]
            assert(payload.readBytes(length: 2) == [0, 0])
            assert(payload.readableBytes == 0)
            
            /// FIXME: check if `if command was COM_FIELD_LIST {` for default values
        }
    }
}
