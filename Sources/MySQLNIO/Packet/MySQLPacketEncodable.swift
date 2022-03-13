public protocol MySQLPacketEncodable {
    func encode(to packet: inout MySQLPacket, capabilities: MySQLProtocol.CapabilityFlags) throws
}

extension MySQLPacket {
    public static func encode<T>(_ type: T, capabilities: MySQLProtocol.CapabilityFlags) throws -> MySQLPacket
        where T: MySQLPacketEncodable
    {
        var packet = MySQLPacket()
        try type.encode(to: &packet, capabilities: capabilities)
        return packet
    }
}
