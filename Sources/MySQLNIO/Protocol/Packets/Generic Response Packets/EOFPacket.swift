import NIOCore

struct EOFPacket {
    let warningCount: UInt16
    let serverStatus: ServerStatusFlags

    init?(from packet: inout ByteBuffer) {
        guard let header = packet.readInteger(as: UInt8.self), header == 0xFE else { return nil }
        guard let warningCount = packet.readInteger(endianness: .little, as: UInt16.self) else { return nil }
        guard let serverStatusRawValue = packet.readInteger(endianness: .little, as: UInt16.self) else { return nil }
        self.warningCount = warningCount
        self.serverStatus = ServerStatusFlags(rawValue: serverStatusRawValue)
    }
}
