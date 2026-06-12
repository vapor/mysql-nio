import Logging

extension Logger {
    func withLogLevel(_ logLevel: Logger.Level) -> Logger {
        var logger = self
        logger.logLevel = logLevel
        return logger
    }
}
