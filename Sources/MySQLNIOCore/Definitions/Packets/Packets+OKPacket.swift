import NIOCore
import Collections

extension MySQLPackets {
    /// A MySQL wire protocol generic "success"/"complete" packet.
    ///
    /// The protocol calls this `OK_Packet`. In the 5.7+ protocol (i.e. when the ``MySQLCapabilities/eofDeprecation``
    /// capability has been negotiated), an incoming packet is an OK packet if it starts with the `0x00` or `0xfe`
    /// marker bytes and is at least 7 bytes long.
    ///
    /// If the ``MySQLCapabilities/sessionStateTracking`` capability has been negotiated, the packet may contain
    /// additional server state data. We recognize all six currently defined state record types but currently
    /// interpret only some of them.
    struct OKPacket {
        static var markerByteOK: UInt8 { 0 } // marker for normal OK
        static var markerByteEOF: UInt8 { 254 } // marker for EOF-replacement OK

        let isEOF: Bool
        let affectedRows: Int
        let lastInsertId: UInt64
        let statusFlags: MySQLServerStatusFlags
        let warningCount: Int
        let statusMessage: String
        let updatedSettings: OrderedDictionary<String, String>
        let newSchema: String?
        let generalStateChange: Bool
        
        /// Throws error if packet has invalid format.
        init(from origPacket: ByteBuffer, activeCapabilities capabilities: MySQLCapabilities) throws {
            var packet = origPacket

            /// In order to ensure an OK packet with EOF marker can be reliably distinguished from a text resultset
            /// data row, an OK packet may not be larger than 2²⁴-1 bytes. The only place where this is clearly
            /// documented is the source code:
            /// https://github.com/mysql/mysql-server/blob/8.0/sql/protocol_classic.cc#L955
            guard (7 ... Int(UInt24.max)).contains(packet.readableBytes),
                  packet.mysql_readMarker(matching: Self.markerByteOK, or: Self.markerByteEOF),
                  let affectedRows  = packet.mysql_readLengthEncodedInteger().flatMap(Int.init(exactly:)),
                  let lastInsertId  = packet.mysql_readLengthEncodedInteger(),
                  let (statusFlagsRaw, warningCount) = packet.readMultipleIntegers(endianness: .little, as: (UInt16, UInt16).self),
                  let statusMessage = capabilities.contains(.sessionStateTracking) ? packet.mysql_readLengthEncodedString() : packet.mysql_readString()
            else {
                throw MySQLCoreError.protocolViolation(debugDescription: "Invalid OK packet")
            }
            
            let statusFlags = MySQLServerStatusFlags(rawValue: statusFlagsRaw)
            var newSchema: String? = nil
            var updatedSettings: OrderedDictionary<String, String> = [:]
            var generalStateChange = false
            
            if capabilities.contains(.sessionStateTracking), statusFlags.contains(.sessionStateInfoIncluded) {
                guard var stateData = packet.mysql_readLengthEncodedSlice() else {
                    throw MySQLCoreError.protocolViolation(debugDescription: "Invalid OK packet")
                }
                
                while stateData.readableBytes > 0 {
                    guard let type = stateData.readInteger(as: UInt8.self), var data = stateData.mysql_readLengthEncodedSlice() else {
                        throw MySQLCoreError.protocolViolation(debugDescription: "Invalid OK packet")
                    }
                    
                    switch SessionTrackingRecordType(rawValue: type) {
                    
                    case .systemSetting:
                        guard let name = data.mysql_readLengthEncodedString(), let value = data.mysql_readLengthEncodedString() else {
                            throw MySQLCoreError.protocolViolation(debugDescription: "Invalid OK packet")
                        }
                        updatedSettings[name] = value
                    
                    case .schema:
                        guard let trackedNewSchema = data.mysql_readLengthEncodedString() else {
                            throw MySQLCoreError.protocolViolation(debugDescription: "Invalid OK packet")
                        }
                        newSchema = trackedNewSchema
                    
                    case .stateChange:
                        guard let flag = data.mysql_readInteger(as: UInt8.self) else {
                            throw MySQLCoreError.protocolViolation(debugDescription: "Invalid OK packet")
                        }
                        generalStateChange = (flag != 0)
                    
                    default: break // we don't track any of the other record types at this time, ignore 'em
                    }
                }
            }
            
            self.isEOF = (origPacket.mysql_getInteger(at: origPacket.readerIndex, as: UInt8.self) == Self.markerByteEOF)
            self.affectedRows = affectedRows
            self.lastInsertId = lastInsertId
            self.statusFlags = statusFlags
            self.warningCount = Int(warningCount)
            self.statusMessage = statusMessage
            self.newSchema = newSchema
            self.updatedSettings = updatedSettings
            self.generalStateChange = generalStateChange
        }
        
        func write(to buffer: inout ByteBuffer, activeCapabilities capabilities: MySQLCapabilities) {
            buffer.writeInteger(self.isEOF ? Self.markerByteEOF : Self.markerByteOK)
            buffer.mysql_writeLengthEncodedInteger(self.affectedRows)
            buffer.mysql_writeLengthEncodedInteger(self.lastInsertId)
            buffer.writeMultipleIntegers(self.statusFlags.rawValue, UInt16(self.warningCount), endianness: .little)
            if capabilities.contains(.sessionStateTracking) {
                buffer.mysql_writeLengthEncodedString(self.statusMessage)
                if self.statusFlags.contains(.sessionStateInfoIncluded) {
                    var stateBuf = ByteBuffer()
                    for pair in self.updatedSettings {
                        stateBuf.mysql_writeInteger(SessionTrackingRecordType.systemSetting.rawValue)
                        stateBuf.mysql_writeLengthEncodedImmutableBuffer(.init(mysql_keyValueStringPairs: [pair]))
                    }
                    if let newSchema = self.newSchema {
                        stateBuf.mysql_writeInteger(SessionTrackingRecordType.schema.rawValue)
                        stateBuf.mysql_writeLengthEncodedImmutableBuffer(.init(mysql_lengthEncodedString: newSchema))
                    }
                    if self.generalStateChange {
                        stateBuf.mysql_writeInteger(SessionTrackingRecordType.stateChange.rawValue)
                        stateBuf.mysql_writeLengthEncodedImmutableBuffer(.init(integer: 1, as: UInt8.self))
                    }
                    buffer.mysql_writeLengthEncodedBuffer(&stateBuf)
                }
            } else {
                buffer.writeString(self.statusMessage)
            }
        }

        enum SessionTrackingRecordType: UInt8 {
            /// One of the variables listed in `@@session.session_track_system_variables` has changed.
            /// New value is included.
            ///
            /// MySQL name: `SESSION_TRACK_SYSTEM_VARIABLES`
            case systemSetting = 0
            
            /// `@@session.session_track_schema` is `ON` and the current default schema has changed
            /// (typically due to a `USE` query). New schema is included.
            ///
            /// MySQL name: `SESSION_TRACK_SCHEMA`
            case schema = 1
            
            /// `@@session.session_track_state_change` is `ON` and any session-specific state other than
            /// that variable has changd. Boolean flag only.
            ///
            /// MySQL name: `SESSION_TRACK_STATE_CHANGE`
            case stateChange = 2
            
            /// `@@session.session_track_gtids` is `ON` and new GTIDs are available.
            ///
            /// MySQL name: `SESSION_TRACK_GTIDS`
            case globalTransactionIDs = 3
            
            /// `@@session.session_track_transaction_info` is `CHARACTERISTICS` and the transaction state
            /// has changed. New characteristics are included. Always accompanied by ``.transactionState``.
            ///
            /// MySQL name: `SESSION_TRACK_TRANSACTION_CHARACTERISTICS`
            case transactionCharacteristics = 4
            
            /// `@@session.session_track_transaction_info` is not `OFF` and the transaction state has
            /// changed. New state is included.
            ///
            /// MySQL name: `SESSION_TRACK_TRANSACTION_STATE`
            case transactionState = 5
        }
    }
}

extension MySQLPackets.OKPacket {
    func build(allocator: ByteBufferAllocator = .init(), activeCapabilities: MySQLCapabilities) -> ByteBuffer {
        var buffer = allocator.buffer(capacity: 4 + 1 + 32 /* + ... */)
        buffer.writeRepeatingByte(0, count: 4) // for frame
        self.write(to: &buffer, activeCapabilities: activeCapabilities)
        return buffer
    }
}
