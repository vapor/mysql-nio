extension MySQLProtocol {
    /// Table 14.4 Column Types
    public struct DataType: RawRepresentable, Equatable, CustomStringConvertible, Sendable {
        /// Implemented by `ProtocolBinary::MYSQL_TYPE_DECIMAL`
        public static var decimal: Self { .init(rawValue: 0x00) }
        
        /// Implemented by `ProtocolBinary::MYSQL_TYPE_TINY`
        public static var tiny: Self { .init(rawValue: 0x01) }
        
        /// Implemented by `ProtocolBinary::MYSQL_TYPE_SHORT`
        public static var short: Self { .init(rawValue: 0x02) }
        
        /// Implemented by `ProtocolBinary::MYSQL_TYPE_LONG`
        public static var long: Self { .init(rawValue: 0x03) }
        
        /// Implemented by `ProtocolBinary::MYSQL_TYPE_FLOAT`
        public static var float: Self { .init(rawValue: 0x04) }
        
        /// Implemented by `ProtocolBinary::MYSQL_TYPE_DOUBLE`
        public static var double: Self { .init(rawValue: 0x05) }
        
        /// Implemented by `ProtocolBinary::MYSQL_TYPE_NULL`
        public static var null: Self { .init(rawValue: 0x06) }
        
        /// Implemented by `ProtocolBinary::MYSQL_TYPE_TIMESTAMP`
        public static var timestamp: Self { .init(rawValue: 0x07) }
        
        /// Implemented by `ProtocolBinary::MYSQL_TYPE_LONGLONG`
        public static var longlong: Self { .init(rawValue: 0x08) }
        
        /// Implemented by `ProtocolBinary::MYSQL_TYPE_INT24`
        public static var int24: Self { .init(rawValue: 0x09) }
        
        /// Implemented by `ProtocolBinary::MYSQL_TYPE_DATE`
        public static var date: Self { .init(rawValue: 0x0a) }
        
        /// Implemented by `ProtocolBinary::MYSQL_TYPE_TIME`
        public static var time: Self { .init(rawValue: 0x0b) }
        
        /// Implemented by `ProtocolBinary::MYSQL_TYPE_DATETIME`
        public static var datetime: Self { .init(rawValue: 0x0c) }
        
        /// Implemented by `ProtocolBinary::MYSQL_TYPE_YEAR`
        public static var year: Self { .init(rawValue: 0x0d) }
        
        /// see `Protocol::MYSQL_TYPE_DATE`
        public static var newdate: Self { .init(rawValue: 0x0e) }
        
        /// Implemented by `ProtocolBinary::MYSQL_TYPE_VARCHAR`
        public static var varchar: Self { .init(rawValue: 0x0f) }
        
        /// Implemented by `ProtocolBinary::MYSQL_TYPE_BIT`
        public static var bit: Self { .init(rawValue: 0x10) }
        
        /// see `Protocol::MYSQL_TYPE_TIMESTAMP2`
        public static var timestamp2: Self { .init(rawValue: 0x11) }
        
        /// see `Protocol::MYSQL_TYPE_DATETIME2`
        public static var datetime2: Self { .init(rawValue: 0x12) }
        
        /// see `Protocol::MYSQL_TYPE_TIME2`
        public static var time2: Self { .init(rawValue: 0x13) }
        
        /// Implemented by `ProtocolBinary::MYSQL_TYPE_JSON`
        public static var json: Self { .init(rawValue: 0xf5) }
        
        /// Implemented by `ProtocolBinary::MYSQL_TYPE_NEWDECIMAL`
        public static var newdecimal: Self { .init(rawValue: 0xf6) }
        
        /// Implemented by `ProtocolBinary::MYSQL_TYPE_ENUM`
        public static var `enum`: Self { .init(rawValue: 0xf7) }
        
        /// Implemented by `ProtocolBinary::MYSQL_TYPE_SET`
        public static var set: Self { .init(rawValue: 0xf8) }
        
        /// Implemented by `ProtocolBinary::MYSQL_TYPE_TINY_BLOB`
        public static var tinyBlob: Self { .init(rawValue: 0xf9) }
        
        /// Implemented by `ProtocolBinary::MYSQL_TYPE_MEDIUM_BLOB`
        public static var mediumBlob: Self { .init(rawValue: 0xfa) }
        
        /// Implemented by `ProtocolBinary::MYSQL_TYPE_LONG_BLOB`
        public static var longBlob: Self { .init(rawValue: 0xfb) }
        
        /// Implemented by `ProtocolBinary::MYSQL_TYPE_BLOB`
        public static var blob: Self { .init(rawValue: 0xfc) }
        
        /// Implemented by `ProtocolBinary::MYSQL_TYPE_VAR_STRING`
        public static var varString: Self { .init(rawValue: 0xfd) }
        
        /// Implemented by `ProtocolBinary::MYSQL_TYPE_STRING`
        public static var string: Self { .init(rawValue: 0xfe) }
        
        /// Implemented by `ProtocolBinary::MYSQL_TYPE_GEOMETRY`
        public static var geometry: Self { .init(rawValue: 0xff) }
        
        /// Length that this type encodes to. If `nil`, the encoded
        /// value is prefixed by a length-encoded integer.
        /// https://dev.mysql.com/doc/refman/8.0/en/c-api-prepared-statement-type-codes.html
        internal var encodingLength: Int? {
            let length: Int?
            switch self {
            case .string, .varchar, .varString, .enum, .set, .longBlob, .mediumBlob, .blob, .tinyBlob, .geometry, .bit, .decimal, .newdecimal, .json, .null:
                length = nil
            case .longlong:
                length = 8
            case .long, .int24:
                length = 4
            case .short, .year:
                length = 2
            case .tiny:
                length = 1
            case .time, .date, .datetime, .timestamp:
                length = nil
            case .float:
                length = 4
            case .double:
                length = 8
            default:
                // guess
                length = nil
            }
            return length
        }
        
        /// The raw byte.
        public let rawValue: UInt8
        
        /// See ``RawRepresentable/init(rawValue:)``.
        public init(rawValue: UInt8) {
            self.rawValue = rawValue
        }
        
        public var description: String {
            return self.name
        }
        
        public var name: String {
            switch self {
            case .decimal: return "MYSQL_TYPE_DECIMAL"
            case .tiny: return "MYSQL_TYPE_TINY"
            case .short: return "MYSQL_TYPE_SHORT"
            case .long: return "MYSQL_TYPE_LONG"
            case .float: return "MYSQL_TYPE_FLOAT"
            case .double: return "MYSQL_TYPE_DOUBLE"
            case .null: return "MYSQL_TYPE_NULL"
            case .timestamp: return "MYSQL_TYPE_TIMESTAMP"
            case .longlong: return "MYSQL_TYPE_LONGLONG"
            case .int24: return "MYSQL_TYPE_INT24"
            case .date: return "MYSQL_TYPE_DATE"
            case .time: return "MYSQL_TYPE_TIME"
            case .datetime: return "MYSQL_TYPE_DATETIME"
            case .year: return "MYSQL_TYPE_YEAR"
            case .newdate: return "MYSQL_TYPE_NEWDATE"
            case .varchar: return "MYSQL_TYPE_VARCHAR"
            case .bit: return "MYSQL_TYPE_BIT"
            case .timestamp2: return "MYSQL_TYPE_TIMESTAMP2"
            case .datetime2: return "MYSQL_TYPE_DATETIME2"
            case .time2: return "MYSQL_TYPE_TIME2"
            case .json: return "MYSQL_TYPE_JSON"
            case .newdecimal: return "MYSQL_TYPE_NEWDECIMAL"
            case .enum: return "MYSQL_TYPE_ENUM"
            case .set: return "MYSQL_TYPE_SET"
            case .tinyBlob: return "MYSQL_TYPE_TINY_BLOB"
            case .mediumBlob: return "MYSQL_TYPE_MEDIUM_BLOB"
            case .longBlob: return "MYSQL_TYPE_LONG_BLOB"
            case .blob: return "MYSQL_TYPE_BLOB"
            case .varString: return "MYSQL_TYPE_VAR_STRING"
            case .string: return "MYSQL_TYPE_STRING"
            case .geometry: return "MYSQL_TYPE_GEOMETRY"
            default: return "MYSQL_TYPE_UNKNOWN (\(self.rawValue))"
            }
        }
    }
}
