import NIOCore

extension MySQLCommandHandlers {
    struct OrderlyQuit: MySQLActiveCommandHandler {
        mutating func handlerActive(context: some MySQLChannelContext) throws {
            context.sendPacket(.init(bytes: [0x01/* COM_QUIT */]))
            context.disconnectNormally()
        }

        mutating func packetReceived(context: some MySQLChannelContext, _ packet: ByteBuffer) throws {
            preconditionFailure("State violation in orderly quit handler (received a packet). Please report a bug.")
        }
        
        mutating func handlerInactive(context: some MySQLChannelContext) throws {}
        
        enum State {}
    }
}
