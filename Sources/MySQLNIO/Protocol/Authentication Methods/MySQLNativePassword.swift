import Algorithms
import Crypto
import NIOCore

struct MySQLNativePassword: AuthenticationMethod, ~Copyable {
    static let name = "mysql_native_password"
    var stateMachine = StateMachine()
    mutating func processData(_ data: ByteBuffer, password: String?, connectionIsSecure _: Bool) throws -> ByteBuffer? {
        try self.stateMachine.processData(data, password: password)
    }
}

extension MySQLNativePassword {
    @usableFromInline
    struct StateMachine: ~Copyable {
        @usableFromInline
        enum State: ~Copyable {
            case uninitialized
            case end
        }
        @usableFromInline
        var state: State

        init() {
            self.state = .uninitialized
        }

        private init(_ state: consuming State) {
            self.state = state
        }

        enum Error: Swift.Error {
            case invalidSeed
        }

        mutating func processData(_ data: ByteBuffer, password: String?) throws -> ByteBuffer {
            switch consume self.state {
            case .uninitialized:
                self = .end
                guard data.readableBytes == 20 else { throw Error.invalidSeed }
                let passwordHash = Insecure.SHA1.hash(data: Array((password ?? "").utf8))
                let seedHash = Insecure.SHA1.hash(data: Array(chain(data.readableBytesView, Insecure.SHA1.hash(data: Array(passwordHash)))))
                return ByteBuffer(bytes: zip(passwordHash, seedHash).map(^))
            case .end:
                preconditionFailure("Received data after authentication completed")
            }
        }

        private static var end: Self {
            StateMachine(.end)
        }
    }
}
