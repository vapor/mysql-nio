import NIOCore
import Logging

struct MySQLPacketDecoder: ByteToMessageDecoder {
    typealias InboundOut = MySQLPacket

    let sequence: MySQLPacketSequence
    let logger: Logger
    
    init(sequence: MySQLPacketSequence, logger: Logger) {
        self.sequence = sequence
        self.logger = logger
    }
    
    mutating func decode(context: ChannelHandlerContext, buffer: inout ByteBuffer) throws -> DecodingState {
        guard let length = buffer.getUInt24(at: buffer.readerIndex, endianness: .little).map(Int.init(_:)),
              let sequenceID = buffer.getInteger(at: buffer.readerIndex + 3, endianness: .little, as: UInt8.self),
              let payload = buffer.getSlice(at: buffer.readerIndex + 4, length: length)
        else {
            return .needMoreData
        }
        buffer.moveReaderIndex(forwardBy: MemoryLayout<UInt32>.size + length)
        
        let packet = MySQLPacket(payload: payload)

        self.sequence.current = UInt8(sequenceID & 0xFF)
        self.logger.trace("MySQLPacketDecoder.decode: \(packet)")
        context.fireChannelRead(self.wrapInboundOut(packet))
        return .continue
    }
    
    mutating func decodeLast(context: ChannelHandlerContext, buffer: inout ByteBuffer, seenEOF: Bool) throws -> DecodingState {
        return .needMoreData
    }
}
