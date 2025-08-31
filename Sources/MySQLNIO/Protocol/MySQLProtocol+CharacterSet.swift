extension MySQLProtocol {
    /// A character set is defined in the protocol as a integer.
    ///
    /// MySQL has a very flexible character set support as documented in Character Sets, Collations, Unicode.
    /// https://dev.mysql.com/doc/internals/en/character-set.html#packet-Protocol::CharacterSet
    public struct CharacterSet: RawRepresentable, Equatable, CustomStringConvertible, ExpressibleByIntegerLiteral, Sendable {
        /// `big5_chinese_ci`
        public static var big5: Self { 1 }
        
        /// `dec8_swedish_ci`
        public static var dec8: Self { 3 }
        
        /// `cp850_general_ci`
        public static var cp850: Self { 4 }
        
        /// `hp8_english_ci`
        public static var hp8: Self { 6 }
        
        /// `koi8r_general_ci`
        public static var koi8r: Self { 7 }
        
        /// `latin1_swedish_ci`
        public static var latin1: Self { 8 }
        
        /// `latin2_general_ci`
        public static var latin2: Self { 9 }
        
        /// `swe7_swedish_ci`
        public static var swe7: Self { 10 }
        
        /// `ascii_general_ci`
        public static var ascii: Self { 11 }
        
        /// `ujis_japanese_ci`
        public static var ujis: Self { 12 }
        
        /// `sjis_japanese_ci`
        public static var sjis: Self { 13 }
        
        /// `hebrew_general_ci`
        public static var hebrew: Self { 16 }
        
        /// `tis620_thai_ci`
        public static var tis620: Self { 18 }
        
        /// `euckr_korean_ci`
        public static var euckr: Self { 19 }
        
        /// `koi8u_general_ci`
        public static var koi8u: Self { 22 }
        
        /// `gb2312_chinese_ci`
        public static var gb2312: Self { 24 }
        
        /// `greek_general_ci`
        public static var greek: Self { 25 }
        
        /// `cp1250_general_ci`
        public static var cp1250: Self { 26 }
        
        /// `gbk_chinese_ci`
        public static var gbk: Self { 28 }
        
        /// `latin5_turkish_ci`
        public static var latin5: Self { 30 }
        
        /// `armscii8_general_ci`
        public static var armscii8: Self { 32 }
        
        /// `utf8_general_ci`
        public static var utf8: Self { 33 }
        
        /// `ucs2_general_ci`
        public static var ucs2: Self { 35 }
        
        /// `cp866_general_ci`
        public static var cp866: Self { 36 }
        
        /// `keybcs2_general_ci`
        public static var keybcs2: Self { 37 }
        
        /// `macce_general_ci`
        public static var macce: Self { 38 }
        
        /// `macroman_general_ci`
        public static var macroman: Self { 39 }
        
        /// `cp852_general_ci`
        public static var cp852: Self { 40 }
        
        /// `latin7_general_ci`
        public static var latin7: Self { 41 }
        
        /// `cp1251_general_ci`
        public static var cp1251: Self { 51 }
        
        /// `utf16_general_ci`
        public static var utf16: Self { 54 }
        
        /// `utf16le_general_ci`
        public static var utf16le: Self { 56 }
        
        /// `cp1256_general_ci`
        public static var cp1256: Self { 57 }
        
        /// `cp1257_general_ci`
        public static var cp1257: Self { 59 }
        
        /// `utf32_general_ci`
        public static var utf32: Self { 60 }
        
        /// `binary`
        public static var binary: Self { 63 }
        
        /// `geostd8_general_ci`
        public static var geostd8: Self { 92 }
        
        /// `cp932_japanese_ci`
        public static var cp932: Self { 95 }
        
        /// `eucjpms_japanese_ci`
        public static var eucjpms: Self { 97 }
        
        /// `gb18030_chinese_ci`
        public static var gb18030: Self { 248 }
        
        /// `utf8mb4_0900_ai_ci`
        public static var utf8mb4: Self { 255 }
        
        /// `charset_nr` (2) -- number of the character set and collation
        public var rawValue: UInt8
        
        /// See ``CustomStringConvertible/description``.
        public var description: String {
            self.name
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
            case .utf8mb4: return "utf8mb4_0900_ai_ci"
            default: return "unknown (\(self.rawValue))"
            }
        }
        
        /// See ``RawRepresentable/init(rawValue:)``.
        public init(rawValue: UInt8) {
            self.rawValue = rawValue
        }
        
        /// See ``ExpressibleByIntegerLiteral/init(integerLiteral:)``.
        public init(integerLiteral value: UInt8) {
            self.rawValue = value
        }
    }
}
