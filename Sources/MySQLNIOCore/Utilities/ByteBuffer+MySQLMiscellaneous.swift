import NIOCore

// MARK: - Little-endian integers

/// These methods are just shorthand, used because writing out `endianness: .little` takes up a lot of visual
/// space given that integers in MySQL's wire protocol are always little-endian.
extension ByteBuffer {
    /// `getInteger(at:endianness:as:)` but always little-endian.
    @inlinable
    func mysql_getInteger<T: FixedWidthInteger>(at index: Int, as: T.Type = T.self) -> T? {
        self.getInteger(at: index, endianness: .little, as: T.self)
    }
    
    /// `readInteger(endianness:as:)` but always little-endian.
    @inlinable
    mutating func mysql_readInteger<T: FixedWidthInteger>(as: T.Type = T.self) -> T? {
        self.readInteger(endianness: .little, as: T.self)
    }
    
    /// `setInteger(_:at:endianness:as:)` but always little-endian.
    @discardableResult
    @inlinable
    mutating func mysql_setInteger<T: FixedWidthInteger>(_ integer: T, at index: Int, as: T.Type = T.self) -> Int {
        self.setInteger(integer, at: index, endianness: .little, as: T.self)
    }

    /// `writeInteger(_:endianness:as:)` but always little-endian.
    @discardableResult
    @inlinable
    mutating func mysql_writeInteger<T: FixedWidthInteger>(_ integer: T, as: T.Type = T.self) -> Int {
        self.writeInteger(integer, endianness: .little, as: T.self)
    }
}

// MARK: - Marker bytes

extension ByteBuffer {

    /// Return the first byte in the buffer (counting from the reader index), if it exists.
    @inlinable
    func mysql_marker() -> UInt8? {
        self.getInteger(at: self.readerIndex)
    }
    
    /// Check that the first byte of the buffer (counting from the reader index) matches one of the
    /// provided values. If so, advance the reader index and return the byte. Otherwise, return `nil`.
    /// If the buffer has no more readable bytes, trigger a channel protocol violation.
    @inlinable
    mutating func mysql_readMarker(matching valid1: UInt8, or valid2: UInt8? = nil) -> Bool {
        guard let checkByte = self.mysql_marker(),
              checkByte == valid1 || checkByte == valid2 else {
            return false
        }
        
        self.moveReaderIndex(forwardBy: MemoryLayout<UInt8>.size)
        return true
    }
}

// MARK: - Misc utilities

extension ByteBuffer {
    /// This bizarre little utility is for use in `guard` clauses when a field's presence in a packet
    /// is determined by a boolean flag (typically a capability).
    ///
    /// If `flag` is `false`, yields `T??.some(.none)`, which unwraps to `T?(nil)`.
    /// If `flag` is `true` but the closure returns `nil`, yields `T??.none`, which fails to unwrap.
    /// If `flag` is `true` and the closure succeeds, yields `T??.some(...)`, which unwraps to `T?(...)`.
    ///
    /// Example usage:
    ///
    ///     guard let optionalField = packet.mysql_optional(capabilities.contains(.connectWithDatabase), $0.readNullTerminatedString()) else {
    ///         ...
    ///     }
    func mysql_optional<T>(_ flag: @autoclosure () -> Bool, _ trueExpr: @autoclosure () -> T?) -> T?? {
        guard flag() else { return .some(.none) }
        return trueExpr().map(T??.some(_:)) ?? .none
    }
    
    /// Gets the given number of bytes and returns `true` if they all have the given value.
    ///
    /// Returns `false` if not enough data is present at the given index or any bytes do not match.
    func mysql_getRepeatingByte(_ value: UInt8 = 0, count: Int, at index: Int) -> Bool {
        self.viewBytes(at: index, length: count)?.allSatisfy({ $0 == value }) ?? false
    }
    
    /// Reads the given number of bytes and returns `true` if they all have the given value.
    ///
    /// Returns `false` if not enough readable data is present or any bytes do not match.
    mutating func mysql_readRepeatingByte(_ value: UInt8 = 0, count: Int) -> Bool {
        guard self.mysql_getRepeatingByte(value, count: count, at: self.readableBytes) else {
            return false
        }
        self.moveReaderIndex(forwardBy: count)
        return true
    }
    
    /// Returns a copy of the buffer. The copy's reader index is advanced by the given count.
    func mysql_makeMutableAndAdvanceReaderIndex(by count: Int) -> ByteBuffer {
        var copy = self
        copy.moveReaderIndex(forwardBy: count)
        return copy
    }
}

