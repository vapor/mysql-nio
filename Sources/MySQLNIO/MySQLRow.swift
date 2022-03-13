import NIOCore

public struct MySQLRow: CustomStringConvertible {
    let format: MySQLData.Format
    let columnDefinitions: [MySQLProtocol.ColumnDefinition41]
    let values: [ByteBuffer?]
    
    public var description: String {
        var desc = [String: MySQLData]()
        for (column, value) in zip(self.columnDefinitions, self.values) {
            desc[column.name] = .init(
                type: column.columnType,
                format: self.format,
                buffer: value,
                isUnsigned: column.flags.contains(.UNSIGNED)
            )
        }
        return desc.description
    }
    
    init(
        format: MySQLData.Format,
        columnDefinitions: [MySQLProtocol.ColumnDefinition41],
        values: [ByteBuffer?]
    ) {
        self.format = format
        self.columnDefinitions = columnDefinitions
        self.values = values
    }
    
    func column(_ name: String, table: String? = nil) -> MySQLData? {
        for (column, value) in zip(self.columnDefinitions, self.values) {
            if column.name == name && (table == nil || column.table == table) {
                return .init(
                    type: column.columnType,
                    format: self.format,
                    buffer: value,
                    isUnsigned: column.flags.contains(.UNSIGNED)
                )
            }
        }
        return nil
    }
}
