public import NIOCore

/// A representation of a cell value within a ``MySQLRow`` and ``MySQLRandomAccessRow``.
public struct MySQLCell: Sendable, Equatable {
    /// The cell's value as raw bytes.
    public var bytes: ByteBuffer?
    /// The cell's data type. This is important metadata when decoding the cell.
    public var dataType: MySQLDataType
    /// The format in which the cell's bytes are encoded.
    public var format: MySQLFormat

    /// The cell's column name within the row.
    public var columnName: String
    /// The cell's column index within the row.
    public var columnIndex: Int

    public init(
        bytes: ByteBuffer?,
        dataType: MySQLDataType,
        format: MySQLFormat,
        columnName: String,
        columnIndex: Int
    ) {
        self.bytes = bytes
        self.dataType = dataType
        self.format = format

        self.columnName = columnName
        self.columnIndex = columnIndex
    }
}
