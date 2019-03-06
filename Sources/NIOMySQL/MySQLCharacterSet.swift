#warning("TODO: add rest of character set types")
#warning("TODO: conform MySQLCharacterSet to raw representable")
#warning("TODO: move MySQLCharacterSet to enum")

/// 14.1.4 Character Set
///
/// MySQL has a very flexible character set support as documented in Character Sets, Collations, Unicode.
/// https://dev.mysql.com/doc/internals/en/character-set.html#packet-Protocol::CharacterSet
///
/// A character set is defined in the protocol as a integer.
public struct MySQLCharacterSet: Equatable {
    /// charset_nr (2) -- number of the character set and collation
    var rawValue: UInt16
    
    /// Creates a new `MySQLCharacterSet` from UInt16
    ///
    /// - Parameter raw: UInt16 value of collation.
    init(rawValue: UInt16) {
        self.rawValue = rawValue
    }
    
    /// Creates a new `MySQLCharacterSet` with Byte value.
    ///
    /// - Parameter byte: Byte value of collation.
    init(byte: UInt8) {
        self.rawValue = numericCast(byte)
    }
    
    /// Creates a new `MySQLCharacterSet` from a string. Can return nil if the string is a invalid or unsupported collation.
    ///
    /// - Parameter string: Collation name of desirable character set.
    ///
    /// Currently accepting the followings collations:
    /// * latin1_swedish_ci
    /// * utf8_general_ci
    /// * binary
    /// * utf8mb4_unicode_ci
    ///
    /// Example: MySQLCharacterSet(string: "utf8mb4_unicode_ci")
    public init?(string: String) {
        switch string {
        case "latin1_swedish_ci": self.rawValue = 0x0008
        case "utf8_general_ci": self.rawValue = 0x0021
        case "binary": self.rawValue = 0x003f
        case "utf8mb4_unicode_ci": self.rawValue = 0x00e0
        default: return nil
        }
    }
    
    /// `MySQLCharacterSet` value.
    /// * Collation: latin1_swedish_ci
    /// * Character set: latin1
    /// * Id: 8
    /// * Value: 0x0008
    public static var latin1_swedish_ci: MySQLCharacterSet = 0x0008
    /// `MySQLCharacterSet` value.
    /// * Collation: utf8_general_ci
    /// * Character set: utf8
    /// * Id: 33
    /// * Value: 0x0021
    public static var utf8_general_ci: MySQLCharacterSet = 0x0021
    /// `MySQLCharacterSet` value.
    /// * Collation: binary
    /// * Character set: binary
    /// * Id: 63
    /// * Value: 0x003f
    public static var binary: MySQLCharacterSet = 0x003f
    /// `MySQLCharacterSet` value.
    /// * Collation: utf8mb4_unicode_ci
    /// * Character set: utf8mb4
    /// * Id: 224
    /// * Value: 0x00e0
    public static var utf8mb4_unicode_ci: MySQLCharacterSet = 0x00e0
    
    /// Character set: utf8mb4
    /// Collation: utf8mb4_0900_ai_ci
    public static let utf8mb4: MySQLCharacterSet = 0x00FF
    
    /// Serializes the `MySQLCharacterSet` into a buffer.
    func serialize(into buffer: inout ByteBuffer) {
        buffer.writeInteger(UInt8(self.rawValue & 0xFF), endianness: .little)
    }
}

extension MySQLCharacterSet: CustomStringConvertible {
    /// See `CustomStringConvertible`.
    public var description: String {
        switch self {
        case .latin1_swedish_ci: return "latin1_swedish_ci"
        case .utf8_general_ci: return "utf8_general_ci"
        case .binary: return "binary"
        case .utf8mb4_unicode_ci: return "utf8mb4_unicode_ci"
        case .utf8mb4: return "utf8mb4"
        default: return "unknown \(self.rawValue)"
        }
    }
}

extension MySQLCharacterSet: ExpressibleByIntegerLiteral {
    /// See `ExpressibleByIntegerLiteral.init(integerLiteral:)`
    public init(integerLiteral value: UInt16) {
        self.rawValue = value
    }
}
