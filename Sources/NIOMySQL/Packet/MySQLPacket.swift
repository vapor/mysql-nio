public struct MySQLPacket {
    public var payload: ByteBuffer
    
    public init(payload: ByteBuffer) {
        self.payload = payload
    }
    
    public var isError: Bool {
        return self.payload.getInteger(
            at: self.payload.readerIndex,
            endianness: .little, 
            as: UInt8.self
        ) == 0xFF
    }
}
