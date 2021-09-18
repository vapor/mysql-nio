extension MySQLProtocol {
    /// Protocol::Handshake
    ///
    /// When the client connects to the server the server sends a handshake packet to the client.
    /// Depending on the server version and configuration options different variants of the initial packet are sent.
    ///
    /// https://dev.mysql.com/doc/internals/en/connection-phase-packets.html#packet-Protocol::Handshake
    public struct HandshakeV10: MySQLPacketDecodable {
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
        
        /// protocol_version (1) -- 0x0a protocol_version
        public var protocolVersion: UInt8
        
        /// server_version (string.NUL) -- human-readable server version
        public var serverVersion: String
        
        /// connection_id (4) -- connection id
        public var connectionID: UInt32
        
        /// auth_plugin_data_part_1 (string.fix_len) -- [len=8] first 8 bytes of the auth-plugin data
        public var authPluginData: ByteBuffer
        
        /// The server's capabilities.
        public var capabilities: CapabilityFlags
        
        /// character_set (1) -- default server character-set, only the lower 8-bits Protocol::CharacterSet (optional)
        public var characterSet: CharacterSet?
        
        /// status_flags (2) -- Protocol::StatusFlags (optional)
        public var statusFlags: StatusFlags?
        
        /// auth_plugin_name (string.NUL) -- name of the auth_method that the auth_plugin_data belongs to
        public var authPluginName: String?
        
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
            guard let filler1 = packet.payload.readInteger(as: UInt8.self) else {
                throw Error.missingFiller
            }
            // filler_1 (1) -- 0x00
            assert(filler1 == 0x00)
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
                    assert(authPluginDataLength == 0x00, "invalid auth plugin data filler: \(authPluginDataLength)")
                }
                /// string[6]     reserved (all [00])
                guard let reserved1 = packet.payload.readSlice(length: 6) else {
                    throw Error.missingReserved
                }
                assert(reserved1.readableBytesView.allSatisfy { $0 == 0 }, "invalid reserve 1 \(reserved1)")
                if capabilities.contains(.CLIENT_LONG_PASSWORD) {
                    /// string[4]     reserved (all [00])
                    guard let reserved2 = packet.payload.readSlice(length: 4) else {
                        throw Error.missingReserved
                    }
                    assert(reserved2.readableBytesView.allSatisfy { $0 == 0 }, "invalid reserve 2: \(reserved2)")
                } else {
                    /// Capabilities 3rd part. MariaDB specific flags.
                    /// MariaDB Initial Handshake Packet specific flags
                    /// https://mariadb.com/kb/en/library/1-connecting-connecting/
                    guard let mariaDBSpecific = packet.payload.readInteger(endianness: .little, as: UInt32.self) else {
                        throw Error.missingMariaDBCapabilities
                    }
                    capabilities.mariaDBSpecific = mariaDBSpecific
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
                        guard let filler = packet.payload.readInteger(endianness: .little, as: UInt8.self) else {
                            throw Error.missingFiller
                        }
                        assert(filler == 0x00)
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
