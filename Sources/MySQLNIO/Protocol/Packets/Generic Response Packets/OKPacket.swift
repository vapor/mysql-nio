import NIOCore

struct OKPacket {
    let affectedRows: UInt64
    let lastInsertID: UInt64
    let serverStatus: ServerStatusFlags
    let warningCount: UInt16
    let info: String?
    // TODO: https://mariadb.com/docs/server/reference/clientserver-protocol/4-server-response-packets/ok_packet#session-state-info
    let sessionStateInfo: String?

    enum DecodingError: Error {
        case invalidLength(Int)
        case missingHeader
        case invalidHeader(UInt8)
        case missingAffectedRows
        case missingLastInsertID
        case missingServerStatus
        case missingWarningCount
    }

    init(from packet: inout ByteBuffer, capabilities: MySQLCapabilities) throws(DecodingError) {
        // In order to ensure an OK packet with EOF marker can be reliably distinguished from a text resultset data row,
        // an OK packet may not be larger than 2²⁴-1 bytes. The only place where this is clearly documented is the source code:
        // https://github.com/mysql/mysql-server/blob/8.0/sql/protocol_classic.cc#L955
        guard (7...((1 << 24) - 1)).contains(packet.readableBytes) else { throw .invalidLength(packet.readableBytes) }
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
        let info = packet.readLengthPrefixedString(strategy: .mySQL)
        let sessionStateInfo: String? =
            if serverStatus.contains(.serverSessionStateChanged) && capabilities.contains(.clientSessionTrack) {
                packet.readLengthPrefixedString(strategy: .mySQL)
            } else {
                nil
            }
        self.affectedRows = affectedRows
        self.lastInsertID = lastInsertID
        self.serverStatus = serverStatus
        self.warningCount = warningCount
        self.info = info
        self.sessionStateInfo = sessionStateInfo
    }

    package init(
        affectedRows: UInt64,
        lastInsertID: UInt64,
        serverStatus: ServerStatusFlags,
        warningCount: UInt16,
        info: String?,
        sessionStateInfo: String?
    ) {
        self.affectedRows = affectedRows
        self.lastInsertID = lastInsertID
        self.serverStatus = serverStatus
        self.warningCount = warningCount
        self.info = info
        self.sessionStateInfo = sessionStateInfo
    }

    package func write(to packet: inout ByteBuffer, capabilities: MySQLCapabilities) {
        packet.writeInteger(0x00, as: UInt8.self)
        packet.writeEncodedInteger(self.affectedRows, strategy: .mySQL)
        packet.writeEncodedInteger(self.lastInsertID, strategy: .mySQL)
        packet.writeInteger(self.serverStatus.rawValue, endianness: .little, as: UInt16.self)
        packet.writeInteger(self.warningCount, endianness: .little, as: UInt16.self)
        if let info = self.info {
            packet.writeLengthPrefixedString(info, strategy: .mySQL)
        }
        if let sessionStateInfo = self.sessionStateInfo, capabilities.contains(.clientSessionTrack) {
            packet.writeLengthPrefixedString(sessionStateInfo, strategy: .mySQL)
        }
    }
}
