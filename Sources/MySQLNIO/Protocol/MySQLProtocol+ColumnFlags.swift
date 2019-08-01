extension MySQLProtocol {
    /// These don't seem to be documented anywhere.
    public struct ColumnFlags: OptionSet, CustomStringConvertible {
        /// This column is unsigned.
        public static let COLUMN_UNSIGNED = ColumnFlags(rawValue: 0b000_0000_0010_0000)
        
        /// This column is the primary key.
        public static let PRIMARY_KEY = ColumnFlags(rawValue: 0b000_0000_0000_0010)
        
        /// This column is not null.
        public static let COLUMN_NOT_NULL = ColumnFlags(rawValue: 0b000_0000_0000_0001)
        
        /// The raw status value.
        public var rawValue: UInt16
        
        public var name: String {
            switch self {
            case .COLUMN_UNSIGNED: return "COLUMN_UNSIGNED"
            case .PRIMARY_KEY: return "PRIMARY_KEY"
            case .COLUMN_NOT_NULL: return "COLUMN_NOT_NULL"
            default: return "UNKNOWN(\(self.rawValue))"
            }
        }
        
        /// All capabilities.
        public static var all: [ColumnFlags] {
            return [
                .COLUMN_UNSIGNED,
                .PRIMARY_KEY,
                .COLUMN_NOT_NULL
            ]
        }
        
        /// `CustomStringConvertible` conformance.
        public var description: String {
            return ColumnFlags.all
                .filter { self.contains($0) }
                .map { $0.name }
                .joined(separator: ", ")
        }
        
        /// Create a new `MySQLStatusFlags` from the raw value.
        public init(rawValue: UInt16) {
            self.rawValue = rawValue
        }
    }

}
