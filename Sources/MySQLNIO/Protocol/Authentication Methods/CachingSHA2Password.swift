import Algorithms
import Crypto
import NIOCore
import _CryptoExtras

struct CachingSHA2Password: AuthenticationMethod, ~Copyable {
    static let name = "caching_sha2_password"
    var stateMachine = StateMachine()
    mutating func processData(_ data: ByteBuffer, password: String?, connectionIsSecure: Bool) throws -> ByteBuffer? {
        try self.stateMachine.processData(data, password: password, connectionIsSecure: connectionIsSecure)
    }
}

extension CachingSHA2Password {
    @usableFromInline
    struct StateMachine: ~Copyable {
        @usableFromInline
        enum State: ~Copyable {
            case uninitialized
            case fastAuthentication(nonce: ByteBuffer)
            case publicKey(nonce: ByteBuffer)
            case end
        }
        @usableFromInline
        var state: State

        enum FastAuthenticationResult: UInt8 {
            case success = 0x03
            case `continue` = 0x04
        }

        init() {
            self.state = .uninitialized
        }

        private init(_ state: consuming State) {
            self.state = state
        }

        enum Error: Swift.Error {
            case invalidSeed
            case invalidResponse
            case invalidPublicKey
        }

        mutating func processData(_ data: ByteBuffer, password: String?, connectionIsSecure: Bool) throws -> ByteBuffer? {
            switch consume self.state {
            case .uninitialized:
                self = .fastAuthentication(nonce: connectionIsSecure ? .init() : data)
                if let password {
                    guard data.readableBytes == 20 else { throw Error.invalidSeed }
                    let passwordHash = SHA256.hash(data: Array(password.utf8))
                    let seedHash = SHA256.hash(data: Array(chain(SHA256.hash(data: Array(passwordHash)), data.readableBytesView)))
                    return ByteBuffer(bytes: zip(passwordHash, seedHash).map(^))
                } else {
                    return ByteBuffer(bytes: [0x00])
                }
            case .fastAuthentication(let nonce):
                guard data.readableBytes == 2,
                    let header = data.getInteger(at: data.readerIndex, as: UInt8.self), header == 0x01,
                    let resultByte = data.getInteger(at: data.readerIndex + 1, as: UInt8.self),
                    let result = FastAuthenticationResult(rawValue: resultByte)
                else {
                    self = .end
                    throw Error.invalidResponse
                }
                switch result {
                case .success:
                    self = .end
                    return nil
                case .continue where connectionIsSecure:
                    self = .end
                    var emptyPassword = ByteBuffer()
                    emptyPassword.writeNullTerminatedString(password ?? "")
                    return emptyPassword
                case .continue:
                    self = .publicKey(nonce: nonce)
                    return ByteBuffer(bytes: [0x02])
                }
            case .publicKey(let nonce):
                self = .end
                guard
                    let header = data.getInteger(at: data.readerIndex, as: UInt8.self), header == 0x01,
                    let pemString = data.getString(at: data.readerIndex + 1, length: data.readableBytes - 1),
                    let key = try? _RSA.Encryption.PublicKey(pemRepresentation: pemString)
                else {
                    throw Error.invalidPublicKey
                }
                let saltedPassword = Array(zip(chain((password ?? "").utf8, [0]), nonce.readableBytesView.cycled()).map(^))
                return ByteBuffer(bytes: try key.encrypt(saltedPassword, padding: .PKCS1_OAEP))
            case .end:
                preconditionFailure("Received data after authentication completed")
            }
        }

        private static func fastAuthentication(nonce: ByteBuffer) -> Self {
            StateMachine(.fastAuthentication(nonce: nonce))
        }

        private static func publicKey(nonce: ByteBuffer) -> Self {
            StateMachine(.publicKey(nonce: nonce))
        }

        private static var end: Self {
            StateMachine(.end)
        }
    }
}
