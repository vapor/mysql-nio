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
        onMetadata: @escaping (MySQLQueryMetadata) throws -> () = { _ in }
    ) -> EventLoopFuture<[MySQLRow]> {
        var rows = [MySQLRow]()
        return self.query(sql, binds, onRow: { row in
            rows.append(row)
        }, onMetadata: onMetadata).map { rows }
    }
    
    public func query(
        _ sql: String,
        _ binds: [MySQLData] = [],
        onRow: @escaping (MySQLRow) throws -> (),
        onMetadata: @escaping (MySQLQueryMetadata) throws -> () = { _ in }
    ) -> EventLoopFuture<Void> {
        self.logger.debug("\(sql) \(binds)")
        let query = MySQLQueryCommand(
            sql: sql,
            binds: binds,
            onRow: onRow,
            onMetadata: onMetadata,
            logger: self.logger
        )
        return self.send(query, logger: self.logger)
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
    let onRow: (MySQLRow) throws -> ()
    let onMetadata: (MySQLQueryMetadata) throws -> ()
    let logger: Logger

    private var columns: [MySQLProtocol.ColumnDefinition41]
    private var params: [MySQLProtocol.ColumnDefinition41]
    private var ok: MySQLProtocol.COM_STMT_PREPARE_OK?

    private var lastUserError: Error?
    var statementID: UInt32?
    
    init(
        sql: String,
        binds: [MySQLData],
        onRow: @escaping (MySQLRow) throws -> (),
        onMetadata: @escaping (MySQLQueryMetadata) throws -> (),
        logger: Logger
    ) {
        self.state = .ready
        self.sql = sql
        self.binds = binds
        self.columns = []
        self.params = []
        self.onRow = onRow
        self.onMetadata = onMetadata
        self.logger = logger
    }
    
    func handle(packet: inout MySQLPacket, capabilities: MySQLProtocol.CapabilityFlags) throws -> MySQLCommandState {
        self.logger.trace("MySQLQueryCommand.\(self.state)")
        guard !packet.isError else {
            self.state = .done

            let errorPacket = try packet.decode(
                MySQLProtocol.ERR_Packet.self,
                capabilities: capabilities
            )
            let error: Error
            switch errorPacket.errorCode {
            case .DUP_ENTRY:
                error = MySQLError.duplicateEntry(errorPacket.errorMessage)
            default:
                error = MySQLError.server(errorPacket)
            }

            var response: [MySQLPacket] = []
            if let statementID = self.statementID {
                self.statementID = nil
                var packet = MySQLPacket()
                MySQLProtocol.COM_STMT_CLOSE(
                    statementID: statementID
                ).encode(into: &packet)
                response = [packet]
            }

            return .init(
                response: response,
                done: true,
                resetSequence: true,
                error: error
            )
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
            self.statementID = res.statementID
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
                return try self.done(packet: &packet, capabilities: capabilities)
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
                return try self.done(packet: &packet, capabilities: capabilities)
            }

            let data = try MySQLProtocol.BinaryResultSetRow.decode(from: &packet, columns: columns)
            let row = MySQLRow(
                format: .binary,
                columnDefinitions: self.columns,
                values: data.values
            )
            do {
                try self.onRow(row)
            } catch {
                self.lastUserError = error
            }
            return .noResponse
        case .done: fatalError()
        }
    }

    func done(packet: inout MySQLPacket, capabilities: MySQLProtocol.CapabilityFlags) throws -> MySQLCommandState {
        self.state = .done
        if packet.isOK {
            let ok = try MySQLProtocol.OK_Packet.decode(from: &packet, capabilities: capabilities)
            do {
                try self.onMetadata(.init(affectedRows: ok.affectedRows, lastInsertID: ok.lastInsertID))
            } catch {
                self.lastUserError = error
            }
        }
        var packet = MySQLPacket()
        MySQLProtocol.COM_STMT_CLOSE(
            statementID: self.ok!.statementID
        ).encode(into: &packet)
        self.statementID = nil
        return .init(
            response: [packet],
            done: true,
            resetSequence: true,
            error: self.lastUserError
        )
    }
    
    func activate(capabilities: MySQLProtocol.CapabilityFlags) throws -> MySQLCommandState {
        let prepare = MySQLProtocol.COM_STMT_PREPARE(query: self.sql)
        return try .response([.encode(prepare, capabilities: capabilities)])
    }

    deinit {
        assert(self.statementID == nil, "Statement not closed: \(self.sql)")
        if self.statementID != nil {
            self.logger.error("Statement not closed: \(self.sql)")
        }
    }
}
