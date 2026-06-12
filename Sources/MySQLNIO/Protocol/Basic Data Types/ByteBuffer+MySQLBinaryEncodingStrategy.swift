public import NIOCore

extension ByteBuffer {
    @usableFromInline
    struct MySQLBinaryEncodingStrategy: NIOBinaryIntegerEncodingStrategy {
        @usableFromInline
        init() {}

        @inlinable
        func readInteger<IntegerType: FixedWidthInteger>(as: IntegerType.Type, from buffer: inout ByteBuffer) -> IntegerType? {
            guard let firstByte = buffer.readInteger(as: UInt8.self) else { return nil }
            return switch firstByte {
            case ...0xFB:
                IntegerType(firstByte)
            case 0xFC:
                buffer.readInteger(endianness: .little, as: UInt16.self).map { IntegerType($0) }
            case 0xFD:
                buffer.readBytes(length: 3).map { $0.reversed().reduce(UInt32.zero) { ($0 << 8) | numericCast($1) } }.map { IntegerType($0) }
            case 0xFE:
                buffer.readInteger(endianness: .little, as: UInt64.self).map { IntegerType($0) }
            default:
                fatalError("Unreachable")
            }
        }

        @inlinable
        func writeInteger<IntegerType: FixedWidthInteger>(_ integer: IntegerType, to buffer: inout ByteBuffer) -> Int {
            // We must cast the integer to UInt64 here
            // Otherwise, an integer can fall through to the default case
            // E.g., if someone calls this function with UInt8.max (which is 255), they would not hit the first case (0..<251)
            // The second case cannot be represented at all in UInt8, because 65536 (1 << 16) is too big
            // Swift will end up creating the 65536 literal as 0, and thus we will fall all the way through to the default
            switch UInt64(integer) {
            case 0..<251:
                buffer.writeInteger(UInt8(truncatingIfNeeded: integer))
            case 251..<(1 << 16):
                buffer.writeBytes([0xFC, .init(integer & 0xff), .init(integer >> 8 & 0xff)])
            case (1 << 16)..<(1 << 24):
                buffer.writeBytes([0xFD, .init(integer & 0xff), .init(integer >> 8 & 0xff), .init(integer >> 16 & 0xff)])
            case (1 << 24)..<(1 << 64):
                buffer.writeInteger(0xFE, as: UInt8.self) + buffer.writeInteger(UInt64(truncatingIfNeeded: integer), endianness: .little)
            default:
                fatalError("Unreachable")
            }
        }
    }
}

extension NIOBinaryIntegerEncodingStrategy where Self == ByteBuffer.MySQLBinaryEncodingStrategy {
    @inlinable
    static var mySQL: Self { .init() }
}
