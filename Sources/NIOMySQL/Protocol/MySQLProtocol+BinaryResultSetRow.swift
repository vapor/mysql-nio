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
                    let length: Int?
                    switch column.columnType {
                    case .MYSQL_TYPE_STRING,
                         .MYSQL_TYPE_VARCHAR,
                         .MYSQL_TYPE_VAR_STRING,
                         .MYSQL_TYPE_ENUM,
                         .MYSQL_TYPE_SET,
                         .MYSQL_TYPE_LONG_BLOB,
                         .MYSQL_TYPE_MEDIUM_BLOB,
                         .MYSQL_TYPE_BLOB,
                         .MYSQL_TYPE_TINY_BLOB,
                         .MYSQL_TYPE_GEOMETRY,
                         .MYSQL_TYPE_BIT,
                         .MYSQL_TYPE_DECIMAL,
                         .MYSQL_TYPE_NEWDECIMAL,
                         .MYSQL_TYPE_JSON:
                        length = nil
                    case .MYSQL_TYPE_LONGLONG:
                        length = 8
                    case .MYSQL_TYPE_LONG, .MYSQL_TYPE_INT24:
                        length = 4
                    case .MYSQL_TYPE_SHORT, .MYSQL_TYPE_YEAR:
                        length = 2
                    case .MYSQL_TYPE_TINY:
                        length = 1
                    case .MYSQL_TYPE_TIME, .MYSQL_TYPE_DATE, .MYSQL_TYPE_DATETIME, .MYSQL_TYPE_TIMESTAMP:
                        guard let timeLength = packet.payload.getInteger(at: packet.payload.readableBytes, endianness: .little, as: UInt8.self) else {
                            fatalError()
                        }
                        length = numericCast(timeLength)
                    case .MYSQL_TYPE_FLOAT:
                        length = 4
                    case .MYSQL_TYPE_DOUBLE:
                        length = 8
                    default:
                        fatalError("Unsupported type: \(column)")
                    }
                    
                    if let length = length {
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
