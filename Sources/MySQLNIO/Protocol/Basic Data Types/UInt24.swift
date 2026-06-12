/// A minimal "24-bit integer" type, based on NIO's `_UInt24`.
///
/// This is intended for use by the raw packet framing and length-encoded integer logic _only_
/// and, despite all appearances, is not suitable for any other purpose.
/// Do not use it.
@usableFromInline
struct UInt24: UnsignedInteger, FixedWidthInteger {
    // MARK: - Equatable / Comparable

    @_transparent
    @inlinable
    static func == (lhs: UInt24, rhs: UInt24) -> Bool { lhs._value == rhs._value }

    @_transparent
    @inlinable
    static func < (lhs: UInt24, rhs: UInt24) -> Bool { lhs._value < rhs._value }

    // MARK: - AdditiveArithmetic

    @_transparent
    @usableFromInline
    static func + (lhs: UInt24, rhs: UInt24) -> UInt24 { .init(lhs._value + rhs._value) }

    @_transparent
    @usableFromInline
    static func - (lhs: UInt24, rhs: UInt24) -> UInt24 { .init(lhs._value - rhs._value) }

    // MARK: - ExpressibleByIntegerLiteral

    @_transparent
    @usableFromInline
    init(integerLiteral value: UInt32) { self.init(value) }

    // MARK: - Numeric

    @_transparent
    @usableFromInline
    static func * (lhs: UInt24, rhs: UInt24) -> UInt24 { .init(lhs._value * rhs._value) }

    @_transparent
    @usableFromInline
    static func *= (lhs: inout UInt24, rhs: UInt24) { lhs = lhs * rhs }

    // MARK: - Hashable

    @inlinable
    func hash(into hasher: inout Hasher) {
        hasher.combine(self._backing.0)
        hasher.combine(self._backing.1)
    }

    // MARK: - BinaryInteger

    @_transparent
    @usableFromInline
    var words: UInt32.Words { self._value.words }

    @_transparent
    @usableFromInline
    var trailingZeroBitCount: Int { Swift.min(self._value.trailingZeroBitCount, Self.bitWidth) }

    @_transparent
    @usableFromInline
    init(clamping source: some BinaryInteger) {
        if source < .zero {
            self = .min
            return
        }

        guard let source64 = UInt64(exactly: source) else {
            self = .max
            return
        }

        self = source64 > 0x00_ff_ff_ff ? .max : .init(.init(source64))
    }

    @_transparent
    @usableFromInline
    static func / (lhs: UInt24, rhs: UInt24) -> UInt24 { .init(lhs._value / rhs._value) }

    @_transparent
    @usableFromInline
    static func % (lhs: UInt24, rhs: UInt24) -> UInt24 { .init(lhs._value % rhs._value) }

    @_transparent
    @usableFromInline
    static func /= (lhs: inout UInt24, rhs: UInt24) { lhs = lhs / rhs }

    @_transparent
    @usableFromInline
    static func %= (lhs: inout UInt24, rhs: UInt24) { lhs = lhs % rhs }

    @_transparent
    @usableFromInline
    static func &= (lhs: inout UInt24, rhs: UInt24) { lhs = .init(lhs._value & rhs._value) }

    @_transparent
    @usableFromInline
    static func |= (lhs: inout UInt24, rhs: UInt24) { lhs = .init(lhs._value | rhs._value) }

    @_transparent
    @usableFromInline
    static func ^= (lhs: inout UInt24, rhs: UInt24) { lhs = .init(lhs._value ^ rhs._value) }

    // MARK: - FixedWidthInteger

    @_transparent
    @usableFromInline
    static var bitWidth: Int { MemoryLayout<Self>.size << 3 }

    @_transparent
    @usableFromInline
    var nonzeroBitCount: Int { self._backing.0.nonzeroBitCount + self._backing.1.nonzeroBitCount }

    @_transparent
    @usableFromInline
    var leadingZeroBitCount: Int { self._value.leadingZeroBitCount - (UInt32.bitWidth - Self.bitWidth) }

    @_transparent
    @usableFromInline
    var byteSwapped: UInt24 { .init(truncatingIfNeeded: self._value.byteSwapped >> (UInt32.bitWidth - Self.bitWidth)) }

    @_transparent
    @usableFromInline
    init(_truncatingBits: UInt) { self.init(UInt32(_truncatingBits: _truncatingBits) & 0x00_ff_ff_ff) }

    @_transparent
    @usableFromInline
    func addingReportingOverflow(_ rhs: UInt24) -> (partialValue: UInt24, overflow: Bool) {
        let result = self._value.addingReportingOverflow(rhs._value)

        return (partialValue: .init(truncatingIfNeeded: result.partialValue), overflow: result.overflow || result.partialValue > Self.max)
    }

    @_transparent
    @usableFromInline
    func subtractingReportingOverflow(_ rhs: UInt24) -> (partialValue: UInt24, overflow: Bool) {
        let result = self._value.subtractingReportingOverflow(rhs._value)

        return (partialValue: .init(truncatingIfNeeded: result.partialValue), overflow: result.overflow)
    }

    @_transparent
    @usableFromInline
    func multipliedReportingOverflow(by rhs: UInt24) -> (partialValue: UInt24, overflow: Bool) {
        let result = self._value.multipliedReportingOverflow(by: rhs._value)

        return (partialValue: .init(truncatingIfNeeded: result.partialValue), overflow: result.overflow || result.partialValue > Self.max)
    }

    @_transparent
    @usableFromInline
    func dividedReportingOverflow(by rhs: UInt24) -> (partialValue: UInt24, overflow: Bool) {
        let result = self._value.dividedReportingOverflow(by: rhs._value)

        return (partialValue: .init(truncatingIfNeeded: result.partialValue), overflow: result.overflow)
    }

    @_transparent
    @usableFromInline
    func remainderReportingOverflow(dividingBy rhs: UInt24) -> (partialValue: UInt24, overflow: Bool) {
        let result = self._value.remainderReportingOverflow(dividingBy: rhs._value)

        return (partialValue: .init(truncatingIfNeeded: result.partialValue), overflow: result.overflow)
    }

    @usableFromInline
    func dividingFullWidth(_ dividend: (high: UInt24, low: UInt24)) -> (quotient: UInt24, remainder: UInt24) {
        let (quotient32, remainder32) = self._value.dividingFullWidth(
            (
                high: dividend.high._value >> 8,
                low: (dividend.high._value & 0xff) << 24 | dividend.low._value
            )
        )
        guard quotient32 < Self.max, remainder32 < Self.max else {
            fatalError("Result out of bounds")
        }
        return (quotient: .init(quotient32), remainder: .init(remainder32))

    }

    // MARK: - Backing storage

    @usableFromInline
    var _backing: (UInt16, UInt8)

    @_transparent
    @inlinable
    var _value: UInt32 { .init(self._backing.0) << 8 | .init(self._backing.1) }

    @_transparent
    @usableFromInline
    init(_backing: (UInt16, UInt8)) { self._backing = _backing }

    @_transparent
    @usableFromInline
    init(_ value: UInt32) {
        precondition(value & 0xff_00_00_00 == 0, "value \(value) too large for UInt24")
        self.init(_backing: (.init(truncatingIfNeeded: value >> 8), .init(truncatingIfNeeded: value)))
    }
}
