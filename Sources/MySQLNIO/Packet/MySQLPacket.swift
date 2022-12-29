import NIOCore

public struct MySQLPacket {
    public var payload: ByteBuffer
    
    public init(payload: ByteBuffer) {
        self.payload = payload
    }
    
    public init() {
        self.init(payload: ByteBuffer())
    }
    
    public var isError: Bool { self.headerFlag == 0xFF }
    public var isOK: Bool { self.headerFlag == 0x00 }
    public var isEOF: Bool { self.headerFlag == 0xFE && self.payload.writerIndex < 8 } // EOF may be no longer than 7 bytes
    
    var headerFlag: UInt8? { self.payload.getInteger(at: 0) }
}

extension MySQLPacket: CustomStringConvertible {
    public var description: String {
        "\(self.payload.getBytes(at: 0, length: 16) ?? [])... (err: \(self.isError), ok: \(self.isOK), eof: \(self.isEOF))"
    }
}

protocol MySQLPacketCodable: MySQLPacketDecodable, MySQLPacketEncodable {}
