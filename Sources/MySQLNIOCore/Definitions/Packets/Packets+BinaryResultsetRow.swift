import NIOCore

extension MySQLPackets {
    /// A MySQL wire protocol client binary resultset data row packet.
    struct BinaryResultsetRow {
        /// A binary result row has the same marker as an `OK_Packet`. This avoids ambiguity only because
        /// a binary row will never appear as the first packet of an execute or fetch response and because
        /// the final terminating OK packet which comes after all data rows will have the EOF marker. The
        /// marker is provided on binary rows at all solely because otherwise a row could be confused with
        /// a column count packet. In practice there can never be confusion between an EOF packet and a NULL
        /// bitmap; the NULL bitmap in a binary row will always have an offset of two, and the two prefix bits
        /// will always be zero, meaning that the first byte of the NULL bitmap is limited to `0x00-0xfc`.
        static var markerByte: UInt8 { 0x00 }
        
        let valueSlices: [ByteBuffer?]
        
        /// Unlike a text resultset row, a binary row's values can not be parsed even partially without
        /// advance knowledge of, at minimum, the individual column sizes.
        init(from packet: ByteBuffer, columnWidths: [Int?]) throws {
            var packet = packet

            guard packet.mysql_readMarker(matching: Self.markerByte),
                  let nullFlagBytes = packet.readBytes(length: FixedBitArray.bytesRequired(forCapacity: columnWidths.count + 2)) else {
                throw MySQLCoreError.protocolViolation(debugDescription: "Invalid binary result row packet")
            }
            
            let nullFlags = FixedBitArray(bytes: nullFlagBytes, significantBits: columnWidths.count + 2)
            
            self.valueSlices = try [ByteBuffer?].init(unsafeUninitializedCapacity: columnWidths.count) { valueSlices, count in
                assert(count == 0)
                for length in columnWidths {
                    if nullFlags[count + 2] {
                        valueSlices[count] = nil
                    } else if let length {
                        guard let slice = packet.readSlice(length: length) else {
                            throw MySQLCoreError.protocolViolation(debugDescription: "Invalid binary result row packet")
                        }
                        valueSlices[count] = slice
                    } else {
                        guard let length = packet.mysql_readLengthEncodedInteger(),
                              let slice  = packet.readSlice(length: Int(length))
                        else {
                            throw MySQLCoreError.protocolViolation(debugDescription: "Invalid binary result row packet")
                        }
                        valueSlices[count] = slice
                    }
                    count += 1
                }
                guard packet.readableBytes == 0 else {
                    throw MySQLCoreError.protocolViolation(debugDescription: "Invalid binary result row packet")
                }
            }
        }
        
        func write(to buffer: inout ByteBuffer) {
            buffer.writeInteger(Self.markerByte)
            buffer.writeBytes(FixedBitArray(self.valueSlices.map { $0 == nil }).bytes)
            for slice in self.valueSlices.compacted() {
                buffer.writeImmutableBuffer(slice)
            }
        }
    }
}

extension MySQLPackets.BinaryResultsetRow {
    func build(allocator: ByteBufferAllocator = .init()) -> ByteBuffer {
        var buffer = allocator.buffer(capacity:
            4 + 1 +
            FixedBitArray.bytesRequired(forCapacity: valueSlices.count) +
            self.valueSlices.reduce(0, { $0 + ($1?.readableBytes ?? 0) }))
        buffer.writeRepeatingByte(0, count: 4) // for frame
        self.write(to: &buffer)
        return buffer
    }
}
