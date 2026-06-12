import NIOCore
import OrderedCollections

struct HandshakeResponsePacket {
    let clientCapabilities: MySQLCapabilities
    let maxPacketSize: UInt32
    let clientDefaultCharacterSetAndCollation: MySQLCollation
    let username: String
    let authResponse: ByteBuffer
    let defaultDatabaseName: String?
    let authenticationPluginName: String?
    let connectionAttributes: OrderedDictionary<String, String>?
    let zstdCompressionLevel: UInt8?

    func write(to packet: inout ByteBuffer, capabilities: MySQLCapabilities, password: Bool) {
        packet.writeInteger(UInt32(self.clientCapabilities.rawValue & 0xFFFF_FFFF), endianness: .little)
        packet.writeInteger(self.maxPacketSize, endianness: .little)
        packet.writeInteger(self.clientDefaultCharacterSetAndCollation.idForHandshake)
        packet.writeBytes([UInt8](repeating: 0, count: 19))  // reserved.
        if !capabilities.contains(.clientMySQL) {
            packet.writeInteger(UInt32(self.clientCapabilities.rawValue >> 32), endianness: .little)
        } else {
            packet.writeBytes([UInt8](repeating: 0, count: 4))  // reserved.
        }
        packet.writeNullTerminatedString(self.username)
        if password {
            if capabilities.contains(.pluginAuthLenencClientData) {
                packet.writeLengthPrefixedBuffer(self.authResponse, strategy: .mySQL)
            } else if capabilities.contains(.secureConnection) {
                try! packet.writeLengthPrefixed(as: UInt8.self) { $0.writeImmutableBuffer(self.authResponse) }
            }
        } else {
            packet.writeNullTerminatedString("")
        }
        if let defaultDatabaseName = self.defaultDatabaseName, capabilities.contains(.connectWithDB) {
            packet.writeNullTerminatedString(defaultDatabaseName)
        }
        if let authenticationPluginName = self.authenticationPluginName, capabilities.contains(.pluginAuth) {
            packet.writeNullTerminatedString(authenticationPluginName)
        }
        if let connectionAttributes = self.connectionAttributes, capabilities.contains(.connectAttrs) {
            var attributesData = ByteBuffer()
            for (key, value) in connectionAttributes {
                attributesData.writeLengthPrefixedString(key, strategy: .mySQL)
                attributesData.writeLengthPrefixedString(value, strategy: .mySQL)
            }
            packet.writeLengthPrefixedBytes(attributesData.readableBytesView, strategy: .mySQL)
        }
        if let zstdCompressionLevel = self.zstdCompressionLevel, capabilities.contains(.clientZstdCompressionAlgorithm) {
            packet.writeInteger(zstdCompressionLevel)
        }
    }

    init(
        clientCapabilities: MySQLCapabilities,
        maxPacketSize: UInt32,
        clientDefaultCharacterSetAndCollation: MySQLCollation,
        username: String,
        authResponse: ByteBuffer,
        defaultDatabaseName: String?,
        authenticationPluginName: String?,
        connectionAttributes: OrderedDictionary<String, String>?,
        zstdCompressionLevel: UInt8?
    ) {
        self.clientCapabilities = clientCapabilities
        self.maxPacketSize = maxPacketSize
        self.clientDefaultCharacterSetAndCollation = clientDefaultCharacterSetAndCollation
        self.username = username
        self.authResponse = authResponse
        self.defaultDatabaseName = defaultDatabaseName
        self.authenticationPluginName = authenticationPluginName
        self.connectionAttributes = connectionAttributes
        self.zstdCompressionLevel = zstdCompressionLevel
    }

    package init?(from packet: inout ByteBuffer, serverCapabilities: MySQLCapabilities, password: Bool) {
        guard let clientCapabilities = packet.readInteger(endianness: .little, as: UInt32.self) else { return nil }
        guard let maxPacketSize = packet.readInteger(endianness: .little, as: UInt32.self) else { return nil }
        guard let clientDefaultCharacterSetAndCollation = packet.readInteger(as: UInt8.self) else { return nil }
        packet.moveReaderIndex(forwardBy: 19)  // reserved.
        let extendedClientCapabilities: UInt32?
        if !serverCapabilities.contains(.clientMySQL) {
            guard let capabilities = packet.readInteger(endianness: .little, as: UInt32.self) else { return nil }
            extendedClientCapabilities = capabilities
        } else {
            extendedClientCapabilities = nil
            packet.moveReaderIndex(forwardBy: 4)  // reserved.
        }
        guard let username = packet.readNullTerminatedString() else { return nil }
        let authResponse: ByteBuffer
        if password {
            if serverCapabilities.contains(.pluginAuthLenencClientData) {
                guard let response = packet.readLengthPrefixedSlice(strategy: .mySQL) else { return nil }
                authResponse = response
            } else if serverCapabilities.contains(.secureConnection) {
                guard let responseLength = packet.readInteger(as: UInt8.self) else { return nil }
                guard let response = packet.readSlice(length: Int(responseLength)) else { return nil }
                authResponse = response
            } else {
                guard let response = packet.readNullTerminatedString() else { return nil }
                authResponse = ByteBuffer(string: response)
            }
        } else {
            authResponse = ByteBuffer()
        }
        let defaultDatabaseName: String? =
            if serverCapabilities.contains(.connectWithDB) {
                packet.readNullTerminatedString()
            } else {
                nil
            }
        let authenticationPluginName: String? =
            if serverCapabilities.contains(.pluginAuth) {
                packet.readNullTerminatedString()
            } else {
                nil
            }
        let connectionAttributes: OrderedDictionary<String, String>?
        if serverCapabilities.contains(.connectAttrs) {
            guard var attributesData = packet.readLengthPrefixedSlice(strategy: .mySQL) else { return nil }
            var attributes: OrderedDictionary<String, String> = [:]
            while attributesData.readableBytes > 0 {
                guard let key = attributesData.readLengthPrefixedString(strategy: .mySQL) else { return nil }
                guard let value = attributesData.readLengthPrefixedString(strategy: .mySQL) else { return nil }
                attributes[key] = value
            }
            connectionAttributes = attributes
        } else {
            connectionAttributes = nil
        }
        let zstdCompressionLevel: UInt8? =
            if serverCapabilities.contains(.clientZstdCompressionAlgorithm) {
                packet.readInteger(as: UInt8.self)
            } else {
                nil
            }
        self.clientCapabilities = MySQLCapabilities(rawValue: UInt64(extendedClientCapabilities ?? 0) << 32 | UInt64(clientCapabilities))
        self.maxPacketSize = maxPacketSize
        self.clientDefaultCharacterSetAndCollation = .lookup(byId: UInt16(clientDefaultCharacterSetAndCollation))
        self.username = username
        self.authResponse = authResponse
        self.defaultDatabaseName = defaultDatabaseName
        self.authenticationPluginName = authenticationPluginName
        self.connectionAttributes = connectionAttributes
        self.zstdCompressionLevel = zstdCompressionLevel
    }
}
