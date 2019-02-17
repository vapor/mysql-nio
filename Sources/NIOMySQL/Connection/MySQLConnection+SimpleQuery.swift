extension MySQLConnection {
    public func simpleQuery(_ sql: String) -> EventLoopFuture<Void> {
        let query = MySQLSimpleQueryCommand(sql: sql)
        return self.send(query)
    }
}

private final class MySQLSimpleQueryCommand: MySQLCommandHandler {
    let sql: String
    init(sql: String) {
        self.sql = sql
    }
    
    func handle(packet: inout MySQLPacket) throws -> MySQLCommandState {
        if packet.isOK {
            return .done
        } else {
            return .noResponse
        }
    }
    
    func activate() throws -> MySQLCommandState {
        let comQuery = MySQLPacket.ComQuery(query: self.sql)
        return .response([.init(comQuery)])
    }
}
