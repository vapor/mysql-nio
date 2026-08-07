import NIOCore

@usableFromInline
struct ColumnDefinitionPacket {
    let schema: String
    let tableAlias: String
    let tableName: String
    let columnAlias: String
    let columnName: String
    let extendedMetadata: String?
    let characterSet: MySQLCollation
    let maxColumnSize: UInt32
    let type: MySQLDataType
    let flags: UInt16
    let decimals: UInt8

    init?(from packet: inout ByteBuffer, capabilities: MySQLCapabilities) {
        guard
            let catalog = packet.readLengthPrefixedString(strategy: .mySQL), catalog == "def",
            let schema = packet.readLengthPrefixedString(strategy: .mySQL),
            let tableAlias = packet.readLengthPrefixedString(strategy: .mySQL),
            let tableName = packet.readLengthPrefixedString(strategy: .mySQL),
            let columnAlias = packet.readLengthPrefixedString(strategy: .mySQL),
            let columnName = packet.readLengthPrefixedString(strategy: .mySQL)
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
            let maxColumnSize = packet.readInteger(endianness: .little, as: UInt32.self),
            let type = packet.readInteger(as: UInt8.self),
            let flags = packet.readInteger(endianness: .little, as: UInt16.self),
            let decimals = packet.readInteger(as: UInt8.self)
        else {
            return nil
        }
        packet.moveReaderIndex(forwardBy: 2)  // - unused -
        self.schema = schema
        self.tableAlias = tableAlias
        self.tableName = tableName
        self.columnAlias = columnAlias
        self.columnName = columnName
        self.characterSet = .lookup(byId: characterSetRaw)
        self.maxColumnSize = maxColumnSize
        self.type = MySQLDataType(rawValue: type)
        self.flags = flags
        self.decimals = decimals
    }
}
