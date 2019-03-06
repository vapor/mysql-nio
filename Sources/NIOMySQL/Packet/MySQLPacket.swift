public struct MySQLPacket {
    public var payload: ByteBuffer
    
    public init(payload: ByteBuffer) {
        self.payload = payload
    }
    
    public init() {
        self.payload = ByteBufferAllocator().buffer(capacity: 0)
    }
    
    public var isError: Bool {
        return self.headerFlag == 0xFF
    }
    
    public var isOK: Bool {
        return self.headerFlag == 0xFE || self.headerFlag == 0x00
    }
    
    var headerFlag: UInt8? {
        return self.payload.getInteger(at: self.payload.readerIndex)
    }
}
