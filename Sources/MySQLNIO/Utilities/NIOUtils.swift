import NIOCore

extension ByteBuffer {
    
    // MARK: - `RawRepresentable` with `FixedWidthInteger` raw value
    
    func getInteger<T>(at index: Int, endianness: Endianness = .big, as: T.Type = T.self) -> T?
        where T: RawRepresentable, T.RawValue: FixedWidthInteger
    {
        return self.getInteger(at: index, endianness: endianness, as: T.RawValue.self).flatMap(T.init(rawValue:))
    }
    
    mutating func readInteger<T>(endianness: Endianness = .big, as: T.Type = T.self) -> T?
        where T: RawRepresentable, T.RawValue: FixedWidthInteger
    {
        return self.readInteger(endianness: endianness, as: T.RawValue.self).flatMap(T.init(rawValue:))
    }
    
    @discardableResult
    mutating func setInteger<T>(_ value: T, at index: Int, endianness: Endianness = .big) -> Int
        where T: RawRepresentable, T.RawValue: FixedWidthInteger
    {
        return self.setInteger(value.rawValue, at: index, endianness: endianness)
    }
    
    @discardableResult
    mutating func writeInteger<T>(_ value: T, endianness: Endianness = .big) -> Int
        where T.RawRepresentable, T.RawValue: FixedWidthInteger
    {
        return self.writeInteger(value.rawValue, endianness: endianness)
    }
    
    // MARK: - 3-byte (24-bit) unsigned integer
    
    func getUInt24(at index: Int, endianness: Endianness = .big) -> UInt32? {
        guard let view = self.readRangeWithinReadableBytes(index: index, length: 3).map({self.readableBytesView[$0]}) else { return nil }
        let (a, b, c) = (view[0], view[1], view[2])
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
    mutating func setUInt24(_ value: UInt64, at index: Int, endianness: Endianness = .big) -> Int {
        assert(value < 0x01000000)
        return self.setUInt24(UInt32(truncatingIfNeeded: value), at: index, endianness: endianness)
    }
    
    @discardableResult
    mutating func writeUInt24(_ value: UInt32, endianness: Endianness = .big) -> Int {
        let written = self.setUInt24(value, at: self.writerIndex, endianness: endianness)
        self.moveWriterIndex(forwardBy: written)
        return written
    }

    @discardableResult
    mutating func writeUInt24(_ value: UInt64, endianness: Endianness = .big) -> Int {
        let written = self.setUInt24(value, at: self.writerIndex, endianness: endianness)
        self.moveWriterIndex(forwardBy: written)
        return written
    }

    // MARK: - MySQL "length encoding" for integers
    
    /// Return a decoded length-encoded integer _and_ the number of additional bytes which were required to load that
    /// value. If the initial byte is less than `0xfb`, zero is returned. `nil` is returned if the byte value is `0xfb`
    /// (reserved) or `0xff` (`ERR_Packet` header flag).
    private func getLengthEncodedIntegerRaw(at index: Int, endianness: Endianness = .little) -> (UInt64, Int)? {
        // Note: MySQL historicallly used an additional encoding with the `0xfb` leading byte, which seems to have
        // represented a NULL value. It isn't clear what it was ever actually used for; neither MySQL nor MariaDB
        // generate it since at least as far back as MySQL 5.1, and current versions handle it inconsistently at best.
        // We just treat it as invalid outright.
        switch self.getInteger(at: index, endianness: endianness, as: UInt8.self) {
            case .none, 0xfb, 0xff: return nil
            case 0xfc: return (getInteger(at: index + 1, endianness: endianness, as: UInt16.self).map(numericCast), MemoryLayout<UInt16>.size)
            case 0xfd: return (getUInt24(at: index + 1, endianness: endianness).map(numericCast), 3)
            case 0xfe: return (getInteger(at: index + 1, endianness: endianness, as: UInt64.self), MemoryLayout<UInt64>.size)
            case .some(let byte): return (numericCast(byte), 0)
        }
    }
    
    func getLengthEncodedInteger(at index: Int, endianness: Endianness = .little) -> UInt64? {
        return self.getLengthEncodedIntegerRaw(at: index, endianness: endianness)?.0
    }
    
    mutating func readLengthEncodedInteger(endianness: Endianness = .little) -> UInt64? {
        guard let result = self.getLengthEncodedIntegerRaw(at: self.readerIndex, endianness: endianness) else { return nil }
        self.moveReaderIndex(forwardBy: 1 + result.1)
        return result.0
    }
    
    @discardableResult
    mutating func setLengthEncodedInteger(_ integer: UInt64, at index: Int, endianness: Endianness = .little) -> Int {
        switch integer {
        case ..<0xfb:  return self.setInteger(integer, at: index, endianness: endianness, as: UInt8.self)
        case ..<1<<16: return self.setBytes([0xfc], at: index) + self.setInteger(integer, at: index + 1, endianness: endianness, as: UInt16.self)
        case ..<1<<24: return self.setBytes([0xfd], at: index) + self.setUInt24(integer, at: index + 1, endianness: endianness)
        default:       return self.setBytes([0xfe], at: index) + self.setInteger(integer, at: index + 1, endianness: endianness, as: UInt64.self)
        }
    }
    
    @discardableResult
    mutating func writeLengthEncodedInteger(_ integer: UInt64, endianness: Endianness = .little) -> Int {
        let written = self.setLengthEncodedInteger(integer, at: self.writerIndex, endianness: endianness)
        self.moveWriterIndex(forwardBy: written)
        return written
    }
    
    // MARK: - Lenenc length-prefixed slice
    
    private func fetchLengthEncodedSlice(at index: Int) -> (ByteBuffer, Int)? {
        guard let (length, offset) = self.getLengthEncodedIntegerRaw(at: index) else { return nil }
        guard let result = self.getSlice(at: index + 1 + offset, length: numericCast(length)) else { return nil }
        return (result, offset + 1 + numericCast(length))
    }

    func getLengthEncodedSlice(at index: Int) -> ByteBuffer? {
        return self.fetchLengthEncodedSlice(at: index)?.0
    }

    mutating func readLengthEncodedSlice() -> ByteBuffer? {
        guard let (result, offset) = self.fetchLengthEncodedSlice(at: self.readerIndex) else { return nil }
        self.moveReaderIndex(forwardBy: offset)
        return result
    }
    
    @discardableResult
    mutating func setLengthEncodedSlice(_ buffer: ByteBuffer, at index: Int) -> Int {
        let written = self.setLengthEncodedInteger(numericCast(buffer.readableBytes), at: index)
        return written + self.setBuffer(buffer, at: index + written)
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
    
    // MARK: - Lenenc length-prefixed string
    
    private func fetchLengthEncodedString(at index: Int) -> (String, Int)? {
        guard let (length, offset) = self.getLengthEncodedIntegerRaw(at: index) else { return nil }
        guard let result = self.getString(at: index + 1 + offset, length: numericCast(length)) else { return nil }
        return (result, offset + 1 + numericCast(length))
    }
    
    func getLengthEncodedString(at index: Int) -> String? {
        return self.fetchLengthEncodedString(at: index)?.0
    }
    
    mutating func readLengthEncodedString() -> String? {
        guard let (result, offset) = self.fetchLengthEncodedString(at: self.readerIndex) else { return nil }
        self.moveReaderIndex(forwardBy: offset)
        return result
    }
    
    @discardableResult
    mutating func setLengthEncodedString(_ string: String, at index: Int) -> Int {
        let written = self.setLengthEncodedInteger(numericCast(string.utf8.count), at: index)
        return written + self.setString(string, at: index + written)
    }
    
    @discardableResult
    mutating func writeLengthEncodedString(_ string: String) -> Int {
        return self.writeLengthEncodedInteger(numericCast(string.utf8.count))
             + self.writeString(string)
    }
    
    // MARK: - Always-zero repeating byte read
    
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
    
    // MARK: - Local helpers

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
