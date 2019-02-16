extension MySQLPacket {
    public mutating func handshake() throws -> Handshake {
        return try .init(payload: &self.payload)
    }
    
    /// Protocol::Handshake
    ///
    /// When the client connects to the server the server sends a handshake packet to the client.
    /// Depending on the server version and configuration options different variants of the initial packet are sent.
    ///
    /// https://dev.mysql.com/doc/internals/en/connection-phase-packets.html#packet-Protocol::Handshake
    public struct Handshake {
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
        public var capabilities: MySQLCapabilityFlags
        
        /// character_set (1) -- default server character-set, only the lower 8-bits Protocol::CharacterSet (optional)
        public var characterSet: MySQLCharacterSet?
        
        /// status_flags (2) -- Protocol::StatusFlags (optional)
        public var statusFlags: MySQLStatusFlags?
        
        /// auth_plugin_name (string.NUL) -- name of the auth_method that the auth_plugin_data belongs to
        public var authPluginName: String?
        
        /// Parses a `MySQLHandshakeV10` from the `ByteBuffer`.
        init(payload: inout ByteBuffer) throws {
            guard let protocolVersion = payload.readInteger(endianness: .little, as: UInt8.self) else {
                throw Error.missingProtocolVersion
            }
            self.protocolVersion = protocolVersion
            guard protocolVersion == 10 else {
                throw Error.invalidProtocolVersion(protocolVersion)
            }
            
            guard let serverVersion = payload.readNullTerminatedString() else {
                throw Error.missingServerVersion
            }
            self.serverVersion = serverVersion
            
            guard let connectionID = payload.readInteger(endianness: .little, as: UInt32.self) else {
                throw Error.missingConnectionID
            }
            self.connectionID = connectionID
            
            guard let authPluginDataPart1 = payload.readSlice(length: 8) else {
                throw Error.missingAuthPluginData
            }
            guard let filler1 = payload.readInteger(as: UInt8.self) else {
                throw Error.missingFiller
            }
            // filler_1 (1) -- 0x00
            assert(filler1 == 0x00)
            
            // capability_flag_1 (2) -- lower 2 bytes of the Protocol::CapabilityFlags (optional)
            guard let capabilityFlag1 = payload.readInteger(endianness: .little, as: UInt16.self) else {
                throw Error.missingCapabilityFlag1
            }
            
            if payload.readableBytes > 0 {
                guard let characterSetByte = payload.readInteger(endianness: .little, as: UInt8.self) else {
                    throw Error.missingCharacterSet
                }
                self.characterSet = .init(byte: characterSetByte)
                guard let statusFlags = payload.readInteger(endianness: .little, as: UInt16.self) else {
                    throw Error.missingStatusFlags
                }
                self.statusFlags = .init(rawValue: statusFlags)
                
                // capability_flags_2 (2) -- upper 2 bytes of the Protocol::CapabilityFlags
                guard let upperCapabilities = payload.readInteger(endianness: .little, as: UInt16.self) else {
                    throw Error.missingUpperCapabilities
                }
                self.capabilities = MySQLCapabilityFlags(upper: upperCapabilities, lower: capabilityFlag1)
                
                guard let authPluginDataLength = payload.readInteger(endianness: .little, as: UInt8.self) else {
                    throw Error.missingAuthPluginDataLength
                }
                if !self.capabilities.contains(.CLIENT_PLUGIN_AUTH) {
                    assert(authPluginDataLength == 0x00, "invalid auth plugin data filler: \(authPluginDataLength)")
                }
                
                /// string[6]     reserved (all [00])
                guard let reserved1 = payload.readSlice(length: 6) else {
                    throw Error.missingReserved
                }
                assert(reserved1.isZeroes, "invalid reserve 1 \(reserved1)")
                
                if capabilities.contains(.CLIENT_LONG_PASSWORD) {
                    /// string[4]     reserved (all [00])
                    guard let reserved2 = payload.readSlice(length: 4) else {
                        throw Error.missingReserved
                    }
                    assert(reserved2.isZeroes, "invalid reserve 2: \(reserved2)")
                } else {
                    /// Capabilities 3rd part. MariaDB specific flags.
                    /// MariaDB Initial Handshake Packet specific flags
                    /// https://mariadb.com/kb/en/library/1-connecting-connecting/
                    guard let mariaDBSpecific = payload.readInteger(endianness: .little, as: UInt32.self) else {
                        throw Error.missingMariaDBCapabilities
                    }
                    self.capabilities.mariaDBSpecific = mariaDBSpecific
                }
                
                if capabilities.contains(.CLIENT_SECURE_CONNECTION) {
                    let authPluginDataPart2Length: Int
                    if capabilities.contains(.CLIENT_PLUGIN_AUTH) {
                        authPluginDataPart2Length = numericCast(max(13, authPluginDataLength - 8))
                    } else {
                        authPluginDataPart2Length = 12
                    }
                    guard var authPluginDataPart2 = payload.readSlice(length: authPluginDataPart2Length) else {
                        throw Error.missingAuthPluginData
                    }
                    var authPluginData = authPluginDataPart1
                    authPluginData.writeBuffer(&authPluginDataPart2)
                    self.authPluginData = authPluginData
                    if !self.capabilities.contains(.CLIENT_PLUGIN_AUTH) {
                        guard let filler = payload.readInteger(endianness: .little, as: UInt8.self) else {
                            throw Error.missingFiller
                        }
                        assert(filler == 0x00)
                    }
                } else {
                    self.authPluginData = authPluginDataPart1
                }
                
                if capabilities.contains(.CLIENT_PLUGIN_AUTH) {
                    guard let authPluginName = payload.readNullTerminatedString() else {
                        throw Error.missingAuthPluginName
                    }
                    self.authPluginName = authPluginName
                }
            } else {
                self.capabilities = .init(lower: capabilityFlag1)
                self.authPluginData = authPluginDataPart1
            }
        }
    }
}
