import NIOCore

extension MySQLPacketDescriptions {
    /// A MySQL wire protocol auth method switch request packet
    struct AuthSwitchPacket {
        static var markerByte: UInt8 { 0xfe }
        
        let newPluginName: String
        let newPluginData: ByteBuffer
        
        init?(from packet: ByteBuffer) throws {
            var packet = packet

            guard try packet.mysql_readMarker(matching: Self.markerByte) else { return nil }
            guard let pluginName = packet.readNullTerminatedString(),
                  let pluginData = packet.readSlice(length: packet.readableBytes)
            else {
                throw MySQLChannel.Error.protocolViolation
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
        
        init?(from packet: ByteBuffer) throws {
            var packet = packet
            guard try packet.mysql_readMarker(matching: Self.markerByte) else { return nil }
            
            self.data = packet.slice()
        }
        
        func write(to buffer: inout ByteBuffer) {
            buffer.mysql_writeInteger(Self.markerByte)
            buffer.writeImmutableBuffer(self.data)
        }
    }
}
