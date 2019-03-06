public final class MySQLConnection {
    public let channel: Channel
    
    public var eventLoop: EventLoop {
        return self.channel.eventLoop
    }
    
    public var isClosed: Bool {
        return !self.channel.isActive
    }
    
    internal init(channel: Channel) {
        self.channel = channel
    }
    
    public func close() -> EventLoopFuture<Void> {
        guard self.channel.isActive else {
            return self.channel.eventLoop.makeSucceededFuture(())
        }
        return self.channel.close(mode: .all)
    }
    
    deinit {
        assert(!self.channel.isActive, "MySQLConnection not closed before deinit.")
    }
}
