import NIOCore

/// The property wrapper version of `NIOLoopBound`.
///
/// Because the event loop must be known at initialization time, it is generally necessary to initialize
/// the backing storage of properties using this wrapper in the containing type's initializer rather than
/// inline in the property declaration.
@propertyWrapper
struct EventLoopBound<T>: Sendable {
    private var loopBoundValue: NIOLoopBound<T>
    
    init(initialValue: T, eventLoop: any EventLoop) {
        self.loopBoundValue = .init(initialValue, eventLoop: eventLoop)
    }
    
    var wrappedValue: T {
        get { self.loopBoundValue.value }
        set { self.loopBoundValue.value = newValue }
    }
}
