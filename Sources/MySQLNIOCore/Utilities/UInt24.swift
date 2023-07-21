/// A minimal "24-bit integer" type, based on NIO's `_UInt24`. This is intended for use by the raw packet framing
/// and length-encoded integer logic _only_ and, despite all appearances, is not suitable for any other purpose.
/// Do not use it.
@usableFromInline
struct UInt24: UnsignedInteger, FixedWidthInteger {
    // MARK: - AdditiveArithmetic

    @_transparent
    @usableFromInline
    static func + (lhs: UInt24, rhs: UInt24) -> UInt24 { .init(UInt32(lhs) + UInt32(rhs)) }
    
    @_transparent
    @usableFromInline
    static func - (lhs: UInt24, rhs: UInt24) -> UInt24 { .init(UInt32(lhs) - UInt32(rhs)) }
    
    // MARK: - ExpressibleByIntegerLiteral

    @_transparent
    @usableFromInline
    init(integerLiteral value: UInt32) { self.init(value) }

    // MARK: - Numeric

    @_transparent
    @usableFromInline
    static func * (lhs: UInt24, rhs: UInt24) -> UInt24 { .init(UInt32(lhs) * UInt32(rhs)) }
    
    @_transparent
    @usableFromInline
    static func *= (lhs: inout UInt24, rhs: UInt24) { lhs = lhs * rhs }
    
    // MARK: - Hashable

    @inline(__always)
    @inlinable
    func hash(into hasher: inout Hasher) {
        hasher.combine(self._backing.0)
        hasher.combine(self._backing.1)
    }
    
    // MARK: - BinaryInteger
    
    @_transparent
    @usableFromInline
    var words: UInt32.Words { UInt32(self).words }

    @_transparent
    @usableFromInline
    var trailingZeroBitCount: Int { Swift.min(UInt32(self).trailingZeroBitCount, Self.bitWidth) }

    @_transparent
    @usableFromInline
    init(clamping source: some BinaryInteger) { self.init(source < .zero ? 0 : (source.bitWidth > Self.bitWidth ? source & 0xff_ff_ff : source)) }
    
    @_transparent
    @usableFromInline
    static func / (lhs: UInt24, rhs: UInt24) -> UInt24 { .init(UInt32(lhs) / UInt32(rhs)) }
    
    @_transparent
    @usableFromInline
    static func % (lhs: UInt24, rhs: UInt24) -> UInt24 { .init(UInt32(lhs) % UInt32(rhs)) }
    
    @_transparent
    @usableFromInline
    static func /= (lhs: inout UInt24, rhs: UInt24) { lhs = lhs / rhs }
    
    @_transparent
    @usableFromInline
    static func %= (lhs: inout UInt24, rhs: UInt24) { lhs = lhs % rhs }
    
    @_transparent
    @usableFromInline
    static func &= (lhs: inout UInt24, rhs: UInt24) { lhs = .init(UInt32(lhs) & UInt32(rhs)) }
    
    @_transparent
    @usableFromInline
    static func |= (lhs: inout UInt24, rhs: UInt24) { lhs = .init(UInt32(lhs) | UInt32(rhs)) }
    
    @_transparent
    @usableFromInline
    static func ^= (lhs: inout UInt24, rhs: UInt24) { lhs = .init(UInt32(lhs) ^ UInt32(rhs)) }

    // MARK: - FixedWidthInteger

    @_transparent
    @usableFromInline
    static var bitWidth: Int { MemoryLayout<Self>.size << 3 }

    @_transparent
    @usableFromInline
    var nonzeroBitCount: Int { self._backing.0.nonzeroBitCount + self._backing.1.nonzeroBitCount }

    @_transparent
    @usableFromInline
    var leadingZeroBitCount: Int { UInt32(self).leadingZeroBitCount - (UInt32.bitWidth - Self.bitWidth) }
    
    @_transparent
    @usableFromInline
    var byteSwapped: UInt24 { .init(truncatingIfNeeded: UInt32(self).byteSwapped >> (UInt32.bitWidth - Self.bitWidth)) }
    
    @_transparent
    @usableFromInline
    init(_truncatingBits: UInt) { self.init(UInt32(_truncatingBits: _truncatingBits) & 0x00_ff_ff_ff) }

    @inline(__always)
    @inlinable
    func addingReportingOverflow(_ rhs: UInt24) -> (partialValue: UInt24, overflow: Bool) {
        let result = UInt32(self).addingReportingOverflow(.init(rhs))
    
        return (partialValue: .init(truncatingIfNeeded: result.partialValue), overflow: result.overflow || result.partialValue > Self.max)
    }
    
    @inline(__always)
    @inlinable
    func subtractingReportingOverflow(_ rhs: UInt24) -> (partialValue: UInt24, overflow: Bool) {
        let result = UInt32(self).subtractingReportingOverflow(.init(rhs))
        
        return (partialValue: .init(truncatingIfNeeded: result.partialValue), overflow: result.overflow)
    }
    
    @inline(__always)
    @inlinable
    func multipliedReportingOverflow(by rhs: UInt24) -> (partialValue: UInt24, overflow: Bool) {
        let result = UInt32(self).multipliedReportingOverflow(by: .init(rhs))
   
        return (partialValue: .init(truncatingIfNeeded: result.partialValue), overflow: result.overflow || result.partialValue > Self.max)
    }
    
    @inline(__always)
    @inlinable
    func dividedReportingOverflow(by rhs: UInt24) -> (partialValue: UInt24, overflow: Bool) {
        let result = UInt32(self).dividedReportingOverflow(by: .init(rhs))
   
        return (partialValue: .init(truncatingIfNeeded: result.partialValue), overflow: result.overflow)
    }
    
    @inline(__always)
    @inlinable
    func remainderReportingOverflow(dividingBy rhs: UInt24) -> (partialValue: UInt24, overflow: Bool) {
        let result = UInt32(self).remainderReportingOverflow(dividingBy: .init(rhs))
        
        return (partialValue: .init(truncatingIfNeeded: result.partialValue), overflow: result.overflow)
    }
    
    @inline(__always)
    @inlinable
    func dividingFullWidth(_ dividend: (high: UInt24, low: UInt24)) -> (quotient: UInt24, remainder: UInt24) {
        let (quotient32, remainder32) = UInt32(self).dividingFullWidth((
            high: .init(dividend.high) >> 8,
            low: .init(dividend.high & 0xff) << 24 | .init(dividend.low)
        ))
        guard quotient32 < Self.max, remainder32 < Self.max else {
            fatalError("Result out of bounds")
        }
        return (quotient: .init(quotient32), remainder: .init(remainder32))
   
    }
    
    // MARK: - Backing storage
    
    @usableFromInline
    var _backing: (UInt16, UInt8)
    
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
