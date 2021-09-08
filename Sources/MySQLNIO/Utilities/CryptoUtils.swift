import Crypto

func sha256(_ messages: ByteBuffer...) -> ByteBuffer {
    let digest = SHA256.hash(data: [UInt8](messages.combine().readableBytesView))
    var buffer = ByteBufferAllocator().buffer(capacity: SHA256.Digest.byteCount)
    buffer.writeBytes(digest)
    return buffer
}

func sha1(_ messages: ByteBuffer...) -> ByteBuffer {
    let digest = Insecure.SHA1.hash(data: [UInt8](messages.combine().readableBytesView))
    var buffer = ByteBufferAllocator().buffer(capacity: Insecure.SHA1.Digest.byteCount)
    buffer.writeBytes(digest)
    return buffer
}

func xor(_ a: ByteBuffer, _ b: ByteBuffer) -> ByteBuffer {
    assert(a.readableBytes == b.readableBytes)
    var output = ByteBufferAllocator().buffer(capacity: a.readableBytes)
    for i in 0..<a.readableBytes {
        output.writeInteger(a.getInteger(at: i, as: UInt8.self)! ^ b.getInteger(at: i, as: UInt8.self)!)
    }
    return output
}

func xor_pattern(_ a: ByteBuffer, _ b: ByteBuffer) -> ByteBuffer {
    var output = ByteBufferAllocator().buffer(capacity: a.readableBytes)
    for i in 0..<a.readableBytes {
        output.writeInteger(a.getInteger(at: i, as: UInt8.self)! ^ b.getInteger(at: i % b.readableBytes, as: UInt8.self)!)
    }
    return output
}

extension Array where Element == ByteBuffer {
    func combine() -> ByteBuffer {
        switch self.count {
        case 1: return self[0]
        default:
            var base = ByteBufferAllocator().buffer(capacity: 0)
            self.forEach { buffer in
                var copy = buffer
                base.writeBuffer(&copy)
            }
            return base
        }
    }
}

private extension OpaquePointer {
    func convert<T>() -> UnsafePointer<T> {
        return .init(self)
    }
    
    func convert<T>() -> UnsafeMutablePointer<T> {
        return .init(self)
    }
    
    func convert() -> OpaquePointer {
        return self
    }
}

private extension UnsafePointer {
    func convert() -> OpaquePointer {
        return .init(self)
    }
}

private extension UnsafeMutablePointer {
    func convert() -> OpaquePointer {
        return .init(self)
    }
}
