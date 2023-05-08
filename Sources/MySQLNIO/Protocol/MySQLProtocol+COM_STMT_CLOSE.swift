extension MySQLProtocol {
    /// `COM_STMT_CLOSE` deallocates a prepared statement
    ///
    /// No response is sent back to the client.
    ///
    /// https://dev.mysql.com/doc/internals/en/com-stmt-close.html
    public struct COM_STMT_CLOSE {
        /// `stmt-id`
        public var statementID: UInt32
        
        /// Serializes the `ComStmtClose` into a buffer.
        public func encode(into packet: inout MySQLPacket) {
            packet.payload.writeInteger(0x19, endianness: .little, as: UInt8.self)
            packet.payload.writeInteger(self.statementID, endianness: .little)
        }
    }
}
