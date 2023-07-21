import struct Logging.Logger
import NIOCore

/// Provides interfaces for an active state machine to mutate connection data, send packets, and take
/// certain critical actions.
///
/// "Connection data" is any information about the connection which persists across active commands.
/// Capability flags, the current database, and server version information are examples of conection data.
protocol MySQLChannelContext: AnyObject {
    /// The channel's event loop
    var eventLoop: any EventLoop { get }
    
    /// The logger used by the channel
    var logger: Logger { get }
    
    // MARK: Connection data
    
    /// Connection attributes
    var connectionAttributes: [String: String] { get }
    
    /// Server connection ID (aka thread ID, used with `SHOW PROCESSLIST` and `KILL QUERY`)
    var connectionIdentifier: UInt32 { get }
    
    /// Server version string
    var serverVersion: String { get }
    
    /// The set of active capability flags
    var capabilities: MySQLCapabilities { get }
    
    /// Server status flags
    var statusFlags: MySQLServerStatusFlags { get set }
    
    /// Current default "schema" (most often referred to as a "database" in MySQL)
    ///
    /// If `nil`, there is no default schema (or it is not known).
    var currentSchema: String? { get set }
    
    /// Most recently received session tracking status message
    var lastReportedSessionStatus: String? { get set }
    
    /// Most recently reported query metadata (warning count, affected rows, last-insert ID)
    var lastKnownQueryMetadata: MySQLQueryMetadata? { get set }
    
    // MARK: Connection actions
    
    /// Set the initial connection data. This may only be called once per connection.
    func storeInitialConnectionInfo(threadId: UInt32, version: String, negotiatedCapabilities: MySQLCapabilities)
    
    /// Send a packet. The buffer _MUST_ start with four zero bytes, followed by the packet's complete
    /// contents. Failure to follow this rule will cause the packet to be sent in corrupted form.
    func sendPacket(_ packet: ByteBuffer)
    
    /// Insert a new command handler at the front of the queue, preempting any commands already in the queue.
    /// Does _not_ mark the current command as complete, nor is the new handler made active.
    func preemptNextCommand(with handler: any MySQLActiveCommandHandler)
    
    /// Mark the current command as completed. The handler will be marked inactive _only after returning from
    /// this method's caller!_ (In other words, handlers are never invoked reentrantly.)
    ///
    /// If any additional commands are queued, the next queued command's handler will become active
    /// immediately after the current handler is made inactive.
    func markCommandComplete()
    
    /// Trigger an orderly connection shutdown without further communication. This does _NOT_ send a `COM_QUIT`
    /// command; rather, that command invokes this method.
    ///
    /// Do not use this method to report an unrecoverable error.
    func disconnectNormally()
}

extension MySQLChannelContext {
    /// Attempt to decode a buffer as a generic OK (or OK-marked-EOF) packet.
    ///
    /// If the decode succeeds, the appropriate connection data is automatically updated without need for action
    /// by the caller.
    ///
    /// If the decode fails because the packet does not appear to be an OK packet, `nil` is returned and no data
    /// is updated. If the decode detects an OK packet but the packet format is not valid, an error is thrown.
    ///
    /// Do not call this method unless an OK packet is a valid server response in the current state.
    func decodeOKPacketAndUpdateConnection(from buffer: ByteBuffer) throws -> MySQLPacketDescriptions.OKPacket? {
        guard let packet = try MySQLPacketDescriptions.OKPacket(from: buffer, activeCapabilities: self.capabilities) else {
            return nil
        }
        self.statusFlags = packet.statusFlags
        self.currentSchema = packet.newSchema ?? self.currentSchema
        self.lastReportedSessionStatus = packet.statusMessage
        self.lastKnownQueryMetadata = .init(lastAffectedRows: packet.affectedRows, lastInsertId: packet.lastInsertId, lastWarningCount: packet.warningCount)
        return packet
    }
    
    /// Attempt to decode a buffer as a generic ERR packet.
    ///
    /// If the decode fails because the packet does not appear to be an ERR packet, `nil` is returned.
    ///
    /// If the decode fails because the packet is corrupted, a protocol error is thrown.
    func decodeERRPacket(from buffer: ByteBuffer) throws -> MySQLPacketDescriptions.ERRPacket? {
        try .init(from: buffer)
    }
    
    /// Same as ``decodeERRPacket(from:)`` but also throws the decoded error on sucecss.
    func decodeERRPacketAndReport(from buffer: ByteBuffer) throws {
        if let error = try self.decodeERRPacket(from: buffer) {
            throw MySQLChannel.Error.serverError(errorPacket: error)
        }
    }
}
