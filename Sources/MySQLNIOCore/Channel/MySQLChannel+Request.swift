import Logging
import NIOCore
import NIOTLS
import Collections

extension MySQLChannel {
    enum Request {
        case ping(EventLoopPromise<Void>)
        case getStatistics(EventLoopPromise<String>)
        case resetAllState(EventLoopPromise<Void>)
        case plainQuery(PlainQueryContext)
        case prepareStatement(()/*PrepareStatementContext*/)
        case executeStatement(()/*ExecuteStatementContext*/)
        case fetchCursorData(()/*FetchCursorDataContext*/)
        case resetStatement(()/*ResetStatementContext*/)
        case deallocateStatement(())
        case quit
    }
    
    func ping() -> EventLoopFuture<Void> {
        let promise = self.eventLoop.makePromise(of: Void.self)
        
        self.channel.write(Request.ping(promise), promise: nil)
        return promise.futureResult
    }
    
    func getStatistics() -> EventLoopFuture<String> {
        let promise = self.eventLoop.makePromise(of: String.self)
        
        self.channel.write(Request.getStatistics(promise), promise: nil)
        return promise.futureResult
    }
    
    func resetAllState() -> EventLoopFuture<Void> {
        let promise = self.eventLoop.makePromise(of: Void.self)
        
        self.channel.write(Request.resetAllState(promise), promise: nil)
        return promise.futureResult
    }
    
    func query(sql: String) -> EventLoopFuture<MySQLResultsetStream> {
        let promise = self.eventLoop.makePromise(of: MySQLResultsetStream.self)
        
        self.channel.write(Request.plainQuery(.init(attributes: [:], sql: sql, stream: promise)), promise: nil)
        return promise.futureResult
    }
    
    func prepare(statement: String) -> EventLoopFuture<Void> {
        let promise = self.eventLoop.makePromise(of: Void.self)
        
        self.channel.write(Request.prepareStatement(()), promise: nil)
        return promise.futureResult
    }
    
    func execute(statement: String) -> EventLoopFuture<Void> {
        let promise = self.eventLoop.makePromise(of: Void.self)
        
        self.channel.write(Request.executeStatement(()), promise: nil)
        return promise.futureResult
    }
    
    func fetchData(from statement: String) -> EventLoopFuture<Void> {
        let promise = self.eventLoop.makePromise(of: Void.self)
        
        self.channel.write(Request.fetchCursorData(()), promise: nil)
        return promise.futureResult
    }
    
    func resetStatement(_ statement: String) -> EventLoopFuture<Void> {
        let promise = self.eventLoop.makePromise(of: Void.self)
        
        self.channel.write(Request.resetStatement(()), promise: nil)
        return promise.futureResult
    }
    
    func deallocate(_ statement: String) -> EventLoopFuture<Void> {
        let promise = self.eventLoop.makePromise(of: Void.self)
        
        self.channel.write(Request.deallocateStatement(()), promise: nil)
        return promise.futureResult
    }
    
    func close() -> EventLoopFuture<Void> {
        let promise = self.eventLoop.makePromise(of: Void.self)
        
        self.channel.write(Request.quit, promise: nil)
        return promise.futureResult
    }
}
