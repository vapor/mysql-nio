import Logging
import NIOCore

public final class MySQLPacketEncoder: MessageToByteEncoder {
    public typealias OutboundIn = MySQLPacket
    
    public let sequence: MySQLPacketSequence
    let logger: Logger

    public init(sequence: MySQLPacketSequence, logger: Logger) {
        self.sequence = sequence
        self.logger = logger
    }
    
    public func encode(data: MySQLPacket, out: inout ByteBuffer) throws {
        var packet = data
        self.logger.trace("MySQLPacketDecoder.encode: \(packet)")
        let length = packet.payload.readableBytes
        out.writeInteger(UInt8(length & 0xFF))
        out.writeInteger(UInt8(length >> 8 & 0xFF))
        out.writeInteger(UInt8(length >> 16 & 0xFF))
        out.writeInteger(UInt8(self.sequence.next()))
        out.writeBuffer(&packet.payload)
    }
}
