public final class MySQLPacketEncoder: MessageToByteEncoder {
    public typealias OutboundIn = MySQLPacket
    
    public let state: MySQLConnectionState
    
    public init(state: MySQLConnectionState) {
        self.state = state
    }
    
    public func encode(ctx: ChannelHandlerContext, data: MySQLPacket, out: inout ByteBuffer) throws {
        var packet = data
        let length = packet.payload.readableBytes
        out.writeInteger(UInt8(length & 0xFF))
        out.writeInteger(UInt8(length >> 8 & 0xFF))
        out.writeInteger(UInt8(length >> 16 & 0xFF))
        out.writeInteger(UInt8(self.state.nextSequenceID()))
        out.writeBuffer(&packet.payload)
    }
}
