import Collections
import NIOCore

enum PrepareStatement {
    struct Context {
        let attributes: OrderedDictionary<String, MySQLProtocolValue>
        let sql: String
        let promise: EventLoopPromise<Int>
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
