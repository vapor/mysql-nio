import NIOCore

extension MySQLPackets {
    /// A MySQL wire protocol client SSL request packet
    struct SSLRequest {
        let clientCapabilities: MySQLCapabilities
        let collation: UInt8

        /// Attempt to decode a raw packet as an `SSLRequest` packet.
        ///
        /// It is not possible to reliably distinguish an SSL request packet from other packets; thus,
        /// any problem with decoding is always considered a protocol violation.
        ///
        /// - Throws: Protocol violation error for a `SSLRequest` packet with invalid or truncated data
        init(from packet: ByteBuffer, activeCapabilities capabilities: MySQLCapabilities) throws {
            var packet = packet
            
            guard let (capabilityFlags, _/*maxPacketSize*/, collation)
                                         = packet.readMultipleIntegers(endianness: .little, as: (UInt32, UInt32, UInt8).self),
                  /*let filler          =*/packet.mysql_readRepeatingByte(count: 19),
                  let capabilityFlagsExt = packet.mysql_readInteger(as: UInt32.self)
            else {
                throw MySQLCoreError.protocolViolation(debugDescription: "Invalid SSL request packet")
            }
            
            self.clientCapabilities = .init(rawValues: capabilityFlags, capabilityFlagsExt)
            self.collation = collation
        }
        
        /// Create an `SSLRequest` packet from a set of parameters.
        init(
            clientCapabilities: MySQLCapabilities,
            collation: UInt8
        ) {
            self.clientCapabilities = clientCapabilities
            self.collation = collation
        }
        
        /// Encode this structure in the raw `SSLRequest` wire format.
        func write(to buffer: inout ByteBuffer) {
            buffer.writeMultipleIntegers(self.clientCapabilities.lowHalf, UInt32.max, self.collation, endianness: .little)
            buffer.writeRepeatingByte(0, count: 19)
            buffer.mysql_writeInteger(self.clientCapabilities.extendedHalf)
        }
    }
}

extension MySQLPackets.SSLRequest {
    func build(allocator: ByteBufferAllocator = .init()) -> ByteBuffer {
        var buffer = allocator.buffer(capacity: 36)
        buffer.writeRepeatingByte(0, count: 4) // for frame
        self.write(to: &buffer)
        return buffer
    }
}
