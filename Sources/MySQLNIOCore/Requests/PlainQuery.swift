import Collections
import NIOCore

enum PlainQuery {
    struct Context {
        let attributes: OrderedDictionary<String, MySQLProtocolValue>
        let sql: String
        let promise: EventLoopPromise<MySQLResultsetStream> // result set(s) delivery goes here
    }

    struct StateMachine {
        /// The marker byte for a `LOCAL INFILE Request` packet. Defined here because we don't bother with a full
        /// packet definition for it, which is in turn because we don't implement the support yet.
        static var localInfileRequestMarkerByte: UInt8 { 0xfb }
        
        // MARK: - States

        /// The defined states for plain query handling
        #if swift(>=5.9) && $AttachedMacros
        @StateMachineStateConditions
        #endif
        enum State {
            /// A `COM_QUERY` command was sent and no response has yet been received, or a new
            /// resultset has been signaled as incoming but not yet received.
            case awaitingResultsetStart
            /// Partially finished sending a `LOCAL INFILE` data response.
            case sendingLocalInfileData
            /// Waiting for one or more column metadata packets
            case awaitingColumnMetadata(columnsRemaining: Int)
            /// Reading resultset rows
            case readingRows
            /// All result sets received, all infile data sent, or error stopped the query.
            case done(result: (any Swift.Error)?)
        }
        
        private var state: State = .awaitingResultsetStart

        let capabilities: MySQLCapabilities
        let context: Context
        
        init(capabilities: MySQLCapabilities, context: Context) {
            self.capabilities = capabilities
            self.context = context
        }
        
        func start() -> MySQLPackets.PlainQueryCommand {
            assert(self.state.isAwaitingResultsetStart)
            
            return .init(attributes: self.context.attributes, sql: self.context.sql)
        }
        
        mutating func handlePacketRead(_ packet: ByteBuffer) -> MySQLChannel.Handler.Reaction {
            do {
                switch self.state {
                case .awaitingResultsetStart:
                    return try self.handleResultsetStartPacket(packet)
                case .sendingLocalInfileData:
                    stateCheckFailure("unimplemented")
                case .awaitingColumnMetadata(columnsRemaining: let columnsRemaining):
                    return try self.handleColumnMetadataPacket(packet, columnsRemaining: columnsRemaining)
                case .readingRows:
                    return try self.handleRowDataPacket(packet)
                case .done:
                    stateCheckFailure("shouldn't still get packets after completion")
                }
            } catch {
                return .handleError(error)
            }
        }
        
        mutating func handleError(_ error: any Swift.Error) -> MySQLChannel.Handler.Reaction {
            self.teardownState(reason: error)
            return .startNextRequest
        }
        
        mutating func teardownState(reason: any Swift.Error) {
            self.context.promise.fail(reason)
            self.state = .done(result: reason)
        }
    
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
        private mutating func handleResultsetStartPacket(_ packet: ByteBuffer) throws -> MySQLChannel.Handler.Reaction {
            switch packet.mysql_getInteger(at: packet.readerIndex, as: UInt8.self) {
            
            // OK Packet - empty resultset
            case MySQLPackets.OKPacket.markerByteOK:
                let packet = try MySQLPackets.OKPacket(from: packet, activeCapabilities: self.capabilities)
                
                if !packet.statusFlags.contains(.resultsetPending) {
                    // No more resultsets pending, so we're offically *done* done.
                    self.state = .done(result: nil)
                    try self.signalAllResultsetsComplete()
                    return .updateStatusFlags(packet.statusFlags, then: .startNextRequest)
                } else {
                    try self.signalStartingNewResultset()
                    return .updateStatusFlags(packet.statusFlags, then: .read)
                }
            
            // LOCAL INFILE Request - we don't currently implement this
            case Self.localInfileRequestMarkerByte:
                throw MySQLCoreError.protocolViolation(debugDescription: "unimplemented")
            
            // ERR Packet - query failed, probably recoverably
            case MySQLPackets.ERRPacket.markerByte:
                throw try MySQLCoreError.server(errorPacket: MySQLPackets.ERRPacket.init(from: packet))

            // ResultsetFieldCount packet - start of result set
            default:
                let countPacket = try MySQLPackets.ResultsetFieldCount(from: packet, activeCapabilities: self.capabilities)
                
                try self.signalStartingNewResultset()
                if countPacket.metadataPending {
                    self.state = .awaitingColumnMetadata(columnsRemaining: countPacket.columnCount)
                } else {
                    self.state = .readingRows
                    try self.signalResultsetMetadataReady()
                }
                return .read
            }
        }
        
        private mutating func handleColumnMetadataPacket(_ packet: ByteBuffer, columnsRemaining: Int) throws -> MySQLChannel.Handler.Reaction {
            // Receiving OK/EOF in this state is not valid; we require `CLIENT_EOF_DEPRECATED`, so this data is not
            // terminated by an EOF packet, and an OK packet signals command completion, which cannot happen while
            // metadata is being sent. Thus, anything other than a column definition packet is invalid.
            // Additionally, the columnsRemaining value expresses how many metadata packets we are _waiting_ to
            // receive, meaning the value will never reach zero.
            precondition(columnsRemaining > 0, "State violation in query handler (metadata read overrun). Please report a bug.")
            
            let columnDefinition = try MySQLPackets.ColumnDefinition41(from: packet, activeCapabilities: self.capabilities)
            
            if columnsRemaining > 1 {
                self.state = .awaitingColumnMetadata(columnsRemaining: columnsRemaining - 1)
            } else {
                self.state = .readingRows
            }
            return .read
        }
        
        private mutating func handleRowDataPacket( _ packet: ByteBuffer) throws -> MySQLChannel.Handler.Reaction {
            let data = try MySQLPackets.TextResultsetRow(from: packet)
            
            try self.signalResultsetRowReceived(data)
            return .read
        }
        
        // MARK: - Resultset data handlers
        
        private mutating func signalStartingNewResultset() throws {
            fatalError()
        }
        
        private mutating func signalResultsetMetadataReady() throws {
            fatalError()
        }
        
        private mutating func signalResultsetRowReceived(_ row: MySQLPackets.TextResultsetRow) throws {
            fatalError()
        }
        
        private mutating func signalAllResultsetsComplete() throws  {
            fatalError()
        }
        
        private mutating func signalQueryFailure() throws {
            fatalError()
        }
        
        private func stateCheck(_ check: @autoclosure () -> Bool, _ message: @autoclosure () -> String, file: StaticString = #file, line: UInt = #line) {
            guard check() else {
                stateCheckFailure(message(), file: file, line: line)
            }
        }
        
        private func stateCheckFailure(_ message: @autoclosure () -> String, file: StaticString = #file, line: UInt = #line) -> Never {
            preconditionFailure("State violation in query state machine (\(message())). Please report a bug.", file: file, line: line)
        }
    }
}

#if compiler(<5.9) || !$AttachedMacros

extension PlainQuery.StateMachine.State {
    var isAwaitingResultsetStart: Bool { guard case .awaitingResultsetStart = self else { return false }; return true }
    var isSendingLocalInfileData: Bool { guard case .sendingLocalInfileData = self else { return false }; return true }
    var isAwaitingColumnMetadata: Bool { guard case .awaitingColumnMetadata = self else { return false }; return true }
    var isReadingRows: Bool            { guard case .readingRows            = self else { return false }; return true }
    var isDone: Bool                   { guard case .done                   = self else { return false }; return true }
}

#endif
