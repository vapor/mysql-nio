import struct Foundation.Calendar
import struct Foundation.Date
import struct Foundation.DateComponents
import struct Foundation.TimeInterval
import struct Foundation.TimeZone

/// MARK: Date

/// MYSQL_TIME
///
/// This structure is used to send and receive DATE, TIME, DATETIME, and TIMESTAMP data directly to and from the server.
/// Set the buffer member to point to a MYSQL_TIME structure, and set the buffer_type member of a MYSQL_BIND structure
/// to one of the temporal types (MYSQL_TYPE_TIME, MYSQL_TYPE_DATE, MYSQL_TYPE_DATETIME, MYSQL_TYPE_TIMESTAMP).
///
/// https://dev.mysql.com/doc/refman/5.7/en/c-api-prepared-statement-data-structures.html
public struct MySQLTime: Equatable, CustomStringConvertible, MySQLDataConvertible {
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
    
    /// Creates a new `MySQLTime`.
    public init(year: UInt16, month: UInt8, day: UInt8, hour: UInt8, minute: UInt8, second: UInt8, microsecond: UInt32) {
        self.year = year
        self.month = month
        self.day = day
        self.hour = hour
        self.minute = minute
        self.second = second
        self.microsecond = microsecond
    }
    
    /// Creates a new `MySQLTime` from a Swift Date using current calendar and GMT timezone.
    public init(date: Date) {
        // let comps = Calendar.current.dateComponents(in: .gmt, from: date)
        var rawtime = Int(date.timeIntervalSince1970)
        let tm = gmtime(&rawtime)!.pointee
        self.init(
            year: numericCast(1900 + tm.tm_year),
            month: numericCast(1 + tm.tm_mon),
            day: numericCast(tm.tm_mday),
            hour: numericCast(tm.tm_hour),
            minute: numericCast(tm.tm_min),
            second: numericCast(tm.tm_sec),
            microsecond: UInt32(date.timeIntervalSince1970.microseconds)
        )
    }
    
    /// `MySQLDataConvertible` conformance.
    public init?(mysqlData: MySQLData) {
        guard let time = mysqlData.time else {
            return nil
        }
        self = time
    }
    
    /// Converts this `MySQLTime` to a Swift `Date` using the current calendar and GMT timezone.
    public var date: Date {
        var comps = DateComponents(calendar: .current, timeZone: .gmt)
        /// For some reason comps.nanosecond is `nil` on linux :(
        let nanosecond: Int
        #if os(macOS)
        nanosecond = numericCast(self.microsecond) * 1_000
        #else
        nanosecond = 0
        #endif
        
        comps.year = numericCast(self.year)
        comps.month = numericCast(self.month)
        comps.day = numericCast(self.day)
        comps.hour = numericCast(self.hour)
        comps.minute = numericCast(self.minute)
        comps.second = numericCast(self.second)
        comps.nanosecond = numericCast(self.microsecond) * 1_000
        
        guard let date = comps.date else {
            fatalError("invalid date")
        }
        
        /// For some reason comps.nanosecond is `nil` on linux :(
        #if os(macOS)
        return date
        #else
        return date.addingTimeInterval(TimeInterval(self.microsecond) / 1_000_000)
        #endif

    }
    
    /// `MySQLDataConvertible` conformance.
    public var mysqlData: MySQLData? {
        return .init(time: self)
    }
    
    /// `CustomStringConvertible` conformance.
    public var description: String {
        return self.date.description
    }
}

// MARK: Internal

extension ByteBuffer {
    mutating func writeMySQLTime(_ time: MySQLTime) {
        // always write all the time bytes even though we don't need to
        self.writeInteger(time.year, endianness: .little)
        self.writeInteger(time.month, endianness: .little)
        self.writeInteger(time.day, endianness: .little)
        self.writeInteger(time.hour, endianness: .little)
        self.writeInteger(time.minute, endianness: .little)
        self.writeInteger(time.second, endianness: .little)
        self.writeInteger(time.microsecond, endianness: .little)
    }
    
    mutating func readMySQLTime() -> MySQLTime? {
        let time: MySQLTime
        switch self.readableBytes {
        case 0:
            // if year, month, day, hour, minutes, seconds and micro_seconds are all 0, length is 0 and no other field is sent
            time = MySQLTime(year: 0, month: 0, day: 0, hour: 0, minute: 0, second: 0, microsecond: 0)
        case 4:
            // if hour, minutes, seconds and micro_seconds are all 0, length is 4 and no other field is sent
            time = MySQLTime(
                year: self.readInteger(endianness: .little)!,
                month: self.readInteger(endianness: .little)!,
                day: self.readInteger(endianness: .little)!,
                hour: 0,
                minute: 0,
                second: 0,
                microsecond: 0
            )
        case 7:
            // if micro_seconds is 0, length is 7 and micro_seconds is not sent
            time = MySQLTime(
                year: self.readInteger(endianness: .little)!,
                month: self.readInteger(endianness: .little)!,
                day: self.readInteger(endianness: .little)!,
                hour: self.readInteger(endianness: .little)!,
                minute: self.readInteger(endianness: .little)!,
                second: self.readInteger(endianness: .little)!,
                microsecond: 0
            )
        case 11:
            // otherwise length is 11
            time = MySQLTime(
                year: self.readInteger(endianness: .little)!,
                month: self.readInteger(endianness: .little)!,
                day: self.readInteger(endianness: .little)!,
                hour: self.readInteger(endianness: .little)!,
                minute: self.readInteger(endianness: .little)!,
                second: self.readInteger(endianness: .little)!,
                microsecond: self.readInteger(endianness: .little)!
            )
        default: return nil
        }
        return time
    }
}

// MARK: Private

private extension TimeInterval {
    var microseconds: Double {
        let fractionalPart = self.truncatingRemainder(dividingBy: 1)
        return fractionalPart * 1_000_000
    }
}

private extension TimeZone {
    static var gmt: TimeZone {
        return _gmt
    }
}

private let _gmt = TimeZone(secondsFromGMT: 0)!
