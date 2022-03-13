import NIOCore

extension MySQLProtocol {
    /// Protocol::Handshake
    ///
    /// When the client connects to the server the server sends a handshake packet to the client.
    /// Depending on the server version and configuration options different variants of the initial packet are sent.
    ///
    /// https://dev.mysql.com/doc/internals/en/connection-phase-packets.html#packet-Protocol::Handshake
    /// https://mariadb.com/kb/en/connection/
    public struct HandshakeV10: MySQLPacketCodable {
        public enum Error: Swift.Error {
            case missingProtocolVersion
            case invalidProtocolVersion(UInt8)
            case missingServerVersion
            case missingConnectionID
            case missingAuthPluginData
            case missingFiller
            case missingCapabilityFlag1
            case missingCharacterSet
            case missingStatusFlags
            case missingUpperCapabilities
            case missingAuthPluginDataLength
            case missingReserved
            case missingMariaDBCapabilities
            case missingAuthPluginName
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
        
        /// `character_set` (1) -- default server character-set, only the lower 8-bits `Protocol::CharacterSet` (optional)
        public var characterSet: CharacterSet?
        
        /// `status_flags` (2) -- `Protocol::StatusFlags` (optional)
        public var statusFlags: StatusFlags?
        
        /// `auth_plugin_name` (`string.NUL`) -- name of the `auth_method` that the `auth_plugin_data` belongs to
        public var authPluginName: String?
        
        /// `MySQLPacketEncodable` conformance.
        public func encode(to packet: inout MySQLPacket, capabilities: MySQLProtocol.CapabilityFlags) throws {
            guard self.authPluginData.readableBytes <= UInt8.max else {
                throw Error.missingAuthPluginDataLength
            }
            
            packet.payload.writeInteger(self.protocolVersion, endianness: .little, as: UInt8.self)
            packet.payload.writeNullTerminatedString(self.serverVersion)
            packet.payload.writeInteger(self.connectionID, endianness: .little, as: UInt32.self)
            packet.payload.writeBytes(([UInt8](self.authPluginData.readableBytesView.prefix(8))+[0,0,0,0,0,0,0,0]).prefix(8))
            packet.payload.writeInteger(0, as: UInt8.self)
            packet.payload.writeInteger(self.capabilities.rawValue & 0x00ffff, endianness: .little, as: UInt16.self)
            if self.characterSet != nil || self.statusFlags != nil || self.capabilities.rawValue > UInt16.max ||
               self.authPluginName != nil || self.authPluginData.readableBytes > 8
            {
                guard let characterSet = self.characterSet else { throw Error.missingCharacterSet }
                guard let statusFlags = self.statusFlags else { throw Error.missingStatusFlags }
                
                packet.payload.writeInteger(characterSet, as: CharacterSet.self)
                packet.payload.writeInteger(statusFlags, endianness: .little, as: StatusFlags.self)
                packet.payload.writeInteger((self.capabilities.rawValue >> 16) & 0x00ffff, endianness: .little, as: UInt16.self)
                packet.payload.writeInteger(self.capabilities.contains(.CLIENT_PLUGIN_AUTH) ? self.authPluginData.readableBytes : 0, as: UInt8.self)
                packet.payload.writeBytes([UInt8](repeating: 0, count: self.capabilities.contains(.CLIENT_LONG_PASSWORD) ? 10 : 6))
                if !self.capabilities.contains(.CLIENT_LONG_PASSWORD) {
                    packet.payload.writeInteger(self.capabilities.rawValue >> 32, endianness: .little, as: UInt32.self)
                }
                if self.capabilities.contains(.CLIENT_SECURE_CONNECTION) {
                    packet.payload.writeBytes(self.authPluginData.readableBytesView.dropFirst(8))
                    if self.authPluginData.readableBytes < 20 {
                        packet.payload.writeBytes([UInt8](repeating: 0, count: 12 - (self.authPluginData.readableBytes - 8)))
                    }
                    packet.payload.writeInteger(0, as: UInt8.self)
                }
                if self.capabilities.contains(.CLIENT_PLUGIN_AUTH) {
                    guard let authPluginName = self.authPluginName else { throw Error.missingAuthPluginName }
                    packet.payload.writeNullTerminatedString(authPluginName)
                }
            }
        }
        
        /// `MySQLPacketDecodable` conformance.
        public static func decode(from packet: inout MySQLPacket, capabilities _: MySQLProtocol.CapabilityFlags) throws -> HandshakeV10 {
            guard let protocolVersion = packet.payload.readInteger(endianness: .little, as: UInt8.self) else {
                throw Error.missingProtocolVersion
            }
            guard protocolVersion == 10 else {
                throw Error.invalidProtocolVersion(protocolVersion)
            }
            guard let serverVersion = packet.payload.readNullTerminatedString() else {
                throw Error.missingServerVersion
            }
            guard let connectionID = packet.payload.readInteger(endianness: .little, as: UInt32.self) else {
                throw Error.missingConnectionID
            }
            guard let authPluginDataPart1 = packet.payload.readSlice(length: 8) else {
                throw Error.missingAuthPluginData
            }
            guard let filler1 = packet.payload.readInteger(as: UInt8.self), filler1 == 0x00 else {
                throw Error.missingFiller
            }
            // capability_flag_1 (2) -- lower 2 bytes of the Protocol::CapabilityFlags (optional)
            guard let capabilitiesLower = packet.payload.readInteger(endianness: .little, as: UInt16.self) else {
                throw Error.missingCapabilityFlag1
            }
            
            let characterSet: CharacterSet?
            let statusFlags: StatusFlags?
            var capabilities: CapabilityFlags
            var authPluginData: ByteBuffer
            let authPluginName: String?
            if packet.payload.readableBytes > 0 {
                guard let set = packet.payload.readInteger(endianness: .little, as: CharacterSet.self) else {
                    throw Error.missingCharacterSet
                }
                characterSet = set
                guard let status = packet.payload.readInteger(endianness: .little, as: StatusFlags.self) else {
                    throw Error.missingStatusFlags
                }
                statusFlags = status
                // capability_flags_2 (2) -- upper 2 bytes of the Protocol::CapabilityFlags
                guard let capabilitiesUpper = packet.payload.readInteger(endianness: .little, as: UInt16.self) else {
                    throw Error.missingUpperCapabilities
                }
                capabilities = .init(upper: capabilitiesUpper, lower: capabilitiesLower)
                guard let authPluginDataLength = packet.payload.readInteger(endianness: .little, as: UInt8.self) else {
                    throw Error.missingAuthPluginDataLength
                }
                if !capabilities.contains(.CLIENT_PLUGIN_AUTH) {
                    guard authPluginDataLength == 0x00 else {
                        throw Error.missingAuthPluginDataLength
                    }
                }
                /// string[6]     reserved (all [00])
                guard let reserved1 = packet.payload.readSlice(length: 6), reserved1.readableBytesView.allSatisfy({ $0 == 0 }) else {
                    throw Error.missingReserved
                }
                if capabilities.contains(.CLIENT_LONG_PASSWORD) {
                    /// string[4]     reserved (all [00])
                    guard let reserved2 = packet.payload.readSlice(length: 4), reserved2.readableBytesView.allSatisfy({ $0 == 0 }) else {
                        throw Error.missingReserved
                    }
                } else {
                    /// Capabilities 3rd part. MariaDB specific flags.
                    /// MariaDB Initial Handshake Packet specific flags
                    /// https://mariadb.com/kb/en/library/1-connecting-connecting/
                    guard let mariaDBSpecific = packet.payload.readInteger(endianness: .little, as: UInt32.self) else {
                        throw Error.missingMariaDBCapabilities
                    }
                    capabilities.rawValue |= UInt64(mariaDBSpecific) << 32
                }
                
                if capabilities.contains(.CLIENT_SECURE_CONNECTION) {
                    let authPluginDataPart2Length: Int
                    if capabilities.contains(.CLIENT_PLUGIN_AUTH) {
                        authPluginDataPart2Length = numericCast(max(13, authPluginDataLength - 8))
                    } else {
                        authPluginDataPart2Length = 12
                    }
                    guard var authPluginDataPart2 = packet.payload.readSlice(length: authPluginDataPart2Length) else {
                        throw Error.missingAuthPluginData
                    }
                    authPluginData = authPluginDataPart1
                    authPluginData.writeBuffer(&authPluginDataPart2)
                    if !capabilities.contains(.CLIENT_PLUGIN_AUTH) {
                        guard let filler = packet.payload.readInteger(endianness: .little, as: UInt8.self), filler == 0x00 else {
                            throw Error.missingFiller
                        }
                    }
                } else {
                    authPluginData = authPluginDataPart1
                }
                
                if capabilities.contains(.CLIENT_PLUGIN_AUTH) {
                    guard let name = packet.payload.readNullTerminatedString() else {
                        throw Error.missingAuthPluginName
                    }
                    authPluginName = name
                } else {
                    authPluginName = nil
                }
            } else {
                characterSet = nil
                statusFlags = nil
                capabilities = .init(lower: capabilitiesLower)
                authPluginData = authPluginDataPart1
                authPluginName = nil
            }
            
            return .init(
                protocolVersion: protocolVersion,
                serverVersion: serverVersion,
                connectionID: connectionID,
                authPluginData: authPluginData,
                capabilities: capabilities,
                characterSet: characterSet,
                statusFlags: statusFlags,
                authPluginName: authPluginName
            )
        }
    }
}
