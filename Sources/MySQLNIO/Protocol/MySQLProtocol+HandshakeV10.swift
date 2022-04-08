import NIOCore

extension MySQLProtocol {
    /// `Protocol::Handshake`
    ///
    /// When the client connects to the server the server sends a handshake packet to the client.
    /// Depending on the server version and configuration options different variants of the initial packet are sent.
    ///
    /// https://dev.mysql.com/doc/internals/en/connection-phase-packets.html#packet-Protocol::Handshake
    /// https://mariadb.com/kb/en/connection/
    public struct HandshakeV10: MySQLPacketCodable {
        public enum Error: Swift.Error {
            case invalidAuthorizationData
        }
        
        /// `protocol_version` (1) -- `0x0a` `protocol_version`
        public var protocolVersion: UInt8
        
        /// `server_version` (`string.NUL`) -- human-readable server version
        public var serverVersion: String
        
        /// `connection_id` (4) -- connection id
        public var connectionID: UInt32
        
        /// `auth_plugin_data_part_1` (`string.fix_len`) -- [len=8] first 8 bytes of the auth-plugin data
        public var authPluginData: ByteBuffer
        
        /// The server's capabilities.
        public var capabilities: CapabilityFlags
        
        /// `character_set` (1) -- default server character-set, only the lower 8-bits `Protocol::CharacterSet`
        public var characterSet: CharacterSet
        
        /// `status_flags` (2) -- `Protocol::StatusFlags`
        public var statusFlags: StatusFlags
        
        /// `auth_plugin_name` (`string.NUL`) -- name of the `auth_method` that the `auth_plugin_data` belongs to
        public var authPluginName: String?
        
        /// `MySQLPacketEncodable` conformance.
        public func encode(to packet: inout MySQLPacket, capabilities: MySQLProtocol.CapabilityFlags) throws {
            guard self.authPluginData.readableBytes <= UInt8.max,
                  (self.authPluginName != nil || !self.capabilities.contains(.CLIENT_PLUGIN_AUTH))
            else {
                throw Error.invalidAuthorizationData
            }
            
            packet.payload.writeInteger(self.protocolVersion, endianness: .little, as: UInt8.self)
            packet.payload.writeNullTerminatedString(self.serverVersion)
            packet.payload.writeInteger(self.connectionID, endianness: .little, as: UInt32.self)
            packet.payload.writeBytes(([UInt8](self.authPluginData.readableBytesView.prefix(8))+[0,0,0,0,0,0,0,0]).prefix(8))
            packet.payload.writeInteger(0, as: UInt8.self)
            packet.payload.writeInteger(self.capabilities.lowerGeneral, endianness: .little, as: UInt16.self)
            packet.payload.writeInteger(self.characterSet, as: CharacterSet.self)
            packet.payload.writeInteger(self.statusFlags, endianness: .little, as: StatusFlags.self)
            packet.payload.writeInteger(self.capabilities.upperGeneral, endianness: .little, as: UInt16.self)
            packet.payload.writeInteger(self.capabilities.contains(.CLIENT_PLUGIN_AUTH) ? self.authPluginData.readableBytes : 0, as: UInt8.self)
            packet.payload.writeRepeatingByte(0, count: self.capabilities.contains(.CLIENT_LONG_PASSWORD) ? 10 : 6)
            if !self.capabilities.contains(.CLIENT_LONG_PASSWORD) {
                packet.payload.writeInteger(self.capabilities.mariaDBSpecific, endianness: .little, as: UInt32.self)
            }
            packet.payload.writeBytes(self.authPluginData.readableBytesView.dropFirst(8))
            if self.authPluginData.readableBytes < 20 {
                packet.payload.writeRepeatingByte(0, count: 12 - (self.authPluginData.readableBytes - 8))
            }
            packet.payload.writeInteger(0, as: UInt8.self)
            if self.capabilities.contains(.CLIENT_PLUGIN_AUTH) {
                packet.payload.writeNullTerminatedString(self.authPluginName!)
            }
        }
        
        /// `MySQLPacketDecodable` conformance.
        public static func decode(from packet: inout MySQLPacket, capabilities: MySQLProtocol.CapabilityFlags) throws -> HandshakeV10 {
            guard try packet.readInteger(endianness: .little, as: UInt8.self) == 10 else { throw MySQLError.unsupportedServer(message: "Unrecognized protocol version") }
            let serverVersion = try packet.readNullTerminatedString()
            let connectionID = try packet.readInteger(endianness: .little, as: UInt32.self)
            let pluginDataPart1 = try packet.readSlice(length: 8)
            try packet.readReservedBytes(length: 1)
            let capabilitiesLower = try packet.readInteger(endianness: .little, as: UInt16.self)
            let characterSet = try packet.readInteger(endianness: .little, as: CharacterSet.self)
            let statusFlags = try packet.readInteger(endianness: .little, as: StatusFlags.self)
            let capabilitiesUpper = try packet.readInteger(endianness: .little, as: UInt16.self)
            let serverCapabilities = MySQLProtocol.CapabilityFlags(upper: capabilitiesUpper, lower: capabilitiesLower)
            let sharedCapabilities = capabilities.intersection(serverCapabilities)
            let pluginDataLength = try packet.readInteger(endianness: .little, as: UInt8.self)
            guard pluginDataLength == 0 || !serverCapabilities.contains(.CLIENT_PLUGIN_AUTH) else { throw MySQLError.protocolError }
            try packet.readReservedBytes(length: 6)
            if !capabilities.contains(.CLIENT_MYSQL) && !serverCapabilities.contains(.CLIENT_MYSQL) {
                serverCapabilities.mariaDBSpecific = try packet.payload.readInteger(endianness: .little, as: UInt32.self)
                sharedCapabilities = capabilities.intersection(serverCapabilities)
            } else {
                try packet.readReservedBytes(length: 4)
            }
            let pluginDataPart2 = try packet.readSlice(length: sharedCapabilities.contains(.CLIENT_PLUGIN_AUTH) ? numericCast(Swift.max(13, pluginDataLength - 8)) : 12)
            var pluginName: String?
            if !sharedCapabilities.contains(.CLIENT_PLUGIN_AUTH) {
                try packet.readReservedBytes(length: 1)
            } else {
                pluginName = try packet.readNullTerminatedString()
            }
            
            return .init(
                protocolVersion: 10,
                serverVersion: serverVersion,
                connectionID: connectionID,
                authPluginData: .init(bytes: Array(pluginDataPart1.readableBytesView) + pluginDataPart2.readableBytesView),
                capabilities: sharedCapabilities,
                characterSet: characterSet,
                statusFlags: statusFlags,
                authPluginName: pluginName
            )
        }
    }
}
