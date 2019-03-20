public struct MySQLQueryMetadata {
    /// int<lenenc>    affected_rows    affected rows
    public let affectedRows: UInt64
    
    /// int<lenenc>    last_insert_id    last insert-id
    public let lastInsertID: UInt64?
}

extension MySQLDatabase {
    public func query(
        _ sql: String,
        _ binds: [MySQLData] = [],
        onMetadata: @escaping (MySQLQueryMetadata) -> () = { _ in }
    ) -> EventLoopFuture<[MySQLRow]> {
        var rows = [MySQLRow]()
        return self.query(sql, binds, onRow: { row in
            rows.append(row)
        }, onMetadata: onMetadata).map { rows }
    }
    
    public func query(
        _ sql: String,
        _ binds: [MySQLData] = [],
        onRow: @escaping (MySQLRow) -> (),
        onMetadata: @escaping (MySQLQueryMetadata) -> () = { _ in }
    ) -> EventLoopFuture<Void> {
        print("[NIOMySQL] \(sql)")
        let query = MySQLQueryCommand(sql: sql, binds: binds, onRow: onRow, onMetadata: onMetadata)
        return self.send(query)
    }
}

private final class MySQLQueryCommand: MySQLCommand {
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
    let onMetadata: (MySQLQueryMetadata) -> ()
    private var columns: [MySQLProtocol.ColumnDefinition41]
    private var params: [MySQLProtocol.ColumnDefinition41]
    private var ok: MySQLProtocol.COM_STMT_PREPARE_OK?
    
    init(sql: String, binds: [MySQLData], onRow: @escaping (MySQLRow) -> (), onMetadata: @escaping (MySQLQueryMetadata) -> ()) {
        self.state = .ready
        self.sql = sql
        self.binds = binds
        self.columns = []
        self.params = []
        self.onRow = onRow
        self.onMetadata = onMetadata
    }
    
    func handle(packet: inout MySQLPacket, capabilities: MySQLProtocol.CapabilityFlags) throws -> MySQLCommandState {
        // print("QUERY \(state): \(packet.payload.debugDescription)")
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
            return try .init(response: [.encode(execute, capabilities: capabilities)], resetSequence: true)
        case .params:
            let param = try packet.decode(MySQLProtocol.ColumnDefinition41.self, capabilities: capabilities)
            self.params.append(param)
            if self.params.count == numericCast(self.ok!.numParams) {
                if self.ok!.numColumns != 0 {
                    self.state = .columns
                } else {
                    self.state = .rows
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
            guard !packet.isOK else {
                self.state = .done
                return .done
            }
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
            if packet.isEOF || packet.isOK && columns.count == 0 {
                if packet.isOK {
                    let ok = try MySQLProtocol.OK_Packet.decode(from: &packet, capabilities: capabilities)
                    self.onMetadata(.init(affectedRows: ok.affectedRows, lastInsertID: ok.lastInsertID))
                }
                var packet = MySQLPacket()
                MySQLProtocol.COM_STMT_CLOSE(statementID: self.ok!.statementID).encode(into: &packet)
                return .init(response: [packet], done: true, resetSequence: true)
            }

            let data = try MySQLProtocol.BinaryResultSetRow.decode(from: &packet, columns: columns)
            let row = MySQLRow(format: .binary, columns: self.columns, values: data.values)
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
