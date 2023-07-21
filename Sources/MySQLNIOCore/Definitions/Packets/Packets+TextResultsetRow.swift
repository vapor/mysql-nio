import NIOCore

extension MySQLPackets {
    /// A MySQL wire protocol client text resultset data row packet,
    struct TextResultsetRow {
        static var nullValueMarkerByte: UInt8 { 0xfb }
        
        let valueSlices: [ByteBuffer?]
        
        /// Parse a text resultset data row. If the expected value count is not `nil`, it will be considered a
        /// protocol violation if the packet does not contain exactly that many values. It is always a protocol
        /// violation for the packet to contain zero values.
        ///
        /// In the text protocol, it is possible to confuse a data row which begins with a 9-byte length value
        /// (prefix `0xfe`) with the EOF-marked OK packet. The protocol sidesteps this possibility by explicitly
        /// restricting OK packets to never be large enough to be confusable with such encoding, per
        /// https://github.com/mysql/mysql-server/blob/8.0/sql/protocol_classic.cc#L955
        init(from packet: ByteBuffer, expectedValueCount: Int? = nil) throws {
            assert((expectedValueCount ?? .max) > 0)
            
            guard packet.readableBytes > 0 else {
                throw MySQLCoreError.protocolViolation(debugDescription: "Invalid text result row packet")
            }
            
            var packet = packet
            var valueSlices = [ByteBuffer?](reservingCapacity: expectedValueCount ?? 4)
            
            while packet.readableBytes > 0, valueSlices.count < expectedValueCount ?? .max {
                // NULL value is encoded as `0xfb`, which is an invalid length-encoded integer prefix.
                // Non-NULL value is encoded as a length-encoded string.
                if let valueLength = packet.mysql_readLengthEncodedInteger() {
                    guard let slice = packet.readSlice(length: Int(valueLength)) else {
                        throw MySQLCoreError.protocolViolation(debugDescription: "Invalid text result row packet")
                    }
                    valueSlices.append(slice)
                } else if packet.mysql_readMarker(matching: Self.nullValueMarkerByte) {
                    valueSlices.append(nil)
                } else {
                    throw MySQLCoreError.protocolViolation(debugDescription: "Invalid text result row packet")
                }
            }
            guard packet.readableBytes == 0, valueSlices.count == expectedValueCount ?? valueSlices.count else {
                throw MySQLCoreError.protocolViolation(debugDescription: "Invalid text result row packet")
            }
            
            self.valueSlices = valueSlices
        }
        
        func write(to buffer: inout ByteBuffer) {
            for slice in self.valueSlices {
                if let slice {
                    buffer.writeImmutableBuffer(slice)
                } else {
                    buffer.mysql_writeInteger(Self.nullValueMarkerByte)
                }
            }
        }
    }
}

extension MySQLPackets.TextResultsetRow {
    func build(allocator: ByteBufferAllocator = .init()) -> ByteBuffer {
        var buffer = allocator.buffer(capacity: 4 + valueSlices.reduce(0, { $0 + ($1?.readableBytes ?? 1) }))
        buffer.writeRepeatingByte(0, count: 4) // for frame
        self.write(to: &buffer)
        return buffer
    }
}
