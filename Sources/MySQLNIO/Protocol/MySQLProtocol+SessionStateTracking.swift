extension MySQLProtocol {
    
    /// State-change information is sent in the OK packet as a array of state-change blocks
    ///
    /// https://dev.mysql.com/doc/internals/en/packet-OK_Packet.html#cs-sect-packet-ok-sessioninfo
    struct SessionStateChangeType: RawRepresentable, Equatable, CustomStringConvertible {

        /// one or more system variables changed
        static let SESSION_TRACK_SYSTEM_VARIABLES = SessionStateChangeType(0x00)
        
        /// schema changed
        static let SESSION_TRACK_SCHEMA = SessionStateChangeType(0x01)

        /// "track state change" changed
        static let SESSION_TRACK_STATE_CHANGE = SessionStateChangeType(0x02)

        /// "track GTIDs" changed
        static let SESSION_TRACK_GTIDS = SessionStateChangeType(0x03)

        /// transaction characteristics changed
        static let SESSION_TRACK_TRANSACTION_CHARACTERISTICS = SessionStateChangeType(0x04)

        /// transaction activity state changed
        static let SESSION_TRACK_TRANSACTION_STATE = SessionStateChangeType(0x05)
        
        let rawValue: UInt8
        
        init?(rawValue: UInt8) {
            self.init(rawValue)
        }
        
        init(_ rawValue: UInt8) {
            self.rawValue = rawValue
        }
        
        var description: String {
            switch self.rawValue {
                case SESSION_TRACK_SYSTEM_VARIABLES: return "SESSION_TRACK_SYSTEM_VARIABLES"
                case SESSION_TRACK_SCHEMA: return "SESSION_TRACK_SCHEMA"
                case SESSION_TRACK_STATE_CHANGE: return "SESSION_TRACK_STATE_CHANGE"
                case SESSION_TRACK_GTIDS: return "SESSION_TRACK_GTIDS"
                case SESSION_TRACK_TRANSACTION_CHARACTERISTICS: return "SESSION_TRACK_TRANSACTION_CHARACTERISTICS"
                case SESSION_TRACK_TRANSACTION_STATE: return "SESSION_TRACK_TRANSACTION_STATE"
                case let value: return "SESSION_TRACK_UNKNOWN(\(value))"
            }
        }
    }
    
    struct SessionTrackedSystemVar {
        let name: String
        let value: String
    }
    
    struct SessionTrackedSchema {
        let schema: String
    }
    
    struct SessionTrackedTracking {
        let trackingEnabled: Bool
    }
    
    struct SessionTrackedGTID {
        let gtid: String
    }
    
    struct SessionTrackedTransactionCharacteristic {
        let recreateTransactionSql: String
    }
    
    struct SessionTrackedTransactionState: RawRepresentable, Equatable {
        enum Error: Swift.Error {
            case invalidRawSequence
        }
        
        /// true == autocommit transaction, false == explicit transaction, nil == no transaction
        let implicitTransacton: Bool?
        let nontransactionalReadFlag: Bool
        let transactionalReadFlag: Bool
        let unsafeWritesFlag: Bool
        let transactionalWritesFlag: Bool
        let unsafeStatementsFlag: Bool
        let resultSetsSentFlag: Bool
        let lockTablesFlag: Bool
        
        init?(rawValue: String) {
            var rawIter = rawSequence.makeIterator()
            func check(_ c: Character?, for valid: Character) throws -> Bool { switch c {
                case valid, "_": return c == valid
                default: throw Error.invalidRawSequence
            } }
            switch rawIter.next() {
                case "_" where rawSequence == "________": self.implicitTransacton = nil
                case "T": self.implicitTransacton = false
                case "I": self.implicitTransacton = true
                default: throw Error.invalidRawSequence
            }
            self.nontransactionalReadFlag = try check(rawIter.next(), for: "r")
            self.transactionalReadFlag = try check(rawIter.next(), for: "R")
            self.unsafeWritesFlag = try check(rawIter.next(), for: "w")
            self.transactionalWritesFlag = try check(rawIter.next(), for: "W")
            self.unsafeStatementsFlag = try check(rawIter.next(), for: "s")
            self.resultSetsSentFlag = try check(rawIter.next(), for: "S")
            self.lockTablesFlag = try check(rawIter.next(), for: "L")
            guard rawIter.next() == nil else { throw Error.invalidRawSequence }
        }
        
        var rawValue: String {
            guard let implicitTransacton = self.implicitTransacton else { return "________" }
            return """
                \(self.implicitTransacton ? "I" : "T")\
                \(self.nontransactionalReadFlag ? "r" : "_")\
                \(self.transactionalReadFlag ? "R" : "_")\
                \(self.unsafeWritesFlag ? "w" : "_")\
                \(self.transactionalWritesFlag ? "W" : "_")\
                \(self.unsafeStatementsFlag ? "s" : "_")\
                \(self.resultSetsSentFlag ? "S" : "_")\
                \(self.lockTablesFlag ? "L" : "_")
            """
        }
    }
    
    enum SessionTrackedChange {
        case systemVars([SessionTrackedSystemVar])
        case schema(SessionTrackedSchema)
        case trackingFlag(SessionTrackedTracking)
        case gtid(SessionTrackedGTID)
        case transactionCharacteristic(SessionTrackedTransactionCharacteristic)
        case transactionState(SessionTrackedTransactionState)
        case unknown(SessionStateChangeType, ByteBuffer)
    }
    
}

extension MySQLProtocol.SessionTrackedChange {
    enum Error: Swift.Error {
        case corruptSessionTrackData
    }
    
    static func readOneChange(from buffer: inout ByteBuffer) throws -> SessionTrackedChange {
        guard let stateType = buffer.readInteger(endianness: .little, as: SessionStateChangeType.self),
              var stateData = buffer.readLengthEncodedSlice()
        else {
            throw Error.corruptSessionTrackData
        }
        let result = try self.decode(from: &stateData, type: stateType)
        guard stateData.readableBytes == 0 else { throw Error.corruptSessionTrackData }
        return result
    }
    
    private static func decode(from buffer: inout ByteBuffer, type: SessionStateChangeType) throws -> SessionTrackedChange {
        switch stateType {
        case .SESSION_TRACK_SYSTEM_VARIABLES:
            var pairs = [SessionTrackedSystemVar]()
            while buffer.readableBytes > 0 {
                guard let name = buffer.readLengthEncodedString(), let value = buffer.readLengthEncodedString() else {
                    throw Error.corruptSessionTrackData
                }
                pairs.append(.init(name: name, value: value))
            }
            return .systemVars(pairs)
        case .SESSION_TRACK_SCHEMA:
            guard let schema = buffer.readLengthEncodedString() else { throw Error.corruptSessionTrackData }
            return .schema(.init(schema: schema))
        case .SESSION_TRACK_STATE_CHANGE:
            guard let str = buffer.readLengthEncodedString(), str.count == 1 else { throw Error.corruptSessionTrackData }
            return .trackingFlag(.init(trackingEnabled: str == "1"))
        case .SESSION_TRACK_GTIDS:
            guard let gtid = buffer.readLengthEncodedString() else { throw Error.corruptSessionTrackData }
            return .gtid(.init(gtid: gtid))
        case .SESSION_TRACK_TRANSACTION_CHARACTERISTICS:
            guard let sql = buffer.readLengthEncodedString() else { throw Error.corruptSessionTrackData }
            return .transactionCharacteristic(.init(recreateTransactionSql: sql))
        case .SESSION_TRACK_TRANSACTION_STATE:
            guard let sequence = buffer.readLengthEncodedString() else { throw Error.corruptSessionTrackData }
            return try .transactionState(.init(parsing: sequence))
        case let unknown:
            return .unknown(unknown, buffer)
        }
    }
    
    func write(to buffer: inout ByteBuffer) {
        var scratchBuffer = ByteBuffer()
        
        switch self {
            case .systemVars(let sysvars):
                buffer.writeInteger(SessionStateChangeType.SESSION_TRACK_SYSTEM_VARIABLES)
                for pair in sysvars {
                    scratchBuffer.writeLengthEncodedString(pair.name)
                    scratchBuffer.writeLengthEncodedString(pair.value)
                }
                buffer.writeLengthEncodedSlice(&scratchBuffer)
            case .schema(let info):
                buffer.writeInteger(SessionStateChangeType.SESSION_TRACK_SCHEMA)
                scratchBuffer.writeLengthEncodedString(info.schema)
                buffer.writeLengthEncodedSlice(&scratchBuffer)
            case .trackingFlag(let info):
                buffer.writeInteger(SessionStateChangeType.SESSION_TRACK_STATE_CHANGE)
                buffer.writeBytes([0x2, 0x1, info.trackingEnabled ? 0x31 : 0x30])
            case .gtid(let info):
                buffer.writeInteger(SessionStateChangeType.SESSION_TRACK_GTIDS)
                scratchBuffer.writeLengthEncodedString(info.gtid)
                buffer.writeLengthEncodedSlice(&scratchBuffer)
            case .transactionCharacteristic(let info):
                buffer.writeInteger(SessionStateChangeType.SESSION_TRACK_TRANSACTION_CHARACTERISTICS)
                scratchBuffer.writeLengthEncodedString(info.recreateTransactionSql)
                buffer.writeLengthEncodedSlice(&scratchBuffer)
            case .transactionState(let info):
                buffer.writeInteger(SessionStateChangeType.SESSION_TRACK_TRANSACTION_STATE)
                scratchBuffer.writeLengthEncodedString(info.rawValue)
                buffer.writeLengthEncodedSlice(&scratchBuffer)
            case .unknown(let type, var slice):
                buffer.writeInteger(type)
                buffer.writeLengthEncodedSlice(&slice)
        }
    }
}
