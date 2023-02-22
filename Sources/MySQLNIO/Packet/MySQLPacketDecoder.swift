import NIOCore
import Logging

public struct MySQLPacketDecoder: ByteToMessageDecoder {
    public typealias InboundOut = MySQLPacket

    public let sequence: MySQLPacketSequence
    let logger: Logger
    
    public init(
        sequence: MySQLPacketSequence,
        logger: Logger
    ) {
        self.sequence = sequence
        self.logger = logger
    }
    
    public mutating func decode(context: ChannelHandlerContext, buffer: inout ByteBuffer) throws -> DecodingState {
        var copy = buffer
        guard let header = copy.readInteger(endianness: .little, as: UInt32.self) else {
            return .needMoreData
        }
        // header = 01     00 00 01
        //          <seq>  <length>
        let length = header & 0x00_FF_FF_FF
        let sequenceID = header >> 24
        // print("header: \(header) length: \(length) seq: \(sequenceID)")
        guard let payload = copy.readSlice(length: numericCast(length)) else {
            return .needMoreData
        }
        buffer = copy
        let packet = MySQLPacket(payload: payload)
        self.logger.trace("MySQLPacketDecoder.decode: \(packet)")
        self.sequence.current = UInt8(sequenceID & 0xFF)
        context.fireChannelRead(self.wrapInboundOut(packet))
        return .continue
    }
    
    public mutating func decodeLast(context: ChannelHandlerContext, buffer: inout ByteBuffer, seenEOF: Bool) throws -> DecodingState {
        return .needMoreData
    }
}
