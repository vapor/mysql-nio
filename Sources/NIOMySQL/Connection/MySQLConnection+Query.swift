extension MySQLConnection {
    public func query(_ sql: String, _ binds: [MySQLData] = []) -> EventLoopFuture<[MySQLRow]> {
        var rows = [MySQLRow]()
        return self.query(sql, binds) { row in
            rows.append(row)
        }.map { rows }
    }
    
    public func query(_ sql: String, _ binds: [MySQLData] = [], onRow: @escaping (MySQLRow) -> ()) -> EventLoopFuture<Void> {
        let query = MySQLQueryCommand(sql: sql, binds: binds, onRow: onRow)
        return self.send(query)
    }
}

private final class MySQLQueryCommand: MySQLCommandHandler {
    let sql: String
    
    enum State {
        case ready
        case params
        case columns
        case executeColumnCount
        case executeColumns(remaining: Int)
        case rows
        case done
    }
    
    var state: State
    let binds: [MySQLData]
    let onRow: (MySQLRow) -> ()
    private var columns: [MySQLProtocol.ColumnDefinition41]
    private var params: [MySQLProtocol.ColumnDefinition41]
    private var ok: MySQLProtocol.COM_STMT_PREPARE_OK?
    
    init(sql: String, binds: [MySQLData], onRow: @escaping (MySQLRow) -> ()) {
        self.state = .ready
        self.sql = sql
        self.binds = binds
        self.columns = []
        self.params = []
        self.onRow = onRow
    }
    
    func handle(packet: inout MySQLPacket, capabilities: MySQLProtocol.CapabilityFlags) throws -> MySQLCommandState {
        print("")
        print("\(self.state) \(packet.payload.debugDescription)")
        guard !packet.isError else {
            self.state = .done
            let error = try packet.decode(MySQLProtocol.ERR_Packet.self, capabilities: capabilities)
            throw MySQLError.server(error)
        }
        switch self.state {
        case .ready:
            let res = try packet.decode(MySQLProtocol.COM_STMT_PREPARE_OK.self, capabilities: capabilities)
            self.ok = res
            if res.numParams != 0 {
                self.state = .params
            } else if res.numColumns != 0 {
                self.state = .columns
            } else {
                self.state = .executeColumnCount
            }
            let execute = MySQLProtocol.COM_STMT_EXECUTE(
                statementID: res.statementID,
                flags: [],
                values: self.binds
            )
            return try .reset([.encode(execute, capabilities: capabilities)])
        case .params:
            let param = try packet.decode(MySQLProtocol.ColumnDefinition41.self, capabilities: capabilities)
            self.params.append(param)
            if self.params.count == numericCast(self.ok!.numParams) {
                if self.ok!.numColumns != 0 {
                    self.state = .columns
                } else {
                    self.state = .executeColumnCount
                }
            }
            return .noResponse
        case .columns:
            let column = try packet.decode(MySQLProtocol.ColumnDefinition41.self, capabilities: capabilities)
            self.columns.append(column)
            if self.columns.count == numericCast(self.ok!.numColumns) {
                self.state = .executeColumnCount
            }
            return .noResponse
        case .executeColumnCount:
            guard let count = packet.payload.readLengthEncodedInteger() else {
                fatalError()
            }
            self.state = .executeColumns(remaining: numericCast(count))
            return .noResponse
        case .executeColumns(var remaining):
            remaining -= 1
            switch remaining {
            case 0:
                self.state = .rows
            default:
                self.state = .executeColumns(remaining: remaining)
            }
            return .noResponse
        case .rows:
            guard !packet.isEOF else {
                self.state = .done
                return .done
            }

            let data = try MySQLProtocol.BinaryResultSetRow.decode(from: &packet, columns: columns)
            let row = MySQLRow(format: .binary, columns: self.columns, values: data.values)
            self.onRow(row)
            var packet = MySQLPacket()
            MySQLProtocol.COM_STMT_CLOSE(statementID: self.ok!.statementID).encode(into: &packet)
            return .reset([packet])
        case .done: fatalError()
        }
    }
    
    func activate(capabilities: MySQLProtocol.CapabilityFlags) throws -> MySQLCommandState {
        let prepare = MySQLProtocol.COM_STMT_PREPARE(query: self.sql)
        return try .response([.encode(prepare, capabilities: capabilities)])
    }
}
