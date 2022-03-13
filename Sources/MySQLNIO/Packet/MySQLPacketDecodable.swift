public protocol MySQLPacketDecodable {
    static func decode(from packet: inout MySQLPacket, capabilities: MySQLProtocol.CapabilityFlags) throws -> Self
}

extension MySQLPacket {
    public mutating func decode<T>(_ type: T.Type, capabilities: MySQLProtocol.CapabilityFlags) throws -> T
        where T: MySQLPacketDecodable
    {
        return try T.decode(from: &self, capabilities: capabilities)
    }
}
