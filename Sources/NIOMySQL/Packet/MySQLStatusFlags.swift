/// The status flags are a bit-field.
///
/// https://dev.mysql.com/doc/internals/en/status-flags.html#packet-Protocol::StatusFlags
public struct MySQLStatusFlags: OptionSet, CustomStringConvertible {
    /// a transaction is active
    public static let SERVER_STATUS_IN_TRANS = MySQLStatusFlags(rawValue: 0x0001)
    
    /// auto-commit is enabled
    public static let SERVER_STATUS_AUTOCOMMIT = MySQLStatusFlags(rawValue: 0x0002)
    
    public static let SERVER_MORE_RESULTS_EXISTS = MySQLStatusFlags(rawValue: 0x0008)
    
    public static let SERVER_STATUS_NO_GOOD_INDEX_USED = MySQLStatusFlags(rawValue: 0x0010)
    
    public static let SERVER_STATUS_NO_INDEX_USED = MySQLStatusFlags(rawValue: 0x0020)
    
    /// Used by Binary Protocol Resultset to signal that
    /// COM_STMT_FETCH must be used to fetch the row-data.
    public static let SERVER_STATUS_CURSOR_EXISTS = MySQLStatusFlags(rawValue: 0x0040)
    
    public static let SERVER_STATUS_LAST_ROW_SENT = MySQLStatusFlags(rawValue: 0x0080)
    
    public static let SERVER_STATUS_DB_DROPPED = MySQLStatusFlags(rawValue: 0x0100)
    
    public static let SERVER_STATUS_NO_BACKSLASH_ESCAPES = MySQLStatusFlags(rawValue: 0x0200)
    
    public static let SERVER_STATUS_METADATA_CHANGED = MySQLStatusFlags(rawValue: 0x0400)
    
    public static let SERVER_QUERY_WAS_SLOW = MySQLStatusFlags(rawValue: 0x0800)
    
    public static let SERVER_PS_OUT_PARAMS = MySQLStatusFlags(rawValue: 0x1000)
    
    /// in a read-only transaction
    public static let SERVER_STATUS_IN_TRANS_READONLY = MySQLStatusFlags(rawValue: 0x2000)
    
    /// connection state information has changed
    public static let SERVER_SESSION_STATE_CHANGED = MySQLStatusFlags(rawValue: 0x4000)
    
    public static let all: [MySQLStatusFlags] = [
        .SERVER_STATUS_IN_TRANS,
        .SERVER_STATUS_AUTOCOMMIT,
        .SERVER_MORE_RESULTS_EXISTS,
        .SERVER_STATUS_NO_GOOD_INDEX_USED,
        .SERVER_STATUS_NO_INDEX_USED,
        .SERVER_STATUS_CURSOR_EXISTS,
        .SERVER_STATUS_LAST_ROW_SENT,
        .SERVER_STATUS_NO_BACKSLASH_ESCAPES,
        .SERVER_STATUS_METADATA_CHANGED,
        .SERVER_QUERY_WAS_SLOW,
        .SERVER_PS_OUT_PARAMS,
        .SERVER_STATUS_IN_TRANS_READONLY,
        .SERVER_SESSION_STATE_CHANGED
    ]
    
    public var name: String {
        switch self {
        case .SERVER_STATUS_IN_TRANS: return "SERVER_STATUS_IN_TRANS"
        case .SERVER_STATUS_AUTOCOMMIT: return "SERVER_STATUS_AUTOCOMMIT"
        case .SERVER_MORE_RESULTS_EXISTS: return "SERVER_MORE_RESULTS_EXISTS"
        case .SERVER_STATUS_NO_GOOD_INDEX_USED: return "SERVER_STATUS_NO_GOOD_INDEX_USED"
        case .SERVER_STATUS_NO_INDEX_USED: return "SERVER_STATUS_NO_INDEX_USED"
        case .SERVER_STATUS_CURSOR_EXISTS: return "SERVER_STATUS_CURSOR_EXISTS"
        case .SERVER_STATUS_LAST_ROW_SENT: return "SERVER_STATUS_LAST_ROW_SENT"
        case .SERVER_STATUS_NO_BACKSLASH_ESCAPES: return "SERVER_STATUS_NO_BACKSLASH_ESCAPES"
        case .SERVER_STATUS_METADATA_CHANGED: return "SERVER_STATUS_METADATA_CHANGED"
        case .SERVER_QUERY_WAS_SLOW: return "SERVER_QUERY_WAS_SLOW"
        case .SERVER_PS_OUT_PARAMS: return "SERVER_PS_OUT_PARAMS"
        case .SERVER_STATUS_IN_TRANS_READONLY: return "SERVER_STATUS_IN_TRANS_READONLY"
        case .SERVER_SESSION_STATE_CHANGED: return "SERVER_SESSION_STATE_CHANGED"
        default: return "UNKNOWN(\(self.rawValue))"
        }
    }
    
    public var description: String {
        return MySQLStatusFlags.all
            .filter { self.contains($0) }
            .map { $0.name }
            .description
    }
    
    /// The raw status value.
    public var rawValue: UInt16

    /// Create a new `MySQLStatusFlags` from raw value.
    public init(rawValue: UInt16) {
        self.rawValue = rawValue
    }
}
