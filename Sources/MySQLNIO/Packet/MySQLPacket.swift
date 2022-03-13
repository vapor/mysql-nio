import NIOCore

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

public protocol MySQLPacketCodable: MySQLPacketDecodable, MySQLPacketEncodable {}
