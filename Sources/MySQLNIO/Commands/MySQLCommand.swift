import NIOSSL

/// Encapsulates the various manipulations of connection state a `MySQLComand` can perform as
/// often as once per incoming packet. Also expressible as a description of how to transform
/// the previous state to achieve the correct current state.
public struct MySQLCommandAction {
    public enum QueuePosition: Equatable {
        case front, next, end
    }
    
    /// If non-empty, all packets in this array are written to the channel before any further action is taken.
    let sendResponse: [MySQLPacket]
    
    /// If set, the connection's packet sequence number is reset to zero.
    let resetSequence: Bool

    /// If set, the connection's capabilities list is replaced with the one given.
    let updateCapabilities: MySQLProtocol.CapabilityFlags?

    /// If set, inserts the given command(s) at the specified positions within the command
    /// queue. The allowed positions are "end" (waits until all previously queued commands
    /// are completed), "next" (becomes active immediately after the current command completes),
    /// or "front" (immediately supplants the current command without removing it). Multiple
    /// added commands are always inserted in the same relative order. Commands are queued
    /// before delivering an `initiateTLS` activation.
    let queueCommands: [(MySQLCommand, QueuePosition)]
    
    /// If set when a TLS connection is not already established, all other requested actions
    /// are completed, followed by the initiation of a TLS handshake using the given context.
    /// No further packets are delivered during TLS bringup. Once the TLS connection is fully
    /// established, the frontmost command's `activate()` method is called, even if it already
    /// has been before. An error occurs if requested once a TLS connection is already
    /// established, or if TLS initiation is requested when `complete` indicates failure.
    let initiateTLS: NIOSSLContext?
    
    /// If set, indicates the command has finished, either successfully or not. In the failure
    /// case, the given error is propagated to any waiters on the command's completion. Returning
    /// failure differs from throwing an error only in that any other actions requested by the
    /// failure state (response packets, sequence reset, etc.) still take effect.
    let complete: Result<Void, Error>?

    /// If all parameters are left at or take their default values, no action is taken and the
    /// next incoming packet is delivered to the same command.
    public init(
        sendResponse: [MySQLPacket] = [],
        resetSequence: Bool = false,
        updateCapabilities: MySQLProtocol.CapabilityFlags? = nil,
        queueCommands: [(MySQLCommand, QueuePosition)] = [],
        initiateTLS: NIOSSLContext? = nil,
        complete: Result<Void, Error>? = nil
    ) {
        self.sendResponse = sendResponse
        self.resetSequence = resetSequence
        self.updateCapabilities = updateCapabilities
        self.queueCommands = queueCommands
        self.initiateTLS = initiateTLS
        self.complete = complete
    }
}

/// A set of isolated state transitions within a MySQL server connection.
public protocol MySQLCommand {
    /// Called when a command reaches the front of the command queue, and also when a TLS
    /// connection is successfully started while the command is at the front of the queue.
    /// The provided capability flags start as `[]` and are updated according to the
    /// direction of the current command. See ``MySQLCommandAction`` for further details.
    func activate(capabilities: MySQLProtocol.CapabilityFlags) throws -> MySQLCommandAction

    /// Called when an incoming packet is received while the command is at the front of the
    /// command queue. The capabilities are the same as those provided to
    /// ``activate(capabilities:)``.
    func handle(packet: inout MySQLPacket, capabilities: MySQLProtocol.CapabilityFlags) throws -> MySQLCommandAction
}
