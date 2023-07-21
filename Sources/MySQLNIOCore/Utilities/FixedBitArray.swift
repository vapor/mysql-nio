import Algorithms

/// Implements a naïve random-access array of bits with access to the underlying bytewise storage.
///
/// The capacity of the array is set at creation time and can not be changed afterwards. For all
/// intents and purposes, it is as close to a fixed-length array as Swift can manage.
///
/// This is used to interpret the MySQL binary result set wire protocol's "NULL bitmap", which is
/// a sequence of N bits (padded to the nearest byte with zeroes), with each bit flagging whether
/// the field at the same index as the bit in the data row is NULL (and thus has no value).
///
/// In theory, we could use the `BitArray` type from `swift-collections` for this, but as of
/// the time of this writing, the package still has not received a 1.1 release, before which the
/// bit collection types don't exist. Even if this weren't the case, however, we might stick to
/// this version anyway, as the as-yet unreleased `BitArray` implementation in `swift-collections`
/// is a dynamically-sized collection, which implies a certain amount of overhead the logic
/// in use here simply does not need.
struct FixedBitArray: RandomAccessCollection {
    /// Underlying storage. Read-only for direct access.
    private(set) var bytes: [UInt8]
    
    // `Collection` requirement
    let startIndex = 0
    
    /// `Collection` requirement; doubles as the number of valid bits.
    var endIndex: Int
    
    // `Collection` requirement
    subscript(_ position: Int) -> Bool {
        get {
            precondition(self.indices.contains(position))
            return (self.bytes[position &>> 3] &>> (position & 7)) & 1 > 0
        }
        set {
            precondition(self.indices.contains(position))
            if newValue {
                self.bytes[position &>> 3] |= 1 &<< (position & 7)
            } else {
                self.bytes[position &>> 3] &= ~(1 &<< (position & 7))
            }
        }
    }
    
    /// Returns the number of storage bytes needed for a given capacity in bits.
    static func bytesRequired(forCapacity capacity: Int) -> Int {
        (capacity + 7) &>> 3
    }
    
    /// Create a new bit array with a given bit capacity. All bits are initially zero.
    ///
    /// A capacity of zero is valid.
    init(bitCapacity: Int) {
        self.bytes = .init(repeating: 0, count: Self.bytesRequired(forCapacity: bitCapacity))
        self.endIndex = bitCapacity
    }
    
    /// Construct a bit array from an existing sequence of bytes and a count of "significant" bits.
    ///
    /// The input sequence must have exactly ``bytesRequired(forCapacity: significantBits)`` elements,
    /// and all padding bits in the input must be 0. Failure to meet these conditions is a runtime error.
    ///
    /// An empty collection, with zero significant bits, is a valid input.
    init(bytes: some Sequence<UInt8>, significantBits: Int) {
        self.init(bytes: bytes.map { $0 }, significantBits: significantBits)
    }
    
    /// Construct a bit array from a count of significant bits and an existing array of bytes, without copying.
    ///
    /// The input array must have exactly ``bytesRequired(forCapacity: significantBits)`` elements,
    /// and all padding bits in the input must be 0. Failure to meet these conditions is a runtime error.
    ///
    /// An empty collection, with zero significant bits, is a valid input.
    init(bytes: [UInt8], significantBits: Int) {
        precondition(bytes.count == Self.bytesRequired(forCapacity: significantBits))
        precondition(bytes.suffix(1).first.map { $0 &>> (significantBits & 7) == 0 } ?? true)

        self.bytes = bytes
        self.endIndex = significantBits
    }
    
    /// Construct a bit array from a sequence of boolean values. The number of significant bits will be equal
    /// to the number of flags in the sequence.
    init(_ flags: some Sequence<Bool>) {
        self.init(flags.lazy.map { $0 })
    }
    
    /// Construct a bit array from a collection of boolean values. The number of significant bits will be equal
    /// to the number of flags in the collection.
    init(_ flags: some Collection<Bool>) {
        self.init(bytes: flags.lazy.chunks(ofCount: 8).map { $0.reduce(0) { ($0 &<< 1) | ($1 ? 1 : 0) } }, significantBits: flags.count)
    }
}

