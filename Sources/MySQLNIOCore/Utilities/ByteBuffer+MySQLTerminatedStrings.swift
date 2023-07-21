import NIOCore

// MARK: - EOF-terminated strings

extension ByteBuffer {
    /// Treat the entire remaining contents of the buffer as a string. Zero bytes remaining
    /// is treated as an empty string.
    ///
    /// This method does not advance the reader index. It is named according to the convention of
    /// ``ByteBuffer/slice()`` (not a "get" method because it does not accept an index, but not a
    /// "read" method because it does not move the reader index).
    @inlinable
    func mysql_string() -> String? {
        self.getString(at: self.readerIndex, length: self.readableBytes)
    }

    /// Read the entire remaining contents of the buffer as a string. Zero bytes remaining is
    /// treated as an empty string.
    @inlinable
    mutating func mysql_readString() -> String? {
        guard let string = self.mysql_string() else { return nil }
        self.moveReaderIndex(forwardBy: self.readableBytes)
        return string
    }
    
    /// No need for an initializer or `set`/`write` methods; `ByteBuffer` already provides these
    /// as `init(string:)`, `setString(_:at:)`, and `writeString(_:)`.
}

// MARK: - Null-terminated strings

extension ByteBuffer {
    @inlinable
    init(nullTerminatedString: String?) {
        self.init()
        self.writeNullTerminatedString(nullTerminatedString ?? "")
    }
}
