import NIOCore

extension MySQLDatabase {
    public func simpleQuery(_ sql: String) -> EventLoopFuture<[MySQLRow]> {
        var rows = [MySQLRow]()
        return self.simpleQuery(sql) { row in
            rows.append(row)
        }.map { rows }
    }
    
    public func simpleQuery(_ sql: String, onRow: @escaping (MySQLRow) -> ()) -> EventLoopFuture<Void> {
        self.logger.debug("\(sql)")
        let query = MySQLSimpleQueryCommand(sql: sql, onRow: onRow)
        return self.send(query, logger: self.logger)
    }
}

private final class MySQLSimpleQueryCommand: MySQLCommand {
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
        // print("QUERY \(state): \(packet.payload.debugDescription)")
        guard !packet.isError else {
            self.state = .done
            let errorPacket = try packet.decode(MySQLProtocol.ERR_Packet.self, capabilities: capabilities)
            let error: any Error
            switch errorPacket.errorCode {
            case .DUP_ENTRY:
                error = MySQLError.duplicateEntry(errorPacket.errorMessage)
            case .PARSE_ERROR:
                error = MySQLError.invalidSyntax(errorPacket.errorMessage)
            default:
                error = MySQLError.server(errorPacket)
            }
            throw error
        }
        switch self.state {
        case .ready:
            if packet.isOK {
                let okPacket = try packet.decode(MySQLProtocol.OK_Packet.self, capabilities: capabilities)
                if okPacket.statusFlags.contains(.SERVER_MORE_RESULTS_EXISTS) {
                    return .noResponse
                } else {
                    self.state = .done
                    return .done
                }
            } else {
                let res = try packet.decode(MySQLProtocol.COM_QUERY_Response.self, capabilities: capabilities)
                self.state = .columns(count: res.columnCount)
                self.columns = []
                return .noResponse
            }
        case .columns(let total):
            let column = try packet.decode(MySQLProtocol.ColumnDefinition41.self, capabilities: capabilities)
            self.columns.append(column)
            if self.columns.count >= numericCast(total) {
                self.state = .rows
            }
            return .noResponse
        case .rows:
            guard !packet.isEOF else {
                let okPacket = try packet.decode(MySQLProtocol.OK_Packet.self, capabilities: capabilities)
                if okPacket.statusFlags.contains(.SERVER_MORE_RESULTS_EXISTS) {
                    self.state = .ready
                    return .noResponse
                } else {
                    self.state = .done
                    return .done
                }
            }
            
            let data = try MySQLProtocol.TextResultSetRow.decode(from: &packet, columnCount: self.columns.count)
            let row = MySQLRow(
                format: .text,
                columnDefinitions: self.columns,
                values: data.values
            )
            self.onRow(row)
            return .noResponse
        case .done: throw MySQLError.protocolError
        }
    }
    
    func activate(capabilities: MySQLProtocol.CapabilityFlags) throws -> MySQLCommandState {
        try .response([
            .encode(MySQLProtocol.COM_QUERY(query: self.sql), capabilities: capabilities)
        ])
    }
}
