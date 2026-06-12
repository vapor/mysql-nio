import NIOCore

/// If both server and the client support ``MySQLCapability.pluginAuth`` capability,
/// server can send this packet to ask client to use another authentication method.
@usableFromInline
struct AuthenticationSwitchRequest {
    let authenticationPluginName: String
    let authenticationPluginData: ByteBuffer

    init?(from packet: inout ByteBuffer) {
        guard let header = packet.readInteger(as: UInt8.self), header == 0xFE else { return nil }
        guard let authenticationPluginName = packet.readNullTerminatedString() else { return nil }
        // TODO: the authentication plugin data should be 20 bytes long, but servers send 21 bytes with an extra null byte at the end.
        guard let authenticationPluginData = packet.readSlice(length: packet.readableBytes - 1) else { return nil }
        self.authenticationPluginName = authenticationPluginName
        self.authenticationPluginData = authenticationPluginData
    }
}
