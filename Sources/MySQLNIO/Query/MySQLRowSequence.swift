/// An async sequence of ``MySQLRow``s.
///
/// - Note: This is a struct to allow us to move to a move-only type easily once they become available.
public struct MySQLRowSequence: AsyncSequence, Sendable {
    public typealias Element = MySQLRow

    @usableFromInline
    typealias BackingSequence = AsyncThrowingStream<Element, any Error>
    @usableFromInline
    typealias Continuation = BackingSequence.Continuation

    let backing: BackingSequence
    // TODO: public let columns: [ColumnDefinition]

    static func makeStream() -> (Self, Self.Continuation) {
        let (stream, continuation) = BackingSequence.makeStream()
        return (.init(backing: stream), continuation)
    }

    public func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(base: self.backing.makeAsyncIterator())
    }
}

extension MySQLRowSequence {
    public struct AsyncIterator: AsyncIteratorProtocol {
        var base: BackingSequence.AsyncIterator

        @concurrent
        public mutating func next() async throws -> Element? {
            try await self.base.next()
        }

        public mutating func next(isolation actor: isolated (any Actor)?) async throws(any Error) -> Element? {
            try await self.base.next(isolation: actor)
        }
    }
}

@available(*, unavailable)
extension MySQLRowSequence.AsyncIterator: Sendable {}

extension MySQLRowSequence {
    public func collect() async throws -> [Element] {
        var result = [Element]()
        for try await row in self {
            result.append(row)
        }
        return result
    }
}
