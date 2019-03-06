/// Table 14.4 Column Types
public struct MySQLBinaryDataType: RawRepresentable {
    /// Implemented by ProtocolBinary::MYSQL_TYPE_DECIMAL
    public static let MYSQL_TYPE_DECIMAL = MySQLBinaryDataType(rawValue: 0x00)
    
    /// Implemented by ProtocolBinary::MYSQL_TYPE_TINY
    public static let MYSQL_TYPE_TINY = MySQLBinaryDataType(rawValue: 0x01)
    
    /// Implemented by ProtocolBinary::MYSQL_TYPE_SHORT
    public static let MYSQL_TYPE_SHORT = MySQLBinaryDataType(rawValue: 0x02)
    
    /// Implemented by ProtocolBinary::MYSQL_TYPE_LONG
    public static let MYSQL_TYPE_LONG = MySQLBinaryDataType(rawValue: 0x03)
    
    /// Implemented by ProtocolBinary::MYSQL_TYPE_FLOAT
    public static let MYSQL_TYPE_FLOAT = MySQLBinaryDataType(rawValue: 0x04)
    
    /// Implemented by ProtocolBinary::MYSQL_TYPE_DOUBLE
    public static let MYSQL_TYPE_DOUBLE = MySQLBinaryDataType(rawValue: 0x05)
    
    /// Implemented by ProtocolBinary::MYSQL_TYPE_NULL
    public static let MYSQL_TYPE_NULL = MySQLBinaryDataType(rawValue: 0x06)
    
    /// Implemented by ProtocolBinary::MYSQL_TYPE_TIMESTAMP
    public static let MYSQL_TYPE_TIMESTAMP = MySQLBinaryDataType(rawValue: 0x07)
    
    /// Implemented by ProtocolBinary::MYSQL_TYPE_LONGLONG
    public static let MYSQL_TYPE_LONGLONG = MySQLBinaryDataType(rawValue: 0x08)
    
    /// Implemented by ProtocolBinary::MYSQL_TYPE_INT24
    public static let MYSQL_TYPE_INT24 = MySQLBinaryDataType(rawValue: 0x09)
    
    /// Implemented by ProtocolBinary::MYSQL_TYPE_DATE
    public static let MYSQL_TYPE_DATE = MySQLBinaryDataType(rawValue: 0x0a)
    
    /// Implemented by ProtocolBinary::MYSQL_TYPE_TIME
    public static let MYSQL_TYPE_TIME = MySQLBinaryDataType(rawValue: 0x0b)
    
    /// Implemented by ProtocolBinary::MYSQL_TYPE_DATETIME
    public static let MYSQL_TYPE_DATETIME = MySQLBinaryDataType(rawValue: 0x0c)
    
    /// Implemented by ProtocolBinary::MYSQL_TYPE_YEAR
    public static let MYSQL_TYPE_YEAR = MySQLBinaryDataType(rawValue: 0x0d)
    
    /// see Protocol::MYSQL_TYPE_DATE
    public static let MYSQL_TYPE_NEWDATE = MySQLBinaryDataType(rawValue: 0x0e)
    
    /// Implemented by ProtocolBinary::MYSQL_TYPE_VARCHAR
    public static let MYSQL_TYPE_VARCHAR = MySQLBinaryDataType(rawValue: 0x0f)
    
    /// Implemented by ProtocolBinary::MYSQL_TYPE_BIT
    public static let MYSQL_TYPE_BIT = MySQLBinaryDataType(rawValue: 0x10)
    
    /// see Protocol::MYSQL_TYPE_TIMESTAMP
    public static let MYSQL_TYPE_TIMESTAMP2 = MySQLBinaryDataType(rawValue: 0x11)
    
    /// see Protocol::MYSQL_TYPE_DATETIME
    public static let MYSQL_TYPE_DATETIME2 = MySQLBinaryDataType(rawValue: 0x12)
    
    /// see Protocol::MYSQL_TYPE_TIME
    public static let MYSQL_TYPE_TIME2 = MySQLBinaryDataType(rawValue: 0x13)
    
    /// Implemented by ProtocolBinary::MYSQL_TYPE_JSON
    public static let MYSQL_TYPE_JSON = MySQLBinaryDataType(rawValue: 0xf5)
    
    /// Implemented by ProtocolBinary::MYSQL_TYPE_NEWDECIMAL
    public static let MYSQL_TYPE_NEWDECIMAL = MySQLBinaryDataType(rawValue: 0xf6)
    
    /// Implemented by ProtocolBinary::MYSQL_TYPE_ENUM
    public static let MYSQL_TYPE_ENUM = MySQLBinaryDataType(rawValue: 0xf7)
    
    /// Implemented by ProtocolBinary::MYSQL_TYPE_SET
    public static let MYSQL_TYPE_SET = MySQLBinaryDataType(rawValue: 0xf8)
    
    /// Implemented by ProtocolBinary::MYSQL_TYPE_TINY_BLOB
    public static let MYSQL_TYPE_TINY_BLOB = MySQLBinaryDataType(rawValue: 0xf9)
    
    /// Implemented by ProtocolBinary::MYSQL_TYPE_MEDIUM_BLOB
    public static let MYSQL_TYPE_MEDIUM_BLOB = MySQLBinaryDataType(rawValue: 0xfa)
    
    /// Implemented by ProtocolBinary::MYSQL_TYPE_LONG_BLOB
    public static let MYSQL_TYPE_LONG_BLOB = MySQLBinaryDataType(rawValue: 0xfb)
    
    /// Implemented by ProtocolBinary::MYSQL_TYPE_BLOB
    public static let MYSQL_TYPE_BLOB = MySQLBinaryDataType(rawValue: 0xfc)
    
    /// Implemented by ProtocolBinary::MYSQL_TYPE_VAR_STRING
    public static let MYSQL_TYPE_VAR_STRING = MySQLBinaryDataType(rawValue: 0xfd)
    
    /// Implemented by ProtocolBinary::MYSQL_TYPE_STRING
    public static let MYSQL_TYPE_STRING = MySQLBinaryDataType(rawValue: 0xfe)
    
    public static let MYSQL_TYPE_GEOMETRY = MySQLBinaryDataType(rawValue: 0xff)
    
    /// The raw byte.
    public let rawValue: UInt8
    
    /// Creates a new `MySQLColumnType`.
    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }
}
