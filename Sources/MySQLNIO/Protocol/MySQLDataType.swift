/// The format the MySQL types are encoded in on the wire.
///
/// Currently there are two wire formats supported:
///  - binary
///  - text
public enum MySQLFormat: Sendable {
    case binary
    case text
}

extension MySQLFormat: CustomStringConvertible {
    public var description: String {
        switch self {
        case .binary: "binary"
        case .text: "text"
        }
    }
}

/// The raw wire-level type of a MySQL value.
///
/// These are all of the possible types a given value might have, from MySQL's perspective.
/// When the binary protocol encoding is used, they also describe a value's wire format;
/// for the text protocol encoding, they act as type affinities describing how best to interpret a given value.
///
/// > Note: Several of the type codes listed here are considered internal to MySQL.
/// > These types are implementation details of the server's internal storage formats;
/// > most of them are either "new" versions of old types or vice versa.
/// > In both cases, the server is expected to translate between the "internal" versions and the "normal" ones transparently in both directions;
/// > we include limited handling of the internal ones here in order to be resilient against badly behaved servers.
/// >
/// > There are a few "internal" types which are _not_ alternate versions of other types;
/// > these are commented out here, as they can not be sensibly handled and should never be used.
public struct MySQLDataType: RawRepresentable, Sendable, Hashable, CustomStringConvertible {
    // MARK: - Integers

    /// - term **MySQL name**: `MYSQL_TYPE_TINY`
    public static var tinyint: Self { .init(rawValue: 1) }
    /// - term **MySQL name**: `MYSQL_TYPE_SHORT`
    public static var smallint: Self { .init(rawValue: 2) }
    /// - term **MySQL name**: `MYSQL_TYPE_INT24`
    public static var mediumint: Self { .init(rawValue: 9) }
    /// - term **MySQL name**: `MYSQL_TYPE_LONG`
    public static var integer: Self { .init(rawValue: 3) }
    /// - term **MySQL name**: `MYSQL_TYPE_LONGLONG`
    public static var bigint: Self { .init(rawValue: 8) }

    // MARK: Decimals

    /// - term **MySQL name**: `MYSQL_TYPE_FLOAT`
    public static var float: Self { .init(rawValue: 4) }
    /// - term **MySQL name**: `MYSQL_TYPE_DOUBLE`
    public static var double: Self { .init(rawValue: 5) }
    /// Used for both `DECIMAL` and `NUMERIC`.
    /// - term **MySQL name**: `MYSQL_TYPE_DECIMAL`
    public static var decimal: Self { .init(rawValue: 0) }

    // MARK: Temporal

    /// - term **MySQL name**: `MYSQL_TYPE_TIMESTAMP`
    public static var timestamp: Self { .init(rawValue: 7) }
    /// - term **MySQL name**: `MYSQL_TYPE_DATE`
    public static var date: Self { .init(rawValue: 10) }
    /// - term **MySQL name**: `MYSQL_TYPE_TIME`
    public static var time: Self { .init(rawValue: 11) }
    /// - term **MySQL name**: `MYSQL_TYPE_DATETIME`
    public static var datetime: Self { .init(rawValue: 12) }
    /// - term **MySQL name**: `MYSQL_TYPE_YEAR`
    public static var year: Self { .init(rawValue: 13) }

    // MARK: Unstructured

    /// - term **MySQL name**: `MYSQL_TYPE_BIT`
    public static var bit: Self { .init(rawValue: 16) }
    /// Used for both `CHAR` and `BINARY`.
    /// - term **MySQL name**: `MYSQL_TYPE_STRING`
    public static var char: Self { .init(rawValue: 254) }
    /// Used for both `VARCHAR` and `VARBINARY`.
    /// - term **MySQL name**: `MYSQL_TYPE_VARCHAR`
    public static var varchar: Self { .init(rawValue: 15) }
    /// Used for both `TINYBLOB` and `TINYTEXT`.
    /// - term **MySQL name**: `MYSQL_TYPE_TINY_BLOB`
    public static var tinyblob: Self { .init(rawValue: 249) }
    /// Used for both `BLOB` and `TEXT`.
    /// - term **MySQL name**: `MYSQL_TYPE_BLOB`
    public static var blob: Self { .init(rawValue: 250) }
    /// Used for both `MEDIUMBLOB` and `MEDIUMTEXT`.
    /// - term **MySQL name**: `MYSQL_TYPE_MEDIUM_BLOB`
    public static var mediumblob: Self { .init(rawValue: 251) }
    /// Used for both `LONGBLOB` and `LONGTEXT`.
    /// - term **MySQL name**: `MYSQL_TYPE_LONG_BLOB`
    public static var longblob: Self { .init(rawValue: 252) }

    // MARK: Complex

    /// - term **MySQL name**: `MYSQL_TYPE_JSON`
    public static var json: Self { .init(rawValue: 245) }
    /// - term **MySQL name**: `MYSQL_TYPE_ENUM`
    public static var `enum`: Self { .init(rawValue: 247) }
    /// - term **MySQL name**: `MYSQL_TYPE_SET`
    public static var set: Self { .init(rawValue: 248) }
    /// - term **MySQL name**: `MYSQL_TYPE_GEOMETRY`
    public static var geometry: Self { .init(rawValue: 255) }

    // MARK: Meta

    /// An otherwise untyped `NULL` value.
    ///
    /// Used when convenient as an alternative to ``unknown`` for known-`NULL`s.
    ///
    /// - term **MySQL name**: `MYSQL_TYPE_NULL`
    public static var null: Self { .init(rawValue: 6) }

    /// A value with unknown or otherwise indeterminate type.
    ///
    /// Used internally by MySQL, and also internally by this package, to represent a
    /// parameter value having no explicit type. Using it in the wire protocol is a
    /// protocol violation.
    ///
    /// - term **MySQL name**: `MYSQL_TYPE_INVALID`
    public static var unknown: Self { .init(rawValue: 243) }

    // MARK: Internal

    /// - term **MySQL name**: `MYSQL_TYPE_NEWDATE`    (replaces `MYSQL_TYPE_DATE` internally to MySQL)
    static var _newdate: Self { .init(rawValue: 14) }
    /// - term **MySQL name**: `MYSQL_TYPE_TIMESTAMP2` (replaces `MYSQL_TYPE_TIMESTAMP` internally to MySQL)
    static var _timestamp2: Self { .init(rawValue: 17) }
    /// - term **MySQL name**: `MYSQL_TYPE_DATETIME2`  (replaces `MYSQL_TYPE_DATETIME` internally to MySQL)
    static var _datetime2: Self { .init(rawValue: 18) }
    /// - term **MySQL name**: `MYSQL_TYPE_TIME2`      (replaces `MYSQL_TYPE_TIME` internally to MySQL)
    static var _time2: Self { .init(rawValue: 19) }
    /// - term **MySQL name**: `MYSQL_TYPE_NEWDECIMAL` (replaces `MYSQL_TYPE_DECIMAL` internally to MySQL)
    static var _newdecimal: Self { .init(rawValue: 246) }
    /// - term **MySQL name**: `MYSQL_TYPE_VAR_STRING` (replaced by `MYSQL_TYPE_VARCHAR` internally to MySQL)
    static var _varstring: Self { .init(rawValue: 253) }

    //static var _typedArray:     Self { .init(rawValue:  20) } // `MYSQL_TYPE_TYPED_ARRAY` - internal implementation detail of replication
    //static var _bool:           Self { .init(rawValue: 244) } // `MYSQL_TYPE_BOOL`        - defined but unimplemented, treated like MYSQL_TYPE_INVALID

    /// The raw data type code recognized by MySQL.
    public let rawValue: UInt8

    public init(rawValue: UInt8) { self.rawValue = rawValue }

    /// Returns the known SQL name, if one exists.
    ///
    /// > Note: This only supports a limited subset of all MySQL types and is meant for convenience only.
    ///
    /// This list was manually generated.
    public var knownSQLName: String? {
        switch self {
        case .tinyint: "TINYINT"
        case .smallint: "SMALLINT"
        case .mediumint: "MEDIUMINT"
        case .integer: "INT"
        case .bigint: "BIGINT"
        case .float: "FLOAT"
        case .double: "DOUBLE"
        case .decimal: "DECIMAL"
        case .timestamp: "TIMESTAMP"
        case .date: "DATE"
        case .time: "TIME"
        case .datetime: "DATETIME"
        case .year: "YEAR"
        case .bit: "BIT"
        case .char: "CHAR"
        case .varchar: "VARCHAR"
        case .tinyblob: "TINYBLOB"
        case .blob: "BLOB"
        case .mediumblob: "MEDIUMBLOB"
        case .longblob: "LONGBLOB"
        case .json: "JSON"
        case .enum: "ENUM"
        case .set: "SET"
        case .geometry: "GEOMETRY"
        case .null: "<NULL>"
        case .unknown: "?INVALID?"
        case ._newdate: "_NEWDATE"
        case ._timestamp2: "_TIMESTAMP2"
        case ._datetime2: "_DATETIME2"
        case ._time2: "_TIME2"
        case ._newdecimal: "_NEWDECIMAL"
        case ._varstring: "_VARSTRING"
        case .init(rawValue: 20): "_typedarray"
        case .init(rawValue: 244): "_bool"
        default: nil
        }
    }

    // See `CustomStringConvertible.description`.
    public var description: String {
        self.knownSQLName ?? "<unknown(\(self.rawValue))>"
    }
}
