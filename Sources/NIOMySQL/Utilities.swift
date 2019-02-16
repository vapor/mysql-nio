extension ByteBuffer {
    mutating func readNullTerminatedString() -> String? {
        var copy = self
        scan: while let byte = copy.readInteger(as: UInt8.self) {
            switch byte {
            case 0x00: break scan
            default: break
            }
        }
        defer { self.moveReaderIndex(forwardBy: 1) }
        return self.readString(length: (self.readableBytes - copy.readableBytes) - 1)
    }
    
    mutating func writeNullTerminatedString(_ string: String) {
        self.writeString(string)
        self.writeInteger(0, as: UInt8.self)
    }
    
    var isZeroes: Bool {
        for byte in self.readableBytesView {
            switch byte {
            case 0x00: continue
            default: return false
            }
        }
        return true
    }
}
