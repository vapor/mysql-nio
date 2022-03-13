extension MySQLProtocol {
    /// `Protocol::SSLRequest`
    ///
    /// SSL Connection Request Packet. It is similar to the Handshake Response Packet, except that it ends immediately
    /// after the reserved bytes. If the server supports the `CLIENT_SSL` capability, a client can send this packet to
    /// request a secure TLS connection. The `CLIENT_SSL` capability flag must be set inside the SSL Connection Request
    /// Packet.
    ///
    /// https://dev.mysql.com/doc/internals/en/connection-phase-packets.html#packet-Protocol::SSLRequest
    struct SSLRequest: MySQLPacketCodable {
        /// `capability_flags (4)`
        /// capability flags of the client as defined in `Protocol::CapabilityFlags`
        /// `CLIENT_SSL` is always set in this packet
        let capabilities: CapabilityFlags
        
        /// `max_packet_size (4)`
        /// max size of a command packet that the client wants to send to the server
        let maxPacketSize: UInt32
        
        /// `character_set (1)`
        /// connection's default character set as defined in `Protocol::CharacterSet`
        let characterSet: CharacterSet
        
        init(
            capabilities: CapabilityFlags,
            maxPacketSize: UInt32,
            characterSet: CharacterSet
        ) {
            assert(capabilities.contains(.CLIENT_SSL), "SSLRequest packet must specify the CLIENT_SSL capability.")
            self.capabilities = capabilities
            self.maxPacketSize = maxPacketSize
            self.characterSet = characterSet
        }
        
        /// `MySQLPacketEncodable` conformance.
        func encode(to packet: inout MySQLPacket, capabilities: MySQLProtocol.CapabilityFlags) throws {
            // Calculate the set of capability flags both reported by the server _and_ selected for this response.
            let sharedCapabilities = self.capabilities.intersection(capabilities)
            assert(sharedCapabilities.contains(.CLIENT_SSL), "SSLRequest packet is not valid if both sides do not specify CLIENT_SSL")

            packet.payload.writeInteger(self.capabilities.general, endianness: .little)
            packet.payload.writeInteger(self.maxPacketSize, endianness: .little)
            packet.payload.writeInteger(self.characterSet.rawValue, endianness: .little)
            packet.payload.writeRepeatingByte(0, count: 19)
            packet.payload.writeInteger(sharedCapabilities.contains(.CLIENT_MYSQL) ? self.capabilities.mariaDBSpecific : 0, endianness: .little, as: UInt32.self)
        }
        
        /// `MySQLPacketDecodable` conformance.
        static func decode(from packet: inout MySQLPacket, capabilities: MySQLProtocol.CapabilityFlags) throws -> SSLRequest {
            guard let clientCapabilities = packet.payload.readInteger(endianness: .little, as: UInt32.self),
                  let maxPacketSize = packet.payload.readInteger(endianness: .little, as: UInt32.self),
                  let rawCharacterSet = packet.payload.readInteger(endianness: .little, as: UInt8.self),
                  packet.payload.readReservedBytes(length: 19),
                  let maybeExtraCapabilities = packet.payload.readInteger(endianness: .little, as: UInt32.self),
                  let effectiveCapabilities = CapabilityFlags(checking: capabilities, general: clientCapabilities, extended: maybeExtraCapabilities),
                  effectiveCapabilities.contains(.CLIENT_SSL)
            else { throw Error.invalidTLSRequest }
            
            return .init(
                capabilities: .init(general: clientCapabilities, extended: maybeExtraCapabilities),
                maxPacketSize: maxPacketSize,
                characterSet: .init(rawValue: rawCharacterSet)
            )
        }

        enum Error: Swift.Error {
            case invalidTLSRequest
        }
    }
}
