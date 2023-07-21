import NIOCore
import Algorithms

extension MySQLPackets {
    /// A MySQL wire protocol server initial handshake (protocol version 10) packet
    struct HandshakeV10 {
        static var markerByte: UInt8 { 10 } // protocol version
        
        let serverVersion: String
        let threadId: UInt32
        let authPluginData: ByteBuffer
        let serverCapabilities: MySQLCapabilities
        let statusFlags: MySQLServerStatusFlags
        let authPluginName: String
        
        /// Attempt to decode a raw packet as a `HandshakeV10` packet.
        ///
        /// > Note: This implementation eschews 100% strict protocol validation in favor of being as flexible
        ///   as possible within the packet format. In particular, it does not check for violations such as
        ///   non-zero extended capability flags when the `CLIENT_MYSQL` capability is set, a missing
        ///   authentication plugin name when `CLIENT_PLUGIN_AUTH` is present, an obviously invalid
        ///   authentication data length (relative to the presence or absence of `CLIENT_PLUGIN_AUTH`), or
        ///   the absence of the "hardcoded" protocol capabilities (see
        ///   ``MySQLCapabilityFlags/hardcodedCapabilities``). The primary reason for this is it allows
        ///   reading the entire packet without having to be concerned with _any_ capability flags, which
        ///   in turn allows all compatibility determinations beyond the protocol version to happen at a
        ///   higher layer than the raw packet format.
        ///
        /// - Returns: `nil` if packet is not an `HandshakeV10` packet. This occurs only if the initial marker
        ///   byte does not signal protocol version 10; all other packet format issues are hard errors.
        /// - Throws: Protocol violation error for a `HandshakeV10` packet with invalid or truncated data
        init(from packet: ByteBuffer) throws {
            var packet = packet
            
            // Check protocol version, which is also the server handshake packet's marker byte.
            guard packet.mysql_readMarker(matching: Self.markerByte),
            // Load data from packet.
                  let serverVersion      = packet.readNullTerminatedString(),
                  let threadId           = packet.mysql_readInteger(as: UInt32.self),
                  let authPluginData1    = packet.readBytes(length: 8),
                  /*let filler          =*/packet.mysql_readInteger(as: UInt8.self) == 0x00,
                  let (capabilityFlags1, _/*collation*/, statusFlags, capabilityFlags2, authPluginDataLen)
                                         = packet.readMultipleIntegers(endianness: .little, as: (UInt16, UInt8, UInt16, UInt16, UInt8).self),
                  /*let reserved        =*/packet.readBytes(length: 6) == [0, 0, 0, 0, 0, 0],
                  let capabilityFlagsExt = packet.mysql_readInteger(as: UInt32.self),
                  let authPluginData2    = packet.readBytes(length: (authPluginDataLen > 0 ? Int(authPluginDataLen) : 20) - authPluginData1.count),
                  let authPluginName     = packet.readNullTerminatedString() ?? .some(MySQLBuiltinAuthHandlers.NativePassword.pluginName)
            else {
                throw MySQLCoreError.protocolViolation(debugDescription: "Invalid handshake packet")
            }
            
            self.serverVersion = serverVersion
            self.threadId = threadId
            self.authPluginData = ByteBuffer(bytes: authPluginData1 + authPluginData2)
            self.serverCapabilities = .init(rawValues: capabilityFlags1, capabilityFlags2, capabilityFlagsExt)
            self.statusFlags = .init(rawValue: statusFlags)
            self.authPluginName = authPluginName
        }
        
        /// Encode this structure in the raw `HandshakeV10` wire format.
        ///
        /// If `CLIENT_PLUGIN_AUTH` is not set in ``serverCapabilities``, ``authPluginName`` must be
        /// `"mysql_native_password"` and ``authPluginData`` must be exactly 20 bytes.
        func write(to buffer: inout ByteBuffer) {
            precondition(serverCapabilities.contains(.pluggableAuthentication) || self.authPluginName == MySQLBuiltinAuthHandlers.NativePassword.pluginName)
            precondition(serverCapabilities.contains(.pluggableAuthentication) || self.authPluginData.readableBytes == 20)

            buffer.mysql_writeInteger(Self.markerByte)
            buffer.writeNullTerminatedString(self.serverVersion)
            buffer.mysql_writeInteger(self.threadId)
            buffer.writeBytes(chain(self.authPluginData.readableBytesView.prefix(8), [0,0,0,0,0,0,0,0]).prefix(8))
            buffer.writeMultipleIntegers(
                0x00 as UInt8, // filler
                self.serverCapabilities.lowThird,
                MySQLTextCollation.bestCollation(forVersion: self.serverVersion, capabilities: self.serverCapabilities).idForHandshake,
                self.statusFlags.rawValue,
                self.serverCapabilities.midThird,
                UInt8(self.serverCapabilities.contains(.pluggableAuthentication) ? self.authPluginData.readableBytes - 8 : 0),
                0 as UInt32, 0 as UInt16, // reserved
                self.serverCapabilities.extendedHalf,
                endianness: .little
            )
            buffer.writeBytes(self.authPluginData.readableBytesView.dropFirst(8))
            if self.serverCapabilities.contains(.pluggableAuthentication) {
                buffer.writeNullTerminatedString(self.authPluginName)
            }
        }
    }
}

extension MySQLPackets.HandshakeV10 {
    func build(allocator: ByteBufferAllocator = .init()) -> ByteBuffer {
        var buffer = allocator.buffer(capacity: 4 + 1 +
            self.serverVersion.utf8.count + 4 +
            Swift.max(self.authPluginData.readableBytes, 20) +
            1 + 18 + self.authPluginName.utf8.count)
        buffer.writeRepeatingByte(0, count: 4) // for frame
        self.write(to: &buffer)
        return buffer
    }
}
