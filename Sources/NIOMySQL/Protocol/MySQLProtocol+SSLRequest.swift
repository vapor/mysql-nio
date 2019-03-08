extension MySQLProtocol {
    /// Protocol::SSLRequest:
    ///
    /// SSL Connection Request Packet. It is like Handshake Response Packet but is truncated right before username field.
    /// If server supports CLIENT_SSL capability, client can send this packet to request a secure SSL connection.
    /// The CLIENT_SSL capability flag must be set inside the SSL Connection Request Packet.
    ///
    /// https://dev.mysql.com/doc/internals/en/connection-phase-packets.html#packet-Protocol::SSLRequest
    public struct SSLRequest: MySQLPacketEncodable {
        /// capability_flags (4)
        /// capability flags of the client as defined in Protocol::CapabilityFlags
        /// CLIENT_SSL always set
        public var capabilities: CapabilityFlags
        
        /// max_packet_size (4)
        /// max size of a command packet that the client wants to send to the server
        public var maxPacketSize: UInt32
        
        /// character_set (1)
        /// connection's default character set as defined in Protocol::CharacterSet.
        public var characterSet: CharacterSet
        
        public init(
            capabilities: CapabilityFlags,
            maxPacketSize: UInt32,
            characterSet: CharacterSet
        ) {
            assert(capabilities.contains(.CLIENT_SSL), "SSLRequest packet must have CLIENT_SSL capability.")
            self.capabilities = capabilities
            self.maxPacketSize = maxPacketSize
            self.characterSet = characterSet
        }
        
        /// `MySQLPacketEncodable` conformance.
        public func encode(to packet: inout MySQLPacket, capabilities: MySQLProtocol.CapabilityFlags) throws {
            packet.payload.writeInteger(self.capabilities.general, endianness: .little, as: UInt32.self)
            packet.payload.writeInteger(self.maxPacketSize, endianness: .little)
            packet.payload.writeInteger(self.characterSet.rawValue, endianness: .little)
            /// string[23]     reserved (all [0])
            packet.payload.writeBytes([
                0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                0x00, 0x00, 0x00
            ])
        }
    }
}
