import NIOCore

struct LocalInfilePacket {
    let fileName: String

    init?(from packet: inout ByteBuffer) {
        guard let header = packet.readInteger(as: UInt8.self), header == 0xFB else { return nil }
        guard let fileName = packet.readString(length: packet.readableBytes) else { return nil }
        self.fileName = fileName
    }
}
