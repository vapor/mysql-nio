public protocol MySQLDataConvertible {
    init?(mysqlData: MySQLData)
    var mysqlData: MySQLData? { get }
}

extension Date: MySQLDataConvertible {
    public init?(mysqlData: MySQLData) {
        guard let date = mysqlData.date else {
            return nil
        }
        self = date
    }
    
    public var mysqlData: MySQLData? {
        return .init(date: self)
    }
}
