import NIOCore

extension ByteBuffer {
    mutating func readInteger<T>(endianness: Endianness = .big, as: T.Type = T.self) -> T?
        where T: RawRepresentable, T.RawValue: FixedWidthInteger
    {
        return self.readInteger(endianness: endianness, as: T.RawValue.self)
            .flatMap(T.init(rawValue:))
    }
    
    @discardableResult
    mutating func writeLengthEncodedInteger(_ integer: UInt64) -> Int {
        switch integer {
        case 0..<251:
            return self.writeInteger(numericCast(integer), as: UInt8.self)
        case 251..<1<<16:
            return self.writeBytes([0xfc, .init(integer & 0xff), .init(integer >> 8 & 0xff)])
        case 1<<16..<1<<24:
            return self.writeBytes([0xfd, .init(integer & 0xff), .init(integer >> 8 & 0xff), .init(integer >> 16 & 0xff)])
        default:
            return self.writeInteger(0xfe, as: UInt8.self) + self.writeInteger(integer, endianness: .little, as: UInt64.self)
        }
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
        switch self.readInteger(endianness: .little, as: UInt8.self) {
            case .none:
                return nil
            case .some(0xfc):
                return readInteger(endianness: .little, as: UInt16.self).map(numericCast)
            case .some(0xfd):
                return readBytes(length: 3).map { $0.reversed().reduce(UInt64.zero) { ($0 << 8) | numericCast($1) } }
            case .some(0xfe):
                return readInteger(endianness: .little, as: UInt64.self)
            case .some(let byte):
                return numericCast(byte)
        }
    }
}

