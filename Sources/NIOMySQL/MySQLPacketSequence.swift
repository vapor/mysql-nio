public final class MySQLPacketSequence {
    public var current: UInt8?
    
    public init() {
        self.current = nil
    }
    
    public func next() -> UInt8 {
        if let existing = self.current {
            self.current = existing &+ 1
        } else {
            self.current = 0
        }
        return self.current!
    }
}
