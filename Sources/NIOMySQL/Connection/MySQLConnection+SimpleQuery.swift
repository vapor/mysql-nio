extension MySQLConnection {
    public func simpleQuery(_ sql: String) -> EventLoopFuture<[MySQLRow]> {
        var rows = [MySQLRow]()
        return self.simpleQuery(sql) { row in
            rows.append(row)
        }.map { rows }
    }
    
    public func simpleQuery(_ sql: String, onRow: @escaping (MySQLRow) -> ()) -> EventLoopFuture<Void> {
        let query = MySQLSimpleQueryCommand(sql: sql, onRow: onRow)
        return self.send(query)
    }
}

public struct MySQLRow: CustomStringConvertible {
    let columns: [MySQLPacket.ColumnDefinition]
    let values: [MySQLPacket.ResultSetRow]
    
    public var description: String {
        var desc = [String: String]()
        for (column, value) in zip(columns, values) {
            desc[column.name] = value.value?.readableString ?? "null"
        }
        return desc.description
    }
    
    init(columns: [MySQLPacket.ColumnDefinition], values: [MySQLPacket.ResultSetRow]) {
        self.columns = columns
        self.values = values
    }
}



private final class MySQLSimpleQueryCommand: MySQLCommandHandler {
    let sql: String
    
    enum State {
        case ready
        case columns(count: UInt64)
        case rows
        case done
    }
    var state: State
    
    var columns: [MySQLPacket.ColumnDefinition]
    let onRow: (MySQLRow) -> ()
    
    init(sql: String, onRow: @escaping (MySQLRow) -> ()) {
        self.state = .ready
        self.sql = sql
        self.columns = []
        self.onRow = onRow
    }
    
    func handle(packet: inout MySQLPacket) throws -> MySQLCommandState {
        switch self.state {
        case .ready:
            if packet.isOK {
                self.state = .done
                return .done
            } else {
                let res = try packet.comQueryResponse()
                self.state = .columns(count: res.columnCount)
                return .noResponse
            }
        case .columns(let total):
            let column = try packet.columnDefinition()
            self.columns.append(column)
            if self.columns.count == numericCast(total) {
                self.state = .rows
            }
            return .noResponse
        case .rows:
            if packet.isOK {
                self.state = .done
                return .done
            } else {
                var values: [MySQLPacket.ResultSetRow] = []
                for _ in 0..<self.columns.count {
                    let value = try packet.resultSetRow()
                    values.append(value)
                }
                let row = MySQLRow(columns: self.columns, values: values)
                self.onRow(row)
                return .noResponse
            }
        case .done: fatalError()
        }
    }
    
    func activate() throws -> MySQLCommandState {
        return .response([
            .init(comQuery: .init(query: self.sql))
        ])
    }
}
