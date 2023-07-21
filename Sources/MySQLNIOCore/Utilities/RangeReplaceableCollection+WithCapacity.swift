extension RangeReplaceableCollection {
    /// A shorthand initializer combining `self.init()` and `self.reserveCapacity(_:)`.
    public init(reservingCapacity n: Int) {
        self.init()
        self.reserveCapacity(n)
    }
}
