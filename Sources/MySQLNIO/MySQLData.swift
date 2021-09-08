@_exported import struct Foundation.Date
@_exported import struct Foundation.UUID
@_exported import struct Foundation.Decimal

import class Foundation.JSONEncoder
import class Foundation.JSONDecoder
import struct Foundation.Data

public struct MySQLData: CustomStringConvertible, ExpressibleByStringLiteral, ExpressibleByIntegerLiteral, ExpressibleByBooleanLiteral, MySQLDataConvertible {
    public enum Format {
        case binary
        case text
    }
    
    public static var null: MySQLData {
        return .init(type: .null, buffer: nil)
    }
    
    public let type: MySQLProtocol.DataType
    public let format: Format
    public let buffer: ByteBuffer?
    
    /// If `true`, this value is unsigned.
    public var isUnsigned: Bool
    
    // MARK: Initializers
    
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
        self.type = .tiny
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

    public init(decimal: Decimal) {
        let string = decimal.description
        self.format = .binary
        self.type = .newdecimal
        var buffer = ByteBufferAllocator().buffer(capacity: string.utf8.count)
        buffer.writeString(string)
        self.buffer = buffer
        self.isUnsigned = false
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

    public init(uuid: UUID) {
        self.format = .binary
        self.type = .blob
        var buffer = ByteBufferAllocator().buffer(capacity: 16)
        var cuuid = uuid.uuid
        _ = Swift.withUnsafeBytes(of: &cuuid) { ptr in
            buffer.writeBytes(ptr)
        }
        self.isUnsigned = false
        self.buffer = buffer
    }
    
    public init(date: Date) {
        self.init(time: .init(date: date))
    }
    
    public init(time: MySQLTime) {
        var buffer = ByteBufferAllocator().buffer(capacity: 12)
        var type: MySQLProtocol.DataType = .datetime
        buffer.writeMySQLTime(time, as: &type)
        self.init(type: type, format: .binary, buffer: buffer, isUnsigned: false)
    }

    private struct Wrapper: Encodable {
        let encodable: Encodable
        init(_ encodable: Encodable) {
            self.encodable = encodable
        }
        func encode(to encoder: Encoder) throws {
            try self.encodable.encode(to: encoder)
        }
    }

    public init(json value: Encodable) throws {
        let json = JSONEncoder()
        let data = try json.encode(Wrapper(value))
        var buffer = ByteBufferAllocator().buffer(capacity: data.count)
        buffer.writeBytes(data)
        self.init(
            type: .string,
            format: .text,
            buffer: buffer,
            isUnsigned: true
        )
    }
    
    // MARK: Literal Initializers
    
    public init(booleanLiteral value: Bool) {
        self.init(bool: value)
    }
    
    public init(stringLiteral value: String) {
        self.init(string: value)
    }
    
    public init(integerLiteral value: Int) {
        self.init(int: value)
    }
    
    public init?(mysqlData: MySQLData) {
        self = mysqlData
    }
    
    // MARK: Converters

    public func json<Value>(as type: Value.Type) throws -> Value?
        where Value: Decodable
    {
        guard var buffer = self.buffer else {
            return nil
        }
        guard let data = buffer.readBytes(length: buffer.readableBytes) else {
            return nil
        }
        return try JSONDecoder().decode(Value.self, from: Data(data))
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
            case .varchar, .varString, .string, .blob, .tinyBlob, .mediumBlob, .longBlob, .null:
                return buffer.readString(length: buffer.readableBytes)
            case .longlong, .long, .int24, .short, .tiny, .bit:
                return self.int?.description
            default:
                return nil
            }
        }
    }

    public var double: Double? {
        switch self.format {
        case .binary:
            switch self.type {
            case .double:
                guard var buffer = self.buffer else {
                    return nil
                }
                guard let bytes = buffer.readBytes(length: MemoryLayout<Double>.size) else {
                    return nil
                }
                var double: Double = 0
                Swift.withUnsafeMutableBytes(of: &double) { buffer in
                    buffer.copyBytes(from: bytes)
                }
                return double
            case .float:
                return self.float.flatMap(Double.init)
            case .newdecimal:
                guard var buffer = self.buffer else {
                    return nil
                }
                return buffer.readString(length: buffer.readableBytes)
                    .flatMap(Double.init)
            default:
                return nil
            }
        case .text:
            return self.string.flatMap(Double.init)
        }
    }

    public var decimal: Decimal? {
        switch self.format {
        case .binary:
            switch self.type {
            case .double:
                guard var buffer = self.buffer else {
                    return nil
                }
                guard let bytes = buffer.readBytes(length: MemoryLayout<Double>.size) else {
                    return nil
                }
                var double: Double = 0
                Swift.withUnsafeMutableBytes(of: &double) { buffer in
                    buffer.copyBytes(from: bytes)
                }
                return Decimal(floatLiteral: double)
            case .float:
                return self.float.flatMap { Decimal(Double($0)) }
            case .newdecimal:
                guard var buffer = self.buffer else {
                    return nil
                }
                return buffer.readString(length: buffer.readableBytes)
                    .flatMap{ Decimal(string: $0)  }
            case .varchar, .varString, .string, .blob, .tinyBlob, .mediumBlob, .longBlob:
                guard var buffer = self.buffer else {
                    return nil
                }
                return buffer.readString(length: buffer.readableBytes)
                        .flatMap{ Decimal(string: $0)  }
            default:
                return nil
            }
        case .text:
            return self.string.flatMap{ Decimal(string: $0) }
        }
    }

    public var float: Float? {
        switch self.format {
        case .binary:
            switch self.type {
            case .float:
                guard var buffer = self.buffer else {
                    return nil
                }
                guard let bytes = buffer.readBytes(length: MemoryLayout<Float>.size) else {
                    return nil
                }
                var float: Float = 0
                Swift.withUnsafeMutableBytes(of: &float) { buffer in
                    buffer.copyBytes(from: bytes)
                }
                return float
            case .double:
                return self.double.flatMap(Float.init)
            case .newdecimal:
                guard var buffer = self.buffer else {
                    return nil
                }
                return buffer.readString(length: buffer.readableBytes)
                    .flatMap(Float.init)
            default:
                return nil
            }
        case .text:
            return self.string.flatMap(Float.init)
        }
    }

    public var uuid: UUID? {
        switch self.format {
        case .binary:
            guard var buffer = self.buffer else {
                return nil
            }
            guard buffer.readableBytes == 16 else {
                return nil
            }
            guard let bytes = buffer.readBytes(length: 16) else {
                return nil
            }
            return UUID(uuid: (
                bytes[0], bytes[1], bytes[2], bytes[3],
                bytes[4], bytes[5], bytes[6], bytes[7],
                bytes[8], bytes[9], bytes[10], bytes[11],
                bytes[12], bytes[13], bytes[14], bytes[15]
            ))
        case .text:
            return self.string.flatMap(UUID.init)
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
        self.fwi()
    }

    public var int8: Int8? {
        self.fwi()
    }

    public var int16: Int16? {
        self.fwi()
    }

    public var int32: Int32? {
        self.fwi()
    }

    public var int64: Int64? {
        self.fwi()
    }

    public var uint: UInt? {
        self.fwi()
    }

    public var uint8: UInt8? {
        self.fwi()
    }

    public var uint16: UInt16? {
        self.fwi()
    }

    public var uint32: UInt32? {
        self.fwi()
    }

    public var uint64: UInt64? {
        self.fwi()
    }

    private func fwi<I>(_ type: I.Type = I.self) -> I?
        where I: FixedWidthInteger
    {
        guard var buffer = self.buffer else {
            return nil
        }
        switch format {
        case .text:
            return buffer.readString(length: buffer.readableBytes).flatMap(I.init)
        default:
            switch self.type {
            case .varchar, .varString:
                return buffer.readString(length: buffer.readableBytes).flatMap(I.init)
            case .longlong:
                if self.isUnsigned {
                    return buffer.readInteger(endianness: .little, as: UInt64.self)
                        .flatMap(I.init)
                } else {
                    return buffer.readInteger(endianness: .little, as: Int64.self)
                        .flatMap(I.init)
                }
            case .long, .int24:
                if self.isUnsigned {
                    return buffer.readInteger(endianness: .little, as: UInt32.self)
                        .flatMap(I.init)
                } else {
                    return buffer.readInteger(endianness: .little, as: Int32.self)
                        .flatMap(I.init)
                }
            case .short:
                if self.isUnsigned {
                    return buffer.readInteger(endianness: .little, as: UInt16.self)
                        .flatMap(I.init)
                } else {
                    return buffer.readInteger(endianness: .little, as: Int16.self)
                        .flatMap(I.init)
                }
            case .tiny, .bit:
                if self.isUnsigned {
                    return buffer.readInteger(endianness: .little, as: UInt8.self)
                        .flatMap(I.init)
                } else {
                    return buffer.readInteger(endianness: .little, as: Int8.self)
                        .flatMap(I.init)
                }
            case .newdecimal:
                return buffer.readString(length: buffer.readableBytes)
                    .flatMap(I.init)
            default:
                return nil
            }
        }
    }
    
    public var date: Date? {
        guard let time = self.time else {
            return nil
        }
        return time.date
    }
    
    public var time: MySQLTime? {
        guard var buffer = self.buffer else {
            return nil
        }
        switch self.type {
        case .timestamp, .datetime, .date, .time:
            return buffer.readMySQLTime()
        default: return nil
        }
    }
    
    public var mysqlData: MySQLData? {
        return self
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
            case .datetime, .timestamp:
                return (self.time!.date ?? Date(timeIntervalSince1970: 0)).description
            case .varchar, .varString, .string:
                return self.string!.debugDescription
            case .double:
                return self.double!.description
            case .float:
                return self.float!.description
            case .blob:
                return Data(self.buffer!.readableBytesView).description
            default:
                return "<\(self.type)>"
            }
        }
    }
}
