public final class MySQLConnection {
    public let channel: Channel
    
    internal init(channel: Channel) {
        self.channel = channel
    }
    
    public func close() -> EventLoopFuture<Void> {
        return self.channel.close(mode: .all)
    }
}
