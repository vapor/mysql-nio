public struct MySQLData {
    public enum Format {
        case binary
        case text
    }
    
    public let type: MySQLProtocol.DataType
    public let format: Format
    public let buffer: ByteBuffer?
    
    /// If `true`, this value is unsigned.
    public var isUnsigned: Bool
    
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
                print(buffer)
                return 0
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
