public struct MySQLData: CustomStringConvertible, ExpressibleByStringLiteral {
    public enum Format {
        case binary
        case text
    }
    
    public let type: MySQLProtocol.DataType
    public let format: Format
    public let buffer: ByteBuffer?
    
    /// If `true`, this value is unsigned.
    public var isUnsigned: Bool
    
    public init(stringLiteral value: String) {
        self.init(string: value)
    }
    
    public init(string: String) {
        self.format = .binary
        self.type = .MYSQL_TYPE_VAR_STRING
        var buffer = ByteBufferAllocator().buffer(capacity: string.utf8.count)
        #warning("TODO: make length encoded")
        buffer.writeInteger(numericCast(string.utf8.count), endianness: .little, as: UInt8.self)
        buffer.writeString(string)
        self.buffer = buffer
        self.isUnsigned = false
    }
    
    public var description: String {
        if self.buffer == nil {
            return "nil"
        } else {
            #warning("TODO: better description based on type")
            return self.string?.debugDescription ?? "<n/a>"
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
            case .MYSQL_TYPE_VARCHAR, .MYSQL_TYPE_VAR_STRING:
                return buffer.readString(length: buffer.readableBytes)
            case .MYSQL_TYPE_LONGLONG:
                return self.int?.description
            default:
                return nil
            }
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
            case .MYSQL_TYPE_VARCHAR, .MYSQL_TYPE_VAR_STRING:
                return buffer.readString(length: buffer.readableBytes).flatMap(Int.init)
            case .MYSQL_TYPE_LONGLONG:
                #warning("TODO: consider throwing on overflow")
                if self.isUnsigned {
                    return buffer.readInteger(endianness: .little, as: UInt64.self)
                        .flatMap(Int.init)
                } else {
                    return buffer.readInteger(endianness: .little, as: Int64.self)
                        .flatMap(Int.init)
                }
            default:
                return nil
            }
        }
    }
    
    public init(
        type: MySQLProtocol.DataType,
        format: Format,
        buffer: ByteBuffer?,
        isUnsigned: Bool
    ) {
        self.type = type
        self.format = format
        self.buffer = buffer
        self.isUnsigned = isUnsigned
    }
}
