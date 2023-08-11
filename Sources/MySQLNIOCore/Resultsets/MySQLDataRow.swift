import NIOCore

protocol MySQLDataRowValues: RandomAccessCollection where Index == Int {
    var valuesEncoding: MySQLProtocolValue.Encoding { get }
    var valueSlices: [ByteBuffer?] { get }
}

extension MySQLDataRowValues {
    var startIndex: Int { self.valueSlices.startIndex }
    var endIndex: Int { self.valueSlices.endIndex }
    
    subscript(position: Int) -> ByteBuffer? {
        self.valueSlices[position]
    }
}

extension MySQLPackets.TextResultsetRow: MySQLDataRowValues {
    var valuesEncoding: MySQLProtocolValue.Encoding { .text }
}

extension MySQLPackets.BinaryResultsetRow: MySQLDataRowValues {
    var valuesEncoding: MySQLProtocolValue.Encoding { .binary }
}

struct MySQLFieldIdentifier: Sendable, Hashable {
    var schema: String?
    var table: String?
    var name: String
    var index: Int
}
