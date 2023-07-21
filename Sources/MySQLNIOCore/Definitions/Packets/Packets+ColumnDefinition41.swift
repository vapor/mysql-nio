import NIOCore

extension MySQLPackets {
    /// A MySQL wire protocol client column definition (4.1 protocol) packet.
    struct ColumnDefinition41 {
        
        /// Ostensibly, column definition packets don't actually have a marker byte. However, since the first
        /// value of a column definition is always the catalog, and the catalog is always "def", the first byte
        /// of the packet is always the length-encoded integer prefix for a 3-byte string, which is, of course,
        /// just `0x3`. This is not sufficient to _positively_ identify a column definition packet, since both
        /// a resultset field count packet and a text protocol data row packet can also start with this byte,
        /// but we can at least be quite certain that a packet that doesn't start with it is definitely not a
        /// column definition.
        static var markerByte: UInt8 { 0x03 }
        
        let schema: String
        let tableAlias: String
        let tableName: String
        let columnAlias: String
        let columnName: String
        let collation: MySQLTextCollation
        let maxLength: UInt32
        let format: MySQLProtocolValue.Format
        let flags: MySQLProtocolValue.Flags
        let visibleDecimalDigits: UInt8
        
        /// Capabilities provided for when support for ``MySQLCapabilities/mariadbAwkwardlyExtendedMetadata`` is added.
        init(from packet: ByteBuffer, activeCapabilities capabilities: MySQLCapabilities) throws {
            assert(!capabilities.contains(.mariadbAwkwardlyExtendedMetadata), "MariaDB extended metadata not yet supported, should not be enabled.")
            
            var packet = packet

            guard packet.mysql_readMarker(matching: Self.markerByte),
                  /*let catalog      =*/packet.mysql_readLengthEncodedString() == "def",
                  let schema          = packet.mysql_readLengthEncodedString(),
                  let tableAlias      = packet.mysql_readLengthEncodedString(),
                  let tableName       = packet.mysql_readLengthEncodedString(),
                  let columnAlias     = packet.mysql_readLengthEncodedString(),
                  let columnName      = packet.mysql_readLengthEncodedString(),
                  /*let fieldsLength =*/packet.mysql_readLengthEncodedInteger() == 0xc,
                  let (collationRaw, maxLength, formatRaw, flagsRaw, visibleDecimalDigits, _/*reserved*/)
                                      = packet.readMultipleIntegers(endianness: .little, as: (UInt16, UInt32, UInt8, UInt16, UInt8, UInt16).self)
            else {
                throw MySQLCoreError.protocolViolation(debugDescription: "Invalid column definition packet")
            }
            
            self.schema = schema
            self.tableAlias = tableAlias
            self.tableName = tableName
            self.columnAlias = columnAlias
            self.columnName = columnName
            self.collation = .lookup(byId: collationRaw)
            self.maxLength = maxLength
            self.format = .init(rawValue: formatRaw)
            self.flags = .init(columnFlags: flagsRaw)
            self.visibleDecimalDigits = visibleDecimalDigits
        }
        
        /// Capabilities provided for when support for ``MySQLCapabilities/mariadbAwkwardlyExtendedMetadata`` is added.
        func write(to buffer: inout ByteBuffer, activeCapabilities capabilities: MySQLCapabilities) {
            assert(!capabilities.contains(.mariadbAwkwardlyExtendedMetadata), "MariaDB extended metadata not yet supported, should not be enabled.")
            
            buffer.mysql_writeLengthEncodedString("def")
            buffer.mysql_writeLengthEncodedString(self.schema)
            buffer.mysql_writeLengthEncodedString(self.tableAlias)
            buffer.mysql_writeLengthEncodedString(self.tableName)
            buffer.mysql_writeLengthEncodedString(self.columnAlias)
            buffer.mysql_writeLengthEncodedString(self.columnName)
            buffer.mysql_writeLengthEncodedInteger(0xc)
            buffer.writeMultipleIntegers(
                self.collation.id,
                self.maxLength,
                self.format.rawValue,
                self.flags.columnFlagsValue,
                self.visibleDecimalDigits,
                0 as UInt16, // reserved
            endianness: .little)
        }
    }
}

extension MySQLPackets.ColumnDefinition41 {
    func build(allocator: ByteBufferAllocator = .init(), activeCapabilities: MySQLCapabilities) -> ByteBuffer {
        var buffer = allocator.buffer(capacity:
            4 + 4 + self.schema.utf8.count +
            self.tableAlias.utf8.count + self.tableName.utf8.count +
            self.columnAlias.utf8.count + self.columnName.utf8.count + 12)
        buffer.writeRepeatingByte(0, count: 4) // for frame
        self.write(to: &buffer, activeCapabilities: activeCapabilities)
        return buffer
    }
}
