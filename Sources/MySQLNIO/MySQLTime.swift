import NIOCore
import Logging
import Foundation

/// `MYSQL_TIME`
///
/// This structure is used to send and receive `DATE`, `TIME`, `DATETIME`, and `TIMESTAMP` data directly to and from the server.
/// Set the buffer member to point to a `MYSQL_TIME` structure, and set the `buffer_type` member of a `MYSQL_BIND` structure
/// to one of the temporal types (`MYSQL_TYPE_TIME`, `MYSQL_TYPE_DATE`, `MYSQL_TYPE_DATETIME`, `MYSQL_TYPE_TIMESTAMP`).
///
/// https://dev.mysql.com/doc/refman/5.7/en/c-api-prepared-statement-data-structures.html
public struct MySQLTime: Equatable, MySQLDataConvertible {
    /// The year
    public var year: UInt16?
    
    /// The month of the year
    public var month: UInt16?
    
    /// The day of the month
    public var day: UInt16?
    
    /// The hour of the day
    public var hour: UInt16?
    
    /// The minute of the hour
    public var minute: UInt16?

    /// The second of the minute
    public var second: UInt16?
    
    /// The fractional part of the second in microseconds
    public var microsecond: UInt32?
    
    /// Creates a new ``MySQLTime``.
    public init(
        year: UInt16? = nil,
        month: UInt16? = nil,
        day: UInt16? = nil,
        hour: UInt16? = nil,
        minute: UInt16? = nil,
        second: UInt16? = nil,
        microsecond: UInt32? = nil
    ) {
        self.year = year
        self.month = month
        self.day = day
        self.hour = hour
        self.minute = minute
        self.second = second
        self.microsecond = microsecond
    }
    
    /// Creates a new ``MySQLTime`` from a Swift ``Date`` using current calendar and GMT timezone.
    public init(date: Date) {
        // let comps = Calendar.current.dateComponents(in: .gmt, from: date)
        var rawtime = Int(date.timeIntervalSince1970)
        var tms = tm()
        gmtime_r(&rawtime, &tms)
        var microseconds = date.timeIntervalSince1970.microseconds
        if microseconds < 0.0 {
            microseconds = 1_000_000 - microseconds
        }
        self.init(
            year: numericCast(1900 + tms.tm_year),
            month: numericCast(1 + tms.tm_mon),
            day: numericCast(tms.tm_mday),
            hour: numericCast(tms.tm_hour),
            minute: numericCast(tms.tm_min),
            second: numericCast(tms.tm_sec),
            microsecond: UInt32(microseconds)
        )
    }
    
    /// Parse a new ``MySQLTime`` from a ``String`` in `"yyyy-MM-dd hh:mm:ss"` format.
    public init?(_ string: String) {
        let parts = string.split { c in
            ":- ".contains(c)
        }
        guard parts.count >= 6,
              let year = UInt16(parts[0]),
              let month = UInt16(parts[1]),
              let day = UInt16(parts[2]),
              let hour = UInt16(parts[3]),
              let minute = UInt16(parts[4]),
              let second = UInt16(parts[5])
        else {
            return nil
        }
        self.init(year: year, month: month, day: day, hour: hour, minute: minute, second: second)
    }
    
    /// See ``MySQLDataConvertible/init(mysqlData:)``.
    public init?(mysqlData: MySQLData) {
        guard let time = mysqlData.time else {
            return nil
        }
        self = time
    }
    
    /// Converts this ``MySQLTime`` to a Swift ``Date`` using the current calendar and GMT timezone.
    public var date: Date? {
        var comps = DateComponents(
            calendar:  Calendar(identifier: .gregorian),
            timeZone: .gmt
        )

        if let year = self.year, let month = self.month, let day = self.day {
            comps.year = numericCast(year)
            comps.month = numericCast(month)
            comps.day = numericCast(day)
        }

        if let hour = self.hour, let minute = self.minute, let second = self.second {
            comps.hour = numericCast(hour)
            comps.minute = numericCast(minute)
            comps.second = numericCast(second)
        }

        if let microsecond = self.microsecond {
            comps.nanosecond = numericCast(microsecond) * 1_000
        }

        guard let date = comps.date else {
            return nil
        }

        return date
    }
    
    /// See ``MySQLDataConvertible/mysqlData``.
    public var mysqlData: MySQLData? {
        .init(time: self)
    }
}

// MARK: Internal

extension ByteBuffer {
    mutating func writeMySQLTime(_ time: MySQLTime, as type: inout MySQLProtocol.DataType) {
        switch (
            time.year, time.month, time.day,
            time.hour, time.minute, time.second,
            time.microsecond
        ) {
        case (
            .none, .none, .none,
            .none, .none, .none,
            .none
        ):
            // null
            break
        case (
            .some(let year), .some(let month), .some(let day),
            .none, .none, .none,
            .none
        ):
            // date
            type = .date
            self.writeInteger(year, endianness: .little, as: UInt16.self)
            self.writeInteger(numericCast(month), endianness: .little, as: UInt8.self)
            self.writeInteger(numericCast(day), endianness: .little, as: UInt8.self)
        case (
            .some(let year), .some(let month), .some(let day),
            .some(let hour), .some(let minute), .some(let second),
            .none
        ):
            // date + time
            type = .datetime
            self.writeInteger(year, endianness: .little, as: UInt16.self)
            self.writeInteger(numericCast(month), endianness: .little, as: UInt8.self)
            self.writeInteger(numericCast(day), endianness: .little, as: UInt8.self)
            self.writeInteger(numericCast(hour), endianness: .little, as: UInt8.self)
            self.writeInteger(numericCast(minute), endianness: .little, as: UInt8.self)
            self.writeInteger(numericCast(second), endianness: .little, as: UInt8.self)
        case (
            .none, .none, .none,
            .some(let hour), .some(let minute), .some(let second),
            .none
        ):
            // time
            type = .time
            self.writeBytes([0, 0, 0, 0, 0])
            self.writeInteger(numericCast(hour), endianness: .little, as: UInt8.self)
            self.writeInteger(numericCast(minute), endianness: .little, as: UInt8.self)
            self.writeInteger(numericCast(second), endianness: .little, as: UInt8.self)
        case (
            .some(let year), .some(let month), .some(let day),
            .some(let hour), .some(let minute), .some(let second),
            .some(let microsecond)
        ):
            // date + time + fractional seconds
            type = .datetime
            self.writeInteger(year, endianness: .little, as: UInt16.self)
            self.writeInteger(numericCast(month), endianness: .little, as: UInt8.self)
            self.writeInteger(numericCast(day), endianness: .little, as: UInt8.self)
            self.writeInteger(numericCast(hour), endianness: .little, as: UInt8.self)
            self.writeInteger(numericCast(minute), endianness: .little, as: UInt8.self)
            self.writeInteger(numericCast(second), endianness: .little, as: UInt8.self)
            self.writeInteger(microsecond, endianness: .little, as: UInt32.self)
        case (
            .none, .none, .none,
            .some(let hour), .some(let minute), .some(let second),
            .some(let microsecond)
        ):
            // time + fractional seconds
            type = .time
            self.writeBytes([0, 0, 0, 0, 0])
            self.writeInteger(numericCast(hour), endianness: .little, as: UInt8.self)
            self.writeInteger(numericCast(minute), endianness: .little, as: UInt8.self)
            self.writeInteger(numericCast(second), endianness: .little, as: UInt8.self)
            self.writeInteger(microsecond, endianness: .little, as: UInt32.self)
        default:
            Logger(label: "codes.vapor.mysql")
                .warning("Cannot convert MySQLTime to ByteBuffer: \(time)")
        }
    }
    
    mutating func readMySQLTime() -> MySQLTime? {
        let time: MySQLTime
        switch self.readableBytes {
        case 0:
            // null
            time = MySQLTime()
        case 4:
            // date
            time = MySQLTime(
                year: self.readInteger(endianness: .little),
                month: self.readInteger(endianness: .little, as: UInt8.self)
                    .flatMap(numericCast),
                day: self.readInteger(endianness: .little, as: UInt8.self)
                    .flatMap(numericCast)
            )
        case 7:
            // date + time
            time = MySQLTime(
                year: self.readInteger(endianness: .little),
                month: self.readInteger(endianness: .little, as: UInt8.self)
                    .flatMap(numericCast),
                day: self.readInteger(endianness: .little, as: UInt8.self)
                    .flatMap(numericCast),
                hour: self.readInteger(endianness: .little, as: UInt8.self)
                    .flatMap(numericCast),
                minute: self.readInteger(endianness: .little, as: UInt8.self)
                    .flatMap(numericCast),
                second: self.readInteger(endianness: .little, as: UInt8.self)
                    .flatMap(numericCast)
            )
        case 8:
            // time
            self.moveReaderIndex(forwardBy: 5)
            time = MySQLTime(
                hour: self.readInteger(endianness: .little, as: UInt8.self)
                    .flatMap(numericCast),
                minute: self.readInteger(endianness: .little, as: UInt8.self)
                    .flatMap(numericCast),
                second: self.readInteger(endianness: .little, as: UInt8.self)
                    .flatMap(numericCast)
            )
        case 11:
            // date + time + fractional seconds
            time = MySQLTime(
                year: self.readInteger(endianness: .little),
                month: self.readInteger(endianness: .little, as: UInt8.self)
                    .flatMap(numericCast),
                day: self.readInteger(endianness: .little, as: UInt8.self)
                    .flatMap(numericCast),
                hour: self.readInteger(endianness: .little, as: UInt8.self)
                    .flatMap(numericCast),
                minute: self.readInteger(endianness: .little, as: UInt8.self)
                    .flatMap(numericCast),
                second: self.readInteger(endianness: .little, as: UInt8.self)
                    .flatMap(numericCast),
                microsecond: self.readInteger(endianness: .little)
            )
        case 12:
            // time + fractional seconds
            self.moveReaderIndex(forwardBy: 5)
            time = MySQLTime(
                hour: self.readInteger(endianness: .little, as: UInt8.self)
                    .flatMap(numericCast),
                minute: self.readInteger(endianness: .little, as: UInt8.self)
                    .flatMap(numericCast),
                second: self.readInteger(endianness: .little, as: UInt8.self)
                    .flatMap(numericCast),
                microsecond: self.readInteger(endianness: .little)
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
