import NIOCore

/// Defines requirements for active command handlers.
///
/// At any given time, a fully authenticated MySQL connection is either idle, such that there is no
/// command being processed nor any pending commands, or active. An active connection is processing
/// a command and may also have additional commands queued for processing. A command being processed
/// by an active connection has a corresponding handler which conforms to this protocol.
protocol MySQLActiveCommandHandler {
    /// The type which defines the possible states of the handler.
    ///
    /// There is no specific functional purpose served by this particular protocol requirement; it is
    /// here primarily to serve as a reminder to conforming types that they should be implemented as
    /// strictly-defined finite state machines.
    associatedtype State
    
    /// The handler has just become active. Most, if not all, handlers will send the actual command
    /// packet(s) from this method.
    ///
    /// Errors thrown from this method are assumed to be unrecoverable, causing connection termination.
    mutating func handlerActive(context: some MySQLChannelContext) throws

    /// The handler is about to become inactive.
    ///
    /// This method is guaranteed to be invoked at least once on any handler on which the
    /// ``handlerActive(context:)`` method was previously invoked, even if the connection was closed
    /// due to an error. Most channel context methods will throw an error if invoked from this method.
    ///
    /// Errors thrown from this method are assumed to be unrecoverable, causing connection termination.
    mutating func handlerInactive(context: some MySQLChannelContext) throws

    /// A complete raw packet has been received.
    ///
    /// Errors thrown from this method are assumed to be unrecoverable, causing connection termination.
    mutating func packetReceived(context: some MySQLChannelContext, _ packet: ByteBuffer) throws
}

/// Namespace for command handlers.
enum MySQLCommandHandlers {}
