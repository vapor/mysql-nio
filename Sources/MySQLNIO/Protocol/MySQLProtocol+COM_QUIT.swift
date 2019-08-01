extension MySQLProtocol {
    /// tells the server that the client wants to close the connection
    ///
    /// https://dev.mysql.com/doc/internals/en/com-quit.html
    public struct COM_QUIT: MySQLPacketEncodable {
        /// Creates a new `COM_QUIT` packet.
        public init() { }
        
        /// `MySQLPacketEncodable` conformance.
        public func encode(to packet: inout MySQLPacket, capabilities: MySQLProtocol.CapabilityFlags) throws {
            packet.payload.writeInteger(1, endianness: .little, as: UInt8.self)
        }
    }
}
