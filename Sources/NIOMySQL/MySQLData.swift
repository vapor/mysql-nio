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
                print()
                print(self.type)
                print(self.buffer?.debugDescription)
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
