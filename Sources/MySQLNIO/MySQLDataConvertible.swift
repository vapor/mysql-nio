import struct Foundation.Decimal

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

extension FixedWidthInteger {
    public init?(mysqlData: MySQLData) {
        guard let int = mysqlData.int else {
            return nil
        }
        self = numericCast(int)
    }

    public var mysqlData: MySQLData? {
        return .init(int: numericCast(self))
    }
}

extension Int: MySQLDataConvertible { }
extension Int8: MySQLDataConvertible { }
extension Int16: MySQLDataConvertible { }
extension Int32: MySQLDataConvertible { }
extension Int64: MySQLDataConvertible { }
extension UInt: MySQLDataConvertible { }
extension UInt8: MySQLDataConvertible { }
extension UInt16: MySQLDataConvertible { }
extension UInt32: MySQLDataConvertible { }
extension UInt64: MySQLDataConvertible { }

extension String: MySQLDataConvertible {
    public init?(mysqlData: MySQLData) {
        guard let string = mysqlData.string else {
            return nil
        }
        self = string
    }

    public var mysqlData: MySQLData? {
        return .init(string: self)
    }
}

extension Bool: MySQLDataConvertible {
    public init?(mysqlData: MySQLData) {
        guard let bool = mysqlData.bool else {
            return nil
        }
        self = bool
    }

    public var mysqlData: MySQLData? {
        return .init(bool: self)
    }
}

extension UUID: MySQLDataConvertible {
    public init?(mysqlData: MySQLData) {
        guard let uuid = mysqlData.uuid else {
            return nil
        }
        self = uuid
    }

    public var mysqlData: MySQLData? {
        return .init(uuid: self)
    }
}


extension Double: MySQLDataConvertible {
    public init?(mysqlData: MySQLData) {
        guard let double = mysqlData.double else {
            return nil
        }
        self = double
    }

    public var mysqlData: MySQLData? {
        return .init(double: self)
    }
}

extension Float: MySQLDataConvertible {
    public init?(mysqlData: MySQLData) {
        guard let float = mysqlData.float else {
            return nil
        }
        self = float
    }

    public var mysqlData: MySQLData? {
        return .init(float: self)
    }
}

extension Decimal: MySQLDataConvertible {
    public init?(mysqlData: MySQLData) {
        guard let decimal = mysqlData.decimal else {
            return nil
        }
        self = decimal
    }

    public var mysqlData: MySQLData? {
        .init(decimal: self)
    }
}
