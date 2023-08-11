import NIOCore

/// Provides a version of `MessageToByteEncoder` that doesn't throw from its encode method.
public protocol NonThrowingMessageToByteEncoder {
    associatedtype OutboundIn

    /// Called once there is data to encode.
    ///
    /// - parameters:
    ///     - data: The data to encode into a `ByteBuffer`.
    ///     - out: The `ByteBuffer` into which we want to encode.
    func encode(data: OutboundIn, out: inout ByteBuffer)
}

/// A counterpart to `NIOSingleStepByteToMessageProcessor` used to buffer outgoing data.
public final class MessageToByteProcessor<Encoder: MessageToByteEncoder> {
    @usableFromInline
    enum State: Hashable {
        case flushable
        case waitingForBuffer
    }
    
    @usableFromInline internal private(set) var encoder: Encoder
    @usableFromInline internal private(set) var buffer: ByteBuffer
    @usableFromInline internal private(set) var state: State = .flushable
    
    @inlinable
    init(_ encoder: Encoder, buffer: ByteBuffer) {
        self.encoder = encoder
        self.buffer = buffer
    }
    
    @inlinable
    func process(message: Encoder.OutboundIn) throws {
        if self.state == .waitingForBuffer {
            self.buffer.discardReadBytes()
            self.state = .flushable
        }
        try self.encoder.encode(data: message, out: &self.buffer)
    }
    
    @inlinable
    func flush() -> ByteBuffer {
        self.state = .waitingForBuffer
        return self.buffer
    }
}
@available(*, unavailable) extension MessageToByteProcessor: Sendable {}

/// ``MessageToByteProcessor``, but for non-throwing encoders
public final class NonThrowingMessageToByteProcessor<Encoder: NonThrowingMessageToByteEncoder> {
    @usableFromInline internal private(set) var encoder: Encoder
    @usableFromInline internal private(set) var buffer: ByteBuffer
    
    @inlinable init(_ encoder: Encoder, buffer: ByteBuffer) {
        (self.encoder, self.buffer) = (encoder, buffer)
    }
    
    @inlinable func process(message: Encoder.OutboundIn) {
        self.buffer.discardReadBytes() // incurs no cost if no bytes have been read
        self.encoder.encode(data: message, out: &self.buffer)
    }
    
    @inlinable func flush() -> ByteBuffer { self.buffer }
}
@available(*, unavailable) extension NonThrowingMessageToByteProcessor: Sendable {}

/// A combined `NIOSingleStepByteToMessageProcessor` and ``MessageToByteProcessor``, designed for working with
/// codecs which conform to both protocols to accomodate the need for shared state which affects both incoming
/// decoding and outgoing encoding.
public final class MessageByteTranscodingProcessor<Codec: NIOSingleStepByteToMessageDecoder & MessageToByteEncoder> {
    @usableFromInline internal private(set) var codec: Codec
    @usableFromInline internal let decodeProcessor: NIOSingleStepByteToMessageProcessor<Codec>
    @usableFromInline internal let encodeProcessor: MessageToByteProcessor<Codec>
    
    @inlinable init(_ codec: Codec, maximumDecodeBufferSize: Int? = nil, encodeBuffer: ByteBuffer) {
        self.codec = codec
        self.decodeProcessor = .init(codec, maximumBufferSize: maximumDecodeBufferSize)
        self.encodeProcessor = .init(codec, buffer: encodeBuffer)
    }
    
    @inlinable var unprocessedBytes: Int {
        self.decodeProcessor.unprocessedBytes
    }
    
    @inlinable func process(buffer: ByteBuffer, _ messageReceiver: (Codec.InboundOut) throws -> Void) throws {
        try self.decodeProcessor.process(buffer: buffer, messageReceiver)
    }
    
    @inlinable func finishProcessing(seenEOF: Bool, _ messageReceiver: (Codec.InboundOut) throws -> Void) throws {
        try self.decodeProcessor.finishProcessing(seenEOF: seenEOF, messageReceiver)
    }
    
    @inlinable func process(message: Codec.OutboundIn) throws {
        try self.encodeProcessor.process(message: message)
    }
    
    @inlinable func flush() -> ByteBuffer {
        self.encodeProcessor.flush()
    }
}
@available(*, unavailable) extension MessageByteTranscodingProcessor: Sendable {}

/// ``MessageByteTranscodingProcessor``, but for non-throwing encoders
public final class NonThrowingMessageByteTranscodingProcessor<Codec: NIOSingleStepByteToMessageDecoder & NonThrowingMessageToByteEncoder> {
    @usableFromInline internal private(set) var codec: Codec
    @usableFromInline internal let decodeProcessor: NIOSingleStepByteToMessageProcessor<Codec>
    @usableFromInline internal let encodeProcessor: NonThrowingMessageToByteProcessor<Codec>
    
    @inlinable init(_ codec: Codec, maximumDecodeBufferSize: Int? = nil, encodeBuffer: ByteBuffer) {
        self.codec = codec
        self.decodeProcessor = .init(codec, maximumBufferSize: maximumDecodeBufferSize)
        self.encodeProcessor = .init(codec, buffer: encodeBuffer)
    }
    @inlinable var unprocessedBytes: Int { self.decodeProcessor.unprocessedBytes }
    @inlinable func process(buffer: ByteBuffer, _ cb: (Codec.InboundOut) throws -> Void) throws { try self.decodeProcessor.process(buffer: buffer, cb) }
    @inlinable func finishProcessing(seenEOF: Bool, _ cb: (Codec.InboundOut) throws -> Void) throws { try self.decodeProcessor.finishProcessing(seenEOF: seenEOF, cb) }
    @inlinable func process(message: Codec.OutboundIn) { self.encodeProcessor.process(message: message) }
    @inlinable func flush() -> ByteBuffer { self.encodeProcessor.flush() }
}
@available(*, unavailable) extension NonThrowingMessageByteTranscodingProcessor: Sendable {}

extension MessageByteTranscodingProcessor {
    @inlinable func processAndFlush(message: Codec.OutboundIn) throws -> ByteBuffer {
        try self.encodeProcessor.process(message: message)
        return self.encodeProcessor.flush()
    }
}

extension NonThrowingMessageByteTranscodingProcessor {
    @inlinable func processAndFlush(message: Codec.OutboundIn) -> ByteBuffer {
        self.encodeProcessor.process(message: message)
        return self.encodeProcessor.flush()
    }
}
