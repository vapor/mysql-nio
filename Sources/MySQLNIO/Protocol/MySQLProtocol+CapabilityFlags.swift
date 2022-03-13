extension MySQLProtocol {
    /// The capability flags are used by the client and server to indicate which features they support and want to use.
    ///
    /// https://dev.mysql.com/doc/internals/en/capability-flags.html#packet-Protocol::CapabilityFlags
    /// https://mariadb.com/kb/en/connection/
    /// https://github.com/MariaDB/server/blob/10.9/include/mysql_com.h
    /// https://github.com/mysql/mysql-server/blob/8.0/include/mysql_com.h
    public struct CapabilityFlags: OptionSet, CustomStringConvertible {
        /// Use the improved version of Old Password Authentication.
        /// note: Assumed to be set since 4.1.1.
        /// important: MariaDB **unsets** this flag to signal the presence of extended capability flags
        public static let CLIENT_LONG_PASSWORD = CapabilityFlags(rawValue: 1 << 0)
        
        /// Send found rows instead of affected rows in `EOF_Packet`.
        public static let CLIENT_FOUND_ROWS = CapabilityFlags(rawValue: 1 << 1)
        
        /// Longer flags in `Protocol::ColumnDefinition320`.
        /// Server: Supports longer flags.
        /// Client: Expects longer flags.
        public static let CLIENT_LONG_FLAG = CapabilityFlags(rawValue: 1 << 2)
        
        /// Database (schema) name can be specified on connect in Handshake Response Packet.
        /// Server: Supports schema-name in Handshake Response Packet.
        /// Client: Handshake Response Packet contains a schema-name.
        public static let CLIENT_CONNECT_WITH_DB = CapabilityFlags(rawValue: 1 << 3)
        
        /// Server: Do not permit `database.table.column`.
        public static let CLIENT_NO_SCHEMA = CapabilityFlags(rawValue: 1 << 4)
        
        /// Compression protocol supported.
        /// Server: Supports compression.
        /// Client: Switches to Compression compressed protocol after successful authentication.
        public static let CLIENT_COMPRESS = CapabilityFlags(rawValue: 1 << 5)
        
        /// Special handling of ODBC behavior.
        /// note: No special behavior since 3.22.
        public static let CLIENT_ODBC = CapabilityFlags(rawValue: 1 << 6)
        
        /// Can use `LOAD DATA LOCAL`.
        /// Server: Enables the `LOCAL INFILE` request of `LOAD DATA|XML`.
        /// Client: Will handle `LOCAL INFILE` request.
        public static let CLIENT_LOCAL_FILES = CapabilityFlags(rawValue: 1 << 7)
        
        /// Server: Parser can ignore spaces before '('.
        /// Client: Let the parser ignore spaces before '('.
        public static let CLIENT_IGNORE_SPACE = CapabilityFlags(rawValue: 1 << 8)
        
        /// Server: Supports the 4.1 protocol.
        /// Client: Uses the 4.1 protocol.
        /// note: this value was `CLIENT_CHANGE_USER` in 3.22, unused in 4.0
        public static let CLIENT_PROTOCOL_41 = CapabilityFlags(rawValue: 1 << 9)
        
        /// `wait_timeout` versus `wait_interactive_timeout`.
        /// Server: Supports interactive and noninteractive clients.
        /// Client: Client is interactive.
        /// See `mysql_real_connect()`
        public static let CLIENT_INTERACTIVE = CapabilityFlags(rawValue: 1 << 10)
        
        /// Server: Supports SSL.
        /// Client: Switch to SSL after sending the capability-flags.
        public static let CLIENT_SSL = CapabilityFlags(rawValue: 1 << 11)
        
        /// Client: Do not issue `SIGPIPE` if network failures occur (`libmysqlclient` only).
        /// See `mysql_real_connect()`
        public static let CLIENT_IGNORE_SIGPIPE = CapabilityFlags(rawValue: 1 << 12)
        
        /// Server: Can send status flags in `EOF_Packet`.
        /// Client: Expects status flags in `EOF_Packet`.
        /// - Note: This flag is optional in 3.23, but always set by the server since 4.0.
        public static let CLIENT_TRANSACTIONS = CapabilityFlags(rawValue: 1 << 13)
        
        /// Unused.
        /// note: Was named `CLIENT_PROTOCOL_41` in 4.1.0.
        public static let CLIENT_RESERVED = CapabilityFlags(rawValue: 1 << 14)
        
        /// Server: Supports `Authentication::Native41`.
        /// Client: Supports `Authentication::Native41`.
        public static let CLIENT_SECURE_CONNECTION = CapabilityFlags(rawValue: 1 << 15)
        
        /// Server: Can handle multiple statements per `COM_QUERY` and `COM_STMT_PREPARE`.
        /// Client: May send multiple statements per `COM_QUERY` and `COM_STMT_PREPARE`.
        /// note: Was named `CLIENT_MULTI_QUERIES` in 4.1.0, renamed later.
        /// requires: `CLIENT_PROTOCOL_41`
        public static let CLIENT_MULTI_STATEMENTS = CapabilityFlags(rawValue: 1 << 16)
        
        /// Server: Can send multiple resultsets for `COM_QUERY`.
        /// Client: Can handle multiple resultsets for `COM_QUERY`.
        /// requires: `CLIENT_PROTOCOL_41`
        public static let CLIENT_MULTI_RESULTS = CapabilityFlags(rawValue: 1 << 17)
        
        /// Server: Can send multiple resultsets for `COM_STMT_EXECUTE`.
        /// Client: Can handle multiple resultsets for `COM_STMT_EXECUTE`.
        /// requires: `CLIENT_PROTOCOL_41`
        public static let CLIENT_PS_MULTI_RESULTS = CapabilityFlags(rawValue: 1 << 18)
        
        /// Server: Sends extra data in Initial Handshake Packet and supports the pluggable authentication protocol.
        /// Client: Supports authentication plugins.
        /// Requires: `CLIENT_PROTOCOL_41`
        public static let CLIENT_PLUGIN_AUTH = CapabilityFlags(rawValue: 1 << 19)
        
        /// Server: Permits connection attributes in `Protocol::HandshakeResponse41`.
        /// Client: Sends connection attributes in `Protocol::HandshakeResponse41`.
        public static let CLIENT_CONNECT_ATTRS = CapabilityFlags(rawValue: 1 << 20)
        
        /// Server: Understands length-encoded integer for auth response data in `Protocol::HandshakeResponse41`.
        /// Client: Length of auth response data in `Protocol::HandshakeResponse41` is a length-encoded integer.
        /// note: The flag was introduced in 5.6.6, but had the wrong value.
        public static let CLIENT_PLUGIN_AUTH_LENENC_CLIENT_DATA = CapabilityFlags(rawValue: 1 << 21)
        
        /// Server: Announces support for expired password extension.
        /// Client: Can handle expired passwords.
        /// https://dev.mysql.com/doc/internals/en/cs-sect-expired-password.html
        public static let CLIENT_CAN_HANDLE_EXPIRED_PASSWORDS = CapabilityFlags(rawValue: 1 << 22)
        
        /// Server: Can set `SERVER_SESSION_STATE_CHANGED` in the Status Flags and send session-state change data after a OK packet.
        /// Client: Expects the server to send sesson-state changes after a OK packet.
        public static let CLIENT_SESSION_TRACK = CapabilityFlags(rawValue: 1 << 23)
        
        /// Server: Can send OK after a Text Resultset.
        /// Client: Expects an OK (instead of EOF) after the resultset rows of a Text Resultset.
        /// To support `CLIENT_SESSION_TRACK`, additional information must be sent after all successful commands.
        /// Although the OK packet is extensible, the EOF packet is not due to the overlap of its bytes with the content of the Text Resultset Row.
        /// Therefore, the EOF packet in the Text Resultset is replaced with an OK packet. EOF packets are deprecated as of MySQL 5.7.5.
        public static let CLIENT_DEPRECATE_EOF = CapabilityFlags(rawValue: 1 << 24)
        
        // MARK: - Additional MySQL capabilities added in 8.0
        
        /// The client can handle optional metadata information in the resultset.
        static let CLIENT_OPTIONAL_RESULTSET_METADATA = CapabilityFlags(rawValue: 1 << 25)
        
        /// Server: Sets this flag when global variable protocol-compression-algorithms has zstd in its list of supported values.
        /// Client: Sets this flag when it is configured to use zstd compression method.
        static let CLIENT_ZSTD_COMPRESSION_ALGORITHM = CapabilityFlags(rawValue: 1 << 26)
        
        /// Server: Expects an optional part containing the query parameter set(s). Executes the query for each set of
        ///         parameters or returns an error if more than 1 set of parameters is sent and the server can't execute it.
        /// Client: Can send the optional part containing the query parameter set(s).
        static let CLIENT_QUERY_ATTRIBUTES = CapabilityFlags(rawValue: 1 << 27)
        
        /// Server: Sends AuthNextFactor packet after every nth factor authentication method succeeds, except the last factor authentication.
        /// Client: Reads AuthNextFactor packet sent by server and initiates next factor authentication method.
        static let MULTI_FACTOR_AUTHENTICATION = CapabilityFlags(rawValue: 1 << 28)
        
        /// This flag will be reserved to extend the 32bit capabilities structure to 64bits.
        static let CLIENT_CAPABILITY_EXTENSION = CapabilityFlags(rawValue: 1 << 29)
        
        // MARK: - MariaDB-specific capabilities
        
        /// See: [MariaDB Initial Handshake Packet specific flags](https://mariadb.com/kb/en/library/1-connecting-connecting/)
        
        /// Client support progress indicator (since 10.2).
        public static let MARIADB_CLIENT_PROGRESS = CapabilityFlags(rawValue: 1 << 32)
        
        /// This functionality was experimental and ultimately removed starting in MariaDB 10.6.
        public static let MARIADB_CLIENT_RESERVED_1 = CapabilityFlags(rawValue: 1 << 33)
        
        /// Permit bulk insert.
        public static let MARIADB_CLIENT_STMT_BULK_OPERATIONS = CapabilityFlags(rawValue: 1 << 34)
        
        /// Add extended metadata information.
        public static let MARIADB_CLIENT_EXTENDED_METADATA = CapabilityFlags(rawValue: 1 << 35)
        
        /// Permit skipping metadata.
        public static let MARIADB_CLIENT_CACHE_METADATA = CapabilityFlags(rawValue: 1 << 36)
        
        /// MariaDB's alternate name for ``CLIENT_LONG_PASSWORD``.
        static let CLIENT_MYSQL = Self.CLIENT_LONG_PASSWORD
        
        /// Default capabilities.
        ///
        /// - CLIENT_PROTOCOL_41,
        /// - CLIENT_PLUGIN_AUTH,
        /// - CLIENT_SECURE_CONNECTION,
        /// - CLIENT_CONNECT_WITH_DB,
        /// - CLIENT_DEPRECATE_EOF
        /// - CLIENT_SSL
        public static let clientDefault: CapabilityFlags = [
            .CLIENT_PROTOCOL_41,
            .CLIENT_PLUGIN_AUTH,
            .CLIENT_SECURE_CONNECTION,
            .CLIENT_CONNECT_WITH_DB,
            .CLIENT_DEPRECATE_EOF,
            .CLIENT_PLUGIN_AUTH_LENENC_CLIENT_DATA,
            .CLIENT_LONG_PASSWORD,
            .CLIENT_TRANSACTIONS,
            .CLIENT_SESSION_TRACK,
        ]
        
        /// The raw capabilities value.
        public var rawValue: UInt64
        
        public var name: String {
            switch self {
            case .CLIENT_LONG_PASSWORD: return "CLIENT_LONG_PASSWORD"
            case .CLIENT_FOUND_ROWS: return "CLIENT_FOUND_ROWS"
            case .CLIENT_LONG_FLAG: return "CLIENT_LONG_FLAG"
            case .CLIENT_CONNECT_WITH_DB: return "CLIENT_CONNECT_WITH_DB"
            case .CLIENT_NO_SCHEMA: return "CLIENT_NO_SCHEMA"
            case .CLIENT_COMPRESS: return "CLIENT_COMPRESS"
            case .CLIENT_ODBC: return "CLIENT_ODBC"
            case .CLIENT_LOCAL_FILES: return "CLIENT_LOCAL_FILES"
            case .CLIENT_IGNORE_SPACE: return "CLIENT_IGNORE_SPACE"
            case .CLIENT_PROTOCOL_41: return "CLIENT_PROTOCOL_41"
            case .CLIENT_INTERACTIVE: return "CLIENT_INTERACTIVE"
            case .CLIENT_SSL: return "CLIENT_SSL"
            case .CLIENT_IGNORE_SIGPIPE: return "CLIENT_IGNORE_SIGPIPE"
            case .CLIENT_TRANSACTIONS: return "CLIENT_TRANSACTIONS"
            case .CLIENT_RESERVED: return "CLIENT_RESERVED"
            case .CLIENT_SECURE_CONNECTION: return "CLIENT_SECURE_CONNECTION"
            case .CLIENT_MULTI_STATEMENTS: return "CLIENT_MULTI_STATEMENTS"
            case .CLIENT_MULTI_RESULTS: return "CLIENT_MULTI_RESULTS"
            case .CLIENT_PS_MULTI_RESULTS: return "CLIENT_PS_MULTI_RESULTS"
            case .CLIENT_PLUGIN_AUTH: return "CLIENT_PLUGIN_AUTH"
            case .CLIENT_CONNECT_ATTRS: return "CLIENT_CONNECT_ATTRS"
            case .CLIENT_PLUGIN_AUTH_LENENC_CLIENT_DATA: return "CLIENT_PLUGIN_AUTH_LENENC_CLIENT_DATA"
            case .CLIENT_CAN_HANDLE_EXPIRED_PASSWORDS: return "CLIENT_CAN_HANDLE_EXPIRED_PASSWORDS"
            case .CLIENT_SESSION_TRACK: return "CLIENT_SESSION_TRACK"
            case .CLIENT_DEPRECATE_EOF: return "CLIENT_DEPRECATE_EOF"
            case .CLIENT_OPTIONAL_RESULTSET_METADATA: return "CLIENT_OPTIONAL_RESULTSET_METADATA"
            case .CLIENT_ZSTD_COMPRESSION_ALGORITHM: return "CLIENT_ZSTD_COMPRESSION_ALGORITHM"
            case .CLIENT_QUERY_ATTRIBUTES: return "CLIENT_QUERY_ATTRIBUTES"
            case .MULTI_FACTOR_AUTHENTICATION: return "MULTI_FACTOR_AUTHENTICATION"
            case .CLIENT_CAPABILITY_EXTENSION: return "CLIENT_CAPABILITY_EXTENSION"
            case .MARIADB_CLIENT_PROGRESS: return "MARIADB_CLIENT_PROGRESS"
            case .MARIADB_CLIENT_RESERVED_1: return "MARIADB_CLIENT_RESERVED_1"
            case .MARIADB_CLIENT_STMT_BULK_OPERATIONS: return "MARIADB_CLIENT_STMT_BULK_OPERATIONS"
            case .MARIADB_CLIENT_EXTENDED_METADATA: return "MARIADB_CLIENT_EXTENDED_METADATA"
            case .MARIADB_CLIENT_CACHE_METADATA: return "MARIADB_CLIENT_CACHE_METADATA"
            default: return "UNKNOWN(\(String(self.rawValue, radix: 16))"
            }
        }
        
        /// See `CustomStringConvertible`.
        public var description: String {
            (0 ..< RawValue.bitWidth).map { .init(rawValue: 1 << $0) }.filter(self.contains(_:)).map(\.name).joined(separator: ", ")
        }
        
        /// MySQL specific flags
        internal var general: UInt32 {
            get { return UInt32(self.rawValue & 0xFFFFFFFF) }
            set { self.rawValue = (UInt64(self.mariaDBSpecific) << 32) | UInt64(newValue) }
        }
        
        /// MariaDB Initial Handshake Packet specific flags
        /// https://mariadb.com/kb/en/library/1-connecting-connecting/
        internal var mariaDBSpecific: UInt32 {
            get { return UInt32(self.rawValue >> 32) }
            set { self.rawValue = (UInt64(newValue) << 32) | UInt64(self.general) }
        }
        
        /// Create a new `MySQLCapabilityFlags` from a full-width bitfield.
        public init(rawValue: UInt64) {
            self.rawValue = rawValue
        }
        
        /// Create a `CapabilityFlags` from the combination of general and extended flags.
        internal init(general: UInt32, extended: UInt32) {
            self.init(rawValue: numericCast(general))
            self.mariaDBSpecific = extended
        }
        
        /// Create a new `MySQLCapabilities` from the upper and lower values.
        init(upper: UInt16? = nil, lower: UInt16) {
            var raw: UInt64 = 0
            if let upper = upper {
                raw = numericCast(lower)
                raw |= numericCast(upper) << 16
            } else {
                raw = numericCast(lower)
            }
            self.init(rawValue: raw)
        }
    }
}
