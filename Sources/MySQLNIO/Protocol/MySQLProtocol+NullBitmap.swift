import NIOCore
import Algorithms

extension MySQLProtocol {
    /// 14.7.2.1 NULL-Bitmap
    ///
    /// The binary protocol sends `NULL` values packed as individual bit flags rather than using a full byte for each
    /// as the text protocol does. This can result in a considerable savings in network bandwidth, with minimal
    /// computational penalty, for large result sets containing many `NULL` values.
    ///
    /// https://dev.mysql.com/doc/internals/en/null-bitmap.html
    struct NullBitmap: CustomStringConvertible, RandomAccessCollection {
        /// This NULL bitmap's static offset. The first two bits of a binary resultset row's NULL bitmap are reserved
        /// (and completely unused most of the time; they serve no purpose whatseover), meaning the `NULL` flag of the
        /// first field in the row (position 0) is stored in the third bit. This appears to be yet another entirely
        /// arbitrary (or at best mandated by technical debt) and pointless massively overcomplicating quirk of MySQL's
        /// wire protocol. It sometimes seems as if the protocol itself is bound and determined to ensure that it shall
        /// be impossible to write a conformant implementation which exhibits temporal efficiency (faster operations).
        /// Length-encoded integers and strings make it impossible to precalculate offsets when parsing or avoid excess
        /// data copying during serialization; endless quirks of packet structure and behavior, usually archaic
        /// remnants of much older server versions, complicate safe data parsing and accurate input validation; the
        /// wire protocol's documentation is breathtakingly incomplete and tends to be inaccurate even it isn't just
        /// plain outdated. Menawhile, the arbitrarily variable-length encoding implied by the NULL bitmap prevents
        /// even being able to parse binary resultset rows as a linear stride even if they contain only fixed-width
        /// fields - and the X protocol doesn't do any better.
        let offset: Int
        
        /// the raw bitmap bytes.
        var bytes: [UInt8]
        
        /// Create a bitmap with capacity for up to `count + offset` fields, applying `offset` to all field indexes.
        /// See the ``offset`` property for additional details.
        init(count: Int, offset: Int) {
            self.init(bytes: .init(repeating: 0, count: (count + offset + 7) >> 3), offset: offset)
        }
        
        /// Create a bitmap from a preexisting series of raw bytes, applying `offset` to all field indexes.
        init(bytes: [UInt8], offset: Int) {
            self.offset = offset
            self.bytes = bytes
        }
        
        var startIndex: Int { 0 } // no, we do _not_ want to add the offset here
        var endIndex: Int { (self.bytes.count << 3) - self.offset }
        
        /// Check or update the `NULL` flag of the field at the given position. The position value must be greater than
        /// or equal to zero and less than the field count specified when the bitmap was created.
        subscript(pos: Int) -> Bool {
            get {
                let pos = pos + self.offset, idx = pos >> 3, mask = UInt8(1 << (pos & 0x7))
                return self.bytes[idx] & mask != 0
            }
            set {
                let pos = pos + self.offset, idx = pos >> 3, mask = UInt8(1 << (pos & 0x7)), rev: UInt8 = newValue ? ~0 : 0
                self.bytes[idx] ^= (self.bytes[idx] ^ rev) & mask // https://graphics.stanford.edu/~seander/bithacks.html#ConditionalSetOrClearBitsWithoutBranching
            }
        }
                
        /// See ``CustomStringConvertible.description``
        public var description: String { "NULLmap(\(self.count)):[\(self.bytes.map(\.binaryDescription).joined(separator: " "))" }
    }
}

extension UInt8 {
    var binaryDescription: String {
        "\(String(repeating: "0", count: self.leadingZeroBitCount))\(String(self, radix: 2))"
    }
}
