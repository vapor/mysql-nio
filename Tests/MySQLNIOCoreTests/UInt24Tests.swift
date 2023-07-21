@testable import MySQLNIOCore
import XCTest
import Foundation
import NIOCore

final class UInt24Tests: XCTestCase {
    func testUInt24() {
        // MARK: AdditiveArithmetic
        XCTAssertEqual(UInt24(1) + UInt24(1), UInt24(2))
        XCTAssertEqual(UInt24(1) - UInt24(1), UInt24(0))
        // MARK: ExpressibleByIntegerLiteral
        XCTAssertEqual(2 as UInt24, UInt24(2))
        // MARK: Numeric
        XCTAssertEqual(UInt24(1) * UInt24(1), UInt24(1))
        XCTAssertEqual({ var i = UInt24.min; i *= 0; return i }(), UInt24.min)
        // MARK: BinaryInteger
        XCTAssertEqual(Array(UInt24(1).words), Array(UInt32(1).words))
        XCTAssertEqual(UInt24.max.trailingZeroBitCount, 0)
        XCTAssertEqual(UInt24.min.trailingZeroBitCount, UInt24.bitWidth)
        XCTAssertEqual(UInt24(clamping: -1), UInt24.min)
        XCTAssertEqual(UInt24(clamping: 0x1_00_00_00), UInt24.max)
        XCTAssertEqual(UInt24(1) / UInt24(1), UInt24(1))
        XCTAssertEqual(UInt24(1) % UInt24(1), UInt24(0))
        XCTAssertEqual({ var i = UInt24.min; i /= 1; return i }(), UInt24.min)
        XCTAssertEqual({ var i = UInt24.min; i %= 1; return i }(), UInt24.min)
        XCTAssertEqual({ var i = UInt24.min; i &= 0; return i }(), UInt24.min)
        XCTAssertEqual({ var i = UInt24.min; i |= 0; return i }(), UInt24.min)
        XCTAssertEqual({ var i = UInt24.min; i ^= 0; return i }(), UInt24.min)
        // MARK: FixedWidthInteger
        XCTAssertEqual(UInt24.bitWidth, 24)
        XCTAssertEqual(UInt24.min.nonzeroBitCount, 0)
        XCTAssertEqual(UInt24.max.leadingZeroBitCount, 0)
        XCTAssertEqual(UInt24.min.leadingZeroBitCount, UInt24.bitWidth)
        XCTAssertEqual(UInt24.max.byteSwapped, UInt24.max)
        XCTAssertEqual(UInt24(_truncatingBits: 0), UInt24(exactly: 0))
        XCTAssertEqual(UInt24.min.addingReportingOverflow(0).partialValue, 0)
        XCTAssertEqual(UInt24.min.subtractingReportingOverflow(0).partialValue, 0)
        XCTAssertEqual(UInt24.min.multipliedReportingOverflow(by: 0).partialValue, 0)
        XCTAssertEqual(UInt24.min.dividedReportingOverflow(by: 1).partialValue, 0)
        XCTAssertEqual(UInt24.min.remainderReportingOverflow(dividingBy: 1).partialValue, 0)
        XCTAssertEqual(UInt24(1).dividingFullWidth((high: 0, low: 0)).quotient, 0)
    }
}
