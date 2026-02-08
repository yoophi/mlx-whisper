import Foundation

enum LoggerFactory {
    static let usePrintLogger = CommandLine.arguments.contains("--print-log")

    static func make(tag: String) -> Logging {
        if usePrintLogger {
            return PrintLogger(tag: tag)
        }
        return UnifiedLogger(tag: tag)
    }
}
