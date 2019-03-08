extension MySQLProtocol {
    /// ProtocolText::ResultsetRow
    ///
    /// A row with the data for each column.
    /// - NULL is sent as 0xfb
    /// - everything else is converted into a string and is sent as Protocol::LengthEncodedString.
    public struct ResultSetRow: MySQLPacketDecodable {
        /// The result set's data.
        public var value: ByteBuffer?
        
        /// Creates a new `ResultSetRow`.
        public init(value: ByteBuffer?) {
            self.value = value
        }
        
        /// `MySQLPacketDecodable` conformance.
        public static func decode(from packet: inout MySQLPacket, capabilities: MySQLProtocol.CapabilityFlags) throws -> ResultSetRow {
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
            return .init(value: value)
        }
    }
}
