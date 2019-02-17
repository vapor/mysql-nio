extension MySQLPacket {
    public init(_ sslRequest: SSLRequest) {
        self.payload = ByteBufferAllocator().buffer(capacity: 0)
        sslRequest.serialize(into: &self.payload)
    }
    
    /// Protocol::SSLRequest:
    ///
    /// SSL Connection Request Packet. It is like Handshake Response Packet but is truncated right before username field.
    /// If server supports CLIENT_SSL capability, client can send this packet to request a secure SSL connection.
    /// The CLIENT_SSL capability flag must be set inside the SSL Connection Request Packet.
    ///
    /// https://dev.mysql.com/doc/internals/en/connection-phase-packets.html#packet-Protocol::SSLRequest
    public struct SSLRequest {
        /// capability_flags (4)
        /// capability flags of the client as defined in Protocol::CapabilityFlags
        /// CLIENT_SSL always set
        public var capabilities: MySQLCapabilityFlags
        
        /// max_packet_size (4)
        /// max size of a command packet that the client wants to send to the server
        public var maxPacketSize: UInt32
        
        /// character_set (1)
        /// connection's default character set as defined in Protocol::CharacterSet.
        public var characterSet: MySQLCharacterSet
        
        public init(capabilities: MySQLCapabilityFlags, maxPacketSize: UInt32, characterSet: MySQLCharacterSet) {
            assert(capabilities.contains(.CLIENT_SSL), "SSLRequest packet must have CLIENT_SSL capability.")
            self.capabilities = capabilities
            self.maxPacketSize = maxPacketSize
            self.characterSet = characterSet
        }
        
        /// Serializes the `SSLRequest` into a buffer.
        internal func serialize(into buffer: inout ByteBuffer) {
            buffer.writeInteger(self.capabilities.general, endianness: .little, as: UInt32.self)
            buffer.writeInteger(self.maxPacketSize, endianness: .little)
            self.characterSet.serialize(into: &buffer)
            /// string[23]     reserved (all [0])
            buffer.writeBytes([
                0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                0x00, 0x00, 0x00
            ])
        }
    }
}
