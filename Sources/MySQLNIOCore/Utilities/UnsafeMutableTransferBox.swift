/// ``UnsafeTransfer`` can be used to make non-`Sendable` values `Sendable`.
/// As the name implies, the usage of this is unsafe because it disables the sendable checking of the compiler.
/// It can be used similar to `@unsafe Sendable` but for values instead of types.
@usableFromInline
struct UnsafeTransfer<Wrapped>: @unchecked Sendable {
    @usableFromInline
    var wrappedValue: Wrapped
    
    @inlinable
    init(_ wrappedValue: Wrapped) {
        self.wrappedValue = wrappedValue
    }
}
extension UnsafeTransfer: Equatable where Wrapped: Equatable {}
extension UnsafeTransfer: Hashable where Wrapped: Hashable {}


/// Unsafely enables mutation of local values from within `@Sendable` closures
///
/// > This type and is implementation are copied mostly verbatim from `NIOCore`.
///
/// ## Original documentation
///
/// ``UnsafeMutableTransferBox`` is used to make non-`Sendable` values `Sendable` and mutable.
/// It can be used to capture local mutable values in a `@Sendable` closure and mutate them from
/// within the closure. As the name implies, its usage is unsafe because it disables the
/// compiler's `Sendable` checking without providing any synchronization.
@usableFromInline
final class UnsafeMutableTransferBox<Wrapped>: @unchecked Sendable {
    /// The mutable non-`Sendable` value
    @usableFromInline
    var wrappedValue: Wrapped
    
    /// Wraps a value
    @inlinable
    init(_ wrappedValue: Wrapped) {
        self.wrappedValue = wrappedValue
    }
}
