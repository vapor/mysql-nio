extension MySQLConnection {
    public func authenticate() -> EventLoopFuture<Void> {
        return self.send(MySQLAuthRequest())
    }
}

final class MySQLAuthRequest: MySQLConnectionRequestDelegate {
    enum State {
        case nascent
        case sha2
        case native(MySQLCapabilityFlags)
    }
    
    var state: State
    
    init() {
        self.state = .nascent
    }

    func initial() -> [MySQLPacket] {
        return []
    }

    func handle(_ packet: inout MySQLPacket) throws -> [MySQLPacket]? {
        switch self.state {
        case .nascent:
            var handshake = try packet.handshake()
            guard handshake.capabilities.contains(.CLIENT_SECURE_CONNECTION) else {
                throw MySQLError.unsupportedServer(message: "Pre-4.1 auth protocol is not supported or safe.")
            }
            guard let authPluginName = handshake.authPluginName else {
                throw MySQLError.unsupportedAuthPlugin(name: "<none>")
            }
            
            var password = ByteBufferAllocator().buffer(capacity: 0)
            password.writeString("vapor_password")
            
            let hash: ByteBuffer
            switch authPluginName {
            case "caching_sha2_password":
                let seed = handshake.authPluginData
                hash = xor(sha256(password), sha256(sha256(sha256(password)), seed))
                self.state = .sha2
            case "mysql_native_password":
                guard let salt = handshake.authPluginData.readSlice(length: 20) else {
                    throw MySQLError.protocolError
                }
                hash = xor(sha1(salt, sha1(sha1(password))), sha1(password))
                self.state = .native(handshake.capabilities)
            default:
                throw MySQLError.unsupportedAuthPlugin(name: authPluginName)
            }
            
            let res = MySQLPacket.HandshakeResponse(
                capabilities: .clientDefault,
                maxPacketSize: 0,
                characterSet: .utf8mb4,
                username: "vapor_username",
                authResponse: hash,
                database: "vapor_database",
                authPluginName: authPluginName
            )
            return [.init(res)]
        case .sha2:
            guard let status = packet.payload.readInteger(endianness: .little, as: UInt8.self) else {
                throw MySQLError.protocolError
            }
            switch status {
            case 0x01:
                guard let name = packet.payload.readInteger(endianness: .little, as: UInt8.self) else {
                    throw MySQLError.protocolError
                }
                switch name {
                case 0x04:
                    throw MySQLError.secureConnectionRequired
                default:
                    throw MySQLError.protocolError
                }
            default:
                throw MySQLError.protocolError
            }
        case .native(let capabilities):
            guard !packet.isError else {
                let error = try packet.err(capabilities: capabilities)
                throw MySQLError.server(error)
            }
            let ok = try packet.ok(capabilities: capabilities)
            print(ok)
            return nil
        }
    }
}
