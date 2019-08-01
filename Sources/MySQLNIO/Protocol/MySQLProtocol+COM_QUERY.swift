extension MySQLProtocol {
    /// 14.6.4 COM_QUERY
    ///
    /// A COM_QUERY is used to send the server a text-based query that is executed immediately.
    /// The server replies to a COM_QUERY packet with a COM_QUERY Response.
    /// The length of the query-string is a taken from the packet length - 1.
    ///
    /// https://dev.mysql.com/doc/internals/en/com-query.html
    public struct COM_QUERY: MySQLPacketEncodable {
        /// query (string.EOF) -- query_text
        public let query: String
        
        public init(query: String) {
            self.query = query
        }
        
        public func encode(to packet: inout MySQLPacket, capabilities: MySQLProtocol.CapabilityFlags) throws {
            /// command_id (1) -- 0x03 COM_QUERY
            packet.payload.writeInteger(0x03, as: UInt8.self)
            /// eof-terminated
            packet.payload.writeString(self.query)
        }
    }
}
