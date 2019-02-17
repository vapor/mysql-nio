public final class MySQLPacketSequence {
    public var current: UInt8
    
    public init() {
        self.current = 0
    }
    
    public func next() -> UInt8 {
        self.current = self.current &+ 1
        return self.current
    }
}
