extension MySQLProtocol {
    /// Partially documented by https://mariadb.com/kb/en/result-set-packets/#field-details-flag
    ///
    /// Value definitions taken from:
    /// - https://github.com/mysql/mysql-server/blob/5.7/include/mysql_com.h#L103-L139
    /// - https://github.com/mysql/mysql-server/blob/8.0/include/mysql_com.h#L153-L197
    struct ColumnFlags: OptionSet, CustomStringConvertible {
        // MARK: Flags
        
        /// The column has a `NOT NULL` constraint.
        static let NOT_NULL         = Self(rawValue: 1 <<  0)
        
        /// The column is the primary key of its table.
        static let PRI_KEY          = Self(rawValue: 1 <<  1)
        
        /// The column participates in a single-field `UNIQUE KEY`.
        static let UNIQUE_KEY       = Self(rawValue: 1 <<  2)
        
        /// The column participates in a key spanning mulitple fields.
        static let MULTIPLE_KEY     = Self(rawValue: 1 <<  3)
        
        /// The column is a `TINYBLOB`, `MEDIUMBLOB`, `BLOB`, or `LONGBLOB`.
        static let BLOB             = Self(rawValue: 1 <<  4)
        
        /// The column's value is unsigned if signedness is meaningful for the type.
        static let UNSIGNED         = Self(rawValue: 1 <<  5)
        
        /// The column has a numeric type with the `ZEROFILL` specifier.
        static let ZEROFILL         = Self(rawValue: 1 <<  6)
        
        /// The column is of string or blob type and has `BINARY` collation.
        static let BINARY           = Self(rawValue: 1 <<  7)
        
        /// The column has type `ENUM`.
        static let ENUM             = Self(rawValue: 1 <<  8)
        
        /// The column has the `AUTOINCREMENT` modifier.
        static let AUTO_INCREMENT   = Self(rawValue: 1 <<  9)
        
        /// The column has type `TIMESTAMP`.
        static let TIMESTAMP        = Self(rawValue: 1 << 10)
        
        /// The column has type `SET`.
        static let SET              = Self(rawValue: 1 << 11)
        
        /// The column has no default value.
        static let NO_DEFAULT_VALUE = Self(rawValue: 1 << 12)
        
        /// The column is set to `NOW()` when updated.
        static let ON_UPDATE_NOW    = Self(rawValue: 1 << 13)
        
        /// The column is of a numeric type (never set by server).
        static let NUM              = Self(rawValue: 1 << 15)
        
        // MARK: Implementation
        
        /// The raw column flags.
        var rawValue: UInt16
        
        /// Create a new `ColumnFlags` from the raw value.
        init(rawValue: UInt16) {
            self.rawValue = rawValue
        }

        /// The string representation of a single flag (multiple flags are treated as unknown).
        var name: String {
            switch self {
                case []: return ""
                case .NOT_NULL: return "NOT_NULL_FLAG"
                case .PRI_KEY: return "PRI_KEY_FLAG"
                case .UNIQUE_KEY: return "UNIQUE_KEY_FLAG"
                case .MULTIPLE_KEY: return "MULTIPLE_KEY_FLAG"
                case .BLOB: return "BLOB_FLAG"
                case .UNSIGNED: return "UNSIGNED_FLAG"
                case .ZEROFILL: return "ZEROFILL_FLAG"
                case .BINARY: return "BINARY_FLAG"
                case .ENUM: return "ENUM_FLAG"
                case .AUTO_INCREMENT: return "AUTO_INCREMENT_FLAG"
                case .TIMESTAMP: return "TIMESTAMP_FLAG"
                case .SET: return "SET_FLAG"
                case .NO_DEFAULT_VALUE: return "NO_DEFAULT_VALUE_FLAG"
                case .ON_UPDATE_NOW: return "ON_UPDATE_NOW_FLAG"
                case .NUM: return "NUM_FLAG"
                default: return "UNKNOWN(\(String(self.rawValue, radix: 16))"
            }
        }
        
        /// `CustomStringConvertible` conformance.
        var description: String {
            (0 ..< RawValue.bitWidth).map { .init(rawValue: 1 << $0) }.filter(self.contains(_:)).map(\.name).joined(separator: ", ")
        }
    }

}

extension MySQLProtocol.ColumnFlags {
    // MARK: `mysqld` internal column flags
    
    // Most of the internal flags require more than 16 bits to represent and thus are not actually expressible
    // by this type. These defintions are provided solely for completeness; they are not actually useful as written,
    // or at all, really, unless you're trying to incrementally port `mysqld` to Swift (I wish you luck).
    
    /// The column participates in some key.
    static let _INTERNAL_PART_KEY           = Self(rawValue: UInt16(1 << 14))
    /// The column is a group field.
    static let _INTERNAL_GROUP              = Self(rawValue: UInt16(1 << 15))
    /// The column was flagged as unique during yaccing.
    static let _INTERNAL_UNIQUE             = Self(rawValue: UInt16(1 << 16))
    /// The column was flagged as binary-comparable during yaccing.
    static let _INTERNAL_BINCMP             = Self(rawValue: UInt16(1 << 17))
    /// The column is being used to fetch fields in an item tree.
    static let _INTERNAL_GET_FIXED_FIELDS   = Self(rawValue: UInt16(1 << 18))
    /// The column is part of a parition function.
    static let _INTERNAL_FIELD_IN_PART_FUNC = Self(rawValue: UInt16(1 << 19))
    /// The column is part of a new index during alter table.
    static let _INTERNAL_FIELD_IN_ADD_INDEX = Self(rawValue: UInt16(1 << 20))
    /// The column is being renamed.
    static let _INTERNAL_FIELD_IS_RENAMED   = Self(rawValue: UInt16(1 << 21))
    /// The column has storage media 1.
    static let _INTERNAL_STORAGE_MEDIA_1    = Self(rawValue: UInt16(1 << 22))
    /// The column has storage media 2.
    static let _INTERNAL_STORAGE_MEDIA_2    = Self(rawValue: UInt16(1 << 23))
    /// The column has storage media 3.
    static let _INTERNAL_STORAGE_MEDIA_3    = Self(rawValue: UInt16(3 << 22))
    /// The column has column format 1.
    static let _INTERNAL_COLUMN_FORMAT_1    = Self(rawValue: UInt16(1 << 24))
    /// The column has column format 2.
    static let _INTERNAL_COLUMN_FORMAT_2    = Self(rawValue: UInt16(1 << 25))
    /// The column has column format 3.
    static let _INTERNAL_COLUMN_FORMAT_3    = Self(rawValue: UInt16(3 << 24))
    /// The column is being dropped.
    static let _INTERNAL_FIELD_IS_DROPPED   = Self(rawValue: UInt16(1 << 26))
    /// The column has been explcitly specified as `NULL`.
    static let _INTERNAL_EXPLICIT_NULL_FLAG = Self(rawValue: UInt16(1 << 27))
    /// The column is `SERIAL` (MySQL 5.7 only, unused in 8.0)
    static let _INTERNAL_SERIAL             = Self(rawValue: UInt16(1 << 28))
    /// The column is not loaded in a secondary engine (MySQL 8.0+)
    static let _INTERNAL_NOT_SECONDARY      = Self(rawValue: UInt16(1 << 29))
    /// The column has been marked invisible by the user.
    static let _INTERNAL_FIELD_IS_INVISIBLE = Self(rawValue: UInt16(1 << 30))
}
