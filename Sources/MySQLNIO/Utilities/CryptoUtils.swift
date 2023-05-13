import Crypto
import Foundation
import NIOCore

func sha256(_ messages: ByteBuffer...) -> ByteBuffer {
    .init(bytes: SHA256.hash(data: [UInt8](messages.combine().readableBytesView)))
}

func sha1(_ messages: ByteBuffer...) -> ByteBuffer {
    .init(bytes: Insecure.SHA1.hash(data: [UInt8](messages.combine().readableBytesView)))
}

func xor(_ a: ByteBuffer, _ b: ByteBuffer) -> ByteBuffer {
    assert(a.readableBytes == b.readableBytes)
    return .init(bytes: zip(a.readableBytesView, b.readableBytesView).map(^))
}

func xor_pattern(_ a: ByteBuffer, _ b: ByteBuffer) -> ByteBuffer {
    var output = a, outView = output.readableBytesView, bView = b.readableBytesView
    for i in outView.indices {
        outView[i] ^= bView[i % bView.count]
    }
    return output
}

extension Array where Element == ByteBuffer {
    func combine() -> ByteBuffer {
        self.reduce(into: .init()) { $0.writeImmutableBuffer($1) }
    }
}
