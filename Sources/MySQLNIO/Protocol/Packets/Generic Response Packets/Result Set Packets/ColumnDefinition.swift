import NIOCore

@usableFromInline
struct ColumnDefinition: Hashable, Sendable {
    /// Schema name
    @usableFromInline
    let schema: String

    /// Virtual table name
    @usableFromInline
    let table: String

    /// Physical table name
    @usableFromInline
    let orgTable: String

    /// Virtual column name
    @usableFromInline
    let name: String

    /// Physical column name
    @usableFromInline
    let orgName: String

    /// See `MARIADB_CLIENT_EXTENDED_METADATA`
    @usableFromInline
    let extendedMetadata: String?

    /// The column character set
    @usableFromInline
    let characterSet: MySQLCollation

    /// Maximum length of the field
    @usableFromInline
    let columnLength: UInt32

    /// Type of the column
    @usableFromInline
    let dataType: MySQLDataType

    @usableFromInline
    let flags: UInt16

    /// Max shown decimal digits:
    /// - `0x00` for integers and static strings
    /// - `0x1f` for dynamic strings, double, float
    /// - `0x00` to `0x51` for decimals
    @usableFromInline
    let decimals: UInt8

    /// The format in which the column values are encoded (either text or binary).
    ///
    /// > Note: This is not part of the packet in the MySQL protocol,
    /// > we set it when we parse the packet to then know how to decode the column values.
    @usableFromInline
    let format: MySQLFormat

    init?(from packet: inout ByteBuffer, capabilities: MySQLCapabilities, format: MySQLFormat) {
        guard
            let catalog = packet.readLengthPrefixedString(strategy: .mySQL), catalog == "def",
            let schema = packet.readLengthPrefixedString(strategy: .mySQL),
            let table = packet.readLengthPrefixedString(strategy: .mySQL),
            let orgTable = packet.readLengthPrefixedString(strategy: .mySQL),
            let name = packet.readLengthPrefixedString(strategy: .mySQL),
            let orgName = packet.readLengthPrefixedString(strategy: .mySQL)
        else {
            return nil
        }
        if capabilities.contains(.mariaDBClientExtendedMetadata) {
            guard let extendedMetadata = packet.readLengthPrefixedString(strategy: .mySQL) else { return nil }
            self.extendedMetadata = extendedMetadata
        } else {
            self.extendedMetadata = nil
        }
        guard
            let fixedFieldsLength = packet.readEncodedInteger(as: UInt8.self, strategy: .mySQL), fixedFieldsLength == 0x0C,
            let characterSetRaw = packet.readInteger(endianness: .little, as: UInt16.self),
            let columnLength = packet.readInteger(endianness: .little, as: UInt32.self),
            let type = packet.readInteger(as: UInt8.self),
            let flags = packet.readInteger(endianness: .little, as: UInt16.self),
            let decimals = packet.readInteger(as: UInt8.self)
        else {
            return nil
        }
        packet.moveReaderIndex(forwardBy: 2)  // - unused -
        self.schema = schema
        self.table = table
        self.orgTable = orgTable
        self.name = name
        self.orgName = orgName
        self.characterSet = .lookup(byId: characterSetRaw)
        self.columnLength = columnLength
        self.dataType = MySQLDataType(rawValue: type)
        self.flags = flags
        self.decimals = decimals

        self.format = format
    }

    package init(
        schema: String,
        table: String,
        orgTable: String,
        name: String,
        orgName: String,
        extendedMetadata: String?,
        characterSet: MySQLCollation,
        columnLength: UInt32,
        dataType: MySQLDataType,
        flags: UInt16,
        decimals: UInt8,
        format: MySQLFormat
    ) {
        self.schema = schema
        self.table = table
        self.orgTable = orgTable
        self.name = name
        self.orgName = orgName
        self.extendedMetadata = extendedMetadata
        self.characterSet = characterSet
        self.columnLength = columnLength
        self.dataType = dataType
        self.flags = flags
        self.decimals = decimals
        self.format = format
    }

    package func write(to packet: inout ByteBuffer, capabilities: MySQLCapabilities) {
        packet.writeLengthPrefixedString("def", strategy: .mySQL)
        packet.writeLengthPrefixedString(self.schema, strategy: .mySQL)
        packet.writeLengthPrefixedString(self.table, strategy: .mySQL)
        packet.writeLengthPrefixedString(self.orgTable, strategy: .mySQL)
        packet.writeLengthPrefixedString(self.name, strategy: .mySQL)
        packet.writeLengthPrefixedString(self.orgName, strategy: .mySQL)
        if capabilities.contains(.mariaDBClientExtendedMetadata), let extendedMetadata = self.extendedMetadata {
            packet.writeLengthPrefixedString(extendedMetadata, strategy: .mySQL)
        }
        packet.writeEncodedInteger(0x0C, strategy: .mySQL)  // length of the following fixed-length fields
        packet.writeInteger(self.characterSet.id, endianness: .little, as: UInt16.self)
        packet.writeInteger(self.columnLength, endianness: .little, as: UInt32.self)
        packet.writeInteger(self.dataType.rawValue, as: UInt8.self)
        packet.writeInteger(self.flags, endianness: .little, as: UInt16.self)
        packet.writeInteger(self.decimals, as: UInt8.self)
        packet.writeInteger(0x00, as: UInt16.self)  // filler
    }
}
