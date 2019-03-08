public struct MySQLData {
    public let type: MySQLProtocol.DataType
    public let buffer: ByteBuffer?
    
    public var string: String? {
        guard var buffer = self.buffer else {
            return nil
        }
        print(self.type)
        switch self.type {
        case .MYSQL_TYPE_VARCHAR, .MYSQL_TYPE_VAR_STRING:
            return buffer.readString(length: buffer.readableBytes)
        default:
            return nil
        }
    }
    
    public init(type: MySQLProtocol.DataType, buffer: ByteBuffer?) {
        self.type = type
        self.buffer = buffer
    }
}
