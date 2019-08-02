extension MySQLProtocol {
    public struct ExecuteFlags: OptionSet, ExpressibleByIntegerLiteral {
        public static let CURSOR_TYPE_NO_CURSOR: ExecuteFlags = 0b0000_0000
        public static let CURSOR_TYPE_READ_ONLY: ExecuteFlags = 0b0000_0001
        public static let CURSOR_TYPE_FOR_UPDATE: ExecuteFlags = 0b0000_0010
        public static let CURSOR_TYPE_SCROLLABLE: ExecuteFlags = 0b0000_0100
        
        public var rawValue: UInt8
        
        public init(rawValue: UInt8) {
            self.rawValue = rawValue
        }
        
        public init(integerLiteral value: UInt8) {
            self.rawValue = value
        }
    }
    /// COM_STMT_EXECUTE asks the server to execute a prepared statement as identified by stmt-id.
    ///
    /// It sends the values for the placeholders of the prepared statement (if it contained any) in Binary Protocol Value form.
    /// The type of each parameter is made up of two bytes:
    /// - the type as in Protocol::ColumnType
    /// - a flag byte which has the highest bit set if the type is unsigned [80]
    ///
    /// The num-params used for this packet has to match the num_params of the COM_STMT_PREPARE_OK of the corresponding prepared statement.
    ///
    /// The server returns a COM_STMT_EXECUTE Response.
    ///
    /// https://dev.mysql.com/doc/internals/en/com-stmt-execute.html#packet-COM_STMT_EXECUTE
    public struct COM_STMT_EXECUTE: MySQLPacketEncodable {
        /// stmt-id
        public var statementID: UInt32
        
        /// flags
        public var flags: ExecuteFlags
        
        /// The values to bind
        public var values: [MySQLData]
        
        /// `MySQLPacketEncodable` conformance.
        public func encode(to packet: inout MySQLPacket, capabilities: CapabilityFlags) throws {
            /// [17] COM_STMT_EXECUTE
            packet.payload.writeInteger(0x17, endianness: .little, as: UInt8.self)
            packet.payload.writeInteger(self.statementID, endianness: .little)
            packet.payload.writeInteger(flags.rawValue, endianness: .little)
            /// iteration-count
            /// The iteration-count is always 1.
            packet.payload.writeInteger(0x01, endianness: .little, as: UInt32.self)
            if self.values.count > 0 {
                var nullBitmap = NullBitmap.comExecuteBitmap(count: self.values.count)
                for (i, value) in values.enumerated() {
                    switch value.buffer {
                    case .none: nullBitmap.setNull(at: i)
                    case .some: break
                    }
                }
                packet.payload.writeBytes(nullBitmap.bytes)
                
                /// new-params-bound-flag
                packet.payload.writeInteger(0x01, endianness: .little, as: UInt8.self)
                
                /// set value types
                for value in self.values {
                    packet.payload.writeInteger(value.type.rawValue, endianness: .little)
                    /// a flag byte which has the highest bit set if the type is unsigned [80]
                    if value.isUnsigned {
                        packet.payload.writeInteger(0b1000_0000, endianness: .little, as: UInt8.self)
                    } else {
                        packet.payload.writeInteger(0b0000_0000, endianness: .little, as: UInt8.self)
                    }
                }
                
                /// set values
                for value in self.values {
                    switch value.buffer {
                    case .none: break
                    case .some(var buffer):
                        if value.type.encodingLength == nil {
                            // TODO: make length encoded
                            packet.payload.writeInteger(numericCast(buffer.readableBytes), endianness: .little, as: UInt8.self)
                        }
                        packet.payload.writeBuffer(&buffer)
                    }
                }
            }
        }
    }
}
