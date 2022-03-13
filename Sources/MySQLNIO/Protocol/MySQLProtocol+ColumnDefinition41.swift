import NIOCore

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
        
        /// array of type strings received in extended metadata (usually empty)
        let extendedTypes: [String]
        
        /// array of format strings received in extended metadata (usually empty)
        let extendedFormats: [String]
        
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
        /// note: `decimals` and `column_length` can be used for text-output formatting.
        let decimals: UInt8
        
        init(
            catalog: String = "def",
            schema: String,
            table: String,
            orgTable: String,
            name: String,
            orgName: String,
            extendedTypes: [String] = [],
            extendedFormats: [String] = [],
            characterSet: CharacterSet,
            columnLength: UInt32,
            columnType: DataType,
            flags: ColumnFlags,
            decimals: UInt8
        ) {
            self.catalog = catalog
            self.schema = schema
            self.table = table
            self.orgTable = orgTable
            self.name = name
            self.orgName = orgName
            self.extendedTypes = extendedTypes
            self.extendedFormats = extendedFormats
            self.characterSet = characterSet
            self.columnLength = columnLength
            self.columnType = columnType
            self.flags = flags
            self.decimals = decimals
        }
        
        init(from packet: inout MySQLPacket, capabilities: MySQLProtocol.CapabilityFlags) throws {
            self.catalog = try packet.readLengthEncodedString()
            self.schema = try packet.readLengthEncodedString()
            self.table = try packet.readLengthEncodedString()
            self.orgTable = try packet.readLengthEncodedString()
            self.name = try packet.readLengthEncodedString()
            self.orgName = try packet.readLengthEncodedString()
            
            (self.extendedTypes, self.extendedFormats) = !capabilities.contains(.MARIADB_CLIENT_EXTENDED_METADATA) ? ([], []) :
                try packet.withLengthEncodedSlice { s in
                    var types: [String] = [], formats: [String] = []
                    while let dataType = s.payload.readInteger(endianness: .little, as: UInt8.self) { switch dataType {
                        case 0: types.append(try s.readLengthEncodedString())
                        case 1: formats.append(try s.readLengthEncodedString())
                        default: throw MySQLPacket.Error.packetReadFailure
                    } }
                    return (types, formats)
                }
            
            guard try packet.readLengthEncodedInteger() == 0xc else { throw MySQLPacket.Error.packetReadFailure }
            
            self.characterSet = try packet.readInteger(endianness: .little, as: CharacterSet.self)
            self.columnLength = try packet.readInteger(endianness: .little, as: UInt32.self)
            self.columnType = try packet.readInteger(endianness: .little, as: DataType.self)
            self.flags = try packet.readInteger(endianness: .little, as: ColumnFlags.self)
            self.decimals = try packet.readInteger(endianness: .little, as: UInt8.self)
            try packet.readReservedBytes(length: 2)
        }
        
        /// `MySQLPacketDecodable` conformance.
        static func decode(from packet: inout MySQLPacket, capabilities: MySQLProtocol.CapabilityFlags) throws -> ColumnDefinition41 {
            return .init(from: &packet, capabilities: capabilities)
        }
        
        /// `MySQLPacketEncodable` conformance.
        func encode(to packet: inout MySQLPacket, capabilities: MySQLProtocol.CapabilityFlags) throws {
            packet.payload.writeLengthEncodedString(self.catalog)
            packet.payload.writeLengthEncodedString(self.schema)
            packet.payload.writeLengthEncodedString(self.table)
            packet.payload.writeLengthEncodedString(self.orgTable)
            packet.payload.writeLengthEncodedString(self.name)
            packet.payload.writeLengthEncodedString(self.orgName)
            if capabilities.contains(.MARIADB_CLIENT_EXTENDED_METADATA) {
                var buf = ByteBuffer()
                self.extendedTypes.reduce(into: ()) { buf.writeInteger(0 as UInt8); buf.writeLengthEncodedString($1) }
                self.extendedFormats.reduce(into: ()) { buf.writeInteger(1 as UInt8); buf.writeLengthEncodedString($1) }
                packet.payload.writeImmutableLengthEncodedSlice(buf)
            }
            packet.payload.writeInteger(self.characterSet, endianness: .little, as: CharacterSet.self)
            packet.payload.writeInteger(self.columnLength, endianness: .little, as: UInt32.self)
            packet.payload.writeInteger(self.columnType, endianness: .little, as: DataType.self)
            packet.payload.writeInteger(self.flags, endianness: .little, as: ColumnFlags.self)
            packet.payload.writeInteger(self.decimals, endianness: .little, as: UInt8.self)
            packet.payload.writeRepeatingByte(0, count: 2)
        }
    }

}
