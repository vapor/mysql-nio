import CMySQLOpenSSL

func sha256(_ messages: ByteBuffer...) -> ByteBuffer {
    return digest(EVP_sha256(), messages)
}

func sha1(_ messages: ByteBuffer...) -> ByteBuffer {
    return digest(EVP_sha1(), messages)
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
    let context = EVP_MD_CTX_new()
    defer { EVP_MD_CTX_free(context) }
    assert(EVP_DigestInit_ex(context, alg, nil) == 1, "init digest failed")
    messages.combine().withUnsafeReadableBytes { buffer in
        assert(EVP_DigestUpdate(context, buffer.baseAddress, buffer.count) == 1, "update digest failed")
    }
    var digest = ByteBufferAllocator().buffer(capacity: numericCast(EVP_MAX_MD_SIZE))
    var count: UInt32 = 0
    digest.withUnsafeMutableWritableBytes { buffer in
        assert(EVP_DigestFinal_ex(context, buffer.baseAddress?.assumingMemoryBound(to: UInt8.self), &count) == 1, "finalize digest failed")
    }
    digest.moveWriterIndex(forwardBy: numericCast(count))
    return digest
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
