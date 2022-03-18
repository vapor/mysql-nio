extension MySQLProtocol {
    /// 14.6.4 `COM_QUERY`
    ///
    /// A `COM_QUERY` is used to send the server a text-based query that is executed immediately.
    /// The server replies to a `COM_QUERY` packet with a `COM_QUERY Response`.
    /// The length of the query-string is a taken from the `packet length - 1`.
    ///
    /// https://dev.mysql.com/doc/internals/en/com-query.html
    struct COM_QUERY: MySQLPacketCodable {
        /// `query (string.EOF) -- query_text`
        let query: String
        
        init(query: String) {
            self.query = query
        }
        
        static func decode(from packet: inout MySQLPacket, capabilities: MySQLProtocol.CapabilityFlags) throws -> COM_QUERY {
            guard try packet.readInteger(endianness: .little, as: UInt8.self) == 0x03 else {
                throw MySQLError.protocolError
            }
            
            return .init(query: try packet.readString(length: packet.payload.readableBytes))
        }
        
        func encode(to packet: inout MySQLPacket, capabilities: MySQLProtocol.CapabilityFlags) throws {
            /// `command_id (1) -- 0x03 COM_QUERY`
            packet.payload.writeInteger(0x03, as: UInt8.self)
            /// `eof-terminated`
            packet.payload.writeString(self.query)
        }
    }
}
