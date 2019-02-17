extension MySQLPacket {
    public mutating func ok(capabilities: MySQLCapabilityFlags) throws -> OK {
        return try OK(payload: &self.payload, capabilities: capabilities)
    }
    
    /// 14.1.3.1 OK_Packet
    ///
    /// An OK packet is sent from the server to the client to signal successful completion of a command.
    /// As of MySQL 5.7.5, OK packes are also used to indicate EOF, and EOF packets are deprecated.
    ///
    /// If CLIENT_PROTOCOL_41 is set, the packet contains a warning count.
    public struct OK {
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
        
        /// int<lenenc>    affected_rows    affected rows
        public var affectedRows: UInt64
        
        /// int<lenenc>    last_insert_id    last insert-id
        public var lastInsertID: UInt64?
        
        /// int<2>    status_flags    Status Flags
        public var statusFlags: MySQLStatusFlags
        
        ///  int<2>    warnings    number of warnings
        public var warningsCount: UInt16?
        
        ///  string<lenenc>    info    human readable status information
        public var info: String
        
        /// string<lenenc>    session_state_changes    session state info
        public var sessionStateChanges: String?
        
        public init(payload: inout ByteBuffer, capabilities: MySQLCapabilityFlags) throws {
            guard let flag = payload.readInteger(endianness: .little, as: UInt8.self) else {
                throw Error.missingFlag
            }
            guard flag == 0xFE || flag == 0x00 else {
                throw Error.invalidFlag(flag)
            }
            
            guard let affectedRows = payload.readLengthEncodedInteger() else {
                throw Error.missingAffectedRows
            }
            self.affectedRows = affectedRows
            guard let lastInsertID = payload.readLengthEncodedInteger() else {
                throw Error.missingLastInsertID
            }
            self.lastInsertID = lastInsertID
            
            if capabilities.contains(.CLIENT_PROTOCOL_41) || capabilities.contains(.CLIENT_TRANSACTIONS) {
                guard let status = payload.readInteger(endianness: .little, as: UInt16.self) else {
                    throw Error.missingStatusFlags
                }
                self.statusFlags = .init(rawValue: status)
                if capabilities.contains(.CLIENT_PROTOCOL_41) {
                    guard let warningsCount = payload.readInteger(endianness: .little, as: UInt16.self) else {
                        throw Error.missingWarningsCount
                    }
                    self.warningsCount = warningsCount
                }
            } else {
                self.statusFlags = []
            }
            
            if capabilities.contains(.CLIENT_SESSION_TRACK) {
                if payload.readableBytes == 0 {
                    // entire packet has been read already
                    self.info = ""
                } else {
                    guard let info = payload.readLengthEncodedString() else {
                        throw Error.missingInfo
                    }
                    self.info = info
                    if self.statusFlags.contains(.SERVER_SESSION_STATE_CHANGED) {
                        guard let sessionStateChanges = payload.readLengthEncodedString() else {
                            throw Error.missingSessionStateChanges
                        }
                        self.sessionStateChanges = sessionStateChanges
                    }
                }
            } else {
                guard let info = payload.readString(length: payload.readableBytes) else {
                    throw Error.missingInfo
                }
                self.info = info
            }
        }
    }
}
