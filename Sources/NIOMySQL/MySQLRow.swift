public struct MySQLRow: CustomStringConvertible {
    private let columns: [MySQLProtocol.ColumnDefinition41]
    private let values: [MySQLProtocol.ResultSetRow]
    
    public var description: String {
        var desc = [String: String]()
        for (column, value) in zip(columns, values) {
            print(column)
            desc[column.name] = value.value?.readableString ?? "null"
        }
        return desc.description
    }
    
    init(columns: [MySQLProtocol.ColumnDefinition41], values: [MySQLProtocol.ResultSetRow]) {
        self.columns = columns
        self.values = values
    }
    
    public func column(_ name: String, table: String? = nil) -> MySQLData? {
        for (column, value) in zip(self.columns, self.values) {
            if column.name == name && (table == nil || column.table == table) {
                return .init(type: column.columnType, buffer: value.value)
            }
        }
        return nil
    }
}
