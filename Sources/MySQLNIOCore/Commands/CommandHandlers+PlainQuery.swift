import Collections
import NIOCore

struct MySQLPlainQueryContext {
    let attributes: OrderedDictionary<String, MySQLProtocolValue>
    let sql: String
    let promise: EventLoopPromise<()> // result set(s) delivery goes here
}

extension MySQLCommandHandlers {
    struct PlainQuery: MySQLActiveCommandHandler {
        /// The marker byte for a `LOCAL INFILE Request` packet. Defined here because we don't bother with a full
        /// packet definition for it, which is in turn because we don't implement the support yet.
        static var localInfileRequestMarkerByte: UInt8 { 0xfb }
        
        let queryContext: MySQLPlainQueryContext
        
        // MARK: - Incoming packet handlers
        
        /// In the resultset start state, there are four allowed packets:
        ///
        /// - `ERR`, which always has marker byte `0xff`
        /// - `OK`, which always has marker byte `0x00` (the `0xfe` marker is not valid here)
        /// - `LOCAL INFILE Request`, which always has marker byte `0xfb`
        /// - `ResultsetFieldCount`, which may have marker bytes `0x01-0xfa` or `0xfc-0xfe`.
        ///
        /// These possibilities are unambiguous because:
        /// - A `ResultsetFieldCount` with count `0` is not valid.
        /// - `ResultsetFieldCount` starts with a length-encoded integer; `0xfb` and `0xff` are not valid prefixes.
        ///
        /// This means we can know reliably what packet to expect based solely on the marker byte.
        private mutating func handleResultsetStartPacket(context: some MySQLChannelContext, _ packet: ByteBuffer) throws {
            switch packet.mysql_getInteger(at: packet.readerIndex, as: UInt8.self) {
            
            // OK Packet - empty resultset
            case MySQLPacketDescriptions.OKPacket.markerByteOK:
                guard try context.decodeOKPacketAndUpdateConnection(from: packet) != nil else {
                    throw MySQLChannel.Error.protocolViolation
                }
                if !context.statusFlags.contains(.resultsetPending) {
                    // No more resultsets pending, so we're offically *done* done.
                    try self.signalAllResultsetsComplete(context: context)
                    self.state = .done
                }
            
            // LOCAL INFILE Request - we don't currently implement this
            case Self.localInfileRequestMarkerByte:
                throw MySQLChannel.Error.protocolViolation
            
            // ERR Packet - query failed, probably recoverably
            case MySQLPacketDescriptions.ERRPacket.markerByte:
                guard let errorPacket = try context.decodeERRPacket(from: packet) else {
                    throw MySQLChannel.Error.protocolViolation
                }
                let error = MySQLChannel.Error.serverError(errorPacket: errorPacket)
                
                // We don't bother trying to figure out if the error is unrecoverable at this stage; if it is,
                // the server will close the connection on us anyway.
                try self.signalQueryFailure(context: context)
                self.state = .failed(error: error)
                self.queryContext.promise.fail(error)
                context.markCommandComplete()
            
            // ResultsetFieldCount packet - start of result set
            default:
                let countPacket = try MySQLPacketDescriptions.ResultsetFieldCount(from: packet, activeCapabilities: context.capabilities)
                
                try  self.signalStartingNewResultset(context: context)
                if countPacket.metadataPending {
                    self.state = .awaitingColumnMetadata(columnsRemaining: countPacket.columnCount)
                } else {
                    try self.signalResultsetMetadataReady(context: context)
                    self.state = .readingRows
                }
            }
        }
        
        private mutating func handleColumnMetadataPacket(context: some MySQLChannelContext, _ packet: ByteBuffer, columnsRemaining: Int) throws {
            // Receiving OK/EOF in this state is not valid; we require `CLIENT_EOF_DEPRECATED`, so this data is not
            // terminated by an EOF packet, and an OK packet signals command completion, which cannot happen while
            // metadata is being sent. Thus, anything other than a column definition packet is invalid.
            // Additionally, the columnsRemaining value expresses how many metadata packets we are _waiting_ to
            // receive, meaning the value will never reach zero.
            precondition(columnsRemaining > 0, "State violation in query handler (metadata read overrun). Please report a bug.")
            
            let columnDefinition = try MySQLPacketDescriptions.ColumnDefinition41(from: packet, activeCapabilities: context.capabilities)
            
            if columnsRemaining > 1 {
                self.state = .awaitingColumnMetadata(columnsRemaining: columnsRemaining - 1)
            } else {
                self.state = .readingRows
            }
        }
        
        private mutating func handleRowDataPacket(context: some MySQLChannelContext, _ packet: ByteBuffer) throws {
        
        }
        
        // MARK: - Resultset data handlers
        
        private mutating func signalStartingNewResultset(context: some MySQLChannelContext) throws {
        
        }
        
        private mutating func signalResultsetMetadataReady(context: some MySQLChannelContext) throws {
        
        }
        
        private mutating func signalResultsetRowReceived(context: some MySQLChannelContext) throws {
        
        }
        
        private mutating func signalAllResultsetsComplete(context: some MySQLChannelContext) throws {
        
        }
        
        private mutating func signalQueryFailure(context: some MySQLChannelContext) throws {
        
        }
        
        // MARK: - Active command handler
        
        mutating func handlerActive(context: some MySQLChannelContext) throws {
            guard case .awaitingResultsetStart = self.state else { preconditionFailure("State violation in query handler (already active). Please report a bug.") }
            
            var buffer = ByteBuffer()
            MySQLPacketDescriptions.PlainQueryCommand(attributes: self.queryContext.attributes, sql: self.queryContext.sql)
                .write(to: &buffer, activeCapabilities: context.capabilities)
            context.sendPacket(buffer)
        }
        
        mutating func packetReceived(context: some MySQLChannelContext, _ packet: ByteBuffer) throws {
            switch self.state {
            case .awaitingResultsetStart:
                try self.handleResultsetStartPacket(context: context, packet)
            case .awaitingColumnMetadata(columnsRemaining: let columnsRemaining):
                try self.handleColumnMetadataPacket(context: context, packet, columnsRemaining: columnsRemaining)
            case .readingRows:
                try self.handleRowDataPacket(context: context, packet)
            case .done, .failed(_):
                break
            }
        }
        
        mutating func handlerInactive(context: some MySQLChannelContext) throws {
            
        }
        
        /// States and their transitions.
        enum State {
            /// A `COM_QUERY` command was sent and no response has yet been received, or a new resultset has
            /// been signaled as incoming but not yet received.
            ///
            /// The first reply to a `COM_QUERY` may be one of an OK packet, an ERR packet, a LOCAL INFILE
            /// request, or a result set column count. Disambiguating these four possibilities can be
            /// unintuitive; see the ``PlainQueryHandler/packetReceived(context:_:)`` method for details.
            ///
            /// ##### Transitions
            /// ||||
            /// -|:-:|-
            /// ||_initial_|||
            /// `awaitingResultsetStart`|→|`awaitingResultsetStart`
            /// `awaitingResultsetStart`|→|``sendingLocalInfileData``
            /// `awaitingResultsetStart`|→|``awaitingColumnMetadata(columnsRemaining:)``
            /// `awaitingResultsetStart`|→|``readingRows``
            /// `awaitingResultsetStart`|→|``done``
            /// `awaitingResultsetStart`|→|``failed(error:)``
            /// |xx|||
            case awaitingResultsetStart
            
            /// Partially finished sending a `LOCAL INFILE` data response, which may span an arbitrary number of packets
            /// and is the only instance of a valid empty packet in the protocol aside from a fragment terminator.
            ///
            /// ##### Transitions
            /// ||||
            /// -|:-:|-
            /// `sendingLocalInfileData`|→|`sendingLocalInfileData`
            /// `sendingLocalInfileData`|→|``awaitingResultsetStart``
            /// `sendingLocalInfileData`|→|``done``
            /// `sendingLocalInfileData`|→|``failed(error:)``
            //case sendingLocalInfileData
            
            /// Waiting for one or more column metadata packets
            ///
            /// ##### Transitions
            /// ||||
            /// -|:-:|-
            /// `awaitingColumnMetadata`|→|``awaitingResultsetStart``
            /// `awaitingColumnMetadata`|→|`awaitingColumnMetadata`
            /// `awaitingColumnMetadata`|→|``readingRows``
            /// `awaitingColumnMetadata`|→|``done``
            /// `awaitingColumnMetadata`|→|``failed(error:)``
            case awaitingColumnMetadata(columnsRemaining: Int)
            
            /// Reading resultset rows
            ///
            /// ##### Transitions
            /// ||||
            /// -|:-:|-
            /// `readingRows`|→|``awaitingResultsetStart``
            /// `readingRows`|→|`readingRows`
            /// `readingRows`|→|``done``
            /// `readingRows`|→|``failed(error:)``
            case readingRows
            
            /// All result sets received or all infile data sent
            ///
            /// ##### Transitions
            /// ||||
            /// -|:-:|-
            /// ||_terminal_|||
            case done
            
            /// An error occurred during any step of query handling.
            ///
            /// ##### Transitions
            /// ||||
            /// -|:-:|-
            /// ||_terminal_|||
            case failed(error: any Error)
        }
        
        private var state: State
    }
}
