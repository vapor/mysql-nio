extension MySQLProtocol {
    /// This packet is sent as the initial response to both `COM_QUERY` and `COM_EXECUTE` (unless there are no result
    /// rows); it indicates how many `ColumnDefinition41` packets follow. The column count is always greater than zero.
    /// (To be precise, a column count of zero indicates an `OK_Packet`, which is detected before reaching this packet's
    /// decoding logic.)
    ///
    /// If the `MARIADB_CLIENT_CACHE_METADATA` capability is active, an additional flag follows; if the flag is zero,
    /// the column definition packets are _not_ sent as part of the resultset.
    ///
    /// https://dev.mysql.com/doc/internals/en/com-query-response.html#packet-ProtocolText::Resultset
    /// https://dev.mysql.com/doc/internals/en/binary-protocol-resultset.html
    struct ResultsetColumnCount: MySQLPacketCodable {
        /// `int<lenenc> -- column count`
        let columnCount: UInt64
        
        /// `int<1> -- send metadata`
        let sendMetadata: Bool
        
        /// `MySQLPacketDecodable` conformance.
        static func decode(from packet: inout MySQLPacket, capabilities: MySQLProtocol.CapabilityFlags) throws -> ResultsetColumnCount {
            let columnCount = try packet.readLengthEncodedInteger()
            assert(columnCount > 0, "OK_Packet mishandled as resultset column count packet") // this should be detected sooner
            
            let sendMetadata: Bool
            if capabilities.contains(.MARIADB_CLIENT_CACHE_METADATA) {
                let sendMetadataValue = try packet.readInteger(endianness: .little, as: UInt8.self)
                guard sendMetadataValue < 2 else { throw MySQLError.protocolError }
                sendMetadata = (sendMetadataValue == 1)
            } else {
                sendMetadata = true
            }
            
            return .init(columnCount: columnCount, sendMetadata: sendMetadata)
        }
        
        /// `MySQLPacketEncodable` conformance.
        func encode(to packet: inout MySQLPacket, capabilities: MySQLProtocol.CapabilityFlags) throws {
            assert(self.columnCount > 0, "Column count can't be zero")
            packet.payload.writeLengthEncodedInteger(self.columnCount)
            
            if capabilities.contains(.MARIADB_CLIENT_CACHE_METADATA) {
                packet.payload.writeInteger(self.sendMetadata ? 1 : 0, endianness: .little, as: UInt8.self)
            } else {
                assert(self.sendMetadata, "MariaDB cache metadata capability is required to disable metadata in a resultset")
            }
        }
    }
}
