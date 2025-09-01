import Crypto
import NIOCore

func sha256(_ messages: ByteBuffer...) -> ByteBuffer {
    let digest = SHA256.hash(data: [UInt8](messages.combine().readableBytesView))
    return .init(bytes: digest)
}

func sha1(_ messages: ByteBuffer...) -> ByteBuffer {
    let digest = Insecure.SHA1.hash(data: [UInt8](messages.combine().readableBytesView))
    return .init(bytes: digest)
}

func xor(_ a: ByteBuffer, _ b: ByteBuffer) -> ByteBuffer {
    assert(a.readableBytes == b.readableBytes)
    var output = ByteBufferAllocator().buffer(capacity: a.readableBytes)
    for i in 0..<a.readableBytes {
        output.writeInteger(a.getInteger(at: i, as: UInt8.self)! ^ b.getInteger(at: i, as: UInt8.self)!)
    }
    return output
}

extension Array where Element == ByteBuffer {
    func combine() -> ByteBuffer {
        switch self.count {
        case 1: return self[0]
        default:
            var base = ByteBufferAllocator().buffer(capacity: 0)
            for buffer in self {
                base.writeImmutableBuffer(buffer)
            }
            return base
        }
    }
}
