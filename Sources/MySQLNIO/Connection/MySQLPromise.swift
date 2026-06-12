public import NIOCore

@usableFromInline
enum MySQLPromise<T: Sendable>: Sendable {
    case nio(EventLoopPromise<T>)
    case swift(CheckedContinuation<T, any Error>)
    case forget

    func succeed(_ t: T) {
        switch self {
        case .nio(let eventLoopPromise):
            eventLoopPromise.succeed(t)
        case .swift(let checkedContinuation):
            checkedContinuation.resume(returning: t)
        case .forget:
            break
        }
    }

    func fail(_ error: any Error) {
        switch self {
        case .nio(let eventLoopPromise):
            eventLoopPromise.fail(error)
        case .swift(let checkedContinuation):
            checkedContinuation.resume(throwing: error)
        case .forget:
            break
        }
    }
}
