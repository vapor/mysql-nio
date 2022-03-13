import NIOCore

protocol MySQLPacketDecodable {
    static func decode(from packet: inout MySQLPacket, capabilities: MySQLProtocol.CapabilityFlags) throws -> Self
}

extension MySQLPacket {
    /// Attempt to decode a given specific packet type from a raw payload.
    mutating func decode<T>(_ type: T.Type, capabilities: MySQLProtocol.CapabilityFlags) throws -> T
        where T: MySQLPacketDecodable
    {
        do {
            return try T.decode(from: &self, capabilities: capabilities)
        } catch Error.packetReadFailure {
            throw MySQLError.packetDecodingError(type: "\(T.self)")
        }
    }
}

/// Utilties for use during packet decoding.
///
/// These methods function mostly identically to their identically-named counterparts on `ByteBuffer`, operating
/// on the packet's payload, with one major exception: on read failure, instead of returning `nil`, a
/// `MySQLError.packetDecodingError` is thrown.
///
/// - Note: Technically, an internal `packetReadFailure` error is thrown and then translated by the
///   `decode(_:capabilities:)` method into a `MySQLError`, in order to preserve additional contextual information.
///
/// TODO: Make sure the throw/catch/throw sequence in question is not as problematic for performance as it kinda
/// sounds like it'll be.
extension MySQLPacket {
    internal enum Error: Swift.Error {
        case packetReadFailure
    }
    
    mutating func readInteger<T: FixedWidthInteger>(endianness: Endianness = .big, as: T.Type = T.self) throws -> T {
        guard let i = self.payload.readInteger(endianness: endianness, as: T.self) else { throw Error.packetReadFailure }
        return i
    }
    
    mutating func readInteger<T>(endianness: Endianness = .big, as: T.Type = T.self) throws -> T
        where T: RawRepresentable, T.RawValue: FixedWidthInteger
    {
        guard let i = self.payload.readInteger(endianness: endianness, as: T.self) else { throw Error.packetReadFailure }
        return i
    }

    mutating func readString(length: Int) throws -> String {
        guard let s = self.payload.readString(length: length) else throw { Error.packetReadFailure }
        return s
    }
    
    mutating func readBytes(length: Int) throws -> [UInt8] {
        guard let b = self.payload.readBytes(length: length) else throw { Error.packetReadFailure }
        return b
    }

    mutating func readSlice(length: Int) throws -> ByteBuffer {
        guard let s = self.payload.readSlice(length: length) else throw { Error.packetReadFailure }
        return s
    }
    
    mutating func readLengthEncodedInteger() throws -> UInt64 {
        guard let i = self.payload.readLengthEncodedInteger() else throw { Error.packetReadFailure }
        return i
    }
    
    mutating func readLengthEncodedString() throws -> String {
        guard let s = self.payload.readLengthEncodedString() else throw { Error.packetReadFailure }
        return s
    }
    
    mutating func readLengthEncodedSlice() throws -> ByteBuffer {
        guard let s = self.payload.readLengthEncodedSlice() else throw { Error.packetReadFailure }
        return s
    }
    
    mutating func readNullTerminatedString() throws -> String {
        guard let s = self.payload.readNullTerminatedString() else throw { Error.packetReadFailure }
        return s
    }
    
    mutating func readReservedBytes(length: Int) throws {
        guard self.payload.readReservedBytes(length: length) else { throw Error.packetReadFailure }
    }
    
    /// Reads a length-encoded slice from the packet's payload, then invokes the provided closure with a
    /// pseudo-packet containing only the slice as its payload. The closure may either throw or return `nil`
    /// to indicate failure; either will result in an error being thrown from this method. If a non-`nil`
    /// value is returned from the closure, it becomes the return value of this method.
    ///
    /// This method is intended for use cases such as MariaDB's repeated use of length-encoded slices
    /// containing multiple additional length-encoded values to implement its various protocol extensions.
    /// The closure's parameter is provided as a `MySQLPacket` rather than the underlying `ByteBuffer` so
    /// that the closure has access to this set of utility methods without the necessity of adding them to
    /// `ByteBuffer` itself.
    ///
    /// - Note: Adding these methods to `ByteBuffer` would present no meaningful technical challenge, but it
    ///   would definitely present a serious conceptual challenge. Aside from finding a suitable naming scheme
    ///   that would not cause conflicts, these utilties are intended to ease the specific task of decoding
    ///   packets, which certainly can not be reasonably assumed to be the purpose of any arbitrary `ByteBuffer`.
    ///   Making the methods `internal` or `fileprivate` would constitute ducking that issue, not solving it;
    ///   the minor oddity of presenting the closure with the appearance of an entire additional packet is
    ///   much preferable in most respects.
    mutating func withLengthEncodedSlice<R>(_ closure: (inout MySQLPacket) throws -> R?) throws -> R {
        var slice = MySQLPacket(payload: try self.readLengthEncodedSlice())
        guard let result = try closure(&slice) else { throw Error.packetReadFailure }
        return result
    }
}
