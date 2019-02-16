public struct MySQLPacket {
    public var payload: ByteBuffer
    
    public init(payload: ByteBuffer) {
        self.payload = payload
    }
}
