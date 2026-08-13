import NIOCore

/// `MySQLRow` represents a single table row that is received from the server for a query or a prepared statement.
/// Its element type is ``MySQLCell``.
///
/// > Warning: Please note that random access to cells in a ``MySQLRow`` has O(n) time complexity.
/// > If you require random access to cells in O(1),
/// > create a new ``MySQLRandomAccessRow`` with the given row and access it instead.
public struct MySQLRow: Sendable {
    @usableFromInline
    let lookupTable: [String: Int]
    @usableFromInline
    let data: DataRow
    @usableFromInline
    let columns: [ColumnDefinition]

    init(data: DataRow, lookupTable: [String: Int], columns: [ColumnDefinition]) {
        self.data = data
        self.lookupTable = lookupTable
        self.columns = columns
    }
}

extension MySQLRow: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        // We don't need to compare the lookup table here,
        // as the lookup table is only derived from the column definitions.
        lhs.data == rhs.data && lhs.columns == rhs.columns
    }
}

extension MySQLRow: Sequence {
    public typealias Element = MySQLCell

    public struct Iterator: IteratorProtocol {
        public typealias Element = MySQLCell

        private(set) var columnIndex: Array<ColumnDefinition>.Index
        private(set) var columnIterator: Array<ColumnDefinition>.Iterator
        private(set) var dataIterator: DataRow.Iterator

        init(_ row: MySQLRow) {
            self.columnIndex = 0
            self.columnIterator = row.columns.makeIterator()
            self.dataIterator = row.data.makeIterator()
        }

        public mutating func next() -> MySQLCell? {
            guard let bytes = self.dataIterator.next() else {
                return nil
            }

            let column = self.columnIterator.next()!

            defer { self.columnIndex += 1 }

            return MySQLCell(
                bytes: bytes,
                dataType: column.dataType,
                format: column.format,
                columnName: column.name,
                columnIndex: columnIndex
            )
        }
    }

    public func makeIterator() -> Iterator {
        Iterator(self)
    }
}

extension MySQLRow: Collection {
    public struct Index: Comparable {
        var cellIndex: DataRow.Index
        var columnIndex: Array<ColumnDefinition>.Index

        // Only needed implementation for `Comparable`. The compiler synthesizes the rest from this.
        public static func < (lhs: Self, rhs: Self) -> Bool {
            lhs.columnIndex < rhs.columnIndex
        }
    }

    public subscript(position: Index) -> MySQLCell {
        // TODO: Fix crash when there is no column definitions (i.e. when `metadata_follows = 0`)
        let column = self.columns[position.columnIndex]
        return MySQLCell(
            bytes: self.data[position.cellIndex],
            dataType: column.dataType,
            format: column.format,
            columnName: column.name,
            columnIndex: position.columnIndex
        )
    }

    public var startIndex: Index {
        Index(
            cellIndex: self.data.startIndex,
            columnIndex: 0
        )
    }

    public var endIndex: Index {
        Index(
            cellIndex: self.data.endIndex,
            columnIndex: self.columns.count
        )
    }

    public func index(after i: Index) -> Index {
        Index(
            cellIndex: self.data.index(after: i.cellIndex),
            columnIndex: self.columns.index(after: i.columnIndex)
        )
    }

    public var count: Int {
        self.data.count
    }
}

extension MySQLRow {
    public func makeRandomAccess() -> MySQLRandomAccessRow {
        MySQLRandomAccessRow(self)
    }
}

/// A random access row of ``MySQLCell``s.
///
/// Its initialization is O(n), where n is the number of columns in the row. All subsequent cell accesses are O(1).
public struct MySQLRandomAccessRow {
    let columns: [ColumnDefinition]
    let cells: [ByteBuffer?]
    let lookupTable: [String: Int]

    public init(_ row: MySQLRow) {
        self.cells = [ByteBuffer?](row.data)
        self.columns = row.columns
        self.lookupTable = row.lookupTable
    }
}

extension MySQLRandomAccessRow: Sendable, RandomAccessCollection {
    public typealias Element = MySQLCell
    public typealias Index = Int

    public var startIndex: Int { 0 }

    public var endIndex: Int {
        self.columns.count
    }

    public var count: Int {
        self.columns.count
    }

    public subscript(index: Int) -> MySQLCell {
        guard index < self.endIndex else {
            preconditionFailure("index out of bounds")
        }
        let column = self.columns[index]
        return MySQLCell(
            bytes: self.cells[index],
            dataType: column.dataType,
            format: column.format,
            columnName: column.name,
            columnIndex: index
        )
    }

    public subscript(name: String) -> MySQLCell? {
        guard let index = self.lookupTable[name] else {
            return nil
        }
        return self[index]
    }

    /// Checks if the row contains a cell for the given column name.
    /// - Parameter column: The column name to check against.
    /// - Returns: `true` if the row contains this column, `false` if it does not.
    public func contains(_ column: String) -> Bool {
        self.lookupTable[column] != nil
    }
}
