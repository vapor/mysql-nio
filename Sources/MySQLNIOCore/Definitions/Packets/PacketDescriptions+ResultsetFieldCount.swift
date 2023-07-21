import NIOCore

extension MySQLPacketDescriptions {
    /// A MySQL wire protocol client resultset column count packet (valid for both text and binary result sets).
    struct ResultsetFieldCount {
        let columnCount: Int
        let metadataPending: Bool
    
        /// This initializer is not failable because a column count packet is not mistakable for any other
        /// packet at the points in time it can appear.
        init(from packet: ByteBuffer, activeCapabilities capabilities: MySQLCapabilities) throws {
            var packet = packet
            
            guard let columnCount     = packet.mysql_readLengthEncodedInteger(),
                                        columnCount > 0,
                  let metadataPending = packet.mysql_optional(capabilities.metadataFlagAvailable, packet.mysql_readInteger(as: UInt8.self)) ?? 1
            else { throw MySQLChannel.Error.protocolViolation }
            
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
