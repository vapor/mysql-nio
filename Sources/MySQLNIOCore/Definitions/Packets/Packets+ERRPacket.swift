import NIOCore

extension MySQLPackets {
    /// A MySQL wire protocol generic error packet
    ///
    /// The protocol calls this `ERR_Packet`. To be interpreted as an error packet, a given incoming packet must
    /// be at least 9 bytes long (sufficient to contain all required fields) and start with the `0xff` marker byte.
    ///
    /// The protocol does not define _any_ packets which can be mistaken for an `ERR_Packet` regardless of the
    /// connection state. The following table gives proof for all known non-deprecated server packets (note
    /// that a length-encoded integer will never have a `0xfb` or `0xff` prefix; see
    /// <doc:Length-Encoded-Integer-Format> for details).
    ///
    /// Packet|Reason
    /// -|-
    /// `OK_Packet`|Marker `0x00` or `0xfe`
    /// `HandshakeV10`|Marker `0x0a` (protocol version)
    /// `AuthSwitchRequest`|Marker `0xfe`
    /// `AuthMoreData`|Marker `0x01`
    /// `AuthNextFactor`|Marker `0x02`
    /// `COM_STATISTICS` reply|Always ASCII, `0xff` is invalid
    /// `LOCAL INFILE Request`|Marker `0xfb`
    /// `Text Resultset`|Starts with `int<lenenc>`
    /// `Binary Resultset`|Starts with `int<lenenc>`
    /// `ColumnDefinition41`|Starts with `int<lenenc>`
    /// `Text Resultset Row`|Starts with `0xfb` or `int<lenenc>`
    /// `Binary Resultset Row`|Marker `0x00`
    /// `Binlog Event`|Marker `0x00`
    struct ERRPacket {
        static var markerByte: UInt8 { 0xff }

        let errorCode: UInt16
        let sqlState: Substring
        let errorMessage: Substring
        
        /// Attempt to decode a raw packet as an error packet.
        ///
        /// - Throws: Protocol violation error for an `ERR_Packet` with invalid or truncated data
        init(from packet: ByteBuffer) throws {
            var packet = packet
            guard packet.mysql_readMarker(matching: Self.markerByte),
                  let errorCode          = packet.mysql_readInteger(as: UInt16.self),
                  let sqlStateAndMessage = packet.mysql_readString(),
                                           sqlStateAndMessage.count >= 6, sqlStateAndMessage.starts(with: "#")
            else {
                throw MySQLCoreError.protocolViolation(debugDescription: "Invalid error packet")
            }
            
            self.errorCode = errorCode
            self.sqlState = sqlStateAndMessage.dropFirst().prefix(5)
            self.errorMessage = sqlStateAndMessage.dropFirst(6)
        }
        
        /// Create an error from a MySQL error code, five-character SQL state, and
        /// human-readable message. Returns nil if the SQL state is not properly formatted.
        init?(errorCode: UInt16, sqlState: String, message: String) {
            guard sqlState.utf8.count == 5,
                  sqlState.allSatisfy(\.isASCII),
                  sqlState.allSatisfy({ $0.isLetter || $0.isNumber})
            else {
                return nil
            }
            self.errorCode = errorCode
            self.sqlState = sqlState[...]
            self.errorMessage = message[...]
        }

        /// Encode this structure in the raw `ERR_Packet` wire format.
        ///
        /// - Precondition: The SQL state contains exactly 5 alphanumeric ASCII bytes.
        func write(to buffer: inout ByteBuffer) {
            assert(self.sqlState.utf8.count == 5 &&
                   self.sqlState.allSatisfy({ $0.isASCII && ($0.isLetter || $0.isNumber) }))
            
            buffer.writeMultipleIntegers(Self.markerByte, self.errorCode, endianness: .little)
            buffer.writeString("#\(self.sqlState)\(self.errorMessage)")
        }
    }
}

extension MySQLPackets.ERRPacket {
    func build(allocator: ByteBufferAllocator = .init()) -> ByteBuffer {
        var buffer = allocator.buffer(capacity: 4 + 1 + 2 + 6 + self.errorMessage.utf8.count)
        buffer.writeRepeatingByte(0, count: 4) // for frame
        self.write(to: &buffer)
        return buffer
    }
}

extension MySQLCoreError.server {
    /// Create a channel error from an error packet.
    ///
    /// Not intended for external use.
    init(errorPacket: MySQLPackets.ERRPacket, context: MySQLCoreError.Context? = nil) {
        self.init(
            code: errorPacket.errorCode,
            sqlState: .init(errorPacket.sqlState),
            message: .init(errorPacket.errorMessage),
            context: .init(
                sourceLocation: context?.sourceLocation, query: context?.query,
                debugDescription: context?.debugDescription ?? .init(errorPacket.errorMessage)
            )
        )
    }
}
