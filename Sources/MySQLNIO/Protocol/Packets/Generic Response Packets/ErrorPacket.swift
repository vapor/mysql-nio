import NIOCore

struct ErrorPacket {
    let errorCode: UInt16
    let kind: Kind

    enum Kind {
        case progressReporting(ProgressReporting)
        case error(Error)

        struct ProgressReporting {
            let stage: UInt8
            let maxStage: UInt8
            let progress: UInt24
            let progressInfo: String
        }

        struct Error {
            /// string<5>
            let sqlState: String?
            let errorMessage: String
        }
    }

    init?(from packet: inout ByteBuffer) {
        guard let header = packet.readInteger(as: UInt8.self), header == 0xFF else { return nil }
        guard let errorCode = packet.readInteger(endianness: .little, as: UInt16.self) else { return nil }
        self.errorCode = errorCode

        if errorCode == 0xFF_FF {
            guard let stage = packet.readInteger(as: UInt8.self) else { return nil }
            guard let maxStage = packet.readInteger(as: UInt8.self) else { return nil }
            guard let progressBytes = packet.readBytes(length: 3) else { return nil }
            let progress = progressBytes.reversed().reduce(UInt24.zero) { ($0 << 8) | numericCast($1) }
            guard let progressInfo = packet.readLengthPrefixedString(strategy: .mySQL) else { return nil }
            self.kind = .progressReporting(.init(stage: stage, maxStage: maxStage, progress: progress, progressInfo: progressInfo))
        } else {
            let sqlState: String?
            if let sqlStateMarker = packet.getInteger(at: packet.readerIndex, as: UInt8.self), sqlStateMarker == 0x23 {
                // The SQL state is prefixed with a "#" character
                packet.moveReaderIndex(forwardBy: 1)
                guard let sqlStateString = packet.readString(length: 5) else { return nil }
                sqlState = sqlStateString
            } else {
                sqlState = nil
            }
            // string<EOF>
            guard let errorMessage = packet.readString(length: packet.readableBytes) else { return nil }
            self.kind = .error(.init(sqlState: sqlState, errorMessage: errorMessage))
        }
    }
}
