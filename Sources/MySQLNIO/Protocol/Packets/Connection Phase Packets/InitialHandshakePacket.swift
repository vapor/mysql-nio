import NIOCore

/// Initial handshake packet for protocol version 10.
@usableFromInline
struct InitialHandshakePacket {
    let protocolVersion: UInt8
    let serverVersion: String
    let connectionID: UInt32
    let serverCapabilities: MySQLCapabilities
    let serverDefaultCollation: UInt8
    let statusFlags: ServerStatusFlags
    let pluginDataLength: UInt8?
    let authenticationPluginData: ByteBuffer
    let authenticationPluginName: String?

    init?(from packet: inout ByteBuffer) {
        guard let protocolVersion = packet.readInteger(as: UInt8.self) else { return nil }
        guard let serverVersion = packet.readNullTerminatedString() else { return nil }
        guard let connectionID = packet.readInteger(endianness: .little, as: UInt32.self) else { return nil }
        guard let authenticationPluginDataPart1 = packet.readSlice(length: 8) else { return nil }
        packet.moveReaderIndex(forwardBy: 1)  // reserved byte.
        guard let serverCapabilitiesPart1 = packet.readInteger(endianness: .little, as: UInt16.self) else { return nil }
        guard let serverDefaultCollation = packet.readInteger(as: UInt8.self) else { return nil }
        guard let statusFlagsRawValue = packet.readInteger(endianness: .little, as: UInt16.self) else { return nil }
        let statusFlags = ServerStatusFlags(rawValue: statusFlagsRawValue)
        guard let serverCapabilitiesPart2 = packet.readInteger(endianness: .little, as: UInt16.self) else { return nil }
        var serverCapabilities = MySQLCapabilities(rawValue: (UInt64(serverCapabilitiesPart2) << 16) | UInt64(serverCapabilitiesPart1))
        let pluginDataLength: UInt8?
        if serverCapabilities.contains(.pluginAuth) {
            guard let length = packet.readInteger(as: UInt8.self) else { return nil }
            pluginDataLength = length
        } else {
            guard let filler = packet.readInteger(as: UInt8.self), filler == 0 else { return nil }
            pluginDataLength = nil
        }
        packet.moveReaderIndex(forwardBy: 6)  // filler.
        if serverCapabilities.contains(.clientMySQL) {
            packet.moveReaderIndex(forwardBy: 4)  // filler.
        } else {
            guard let serverCapabilitiesPart3 = packet.readInteger(endianness: .little, as: UInt32.self) else { return nil }
            serverCapabilities.formUnion(MySQLCapabilities(rawValue: UInt64(serverCapabilitiesPart3) << 32))
        }
        let authenticationPluginDataPart2: ByteBuffer?
        if serverCapabilities.contains(.secureConnection) {
            authenticationPluginDataPart2 = packet.readSlice(length: max(12, (pluginDataLength.map { Int($0) } ?? 0) - 9))
            packet.moveReaderIndex(forwardBy: 1)  // reserved byte.
        } else {
            authenticationPluginDataPart2 = nil
        }
        var authenticationPluginData = authenticationPluginDataPart1
        if let authenticationPluginDataPart2 {
            authenticationPluginData.writeImmutableBuffer(authenticationPluginDataPart2)
        }
        let authenticationPluginName: String?
        if serverCapabilities.contains(.pluginAuth) {
            guard let authPluginName = packet.readNullTerminatedString() else { return nil }
            authenticationPluginName = authPluginName
        } else {
            authenticationPluginName = nil
        }
        self.protocolVersion = protocolVersion
        self.serverVersion = serverVersion
        self.connectionID = connectionID
        self.serverCapabilities = serverCapabilities
        self.serverDefaultCollation = serverDefaultCollation
        self.statusFlags = statusFlags
        self.pluginDataLength = pluginDataLength
        self.authenticationPluginData = authenticationPluginData
        self.authenticationPluginName = authenticationPluginName
    }

    package init(
        protocolVersion: UInt8,
        serverVersion: String,
        connectionID: UInt32,
        serverCapabilities: MySQLCapabilities,
        serverDefaultCollation: UInt8,
        statusFlags: ServerStatusFlags,
        pluginDataLength: UInt8?,
        authenticationPluginData: ByteBuffer,
        authenticationPluginName: String?
    ) {
        self.protocolVersion = protocolVersion
        self.serverVersion = serverVersion
        self.connectionID = connectionID
        self.serverCapabilities = serverCapabilities
        self.serverDefaultCollation = serverDefaultCollation
        self.statusFlags = statusFlags
        self.pluginDataLength = pluginDataLength
        self.authenticationPluginData = authenticationPluginData
        self.authenticationPluginName = authenticationPluginName
    }

    package func write(to packet: inout ByteBuffer) {
        packet.writeInteger(self.protocolVersion)
        packet.writeNullTerminatedString(self.serverVersion)
        packet.writeInteger(self.connectionID, endianness: .little)

        var authPluginData = self.authenticationPluginData
        let authPluginDataPart1Length = min(8, authPluginData.readableBytes)
        if authPluginDataPart1Length > 0 {
            packet.writeImmutableBuffer(authPluginData.readSlice(length: authPluginDataPart1Length)!)
        }
        if authPluginDataPart1Length < 8 {
            packet.writeBytes(Array(repeating: 0, count: 8 - authPluginDataPart1Length))
        }

        packet.writeInteger(0, as: UInt8.self)  // reserved byte.
        let serverCapabilitiesPart1 = UInt16(self.serverCapabilities.rawValue & 0xFFFF)
        packet.writeInteger(serverCapabilitiesPart1, endianness: .little)
        packet.writeInteger(self.serverDefaultCollation, as: UInt8.self)
        packet.writeInteger(self.statusFlags.rawValue, endianness: .little)
        let serverCapabilitiesPart2 = UInt16((self.serverCapabilities.rawValue >> 16) & 0xFFFF)
        packet.writeInteger(serverCapabilitiesPart2, endianness: .little)
        if self.serverCapabilities.contains(.pluginAuth) {
            packet.writeInteger(UInt8(self.authenticationPluginData.readableBytes + 1), as: UInt8.self)
        } else {
            packet.writeInteger(0, as: UInt8.self)  // filler byte.
        }
        packet.writeBytes([0, 0, 0, 0, 0, 0])  // filler.
        if self.serverCapabilities.contains(.clientMySQL) {
            packet.writeBytes([0, 0, 0, 0])  // filler.
        } else {
            let serverCapabilitiesPart3 = UInt32((self.serverCapabilities.rawValue >> 32) & 0xFFFF_FFFF)
            packet.writeInteger(serverCapabilitiesPart3, endianness: .little)
        }
        if self.serverCapabilities.contains(.secureConnection) {
            // The plugin data length is at least the length of part 1 + the reserved byte.
            let pluginDataLength = max(self.authenticationPluginData.readableBytes + 1, self.pluginDataLength.map { Int($0) } ?? 0)

            let authPluginDataPart2Length = max(12, pluginDataLength - 9)
            let authPluginDataPart2BytesToWrite = min(authPluginDataPart2Length, authPluginData.readableBytes)
            if authPluginDataPart2BytesToWrite > 0 {
                packet.writeImmutableBuffer(authPluginData.readSlice(length: authPluginDataPart2BytesToWrite)!)
            }
            if authPluginDataPart2Length > authPluginDataPart2BytesToWrite {
                packet.writeBytes(Array(repeating: 0, count: authPluginDataPart2Length - authPluginDataPart2BytesToWrite))
            }

            packet.writeInteger(0, as: UInt8.self)  // reserved byte.
        }
        if self.serverCapabilities.contains(.pluginAuth), let authenticationPluginName {
            packet.writeNullTerminatedString(authenticationPluginName)
        }
    }
}
