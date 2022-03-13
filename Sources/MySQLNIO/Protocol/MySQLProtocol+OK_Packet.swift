extension MySQLProtocol {
    /// 14.1.3.1 `OK_Packet`
    ///
    /// An OK packet is sent from the server to the client to signal successful completion of a command.
    /// As of MySQL 5.7.5, OK packets are also used to indicate EOF, and EOF packets are deprecated.
    ///
    /// If CLIENT_PROTOCOL_41 is set, the packet contains a warning count.
    public struct OK_Packet: MySQLPacketDecodable {
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
        
        /// `int<lenenc>      affected_rows           affected rows`
        public var affectedRows: UInt64
        
        /// `int<lenenc>      last_insert_id          last insert-id`
        public var lastInsertID: UInt64?
        
        /// `int<2>           status_flags            Status Flags`
        public var statusFlags: StatusFlags
        
        /// `int<2>           warnings                number of warnings`
        public var warningsCount: UInt16?
        
        /// `string<lenenc>   info                    human readable status information`
        public var info: String
        
        /// `string<lenenc>   session_state_changes   session state info`
        public var sessionStateChanges: String?
        
        public static func decode(from packet: inout MySQLPacket, capabilities: CapabilityFlags) throws -> OK_Packet {
            guard let flag = packet.payload.readInteger(endianness: .little, as: UInt8.self) else {
                throw Error.missingFlag
            }
            guard flag == 0xFE || flag == 0x00 else {
                throw Error.invalidFlag(flag)
            }
            
            guard let affectedRows = packet.payload.readLengthEncodedInteger() else {
                throw Error.missingAffectedRows
            }
            guard let lastInsertID = packet.payload.readLengthEncodedInteger() else {
                throw Error.missingLastInsertID
            }
            
            let statusFlags: StatusFlags
            let warningsCount: UInt16?
            if capabilities.contains(.CLIENT_PROTOCOL_41) || capabilities.contains(.CLIENT_TRANSACTIONS) {
                guard let status = packet.payload.readInteger(endianness: .little, as: UInt16.self) else {
                    throw Error.missingStatusFlags
                }
                statusFlags = .init(rawValue: status)
                if capabilities.contains(.CLIENT_PROTOCOL_41) {
                    guard let w = packet.payload.readInteger(endianness: .little, as: UInt16.self) else {
                        throw Error.missingWarningsCount
                    }
                    warningsCount = w
                } else {
                    warningsCount = nil
                }
            } else {
                statusFlags = []
                warningsCount = nil
            }
            
            let info: String
            let sessionStateChanges: String?
            if capabilities.contains(.CLIENT_SESSION_TRACK) {
                if packet.payload.readableBytes == 0 {
                    // entire packet has been read already
                    info = ""
                    sessionStateChanges = nil
                } else {
                    guard let s = packet.payload.readLengthEncodedString() else {
                        throw Error.missingInfo
                    }
                    info = s
                    if statusFlags.contains(.SERVER_SESSION_STATE_CHANGED) {
                        guard let s = packet.payload.readLengthEncodedString() else {
                            throw Error.missingSessionStateChanges
                        }
                        sessionStateChanges = s
                    } else {
                        sessionStateChanges = nil
                    }
                }
            } else {
                guard let i = packet.payload.readString(length: packet.payload.readableBytes) else {
                    throw Error.missingInfo
                }
                info = i
                sessionStateChanges = nil
            }
            
            return .init(
                affectedRows: affectedRows,
                lastInsertID: lastInsertID,
                statusFlags: statusFlags,
                warningsCount: warningsCount,
                info: info,
                sessionStateChanges: sessionStateChanges
            )
        }
    }
}
