/// MySQL server status flags
///
/// These flags are reported by the server in `OK_Packet`s, including those with the EOF identifier byte.
/// If the command to which the OK packet is responding affected any of these flags, the flags represent
/// the state _after_ the command's completion.
struct MySQLServerStatusFlags: OptionSet {
    /// See ``RawRepresentable/rawValue``.
    let rawValue: UInt16
    
    /// See ``OptionSet/init(rawValue:)``.
    init(rawValue: UInt16) { self.rawValue = rawValue }
    
    /// An uncommitted transaction is active
    ///
    /// If set after being previously unset, the most recent command caused a non-autocommit transaction to
    /// begin, either implicitly in non-autocommit mode or by an explicit begin command. The transaction remains
    /// active as long as this flag remains set.
    ///
    /// > MySQL Name: `SERVER_STATUS_IN_TRANS`
    static var inTransaction: Self { .init(rawValue: 1 << 0) }
    
    /// Flags whether autocommit is enabled.
    ///
    /// Note that even if this flag is set, the ``inTransaction`` flag may also be set; autocommit only takes effect
    /// when ``inTransaction`` is unset.
    ///
    /// > MySQL Name: `SERVER_STATUS_AUTOCOMMIT`
    static var autocommitEnabled: Self { .init(rawValue: 1 << 1) }
    
    // Bit 2 not used
    
    /// An additional result set is pending
    ///
    /// If set, the most recent query-related command returned multiple result sets, this packet signals the
    /// completion of one result set, _and_ at least one additional result set is about to be sent.
    ///
    /// > MySQL Name: `SERVER_MORE_RESULTS_EXISTS`
    static var resultsetPending: Self { .init(rawValue: 1 << 3) }
    
    /// No ideal indexes were found for a query
    ///
    /// If set, the query command just completed found no "good" indexes to use. (What "good" means does not
    /// seem to be particularly well-defined even by MySQL itself.)
    ///
    /// > MySQL Name: `SERVER_QUERY_NO_GOOD_INDEX_USED`
    static var queryUsedNoGoodIndex: Self { .init(rawValue: 1 << 4) }
    
    /// A query did not use any indexes
    ///
    /// If set, the query command just completed made use of no indexes at all.
    ///
    /// > MySQL Name: `SERVER_QUERY_NO_INDEX_USED`
    static var queryUsedNoIndex: Self { .init(rawValue: 1 << 5) }
    
    /// A cursor is open
    ///
    /// A read-only non-scrollable cursor has been successfully opened by the last `COM_STMT_EXECUTE` command.
    /// The `COM_STMT_FETCH` command must be used to retrieve row data.
    ///
    /// > MySQL Name: `SERVER_STATUS_CURSOR_EXISTS`
    static var cursorOpened: Self { .init(rawValue: 1 << 6) }
    
    /// There are no more rows for a cursor
    ///
    /// Appears only in replies to fetch commands, signaling that the cursor has no additional rows to return.
    ///
    /// > MySQL Name: `SERVER_STATUS_LAST_ROW_SENT`
    static var endOfCursor: Self { .init(rawValue: 1 << 7) }
    
    /// A database has been dropped
    ///
    /// The command this packet signals completion of dropped a database.
    ///
    /// > MySQL Name: `SERVER_STATUS_DB_DROPPED`
    static var databaseDropped: Self { .init(rawValue: 1 << 8) }
    
    /// The `NO_BACKSLASH_ESCAPES` SQL mode is in effect.
    ///
    /// > MySQL Name: `SERVER_STATUS_NO_BACKSLASH_ESCAPES`
    static var backslashEscapesDisabled: Self { .init(rawValue: 1 << 9) }
    
    /// Statement metadata changed
    ///
    /// A prepared statement was re-prepared, and its metadata was discovered to have changed in the process.
    /// This signals the need to use `RESULTSET_METADATA_FULL` in the next command for that statement.
    ///
    /// > MySQL Name: `SERVER_STATUS_METADATA_CHANGED`
    static var preparedStatementMetadataChanged: Self { .init(rawValue: 1 << 10) }
    
    /// A query was slow
    ///
    /// If set, the query command just completed was considered "slow" by the server.
    ///
    /// > MySQL Name: `SERVER_QUERY_WAS_SLOW`
    static var queryWasSlow: Self { .init(rawValue: 1 << 11) }
    
    /// A stored procedure had outputs
    ///
    /// If set, the next result set received in reply to a query command contains output parameters from the
    /// execution of a stored procedure.
    ///
    /// > MySQL Name: `SERVER_PS_OUT_PARAMS`
    static var outputParametersPending: Self { .init(rawValue: 1 << 12) }
    
    /// An uncommitted read-only transaction is active
    ///
    /// When set alongside ``inTransaction``, signals that the transaction is in read-only mode.
    ///
    /// > MySQL Name: `SERVER_STATUS_IN_TRANS_READONLY`
    static var inReadonlyTransaction: Self { .init(rawValue: 1 << 13) }
    
    /// Session state data changed
    ///
    /// Signals that one or more session tracking information records are included in this packet.
    ///
    /// > MySQL Name: `SERVER_SESSION_STATE_CHANGED`
    static var sessionStateInfoIncluded: Self { .init(rawValue: 1 << 14) }
    
    /// ANSI quoting is enabled (MariaDB only)
    ///
    /// > MariaDB Name: `SERVER_STATUS_ANSI_QUOTES`
    static var ansiQuotesEnabled: Self { .init(rawValue: 1 << 15) }
}
