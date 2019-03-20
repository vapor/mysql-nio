public protocol MySQLDataConvertible {
    init?(mysqlData: MySQLData)
    var mysqlData: MySQLData? { get }
}

extension MySQLData {
    public static var null: MySQLData {
        return .init(type: .null, buffer: nil)
    }
}

public struct MySQLData: CustomStringConvertible, ExpressibleByStringLiteral, ExpressibleByIntegerLiteral, ExpressibleByBooleanLiteral {
    public enum Format {
        case binary
        case text
    }
    
    public let type: MySQLProtocol.DataType
    public let format: Format
    public let buffer: ByteBuffer?
    
    /// If `true`, this value is unsigned.
    public var isUnsigned: Bool
    
    public init(booleanLiteral value: Bool) {
        self.init(bool: value)
    }
    
    public init(stringLiteral value: String) {
        self.init(string: value)
    }
    
    public init(integerLiteral value: Int) {
        self.init(int: value)
    }
    
    public init(string: String) {
        self.format = .binary
        self.type = .varString
        var buffer = ByteBufferAllocator().buffer(capacity: string.utf8.count)
        buffer.writeString(string)
        self.buffer = buffer
        self.isUnsigned = false
    }
    
    public init(int: Int) {
        self.format = .binary
        self.type = .longlong
        assert(Int.bitWidth == 64)
        var buffer = ByteBufferAllocator().buffer(capacity: 8)
        buffer.writeInteger(int, endianness: .little)
        self.isUnsigned = false
        self.buffer = buffer
    }
    
    public init(bool: Bool) {
        self.format = .binary
        self.type = .bit
        var buffer = ByteBufferAllocator().buffer(capacity: 1)
        buffer.writeInteger(bool ? 1 : 0, endianness: .little, as: UInt8.self)
        self.isUnsigned = true
        self.buffer = buffer
    }
    
    public init(double: Double) {
        var double = double
        self.format = .binary
        self.type = .double
        var buffer = ByteBufferAllocator().buffer(capacity: MemoryLayout<Double>.size)
        _ = Swift.withUnsafeBytes(of: &double) { ptr in
            buffer.writeBytes(ptr)
        }
        self.isUnsigned = false
        self.buffer = buffer
    }
    
    public init(float: Float) {
        var float = float
        self.format = .binary
        self.type = .float
        var buffer = ByteBufferAllocator().buffer(capacity: MemoryLayout<Float>.size)
        _ = Swift.withUnsafeBytes(of: &float) { ptr in
            buffer.writeBytes(ptr)
        }
        self.isUnsigned = false
        self.buffer = buffer
    }
    
    public var description: String {
        if self.buffer == nil {
            return "nil"
        } else {
            switch self.type {
            case .longlong, .long, .int24, .short, .tiny:
                return self.int!.description
            case .bit:
                return self.bool!.description
            default:
                return self.string?.debugDescription ?? "<n/a>"
            }
        }
    }
    
    public var string: String? {
        guard var buffer = self.buffer else {
            return nil
        }
        switch format {
        case .text:
            return buffer.readString(length: buffer.readableBytes)
        default:
            switch self.type {
            case .varchar, .varString, .string, .blob:
                return buffer.readString(length: buffer.readableBytes)
            case .longlong, .long, .int24, .short, .tiny, .bit:
                return self.int?.description
            default:
                return nil
            }
        }
    }
    
    public var bool: Bool? {
        switch self.string {
        case "true", "1": return true
        case "false", "0": return false
        default: return nil
        }
    }
    
    public var int: Int? {
        guard var buffer = self.buffer else {
            return nil
        }
        switch format {
        case .text:
            return buffer.readString(length: buffer.readableBytes).flatMap(Int.init)
        default:
            switch self.type {
            case .varchar, .varString:
                return buffer.readString(length: buffer.readableBytes).flatMap(Int.init)
            case .longlong:
                #warning("TODO: consider throwing on overflow")
                if self.isUnsigned {
                    return buffer.readInteger(endianness: .little, as: UInt64.self)
                        .flatMap(Int.init)
                } else {
                    return buffer.readInteger(endianness: .little, as: Int64.self)
                        .flatMap(Int.init)
                }
            case .long, .int24:
                #warning("TODO: consider throwing on overflow")
                if self.isUnsigned {
                    return buffer.readInteger(endianness: .little, as: UInt32.self)
                        .flatMap(Int.init)
                } else {
                    return buffer.readInteger(endianness: .little, as: Int32.self)
                        .flatMap(Int.init)
                }
            case .short:
                #warning("TODO: consider throwing on overflow")
                if self.isUnsigned {
                    return buffer.readInteger(endianness: .little, as: UInt16.self)
                        .flatMap(Int.init)
                } else {
                    return buffer.readInteger(endianness: .little, as: Int16.self)
                        .flatMap(Int.init)
                }
            case .tiny, .bit:
                #warning("TODO: consider throwing on overflow")
                if self.isUnsigned {
                    return buffer.readInteger(endianness: .little, as: UInt8.self)
                        .flatMap(Int.init)
                } else {
                    return buffer.readInteger(endianness: .little, as: Int8.self)
                        .flatMap(Int.init)
                }
            default:
                return nil
            }
        }
    }
    
    public init(
        type: MySQLProtocol.DataType,
        format: Format = .binary,
        buffer: ByteBuffer?,
        isUnsigned: Bool = false
    ) {
        self.type = type
        self.format = format
        self.buffer = buffer
        self.isUnsigned = isUnsigned
    }
}

import struct Foundation.Calendar
import struct Foundation.Date
import struct Foundation.DateComponents
import struct Foundation.TimeZone

/// MARK: Date

/// MYSQL_TIME
///
/// This structure is used to send and receive DATE, TIME, DATETIME, and TIMESTAMP data directly to and from the server.
/// Set the buffer member to point to a MYSQL_TIME structure, and set the buffer_type member of a MYSQL_BIND structure
/// to one of the temporal types (MYSQL_TYPE_TIME, MYSQL_TYPE_DATE, MYSQL_TYPE_DATETIME, MYSQL_TYPE_TIMESTAMP).
///
/// https://dev.mysql.com/doc/refman/5.7/en/c-api-prepared-statement-data-structures.html
public struct MySQLTime: Equatable {
    /// The year
    public var year: UInt16
    
    /// The month of the year
    public var month: UInt8
    
    /// The day of the month
    public var day: UInt8
    
    /// The hour of the day
    public var hour: UInt8
    
    /// The minute of the hour
    public var minute: UInt8
    
    /// The second of the minute
    public var second: UInt8
    
    /// The fractional part of the second in microseconds
    public var microsecond: UInt32
}

extension MySQLTime: CustomStringConvertible {
    public var description: String {
        return "\(self.year)-\(self.month)-\(self.day) \(self.hour):\(self.minute):\(self.second).\(self.microsecond)"
    }
}

extension Calendar {
    func ccomponent<I>(_ component: Calendar.Component, from date: Date) -> I where I: FixedWidthInteger {
        return numericCast(self.component(component, from: date))
    }
}

private final class _DateComponentsWrapper {
    var value = DateComponents(
        calendar:  Calendar(identifier: .gregorian),
        timeZone: TimeZone(secondsFromGMT: 0)!
    )
}

private var _comps = ThreadSpecificVariable<_DateComponentsWrapper>()


extension Date {
    public init(mysqlTime: MySQLTime) {
        let comps: _DateComponentsWrapper
        if let existing = _comps.currentValue {
            comps = existing
        } else {
            let new = _DateComponentsWrapper()
            _comps.currentValue = new
            comps = new
        }
        /// For some reason comps.nanosecond is `nil` on linux :(
        let nanosecond: Int
        #if os(macOS)
        nanosecond = numericCast(mysqlTime.microsecond) * 1_000
        #else
        nanosecond = 0
        #endif
        
        comps.value.year = numericCast(mysqlTime.year)
        comps.value.month = numericCast(mysqlTime.month)
        comps.value.day = numericCast(mysqlTime.day)
        comps.value.hour = numericCast(mysqlTime.hour)
        comps.value.minute = numericCast(mysqlTime.minute)
        comps.value.second = numericCast(mysqlTime.second)
        comps.value.nanosecond = numericCast(mysqlTime.microsecond) * 1_000
        
        guard let date = comps.value.date else {
            fatalError("invalid date")
        }
        
        /// For some reason comps.nanosecond is `nil` on linux :(
        #if os(macOS)
        self = date
        #else
        self = date.addingTimeInterval(TimeInterval(time.microsecond) / 1_000_000)
        #endif
    }
    
    public var mysqlTime: MySQLTime {
        let comps = Calendar(identifier: .gregorian)
            .dateComponents(in: TimeZone(secondsFromGMT: 0)!, from: self)
        
        let microsecond = UInt32(abs(timeIntervalSince1970.truncatingRemainder(dividingBy: 1) * 1_000_000))
        
        return MySQLTime(
            year: numericCast(comps.year ?? 0),
            month: numericCast(comps.month ?? 0),
            day: numericCast(comps.day ?? 0),
            hour: numericCast(comps.hour ?? 0),
            minute: numericCast(comps.minute ?? 0),
            second: numericCast(comps.second ?? 0),
            microsecond: microsecond
        )
    }
}

extension MySQLData {
    public init(time: MySQLTime) {
        var buffer = ByteBufferAllocator().buffer(capacity: 0)
        buffer.writeInteger(time.year, endianness: .little)
        buffer.writeInteger(time.month, endianness: .little)
        buffer.writeInteger(time.day, endianness: .little)
        buffer.writeInteger(time.hour, endianness: .little)
        buffer.writeInteger(time.minute, endianness: .little)
        buffer.writeInteger(time.second, endianness: .little)
        buffer.writeInteger(time.microsecond, endianness: .little)
        self.init(type: .timestamp, format: .binary, buffer: buffer, isUnsigned: false)
    }
    
    public var time: MySQLTime? {
        guard var buffer = self.buffer else {
            return nil
        }
        switch self.type {
        case .timestamp:
            let time: MySQLTime
            switch buffer.readableBytes {
            case 0:
                /// if year, month, day, hour, minutes, seconds and micro_seconds are all 0, length is 0 and no other field is sent
                time = MySQLTime(year: 0, month: 0, day: 0, hour: 0, minute: 0, second: 0, microsecond: 0)
            case 4:
                /// if hour, minutes, seconds and micro_seconds are all 0, length is 4 and no other field is sent
                time = MySQLTime(
                    year: buffer.readInteger(endianness: .little)!,
                    month: buffer.readInteger(endianness: .little)!,
                    day: buffer.readInteger(endianness: .little)!,
                    hour: 0,
                    minute: 0,
                    second: 0,
                    microsecond: 0
                )
            case 7:
                /// if micro_seconds is 0, length is 7 and micro_seconds is not sent
                time = MySQLTime(
                    year: buffer.readInteger(endianness: .little)!,
                    month: buffer.readInteger(endianness: .little)!,
                    day: buffer.readInteger(endianness: .little)!,
                    hour: buffer.readInteger(endianness: .little)!,
                    minute: buffer.readInteger(endianness: .little)!,
                    second: buffer.readInteger(endianness: .little)!,
                    microsecond: 0
                )
            case 11:
                /// otherwise length is 11
                time = MySQLTime(
                    year: buffer.readInteger(endianness: .little)!,
                    month: buffer.readInteger(endianness: .little)!,
                    day: buffer.readInteger(endianness: .little)!,
                    hour: buffer.readInteger(endianness: .little)!,
                    minute: buffer.readInteger(endianness: .little)!,
                    second: buffer.readInteger(endianness: .little)!,
                    microsecond: buffer.readInteger(endianness: .little)!
                )
            default: fatalError("Invalid MYSQL_TIME length")
            }
            return time
        default: return nil
        }
    }
}

extension MySQLData {
    public init(date: Date) {
        self.init(time: date.mysqlTime)
    }
    
    public var date: Date? {
        guard let time = self.time else {
            return nil
        }
        return Date(mysqlTime: time)
    }
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
