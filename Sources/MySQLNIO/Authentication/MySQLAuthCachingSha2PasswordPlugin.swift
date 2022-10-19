import Crypto
import MiniRSACrypt
import Foundation
import NIOSSL

internal struct MySQLAuthPluginCachingSha2Password: MySQLAuthPluginResponder {
    init() {}
    
    enum State: Hashable {
        case initial
        case sentScramble(salt: [UInt8]) // awaiting OK, ERR, or fast auth response
        case requestedPubkey(salt: [UInt8]) // awaiting pubkey response
        case sentFinal // no further input is valid
    }
    
    var state: State = .initial
    
    func handle(pluginName: String, configuration: MySQLConnection.Configuration, isSecureConnection: Bool, data: [UInt8]) throws -> [UInt8]? {
        assert(pluginName == "caching_sha2_password")
        
        switch self.state {
        case .initial:
            guard data.count == 20 else {
                throw MySQLError.protocolError
            }
            
            guard let password = configuration.authentication.password, !password.isEmpty else {
                // Empty or unspecified password - return empty data.
                return []
            }
            
            /// [MariaDB knowledge base](https://mariadb.com/kb/en/caching_sha2_password-authentication-plugin/)
            ///
            ///     Encryption is XOR(SHA256(password), SHA256(seed, SHA256(SHA256(password))))
            ///
            /// - Note: This is exactly the same scramble that `mysql_native_password` does, except using
            ///   SHA-256 instead of SHA-1.
            let passwordSha256 = SHA256.hash(data: Array(password.utf8)),
                saltedPasswordSha256 = SHA256.hash(data: data + Array(SHA256.hash(data: Array(passwordSha256)))),
                passwordSha256XorSaltEtc = zip(passwordSha256, saltedPasswordSha256).map(^)
            
            self.state = .sentScramble(salt: data)
            return passwordSha256XorSaltEtc
        
        case .sentScramble(let salt):
            // If the server had responded to the scramble with OK or ERR, it would've been handled before getting here.
            // The input therefore must be a fast auth response, or it is invalid. The higher-layer auth logic has
            // stripped the `0x01` AuthMoreData prefix off the packet, so the first byte is the result value.
            guard data.count == 1 else {
                throw MySQLError.protocolError
            }
            switch data[0] {
            case 0x03: // fast_auth_success
                // The server will send OK next, this packet is just noise. Jump to end state.
                self.state = .sentFinal
                return nil
            case 0x04: // perform_full_authentication
                if isSecureConnection {
                    // Send password in cleartext.
                    self.state = .sentFinal
                    return Array((configuration.authentication.password ?? "").utf8) + [0]
                } else {
                    // Send a public key request
                    self.state = .requestedPubkey(salt: salt)
                    return [0x02]
                }
            default:
                throw MySQLError.protocolError
            }
        
        case .requestedPubkey(let salt):
            let rsaPubkey = try _RSA.Encryption.PublicKey(pemRepresentation: .init(decoding: data, as: UTF8.self))
            let proof = zip(salt, Array((configuration.authentication.password ?? "").utf8)).map(^)
            let encryptedProof = Array(try rsaPubkey.encrypt(proof, padding: .PKCS1_OAEP).rawRepresentation)
            
            self.state = .sentFinal
            return encryptedProof
        
        case .sentFinal:
            throw MySQLError.protocolError
        }
    }
}
