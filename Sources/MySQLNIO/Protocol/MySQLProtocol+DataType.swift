extension MySQLProtocol {
    /// Table 14.4 Column Types
    public struct DataType: RawRepresentable, Equatable, CustomStringConvertible {
        /// Implemented by ProtocolBinary::MYSQL_TYPE_DECIMAL
        public static let decimal = DataType(rawValue: 0x00)
        
        /// Implemented by ProtocolBinary::MYSQL_TYPE_TINY
        public static let tiny = DataType(rawValue: 0x01)
        
        /// Implemented by ProtocolBinary::MYSQL_TYPE_SHORT
        public static let short = DataType(rawValue: 0x02)
        
        /// Implemented by ProtocolBinary::MYSQL_TYPE_LONG
        public static let long = DataType(rawValue: 0x03)
        
        /// Implemented by ProtocolBinary::MYSQL_TYPE_FLOAT
        public static let float = DataType(rawValue: 0x04)
        
        /// Implemented by ProtocolBinary::MYSQL_TYPE_DOUBLE
        public static let double = DataType(rawValue: 0x05)
        
        /// Implemented by ProtocolBinary::MYSQL_TYPE_NULL
        public static let null = DataType(rawValue: 0x06)
        
        /// Implemented by ProtocolBinary::MYSQL_TYPE_TIMESTAMP
        public static let timestamp = DataType(rawValue: 0x07)
        
        /// Implemented by ProtocolBinary::MYSQL_TYPE_LONGLONG
        public static let longlong = DataType(rawValue: 0x08)
        
        /// Implemented by ProtocolBinary::MYSQL_TYPE_INT24
        public static let int24 = DataType(rawValue: 0x09)
        
        /// Implemented by ProtocolBinary::MYSQL_TYPE_DATE
        public static let date = DataType(rawValue: 0x0a)
        
        /// Implemented by ProtocolBinary::MYSQL_TYPE_TIME
        public static let time = DataType(rawValue: 0x0b)
        
        /// Implemented by ProtocolBinary::MYSQL_TYPE_DATETIME
        public static let datetime = DataType(rawValue: 0x0c)
        
        /// Implemented by ProtocolBinary::MYSQL_TYPE_YEAR
        public static let year = DataType(rawValue: 0x0d)
        
        /// see Protocol::MYSQL_TYPE_DATE
        public static let newdate = DataType(rawValue: 0x0e)
        
        /// Implemented by ProtocolBinary::MYSQL_TYPE_VARCHAR
        public static let varchar = DataType(rawValue: 0x0f)
        
        /// Implemented by ProtocolBinary::MYSQL_TYPE_BIT
        public static let bit = DataType(rawValue: 0x10)
        
        /// see Protocol::MYSQL_TYPE_TIMESTAMP2
        public static let timestamp2 = DataType(rawValue: 0x11)
        
        /// see Protocol::MYSQL_TYPE_DATETIME2
        public static let datetime2 = DataType(rawValue: 0x12)
        
        /// see Protocol::MYSQL_TYPE_TIME2
        public static let time2 = DataType(rawValue: 0x13)
        
        /// Implemented by ProtocolBinary::MYSQL_TYPE_JSON
        public static let json = DataType(rawValue: 0xf5)
        
        /// Implemented by ProtocolBinary::MYSQL_TYPE_NEWDECIMAL
        public static let newdecimal = DataType(rawValue: 0xf6)
        
        /// Implemented by ProtocolBinary::MYSQL_TYPE_ENUM
        public static let `enum` = DataType(rawValue: 0xf7)
        
        /// Implemented by ProtocolBinary::MYSQL_TYPE_SET
        public static let set = DataType(rawValue: 0xf8)
        
        /// Implemented by ProtocolBinary::MYSQL_TYPE_TINY_BLOB
        public static let tinyBlob = DataType(rawValue: 0xf9)
        
        /// Implemented by ProtocolBinary::MYSQL_TYPE_MEDIUM_BLOB
        public static let mediumBlob = DataType(rawValue: 0xfa)
        
        /// Implemented by ProtocolBinary::MYSQL_TYPE_LONG_BLOB
        public static let longBlob = DataType(rawValue: 0xfb)
        
        /// Implemented by ProtocolBinary::MYSQL_TYPE_BLOB
        public static let blob = DataType(rawValue: 0xfc)
        
        /// Implemented by ProtocolBinary::MYSQL_TYPE_VAR_STRING
        public static let varString = DataType(rawValue: 0xfd)
        
        /// Implemented by ProtocolBinary::MYSQL_TYPE_STRING
        public static let string = DataType(rawValue: 0xfe)
        
        /// Implemented by ProtocolBinary::MYSQL_TYPE_GEOMETRY
        public static let geometry = DataType(rawValue: 0xff)
        
        /// Length that this type encodes to. If `nil`, the encoded
        /// value is prefixed by a length-encoded integer.
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
                fatalError("Unsupported type: \(self)")
            }
            return length
        }
        
        /// The raw byte.
        public let rawValue: UInt8
        
        /// Creates a new `MySQLColumnType`.
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
