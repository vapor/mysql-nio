public struct MySQLQuery: Sendable, Hashable {
    public var sql: String
    public var parameters: [String]
    
    public init(unsafeSql: String, parameters: [String]) {
        self.sql = unsafeSql
        self.parameters = parameters
    }
}

