import CMySQLOpenSSL

func sha256(_ messages: ByteBuffer...) -> ByteBuffer {
    return digest(EVP_sha256().convert(), messages)
}

func sha1(_ messages: ByteBuffer...) -> ByteBuffer {
    return digest(EVP_sha1().convert(), messages)
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

private func digest(_ alg: OpaquePointer, _ messages: [ByteBuffer]) -> ByteBuffer {
    var md = ByteBufferAllocator().buffer(capacity: numericCast(EVP_MAX_MD_SIZE))
    let data = messages.combine()
    var size: UInt32 = 0
    let res = data.withUnsafeReadableBytes { data in
        return md.withUnsafeMutableWritableBytes { md in
            return EVP_Digest(data.baseAddress, data.count, md.baseAddress?.assumingMemoryBound(to: UInt8.self), &size, alg.convert(), nil)
        }
    }
    assert(res == 1, "EVP_Digest failed")
    md.moveWriterIndex(forwardBy: numericCast(size))
    return md
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
