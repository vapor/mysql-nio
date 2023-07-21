import NIOCore
import Logging

/// This type is both an `NIOSingleStepByteToMessageDecoder` and a `MessageToByteEncoder`, and handles adding and
/// removing the raw wire protocol framing to and from data packets.
///
/// ## Discussion
///
/// MySQL's wire protocol requires tracking a small amount of state that is shared between incoming and outgoing
/// packets at the framing level; fortunately, that state is neither needed by nor interesting to any other layer
/// of the protocol and thus can be fully encapsulated here.
///
/// The MySQL wire packet framing (henceforth referred to as the "raw packet format") consists of three fields:
///
///     ┌───────────┬───────────┬─────────┐
///     │ length(3) │ seqnum(1) │ payload │
///     └───────────┴───────────┴─────────┘
///
/// - `length`: A 24-bit little-endian integer which gives the size of the `payload`. The minimum value of zero is
///   valid only if the raw packet is a terminator for a series of packet fragments (see below). The maximum value
///   is `0xffffff` (`16_777_215`) bytes. The maximum value signals that the raw packet is a member of a fragment
///   series; any packet `0xfffffe` bytes or smaller is either self-contained or a series terminator. The length
///   value does **not** include itself or the sequence number.
/// - `seqnum`: A 1-byte wrapping counter value which permits the server and client to do minimal validation of
///   in-order, lossless packet transmission. (It is not clear to the writer of this description what purpose this
///   really serves, being unaware of any server implementation having support for any unreliable Transport-layer
///   protocols). The sequence counter is incremented for each incoming and outgoing packet, wrapping around to zero
///   when it reaches 255. The counter is reset whenever a client starts a new "command" (this being in reality
///   almost any packet a client would have reason to send once authentication is completed).
/// - `payload`: The actual data of the packet. Exactly `length` bytes long.
///
/// #### Fragmentation
///
/// When a server or client needs to send a packet whose total size exceeds `0xfffffe` bytes, packet fragmentation
/// is used to split the payload. Exactly `payload_size + 1 / 0xffffff` raw packets are sent. All but the last has
/// length `0xffffff`; a raw packet of smaller size signals the end of the series. If the original payload is an
/// exact multiple of `0xffffff` bytes long, the terminator will have length zero. Each fragment counts as a packet
/// for the purposes of incrementing the sequence counter. The receiver must reassemble the fragments into a single
/// packet.
///
/// > Important: While `ByteBuffer`s _decoded_ by this codec are stripped of the raw packet framing, the _encoding_
///   implementation explicitly requires that incoming `ByteBuffer`s have 4 bytes of space reserved starting at the
///   buffer's `readerIndex`. This requirement allows the codec to avoid performing either excessive data copying or
///   excessive allocation when adding framing to outgoing packets. (Packets requiring fragmentation do not benefit
///   from this, but at the time of this writing there has never been even a single instance of needing to handle
///   fragmented packets; this author is thus comfortable saying that case can safely be a slow path.)
final class MySQLRawPacketCodec: NIOSingleStepByteToMessageDecoder, NonThrowingMessageToByteEncoder {
    typealias InboundOut = ByteBuffer
    typealias OutboundIn = ByteBuffer
    
    /// Encapsulated logic for combining and separating a raw packet frame's two components.
    /*testableprivate*/ struct RawPacketFrame: RawRepresentable {
        let length: UInt24
        let sequenceId: UInt8
        
        init<I: FixedWidthInteger>(length: I, sequenceId: UInt8) {
            precondition(length <= 0xff_ff_ff, "Invalid raw packet length, \(length) > 2**24 - 1")
            (self.length, self.sequenceId) = (UInt24(length), sequenceId)
        }
        
        /// Create with raw bytes retrieved from a buffer.
        init(rawValue: UInt32) {
            self.init(length: UInt24(truncatingIfNeeded: rawValue), sequenceId: .init(rawValue >> 24))
        }
        
        /// Make raw bytes to store to a buffer.
        var rawValue: UInt32 {
            UInt32(self.length) | (UInt32(self.sequenceId) << 24)
        }
    }
    
    /// Errors that may be raised during raw packet processing. Not wrapped in a struct because not public.
    enum Error: Swift.Error {
        /// An incoming packet's sequence ID was incorrect.
        case incorrectSequencing
        
        /// Received an empty fragment series terminator with no fragment series in progress.
        case zeroLengthPayload
    }
    
    /// The possible modes we can be in for handling sequence counter resets.
    /*testableprivate*/ enum SequencingState: Equatable {
        /// Initial state
        ///
        /// This state persists throughout the handshake, including TLS setup if any and all auth-related
        /// packets. At no time does the protocol send an OK packet - or anything that can be mistaken for
        /// one - until the handshake is complete. After that OK packets show up quite a bit, of course,
        /// but at the framing level we care about only the very first one. Note that even after receiving
        /// the OK we still don't reset the sequence counter; the next outgoing packet will do so once we're
        /// no longer in the waiting state. There are no non-INITIAL transitions which reach this state. No
        /// transition takes place if an ERR packet shows up, as an error never starts the command phase even
        /// if the connection survives.
        ///
        /// > Note: Even when the `CLIENT_DEPRECATE_EOF` capability is set, meaining certain OK packets are
        /// > marked with the old EOF packet's identifier byte, such a packet will never be the _first_ OK
        /// > packet sent to signal authentication success, so the sequencing state logic does not need to check
        /// > for such packets, in the same way it need not be concerned with mistaking a `COM_STMT_PREPARE_OK`
        /// > packet for a normal OK packet.
        /// >
        /// > We conveniently do not need, and thus do not implement, the `COM_CHANGE_USER` command (which puts
        /// > a connection back into the handshake phase), allowing this state to be one-way.
        ///
        /// ##### Transitions
        /// ||||
        /// -|:-:|-
        /// ||_initial_|||
        /// `waitingForInitialOk`|→|``resetOnOutgoing``
        case waitingForInitialOk
        
        /// Reset sequence counter every time an outgoing packet is sent
        ///
        /// Once we're in the command phase, there are only 12 different types of outgoing packet we
        /// might send - while the protocol defines 33 commands, many of them are deprecated, several
        /// more are for server-internal use, and there are a few this implementation has no use for;
        /// see the packet format defintions for more details. All twelve are considered to be
        /// "commands" by the protocol and thus reset the sequence counter. This quite conveniently
        /// allows answering "when do we reset the counter?" with "every time we start a new outgoing
        /// packet" (only the last fragment of a split packet resets the counter, however). This means
        /// the sequence counter handling can happen entirely within the framing logic and no higher
        /// layers need to be aware of it, which in turn means we don't have to keep a messy thread-unsafe
        /// reference type around for it!
        ///
        /// ##### Transitions
        /// ||||
        /// -|:-:|-
        /// ||_terminal_|||
        case resetOnOutgoing
    }
    
    /// The possible states we can be in with regards to raw packet fragmentation support.
    ///
    /// > Warning: The `Equatable` conformance is only to make checking for `.initial` easier; comparing other
    ///   states is really slow, DON'T do it!
    /*testableprivate*/ enum FragmentationState: Equatable {
        /// There is no incomplete packet pending.
        ///
        /// > Note: This case should be named `none`, but currently isn't due to a bug in DoCC.
        ///
        /// ##### Transitions
        /// ||||
        /// -|:-:|-
        /// ||_initial_|||
        /// `initial`|→|``partiallyReceived(buffer:)``
        case initial
        
        /// We have received one or more max-size (16MiB) packet fragments, but have not yet received a
        /// terminator. While storing the data received so far this way is not ideal, leaving the pending
        /// fragments in the decoder's own buffer would require performing one or more copies to remove
        /// the per-fragment framing when the terminator came in; doing it as each fragment is received
        /// instead (hopefully) amortizes the cost somewhat over time.
        ///
        /// > Note: This state only occurs when at least one complete fragment is received without a
        ///   terminator; fragments which are themselves partially received are handled by the decoder's
        ///   buffer in the same way as non-fragmented packets.
        ///
        /// > Important: Even though individual fragments are not complete packets, the sequence counter
        ///   _does_ increment for each fragment, whether incoming or outgoing, including the terminator
        ///   (even if empty).
        ///
        /// ##### Transitions
        /// ||||
        /// -|:-:|-
        /// `partiallyReceived`|→|``initial``
        case partiallyReceived(buffer: ByteBuffer)
    }
    
    /// The current packet sequence counter. Wraps by unsigned 2's-complement overflow (`0xff` -> `0x00`).
    private var sequenceCounter: UInt8 = 0
    
    /// Current sequencing state
    private var sequencingState: SequencingState = .waitingForInitialOk
    
    /// Current fragmentation state
    private var fragmentationState: FragmentationState = .initial
    
    /// Normal initializer.
    init() {}
    
    /// Specialized initializer for testing only. DO NOT CALL THIS.
    /*testableprivate*/ init(sequenceCounter: UInt8, sequencingState: SequencingState, fragmentationState: FragmentationState) {
        self.sequenceCounter = sequenceCounter
        self.sequencingState = sequencingState
        self.fragmentationState = fragmentationState
    }
    
    /// Generate a sequence ID and return it, while also incrementing the counter.
    private func nextSequenceID() -> UInt8 {
        defer { self.sequenceCounter &+= 1 } // wrapping increment
        return self.sequenceCounter
    }
    
    // See `MessageToByteEncoder.encode(data:out:)`.
    func encode(data: ByteBuffer, out: inout ByteBuffer) {
        if self.sequencingState == .resetOnOutgoing {
            self.sequenceCounter = 0
        }
        
        // N.B.: Can't require non-empty packets; empty outgoing packets are valid in at least one place in the protocol.
        precondition(data.readableBytes >= 4, """
            Programmer error: No space set aside in buffer for framing data.
            
            Please report a bug at <https://github.com/vapor/mysql-nio/issues>.
            """)
        
        if data.readableBytes < Int(UInt24.max) + MemoryLayout<RawPacketFrame>.size {
            out = data
            
            // N.B.: The length's MSB is guaranteed to be zero by the length check.
            out.mysql_setInteger(RawPacketFrame(length: out.readableBytes - 4, sequenceId: self.nextSequenceID()).rawValue, at: out.readerIndex)
        } else {
            // Need to split the packet.
            let numFullFragments = (data.readableBytes - 4) / Int(UInt24.max)
            var remainingData = data
            out = remainingData.readSlice(length: Int(UInt24.max) + MemoryLayout<RawPacketFrame>.size)! // N.B.: We already checked the length explicitly
            out.mysql_setInteger(RawPacketFrame(length: UInt24.max, sequenceId: self.nextSequenceID()).rawValue, at: out.readerIndex) // fill in the first fragment's info
            out.reserveCapacity(minimumWritableBytes: remainingData.readableBytes + numFullFragments * 4 /* additional frames, including terminator, minus the first one */)
            while remainingData.readableBytes >= UInt24.max {
                out.mysql_writeInteger(RawPacketFrame(length: UInt24.max, sequenceId: self.nextSequenceID()).rawValue)
                out.writeImmutableBuffer(remainingData.readSlice(length: Int(UInt24.max))!)
            }
            out.mysql_writeInteger(RawPacketFrame(length: remainingData.readableBytes, sequenceId: self.nextSequenceID()).rawValue) // even if there are exactly zero bytes left, we want to send that
            out.writeImmutableBuffer(remainingData.slice())
        }
    }
    
    // See `NIOSingleStepByteToMessageDecoder.decode(buffer:)`.
    func decode(buffer: inout ByteBuffer) throws -> ByteBuffer? {
        // N.B.: Reading a 32-bit word and deconstructing it is much faster than reading a UInt24 and a UInt8, even with readMultipleIntegers()
        guard let frameWord = buffer.mysql_getInteger(at: buffer.readerIndex, as: UInt32.self),
              let frame = .some(RawPacketFrame(rawValue: frameWord)),
              buffer.readableBytes - MemoryLayout<RawPacketFrame>.size >= frame.length
        else { return nil }
        buffer.moveReaderIndex(forwardBy: MemoryLayout<RawPacketFrame>.size)
        
        /// Before anything else, validate the sequence ID. Neither the sequencing state nor the fragmentation
        /// state affects this check - an incoming packet's sequence ID should _always_ be the current sequence
        /// counter value (but see below).
        ///
        /// > Note: There is one exception to this rule - when the current sequence counter is 1 in the
        ///   `resetOnOutgoing` sequencing state and the packet's sequence ID does not match; this indicates
        ///   that the server sent an error (such as due to a connection timeout) before receiving a new command
        ///   that was just sent. In this case it is desirable to parse the error packet rather than signal a
        ///   low-level protocol error. It's annoying to support this case, given how badly it muddies an otherwise
        ///   very simple, straightforward check, but it turns out it crops up fairly often in practice.
        guard frame.sequenceId == self.sequenceCounter || (
            self.sequencingState == .resetOnOutgoing && self.fragmentationState == .initial && frame.sequenceId == 1 &&
            frame.length > 9/*Min ERR_Packet length*/ && buffer.readableBytesView.first == 0xff /*ERR_Packet marker*/
        ) else {
            throw Error.incorrectSequencing
        }
        self.sequenceCounter = frame.sequenceId &+ 1 // update sequence from the packet's ID so as to respect the "ERR packet with ID 1" case
        
        /// Do fragment joining.
        let ongoingBuffer: ByteBuffer
        
        // Max-length packet is always a fragment, update fragmentation state and wait for more data
        if frame.length == .max {
            switch self.fragmentationState {
            case .partiallyReceived(var partialBuffer):
                self.fragmentationState = .initial // temporary to avoid CoW
                partialBuffer.writeImmutableBuffer(buffer.readSlice(length: Int(UInt24.max))!) // we want to advance the reader index on the input buffer
                self.fragmentationState = .partiallyReceived(buffer: partialBuffer)
            case .initial:
                self.fragmentationState = .partiallyReceived(buffer: buffer.readSlice(length: Int(UInt24.max))!)
            }
            return nil
        // Smaller packet with fragmentation state is a terminator
        } else if case .partiallyReceived(var partialBuffer) = self.fragmentationState {
            self.fragmentationState = .initial // set this now to avoid CoW of the buffer
            if frame.length > 0 {
                partialBuffer.writeImmutableBuffer(buffer.readSlice(length: Int(frame.length))!) // advance the reader index of the input
            }
            ongoingBuffer = partialBuffer
        // Zero-length packet without fragment assembly in progress is invalid
        } else if frame.length == 0 {
            throw Error.zeroLengthPayload
        // Normal standalone packet
        } else {
            ongoingBuffer = buffer.readSlice(length: Int(frame.length))! // advance input reader index
        }
        
        /// Update the sequencing state if needed
        if self.sequencingState == .waitingForInitialOk, frame.length > 7/*Min OK_Packet length*/, ongoingBuffer.readableBytesView.first == 0x00/*OK_Packet marker*/ {
            self.sequencingState = .resetOnOutgoing // saw an OK packet while in the wait state, switch to outgoing sequence reset
        }
        
        /// Send the packet onward
        return ongoingBuffer
    }
    
    // See `NIOSingleStepByteToMessageDecoder.decodeLast(buffer:seenEOF:)`.
    func decodeLast(buffer: inout ByteBuffer, seenEOF: Bool) throws -> ByteBuffer? {
        try self.decode(buffer: &buffer)
    }
}
