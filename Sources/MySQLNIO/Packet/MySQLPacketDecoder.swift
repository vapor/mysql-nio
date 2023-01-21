import NIOCore
import Logging

extension MySQLProtocol {
    struct PacketDecoder: NIOSingleStepByteToMessageDecoder {
        let logger: Logger
        
        var splitPacketCache: ByteBuffer = ByteBufferAllocator().buffer(capacity: 0)
        
        mutating func decode(buffer: inout ByteBuffer) throws -> MySQLPacket? {
            // Reading a UInt32 and masking off the sequence ID is a surprising amount faster than using the
            // `getUInt24()` helper followed by a 1-byte `getInteger()`, especially in debug builds.
            guard let length = buffer.getInteger(at: buffer.readerIndex, endianness: .little, as: UInt32.self).flatMap({ Int($0 & 0x00ffffff) }),
                  buffer.readableBytes - MemoryLayout<UInt32>.size >= length
            else { return nil }
            buffer.moveReaderIndex(forwardBy: MemoryLayout<UInt32>.size)
            
            // We already checked that `length` bytes are available, so we can safely force-unwrap if/when we readSlice()
            switch (length, self.splitPacketCache.readableBytes) {
                // The packet is small and there's nothing cached - standalone packet, payload is just the slice.
                case (1..<0x00ffffff, 0):
                    return MySQLPacket(payload: buffer.readSlice(length: length)!)
                // The packet is small and there is cached data - terminator with data, payload is the cached data plus the slice.
                case (1..<0x00ffffff, 1...):
                    self.splitPacketCache.writeImmutableBuffer(buffer.readSlice(length: length)!)
                    fallthrough
                // The packet is empty and there is cached data - data-less terminator, payload is the cached data.
                case (0, 1...):
                    var packet = MySQLPacket(payload: ByteBufferAllocator().buffer(capacity: 0))
                    swap(&self.splitPacketCache, &packet.payload) // swap buffers to avoid any possibility of CoWs
                    return packet
                // The packet is max size - start or continuation of a split packet, need to cache the data and wait for more
                case (0x00ffffff, _):
                    self.splitPacketCache.writeImmutableBuffer(buffer.readSlice(length: length)!)
                    return nil
                // The packet is empty and there is no cached data - this is a protocol error.
                case (0, 0):
                    throw MySQLError.protocolError
                // Length > max, length is negative, or cache size is negative - none of these should be able to happen
                default:
                    fatalError("Invalid packet length or data cache")
            }
        }
        
        mutating func decodeLast(buffer: inout ByteBuffer, seenEOF: Bool) throws -> MySQLPacket? {
            try self.decode(buffer: &buffer)
        }
    }
}
/*
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
*/
