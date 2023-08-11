import NIOCore

extension MySQLPackets {
    /// A MySQL wire protocol client resultset column count packet (valid for both text and binary result sets).
    struct ResultsetFieldCount {
        let columnCount: Int
        let metadataPending: Bool
    
        /// A column count packet is not mistakable for any other packet at the points in time it can appear.
        init(from packet: ByteBuffer, activeCapabilities capabilities: MySQLCapabilities) throws {
            var packet = packet
            
            guard let columnCount     = packet.mysql_readLengthEncodedInteger(),
                                        columnCount > 0,
                  let metadataPending = packet.mysql_optional(capabilities.metadataFlagAvailable, packet.mysql_readInteger(as: UInt8.self)) ?? 1
            else {
                throw MySQLCoreError.protocolViolation(debugDescription: "Invalid column count packet")
            }
            
            self.columnCount = Int(columnCount)
            self.metadataPending = metadataPending != 0
        }
        
        /// - Precondition: If ``metadataPending`` is `false`, a capability permitting the flag must be enabled.
        func write(to buffer: inout ByteBuffer, activeCapabilities capabilities: MySQLCapabilities) {
            precondition(self.metadataPending || capabilities.metadataFlagAvailable)
            
            buffer.mysql_writeLengthEncodedInteger(self.columnCount)
            if capabilities.metadataFlagAvailable {
                buffer.mysql_writeInteger(metadataPending ? 1 : 0, as: UInt8.self)
            }
        }
    }
}

extension MySQLPackets.ResultsetFieldCount {
    func build(allocator: ByteBufferAllocator = .init(), activeCapabilities: MySQLCapabilities) -> ByteBuffer {
        var buffer = allocator.buffer(capacity: 4 + 10)
        buffer.writeRepeatingByte(0, count: 4) // for frame
        self.write(to: &buffer, activeCapabilities: activeCapabilities)
        return buffer
    }
}
