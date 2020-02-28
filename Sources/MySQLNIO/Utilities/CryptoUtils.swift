import Crypto

func sha256(_ messages: ByteBuffer...) -> ByteBuffer {
    let digest = SHA256.hash(data: [UInt8](messages.combine().readableBytesView))
    var buffer = ByteBufferAllocator().buffer(capacity: 0)
    buffer.writeBytes(digest)
    return buffer
}

func sha1(_ messages: ByteBuffer...) -> ByteBuffer {
    let digest = Insecure.SHA1.hash(data: [UInt8](messages.combine().readableBytesView))
    var buffer = ByteBufferAllocator().buffer(capacity: 0)
    buffer.writeBytes(digest)
    return buffer
}

func xor(_ a: ByteBuffer, _ b: ByteBuffer) -> ByteBuffer {
    var a = a
    var b = b
    var output = ByteBufferAllocator().buffer(capacity: min(a.readableBytes, b.readableBytes))
    while let a = a.readInteger(as: UInt8.self), let b = b.readInteger(as: UInt8.self) {
        output.writeInteger(a ^ b)
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
