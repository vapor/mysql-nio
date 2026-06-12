import NIOCore
import Testing

@testable import MySQLNIO

@Suite("MySQL Packet Framing Tests")
struct MySQLPacketFramingTests {
    // N.B.: Several tests use `.withUnsafeBytes { $0.allSatisfy(...) }` because using `.allSatisfy()` directly on a
    // ByteBuffer or ByteBufferView in debug builds (i.e. with no inlining) is four or five orders of magnitude slower
    // (as in 1 second (unsafe bytes) versus multiple minutes (direct use).

    // MARK: - Utility

    var maxZeroArray: [UInt8] { .init(repeating: 0, count: Int(UInt24.max)) }
    var maxZeroBuffer: ByteBuffer { .init(repeating: 0, count: Int(UInt24.max) + MemoryLayout<MySQLRawPacketCodec.RawPacketFrame>.size) }
    func maxZeroBuffer<S: Sequence<UInt8>>(plus: S) -> ByteBuffer {
        var buf = self.maxZeroBuffer
        buf.writeBytes(plus)
        return buf
    }
    var maxMinusOneZeroBuffer: ByteBuffer { .init(repeating: 0, count: Int(UInt24.max) - 1 + MemoryLayout<MySQLRawPacketCodec.RawPacketFrame>.size) }

    // MARK: - RawPacketFrame

    @Test("RawPacketFrame bit packing")
    func rawPacketFrameBitPacking() {
        #expect(MySQLRawPacketCodec.RawPacketFrame(rawTestValue: 0x11_22_33_44).length == 0x33_22_11)
        #expect(MySQLRawPacketCodec.RawPacketFrame(rawTestValue: 0x11_22_33_44).sequenceId == 0x44)
        #expect(MySQLRawPacketCodec.RawPacketFrame(rawTestValue: 0x11_22_33_44).rawValue == 0x44_33_22_11)
        // n.b.: expected result given in little-endian encoding

        #expect(MySQLRawPacketCodec.RawPacketFrame(rawTestValue: 0x44_33_22_11).length == 0x22_33_44)
        #expect(MySQLRawPacketCodec.RawPacketFrame(rawTestValue: 0x44_33_22_11).sequenceId == 0x11)
        #expect(MySQLRawPacketCodec.RawPacketFrame(rawTestValue: 0x44_33_22_11).rawValue == 0x11_22_33_44)
        // n.b.: expected result given in little-endian encoding
    }

    // MARK: - Encoding

    @Test("Encoding standard packets")
    func encodingStandardPackets() {
        var codec1 = MySQLRawPacketCodec(sequenceCounter: 0, sequencingState: .waitingForInitialOk, fragmentationState: .initial)
        var codec2 = MySQLRawPacketCodec(sequenceCounter: 0, sequencingState: .resetOnOutgoing, fragmentationState: .initial)

        // Encode one packet in non-reset mode: Sequence ID 0
        #expect(
            codec1.encodeAndReturn(data: .init(bytes: [0x00, 0x00, 0x00, 0x00, 0x01, 0x02, 0x03, 0x04])).readableBytesView
                == [0x04, 0x00, 0x00, 0x00, 0x01, 0x02, 0x03, 0x04]
        )
        // Encode second packet in non-reset mode: Sequence ID 1
        #expect(
            codec1.encodeAndReturn(data: .init(bytes: [0x00, 0x00, 0x00, 0x00, 0x03, 0x02, 0x01])).readableBytesView
                == [0x03, 0x00, 0x00, 0x01, 0x03, 0x02, 0x01]
        )
        // Encode packet with max - 1 length in non-reset mode: Sequence ID 2
        let bigEncoded1 = codec1.encodeAndReturn(data: self.maxMinusOneZeroBuffer)
        #expect(bigEncoded1.readableBytesView.prefix(4) == [0xfe, 0xff, 0xff, 0x02])
        #expect(bigEncoded1.readableBytesView.dropFirst(4).count == UInt24.max - 1)
        #expect(bigEncoded1.readableBytesView.dropFirst(4).withUnsafeBytes { $0.allSatisfy({ $0 == 0 }) })

        // Encode one packet in reset mode: Sequence ID 0
        #expect(
            codec2.encodeAndReturn(data: .init(bytes: [0x00, 0x00, 0x00, 0x00, 0x01, 0x02, 0x03, 0x04])).readableBytesView
                == [0x04, 0x00, 0x00, 0x00, 0x01, 0x02, 0x03, 0x04]
        )
        // Encode second packet in reset mode: Sequence ID 0
        #expect(
            codec2.encodeAndReturn(data: .init(bytes: [0x00, 0x00, 0x00, 0x00, 0x01, 0x02, 0x03])).readableBytesView
                == [0x03, 0x00, 0x00, 0x00, 0x01, 0x02, 0x03]
        )
        // Encode packet with max - 1 length in reset mode: Sequence ID 0
        let bigEncoded2 = codec2.encodeAndReturn(data: self.maxMinusOneZeroBuffer)
        #expect(bigEncoded2.readableBytesView.prefix(4) == [0xfe, 0xff, 0xff, 0x00])
        #expect(bigEncoded2.readableBytesView.dropFirst(4).count == UInt24.max - 1)
        #expect(bigEncoded2.readableBytesView.dropFirst(4).withUnsafeBytes { $0.allSatisfy({ $0 == 0 }) })
    }

    @Test("Encoding huge packets")
    func encodingHugePackets() {
        var codec1 = MySQLRawPacketCodec(sequenceCounter: 0, sequencingState: .waitingForInitialOk, fragmentationState: .initial)
        var codec2 = MySQLRawPacketCodec(sequenceCounter: 0, sequencingState: .resetOnOutgoing, fragmentationState: .initial)

        // Encode packet of exactly maximum length (wait mode): One fragment, zero-length terminator, Sequence IDs [0, 1]
        let maxEncoded1 = codec1.encodeAndReturn(data: self.maxZeroBuffer)
        #expect(maxEncoded1.readableBytes == Int(UInt24.max) + (MemoryLayout<MySQLRawPacketCodec.RawPacketFrame>.size * 2))
        #expect(maxEncoded1.readableBytesView.prefix(4) == [0xff, 0xff, 0xff, 0x00])
        #expect(maxEncoded1.readableBytesView.dropFirst(4).prefix(Int(UInt24.max)).withUnsafeBytes { $0.allSatisfy({ $0 == 0 }) })
        #expect(maxEncoded1.readableBytesView.dropFirst(Int(UInt24.max) + 4) == [0x00, 0x00, 0x00, 0x01])

        // Encode packet of size max + 1 (wait mode): One fragment, length 1 terminator, Sequence IDs [2, 3]
        let maxEncoded2 = codec1.encodeAndReturn(data: self.maxZeroBuffer(plus: [0x01]))
        #expect(maxEncoded2.readableBytes == Int(UInt24.max) + (MemoryLayout<MySQLRawPacketCodec.RawPacketFrame>.size * 2) + 1)
        #expect(maxEncoded2.readableBytesView.prefix(4) == [0xff, 0xff, 0xff, 0x02])
        #expect(maxEncoded2.readableBytesView.dropFirst(4).prefix(Int(UInt24.max)).withUnsafeBytes { $0.allSatisfy({ $0 == 0 }) })
        #expect(Array(maxEncoded2.readableBytesView.dropFirst(Int(UInt24.max) + 4)) == [0x01, 0x00, 0x00, 0x03, 0x01])

        // Encode packet of size exactly max * 2 (reset mode): Two fragments, zero-length terminator, Sequence IDs [0, 1, 2]
        let maxEncoded3 = codec2.encodeAndReturn(data: self.maxZeroBuffer(plus: self.maxZeroArray))
        #expect(maxEncoded3.readableBytes == (Int(UInt24.max) * 2) + (MemoryLayout<MySQLRawPacketCodec.RawPacketFrame>.size * 3))
        #expect(maxEncoded3.readableBytesView.prefix(4) == [0xff, 0xff, 0xff, 0x00])
        #expect(maxEncoded3.readableBytesView.dropFirst(4).prefix(Int(UInt24.max)).withUnsafeBytes { $0.allSatisfy({ $0 == 0 }) })
        #expect(maxEncoded3.readableBytesView.dropFirst(Int(UInt24.max) + 4).prefix(4) == [0xff, 0xff, 0xff, 0x01])
        #expect(
            maxEncoded3.readableBytesView.dropFirst(Int(UInt24.max) + 8).prefix(Int(UInt24.max)).withUnsafeBytes { $0.allSatisfy({ $0 == 0 }) }
        )
        #expect(maxEncoded3.readableBytesView.dropFirst((Int(UInt24.max) * 2) + 8) == [0x00, 0x00, 0x00, 0x02])

        // Encode packet of max * 2 + 1 (reset mode): Two fragments, length 1 terminator, Sequence IDs [0, 1, 2]
        let maxEncoded4 = codec2.encodeAndReturn(data: self.maxZeroBuffer(plus: self.maxZeroArray + [0x00]))
        #expect(maxEncoded4.readableBytes == (Int(UInt24.max) * 2) + (MemoryLayout<MySQLRawPacketCodec.RawPacketFrame>.size * 3) + 1)
        #expect(maxEncoded4.readableBytesView.prefix(4) == [0xff, 0xff, 0xff, 0x00])
        #expect(maxEncoded4.readableBytesView.dropFirst(4).prefix(Int(UInt24.max)).withUnsafeBytes { $0.allSatisfy({ $0 == 0 }) })
        #expect(maxEncoded4.readableBytesView.dropFirst(Int(UInt24.max) + 4).prefix(4) == [0xff, 0xff, 0xff, 0x01])
        #expect(
            maxEncoded4.readableBytesView.dropFirst(Int(UInt24.max) + 8).prefix(Int(UInt24.max)).withUnsafeBytes { $0.allSatisfy({ $0 == 0 }) }
        )
        #expect(Array(maxEncoded4.readableBytesView.dropFirst((Int(UInt24.max) * 2) + 8)) == [0x01, 0x00, 0x00, 0x02, 0x00])
    }

    // MARK: - Decoding

    @Test("Insufficient data")
    func insufficientData() throws {
        let codec = MySQLRawPacketCodec(sequenceCounter: 0, sequencingState: .waitingForInitialOk, fragmentationState: .initial)
        var buffer = ByteBuffer()

        #expect(try codec.decode(buffer: &buffer) == nil)  // Empty buffer can't be decoded

        buffer.writeBytes([0x01, 0x00, 0x00, 0x00])
        #expect(try codec.decode(buffer: &buffer) == nil)  // Frame word but no data, should wait for more data
        #expect(buffer.readerIndex == 0)

        buffer.setBytes([0x02, 0x00, 0x00, 0x00, 0x00], at: buffer.readerIndex)
        #expect(try codec.decode(buffer: &buffer) == nil)  // Frame word and partial data, should wait for more data
        #expect(buffer.readerIndex == 0)

        buffer.setBytes([0xff, 0xff, 0xff, 0x00] + self.maxZeroArray.dropLast(), at: buffer.readerIndex)
        #expect(try codec.decode(buffer: &buffer) == nil)  // Frame word and one byte short of max size should wait for more data
        #expect(buffer.readerIndex == 0)

        buffer.setBytes([0x00, 0x00, 0x00, 0x00], at: buffer.readerIndex)
        let error = #expect(throws: (any Error).self) { try codec.decode(buffer: &buffer) }
        #expect((error as? MySQLRawPacketCodec.Error) == .zeroLengthPayload)  // Terminator with no previous fragments
    }

    @Test("Sequence ID validation")
    func sequenceIDValidation() throws {
        var codec: MySQLRawPacketCodec
        var buffer: ByteBuffer

        // two incoming packets with sequence IDs [0, 1] == correct
        codec = .init(sequenceCounter: 0, sequencingState: .waitingForInitialOk, fragmentationState: .initial)
        buffer = .init(bytes: [0x01, 0x00, 0x00, 0x00, 0x7f] + [0x01, 0x00, 0x00, 0x01, 0x07f])
        #expect(try codec.decode(buffer: &buffer)?.readableBytes == 1)
        #expect(try codec.decode(buffer: &buffer)?.readableBytes == 1)
        #expect(buffer.readableBytes == 0)

        // incoming packet with sequence ID 1 == incorrect
        codec = .init(sequenceCounter: 0, sequencingState: .waitingForInitialOk, fragmentationState: .initial)
        buffer = .init(bytes: [0x01, 0x00, 0x00, 0x01, 0x7f])
        let error = #expect(throws: (any Error).self) { try codec.decode(buffer: &buffer) }
        #expect((error as? MySQLRawPacketCodec.Error) == .incorrectSequencing)

        // two incoming packets when counter == 0xff with sequence IDs [0xff, 0x00] == correct, counter wraps around
        codec = .init(sequenceCounter: 0xff, sequencingState: .waitingForInitialOk, fragmentationState: .initial)
        buffer = .init(bytes: [0x01, 0x00, 0x00, 0xff, 0x7f] + [0x01, 0x00, 0x00, 0x00, 0x7f])
        #expect(try codec.decode(buffer: &buffer)?.readableBytes == 1)
        #expect(try codec.decode(buffer: &buffer)?.readableBytes == 1)
        #expect(buffer.readableBytes == 0)
    }

    @Test("Incoming fragment handling")
    func incomingFragmentHandling() throws {
        var codec: MySQLRawPacketCodec
        var buffer: ByteBuffer

        // two incoming packets with sequence IDs [0, 1], lengths [max, 0], initial state: none but consumes fragment, then packet with length == max
        codec = .init(sequenceCounter: 0x00, sequencingState: .waitingForInitialOk, fragmentationState: .initial)
        buffer = .init(bytes: [[0xff, 0xff, 0xff, 0x00], self.maxZeroArray, [0x00, 0x00, 0x00, 0x01]].flatMap({ $0 }))
        #expect(try codec.decode(buffer: &buffer) == nil)
        #expect(buffer.readableBytes == 4)
        let decoded1 = try #require(try codec.decode(buffer: &buffer))
        #expect(decoded1.readableBytes == Int(UInt24.max))
        #expect(decoded1.withUnsafeReadableBytes { $0.allSatisfy { $0 == 0 } })
        #expect(buffer.readableBytes == 0)

        // two incoming packets with sequence IDs [0, 1], lengths [max, 1], initial state: decodes to packet with length == max + 1
        codec = .init(sequenceCounter: 0x00, sequencingState: .waitingForInitialOk, fragmentationState: .initial)
        buffer = .init(bytes: [[0xff, 0xff, 0xff, 0x00], self.maxZeroArray, [0x01, 0x00, 0x00, 0x01, 0x00]].flatMap({ $0 }))
        #expect(try codec.decode(buffer: &buffer) == nil)
        #expect(buffer.readableBytes == 5)
        let decoded2 = try #require(try codec.decode(buffer: &buffer))
        #expect(decoded2.readableBytes == Int(UInt24.max) + 1)
        #expect(decoded2.withUnsafeReadableBytes { $0.allSatisfy { $0 == 0 } })
        #expect(buffer.readableBytes == 0)

        // three incoming packets with sequence IDs [0, 1, 2], lengths [max, max, 0], initial state: none but consumes fragment x2, then packet with length = 2*max
        codec = .init(sequenceCounter: 0x00, sequencingState: .waitingForInitialOk, fragmentationState: .initial)
        buffer = .init(
            bytes: [
                [0xff, 0xff, 0xff, 0x00],
                self.maxZeroArray,
                [0xff, 0xff, 0xff, 0x01],
                self.maxZeroArray,
                [0x00, 0x00, 0x00, 0x02],
            ].flatMap { $0 }
        )
        #expect(try codec.decode(buffer: &buffer) == nil)
        #expect(buffer.readableBytes == MemoryLayout<MySQLRawPacketCodec.RawPacketFrame>.size * 2 + Int(UInt24.max))
        #expect(try codec.decode(buffer: &buffer) == nil)
        #expect(buffer.readableBytes == MemoryLayout<MySQLRawPacketCodec.RawPacketFrame>.size)
        let decoded3 = try #require(try codec.decode(buffer: &buffer))
        #expect(decoded3.readableBytes == Int(UInt24.max) * 2)
        #expect(decoded3.withUnsafeReadableBytes { $0.allSatisfy { $0 == 0 } })
        #expect(buffer.readableBytes == 0)

        // three incoming packets with sequence IDs [0, 1, 2], lengths [max, max, 1], initial state: none but consumes fragment x2, then packet with length = 2*max + 1
        codec = .init(sequenceCounter: 0x00, sequencingState: .waitingForInitialOk, fragmentationState: .initial)
        buffer = .init(
            bytes: [
                [0xff, 0xff, 0xff, 0x00],
                self.maxZeroArray,
                [0xff, 0xff, 0xff, 0x01],
                self.maxZeroArray,
                [0x01, 0x00, 0x00, 0x02, 0x00],
            ].flatMap { $0 }
        )
        #expect(try codec.decode(buffer: &buffer) == nil)
        #expect(buffer.readableBytes == MemoryLayout<MySQLRawPacketCodec.RawPacketFrame>.size * 2 + Int(UInt24.max) + 1)
        #expect(try codec.decode(buffer: &buffer) == nil)
        #expect(buffer.readableBytes == MemoryLayout<MySQLRawPacketCodec.RawPacketFrame>.size + 1)
        let decoded4 = try #require(try codec.decode(buffer: &buffer))
        #expect(decoded4.readableBytes == Int(UInt24.max) * 2 + 1)
        #expect(decoded4.withUnsafeReadableBytes { $0.allSatisfy { $0 == 0 } })
        #expect(buffer.readableBytes == 0)

        // incoming zero-length packet with sequence ID 0 in partial fragment state == incorrect (but with sequence error, not zero-length error)
        codec = .init(sequenceCounter: 0x01, sequencingState: .waitingForInitialOk, fragmentationState: .partiallyReceived(buffer: .init()))
        buffer = .init(bytes: [0x00, 0x00, 0x00, 0x00])
        let error = #expect(throws: (any Error).self) { try codec.decode(buffer: &buffer) }
        #expect(error as? MySQLRawPacketCodec.Error == .incorrectSequencing)

        // two incoming packets when counter == 0xff with sequence IDs [255, 0], lengths [max, 0], initial state: none then max-size packet
        codec = .init(sequenceCounter: 0xff, sequencingState: .waitingForInitialOk, fragmentationState: .initial)
        buffer = .init(bytes: [[0xff, 0xff, 0xff, 0xff], self.maxZeroArray, [0x00, 0x00, 0x00, 0x00]].flatMap({ $0 }))
        #expect(try codec.decode(buffer: &buffer) == nil)
        #expect(buffer.readableBytes == 4)
        let decoded5 = try #require(try codec.decode(buffer: &buffer))
        #expect(decoded5.readableBytes == Int(UInt24.max))
        #expect(decoded5.withUnsafeReadableBytes { $0.allSatisfy { $0 == 0 } })
        #expect(buffer.readableBytes == 0)
    }

    @Test("ERR and OK packet detection")
    func errAndOKPacketDetection() throws {
        var codec: MySQLRawPacketCodec
        var buffer: ByteBuffer

        // ERR packet with ID 1 (should be 2) in waiting seq state, initial frag state == incorrect
        codec = .init(sequenceCounter: 2, sequencingState: .waitingForInitialOk, fragmentationState: .initial)
        buffer = .init([0x0a, 0x00, 0x00, 0x01, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff])
        let error1 = #expect(throws: (any Error).self) { try codec.decode(buffer: &buffer) }
        #expect(error1 as? MySQLRawPacketCodec.Error == .incorrectSequencing)

        // ERR packet with ID 1 (should be 2) in waiting seq state, partial frag state == incorrect
        codec = .init(sequenceCounter: 2, sequencingState: .waitingForInitialOk, fragmentationState: .partiallyReceived(buffer: .init()))
        buffer = .init([0x0a, 0x00, 0x00, 0x01, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff])
        let error2 = #expect(throws: (any Error).self) { try codec.decode(buffer: &buffer) }
        #expect(error2 as? MySQLRawPacketCodec.Error == .incorrectSequencing)

        // ERR packet with ID 1 (should be 2) in reset seq state, initial frag state == accepted w/ sequence counter adjust
        codec = .init(sequenceCounter: 2, sequencingState: .resetOnOutgoing, fragmentationState: .initial)
        buffer = .init([0x0a, 0x00, 0x00, 0x01, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff] + [0x01, 0x00, 0x00, 0x02, 0x00])
        #expect(try codec.decode(buffer: &buffer)?.readableBytes == 10)
        #expect(throws: Never.self, "sequence ID not reset after out-of-sequence ERR") { try codec.decode(buffer: &buffer) }

        // ERR packet with ID 1 (should be 2) in reset seq state, partial frag state == incorrect
        codec = .init(sequenceCounter: 2, sequencingState: .resetOnOutgoing, fragmentationState: .partiallyReceived(buffer: .init()))
        buffer = .init([0x0a, 0x00, 0x00, 0x01, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff])
        let error3 = #expect(throws: (any Error).self) { try codec.decode(buffer: &buffer) }
        #expect(error3 as? MySQLRawPacketCodec.Error == .incorrectSequencing)

        // ERR packet with ID 1 (should be 1) in reset seq state, partial frag state == treated as terminator
        codec = .init(sequenceCounter: 1, sequencingState: .resetOnOutgoing, fragmentationState: .partiallyReceived(buffer: .init()))
        buffer = .init([0x0a, 0x00, 0x00, 0x01, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff])
        let decoded1 = try #require(try codec.decode(buffer: &buffer))
        #expect(decoded1.readableBytes == 10)
        #expect(decoded1.withUnsafeReadableBytes { $0.allSatisfy { $0 == 0xff } })
        #expect(buffer.readableBytes == 0)

        // OK packet in waiting seq state, initial frag state == switches to reset state
        codec = .init(sequenceCounter: 2, sequencingState: .waitingForInitialOk, fragmentationState: .initial)
        buffer = .init(bytes: [0x08, 0x00, 0x00, 0x02, 0x00, 0x7d, 0x7e, 0x7f, 0x80, 0x81, 0x82, 0x83])
        #expect(try codec.decode(buffer: &buffer) != nil)
        #expect(
            Array(codec.encodeAndReturn(data: .init(bytes: [0x00, 0x00, 0x00, 0x00, 0x00])).readableBytesView) == [0x01, 0x00, 0x00, 0x00, 0x00],
            "sequence ID not reset by outgoing packet"
        )

        // OK packet in waiting seq state, partial frag state == treated as terminator
        codec = .init(sequenceCounter: 1, sequencingState: .waitingForInitialOk, fragmentationState: .partiallyReceived(buffer: .init(bytes: [0x01])))
        buffer = .init([0x08, 0x00, 0x00, 0x01, 0x00, 0x7d, 0x7e, 0x7f, 0x80, 0x81, 0x82, 0x83])
        let decoded2 = try #require(try codec.decode(buffer: &buffer))
        #expect(decoded2.readableBytes == 9)
        #expect(buffer.readableBytes == 0)
        #expect(
            Array(codec.encodeAndReturn(data: .init(bytes: [0x00, 0x00, 0x00, 0x00, 0x00])).readableBytesView) == [0x01, 0x00, 0x00, 0x02, 0x00],
            "sequence state incorrectly advanced"
        )

        // Packet in waiting seq state, partial frag state where reassembled packet is valid OK packet == switches to reset state
        codec = .init(sequenceCounter: 1, sequencingState: .waitingForInitialOk, fragmentationState: .partiallyReceived(buffer: .init(bytes: [0x00])))
        buffer = .init([0x08, 0x00, 0x00, 0x01, 0x00, 0x7d, 0x7e, 0x7f, 0x80, 0x81, 0x82, 0x83])
        let decoded3 = try #require(try codec.decode(buffer: &buffer))
        #expect(decoded3.readableBytes == 9)
        #expect(buffer.readableBytes == 0)
        #expect(
            Array(codec.encodeAndReturn(data: .init(bytes: [0x00, 0x00, 0x00, 0x00, 0x00])).readableBytesView) == [0x01, 0x00, 0x00, 0x00, 0x00],
            "sequence ID not reset by outgoing packet"
        )
    }

    // MARK: - Code coverage false negatives
    // N.B.: These tests exist solely to convince the test coverage tooling that we're testing everything, including things
    //       which in practice do not need testing. The only thing we can't clean up this way is the preconditions.

    @Test("Code coverage false negatives")
    func codeCoverageFalseNegativesCodec() throws {
        var buf = ByteBuffer()
        let codec = MySQLRawPacketCodec()
        #expect(try codec.decodeLast(buffer: &buf, seenEOF: false) == nil)
    }
}

extension MySQLRawPacketCodec.RawPacketFrame {
    init<T: FixedWidthInteger>(rawTestValue: T) {
        self.init(rawValue: UInt32(rawTestValue).bigEndian)
    }
}

extension NonThrowingMessageToByteEncoder {
    mutating func encodeAndReturn(data: ByteBuffer) -> ByteBuffer where OutboundIn == ByteBuffer {
        var buffer = ByteBuffer()
        self.encode(data: data, out: &buffer)
        return buffer
    }
}
