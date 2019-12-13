public struct MySQLRow: CustomStringConvertible {
    public let format: MySQLData.Format
    public let columnDefinitions: [MySQLProtocol.ColumnDefinition41]
    public let values: [ByteBuffer?]
    
    public var description: String {
        var desc = [String: MySQLData]()
        for (column, value) in zip(self.columnDefinitions, self.values) {
            desc[column.name] = .init(
                type: column.columnType,
                format: self.format,
                buffer: value,
                isUnsigned: column.flags.contains(.COLUMN_UNSIGNED)
            )
        }
        return desc.description
    }
    
    public init(
        format: MySQLData.Format,
        columnDefinitions: [MySQLProtocol.ColumnDefinition41],
        values: [ByteBuffer?]
    ) {
        self.format = format
        self.columnDefinitions = columnDefinitions
        self.values = values
    }
    
    public func column(_ name: String, table: String? = nil) -> MySQLData? {
        for (column, value) in zip(self.columnDefinitions, self.values) {
            if column.name == name && (table == nil || column.table == table) {
                return .init(
                    type: column.columnType,
                    format: self.format,
                    buffer: value,
                    isUnsigned: column.flags.contains(.COLUMN_UNSIGNED)
                )
            }
        }
        return nil
    }
}
