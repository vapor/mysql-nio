extension MySQLPacket {
    public static var quit: MySQLPacket {
        var payload = ByteBufferAllocator().buffer(capacity: 1)
        payload.writeInteger(1, endianness: .little, as: UInt8.self)
        return .init(payload: payload)
    }
}
