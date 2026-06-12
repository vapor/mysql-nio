@usableFromInline
struct ServerStatusFlags: OptionSet, Sendable {
    @usableFromInline
    let rawValue: UInt16

    @usableFromInline
    init(rawValue: UInt16) {
        self.rawValue = rawValue
    }

    /// Is raised when a multi-statement transaction has been started,
    /// either explicitly, by means of BEGIN or COMMIT AND CHAIN,
    /// or implicitly, by the first transactional statement, when autocommit=off.
    static let serverStatusInTrans = Self(rawValue: 1)
    /// Autocommit mode is set.
    static let serverStatusAutocommit = Self(rawValue: 2)
    /// More results exists (more packets will follow).
    static let serverMoreResultsExists = Self(rawValue: 8)
    /// Set if [EXPLAIN](https://mariadb.com/docs/server/reference/sql-statements/administrative-sql-statements/analyze-and-explain-statements/explain) would've shown Range checked for each record.
    static let serverQueryNoGoodIndexUsed = Self(rawValue: 16)
    /// The query did not use an index.
    static let serverQueryNoIndexUsed = Self(rawValue: 32)
    /// The server was able to fulfill the clients request and opened a read-only non-scrollable cursor for a query.
    ///
    /// This flag comes in reply to COM_STMT_EXECUTE and COM_STMT_FETCH commands.
    /// Used by Binary Protocol Resultset to signal that COM_STMT_FETCH must be used to fetch the row-data.
    static let serverStatusCursorExists = Self(rawValue: 64)
    /// This flag is sent when a read-only cursor is exhausted, in reply to COM_STMT_FETCH command.
    static let serverStatusLastRowSent = Self(rawValue: 128)
    /// Database has been dropped.
    static let serverStatusDBDropped = Self(rawValue: 1 << 8)
    /// Current escape mode is "no backslash escape".
    static let serverStatusNoBackslashEscapes = Self(rawValue: 1 << 9)
    /// Sent to the client if after a prepared statement reprepare we discovered that the new statement returns a different number of result set columns.
    static let serverStatusMetadataChanged = Self(rawValue: 1 << 10)
    /// The query was slower than [long_query_time](https://mariadb.com/docs/server/server-management/variables-and-modes/server-system-variables#long_query_time).
    static let serverQueryWasSlow = Self(rawValue: 1 << 11)
    /// This result set contains stored procedure output parameter.
    static let serverPsOutParams = Self(rawValue: 1 << 12)
    /// Set at the same time as SERVER_STATUS_IN_TRANS if the started multi-statement transaction is a read-only transaction.
    ///
    /// Cleared when the transaction commits or aborts.
    /// Since this flag is sent to clients in OK and EOF packets,
    /// the flag indicates the transaction status at the end of command execution.
    static let serverStatusInTransReadonly = Self(rawValue: 1 << 13)
    /// This status flag, when on, implies that one of the state information has changed on the server because of the execution of the last statement.
    ///
    /// See [session change type](https://mariadb.com/docs/server/reference/clientserver-protocol/4-server-response-packets/ok_packet#session-change-type) for more information.
    static let serverSessionStateChanged = Self(rawValue: 1 << 14)
}
