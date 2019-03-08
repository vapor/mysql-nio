extension MySQLProtocol {
    /// Table 14.4 Column Types
    public struct DataType: RawRepresentable, Equatable, CustomStringConvertible {
        /// Implemented by ProtocolBinary::MYSQL_TYPE_DECIMAL
        public static let MYSQL_TYPE_DECIMAL = DataType(rawValue: 0x00)
        
        /// Implemented by ProtocolBinary::MYSQL_TYPE_TINY
        public static let MYSQL_TYPE_TINY = DataType(rawValue: 0x01)
        
        /// Implemented by ProtocolBinary::MYSQL_TYPE_SHORT
        public static let MYSQL_TYPE_SHORT = DataType(rawValue: 0x02)
        
        /// Implemented by ProtocolBinary::MYSQL_TYPE_LONG
        public static let MYSQL_TYPE_LONG = DataType(rawValue: 0x03)
        
        /// Implemented by ProtocolBinary::MYSQL_TYPE_FLOAT
        public static let MYSQL_TYPE_FLOAT = DataType(rawValue: 0x04)
        
        /// Implemented by ProtocolBinary::MYSQL_TYPE_DOUBLE
        public static let MYSQL_TYPE_DOUBLE = DataType(rawValue: 0x05)
        
        /// Implemented by ProtocolBinary::MYSQL_TYPE_NULL
        public static let MYSQL_TYPE_NULL = DataType(rawValue: 0x06)
        
        /// Implemented by ProtocolBinary::MYSQL_TYPE_TIMESTAMP
        public static let MYSQL_TYPE_TIMESTAMP = DataType(rawValue: 0x07)
        
        /// Implemented by ProtocolBinary::MYSQL_TYPE_LONGLONG
        public static let MYSQL_TYPE_LONGLONG = DataType(rawValue: 0x08)
        
        /// Implemented by ProtocolBinary::MYSQL_TYPE_INT24
        public static let MYSQL_TYPE_INT24 = DataType(rawValue: 0x09)
        
        /// Implemented by ProtocolBinary::MYSQL_TYPE_DATE
        public static let MYSQL_TYPE_DATE = DataType(rawValue: 0x0a)
        
        /// Implemented by ProtocolBinary::MYSQL_TYPE_TIME
        public static let MYSQL_TYPE_TIME = DataType(rawValue: 0x0b)
        
        /// Implemented by ProtocolBinary::MYSQL_TYPE_DATETIME
        public static let MYSQL_TYPE_DATETIME = DataType(rawValue: 0x0c)
        
        /// Implemented by ProtocolBinary::MYSQL_TYPE_YEAR
        public static let MYSQL_TYPE_YEAR = DataType(rawValue: 0x0d)
        
        /// see Protocol::MYSQL_TYPE_DATE
        public static let MYSQL_TYPE_NEWDATE = DataType(rawValue: 0x0e)
        
        /// Implemented by ProtocolBinary::MYSQL_TYPE_VARCHAR
        public static let MYSQL_TYPE_VARCHAR = DataType(rawValue: 0x0f)
        
        /// Implemented by ProtocolBinary::MYSQL_TYPE_BIT
        public static let MYSQL_TYPE_BIT = DataType(rawValue: 0x10)
        
        /// see Protocol::MYSQL_TYPE_TIMESTAMP
        public static let MYSQL_TYPE_TIMESTAMP2 = DataType(rawValue: 0x11)
        
        /// see Protocol::MYSQL_TYPE_DATETIME
        public static let MYSQL_TYPE_DATETIME2 = DataType(rawValue: 0x12)
        
        /// see Protocol::MYSQL_TYPE_TIME
        public static let MYSQL_TYPE_TIME2 = DataType(rawValue: 0x13)
        
        /// Implemented by ProtocolBinary::MYSQL_TYPE_JSON
        public static let MYSQL_TYPE_JSON = DataType(rawValue: 0xf5)
        
        /// Implemented by ProtocolBinary::MYSQL_TYPE_NEWDECIMAL
        public static let MYSQL_TYPE_NEWDECIMAL = DataType(rawValue: 0xf6)
        
        /// Implemented by ProtocolBinary::MYSQL_TYPE_ENUM
        public static let MYSQL_TYPE_ENUM = DataType(rawValue: 0xf7)
        
        /// Implemented by ProtocolBinary::MYSQL_TYPE_SET
        public static let MYSQL_TYPE_SET = DataType(rawValue: 0xf8)
        
        /// Implemented by ProtocolBinary::MYSQL_TYPE_TINY_BLOB
        public static let MYSQL_TYPE_TINY_BLOB = DataType(rawValue: 0xf9)
        
        /// Implemented by ProtocolBinary::MYSQL_TYPE_MEDIUM_BLOB
        public static let MYSQL_TYPE_MEDIUM_BLOB = DataType(rawValue: 0xfa)
        
        /// Implemented by ProtocolBinary::MYSQL_TYPE_LONG_BLOB
        public static let MYSQL_TYPE_LONG_BLOB = DataType(rawValue: 0xfb)
        
        /// Implemented by ProtocolBinary::MYSQL_TYPE_BLOB
        public static let MYSQL_TYPE_BLOB = DataType(rawValue: 0xfc)
        
        /// Implemented by ProtocolBinary::MYSQL_TYPE_VAR_STRING
        public static let MYSQL_TYPE_VAR_STRING = DataType(rawValue: 0xfd)
        
        /// Implemented by ProtocolBinary::MYSQL_TYPE_STRING
        public static let MYSQL_TYPE_STRING = DataType(rawValue: 0xfe)
        
        /// Implemented by ProtocolBinary::MYSQL_TYPE_GEOMETRY
        public static let MYSQL_TYPE_GEOMETRY = DataType(rawValue: 0xff)
        
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
            case .MYSQL_TYPE_DECIMAL: return "MYSQL_TYPE_DECIMAL"
            case .MYSQL_TYPE_TINY: return "MYSQL_TYPE_TINY"
            case .MYSQL_TYPE_SHORT: return "MYSQL_TYPE_SHORT"
            case .MYSQL_TYPE_LONG: return "MYSQL_TYPE_LONG"
            case .MYSQL_TYPE_FLOAT: return "MYSQL_TYPE_FLOAT"
            case .MYSQL_TYPE_DOUBLE: return "MYSQL_TYPE_DOUBLE"
            case .MYSQL_TYPE_NULL: return "MYSQL_TYPE_NULL"
            case .MYSQL_TYPE_TIMESTAMP: return "MYSQL_TYPE_TIMESTAMP"
            case .MYSQL_TYPE_LONGLONG: return "MYSQL_TYPE_LONGLONG"
            case .MYSQL_TYPE_INT24: return "MYSQL_TYPE_INT24"
            case .MYSQL_TYPE_DATE: return "MYSQL_TYPE_DATE"
            case .MYSQL_TYPE_TIME: return "MYSQL_TYPE_TIME"
            case .MYSQL_TYPE_DATETIME: return "MYSQL_TYPE_DATETIME"
            case .MYSQL_TYPE_YEAR: return "MYSQL_TYPE_YEAR"
            case .MYSQL_TYPE_NEWDATE: return "MYSQL_TYPE_NEWDATE"
            case .MYSQL_TYPE_VARCHAR: return "MYSQL_TYPE_VARCHAR"
            case .MYSQL_TYPE_BIT: return "MYSQL_TYPE_BIT"
            case .MYSQL_TYPE_TIMESTAMP2: return "MYSQL_TYPE_TIMESTAMP2"
            case .MYSQL_TYPE_DATETIME2: return "MYSQL_TYPE_DATETIME2"
            case .MYSQL_TYPE_TIME2: return "MYSQL_TYPE_TIME2"
            case .MYSQL_TYPE_JSON: return "MYSQL_TYPE_JSON"
            case .MYSQL_TYPE_NEWDECIMAL: return "MYSQL_TYPE_NEWDECIMAL"
            case .MYSQL_TYPE_ENUM: return "MYSQL_TYPE_ENUM"
            case .MYSQL_TYPE_SET: return "MYSQL_TYPE_SET"
            case .MYSQL_TYPE_TINY_BLOB: return "MYSQL_TYPE_TINY_BLOB"
            case .MYSQL_TYPE_MEDIUM_BLOB: return "MYSQL_TYPE_MEDIUM_BLOB"
            case .MYSQL_TYPE_LONG_BLOB: return "MYSQL_TYPE_LONG_BLOB"
            case .MYSQL_TYPE_BLOB: return "MYSQL_TYPE_BLOB"
            case .MYSQL_TYPE_VAR_STRING: return "MYSQL_TYPE_VAR_STRING"
            case .MYSQL_TYPE_STRING: return "MYSQL_TYPE_STRING"
            case .MYSQL_TYPE_GEOMETRY: return "MYSQL_TYPE_GEOMETRY"
            default: return "MYSQL_TYPE_UNKNOWN (\(self.rawValue))"
            }
        }
    }
}
