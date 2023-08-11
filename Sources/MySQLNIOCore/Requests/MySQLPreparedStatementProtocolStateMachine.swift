import NIOCore

struct MySQLPreparedStatementProtocolStateMachine {
    /// States and their transitions.
    enum State {
        ///
        /// ##### Transitions
        /// ||||
        /// -|:-:|-
        /// ||**`INITIAL`**|||

        ///
        /// ##### Transitions
        /// ||||
        /// -|:-:|-
        /// ||_terminal_|||
        case done

        /// An error occurred during any step of prepared statement handling.
        ///
        /// ##### Transitions
        /// ||||
        /// -|:-:|-
        /// ||_terminal_|||
        case failed(error: any Error)
    }
    
    // External events to which the state machine responds

    func packetReceived(_ packet: ByteBuffer) async throws {}

    // Internal events the state machine processes
    
    func receivedOK(_ packet: ByteBuffer, isEOF: Bool) async throws {}
    func receivedERR(_ packet: ByteBuffer) async throws {}

    private var state: State
}
