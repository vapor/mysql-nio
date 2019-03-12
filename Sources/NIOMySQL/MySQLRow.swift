public struct MySQLRow: CustomStringConvertible {
    private let columns: [MySQLProtocol.ColumnDefinition41]
    private let values: [ByteBuffer?]
    private let format: MySQLData.Format
    
    public var description: String {
        var desc = [String: MySQLData]()
        for (column, value) in zip(self.columns, self.values) {
            desc[column.name] = .init(
                type: column.columnType,
                format: self.format,
                buffer: value,
                isUnsigned: column.flags.contains(.COLUMN_UNSIGNED)
            )
        }
        return desc.description
    }
    
    init(
        format: MySQLData.Format,
        columns: [MySQLProtocol.ColumnDefinition41],
        values: [ByteBuffer?]
    ) {
        self.format = format
        self.columns = columns
        self.values = values
    }
    
    public func column(_ name: String, table: String? = nil) -> MySQLData? {
        for (column, value) in zip(self.columns, self.values) {
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
