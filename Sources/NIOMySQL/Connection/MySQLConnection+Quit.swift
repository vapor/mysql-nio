extension MySQLConnection {
    public func quit() -> EventLoopFuture<Void> {
        return self.send(MySQLQuitRequest())
    }
}

final class MySQLQuitRequest: MySQLConnectionRequestDelegate {
    func handle(_ packet: inout MySQLPacket) throws -> [MySQLPacket]? {
        return nil
    }
    
    func initial() -> [MySQLPacket] {
        return [.quit]
    }
    
    var isQuit: Bool {
        return true
    }
}
