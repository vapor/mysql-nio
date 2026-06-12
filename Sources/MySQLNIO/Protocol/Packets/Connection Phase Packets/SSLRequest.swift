import NIOCore

struct SSLRequest {
    let clientCapabilities: MySQLCapabilities
    let maxPacketSize: UInt32
    let clientDefaultCharacterSetAndCollation: MySQLCollation

    func write(to packet: inout ByteBuffer, capabilities: MySQLCapabilities) {
        guard clientCapabilities.contains(.ssl) else {
            preconditionFailure("The CLIENT_SSL capability flag must be set inside the SSL Connection Request Packet.")
        }
        if capabilities.contains(.clientProtocol41) {
            packet.writeInteger(UInt32(self.clientCapabilities.rawValue & 0xFFFF_FFFF), endianness: .little)
            packet.writeInteger(self.maxPacketSize, endianness: .little)
            packet.writeInteger(self.clientDefaultCharacterSetAndCollation.idForHandshake)
            packet.writeBytes([UInt8](repeating: 0, count: 19))  // reserved.
            if !capabilities.contains(.clientMySQL) {
                packet.writeInteger(UInt32(self.clientCapabilities.rawValue >> 32), endianness: .little)
            } else {
                packet.writeBytes([UInt8](repeating: 0, count: 4))  // reserved.
            }
        } else {
            packet.writeInteger(UInt16(self.clientCapabilities.rawValue & 0xFFFF), endianness: .little)
            packet.writeBytes([
                UInt8(self.maxPacketSize & 0xFF),
                UInt8((self.maxPacketSize >> 8) & 0xFF),
                UInt8((self.maxPacketSize >> 16) & 0xFF),
            ])
        }
    }
}
