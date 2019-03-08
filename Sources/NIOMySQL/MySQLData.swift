public struct MySQLData {
    public enum Format {
        case binary
        case text
    }
    
    public let type: MySQLProtocol.DataType
    public let format: Format
    public let buffer: ByteBuffer?
    
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
            default:
                return nil
            }
        }
    }
    
    public init(type: MySQLProtocol.DataType, format: Format, buffer: ByteBuffer?) {
        self.type = type
        self.format = format
        self.buffer = buffer
    }
}
