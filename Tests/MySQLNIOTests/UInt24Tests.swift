import NIOCore
import Testing

@testable import MySQLNIO

@Suite("UInt24 Tests")
struct UInt24Tests {
    @Test("AdditiveArithmetic")
    func additiveArithmetic() {
        #expect(UInt24(1) + UInt24(1) == UInt24(2))
        #expect(UInt24(1) - UInt24(1) == UInt24(0))
    }

    @Test("ExpressibleByIntegerLiteral")
    func expressibleByIntegerLiteral() {
        #expect(2 as UInt24 == UInt24(2))
    }

    @Test("Numeric")
    func numeric() {
        #expect(UInt24(1) * UInt24(1) == UInt24(1))
        var i = UInt24.min
        i *= 0
        #expect(i == UInt24.min)
    }

    @Test("BinaryInteger")
    func binaryInteger() {
        #expect(Array(UInt24(1).words) == Array(UInt32(1).words))
        #expect(UInt24.max.trailingZeroBitCount == 0)
        #expect(UInt24.min.trailingZeroBitCount == UInt24.bitWidth)
        #expect(UInt24(clamping: -1) == UInt24.min)
        #expect(UInt24(clamping: 0x1_00_00_00) == UInt24.max)
        #expect(UInt24(1) / UInt24(1) == UInt24(1))
        #expect(UInt24(1) % UInt24(1) == UInt24(0))
        var i = UInt24.min
        i /= 1
        #expect(i == UInt24.min)
        var j = UInt24.min
        j %= 1
        #expect(j == UInt24.min)
        var x = UInt24.min
        x &= 0
        #expect(x == UInt24.min)
        var y = UInt24.min
        y |= 0
        #expect(y == UInt24.min)
        var z = UInt24.min
        z ^= 0
        #expect(z == UInt24.min)
    }

    @Test("FixedWidthInteger")
    func fixedWidthInteger() {
        #expect(UInt24.bitWidth == 24)
        #expect(UInt24.min.nonzeroBitCount == 0)
        #expect(UInt24.max.leadingZeroBitCount == 0)
        #expect(UInt24.min.leadingZeroBitCount == UInt24.bitWidth)
        #expect(UInt24.max.byteSwapped == UInt24.max)
        #expect(UInt24(_truncatingBits: 0) == UInt24(exactly: 0))
        #expect(UInt24.min.addingReportingOverflow(0).partialValue == 0)
        #expect(UInt24.min.subtractingReportingOverflow(0).partialValue == 0)
        #expect(UInt24.min.multipliedReportingOverflow(by: 0).partialValue == 0)
        #expect(UInt24.min.dividedReportingOverflow(by: 1).partialValue == 0)
        #expect(UInt24.min.remainderReportingOverflow(dividingBy: 1).partialValue == 0)
        #expect(UInt24(1).dividingFullWidth((high: 0, low: 0)).quotient == 0)
    }

    @Test("Endianness")
    func endianness() {
        #if _endian(little)
        #expect(UInt24(0x01_02_03).bigEndian == UInt24(0x03_02_01))
        #expect(UInt24(0x01_02_03).littleEndian == UInt24(0x01_02_03))
        #else
        #expect(UInt24(0x01_02_03).bigEndian == UInt24(0x01_02_03))
        #expect(UInt24(0x01_02_03).littleEndian == UInt24(0x03_02_01))
        #endif
        #expect(UInt24(0x01_02_03).byteSwapped == UInt24(0x03_02_01))
    }
}
