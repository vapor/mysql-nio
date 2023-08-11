import NIOCore
import Algorithms
import Crypto

extension MySQLBuiltinAuthHandlers {
    struct NativePassword: MySQLBuiltinAuthHandler {
        static var pluginName: String { "mysql_native_password" }
        
        mutating func processData(_ data: ByteBuffer, configuration: MySQLChannel.Configuration, connectionIsSecure: Bool) throws -> ByteBuffer? {
            guard case .ready = self.state else { preconditionFailure("Authentication logic state fault (handler received data too soon, too late, or more than once). Please report a bug.")}
            self.state = .done

            guard data.readableBytes == 20 else {
                throw MySQLCoreError.protocolViolation(debugDescription: "Invalid auth nonce")
            }
            
            let passwordHash = Insecure.SHA1.hash(data: Array((configuration.password ?? "").utf8))
            let nonceHash = Insecure.SHA1.hash(data: Array(chain(data.readableBytesView, Insecure.SHA1.hash(data: Array(passwordHash)))))
            let scramble = ByteBuffer(bytes: zip(passwordHash, nonceHash).map(^))
            
            return scramble
        }
        
        private var state: State = .ready
        
        enum State {
            case ready
            case done
        }
    }
}
