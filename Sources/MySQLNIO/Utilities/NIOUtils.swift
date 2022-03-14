import NIOCore

extension ByteBuffer {
    mutating func readInteger<T>(endianness: Endianness = .big, as: T.Type = T.self) -> T?
        where T: RawRepresentable, T.RawValue: FixedWidthInteger
    {
        return self.readInteger(endianness: endianness, as: T.RawValue.self)
            .flatMap(T.init(rawValue:))
    }
    
    mutating func getUInt24(at index: Int, endianness: Endianness = .big) -> UInt32? {
        guard let (a, b, c) = self.readMultipleIntegers(endianness: endianness, as: (UInt8, UInt8, UInt8).self) else { return nil }
        switch endianness {
            case .big: return UInt32(a) | (UInt32(b) << 8) | (UInt32(c) << 16)
            case .little: return UInt32(c) | (UInt32(b) << 8) | (UInt32(a) << 16)
        }
    }
    
    mutating func readUInt24(endianness: Endianness = .big) -> UInt32? {
        guard let result = self.getUInt24(at: self.readerIndex, endianness: endianness) else { return nil }
        self.moveReaderIndex(forwardBy: 3)
        return result
    }
    
    @discardableResult
    mutating func setUInt24(_ value: UInt32, at index: Int, endianness: Endianness = .big) -> Int {
        assert(value < 0x01000000)
        switch endianness {
            case .big: return self.setBytes([UInt8(truncatingIfNeeded: value), UInt8(truncatingIfNeeded: value >> 8), UInt8(value >> 16)], at: index)
            case .little: return self.setBytes([UInt8(value >> 16), UInt8(truncatingIfNeeded: value >> 8), UInt8(truncatingIfNeeded: value)], at: index)
        }
    }
    
    @discardableResult
    mutating func writeUInt24(_ value: UInt32, endianness: Endianness = .big) -> Int {
        let written = self.setUInt24(value, at: self.writerIndex, endianness: endianness)
        self.moveWriterIndex(forwardBy: written)
        return written
    }
    
    @discardableResult
    mutating func writeLengthEncodedInteger(_ integer: UInt64) -> Int {
        switch integer {
        case ..<0xfb:  return self.writeInteger(integer, as: UInt8.self)
        case ..<1<<16: return self.writeBytes([0xfc, .init(integer & 0xff), .init(integer >> 8 & 0xff)])
        case ..<1<<24: return self.writeBytes([0xfd, .init(integer & 0xff), .init(integer >> 8 & 0xff), .init(integer >> 16 & 0xff)])
        default:       return self.writeInteger(0xfe, as: UInt8.self) + self.writeInteger(integer, endianness: .little, as: UInt64.self)
        }
    }

    @discardableResult
    mutating func writeImmutableLengthEncodedSlice(_ buffer: ByteBuffer) -> Int {
        var copy = buffer
        return self.writeLengthEncodedSlice(&copy)
    }
    
    @discardableResult
    mutating func writeLengthEncodedSlice(_ buffer: inout ByteBuffer) -> Int {
        return self.writeLengthEncodedInteger(numericCast(buffer.readableBytes))
             + self.writeBuffer(&buffer)
    }
    
    @discardableResult
    mutating func writeLengthEncodedString(_ string: String) -> Int {
        return self.writeLengthEncodedInteger(numericCast(string.utf8.count)) + self.writeString(string)
    }
    
    mutating func readLengthEncodedString() -> String? {
        guard let length = self.readLengthEncodedInteger() else { return nil }
        return self.readString(length: numericCast(length))
    }
    
    mutating func readLengthEncodedSlice() -> ByteBuffer? {
        guard let length = self.readLengthEncodedInteger() else { return nil }
        return self.readSlice(length: numericCast(length))
    }
    
    mutating func readLengthEncodedInteger() -> UInt64? {
        // Note: MySQL at one time made use of an additional encoding with a leading byte of `0xfb`. This apparently
        // was used to represent a NULL value. It is unclear how this differed meaningfully from just encoding zero.
        // Neither MySQL nor MariaDB has produced this encoding since at least as far back as MySQL 5.1. While they
        // do still have logic to handle the encoding if a client sends it, it is interepreted as both 0 and ~0 at
        // different times and in different versions, and it isn't difficult to guess that the relevant code paths
        // have not been cleaned up because they don't need to be. With all this in mind, we just treat it as an
        // invalid encoding altogether.
        switch self.readInteger(endianness: .little, as: UInt8.self) {
            case .none, 0xfb: return nil
            case 0xfc:  return readInteger(endianness: .little, as: UInt16.self).map(numericCast)
            case 0xfd:  return readBytes(length: 3).map { $0.reversed().reduce(UInt64.zero) { ($0 << 8) | numericCast($1) } }
            case 0xfe:  return readInteger(endianness: .little, as: UInt64.self)
            case .some(let byte): return numericCast(byte)
        }
    }
    
    /// Reads the specified number of bytes from the buffer and ensures that they are all zeroes. Returns `true`
    /// on success, `false` if there are insufficient readable bytes available, or if any of the read bytes are nonzero.
    mutating func readReservedBytes(length: Int) -> Bool {
        guard self.readableBytes >= length,
              self.readableBytesView[..<length].allSatisfy({ $0 == 0 })
        else {
            return false
        }
        self.moveReaderIndex(forwardBy: length)
        return true
    }

    // Copy of `ByteBuffer.getNullTerminatedStringLength(at:)` from `ByteBuffer-aux.swift`.
    fileprivate func getNullTerminatedBytesLength(at index: Int) -> Int? {
        guard self.readerIndex <= index, index < self.writerIndex else { return nil }
        guard let endIndex = self.readableBytesView[index...].firstIndex(of: 0) else { return nil }
        return endIndex &- index
    }

    // Copy of the method of the almost-same name from `ByteBuffer-core.swift`. It's too bad NIO doesn't expose it.
    fileprivate func readRangeWithinReadableBytes(index: Int, length: Int) -> Range<Int>? {
        guard index >= self.readerIndex, length >= 0 else { return nil }
        let indexFromReaderIndex = index &- self.readerIndex
        assert(indexFromReaderIndex >= 0)
        guard indexFromReaderIndex <= self.readableBytes &- length else { return nil }
        return Range<Int>(uncheckedBounds: (lower: indexFromReaderIndex, upper: indexFromReaderIndex &+ length))
    }
}
