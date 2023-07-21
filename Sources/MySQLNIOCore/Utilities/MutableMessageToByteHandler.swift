import NIOCore

/// This is exactly the same protocol as NIO's `MessageToByteEncoder`, except that the ``encode(data:out:)``
/// method is `mutating`, which allows a value-typed encoder to maintain internal state.
public protocol MutableMessageToByteEncoder {
    associatedtype OutboundIn

    /// Called once there is data to encode.
    ///
    /// - Parameters:
    ///   - data: The data to encode into a `ByteBuffer`.
    ///   - out: The `ByteBuffer` into which we want to encode.
    mutating func encode(data: OutboundIn, out: inout ByteBuffer) throws
}

/// An exact copy of `MessageToByteHandler`, except that it accepts a ``MutableMessageToByteEncoder``.
public final class MutableMessageToByteHandler<Encoder: MutableMessageToByteEncoder>: ChannelOutboundHandler {
    public typealias OutboundOut = ByteBuffer
    public typealias OutboundIn = Encoder.OutboundIn

    private enum State {
        case notInChannelYet
        case operational
        case error(any Error)
        case done

        var readyToBeAddedToChannel: Bool {
            switch self {
            case .notInChannelYet:
                return true
            case .operational, .error, .done:
                return false
            }
        }
    }

    private var state: State = .notInChannelYet
    private var encoder: Encoder
    private var buffer: ByteBuffer? = nil

    public init(_ encoder: Encoder) {
        self.encoder = encoder
    }
}

@available(*, unavailable)
extension MutableMessageToByteHandler: Sendable {}

extension MutableMessageToByteHandler {
    public func handlerAdded(context: ChannelHandlerContext) {
        precondition(self.state.readyToBeAddedToChannel, "illegal state when adding to Channel: \(self.state)")
        self.state = .operational
        self.buffer = context.channel.allocator.buffer(capacity: 256)
    }

    public func handlerRemoved(context: ChannelHandlerContext) {
        self.state = .done
        self.buffer = nil
    }

    public func write(context: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
        switch self.state {
        case .notInChannelYet:
            preconditionFailure("MessageToByteHandler.write called before it was added to a Channel")
        case .error(let error):
            promise?.fail(error)
            context.fireErrorCaught(error)
            return
        case .done:
            // let's just ignore this
            return
        case .operational:
            // there's actually some work to do here
            break
        }
        let data = self.unwrapOutboundIn(data)

        do {
            self.buffer!.clear()
            try self.encoder.encode(data: data, out: &self.buffer!)
            context.write(self.wrapOutboundOut(self.buffer!), promise: promise)
        } catch {
            self.state = .error(error)
            promise?.fail(error)
            context.fireErrorCaught(error)
        }
    }
}
