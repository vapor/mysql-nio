import NIOCore

/// A MySQL text or binary protocol value with type (possibly NULL) and data slice (possibly nil).
///
/// This type represents not only bound parameter values for executing prepared statements but also
/// MySQL 8's "query attributes" feature. It is also built from the combination of cached column
/// metadata and raw row data when decoding values from binary resultset rows.
///
/// > Note: We do not deal with marshalling between Swift and wire protocol representations here.
///   That logic goes elsewhere.
public struct MySQLProtocolValue: Sendable {
    /// The raw wire-level type of a MySQL value.
    ///
    /// These are all of the possible types a given value might have, from MySQL's perspective. When the
    /// binary protocol encoding is used, they also describe a value's wire format; for the text protocol
    /// encoding, they act as type affinities describing how best to interpret a given value.
    ///
    /// > Note: This type would be more properly called simply `Type`, but Swift already claims that name
    /// > for metatypes.
    ///
    /// > Note: Several of the type codes listed here are considered internal to MySQL. These types
    /// > are implementation details of the server's internal storage formats; most of them are either
    /// > "new" versions of old types or vice versa. In both cases, the server is expected to translate
    /// > between the "internal" versions and the "normal" ones transparently in both directions; we
    /// > include limited handling of the internal ones here in order to be resilient against badly
    /// > behaved servers.
    /// >
    /// > There are a few "internal" types which are _not_ alternate versions of other types; these are
    /// > commented out here, as they can not be sensibly handled and should never be used.
    public struct Format: RawRepresentable, Hashable, CustomStringConvertible, Sendable {
        // MARK: - Integers
        
        /// - term **MySQL name**: `MYSQL_TYPE_TINY`
        public static var tinyint:    Self { .init(rawValue:   1) }
        /// - term **MySQL name**: `MYSQL_TYPE_SHORT`
        public static var smallint:   Self { .init(rawValue:   2) }
        /// - term **MySQL name**: `MYSQL_TYPE_INT24`
        public static var mediumint:  Self { .init(rawValue:   9) }
        /// - term **MySQL name**: `MYSQL_TYPE_LONG`
        public static var integer:    Self { .init(rawValue:   3) }
        /// - term **MySQL name**: `MYSQL_TYPE_LONGLONG`
        public static var bigint:     Self { .init(rawValue:   8) }
        
        // MARK: Decimals
        
        /// - term **MySQL name**: `MYSQL_TYPE_FLOAT`
        public static var float:      Self { .init(rawValue:   4) }
        /// - term **MySQL name**: `MYSQL_TYPE_DOUBLE`
        public static var double:     Self { .init(rawValue:   5) }
        /// Used for both `DECIMAL` and `NUMERIC`.
        /// - term **MySQL name**: `MYSQL_TYPE_DECIMAL`
        public static var decimal:    Self { .init(rawValue:   0) }
        
        // MARK: Temporal
        
        /// - term **MySQL name**: `MYSQL_TYPE_TIMESTAMP`
        public static var timestamp:  Self { .init(rawValue:   7) }
        /// - term **MySQL name**: `MYSQL_TYPE_DATE`
        public static var date:       Self { .init(rawValue:  10) }
        /// - term **MySQL name**: `MYSQL_TYPE_TIME`
        public static var time:       Self { .init(rawValue:  11) }
        /// - term **MySQL name**: `MYSQL_TYPE_DATETIME`
        public static var datetime:   Self { .init(rawValue:  12) }
        /// - term **MySQL name**: `MYSQL_TYPE_YEAR`
        public static var year:       Self { .init(rawValue:  13) }
        
        // MARK: Unstructured
        
        /// - term **MySQL name**: `MYSQL_TYPE_BIT`
        public static var bit:        Self { .init(rawValue:  16) }
        /// Used for both `CHAR` and `BINARY`.
        /// - term **MySQL name**: `MYSQL_TYPE_STRING`
        public static var char:       Self { .init(rawValue: 254) }
        /// Used for both `VARCHAR` and `VARBINARY`.
        /// - term **MySQL name**: `MYSQL_TYPE_VARCHAR`
        public static var varchar:    Self { .init(rawValue:  15) }
        /// Used for both `TINYBLOB` and `TINYTEXT`.
        /// - term **MySQL name**: `MYSQL_TYPE_TINY_BLOB`
        public static var tinyblob:   Self { .init(rawValue: 249) }
        /// Used for both `BLOB` and `TEXT`.
        /// - term **MySQL name**: `MYSQL_TYPE_BLOB`
        public static var blob:       Self { .init(rawValue: 250) }
        /// Used for both `MEDIUMBLOB` and `MEDIUMTEXT`.
        /// - term **MySQL name**: `MYSQL_TYPE_MEDIUM_BLOB`
        public static var mediumblob: Self { .init(rawValue: 251) }
        /// Used for both `LONGBLOB` and `LONGTEXT`.
        /// - term **MySQL name**: `MYSQL_TYPE_LONG_BLOB`
        public static var longblob:   Self { .init(rawValue: 252) }
        
        // MARK: Complex
        
        /// - term **MySQL name**: `MYSQL_TYPE_JSON`
        public static var json:       Self { .init(rawValue: 245) }
        /// - term **MySQL name**: `MYSQL_TYPE_ENUM`
        public static var `enum`:     Self { .init(rawValue: 247) }
        /// - term **MySQL name**: `MYSQL_TYPE_SET`
        public static var set:        Self { .init(rawValue: 248) }
        /// - term **MySQL name**: `MYSQL_TYPE_GEOMETRY`
        public static var geometry:   Self { .init(rawValue: 255) }
        
        // MARK: Meta
        
        /// An otherwise untyped `NULL` value.
        ///
        /// Used when convenient as an alternative to ``unknown`` for known-`NULL`s.
        ///
        /// - term **MySQL name**: `MYSQL_TYPE_NULL`
        public static var null:       Self { .init(rawValue:   6) }

        /// A value with unknown or otherwise indeterminate type.
        ///
        /// Used internally by MySQL, and also internally by this package, to represent a
        /// parameter value having no explicit type. Using it in the wire protocol is a
        /// protocol violation.
        ///
        /// - term **MySQL name**: `MYSQL_TYPE_INVALID`
        public static var unknown:    Self { .init(rawValue: 243) }

        // MARK: Internal
        
        /// - term **MySQL name**: `MYSQL_TYPE_NEWDATE`    (replaces `MYSQL_TYPE_DATE` internally to MySQL)
        static var _newdate:          Self { .init(rawValue:  14) }
        /// - term **MySQL name**: `MYSQL_TYPE_TIMESTAMP2` (replaces `MYSQL_TYPE_TIMESTAMP` internally to MySQL)
        static var _timestamp2:       Self { .init(rawValue:  17) }
        /// - term **MySQL name**: `MYSQL_TYPE_DATETIME2`  (replaces `MYSQL_TYPE_DATETIME` internally to MySQL)
        static var _datetime2:        Self { .init(rawValue:  18) }
        /// - term **MySQL name**: `MYSQL_TYPE_TIME2`      (replaces `MYSQL_TYPE_TIME` internally to MySQL)
        static var _time2:            Self { .init(rawValue:  19) }
        /// - term **MySQL name**: `MYSQL_TYPE_NEWDECIMAL` (replaces `MYSQL_TYPE_DECIMAL` internally to MySQL)
        static var _newdecimal:       Self { .init(rawValue: 246) }
        /// - term **MySQL name**: `MYSQL_TYPE_VAR_STRING` (replaced by `MYSQL_TYPE_VARCHAR` internally to MySQL)
        static var _varstring:        Self { .init(rawValue: 253) }
        
        //static var _typedArray:     Self { .init(rawValue:  20) } // `MYSQL_TYPE_TYPED_ARRAY` - internal implementation detail of replication
        //static var _bool:           Self { .init(rawValue: 244) } // `MYSQL_TYPE_BOOL`        - defined but unimplemented, treated like MYSQL_TYPE_INVALID
        
        // MARK: -
        
        public var description: String {
            switch self {
            case .tinyint:             return "TINYINT"
            case .smallint:            return "SMALLINT"
            case .mediumint:           return "MEDIUMINT"
            case .integer:             return "INT"
            case .bigint:              return "BIGINT"
            case .float:               return "FLOAT"
            case .double:              return "DOUBLE"
            case .decimal:             return "DECIMAL"
            case .timestamp:           return "TIMESTAMP"
            case .date:                return "DATE"
            case .time:                return "TIME"
            case .datetime:            return "DATETIME"
            case .year:                return "YEAR"
            case .bit:                 return "BIT"
            case .char:                return "CHAR"
            case .varchar:             return "VARCHAR"
            case .tinyblob:            return "TINYBLOB"
            case .blob:                return "BLOB"
            case .mediumblob:          return "MEDIUMBLOB"
            case .longblob:            return "LONGBLOB"
            case .json:                return "JSON"
            case .enum:                return "ENUM"
            case .set:                 return "SET"
            case .geometry:            return "GEOMETRY"
            case .null:                return "<NULL>"
            case .unknown:             return "?INVALID?"
            case ._newdate:            return "_NEWDATE"
            case ._timestamp2:         return "_TIMESTAMP2"
            case ._datetime2:          return "_DATETIME2"
            case ._time2:              return "_TIME2"
            case ._newdecimal:         return "_NEWDECIMAL"
            case ._varstring:          return "_VARSTRING"
            case .init(rawValue: 20):  return "_typedarray"
            case .init(rawValue: 244): return "_bool"
            default:                   return "<unknown(\(self.rawValue))>"
            }
        }
        
        public let rawValue: UInt8
        public init(rawValue: UInt8) { self.rawValue = rawValue }
    }
    
    /// An underlying protocol encoding.
    enum Encoding: Hashable, CustomStringConvertible, Sendable {
        /// The "old" text protocol encoding - all values are either `NULL` or strings.
        case text
        
        /// The "efficient" binary protocol encoding - integers, floats, and temporal types are encoded directly.
        /// (Everything else is still a string.)
        case binary
        
        var description: String {
            self == .text ? "text" : "binary"
        }
    }
    
    /// The flags for the value.
    ///
    /// MySQL defines 30 bits worth of column flags (which is only 16 bits wide - this is not a mistake!).
    /// Only the first 14 bits are defined as far as the protocol is concerned. Of those, three are
    /// completely deprecated, five more do not mean what they say they do and have no useful semantics,
    /// and five of those that _are_ well-defined are also redundant or useless. Most of them are also
    /// mutually exclusive, with no enforcement whatsoever of those semantics. In the end, only one of
    /// the flags ends up having any actual use!
    ///
    /// ### "But what about <flag>?"
    ///
    /// - `PRI/UNIQUE/MUTLIPLE_KEY_FLAG`: These flags do not mean what they say to start with, and
    ///   are of no use to this implementation even if they did.
    /// - `NOT_NULL/AUTO_INCREMENT/NO_DEFAULT_VALUE_FLAG`: We don't provide client-generated table
    ///   descriptions or query parameter validation, so these likewise are useless.
    /// - `ZEROFILL_FLAG`: `ZEROFILL` is deprecated, and not helpful to this package in any case.
    /// - `BLOB_FLAG`: Means "column is \*BLOB, JSON, or GEOMETRY", which the format already expresses.
    /// - `ENUM/SET_FLAG`: Synonyms for `MYSQL_TYPE_ENUM/SET`.
    /// - `BINARY_FLAG`: In MySQL, this means "is DATE, TIME, DATETIME, or TIMESTAMP"; in MariaDB it
    ///   means "that, or BINARY or VARBINARY". The correct way to distinguish the latter from `CHAR`
    ///   and `VARCHAR` is to check if the field's character set (not collation!) is `binary`.
    /// - `TIMESTAMP/ON_UPDATE_NOW_FLAG`: These are deprecated, and aren't used by MySQL anymore.
    ///   `TIMESTAMP_FLAG` doesn't even mean "is timestamp", to add insult to injury.
    /// - `NUM_FLAG`: This is a client-only flag. The first-party MySQL C API library sets it for the
    ///   supposed "convenience" of calling code; it's just another nonspecific format indicator.
    public struct Flags: OptionSet, Hashable, CustomStringConvertible, Sendable {
        public let rawValue: UInt16
        public init(rawValue: UInt16) { self.rawValue = rawValue }
        
        /// Value should be interpreted as an unsigned number.
        ///
        /// This flag is only valid for values with an integer, floating-point, or fixed-point format.
        /// It is a protocol violation for it to be set
        ///
        /// - term **MySQL name**: `UNSIGNED_FLAG`
        public static var isUnsigned: Self     { .init(rawValue: 1 << 5) }
        
        public var description: String {
            ""
        }
    }

    /// Encapsulates the complete description of the value's actual wire representation.
    struct Metadata: Hashable, CustomStringConvertible, Sendable {
        /// The value's format.
        let format: Format
        
        /// The value's data encoding.
        let encoding: Encoding

        /// Returns the number of bytes that would be occupied by an encoded value with this metadata.
        /// Returns `nil` if the format and encoding result in a variable-length value. Returns `-1` if
        /// the type itself is not known.
        func dataSize() -> Int? {
            Self.dataSize(format: self.format, encoding: self.encoding)
        }
        
        /// Same as ``dataSize()``, but doesn't require an existing instance.
        static func dataSize(format: Format, encoding: Encoding) -> Int? {
            switch format {
            case .null: // NULL never takes up any bytes (the marker byte for text encoding is not counted here)
                return 0
            case .tinyint: // One-byte integer in binary encoding, string in text
                return encoding == .binary ? 1 : nil
            case .smallint: // Two-byte integer in binary encoding, string in text
                return encoding == .binary ? 2 : nil
            case .mediumint, .integer: // Four-byte integer in binary encoding, string in text
                return encoding == .binary ? 4 : nil
            case .bigint:  // Eight-byte integer in binary encoding, string in text
                return encoding == .binary ? 8 : nil
            case .float: // Raw Float (4-byte) bit pattern in binary encoding, string in text
                return encoding == .binary ? 4 : nil
            case .double: // Raw Double (8-byte) bit pattern in binary encoding, string in text
                return encoding == .binary ? 8 : nil
            case .decimal, ._newdecimal: // Always a string
                return nil
            case .timestamp,   .date,     .time,   .datetime,
                 ._timestamp2, ._newdate, ._time2, ._datetime2: // MySQLTime (w/ leading length byte) in binary encoding, string in text
                return nil
            case .year: // Two-byte integer in binary encoding, string in text
                return encoding == .binary ? 2 : nil
            case .bit, .char, .varchar, ._varstring: // Always a binary blob (interpreted as string if not BINARY_FLAG)
                return nil
            case .tinyblob, .blob, .mediumblob, .longblob: // Always a binary blob (interpreted as string if not BINARY_FLAG)
                return nil
            case .json: // Always a string
                return nil
            case .enum, .set: // Always a string
                return nil
            case .geometry: // Always a string
                return nil
            default: // Return invalid value for unknown types
                return -1
            }
        }
        
        var description: String {
            "\(self.encoding)(\(self.format))"
        }
    }
    
    /// The value's metadata.
    let metadata: Metadata
    
    /// The raw binary protocol data for the value. `nil` represents a SQL `NULL`; an empty buffer's meaning
    /// is format-dependent and is only valid for some formats.
    let data: ByteBuffer?
}
