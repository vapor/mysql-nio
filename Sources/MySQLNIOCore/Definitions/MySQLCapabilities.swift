/// The various capabilities a client and server may advertise to one another.
///
/// > Note: Many capability flag bits defined by the protocol are ignored or forced "always-on" here; these include
///   "client-only" flags like `CLIENT_IGNORE_SIGPIPE` which are specific to `libmysqlclient`and have no meaning to
///   this implementation, legacy flags which describe capabilities that are always available in the minimum supported
///   protocol version (such as `CLIENT_LONG_FLAG`), and so forth. These missing bits are _not_ an oversight; do not
///   go back and add them in the name of "completeness" or whatever.
struct MySQLCapabilities: OptionSet {
    /// See ``RawRepresentable/rawValue``.
    let rawValue: UInt64
    
    /// See ``OptionSet/init(rawValue:)``.
    init(rawValue: UInt64) {
        self.rawValue = rawValue
    }
    
    /// Create from the three-part split capability fields in a HandshakeV10 packet.
    init(rawValues firstWord: UInt16, _ secondWord: UInt16, _ extendedWord: UInt32) {
        self.init(rawValue: UInt64(extendedWord) << 32 | UInt64(secondWord) << 16 | UInt64(firstWord))
    }
    
    /// Create from the two-part split capability fields in an SSLRequest or HandshakeResponse41 packet.
    init(rawValues firstWord: UInt32, _ secondWord: UInt32) {
        self.init(rawValue: UInt64(secondWord) << 32 | UInt64(firstWord))
    }
    
    /// The first of the three split capability fields in a HandshakeV10 packet.
    var lowThird: UInt16 {
        .init(truncatingIfNeeded: self.rawValue)
    }
    
    /// The second of the three split capability fields in a HandshakeV10 packet.
    var midThird: UInt16 {
        .init(truncatingIfNeeded: self.rawValue >> 16)
    }

    /// The first of the two split capability fields in an SSLRequest or HandshakeResponse41 packet.
    var lowHalf: UInt32 {
        .init(truncatingIfNeeded: self.rawValue)
    }
    
    /// The last of the split capability fields in handshake and handshake response packets.
    var extendedHalf: UInt32 {
        .init(truncatingIfNeeded: self.rawValue >> 32)
    }
    
    /// The set of all obsolete or deprecated capability flags the wire protocol nonetheless requires clients
    /// to set in order to be considered valid by servers compatible with at least MySQL 5.7 (including MariaDB
    /// 10.2+, Percona 8+, and Aurora 2+).
    static var hardcodedProtocolCapabilities: MySQLCapabilities { [
        .longColumnFlags, .modernProtocol, .transactions, .reserved2, .multiStatementQueries,
    ] }
    
    /// The set of all capability flags a server MUST support to be compatible with this implementation. This
    /// set is deliberately chosen such that interoperability with MySQL 5.7 or later is always sufficient
    /// for compatibility with this package as well.
    static var requiredCapabilities: MySQLCapabilities {
        self.hardcodedProtocolCapabilities.union([
            // Required because we do not support old-style "short" EOF packets, found in the pre-5.7 protocol.
            .eofDeprecation,
        ])
    }
    
    /// The set of "global" (i.e. not user-configurable) capabilities supported by this package that servers are
    /// _not_ required to also support.
    static var supportedCapabilities: MySQLCapabilities { [
        .localFileLoading,
        .pluggableAuthentication,
        .connectionAttributes,
        .flexiblySizedAuthPluginData,
        .multipleTextResultsets,
        .multipleBinaryResultsets,
        .sessionStateTracking,
        .resultsetMetadataElision,
        //.mariadbAwkwardlyExtendedMetadata,
        .mariadbResultsetMetadataCaching,
    ] }
    
    /// The set of capabilites used as the initial client set for negotiation, not including any capabilities
    /// which may be enabled on a per-connection basis (such as ``tls`` or ``connectWithDatabase``).
    static var baselineClientCapabilities: MySQLCapabilities {
        .init().union(self.requiredCapabilities)
               .union(self.supportedCapabilities)
    }
    
    /// When set, marks the connection as **not** supporting MariaDB-specific protocol extensions.
    ///
    /// This capability is called `CLIENT_LONG_PASSWORD` by MySQL and Percona and is assumed to always
    /// be set (even if it isn't) by those implementations. MariaDB calls it `CLIENT_MYSQL` and uses its
    /// value to determine whether or not the first four bytes of the long fillers in the HandshakeV10
    /// and HandshakeResponse41 packets specify extended capabilities.
    ///
    /// > Note: MariaDB defined this use long before MySQL set aside the `CLIENT_CAPABILITY_EXTENSION`
    ///   bit for the same purpose; it is unknown whether future MySQL versions will place additional
    ///   capability flags in the same place that MariaDB does. MariaDB also recognizes the newer
    ///   flag but, like current versions of MySQL at the time of this writing, does not act on it.
    ///
    /// > MySQL Name: `CLIENT_LONG_PASSWORD`
    ///
    /// > MariaDB Name: `CLIENT_MYSQL`
    static var isNotMariaDB: MySQLCapabilities { .init(rawValue: 1 << 0) }
    
    /// When set, the "affected row count" field of EOF packets becomes a "found rows" count instead.
    ///
    /// "Affected" rows are those changed by an INSERT, UPDATE, or DELETE query. "Found" rows are those
    /// matching the query's criteria, whether updated or not.
    ///
    /// > MySQL Name: `CLIENT_FOUND_ROWS`
    static var returnFoundRows: MySQLCapabilities { .init(rawValue: 1 << 1) }
    
    /// Indicates support for longer column flags. Deprecated and has no effect on packets.
    /// Not skipped because we mimic `mysql` by sending it anyway.
    ///
    /// > MySQL Name: `CLIENT_LONG_FLAG`
    private static var longColumnFlags: MySQLCapabilities { .init(rawValue: 1 << 2) }
    
    /// Indicates handshake response is allowed to/does contain a database name.
    ///
    /// > MySQL Name: `CLIENT_CONNECT_WITH_DB`
    static var connectWithDatabase: MySQLCapabilities { .init(rawValue: 1 << 3) }
    
    // `CLIENT_NO_SCHEMA` skipped: deprecated, never set

    /// Designates use of the compression "wrapper" protocol.
    ///
    /// > MySQL Name: `CLIENT_COMPRESSION`
    static var compression: MySQLCapabilities { .init(rawValue: 1 << 5) }
    
    // `CLIENT_ODBC` skipped: deprecated
    
    /// Indicates client support for sending local files to the server via `LOAD DATA LOCAL INFILE`.
    ///
    /// > MySQL Name: `CLIENT_LOCAL_FILES`
    static var localFileLoading: MySQLCapabilities { .init(rawValue: 1 << 7) }
    
    /// Specifies that the SQL parser should ignore excess whitespace between function names and the opening
    /// parenthesis (`(`).
    ///
    /// > MySQL Name: `CLIENT_IGNORE_SPACE`
    static var ignoreExcessWhitespace: MySQLCapabilities { .init(rawValue: 1 << 8) }
    
    /// Specifies use of the protocol updates first introduced by MySQL 4.1. Always set.
    ///
    /// > MySQL Name: `CLIENT_PROTOCOL_41`
    static var modernProtocol: MySQLCapabilities { .init(rawValue: 1 << 9) }
    
    /// Designates the client as interactive. Determines which variable the server uses for idle timeout.
    ///
    /// > MySQL Name: `CLIENT_INTERACTIVE`
    static var interactivity: MySQLCapabilities { .init(rawValue: 1 << 10) }
    
    /// Indicates ability to handle TLS communications. When set by a client, also indicates intent to do so.
    ///
    /// It is invalid for a client to signal this capability in a `HandshakeResponse41` unless it sent an
    /// `SSLRequest` signaling the capability first. Likewise, a client must send only the full
    /// `HandshakeResponse41` if it does _not_ signal this capability. For legacy reasons, when an `SSLRequest`
    /// is sent first (e.g. for a TLS-enabled connection), servers ignore the capability flags specified by
    /// the later `HandshakeResponse41` packet, but clients must nonetheless always specify the same flags
    /// both times for compatibility.
    ///
    /// > MySQL Name: `CLIENT_SSL`
    static var tls: MySQLCapabilities { .init(rawValue: 1 << 11) }
    
    // `CLIENT_IGNORE_SIGPIPE` skipped: client-only
    
    /// Indicates support for transactions. Deprecated, always set.
    /// Not skipped because we mimic `mysql` by sending it anyway.
    ///
    /// > MySQL Name: `CLIENT_TRANSACTIONS`
    private static var transactions: MySQLCapabilities { .init(rawValue: 1 << 13) }
    
    // `CLIENT_RESERVED` skipped: deprecated
    
    /// The original flag for 4.1 auth. Deprecated. Previously called `CLIENT_SECURE_CONNECTION`.
    /// Not skipped because we mimic `mysql` by sending it anyway.
    ///
    /// > MySQL Name: `CLIENT_RESERVED2`
    private static var reserved2: MySQLCapabilities { .init(rawValue: 1 << 15) }
    
    /// Indicates the ability to send/receive multiple SQL statements in a single query command.
    /// Always set; has no effect since MySQL 5.5. Not skipped because we mimic `mysql` by
    /// sending it anyway.
    ///
    /// > MySQL Name: `CLIENT_MULTI_STATEMENTS`
    private static var multiStatementQueries: MySQLCapabilities { .init(rawValue: 1 << 16) }
    
    /// Indicates the ability to handle multiple query result sets when using the text protocol.
    ///
    /// > MySQL Name: `CLIENT_MULTI_RESULTS`
    static var multipleTextResultsets: MySQLCapabilities { .init(rawValue: 1 << 17) }
    
    /// Indicates the ability to handle multiple query result sets when using the binary protocol.
    ///
    /// > MySQL Name: `CLIENT_PS_MULTI_RESULTS`
    static var multipleBinaryResultsets: MySQLCapabilities { .init(rawValue: 1 << 18) }
    
    /// Indicates support for plugin-based authentication. Always set.
    ///
    /// > MySQL Name: `CLIENT_PLUGIN_AUTH`
    static var pluggableAuthentication: MySQLCapabilities { .init(rawValue: 1 << 19) }
    
    /// Indicates support for attaching arbitrary key-value pairs to connections.
    ///
    /// > MySQL Name: `CLIENT_CONNECT_ATTRS`
    static var connectionAttributes: MySQLCapabilities { .init(rawValue: 1 << 20) }

    /// Indicates support for authentication data of arbitrary length. Always set.
    ///
    /// > MySQL Name: `CLIENT_PLUGIN_AUTH_LENENC_CLIENT_DATA`
    static var flexiblySizedAuthPluginData: MySQLCapabilities { .init(rawValue: 1 << 21) }
    
    /// Indicates support for handling expired passwords.
    ///
    /// > MySQL Name: `CLIENT_CAN_HANDLE_EXPIRED_PASSWORDS`
    static var expiredPasswords: MySQLCapabilities { .init(rawValue: 1 << 22) }
    
    /// Indicates support for session tracking information.
    ///
    /// > MySQL Name: `CLIENT_SESSION_TRACK`
    static var sessionStateTracking: MySQLCapabilities { .init(rawValue: 1 << 23) }
    
    /// Indicates support for the EOF-less 5.7+ protocol
    ///
    /// > MySQL Name: `CLIENT_EOF_DEPRECATED`
    static var eofDeprecation: MySQLCapabilities { .init(rawValue: 1 << 24) }
    
    /// Indicates support for eliding column metadata from resultsets to save round-trips.
    ///
    /// Used only by MySQL 8; MariaDB provides ``mariadbResultsetMetadataCaching`` instead. Not present
    /// in MySQL 5.7.
    ///
    /// See also <doc:Optional-Metadata> for implementation details and a comparison of the MySQL
    /// and MariaDB versions of this functionality.
    ///
    /// > MySQL Name: `CLIENT_OPTIONAL_RESULTSET_METADATA`
    static var resultsetMetadataElision: MySQLCapabilities { .init(rawValue: 1 << 25) }
    
    /// Indicates use of the `zstd` algorithm instead of `deflate` when compression is in use.
    ///
    /// ``compression`` must also be set when this capability is used. Not present in MySQL 5.7 or MariaDB.
    ///
    /// > MySQL Name: `CLIENT_ZSTD_COMPRESSION_ALGORITHM`
    static var zstdCompression: MySQLCapabilities { .init(rawValue: 1 << 26) }

    /// Indicates support for attaching arbitrary key-value pairs to individual queries.
    ///
    /// Not present in MySQL 5.7 or MariaDB.
    ///
    /// > MySQL Name: `CLIENT_QUERY_ATTRIBUTES`
    static var queryAttributes: MySQLCapabilities { .init(rawValue: 1 << 27) }
    
    /// Indicates support for multi-factor authentication.
    ///
    /// Not present in MySQL 5.7 or MariaDB.
    ///
    /// > MySQL Name: `MULTI_FACTOR_AUTHENTICATION`
    static var multifactorAuthentication: MySQLCapabilities { .init(rawValue: 1 << 28) }
    
    /// Indicates the use of more than 32 bits worth of capability flags.
    ///
    /// Currently does nothing in MySQL.
    ///
    /// MariaDB gives this bit the alternate name `CLIENT_PROGRESS_OBSOLETE`, which is intended as a
    /// deprecated synonym for ``mariadbProgressIndicators``. Unfortunately, MariaDB's client library
    /// has at least two obvious bugs in its capability handling (verified present in MariaDB 11.1 at
    /// the time of this writing) whose effect is to force _any_ client implementation to set both
    /// flags before progress indicators will work.
    ///
    /// > MySQL Name: `CLIENT_CAPABILITY_EXTENSION`
    ///
    /// > MariaDB Name: `CLIENT_PROGRESS_OBSOLETE`
    static var capabilityExtension: MySQLCapabilities { .init(rawValue: 1 << 29) }
    
    // `CLIENT_SSL_VERIFY_SERVER_CERT` skipped: client-only
    // `CLIENT_REMEMBER_OPTIONS` skipped: client-only
    
    /// Indicates support for MariaDB's use of modified ERR packets as progress indicators.
    ///
    /// Not supported by this implementation at this time. Does not work unless the ``capabilityExtension``
    /// capability is also set, due to bugs in MariaDB's capability handling logic.
    ///
    /// > MariaDB Name: `MARIADB_CLIENT_PROGRESS`
    static var mariadbProgressIndicators: MySQLCapabilities { .init(rawValue: 1 << 32) }
    
    // `MARIADB_CLIENT_COM_MULTI`, aka `MARIADB_CLIENT_RESERVED1`, skipped: COM_MULTI is a removed feature
    
    /// Indicates support for MariaDB's `COM_STMT_BULK_EXECUTE` command.
    ///
    /// The bulk execute command is equivalent to executing `COM_STMT_EXECUTE` over and over with each
    /// given set of bound parameters, but only works for `INSERT` queries; this elides the various
    /// round trips which would come with the individual commands, especially if the query uses MariaDB's
    /// support for PostgreSQL's `RETURNING` clause.
    ///
    /// Not supported by this implementation at this time.
    ///
    /// > MariaDB Name: `MARIADB_STMT_BULK_OPERATIONS`
    static var mariadbBulkInserts: MySQLCapabilities { .init(rawValue: 1 << 34) }
    
    /// Indicates support for MariaDB's additional metadata information for certain types.
    ///
    /// Extended metadata is known to be provided for these types, depending on the MariaDB version:
    ///
    /// - `MYSQL_TYPE_STRING` columns of JSON type ("format = json") (MariaDB does not use `MYSQL_TYPE_JSON`)
    /// - `MYSQL_TYPE_BLOB` columns of INET4/6 and UUID type ("type = <name>")
    /// - `MYSQL_TYPE_GEOMETRY` columns ("type = <e.g., point>")
    ///
    /// Incorrectly referred to as `MARIADB_CLIENT_EXTENDED_TYPE_INFO` by the MariaDB documentation.
    ///
    /// > MariaDB Name: `MARIADB_CLIENT_EXTENDED_METADATA`
    static var mariadbAwkwardlyExtendedMetadata: MySQLCapabilities { .init(rawValue: 1 << 35) }
    
    /// Indicates support for MariaDB's ability to skip cacheable metadata.
    ///
    /// Used only by MariaDB; MySQL provides ``resultsetMetadataElision`` instead. Only present in
    /// MariaDB 10.6 or later.
    ///
    /// See also <doc:Optional-Metadata> for implementation details and a comparison of the MySQL
    /// and MariaDB versions of this functionality.
    ///
    /// > MariaDB Name: `MARIADB_CLIENT_CACHE_METADATA`
    static var mariadbResultsetMetadataCaching: MySQLCapabilities { .init(rawValue: 1 << 36) }
}


extension MySQLCapabilities {
    /// Determines whether either of the capabilities which signals the presence of a
    /// `metadata_follows` flag in packets which can potentially carry that flag is enabled.
    ///
    /// Effectively shorthand for checking whether one or the other of ``resultsetMetadataElision``
    /// (available only in MySQL 8+ servers) or ``mariadbResultsetMetadataCaching`` (available only in
    /// MariaDB 10.6+ servers) has been negotiated.
    ///
    /// > Note: It is not actually possible for both capabilities to be set at the same time, at least as of
    /// > the time of this writing, as one is specific to MySQL/Percona/Aurora and the other is specific to
    /// > MariaDB, but this logic does not waste time checking for that particular impossibility.
    var metadataFlagAvailable: Bool {
        !self.intersection([.resultsetMetadataElision, .mariadbResultsetMetadataCaching]).isEmpty
    }
}
