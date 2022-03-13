extension MySQLProtocol {
    /// 14.1.3.1 `OK_Packet`
    ///
    /// An OK packet is sent from the server to the client to signal successful completion of a command.
    /// As of MySQL 5.7.5, OK packets are also used to indicate EOF, and EOF packets are deprecated.
    ///
    /// - Note: There are some exceptions to the above rule.
    ///
    /// The packet also contains a warning count.
    ///
    /// - Note: This packet type is also used for handling EOF packets, which still appear in binary
    ///   result sets sent by MySQL 5.7 servers.
    public struct OK_Packet: MySQLPacketCodable {
        public enum Error: Swift.Error {
            case missingFlag
            case invalidFlag(UInt8)
            case missingAffectedRows
            case missingLastInsertID
            case missingStatusFlags
            case missingWarningsCount
            case missingInfo
            case missingSessionStateChanges
        }
        
        /// `int<1>           header                  [00] or [fe] OK or EOF indicator`
        var type: UInt8
        
        /// `int<lenenc>      affected_rows           affected rows`
        var affectedRows: UInt64
        
        /// `int<lenenc>      last_insert_id          last insert-id`
        var lastInsertID: UInt64?
        
        /// `int<2>           status_flags            Status Flags`
        var statusFlags: StatusFlags
        
        /// `int<2>           warnings                number of warnings`
        var warningsCount: UInt16
        
        /// `string<lenenc>   info                    human readable status information`
        var info: String
        
        /// `string<lenenc>   session_state_changes   session state info`
        var sessionStateChanges: [SessionTrackedChange]?
        
        static func decode(from packet: inout MySQLPacket, capabilities: CapabilityFlags) throws -> OK_Packet {
            guard let flag = packet.payload.readInteger(endianness: .little, as: UInt8.self) else {
                throw Error.missingFlag
            }
            
            switch flag {
                case 0xfe where packet.payload.readableBytes < 8:
                    // Legacy EOF packet. Still need to recognize these.
                    guard let warnings = packet.payload.readInteger(endianness: .little, as: UInt16.self) else { throw Error.missingWarningsCount }
                    guard let statusFlags = packet.payload.readInteger(endianness: .little, as: StatusFlags.self) else { throw Error.missingStatusFlags }
                    return .init(type: 0xfe, affectedRows: 0, lastInsertID: nil, statusFlags: statusFlags, warningsCount: warnings, info: "", sessionStateChanges: nil)
                case 0x00:
                    // Standard OK packet.
                    guard let affectedRows = packet.payload.readLengthEncodedInteger() else { throw Error.missingAffectedRows }
                    guard let lastInsertID = packet.payload.readLengthEncodedInteger() else { throw Error.missingLastInsertID }
                    guard let statusFlags = packet.payload.readInteger(endianness: .little, as: StatusFlags.self) else { throw Error.missingStatusFlags }
                    guard let warnings = packet.payload.readInteger(endianness: .little, as: UInt16.self) else { throw Error.missingWarningsCount }
                    let info: String
                    var sessionStateChanges: [SessionTrackedChange]? = nil
                    
                    if capabilities.contains(.CLIENT_SESSION_TRACK), packet.payload.readableBytes > 0 {
                        guard let statusInfo = packet.payload.readLengthEncodedString() else { throw Error.missingInfo }
                        info = statusInfo
                        if statusFlags.contains(.SERVER_SESSION_STATE_CHANGED) {
                            guard var allStateData = packet.payload.readLengthEncodedSlice() else { throw Error.missingSessionStateChanges }
                            sessionStateChanges = []
                            while allStateData.readableBytes > 0 {
                                sessionStateChanges?.append(try .readOneChange(from: &allStateData))
                            }
                        }
                    } else {
                        guard let statusInfo = packet.payload.readString(length: packet.payload.readableBytes) else { throw Error.missingInfo }
                        info = statusInfo
                    }
                    return .init(type: 0x00,
                        affectedRows: affectedRows, lastInsertID: lastInsertID,
                        statusFlags: statusFlags, warningsCount: warnings,
                        info: info, sessionStateChanges: sessionStateChanges
                    )
                case let badFlag: throw Error.invalidFlag(badFlag)
            }
        }
        
        func encode(to packet: inout MySQLPacket, capabilities: MySQLProtocol.CapabilityFlags) throws {
            switch self.type {
                case 0xfe:
                    guard self.affectedRows == 0, self.lastInsertID == nil, self.info.isEmpty, self.sessionStateChanges == nil else {
                        throw Error.invalidFlag(self.type)
                    }
                    packet.payload.writeInteger(self.warningsCount, endianness: .little, as: UInt16.self)
                    packet.payload.writeInteger(self.statusFlags, endianness: .little, as: StatusFlags.self)
                case 0x00:
                    guard self.sessionStateChanges == nil ||
                          (capabilities.contains(.CLIENT_SESSION_TRACK) && self.statusFlags.contains(.SERVER_SESSION_STATE_CHANGED)) else {
                        throw Error.missingStatusFlags
                    }
                    packet.payload.writeLengthEncodedInteger(self.affectedRows)
                    packet.payload.writeLengthEncodedInteger(self.lastInsertID ?? 0)
                    packet.payload.writeInteger(self.statusFlags, endianness: .little, as: StatusFlags.self)
                    packet.payload.writeInteger(self.warningsCount, endianness: .little, as: UInt16.self)
                    if capabilities.contains(.CLIENT_SESSION_TRACK) {
                        packet.payload.writeLengthEncodedString(self.info)
                        if let sessionStateChanges = self.sessionStateChanges, self.statusFlags.contains(.SERVER_SESSION_STATE_CHANGED) {
                            var buffer = ByteBuffer()
                            for let change in sessionStateChanges {
                                change.write(to: &buffer)
                            }
                            packet.payload.writeLengthEncodedSlice(&buffer)
                        }
                    } else {
                        packet.payload.writeString(self.info)
                    }
                case let badFlag: throw Error.invalidFlag(badFlag)
            }
        }
    }
}
