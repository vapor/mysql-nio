import NIOCore
import Collections

extension MySQLPackets {
    /// A MySQL wire protocol client `COM_QUERY` command packet.
    struct PlainQueryCommand {
        static var commandByte: UInt8 { 0x03 }
        
        let attributes: OrderedDictionary<String, MySQLProtocolValue>
        let sql: String
        
        init(from packet: ByteBuffer, activeCapabilities capabilities: MySQLCapabilities) throws {
            var packet = packet
            guard packet.mysql_readMarker(matching: Self.commandByte) else {
                throw MySQLCoreError.protocolViolation(debugDescription: "Invalid plain query command packet")
            }
            
            var params: OrderedDictionary<String, MySQLProtocolValue> = [:]
            
            if capabilities.contains(.queryAttributes) {
                guard let numParams       = packet.mysql_readLengthEncodedInteger().map(Int.init(_:)),
                      /*let numParamSets =*/packet.mysql_readLengthEncodedInteger() == 1
                else {
                    throw MySQLCoreError.protocolViolation(debugDescription: "Invalid plain query command packet")
                }
                
                if numParams > 0 {
                    guard let nullBitmap  = packet.readBytes(length: (numParams + 7) / 8).map({ FixedBitArray(bytes: $0, significantBits: numParams) }),
                          /*let bindFlag =*/packet.mysql_readInteger(as: UInt8.self) == 1
                    else {
                        throw MySQLCoreError.protocolViolation(debugDescription: "Invalid plain query command packet")
                    }
                    
                    params.reserveCapacity(numParams)
                    for i in 0..<Int(numParams) {
                        guard let valueFormat   = packet.mysql_readInteger(as: UInt8.self).flatMap(MySQLProtocolValue.Format.init(rawValue:)),
                              /*let valueFlags =*/packet.mysql_readInteger(as: UInt8.self) != nil,
                              let valueName     = packet.mysql_readLengthEncodedString(),
                              let valueSize     = nullBitmap[i] ? 0 : (
                                                      MySQLProtocolValue.Metadata.dataSize(format: valueFormat, encoding: .binary) ??
                                                      packet.mysql_readLengthEncodedInteger().map(Int.init(_:))
                                                  ),
                              let valueBytes    = packet.mysql_optional(!nullBitmap[i], packet.readSlice(length: valueSize))
                        else {
                            throw MySQLCoreError.protocolViolation(debugDescription: "Invalid plain query command packet")
                        }
                        
                        params[valueName] = .init(metadata: .init(format: valueFormat, encoding: .binary), data: valueBytes)
                    }
                }
            }
            guard let sql = packet.readString(length: packet.readableBytes) else {
                throw MySQLCoreError.protocolViolation(debugDescription: "Invalid plain query command packet")
            }
            
            self.attributes = params
            self.sql = sql
        }
        
        init(attributes: OrderedDictionary<String, MySQLProtocolValue> = [:], sql: String) {
            self.attributes = attributes
            self.sql = sql
        }
        
        init(attributes: some Sequence<(String, MySQLProtocolValue)>, sql: String) {
            self.init(attributes: .init(attributes) { $1 }, sql: sql)
        }
        
        func write(to buffer: inout ByteBuffer, activeCapabilities capabilities: MySQLCapabilities) {
            buffer.mysql_writeInteger(Self.commandByte)
            if capabilities.contains(.queryAttributes) {
                buffer.mysql_writeLengthEncodedInteger(self.attributes.count)
                buffer.mysql_writeLengthEncodedInteger(1)
                
                if !self.attributes.isEmpty {
                    buffer.writeBytes(FixedBitArray(attributes.map { $0.value.data == nil }).bytes)
                    buffer.mysql_writeInteger(1)
                    for (name, param) in self.attributes {
                        buffer.writeMultipleIntegers(param.metadata.format.rawValue, 0 as UInt8, endianness: .little)
                        buffer.mysql_writeLengthEncodedString(name)
                        if let data = param.data {
                            if param.metadata.dataSize() == nil {
                                buffer.mysql_writeLengthEncodedInteger(data.readableBytes)
                            }
                            buffer.mysql_writeLengthEncodedImmutableBuffer(data)
                        }
                    }
                }
            }
            buffer.writeString(self.sql)
        }
    }
}

extension MySQLPackets.PlainQueryCommand {
    func build(allocator: ByteBufferAllocator = .init(), activeCapabilities: MySQLCapabilities) -> ByteBuffer {
        var buffer = allocator.buffer(capacity: 4 + 1 + self.sql.utf8.count)
        buffer.writeRepeatingByte(0, count: 4) // for frame
        self.write(to: &buffer, activeCapabilities: activeCapabilities)
        return buffer
    }
}
