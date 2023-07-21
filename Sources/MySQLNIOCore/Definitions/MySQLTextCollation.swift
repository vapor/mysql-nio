/// Provides constants for (some of) the well-known character set collations found in various versions
/// of MySQL and compatible implementations.
///
/// Like Swift itself, this package considers UTF-8 its native character set. As such, no effort is made
/// to support the use of non-UTF-8 character sets; clients who perform a manual `SET NAMES` query are
/// likely to quicky encounter protocol errors or, worse, data corruption.
///
/// In particular, this package requires the use of what MySQL calls the `utf8mb4` character set, which
/// corresponds to the canonical UTF-8 encoding defined by BCP 18.
///
/// The `utf8mb4` character offers many different collations (text normalization and comparison rules),
/// some of which are only available in newer MySQL versions, while others are only available in recent
/// versions of MariaDB. The collations of greatest interest for language-nonspecific usage are given
/// by the following table:
///
/// Collation|ID|Comparison|UCA
/// -|:-:|-|:-:
/// `utf8mb4_bin`|46|Simple bytewise|-
/// `utf8mb4_general_ci`|45|Case-insensitive (BMP only)|-
/// `utf8mb4_unicode_ci`|224|Case-insensitive|4.0 (2003)
/// `utf8mb4_unicode_520_ci`|246|Case-insensitive|5.2 (2009)
/// `utf8mb4_0900_ai_ci`|255|Case/accent-insensitive|9.0 (2016)
/// `utf8mb4_uca1400_ai_ci`|2304|Case/accent-insensitive|14.0 (2021)
///
/// Unfortunately, the UCA 9.0-based collations are available only in MySQL 8, Percona 8, and
/// Aurora 3, while the UCA 14.0-based collations are available only in MariaDB 10.10 and later. To
/// ensure the best collation available is used whenever possible, this package uses the following
/// heuristic to choose a collation:
///
/// 1. If `IS_NON_MARIADB` is absent and version `>= 10.10` (new MariaDB):
///
///    - Use `utf8mb4_uca1400_ai_ci`
/// 2. If `IS_NON_MARIDB` and `QUERY_ATTRIBUTES` are present (new MySQL):
///
///    - Use `utf8mb4_0900_ai_ci`
/// 3. In all other cases:
///
///    - Use `utf8mb4_unicode_520_ci`
struct MySQLTextCollation: Sendable, Hashable {
    /// The full name of the collation (e.g. `utf8mb4_0900_ai_ci`).
    let name: String
    
    /// The character set name the collation applies to (e.g. `utf8mb4`).
    ///
    /// Specifying a character set without also identifying a specific collation will result in
    /// the use of the character set's default collation. For `utf8mb4`, the default collation
    /// (unless overriden by server configuration, per-database options, or per-table options) is
    /// the deprecated and obsolete `utf8mb4_general_ci` in all versions of MariaDB and pre-8.0
    /// versions of MySQL. It is therefore strongly recommend to always pick an explict collation.
    let characterSetName: String
    
    /// The numeric ID assigned to the collation.
    ///
    /// In MySQL, all collations have straightforward 16-bit numeric IDs associated directly with
    /// the collation, which is found in the `information_schema.collations` table.
    ///
    /// MariaDB, starting with version 10.10, has started assigning structured ID values to
    /// collations according to common applicability to character sets. These more involved values
    /// are exposed via the MariaDB-specific table
    /// `information_schema.collation_character_set_applicability`. See [MariaDB Server Ticket
    /// MDEV-27009](https://jira.mariadb.org/browse/MDEV-27009) for more details.
    let id: UInt16
    
    /// The numeric ID suitable for this collation when used in server/client handshakes.
    ///
    /// An additional complication occurs with collation selection when peforming the protocol's initial
    /// server/client handshake: the `HandshakeV10`, `SSLRequest`, and `HandshakeResponse41` packets only
    /// set aside one byte for the server and client collation IDs. This doesn't affect the Unicode 4.0,
    /// 5.2, or 9.0 collations we want to use, but MariaDB's Unicode 14.0 collations have IDs with 12
    /// significant bits, and even the accent-sensitive 9.0 collations use 9 bits. For such out-of-range
    /// IDs, the heuristic falls back on the Unicode 5.2 collation for handshake packets and relies on
    /// the higher-level protocol logic to issue a subsequent `SET NAMES` query after authentication.
    var idForHandshake: UInt8 { .init(truncatingIfNeeded: self.id <= UInt16(UInt8.max) ? self.id : Self.utf8Unicode52CI.id) }

    // MARK: - Well-known collations
    
    // CI = Case-Insensitive, CS = Case-Sensitive
    // AI = Accent-Insensitive, AS = Accent-Sensitive
    
    // Binary
    static var binary: Self            { .init(name: "binary",                 characterSetName: "binary",  id:  63) }
    // Unicode binary
    static var utf8Binary: Self        { .init(name: "utf8mb4_bin",            characterSetName: "utf8mb4", id:  46) }
    // Unicode uncollated (deprecated, do not use)
    static var utf8GeneralCI: Self     { .init(name: "utf8mb4_general_ci",     characterSetName: "utf8mb4", id:  45) }
    // Unicode 4.0.0 (20+ years out of date, not recommended)
    static var utf8Unciode4CI: Self    { .init(name: "utf8mb4_unicode_ci",     characterSetName: "utf8mb4", id: 224) }
    // Unicode 5.2.0
    static var utf8Unicode52CI: Self   { .init(name: "utf8mb4_unicode_520_ci", characterSetName: "utf8mb4", id: 246) }
    // Unicode 9.0.0 (MySQL 8.0+ only)
    static var utf8Unicode9AICI: Self  { .init(name: "utf8mb4_0900_ai_ci",     characterSetName: "utf8mb4", id: 255) }
    static var utf8Unicode9ASCI: Self  { .init(name: "utf8mb4_0900_as_ci",     characterSetName: "utf8mb4", id: 305) }
    static var utf8Unicode9ASCS: Self  { .init(name: "utf8mb4_0900_as_cs",     characterSetName: "utf8mb4", id: 278) }
    // Unicode 14.0.0 (MariaDB 10.10+ only)
    static var utf8Unicode14AICI: Self { .init(name: "utf8mb4_uca1400_ai_ci",  characterSetName: "utf8mb4", id: 2304) }
    static var utf8Unicode14AICS: Self { .init(name: "utf8mb4_uca1400_ai_cs",  characterSetName: "utf8mb4", id: 2305) }
    static var utf8Unicode14ASCI: Self { .init(name: "utf8mb4_uca1400_as_ci",  characterSetName: "utf8mb4", id: 2306) }
    static var utf8Unicode14ASCS: Self { .init(name: "utf8mb4_uca1400_as_cs",  characterSetName: "utf8mb4", id: 2307) }

    /// Apply the heuristic algorithm to determining the appropriate collation for a connection.
    static func bestCollation(forVersion version: String, capabilities: MySQLCapabilities) -> MySQLTextCollation {
        if !capabilities.contains(.isNotMariaDB), // MariaDB 10.10 or newer
           (version.starts(with: "10.10") || version.starts(with: "10.11") || version.starts(with: "11."))
        {
            return MySQLTextCollation.utf8Unicode14AICI
        } else if capabilities.contains(.isNotMariaDB), version.starts(with: "8") { // non-MariaDB MySQL 8.0 or newer (or compatible)
            return MySQLTextCollation.utf8Unicode9AICI
        } else { // anything else
            return MySQLTextCollation.utf8Unicode52CI
        }
    }
    
    /// If the given ID corresponds to a "well-known" collation (see above), returns that collection. Otherwise
    /// returns a synthesized collation with empty names.
    static func lookup(byId id: UInt16) -> MySQLTextCollation {
        switch id {
        case MySQLTextCollation.binary.id:            return MySQLTextCollation.binary
        case MySQLTextCollation.utf8Binary.id:        return MySQLTextCollation.utf8Binary
        case MySQLTextCollation.utf8GeneralCI.id:     return MySQLTextCollation.utf8GeneralCI
        case MySQLTextCollation.utf8Unciode4CI.id:    return MySQLTextCollation.utf8Unciode4CI
        case MySQLTextCollation.utf8Unicode52CI.id:   return MySQLTextCollation.utf8Unicode52CI
        case MySQLTextCollation.utf8Unicode9AICI.id:  return MySQLTextCollation.utf8Unicode9AICI
        case MySQLTextCollation.utf8Unicode9ASCI.id:  return MySQLTextCollation.utf8Unicode9ASCI
        case MySQLTextCollation.utf8Unicode9ASCS.id:  return MySQLTextCollation.utf8Unicode9ASCS
        case MySQLTextCollation.utf8Unicode14AICI.id: return MySQLTextCollation.utf8Unicode14AICI
        case MySQLTextCollation.utf8Unicode14AICS.id: return MySQLTextCollation.utf8Unicode14AICS
        case MySQLTextCollation.utf8Unicode14ASCI.id: return MySQLTextCollation.utf8Unicode14ASCI
        case MySQLTextCollation.utf8Unicode14ASCS.id: return MySQLTextCollation.utf8Unicode14ASCS
        default: return .init(name: "", characterSetName: "", id: id)
        }
    }
}
