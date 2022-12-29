import Logging
import NIOCore

final class MySQLPacketEncoder: MessageToByteEncoder {
    typealias OutboundIn = MySQLPacket
    
    let sequence: MySQLPacketSequence
    let logger: Logger

    init(sequence: MySQLPacketSequence, logger: Logger) {
        self.sequence = sequence
        self.logger = logger
    }
    
    func encode(data: MySQLPacket, out: inout ByteBuffer) throws {
        self.logger.trace("MySQLPacketDecoder.encode: \(data)")
        out.writeUInt24(UInt32(data.payload.readableBytes))
        out.writeInteger(self.sequence.next())
        out.writeImmutableBuffer(data.payload)
    }
}
