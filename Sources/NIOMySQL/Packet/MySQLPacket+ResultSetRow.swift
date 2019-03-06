extension MySQLPacket {
    public mutating func resultSetRow() throws -> ResultSetRow {
        return try .init(payload: &self.payload)
    }
    
    /// ProtocolText::ResultsetRow
    ///
    /// A row with the data for each column.
    /// - NULL is sent as 0xfb
    /// - everything else is converted into a string and is sent as Protocol::LengthEncodedString.
    public struct ResultSetRow {
        /// The result set's data.
        var value: ByteBuffer?
        
        /// Parses a `MySQLResultSetRow` from the `ByteBuffer`.
        init(payload: inout ByteBuffer) throws {
            guard let header =  payload.getInteger(at: payload.readerIndex, as: UInt8.self) else {
                fatalError()
            }
            
            switch header {
            case 0xFB:
                self.value = nil
            default:
                guard let value = payload.readLengthEncodedSlice() else {
                    fatalError()
                }
                self.value = value
            }
        }
    }
}
