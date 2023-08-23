import Collections
import NIOCore

enum ExecuteStatement {
    struct Context {
        let statementId: Int
        let promise: EventLoopPromise<MySQLResultsetStream>
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
