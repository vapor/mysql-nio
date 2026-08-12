public import NIOCore

/// A backend data row message.
@usableFromInline
struct DataRow: Sendable, Hashable {
    @usableFromInline
    var columnCount: UInt64
    @usableFromInline
    var bytes: ByteBuffer
}

extension DataRow: Sequence {
    @usableFromInline
    typealias Element = ByteBuffer?
}

extension DataRow: Collection {
    @usableFromInline
    struct ColumnIndex: Comparable {
        @usableFromInline
        var offset: Int

        @inlinable
        init(_ index: Int) {
            self.offset = index
        }

        // Only needed implementation for `Comparable`. The compiler synthesizes the rest from this.
        @inlinable
        static func < (lhs: Self, rhs: Self) -> Bool {
            lhs.offset < rhs.offset
        }
    }

    @usableFromInline
    typealias Index = DataRow.ColumnIndex

    @inlinable
    var startIndex: ColumnIndex {
        ColumnIndex(self.bytes.readerIndex)
    }

    @inlinable
    var endIndex: ColumnIndex {
        ColumnIndex(self.bytes.readerIndex + self.bytes.readableBytes)
    }

    @inlinable
    var count: Int {
        Int(self.columnCount)
    }

    @inlinable
    func index(after index: ColumnIndex) -> ColumnIndex {
        guard index < self.endIndex else {
            preconditionFailure("index out of bounds")
        }

        guard let header = self.bytes.getInteger(at: index.offset, as: UInt8.self) else {
            preconditionFailure("invalid row data")
        }
        if header == 0xFB {
            return ColumnIndex(index.offset + 1)
        }

        var copy = self.bytes
        copy.moveReaderIndex(to: index.offset)
        guard copy.readLengthPrefixedSlice(strategy: .mySQL) != nil else {
            preconditionFailure("invalid row data")
        }
        return ColumnIndex(copy.readerIndex)
    }

    @inlinable
    subscript(index: ColumnIndex) -> Element {
        guard index < self.endIndex else {
            preconditionFailure("index out of bounds")
        }

        guard let header = self.bytes.getInteger(at: index.offset, as: UInt8.self) else {
            preconditionFailure("invalid row data")
        }
        if header == 0xFB {
            return nil
        }

        var copy = self.bytes
        copy.moveReaderIndex(to: index.offset)
        guard let value = copy.readLengthPrefixedSlice(strategy: .mySQL) else {
            preconditionFailure("invalid row data")
        }
        return value
    }
}

extension DataRow {
    subscript(column index: Int) -> Element {
        guard index < self.columnCount else {
            preconditionFailure("index out of bounds")
        }

        var byteIndex = self.startIndex
        for _ in 0..<index {
            byteIndex = self.index(after: byteIndex)
        }

        return self[byteIndex]
    }
}
