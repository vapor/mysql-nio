import NIOCore
import OrderedCollections

/// A MySQL wire protocol generic "success"/"complete" packet.
///
/// The protocol calls this `OK_Packet`.
/// In the 5.7+ protocol (i.e. when the ``MySQLCapabilities/clientDeprecateEOF`` capability has been negotiated),
/// an incoming packet is an OK packet if it starts with the `0x00` or `0xfe` marker bytes and is at least 7 bytes long.
///
/// If the ``MySQLCapabilities/clientSessionTrack`` capability has been negotiated,
/// the packet may contain additional server state data.
/// We recognize all six currently defined state record types but currently interpret only some of them.
struct OKPacket {
    let affectedRows: Int
    let lastInsertID: UInt64
    let serverStatus: ServerStatusFlags
    let warningCount: UInt16
    let info: String?
    // MARK: - Session state info
    let updatedSettings: OrderedDictionary<String, String>
    let newSchema: String?
    let generalStateChange: Bool

    enum DecodingError: Error {
        case invalidLength(Int)
        case missingHeader
        case invalidHeader(UInt8)
        case missingAffectedRows
        case missingLastInsertID
        case missingServerStatus
        case missingWarningCount
        case missingSessionStateInfo
    }

    init(from packet: inout ByteBuffer, capabilities: MySQLCapabilities) throws(DecodingError) {
        // In order to ensure an OK packet with EOF marker can be reliably distinguished from a text resultset data row,
        // an OK packet may not be larger than 2²⁴-1 bytes. The only place where this is clearly documented is the source code:
        // https://github.com/mysql/mysql-server/blob/8.0/sql/protocol_classic.cc#L955
        guard (7...Int(UInt24.max)).contains(packet.readableBytes) else { throw .invalidLength(packet.readableBytes) }
        guard let header = packet.readInteger(as: UInt8.self) else { throw .missingHeader }
        if capabilities.contains(.clientDeprecateEOF) {
            guard header == 0x00 else { throw .invalidHeader(header) }
        } else {
            guard header == 0x00 || header == 0xFE else { throw .invalidHeader(header) }
        }
        guard let affectedRows = packet.readEncodedInteger(as: UInt64.self, strategy: .mySQL) else { throw .missingAffectedRows }
        guard let lastInsertID = packet.readEncodedInteger(as: UInt64.self, strategy: .mySQL) else { throw .missingLastInsertID }
        guard let serverStatusRawValue = packet.readInteger(endianness: .little, as: UInt16.self) else { throw .missingServerStatus }
        let serverStatus = ServerStatusFlags(rawValue: serverStatusRawValue)
        guard let warningCount = packet.readInteger(endianness: .little, as: UInt16.self) else { throw .missingWarningCount }

        var info: String? = nil
        var newSchema: String? = nil
        var updatedSettings: OrderedDictionary<String, String> = [:]
        var generalStateChange = false
        if capabilities.contains(.clientSessionTrack) {
            if serverStatus.contains(.serverSessionStateChanged) || packet.readableBytes > 0 {
                info = packet.readLengthPrefixedString(strategy: .mySQL)
            }
            if serverStatus.contains(.serverSessionStateChanged) {
                guard var stateData = packet.readLengthPrefixedSlice(strategy: .mySQL) else { throw .missingSessionStateInfo }
                while stateData.readableBytes > 0 {
                    guard let type = stateData.readInteger(as: UInt8.self) else { throw .missingSessionStateInfo }
                    guard var data = stateData.readLengthPrefixedSlice(strategy: .mySQL) else { throw .missingSessionStateInfo }
                    switch SessionTrackingRecordType(rawValue: type) {
                    case .systemSetting:
                        guard
                            let name = data.readLengthPrefixedString(strategy: .mySQL),
                            let value = data.readLengthPrefixedString(strategy: .mySQL)
                        else {
                            throw .missingSessionStateInfo
                        }
                        updatedSettings[name] = value
                    case .schema:
                        guard let trackedNewSchema = data.readLengthPrefixedString(strategy: .mySQL) else { throw .missingSessionStateInfo }
                        newSchema = trackedNewSchema
                    case .stateChange:
                        guard let flag = data.readInteger(endianness: .little, as: UInt8.self) else { throw .missingSessionStateInfo }
                        generalStateChange = (flag != 0)
                    default: break  // we don't track any of the other record types at this time, ignore 'em
                    }
                }
            }
        } else {
            info = packet.readString(length: packet.readableBytes)
        }
        self.affectedRows = Int(affectedRows)
        self.lastInsertID = lastInsertID
        self.serverStatus = serverStatus
        self.warningCount = warningCount
        self.info = info
        self.newSchema = newSchema
        self.updatedSettings = updatedSettings
        self.generalStateChange = generalStateChange
    }

    package init(
        affectedRows: Int,
        lastInsertID: UInt64,
        serverStatus: ServerStatusFlags,
        warningCount: UInt16,
        info: String?,
        newSchema: String?,
        updatedSettings: OrderedDictionary<String, String>,
        generalStateChange: Bool
    ) {
        self.affectedRows = affectedRows
        self.lastInsertID = lastInsertID
        self.serverStatus = serverStatus
        self.warningCount = warningCount
        self.info = info
        self.newSchema = newSchema
        self.updatedSettings = updatedSettings
        self.generalStateChange = generalStateChange
    }

    package func write(to packet: inout ByteBuffer, capabilities: MySQLCapabilities) {
        packet.writeInteger(0x00, as: UInt8.self)
        packet.writeEncodedInteger(self.affectedRows, strategy: .mySQL)
        packet.writeEncodedInteger(self.lastInsertID, strategy: .mySQL)
        packet.writeInteger(self.serverStatus.rawValue, endianness: .little, as: UInt16.self)
        packet.writeInteger(self.warningCount, endianness: .little, as: UInt16.self)
        if capabilities.contains(.clientSessionTrack) {
            if let info = self.info { packet.writeLengthPrefixedString(info, strategy: .mySQL) }
            if self.serverStatus.contains(.serverSessionStateChanged) {
                var stateBuf = ByteBuffer()
                for (key, value) in self.updatedSettings {
                    stateBuf.writeInteger(SessionTrackingRecordType.systemSetting.rawValue, endianness: .little)
                    stateBuf.writeLengthPrefixedString(key, strategy: .mySQL)
                    stateBuf.writeLengthPrefixedString(value, strategy: .mySQL)
                }
                if let newSchema = self.newSchema {
                    stateBuf.writeInteger(SessionTrackingRecordType.schema.rawValue, endianness: .little)
                    stateBuf.writeLengthPrefixedString(newSchema, strategy: .mySQL)
                }
                if self.generalStateChange {
                    stateBuf.writeInteger(SessionTrackingRecordType.stateChange.rawValue, endianness: .little)
                    stateBuf.writeLengthPrefixedBuffer(.init(integer: 1, as: UInt8.self), strategy: .mySQL)
                }
                packet.writeLengthPrefixedBuffer(stateBuf, strategy: .mySQL)
            }
        } else {
            if let info = self.info { packet.writeString(info) }
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
