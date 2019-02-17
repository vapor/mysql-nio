extension MySQLPacket {
    public init(_ comQuery: ComQuery) {
        self.payload = ByteBufferAllocator().buffer(capacity: 0)
        comQuery.serialize(into: &self.payload)
    }
    
    /// 14.6.4 COM_QUERY
    ///
    /// A COM_QUERY is used to send the server a text-based query that is executed immediately.
    /// The server replies to a COM_QUERY packet with a COM_QUERY Response.
    /// The length of the query-string is a taken from the packet length - 1.
    ///
    /// https://dev.mysql.com/doc/internals/en/com-query.html
    public struct ComQuery {
        /// query (string.EOF) -- query_text
        public let query: String
        
        internal func serialize(into payload: inout ByteBuffer) {
            /// command_id (1) -- 0x03 COM_QUERY
            payload.writeInteger(0x03, as: UInt8.self)
            /// eof-terminated
            payload.writeString(self.query)
        }
    }
}
