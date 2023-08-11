import NIOCore

extension MySQLPackets {
    /// A MySQL wire protocol auth method switch request packet
    struct AuthSwitchPacket {
        static var markerByte: UInt8 { 0xfe }
        
        let newPluginName: String
        let newPluginData: ByteBuffer
        
        init(from packet: ByteBuffer) throws {
            var packet = packet

            guard packet.mysql_readMarker(matching: Self.markerByte),
                  let pluginName = packet.readNullTerminatedString(),
                  let pluginData = packet.readSlice(length: packet.readableBytes)
            else {
                throw MySQLCoreError.protocolViolation(debugDescription: "Invalid auth switch packet")
            }
            
            self.newPluginName = pluginName
            self.newPluginData = pluginData
        }
        
        func write(to buffer: inout ByteBuffer) {
            buffer.mysql_writeInteger(Self.markerByte)
            buffer.writeNullTerminatedString(self.newPluginName)
            buffer.writeImmutableBuffer(self.newPluginData)
        }
    }
    
    /// A MySQL wire protocol auth data packet
    struct AuthMoreDataPacket {
        static var markerByte: UInt8 { 0x01 }
        
        let data: ByteBuffer
        
        init(from packet: ByteBuffer) throws {
            var packet = packet
            guard packet.mysql_readMarker(matching: Self.markerByte) else {
                throw MySQLCoreError.protocolViolation(debugDescription: "Invalid auth more data packet")
            }
            
            self.data = packet.slice()
        }
        
        func write(to buffer: inout ByteBuffer) {
            buffer.mysql_writeInteger(Self.markerByte)
            buffer.writeImmutableBuffer(self.data)
        }
    }
}

extension MySQLPackets.AuthSwitchPacket {
    func build(allocator: ByteBufferAllocator = .init()) -> ByteBuffer {
        var buffer = allocator.buffer(capacity: 4 + 1 + self.newPluginName.utf8.count + self.newPluginData.readableBytes)
        buffer.writeRepeatingByte(0, count: 4) // for frame
        self.write(to: &buffer)
        return buffer
    }
}

extension MySQLPackets.AuthMoreDataPacket {
    func build(allocator: ByteBufferAllocator = .init()) -> ByteBuffer {
        var buffer = allocator.buffer(capacity: 4 + 1 + self.data.readableBytes)
        buffer.writeRepeatingByte(0, count: 4) // for frame
        self.write(to: &buffer)
        return buffer
    }
}
