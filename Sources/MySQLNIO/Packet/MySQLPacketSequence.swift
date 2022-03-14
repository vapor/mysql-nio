final class MySQLPacketSequence {
    var current: UInt8 = 0
    
    init() {}
    
    func reset() {
        self.current = 0
    }
    
    func next() -> UInt8 {
        defer { self.current &+= 1 }
        return self.current
    }
}
