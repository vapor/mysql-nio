public final class MySQLPacketEncoder: MessageToByteEncoder {
    public typealias OutboundIn = MySQLPacket
    
    public let sequence: MySQLPacketSequence
    
    public init(sequence: MySQLPacketSequence) {
        self.sequence = sequence
    }
    
    public func encode(data: MySQLPacket, out: inout ByteBuffer) throws {
        var packet = data
        let length = packet.payload.readableBytes
        out.writeInteger(UInt8(length & 0xFF))
        out.writeInteger(UInt8(length >> 8 & 0xFF))
        out.writeInteger(UInt8(length >> 16 & 0xFF))
        if packet.payload.readableBytes == 1 {
            // sends seq 0 for quit packet
            #warning("TODO: improve sequence reset logic")
            out.writeInteger(0, as: UInt8.self)
        } else {
            out.writeInteger(UInt8(self.sequence.next()))
        }
        out.writeBuffer(&packet.payload)
    }
}
