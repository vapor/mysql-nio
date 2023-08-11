import Algorithms
import NIOCore
import Foundation
import Crypto
import _CryptoExtras

extension MySQLBuiltinAuthHandlers {
    /// Implements MySQL's `caching_sha2_password` plugin
    ///
    /// This handler will send a request for an RSA public key if necessary.
    ///
    /// > Note: This plugin is the default for MySQL 8, but is not present in MySQL 5.7 and is unavailable
    ///   by default in MariaDB.
    struct CachingSHA2: MySQLBuiltinAuthHandler {
        static var pluginName: String { "caching_sha2_password" }
        
        mutating func processData(_ data: ByteBuffer, configuration: MySQLChannel.Configuration, connectionIsSecure: Bool) throws -> ByteBuffer? {
            switch self.state {
                case .awaitingNonce:
                    guard data.readableBytes == 20 else { throw MySQLCoreError.protocolViolation(debugDescription: "Invalid auth nonce") } // nonce must be 20 bytes exactly, even if we won't use it

                    if let password = configuration.password, !password.isEmpty {
                        // Use the nonce to generate and send a scramble for the "fast" auth step (cache lookup)
                        // The scramble is generated as: XOR(SHA256(password), SHA256(SHA256(SHA256(password)) + nonce))
                        let passwordHash = SHA256.hash(data: Array(password.utf8))
                        let nonceHash = SHA256.hash(data: Array(chain(SHA256.hash(data: Array(passwordHash)), data.readableBytesView)))
                        let scramble = ByteBuffer(bytes: zip(passwordHash, nonceHash).map(^))
                        
                        self.state = .sentFastAuth(nonce: connectionIsSecure ? .init() : data) // save off the nonce if we'll need it
                        return scramble
                    } else {
                        // If no password was provided, we don't need to bother with any of the steps, just send a zero byte.
                        self.state = .passwordSent
                        return .init(nullTerminatedString: "")
                    }
                
                case .sentFastAuth(nonce: let nonce):
                    guard data.readableBytes == 1, let status = data.readableBytesView.first.flatMap(FastAuthStatus.init(rawValue:))
                    else { throw MySQLCoreError.protocolViolation(debugDescription: "Invalid caching-sha2 fast-auth reply") }
                    
                    switch status {
                    case .success:
                        self.state = .passwordSent // jump to waiting for the final OK packet
                        return nil

                    case .performFullAuth where connectionIsSecure: // Encrypted connection, send password in plain text
                        self.state = .passwordSent
                        return .init(nullTerminatedString: configuration.password)

                    case .performFullAuth: // Insecure connection, request key to encrypt password with
                        self.state = .requestedServerKey(nonce: nonce)
                        return .init(bytes: [Self.requestEncryptionKeyMarker])
                    }
                
                case .requestedServerKey(nonce: let nonce):
                    precondition(nonce.readableBytes == 20, "Authentication logic state fault (nonce not saved properly). Please report a bug.")
                    
                    guard let pemString = data.getString(at: data.readerIndex, length: data.readableBytes)
                    else { throw MySQLCoreError.protocolViolation(debugDescription: "Invalid RSA public key from server") }
                    
                    // The cleartext must be XOR'd with the nonce before encrypting. Always such a stitch how this
                    // isn't documented anywhere, not even in comments in the server source code...
                    let key = try _RSA.Encryption.PublicKey(pemRepresentation: pemString)
                    let saltedPassword = Data(zip(chain((configuration.password ?? "").utf8, [0]), nonce.readableBytesView.cycled()).map(^))
                    let encryptedData = ByteBuffer(bytes: try key.encrypt(saltedPassword, padding: .PKCS1_OAEP))
                    
                    self.state = .passwordSent
                    return encryptedData

                case .passwordSent:
                    // Anything received in this state is an error
                    throw MySQLCoreError.protocolViolation(debugDescription: "Should not receive auth data after sending final reply")
            }
        }
        
        // MARK: Implementation
        
        /// Current state
        private var state: State = .awaitingNonce
        
        /// Possible responses to the fast-auth scramble
        private enum FastAuthStatus: UInt8 {
            case success = 0x3 // fast_auth_success
            case performFullAuth = 0x4 // perform_full_authentication
        }
        
        /// The "request server public key for encryption" marker value.
        private static var requestEncryptionKeyMarker: UInt8 { 0x02 } // request_public_key
        
        /// Yep, even this handler is a FSM! As usual, these are the possible states of the machine.
        private enum State {
            /// Awaiting first set of scramble data from server
            case awaitingNonce
            
            /// Sent fast auth scramble, awaiting result
            case sentFastAuth(nonce: ByteBuffer)
            
            /// Fast auth failed on insecure connection, awaiting RSA public key
            case requestedServerKey(nonce: ByteBuffer)
            
            /// Fast auth succeeded or password sent for full auth, awaiting final OK
            case passwordSent
        }
    }
}
