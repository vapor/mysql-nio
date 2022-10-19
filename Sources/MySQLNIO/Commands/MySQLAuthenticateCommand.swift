import Logging

internal final class MySQLAuthenticateCommand: MySQLCommand {
    enum State: Equatable {
        case respondingToInitialHandshake(MySQLProtocol.HandshakeV10, desiredCharacterSet: MySQLProtocol.CharacterSet, commandPacketSizeLimit: UInt32)
        case awaitingAuthResult(activePluginName: String)
    }

    let logger: Logger
    let configuration: MySQLConnection.Configuration
    var state: State
    var activeAuthPluginResponder: MySQLAuthPluginResponder?
    
    init(
        logger: Logger,
        configuration: MySQLConnection.Configuration,
        desiredCharacterSet: MySQLProtocol.CharacterSet,
        commandPacketSizeLimit: UInt32,
        serverHandshake: MySQLProtocol.HandshakeV10
    ) {
        self.logger = logger
        self.configuration = configuration
        self.state = .respondingToInitialHandshake(serverHandshake, desiredCharacterSet: desiredCharacterSet, commandPacketSizeLimit: commandPacketSizeLimit)
    }
    
    func handle(packet: inout MySQLPacket, capabilities: MySQLProtocol.CapabilityFlags) throws -> MySQLCommandAction {
        guard !packet.isError else {
            let errPacket = try packet.decode(MySQLProtocol.ERR_Packet.self, capabilities: [])
            self.logger.trace("MySQL server opened with error \(errPacket.asServerError?.errorMessage ?? "<invalid data>")")
            throw MySQLError.server(.synthesize(from: errPacket))
        }
    }
    
    func activate(capabilities: MySQLProtocol.CapabilityFlags) throws -> MySQLCommandAction {
        switch self.state {
        case .respondingToInitialHandshake(let serverHandshake, let desiredCharacterSet, let commandPacketSizeLimit):
            guard let pluginName = serverHandshake.authPluginName,
                  let pluginResponder = MySQLAuthPluginResponderRegistry.responder(for: pluginName)
            else {
                throw MySQLError.unsupportedAuthPlugin(name: serverHandshake.authPluginName ?? "<none>")
            }
            self.activeAuthPluginResponder = pluginResponder
            self.state = .awaitingAuthResult(activePluginName: pluginName)
            
            let authReplyData = try self.activeAuthPluginResponder.handle(
                pluginName: pluginName,
                configuration: self.configuration,
                isSecureConnection: capabilities.contains(.CLIENT_SSL),
                data: Array(serverHandshake.authPluginData.readableBytesView)
            )
            
            let handshakeReply = MySQLProtocol.HandshakeResponse41(
                capabilities: capabilities,
                maxPacketSize: commandPacketSizeLimit,
                characterSet: desiredCharacterSet,
                username: self.configuration.authentication.username,
                authResponse: .init(bytes: authReplyData ?? []),
                database: self.configuration.authentication.database ?? "",
                authPluginName: pluginName,
                connectionAttributes: MySQLProtocol.ConnectionAttributeName.defaultAttributeValues()
            )
            
            return .init(sendResponse: [.encode(handshakeReply, capabilities: capabilities)])
        default:
            self.logger.debug("Packet sequencing error - authentication command reactivated after initial handshake reply sent")
            throw MySQLError.protocolError
        }
    }
}
