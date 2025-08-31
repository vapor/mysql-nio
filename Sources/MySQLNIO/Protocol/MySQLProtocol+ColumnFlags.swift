extension MySQLProtocol {
    /// These don't seem to be documented anywhere.
    public struct ColumnFlags: OptionSet, CustomStringConvertible, Sendable {
        /// This column is unsigned.
        public static var COLUMN_UNSIGNED: Self { .init(rawValue: 0b000_0000_0010_0000) }

        /// This column is the primary key.
        public static var PRIMARY_KEY: Self { .init(rawValue: 0b000_0000_0000_0010) }

        /// This column is not null.
        public static var COLUMN_NOT_NULL: Self { .init(rawValue: 0b000_0000_0000_0001) }

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
        public static var all: [ColumnFlags] { [
            .COLUMN_UNSIGNED,
            .PRIMARY_KEY,
            .COLUMN_NOT_NULL,
        ] }
        
        /// See ``CustomStringConvertible/description``.
        public var description: String {
            ColumnFlags.all.filter(self.contains(_:)).map(\.name).joined(separator: ", ")
        }
        
        /// See ``RawRepresentable/init(rawValue:)``.
        public init(rawValue: UInt16) {
            self.rawValue = rawValue
        }
    }

}
