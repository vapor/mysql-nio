public struct MySQLCommandState {
    static var noResponse: MySQLCommandState {
        return .init()
    }
    
    static var done: MySQLCommandState {
        return .init(done: true)
    }
    
    static func response(_ packets: [MySQLPacket]) -> MySQLCommandState {
        return .init(response: packets)
    }
    
    let response: [MySQLPacket]
    let done: Bool
    let resetSequence: Bool
    var error: Error?
    
    public init(
        response: [MySQLPacket] = [],
        done: Bool = false,
        resetSequence: Bool = false,
        error: Error? = nil
    ) {
        self.response = response
        self.done = done
        self.resetSequence = resetSequence
        self.error = error
    }
}

public protocol MySQLCommand {
    func handle(packet: inout MySQLPacket, capabilities: MySQLProtocol.CapabilityFlags) throws -> MySQLCommandState
    func activate(capabilities: MySQLProtocol.CapabilityFlags) throws -> MySQLCommandState
}
