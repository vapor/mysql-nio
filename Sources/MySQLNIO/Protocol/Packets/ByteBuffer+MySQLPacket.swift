import NIOCore

extension ByteBuffer {
    var mySQLHeaderFlag: UInt8? {
        self.getInteger(at: self.readerIndex)
    }

    var isErrorPacket: Bool {
        self.mySQLHeaderFlag == 0xFF
    }

    func isOKPacket(capabilities: MySQLCapabilities) -> Bool {
        guard (7...Int(UInt24.max)).contains(self.readableBytes) else { return false }
        if capabilities.contains(.clientDeprecateEOF) {
            return self.mySQLHeaderFlag == 0x00
        } else {
            return self.mySQLHeaderFlag == 0x00 || self.mySQLHeaderFlag == 0xFE
        }
    }

    var isEOFPacket: Bool {
        self.mySQLHeaderFlag == 0xFE && self.readableBytes < 8
    }
}
