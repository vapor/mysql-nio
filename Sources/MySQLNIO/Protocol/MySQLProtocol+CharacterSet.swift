extension MySQLProtocol {
    /// A character set, including collation, is defined in the protocol as a integer.
    ///
    /// MySQL has a very flexible character set support as documented in Character Sets, Collations, Unicode.
    /// https://dev.mysql.com/doc/internals/en/character-set.html#packet-Protocol::CharacterSet
    public struct CharacterSet: RawRepresentable, Equatable, CustomStringConvertible, ExpressibleByIntegerLiteral {
        /// `big5_chinese_ci`
        public static let big5: CharacterSet = 1
        
        /// `dec8_swedish_ci`
        public static let dec8: CharacterSet = 3
        
        /// `cp850_general_ci`
        public static let cp850: CharacterSet = 4
        
        /// `hp8_english_ci`
        public static let hp8: CharacterSet = 6
        
        /// `koi8r_general_ci`
        public static let koi8r: CharacterSet = 7
        
        /// `latin1_swedish_ci`
        public static let latin1: CharacterSet = 8
        
        /// `latin2_general_ci`
        public static let latin2: CharacterSet = 9
        
        /// `swe7_swedish_ci`
        public static let swe7: CharacterSet = 10
        
        /// `ascii_general_ci`
        public static let ascii: CharacterSet = 11
        
        /// `ujis_japanese_ci`
        public static let ujis: CharacterSet = 12
        
        /// `sjis_japanese_ci`
        public static let sjis: CharacterSet = 13
        
        /// `hebrew_general_ci`
        public static let hebrew: CharacterSet = 16
        
        /// `tis620_thai_ci`
        public static let tis620: CharacterSet = 18
        
        /// `euckr_korean_ci`
        public static let euckr: CharacterSet = 19
        
        /// `koi8u_general_ci`
        public static let koi8u: CharacterSet = 22
        
        /// `gb2312_chinese_ci`
        public static let gb2312: CharacterSet = 24
        
        /// `greek_general_ci`
        public static let greek: CharacterSet = 25
        
        /// `cp1250_general_ci`
        public static let cp1250: CharacterSet = 26
        
        /// `gbk_chinese_ci`
        public static let gbk: CharacterSet = 28
        
        /// `latin5_turkish_ci`
        public static let latin5: CharacterSet = 30
        
        /// `armscii8_general_ci`
        public static let armscii8: CharacterSet = 32
        
        /// `utf8_general_ci`
        public static let utf8: CharacterSet = 33
        
        /// `ucs2_general_ci`
        public static let ucs2: CharacterSet = 35
        
        /// `cp866_general_ci`
        public static let cp866: CharacterSet = 36
        
        /// `keybcs2_general_ci`
        public static let keybcs2: CharacterSet = 37
        
        /// `macce_general_ci`
        public static let macce: CharacterSet = 38
        
        /// `macroman_general_ci`
        public static let macroman: CharacterSet = 39
        
        /// `cp852_general_ci`
        public static let cp852: CharacterSet = 40
        
        /// `latin7_general_ci`
        public static let latin7: CharacterSet = 41
        
        /// `cp1251_general_ci`
        public static let cp1251: CharacterSet = 51
        
        /// `utf16_general_ci`
        public static let utf16: CharacterSet = 54
        
        /// `utf16le_general_ci`
        public static let utf16le: CharacterSet = 56
        
        /// `cp1256_general_ci`
        public static let cp1256: CharacterSet = 57
        
        /// `cp1257_general_ci`
        public static let cp1257: CharacterSet = 59
        
        /// `utf32_general_ci`
        public static let utf32: CharacterSet = 60
        
        /// `binary`
        public static let binary: CharacterSet = 63
        
        /// `geostd8_general_ci`
        public static let geostd8: CharacterSet = 92
        
        /// `cp932_japanese_ci`
        public static let cp932: CharacterSet = 95
        
        /// `eucjpms_japanese_ci`
        public static let eucjpms: CharacterSet = 97
        
        /// `gb18030_chinese_ci`
        public static let gb18030: CharacterSet = 248
        
        /// `utf8mb4_unicode_ci` (MySQL 5.7)
        public static let utf8mb4_57: CharacterSet = 224
        
        /// `utf8mb4_unicode_520_ci` (MySQL 5.7)
        public static let utf8mb4_57_ext: CharacterSet = 246
        
        /// `utf8mb4_0900_ai_ci`
        public static let utf8mb4: CharacterSet = 255
        
        /// `charset_nr` (2) -- number of the character set and collation
        public var rawValue: UInt8
        
        /// `CustomStringConvertible` conformance.
        public var description: String {
            return self.name
        }
        
        /// This character set's readable name.
        public var name: String {
            switch self {
            case .big5: return "big5_chinese_ci"
            case .dec8: return "dec8_swedish_ci"
            case .cp850: return "cp850_general_ci"
            case .hp8: return "hp8_english_ci"
            case .koi8r: return "koi8r_general_ci"
            case .latin1: return "latin1_swedish_ci"
            case .latin2: return "latin2_general_ci"
            case .swe7: return "swe7_swedish_ci"
            case .ascii: return "ascii_general_ci"
            case .ujis: return "ujis_japanese_ci"
            case .sjis: return "sjis_japanese_ci"
            case .hebrew: return "hebrew_general_ci"
            case .tis620: return "tis620_thai_ci"
            case .euckr: return "euckr_korean_ci"
            case .koi8u: return "koi8u_general_ci"
            case .gb2312: return "gb2312_chinese_ci"
            case .greek: return "greek_general_ci"
            case .cp1250: return "cp1250_general_ci"
            case .gbk: return "gbk_chinese_ci"
            case .latin5: return "latin5_turkish_ci"
            case .armscii8: return "armscii8_general_ci"
            case .utf8: return "utf8_general_ci"
            case .ucs2: return "ucs2_general_ci"
            case .cp866: return "cp866_general_ci"
            case .keybcs2: return "keybcs2_general_ci"
            case .macce: return "macce_general_ci"
            case .macroman: return "macroman_general_ci"
            case .cp852: return "cp852_general_ci"
            case .latin7: return "latin7_general_ci"
            case .cp1251: return "cp1251_general_ci"
            case .utf16: return "utf16_general_ci"
            case .utf16le: return "utf16le_general_ci"
            case .cp1256: return "cp1256_general_ci"
            case .cp1257: return "cp1257_general_ci"
            case .utf32: return "utf32_general_ci"
            case .binary: return "binary"
            case .geostd8: return "geostd8_general_ci"
            case .cp932: return "cp932_japanese_ci"
            case .eucjpms: return "eucjpms_japanese_ci"
            case .gb18030: return "gb18030_chinese_ci"
            case .utf8mb4_57: return "utf8mb4_unicode_ci"
            case .utf8mb4_57_ext: return "utf8mb4_unicode_520_ci"
            case .utf8mb4: return "utf8mb4_0900_ai_ci"
            default: return "unknown (\(self.rawValue))"
            }
        }
        
        /// Creates a new `CharacterSet` from `UInt8`
        ///
        /// - Parameter raw: `UInt8` value of character set.
        public init(rawValue: UInt8) {
            self.rawValue = rawValue
        }
        
        /// `ExpressibleByIntegerLiteral` conformance.
        public init(integerLiteral value: UInt8) {
            self.rawValue = value
        }
    }
}
