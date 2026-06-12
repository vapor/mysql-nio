/// Values for the capabilities flag bitmask used by the MySQL protocol.
@usableFromInline
struct MySQLCapabilities: OptionSet, Sendable {
    @usableFromInline
    let rawValue: UInt64

    @usableFromInline
    init(rawValue: UInt64) {
        self.rawValue = rawValue
    }

    /// Set by older MariaDB versions. MySQL named this `CLIENT_LONG_PASSWORD`.
    static let clientMySQL = Self(rawValue: 1)
    /// Send found rows instead of affected rows in ``EOFPacket``.
    static let foundRows = Self(rawValue: 2)
    /// Get all column flags.
    static let longFlag = Self(rawValue: 4)
    /// Database (schema) name can be specified on connect in Handshake Response Packet.
    static let connectWithDB = Self(rawValue: 8)
    /// DEPRECATED: Don't allow database.table.column.
    static let noSchema = Self(rawValue: 16)
    /// Compression protocol supported.
    static let compress = Self(rawValue: 32)
    /// Special handling of ODBC behavior.
    static let odbc = Self(rawValue: 64)
    /// Can use [LOAD DATA LOCAL](https://mariadb.com/docs/server/reference/sql-statements/data-manipulation/inserting-loading-data/load-data-into-tables-or-index/load-data-infile#load-data-local-infile).
    static let localFiles = Self(rawValue: 128)
    /// Ignore spaces before `(`.
    static let ignoreSpace = Self(rawValue: 256)
    /// New 4.1 protocol.
    static let clientProtocol41 = Self(rawValue: 1 << 9)
    /// This is an interactive client.
    static let clientInteractive = Self(rawValue: 1 << 10)
    /// Use SSL encryption for the session.
    static let ssl = Self(rawValue: 1 << 11)
    /// Client only flag.
    static let ignoreSigpipe = Self(rawValue: 1 << 12)
    /// Client knows about transactions.
    static let transactions = Self(rawValue: 1 << 13)
    /// DEPRECATED: Old flag for 4.1 protocol
    static let reserved = Self(rawValue: 1 << 14)
    /// DEPRECATED: Old flag for 4.1 authentication \ `CLIENT_RESERVED2`
    static let secureConnection = Self(rawValue: 1 << 15)
    /// Enable/disable multi-statement support.
    static let multiStatements = Self(rawValue: 1 << 16)
    /// Enable/disable multi-results.
    static let multiResults = Self(rawValue: 1 << 17)
    /// Multi-results and OUT parameters in PS-protocol.
    static let psMultiResults = Self(rawValue: 1 << 18)
    /// Client supports plugin authentication.
    static let pluginAuth = Self(rawValue: 1 << 19)
    /// Client sends connection attributes.
    static let connectAttrs = Self(rawValue: 1 << 20)
    /// Enable authentication response packet to be larger than 255 bytes.
    static let pluginAuthLenencClientData = Self(rawValue: 1 << 21)
    /// Don't close the connection for a user account with expired password.
    static let clientCanHandleExpiredPasswords = Self(rawValue: 1 << 22)
    /// Capable of handling server state change information.
    static let clientSessionTrack = Self(rawValue: 1 << 23)
    /// `EOF_Packet` deprecation:
    /// `OK_Packet` replace `EOF_Packet` at the end of the result set when in text format.
    /// `EOF_Packet` between columns definition and `resultsetRows` is deleted.
    static let clientDeprecateEOF = Self(rawValue: 1 << 24)
    /// The client can handle optional metadata information in the resultset.
    /// Not in use for MariaDB.
    static let clientOptionalResultsetMetadata = Self(rawValue: 1 << 25)
    /// Compression protocol extended to support zstd compression method.
    static let clientZstdCompressionAlgorithm = Self(rawValue: 1 << 26)
    /// Support optional extension for query parameters into the COM_QUERY and COM_STMT_EXECUTE packets.
    static let queryAttributes = Self(rawValue: 1 << 27)
    /// Support Multi factor authentication.
    static let multiFactorAuthentication = Self(rawValue: 1 << 28)
    /// This flag will be reserved to extend the 32bit capabilities structure to 64bits.
    static let clientCapabilityExtension = Self(rawValue: 1 << 29)
    /// Client verify server certificate. Deprecated, client has options to indicate if server certificate must be verified.
    static let clientSSLVerifyServerCert = Self(rawValue: 1 << 30)
    /// Don't reset the options after an unsuccessful connect.
    static let clientRememberOptions = Self(rawValue: 1 << 31)
    /// Client support progress indicator.
    static let mariaDBClientProgress = Self(rawValue: 1 << 32)
    /// deprecated - did permit `COM_MULTI` protocol.
    static let mariaDBClientComMulti = Self(rawValue: 1 << 33)
    /// Permit bulk insert.
    static let mariaDBClientSTMTBulkOperations = Self(rawValue: 1 << 34)
    /// Add extended metadata information.
    static let mariaDBClientExtendedMetadata = Self(rawValue: 1 << 35)
    /// Permit skipping metadata.
    static let mariaDBClientCacheMetadata = Self(rawValue: 1 << 36)
    /// When enabled, indicate that bulk command can use `STMT_BULK_FLAG_SEND_UNIT_RESULTS` flag
    /// that permits to return a result set of all affected rows and auto-increment values.
    static let mariaDBClientBulkUnitResults = Self(rawValue: 1 << 37)
}

extension MySQLCapabilities {
    /// The set of all obsolete or deprecated capability flags the wire protocol nonetheless requires clients to set
    /// in order to be considered valid by servers compatible with at least MySQL 5.7
    /// (including MariaDB 10.2+, Percona 8+, and Aurora 2+).
    static var hardcodedProtocolCapabilities: MySQLCapabilities {
        [.longFlag, .clientProtocol41, .transactions, .secureConnection, .multiStatements]
    }

    /// The set of all capability flags a server MUST support to be compatible with this implementation.
    /// This set is deliberately chosen such that interoperability with MySQL 5.7 or later
    /// is always sufficient for compatibility with this package as well.
    static var requiredCapabilities: MySQLCapabilities {
        self.hardcodedProtocolCapabilities.union([
            // Required because we do not support old-style "short" EOF packets, found in the pre-5.7 protocol.
            .clientDeprecateEOF
        ])
    }

    /// The set of "global" (i.e. not user-configurable) capabilities supported by this package
    /// that servers are _not_ required to also support.
    static var supportedCapabilities: MySQLCapabilities {
        [
            .localFiles,
            .pluginAuth,
            .connectAttrs,
            .pluginAuthLenencClientData,
            .multiResults,
            .psMultiResults,
            .clientSessionTrack,
            .clientOptionalResultsetMetadata,
            //.mariaDBClientExtendedMetadata,
            .mariaDBClientCacheMetadata,
        ]
    }

    /// The set of capabilites used as the initial client set for negotiation,
    /// not including any capabilities which may be enabled on a per-connection basis
    /// (such as ``MySQLCapabilities/ssl`` or ``MySQLCapabilities/connectWithDB``).
    static var baselineClientCapabilities: MySQLCapabilities {
        .init().union(self.requiredCapabilities).union(self.supportedCapabilities)
    }
}

extension MySQLCapabilities {
    /// Determines whether either of the capabilities which signals the presence of a `metadata_follows` flag
    /// in packets which can potentially carry that flag is enabled.
    ///
    /// Effectively shorthand for checking whether one or the other of
    /// ``MySQLCapabilities/clientOptionalResultsetMetadata`` (available only in MySQL 8+ servers)
    /// or ``MySQLCapabilities/mariaDBClientCacheMetadata`` (available only in MariaDB 10.6+ servers)
    /// has been negotiated.
    ///
    /// > Note: It is not actually possible for both capabilities to be set at the same time, at least as of the time of this writing,
    /// > as one is specific to MySQL/Percona/Aurora and the other is specific to MariaDB,
    /// > but this logic does not waste time checking for that particular impossibility.
    var metadataFlagAvailable: Bool {
        !self.intersection([.clientOptionalResultsetMetadata, .mariaDBClientCacheMetadata]).isEmpty
    }
}

extension MySQLCapabilities {
    /// Validates a server's offered capability set, decides the client capability set to respond with, and determines whether TLS negotiation is needed.
    static func negotiateCapabilities(
        serverCapabilities: MySQLCapabilities,
        configuration: MySQLConnectionConfiguration
    ) throws(MySQLClientError) -> MySQLCapabilities {
        // Make sure the hardcoded protocol flags are there and that our minimum support requirements are met.
        guard serverCapabilities.contains(.requiredCapabilities) else {
            throw MySQLClientError.incompatibleServer("Required capabilities not available")
        }

        // If we require TLS, make sure the server offers it.
        if configuration.tls.isEnforced {
            guard serverCapabilities.contains(.ssl) else {
                throw MySQLClientError.incompatibleServer("TLS required but not supported by server")
            }
        }

        // Use the baseline capability flags as the starting point for the client's capabilities,
        // then tweak those capabilities to match the configuration.
        var chosenClientCapabilities = Self.baselineClientCapabilities

        // If a default database is specified by our config, tell the server we're sending it.
        if configuration.defaultDatabaseName != nil {
            chosenClientCapabilities.insert(.connectWithDB)
        }

        // If we want TLS and the server offers it, specify it in return; we've already checked the `isEnforced` flag.
        if configuration.tls.sslContext != nil, serverCapabilities.contains(.ssl) {
            chosenClientCapabilities.insert(.ssl)
        }

        // If the interactive configuration was requested, specify that too.
        if configuration.isInteractive {
            chosenClientCapabilities.insert(.clientInteractive)
        }

        // The final client capability set is the intersection of the client and server capabilities.
        // Since a MySQL server will never send "extended" capability flags,
        // this will automatically mask out any MariaDB capabilities we include in our baseline.
        return chosenClientCapabilities.intersection(serverCapabilities)
    }
}
