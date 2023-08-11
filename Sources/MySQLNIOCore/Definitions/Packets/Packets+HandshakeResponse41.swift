import NIOCore
import Collections

extension MySQLPackets {
    /// A MySQL wire protocol client initial handshake response (4.1 protocol) packet
    struct HandshakeResponse41 {
        let clientCapabilities: MySQLCapabilities
        let collation: UInt8
        let username: String
        let authPluginResponse: ByteBuffer
        let initialDatabase: String? // only non-`nil` if `CLIENT_CONNECT_WITH_DB`
        let clientAuthPluginName: String
        let connectionAttributes: OrderedDictionary<String, String>
        let zstdCompressionLevel: UInt8? // only if `CLIENT_COMPRESSION` && `CLIENT_ZSTD_COMPRESSION_ALGORITHM`

        /// Attempt to decode a raw packet as a `HandshakeResponse41` packet.
        init(from packet: ByteBuffer) throws {
            var packet = packet
            
            guard let (capabilityFlags, _/*maxPacketSize*/, collation)
                                           = packet.readMultipleIntegers(endianness: .little, as: (UInt32, UInt32, UInt8).self),
                  /*let filler            =*/packet.mysql_readRepeatingByte(count: 19),
                  let clientCapabilities   = packet.mysql_readInteger(as: UInt32.self).map({ MySQLCapabilities(rawValues: capabilityFlags, $0) }),
                  let username             = packet.readNullTerminatedString(),
                  let authPluginResponse   = clientCapabilities.contains([.pluggableAuthentication, .flexiblySizedAuthPluginData]) ?
                        packet.mysql_readLengthEncodedSlice() :
                        packet.readLengthPrefixedSlice(as: UInt8.self),
                  let initialDatabase      = packet.mysql_optional(clientCapabilities.contains(.connectWithDatabase), packet.readNullTerminatedString()),
                  let clientAuthPluginName = clientCapabilities.contains(.pluggableAuthentication) ? packet.readNullTerminatedString() : MySQLBuiltinAuthHandlers.NativePassword.pluginName,
                  let connectionAttributes = clientCapabilities.contains(.connectionAttributes) ? packet.mysql_readLengthEncodedKeyValuePairs() : .some(.init()),
                  let zstdCompressionLevel = packet.mysql_optional(clientCapabilities.contains([.compression, .zstdCompression]), packet.mysql_readInteger(as: UInt8.self))
            else {
                throw MySQLCoreError.protocolViolation(debugDescription: "Invalid handshake response packet")
            }
            
            self.clientCapabilities = clientCapabilities
            self.collation = collation
            self.username = username
            self.authPluginResponse = authPluginResponse
            self.initialDatabase = initialDatabase
            self.clientAuthPluginName = clientAuthPluginName
            self.connectionAttributes = connectionAttributes
            self.zstdCompressionLevel = zstdCompressionLevel
        }
        
        /// Create a `HandshakeResponse41` packet from a set of parameters.
        init(
            clientCapabilities: MySQLCapabilities,
            collation: UInt8,
            username: String,
            clientAuthPluginName: String,
            authPluginResponseData: ByteBuffer,
            connectionAttributes: OrderedDictionary<String, String>,
            initialDatabase: String?,
            zstdCompressionLevel: UInt8?
        ) {
            precondition(clientCapabilities.contains(.connectWithDatabase) || initialDatabase == nil)
            precondition(clientCapabilities.contains([.compression, .zstdCompression]) || zstdCompressionLevel == nil)
            precondition(clientCapabilities.contains(.pluggableAuthentication) || clientAuthPluginName == MySQLBuiltinAuthHandlers.NativePassword.pluginName)
            precondition(clientCapabilities.contains(.flexiblySizedAuthPluginData) || authPluginResponseData.readableBytes < 256)
            
            self.clientCapabilities = clientCapabilities
            self.collation = collation
            self.username = username
            self.authPluginResponse = authPluginResponseData
            self.initialDatabase = initialDatabase
            self.clientAuthPluginName = clientAuthPluginName
            self.connectionAttributes = connectionAttributes
            self.zstdCompressionLevel = zstdCompressionLevel
        }
        
        /// Encode this structure in the raw `HandshakeResponse41` wire format.
        func write(to buffer: inout ByteBuffer) {
            assert(self.clientCapabilities.contains(.connectWithDatabase) || self.initialDatabase == nil)
            assert(self.clientCapabilities.contains([.compression, .zstdCompression]) || self.zstdCompressionLevel == nil)
            assert(clientCapabilities.contains(.pluggableAuthentication) || self.clientAuthPluginName == MySQLBuiltinAuthHandlers.NativePassword.pluginName)
            assert(clientCapabilities.contains(.flexiblySizedAuthPluginData) || self.authPluginResponse.readableBytes < 256)
            
            buffer.writeMultipleIntegers(
                self.clientCapabilities.lowHalf,
                UInt32.max/*maxPacketSize*/,
                self.collation,
                endianness: .little)
            buffer.writeRepeatingByte(0, count: 19) // filler
            buffer.mysql_writeInteger(self.clientCapabilities.extendedHalf)
            buffer.writeNullTerminatedString(self.username)
            if self.clientCapabilities.contains([.pluggableAuthentication, .flexiblySizedAuthPluginData]) {
                buffer.mysql_writeLengthEncodedImmutableBuffer(self.authPluginResponse)
            } else {
                try! buffer.writeLengthPrefixed(as: UInt8.self, writeMessage: { $0.writeImmutableBuffer(self.authPluginResponse) })
            }
            if let initialDatabase = self.initialDatabase {
                buffer.writeNullTerminatedString(initialDatabase)
            }
            if self.clientCapabilities.contains(.pluggableAuthentication) {
                buffer.writeNullTerminatedString(self.clientAuthPluginName)
            }
            if self.clientCapabilities.contains(.connectionAttributes) {
                buffer.mysql_writeLengthEncodedKeyValuePairs(self.connectionAttributes.map { ($0, $1) })
            }
            if let zstdCompressionLevel = self.zstdCompressionLevel {
                buffer.mysql_writeInteger(zstdCompressionLevel)
            }
        }
    }
}

extension MySQLPackets.HandshakeResponse41 {
    func build(allocator: ByteBufferAllocator = .init()) -> ByteBuffer {
        var buffer = allocator.buffer(capacity: 4 + 32 /* + ...*/)
        buffer.writeRepeatingByte(0, count: 4) // for frame
        self.write(to: &buffer)
        return buffer
    }
}
