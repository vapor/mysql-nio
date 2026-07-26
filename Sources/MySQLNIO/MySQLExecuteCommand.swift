import NIOCore

extension MySQLDatabase {
    /// Executes SQL statements that return OK packets (DDL, DML, CALL for procedures without result sets).
    /// Supports multi-statement execution when separated by semicolons.
    public func execute(_ sql: String) -> EventLoopFuture<Void> {
        let command = MySQLExecuteCommand(sql: sql)
        return self.send(command, logger: self.logger)
    }
}

private final class MySQLExecuteCommand: MySQLCommand, @unchecked Sendable {
    let sql: String

    init(sql: String) {
        self.sql = sql
    }

    func activate(capabilities: MySQLProtocol.CapabilityFlags) throws -> MySQLCommandState {
        try .response([.encode(MySQLProtocol.COM_QUERY(query: sql), capabilities: capabilities)])
    }

    func handle(packet: inout MySQLPacket, capabilities: MySQLProtocol.CapabilityFlags) throws
        -> MySQLCommandState
    {
        if packet.isError {
            let errPacket = try packet.decode(MySQLProtocol.ERR_Packet.self, capabilities: capabilities)
            let error: any Error
            switch errPacket.errorCode {
            case .DUP_ENTRY:
                error = MySQLError.duplicateEntry(errPacket.errorMessage)
            case .PARSE_ERROR:
                error = MySQLError.invalidSyntax(errPacket.errorMessage)
            default:
                error = MySQLError.server(errPacket)
            }
            throw error
        }

        let ok = try MySQLProtocol.OK_Packet.decode(from: &packet, capabilities: capabilities)
        if ok.statusFlags.contains(.SERVER_MORE_RESULTS_EXISTS) {
            return .noResponse
        }
        return .done
    }
}
