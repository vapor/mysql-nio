extension MySQLProtocol {
    /// `COM_STMT_PREPARE` creates a prepared statement from the passed query string.
    ///
    /// The server returns a `COM_STMT_PREPARE` Response which contains a statement-id which is used to identify the prepared statement.
    ///
    /// https://dev.mysql.com/doc/internals/en/com-stmt-prepare.html#packet-COM_STMT_PREPARE
    public struct COM_STMT_PREPARE: MySQLPacketEncodable {
        /// `query` (`string.EOF`) -- the query to prepare
        public var query: String
        
        /// See ``MySQLPacketEncodable/encode(to:capabilities:)``.
        public func encode(to packet: inout MySQLPacket, capabilities: MySQLProtocol.CapabilityFlags) throws {
            /// `command` (1) -- `[16]` the `COM_STMT_PREPARE` command
            packet.payload.writeInteger(0x16, endianness: .little, as: UInt8.self)
            /// eof-terminated
            packet.payload.writeString(self.query)
        }
    }
}
