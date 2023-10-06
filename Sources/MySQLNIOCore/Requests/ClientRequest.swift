import Logging
import NIOCore
import NIOTLS
import Collections

enum ClientRequest {
    case ping(EventLoopPromise<Void>)
    case getStatistics(EventLoopPromise<String>)
    case resetAllState(EventLoopPromise<Void>)
    case plainQuery(PlainQuery.Context)
    case prepareStatement(PrepareStatement.Context)
    case executeStatement(ExecuteStatement.Context)
    case fetchCursorData(FetchCursorData.Context)
    case resetStatement(ResetStatement.Context)
    case deallocateStatement(DeallocateStatement.Context)
    case quit
}

extension MySQLChannel {
    func ping() -> EventLoopFuture<Void> {
        let promise = self.eventLoop.makePromise(of: Void.self)
        
        self.channel.write(ClientRequest.ping(promise), promise: nil)
        return promise.futureResult
    }

    func getStatistics() -> EventLoopFuture<String> {
        let promise = self.eventLoop.makePromise(of: String.self)
        
        self.channel.write(ClientRequest.getStatistics(promise), promise: nil)
        return promise.futureResult
    }

    func resetConnection() -> EventLoopFuture<Void> {
        let promise = self.eventLoop.makePromise(of: Void.self)
        
        self.channel.write(ClientRequest.resetAllState(promise), promise: nil)
        return promise.futureResult
    }

    func query(sql: String) -> EventLoopFuture<MySQLResultsetStream> {
        let promise = self.eventLoop.makePromise(of: MySQLResultsetStream.self)
        
        self.channel.write(ClientRequest.plainQuery(.init(attributes: [:], sql: sql, promise: promise)), promise: nil)
        return promise.futureResult
    }

    func prepare(statement: String) -> EventLoopFuture<Int> {
        let promise = self.eventLoop.makePromise(of: Int.self)
        
        self.channel.write(ClientRequest.prepareStatement(.init(attributes: [:], sql: statement, promise: promise)), promise: nil)
        return promise.futureResult
    }

    func execute(statement: String) -> EventLoopFuture<MySQLResultsetStream> {
        let promise = self.eventLoop.makePromise(of: MySQLResultsetStream.self)
        
        self.channel.write(ClientRequest.executeStatement(.init(statementId: Int(statement)!, promise: promise)), promise: nil)
        return promise.futureResult
    }

    func fetchData(from statement: String) -> EventLoopFuture<MySQLResultsetStream> {
        let promise = self.eventLoop.makePromise(of: MySQLResultsetStream.self)
        
        self.channel.write(ClientRequest.fetchCursorData(.init(statementId: Int(statement)!, promise: promise)), promise: nil)
        return promise.futureResult
    }

    func reset(statement: String) -> EventLoopFuture<Void> {
        let promise = self.eventLoop.makePromise(of: Void.self)
        
        self.channel.write(ClientRequest.resetStatement(.init(statementId: Int(statement)!, promise: promise)), promise: nil)
        return promise.futureResult
    }

    func deallocate(statement: String) -> EventLoopFuture<Void> {
        let promise = self.eventLoop.makePromise(of: Void.self)
        
        self.channel.write(ClientRequest.deallocateStatement(.init(statementId: Int(statement)!, promise: promise)), promise: nil)
        return promise.futureResult
    }

    func close() -> EventLoopFuture<Void> {
        let promise = self.eventLoop.makePromise(of: Void.self)
        
        self.channel.write(ClientRequest.quit, promise: nil)
        return promise.futureResult
    }
}
