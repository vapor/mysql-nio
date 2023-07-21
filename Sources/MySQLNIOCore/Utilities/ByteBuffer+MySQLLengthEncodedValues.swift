import NIOCore
import Collections

/// Describes an integer which can be represented as a bit pattern.
///
/// For an unsigned integer, this is identical to the original value. For a signed integer, this is the
/// result of interpreting the individual byte(s) of the value as an unsigned integer of the same bit width.
///
/// > Note: We only need this because the `init(bitPattern:)` initializers of the unsigned integer types
///   are required by neither `UnsignedNumeric` nor `UnsignedInteger`, making it inconvenient to spell
///   `SignedInteger.Magnitude.init(bitPattern:)` generically.
///
/// Examples:
///
///     Int8.min.bitPatternRepresentation     // 0x80 - UInt8(128)
///     Int8.max.bitPatternRepresentation     // 0x7f - UInt8(127)
///     (-1 as Int8).bitPatternRepresentation // 0xff - UInt8(255)
@usableFromInline
protocol BitPatternRepresentableInteger: FixedWidthInteger {
    var bitPatternRepresentation: Magnitude { get }
}

extension Int8:   BitPatternRepresentableInteger { @_transparent @usableFromInline var bitPatternRepresentation: Magnitude { .init(bitPattern: self) } }
extension Int16:  BitPatternRepresentableInteger { @_transparent @usableFromInline var bitPatternRepresentation: Magnitude { .init(bitPattern: self) } }
extension Int32:  BitPatternRepresentableInteger { @_transparent @usableFromInline var bitPatternRepresentation: Magnitude { .init(bitPattern: self) } }
extension Int64:  BitPatternRepresentableInteger { @_transparent @usableFromInline var bitPatternRepresentation: Magnitude { .init(bitPattern: self) } }
extension Int:    BitPatternRepresentableInteger { @_transparent @usableFromInline var bitPatternRepresentation: Magnitude { .init(bitPattern: self) } }
extension UInt8:  BitPatternRepresentableInteger { @_transparent @usableFromInline var bitPatternRepresentation: Magnitude { self } }
extension UInt16: BitPatternRepresentableInteger { @_transparent @usableFromInline var bitPatternRepresentation: Magnitude { self } }
extension UInt24: BitPatternRepresentableInteger { @_transparent @usableFromInline var bitPatternRepresentation: Magnitude { self } }
extension UInt32: BitPatternRepresentableInteger { @_transparent @usableFromInline var bitPatternRepresentation: Magnitude { self } }
extension UInt64: BitPatternRepresentableInteger { @_transparent @usableFromInline var bitPatternRepresentation: Magnitude { self } }
extension UInt:   BitPatternRepresentableInteger { @_transparent @usableFromInline var bitPatternRepresentation: Magnitude { self } }

// MARK: - Length-encoded integers

extension ByteBuffer {
    /// Return the _total_ number of bytes required to store the given value as a MySQL length-encoded integer.
    ///
    /// The bit pattern of the input value is used to determine its storage requirement, as length-encoded values
    /// are always handled as unsigned integers.
    ///
    /// > Note: This method is intended to be used in conjunction with ``mysql_getLengthEncodedInteger(at:)`` and
    ///   ``mysql_setLengthEncodedInteger(_:at:)`` for callers which need to know the correct length ahead of time.
    ///
    /// See <doc:Length-Encoded-Integer-Format> for details of the encoding format.
    @inline(__always)
    static func mysql_lengthEncodedSize<I: BitPatternRepresentableInteger>(of value: I) -> Int {
        switch value.bitPatternRepresentation {
        case ...0xfa: return 1 // encoded as the last 8 bits of the value
        case ...0xffff: return 3 // encoded as 0xfc followed by the value as a little-endian 16-bit integer
        case ...0xffffff: return 4 // encoded as 0xfd followed by the value as a little-endian 24-bit integer
        default: return 9 // encoded as 0xfe followed by the value as a little-endian 64-bit integer
        }
    }
    
    /// Returns both a MySQL length-encoded integer value read from the buffer at the given position and the
    /// number of bytes said value occupied in the buffer.
    ///
    /// This is identical to calling ``mysql_getLengthEncodedInteger(at:)``, followed by calling
    /// ``mysql_lengthEncodedSize(of:)`` with its result, except for being very slightly more efficient.
    ///
    /// This is not a idiomatic `ByteBuffer` API; it is used to avoid a significant amount of repetition in the
    /// implementation of other length-encoded value methods but is not expected to be of any meaningful use to
    /// callers. Since other length-encoded types are provided in other files, and the `package` access level is
    /// not available yet even in Swift 5.9, this method must be `internal`, but it should nonetheless be
    /// considered private to `ByteBuffer` and not used by any other code.
    ///
    /// See <doc:Length-Encoded-Integer-Format> for details of the encoding format.
    @inlinable
    func mysql_getLengthEncodedIntegerAndSize(at index: Int) -> (value: UInt64, sizeInBuffer: Int)? {
        switch self.getInteger(at: index, as: UInt8.self) {
        case nil, 0xfb, 0xff: // Invalid encoding or empty buffer
            return nil
        case 0xfc: // 3-byte encoding: Value between 0xfb and UInt16.max
            return self.mysql_getInteger(at: index + 1, as: UInt16.self).map { (value: .init(truncatingIfNeeded: $0), sizeInBuffer: 1 + MemoryLayout<UInt16>.size) }
        case 0xfd: // 4-byte encoding: Value between 0x10000 and UInt24.max
            return self.mysql_getInteger(at: index + 1, as: UInt24.self).map { (value: .init(truncatingIfNeeded: $0), sizeInBuffer: 1 + MemoryLayout<UInt24>.size) }
        case 0xfe: // 9-byte encoding: Value between 0x1000000 and UInt64.max
            return self.mysql_getInteger(at: index + 1, as: UInt64.self).map { (value: $0,                            sizeInBuffer: 1 + MemoryLayout<UInt64>.size) }
        case let value?: // 1-byte encoding: Value between 0 and 0xfa
            assert((0...0xfa).contains(value))
            return (value: .init(truncatingIfNeeded: value), sizeInBuffer: 1)
        }
    }
    
    /// Attempt to get a MySQL length-encoded integer value from the buffer at the given position.
    ///
    /// There are two possible failure modes for this method, both signaled by a `nil` return value:
    ///
    /// - Insufficient data in the buffer.
    /// - An invalid length encoding.
    ///
    /// See <doc:Length-Encoded-Integer-Format> for details of the encoding format.
    @inlinable
    func mysql_getLengthEncodedInteger(at index: Int) -> UInt64? {
        self.mysql_getLengthEncodedIntegerAndSize(at: index).map(\.value)
    }
    
    /// Attempt to read a MySQL length-encoded integer value from the buffer at the current reader index.
    ///
    /// See ``mysql_getLengthEncodedInteger(at:)`` for additional details.
    @inlinable
    mutating func mysql_readLengthEncodedInteger() -> UInt64? {
        if let (value, size) = self.mysql_getLengthEncodedIntegerAndSize(at: self.readerIndex) {
            self.moveReaderIndex(forwardBy: size)
            return value
        } else {
            return nil
        }
    }
    
    /// Write an integer to the buffer at the given position as a MySQL length-encoded integer value.
    ///
    /// > Warning: The length-encoded integer format is variable-size; this method may overwrite data
    ///   later in the buffer _or_ leave unassigned bytes if the resulting encoding occupies more or
    ///   less space than expected. Use the ``mysql_lengthEncodedSize(of:)`` method to determine how
    ///   many bytes will be required, or consider using ``mysql_writeLengthEncodedIneger(_:)`` instead.
    ///
    /// See <doc:Length-Encoded-Integer-Format> for details of the encoding format.
    ///
    /// - Returns: As with other `set`-style methods, returns the number of bytes written.
    @inlinable
    @discardableResult
    mutating func mysql_setLengthEncodedInteger<I: BitPatternRepresentableInteger>(_ integer: I, at index: Int) -> Int {
        let savedWriterIndex = self.writerIndex
        self.moveWriterIndex(to: index)
        let result = self.mysql_writeLengthEncodedInteger(integer)
        self.moveWriterIndex(to: savedWriterIndex)
        return result
    }
    
    /// Write an integer to the buffer at the current writer index as a MySQL length-encoded integer value.
    ///
    /// See ``mysql_setLengthEncodedInteger(at:)`` for additional details.
    @inlinable
    @discardableResult
    mutating func mysql_writeLengthEncodedInteger<I: BitPatternRepresentableInteger>(_ integer: I) -> Int {
        switch integer.bitPatternRepresentation {
            case ...0xfa:
                return self.mysql_writeInteger(UInt8(truncatingIfNeeded: integer.bitPatternRepresentation))
            case ...0xffff:
                return self.writeMultipleIntegers(0xfc as UInt8, UInt16(truncatingIfNeeded: integer.bitPatternRepresentation), endianness: .little)
            case ...0xffffff:
                return self.writeMultipleIntegers(0xfd as UInt8, UInt24(truncatingIfNeeded: integer.bitPatternRepresentation), endianness: .little)
            default:
                return self.writeMultipleIntegers(0xfe as UInt8, UInt64(truncatingIfNeeded: integer.bitPatternRepresentation), endianness: .little)
        }
    }
}

// MARK: - Length-encoded strings

extension ByteBuffer {
    @inlinable
    init(mysql_lengthEncodedString string: String) {
        self.init()
        self.mysql_writeLengthEncodedString(string)
    }

    @inlinable
    func mysql_getLengthEncodedString(at index: Int) -> String? {
        guard let (length, lengthSize) = self.mysql_getLengthEncodedIntegerAndSize(at: index).flatMap({ v, s in Int(exactly: v).map { ($0, s) } }) else { return nil }
        return self.getString(at: index + lengthSize, length: length)
    }
    
    @inlinable
    mutating func mysql_readLengthEncodedString() -> String? {
        guard let (length, lengthSize) = self.mysql_getLengthEncodedIntegerAndSize(at: self.readerIndex).flatMap({ v, s in Int(exactly: v).map { ($0, s) } }),
              self.readableBytes - lengthSize >= length
        else { return nil }
        self.moveReaderIndex(forwardBy: lengthSize)
        return self.readString(length: length)
    }
    
    @inlinable
    @discardableResult
    mutating func mysql_setLengthEncodedString(_ string: String, at index: Int) -> Int {
        let lengthSize = self.mysql_setLengthEncodedInteger(string.utf8.count, at: index)
        return lengthSize + self.setString(string, at: index + lengthSize)
    }
    
    @inlinable
    @discardableResult
    mutating func mysql_writeLengthEncodedString(_ string: String) -> Int {
        let written = self.mysql_setLengthEncodedString(string, at: self.writerIndex)
        self.moveWriterIndex(forwardBy: written)
        return written
    }
}

// MARK: - Length-encoded bytes

extension ByteBuffer {
    @inlinable
    func mysql_getLengthEncodedSlice(at index: Int) -> ByteBuffer? {
        guard let (length, lengthSize) = self.mysql_getLengthEncodedIntegerAndSize(at: index).flatMap({ v, s in Int(exactly: v).map { ($0, s) } }) else { return nil }
        return self.getSlice(at: index + lengthSize, length: length)
    }
    
    @inlinable
    mutating func mysql_readLengthEncodedSlice() -> ByteBuffer? {
        guard let (length, lengthSize) = self.mysql_getLengthEncodedIntegerAndSize(at: self.readerIndex).flatMap({ v, s in Int(exactly: v).map { ($0, s) } }),
              self.readableBytes - lengthSize >= length
        else { return nil }
        self.moveReaderIndex(forwardBy: lengthSize)
        return self.readSlice(length: length)
    }
    
    @inlinable
    @discardableResult
    mutating func mysql_setLengthEncodedBuffer(_ slice: ByteBuffer, at index: Int) -> Int {
        let lengthSize = self.mysql_setLengthEncodedInteger(slice.readableBytes, at: index)
        return lengthSize + self.setBuffer(slice, at: index + lengthSize)
    }
    
    @inlinable
    @discardableResult
    mutating func mysql_writeLengthEncodedBuffer(_ slice: inout ByteBuffer) -> Int {
        let written = self.mysql_setLengthEncodedBuffer(slice, at: self.writerIndex)
        slice.moveReaderIndex(forwardBy: slice.readableBytes)
        self.moveWriterIndex(forwardBy: written)
        return written
    }

    @inlinable
    @discardableResult
    mutating func mysql_writeLengthEncodedImmutableBuffer(_ slice: ByteBuffer) -> Int {
        let written = self.mysql_setLengthEncodedBuffer(slice, at: self.writerIndex)
        self.moveWriterIndex(forwardBy: written)
        return written
    }
}

// MARK: - Length-encoded key-value pairs

extension ByteBuffer {
    /// Treat all reamining readable bytes of the buffer as a series of key-value pairs encoded as
    /// sequential doublets of length-encoded strings and return those pairs as an ordered dictionary.
    /// It is an error if a key has no accompanying value, although an explicitly empty value is
    /// accepted. The loop is normally terminated by the failure to read a key, but if any bytes remain
    /// in the buffer after that point, it is considered an error and `nil` is returned.
    ///
    /// In keeping with protocol-imposed limitations, it is an error if more than 64KiB of data is
    /// available (connection attributes maximum size), or if more than 32 pairs are found (query
    /// attributes maximum count); in either case, `nil` is returned.
    ///
    /// If there is no data in the buffer, an empty dictionary is returned.
    ///
    /// If duplicate keys occur in the data, the last value seen wins. (This is arguably a protocol
    /// error, but the overwrite semantic sufficiently simplifies matters to be worth it.)
    ///
    /// This method does not advance the reader index. It is named according to the convention of
    /// ``ByteBuffer/slice()`` (not a "get" method because it does not accept an index, but not a
    /// "read" method because it does not move the reader index).
    @inlinable
    func mysql_keyValueStringPairs() -> OrderedDictionary<String, String>? {
        guard self.readableBytes <= UInt16.max else { return nil }
        guard self.readableBytes > 0 else { return [:] }
        
        var copy = self
        var pairs = OrderedDictionary<String, String>(minimumCapacity: 2)
        while let key = copy.mysql_readLengthEncodedString(), pairs.count <= 32 {
            guard let value = copy.mysql_readLengthEncodedString() else { return nil }
            pairs[key] = value
        }
        guard pairs.count <= 32, copy.readableBytes == 0 else { return nil }
        return pairs
    }

    /// The "reading" version of ``mysql_keyValueStringPairs()``. Semantics are identical, except
    /// that this method will advance the reader index when successful. Unless `nil` is returned,
    /// there will always be zero readable bytes left after this call.
    @inlinable
    mutating func mysql_readKeyValueStringPairs() -> OrderedDictionary<String, String>? {
        guard let pairs = mysql_keyValueStringPairs() else { return nil }
        self.moveReaderIndex(forwardBy: self.readableBytes)
        return pairs
    }
    
    /// Create a `ByteBuffer` from an ordered sequence of key-value pairs, encoding them as
    /// sequential doublets of length-encoded strings.
    ///
    /// No deduplication of keys is performed; each pair is written to the buffer in the order
    /// it appears without additional processing.
    ///
    /// > Preconditions: The total space used by the encoded strings must be no more than 64KiB,
    ///   and there may not be more than 32 key-value pairs.
    @inlinable
    init(mysql_keyValueStringPairs pairs: some Sequence<(String, String)>) {
        var buffer = ByteBuffer()
        var n = 0
        var iterator = pairs.makeIterator()
        
        while let (key, value) = iterator.next() {
            buffer.mysql_writeLengthEncodedString(key)
            buffer.mysql_writeLengthEncodedString(value)
            n += 1
            precondition(n <= 32 && buffer.readableBytes <= UInt16.max)
        }
        self = buffer
    }

    /// Decode a length-encoded slice from the buffer at the given index and attempt to interpret it
    /// as a series of key-value pairs according to the semantics of ``mysql_keyValueStringPairs()``.
    @inlinable
    func mysql_getLengthEncodedKeyValuePairs(at index: Int) -> OrderedDictionary<String, String>? {
        self.mysql_getLengthEncodedSlice(at: index)?.mysql_keyValueStringPairs()
    }

    /// Decode a length-encoded slice from the buffer at the current reader index and interpret it
    /// as a series of key-value pairs according to the semantics of ``mysql_keyValueStringPairs()``.
    @inlinable
    mutating func mysql_readLengthEncodedKeyValuePairs() -> OrderedDictionary<String, String>? {
        var copy = self
        guard let pairs = copy.mysql_readLengthEncodedSlice()?.mysql_keyValueStringPairs() else { return nil }
        self = copy
        return pairs
    }
    
    /// Encode an ordered sequence of key-value pairs as a length-encoded buffer at the given index
    /// according to the semantics of ``init(mysql_keyValueStringPairs:)``.
    @discardableResult
    @inlinable
    mutating func mysql_setLengthEncodedKeyValuePairs(_ pairs: some Sequence<(String, String)>, at index: Int) -> Int {
        self.mysql_setLengthEncodedBuffer(.init(mysql_keyValueStringPairs: pairs), at: index)
    }
    
    /// Encode an ordered sequence of key-value pairs as a length-encoded buffer at the current writer
    /// index according to the semantics of ``init(mysql_keyValueStringPairs:)``.
    @discardableResult
    @inlinable
    mutating func mysql_writeLengthEncodedKeyValuePairs(_ pairs: some Sequence<(String, String)>) -> Int {
        let written = self.mysql_setLengthEncodedKeyValuePairs(pairs, at: self.writerIndex)
        self.moveWriterIndex(forwardBy: written)
        return written
    }
}
