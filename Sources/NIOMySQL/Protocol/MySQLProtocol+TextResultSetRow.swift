extension MySQLProtocol {
    /// ProtocolText::ResultsetRow
    ///
    /// A row with the data for each column.
    /// - NULL is sent as 0xfb
    /// - everything else is converted into a string and is sent as Protocol::LengthEncodedString.
    public struct TextResultSetRow {
        /// The result set's data.
        public var values: [ByteBuffer?]
        
        /// Creates a new `ResultSetRow`.
        public init(values: [ByteBuffer?]) {
            self.values = values
        }
        
        /// `MySQLPacketDecodable` conformance.
        public static func decode(from packet: inout MySQLPacket, columnCount: Int) throws -> TextResultSetRow {
            var values: [ByteBuffer?] = []
            values.reserveCapacity(columnCount)
            for _ in 0..<columnCount {
                guard let header = packet.payload.getInteger(at: packet.payload.readerIndex, as: UInt8.self) else {
                    fatalError()
                }
                let value: ByteBuffer?
                switch header {
                case 0xFB:
                    value = nil
                default:
                    guard let v = packet.payload.readLengthEncodedSlice() else {
                        fatalError()
                    }
                    value = v
                }
                values.append(value)
            }
            return .init(values: values)
        }
    }
}
