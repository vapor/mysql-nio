extension MySQLProtocol {
    /// 14.7.2.1 NULL-Bitmap
    ///
    /// The binary protocol sends NULL values as bits inside a bitmap instead of a full byte as the ProtocolText::ResultsetRow does.
    /// If many NULL values are sent, it is more efficient than the old way.
    ///
    /// https://dev.mysql.com/doc/internals/en/null-bitmap.html
    public struct NullBitmap: CustomStringConvertible {
        /// Creates a new `MySQLNullBitmap` suitable for com statement execute packets.
        public static func comExecuteBitmap(count: Int) -> NullBitmap {
            return .init(count: count, offset: 0)
        }
        
        /// Creates a new `MySQLNullBitmap` suitable for binary result set packets.
        public static func binaryResultSetBitmap(bytes: [UInt8]) -> NullBitmap {
            return .init(bytes: bytes, offset: 2)
        }
        
        /// Reads a `MySQLNullBitmap` for binary result sets from the `ByteBuffer`.
        public static func readResultSetNullBitmap(count: Int, from buffer: inout ByteBuffer) -> NullBitmap? {
            guard let bytes = buffer.readBytes(length: self.length(count: count, offset: 2)) else {
                return nil
            }
            return NullBitmap.binaryResultSetBitmap(bytes: bytes)
        }
        
        /// NULL-bitmap, length: (num-params+7)/8
        private static func length(count: Int, offset: Int) -> Int {
            return (count + 7 + offset) / 8
        }
        
        /// This bitmap's static offset. This varies depending on which packet
        /// the bitmap is being used in.
        public let offset: Int
        
        /// the raw bitmap bytes.
        public var bytes: [UInt8]
        
        /// Creates a new `MySQLNullBitmap` from column count and an offset.
        private init(count: Int, offset: Int) {
            self.offset = offset
            self.bytes = [UInt8](
                repeating: 0,
                count: NullBitmap.length(count: count, offset: offset)
            )
        }
        
        /// Creates a new `MySQLNullBitmap` from bytes and an offset.
        private init(bytes: [UInt8], offset: Int) {
            self.offset = offset
            self.bytes = bytes
        }
        
        /// Sets the position to null.
        public mutating func setNull(at pos: Int) {
            /// NULL-bitmap-byte = ((field-pos + offset) / 8)
            /// NULL-bitmap-bit  = ((field-pos + offset) % 8)
            let NULL_bitmap_byte = (pos + self.offset) / 8
            let NULL_bitmap_bit = (pos + self.offset) % 8
            
            self.bytes[NULL_bitmap_byte] |= 0b1 << NULL_bitmap_bit
        }
        
        /// Returns `true` if the bitmap is null at the supplied position.
        public func isNull(at pos: Int) -> Bool {
            /// NULL-bitmap-byte = ((field-pos + offset) / 8)
            /// NULL-bitmap-bit  = ((field-pos + offset) % 8)
            let NULL_bitmap_byte = (pos + self.offset) / 8
            let NULL_bitmap_bit = (pos + self.offset) % 8
            
            let check = self.bytes[NULL_bitmap_byte] & (0b1 << NULL_bitmap_bit)
            return check > 0
        }
        
        /// See `CustomStringConvertible.description`
        public var description: String {
            var desc: String = "0b"
            let tests: [UInt8] = [
                0b1000_0000,
                0b0100_0000,
                0b0010_0000,
                0b0001_0000,
                0b0000_1000,
                0b0000_0100,
                0b0000_0010,
                0b0000_0001,
            ]
            for byte in bytes {
                if desc != "0b" {
                    desc.append(" ")
                }
                for test in tests {
                    if test == 0b0000_1000 {
                        desc.append("_")
                    }
                    if byte & test > 0 {
                        desc.append("1")
                    } else {
                        desc.append("0")
                    }
                }
            }
            return desc
        }
    }
}
