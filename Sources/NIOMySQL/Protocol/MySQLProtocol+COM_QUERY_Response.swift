extension MySQLProtocol {
    /// The query-response packet is a meta packet which can be one of
    ///
    /// https://dev.mysql.com/doc/internals/en/com-query-response.html
    public struct COM_QUERY_Response: MySQLPacketDecodable {
        public enum Error: Swift.Error {
            case missingCount
        }
        
        /// If the number of columns in the resultset is 0, this is a OK_Packet.
        public let columnCount: UInt64
        
        /// `MySQLPacketDecodable` conformance.
        public static func decode(from packet: inout MySQLPacket, capabilities: MySQLProtocol.CapabilityFlags) throws -> COM_QUERY_Response {
            guard let columnCount = packet.payload.readLengthEncodedInteger() else {
                throw Error.missingCount
            }
            
            return .init(columnCount: columnCount)
        }
    }
}
