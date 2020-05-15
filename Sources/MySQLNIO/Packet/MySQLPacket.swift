public struct MySQLPacket {
    public var payload: ByteBuffer
    
    public init(payload: ByteBuffer) {
        self.payload = payload
    }
    
    public init() {
        self.payload = ByteBufferAllocator().buffer(capacity: 0)
    }
    
    public var isError: Bool {
        return self.headerFlag == 0xFF
    }
    
    public var isOK: Bool {
        return self.headerFlag == 0x00
    }
    
    public var isEOF: Bool {
        return self.headerFlag == 0xFE
    }
    
    var headerFlag: UInt8? {
        return self.payload.getInteger(at: self.payload.readerIndex)
    }
}

extension MySQLPacket: CustomStringConvertible {
    public var description: String {
        let bytes = [UInt8](self.payload.readableBytesView)
        return "\(bytes.prefix(16))... (err: \(self.isError), ok: \(self.isOK), eof: \(self.isEOF))"
    }
}

public protocol MySQLPacketDecodable {
    static func decode(from packet: inout MySQLPacket, capabilities: MySQLProtocol.CapabilityFlags) throws -> Self
}

public protocol MySQLPacketEncodable {
    func encode(to packet: inout MySQLPacket, capabilities: MySQLProtocol.CapabilityFlags) throws
}

extension MySQLPacket {
    public mutating func decode<T>(_ type: T.Type, capabilities: MySQLProtocol.CapabilityFlags) throws -> T
        where T: MySQLPacketDecodable
    {
        return try T.decode(from: &self, capabilities: capabilities)
    }
    
    public static func encode<T>(_ type: T, capabilities: MySQLProtocol.CapabilityFlags) throws -> MySQLPacket
        where T: MySQLPacketEncodable
    {
        var packet = MySQLPacket()
        try type.encode(to: &packet, capabilities: capabilities)
        return packet
    }
}
