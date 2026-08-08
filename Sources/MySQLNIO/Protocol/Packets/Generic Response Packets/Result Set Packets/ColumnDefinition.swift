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
    let type: MySQLDataType

    @usableFromInline
    let flags: UInt16

    /// Max shown decimal digits:
    /// - `0x00` for integers and static strings
    /// - `0x1f` for dynamic strings, double, float
    /// - `0x00` to `0x51` for decimals
    @usableFromInline
    let decimals: UInt8

    init?(from packet: inout ByteBuffer, capabilities: MySQLCapabilities) {
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
        self.type = MySQLDataType(rawValue: type)
        self.flags = flags
        self.decimals = decimals
    }
}
