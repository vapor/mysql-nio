extension MySQLProtocol {
    /// A Binary Protocol Resultset Row is made up of the NULL bitmap containing as many bits as we have columns
    /// in the resultset + 2 and the values for columns that are not NULL in the Binary Protocol Value format.
    public struct BinaryResultSetRow {
        /// The values for this row.
        var values: [ByteBuffer?]
        
        /// Parses a `MySQLBinaryResultsetRow` from the `ByteBuffer`.
        public static func decode(from packet: inout MySQLPacket, columns: [ColumnDefinition41]) throws -> BinaryResultSetRow {
            guard let header = packet.payload.readInteger(endianness: .little, as: UInt8.self) else {
                fatalError()
            }
            assert(header == 0x00)
            guard let nullBitmap = NullBitmap.readResultSetNullBitmap(
                count: columns.count, from: &packet.payload
            ) else {
                fatalError()
            }
            
            var values: [ByteBuffer?] = []
            values.reserveCapacity(columns.count)
            for (i, column) in columns.enumerated() {
                let storage: ByteBuffer?
                if nullBitmap.isNull(at: i) {
                    storage = nil
                } else {
                    if let length = column.columnType.encodingLength {
                        guard let data = packet.payload.readSlice(length: length) else {
                            fatalError()
                        }
                        storage = data
                    } else {
                        guard let data = packet.payload.readLengthEncodedSlice() else {
                            fatalError()
                        }
                        storage = data
                    }
                }
                values.append(storage)
            }
            
            return .init(values: values)
        }
    }
}
