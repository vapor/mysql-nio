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
        case columns(count: UInt16)
        case columnsDone
        case beforeRows(remaining: Int)
        case rows
        case done
    }
    var state: State
    let binds: [MySQLData]
    let onRow: (MySQLRow) -> ()
    private var columns: [MySQLProtocol.ColumnDefinition41]
    
    init(sql: String, binds: [MySQLData], onRow: @escaping (MySQLRow) -> ()) {
        self.state = .ready
        self.sql = sql
        self.binds = binds
        self.columns = []
        self.onRow = onRow
    }
    
    func handle(packet: inout MySQLPacket, capabilities: MySQLProtocol.CapabilityFlags) throws -> MySQLCommandState {
        print(packet.payload.debugDescription)
        switch self.state {
        case .ready:
            guard !packet.isError else {
                self.state = .done
                let error = try packet.decode(MySQLProtocol.ERR_Packet.self, capabilities: capabilities)
                throw MySQLError.server(error)
            }

            let res = try packet.decode(MySQLProtocol.COM_STMT_PREPARE_OK.self, capabilities: capabilities)
            print(res)
            self.state = .columns(count: res.numColumns)
            let execute = MySQLProtocol.COM_STMT_EXECUTE(
                statementID: res.statementID,
                flags: [],
                values: self.binds
            )
            return try .reset([.encode(execute, capabilities: capabilities)])
        case .columns(let total):
            let column = try packet.decode(MySQLProtocol.ColumnDefinition41.self, capabilities: capabilities)
            print(column)
            self.columns.append(column)
            if self.columns.count == numericCast(total) {
                self.state = .columnsDone
            }
            return .noResponse
        case .columnsDone:
            guard let columnCount = packet.payload.readLengthEncodedInteger() else {
                fatalError()
            }
            print("column count: \(columnCount)")
            assert(packet.payload.readableBytes == 0, "unread data")
            assert(self.columns.count == numericCast(columnCount), "column count mis-match")
            self.state = .beforeRows(remaining: numericCast(columnCount))
            return .noResponse
        case .beforeRows(var remaining):
            remaining -= 1
            if remaining == 0 {
                self.state = .rows
            } else {
                self.state = .beforeRows(remaining: remaining)
            }
            let column = try packet.decode(MySQLProtocol.ColumnDefinition41.self, capabilities: capabilities)
            print("consuming column: \(column)")
            return .noResponse
        case .rows:
            guard !packet.isError else {
                self.state = .done
                let error = try packet.decode(MySQLProtocol.ERR_Packet.self, capabilities: capabilities)
                throw MySQLError.server(error)
            }
            guard !packet.isEOF else {
                self.state = .done
                return .done
            }
            guard let header = packet.payload.readInteger(endianness: .little, as: UInt8.self) else {
                fatalError()
            }
            assert(header == 0x00)
            guard let nullBitmap = MySQLProtocol.NullBitmap.readResultSetNullBitmap(
                count: self.columns.count, from: &packet.payload
            ) else {
                fatalError()
            }
            print(nullBitmap)
            var values: [MySQLProtocol.ResultSetRow] = []
            for _ in 0..<self.columns.count {
                let value = try packet.decode(MySQLProtocol.ResultSetRow.self, capabilities: capabilities)
                values.append(value)
            }
            let row = MySQLRow(format: .binary, columns: self.columns, values: values)
            self.onRow(row)
            return .noResponse
        case .done: fatalError()
        }
    }
    
    func activate(capabilities: MySQLProtocol.CapabilityFlags) throws -> MySQLCommandState {
        let prepare = MySQLProtocol.COM_STMT_PREPARE(query: self.sql)
        return try .response([.encode(prepare, capabilities: capabilities)])
    }
}
