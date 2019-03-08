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

private final class MySQLSimpleQueryCommand: MySQLCommandHandler {
    let sql: String
    
    enum State {
        case ready
        case columns(count: UInt64)
        case rows
        case done
    }
    var state: State
    
    var columns: [MySQLProtocol.ColumnDefinition41]
    let onRow: (MySQLRow) -> ()
    
    init(sql: String, onRow: @escaping (MySQLRow) -> ()) {
        self.state = .ready
        self.sql = sql
        self.columns = []
        self.onRow = onRow
    }
    
    func handle(packet: inout MySQLPacket, capabilities: MySQLProtocol.CapabilityFlags) throws -> MySQLCommandState {
        switch self.state {
        case .ready:
            if packet.isOK {
                self.state = .done
                return .done
            } else {
                let res = try packet.decode(MySQLProtocol.COM_QUERY_Response.self, capabilities: capabilities)
                self.state = .columns(count: res.columnCount)
                return .noResponse
            }
        case .columns(let total):
            let column = try packet.decode(MySQLProtocol.ColumnDefinition41.self, capabilities: capabilities)
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
                var values: [MySQLProtocol.ResultSetRow] = []
                for _ in 0..<self.columns.count {
                    let value = try packet.decode(MySQLProtocol.ResultSetRow.self, capabilities: capabilities)
                    values.append(value)
                }
                let row = MySQLRow(format: .text, columns: self.columns, values: values)
                self.onRow(row)
                return .noResponse
            }
        case .done: fatalError()
        }
    }
    
    func activate(capabilities: MySQLProtocol.CapabilityFlags) throws -> MySQLCommandState {
        return try .response([
            .encode(MySQLProtocol.COM_QUERY(query: self.sql), capabilities: capabilities)
        ])
    }
}
