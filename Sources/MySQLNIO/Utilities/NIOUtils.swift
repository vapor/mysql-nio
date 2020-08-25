extension ByteBuffer {
    mutating func readNullTerminatedString() -> String? {
        var copy = self
        while let byte = copy.readInteger(as: UInt8.self), byte != 0x00 { continue }
        defer { self.moveReaderIndex(forwardBy: 1) }
        return self.readString(length: (self.readableBytes - copy.readableBytes) - 1)
    }
    
    mutating func readInteger<T>(endianness: Endianness = .big, as: T.Type = T.self) -> T?
        where T: RawRepresentable, T.RawValue: FixedWidthInteger
    {
        return self.readInteger(endianness: endianness, as: T.RawValue.self)
            .flatMap { T(rawValue: $0) }
    }
    
    mutating func writeNullTerminatedString(_ string: String) {
        self.writeString(string)
        self.writeInteger(0, as: UInt8.self)
    }
    
    mutating func writeLengthEncodedInteger(_ integer: UInt64) {
        switch integer {
        case 0..<251:
            self.writeInteger(numericCast(integer), as: UInt8.self)
        case 251..<1<<16:
            self.writeInteger(0xFC, as: UInt8.self)
            self.writeInteger(numericCast(integer), endianness: .little, as: UInt16.self)
        case 1<<16..<1<<24:
            self.writeInteger(0xFD, as: UInt8.self)
            self.writeInteger(numericCast(integer & 0xFF), as: UInt8.self)
            self.writeInteger(numericCast(integer >> 8 & 0xFF), as: UInt8.self)
            self.writeInteger(numericCast(integer >> 16 & 0xFF), as: UInt8.self)
        default:
            self.writeInteger(0xFE, as: UInt8.self)
            self.writeInteger(numericCast(integer), endianness: .little, as: UInt64.self)
        }
    }

    mutating func writeLengthEncodedSlice(_ buffer: inout ByteBuffer) {
        self.writeLengthEncodedInteger(numericCast(buffer.readableBytes))
        self.writeBuffer(&buffer)
    }
    
    var readableString: String? {
        return self.getString(at: self.readerIndex, length: self.readableBytes)
    }
    
    var isZeroes: Bool {
        for byte in self.readableBytesView {
            switch byte {
            case 0x00: continue
            default: return false
            }
        }
        return true
    }
    
    mutating func readLengthEncodedString() -> String? {
        guard let length = self.readLengthEncodedInteger() else {
            return nil
        }
        return self.readString(length: numericCast(length))
    }
    
    mutating func readLengthEncodedSlice() -> ByteBuffer? {
        guard let length = self.readLengthEncodedInteger() else {
            return nil
        }
        return self.readSlice(length: numericCast(length))
    }
    
    mutating func readLengthEncodedInteger() -> UInt64? {
        guard let first = self.readInteger(endianness: .little, as: UInt8.self) else {
            return nil
        }
        
        switch first {
        case 0xFC:
            guard let uint16 = readInteger(endianness: .little, as: UInt16.self) else {
                return nil
            }
            return numericCast(uint16)
        case 0xFD:
            guard let one = readInteger(endianness: .little, as: UInt8.self) else {
                return nil
            }
            guard let two = readInteger(endianness: .little, as: UInt8.self) else {
                return nil
            }
            guard let three = readInteger(endianness: .little, as: UInt8.self) else {
                return nil
            }
            var num: UInt64 = 0
            num += numericCast(one)   << 0
            num += numericCast(two)   << 8
            num += numericCast(three) << 16
            return num
        case 0xFE:
            guard let uint64 = readInteger(endianness: .little, as: UInt64.self) else {
                return nil
            }
            return uint64
        default:
            return numericCast(first)
        }
    }
}

