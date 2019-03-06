extension MySQLPacket {
    /// https://dev.mysql.com/doc/internals/en/com-query-response.html#packet-COM_QUERY_Response
    public mutating func comQueryResponse() throws -> ComQueryResponse {
        return try .init(payload: &self.payload)
    }
    
    /// The query-response packet is a meta packet which can be one of
    ///
    /// If the number of columns in the resultset is 0, this is a OK_Packet.
    public struct ComQueryResponse {
        public enum Error: Swift.Error {
            case missingCount
        }
        
        public let columnCount: UInt64
        
        /// Parses a `ComQueryResponse` from the `ByteBuffer`.
        init(payload: inout ByteBuffer) throws {
            guard let columnCount = payload.readLengthEncodedInteger() else {
                throw Error.missingCount
            }
            self.columnCount = columnCount
        }
    }
}
