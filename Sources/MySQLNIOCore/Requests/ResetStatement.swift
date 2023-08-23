import Collections
import NIOCore

enum ResetStatement {
    struct Context {
        let statementId: Int
        let promise: EventLoopPromise<Void>
    }

    struct StateMachine {
        /// The defined states for statement prepare handling
        enum State {
            ///
            case done
            ///
            case failed(error: any Error)
        }
        
        private var state: State

        let context: Context
        
        mutating func handlePacketRead(_ packet: ByteBuffer) -> MySQLChannel.Handler.Reaction {
            fatalError()
        }
        
        mutating func teardownState(reason: any Swift.Error) {
            
        }
    }
}
