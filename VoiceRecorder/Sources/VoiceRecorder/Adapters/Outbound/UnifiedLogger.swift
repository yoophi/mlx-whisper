import Foundation
import os

final class UnifiedLogger: Logging {
    private let logger: os.Logger

    init(tag: String, subsystem: String = "com.voicerecorder.app") {
        self.logger = os.Logger(subsystem: subsystem, category: tag)
    }

    func info(_ message: String) {
        logger.info("\(message, privacy: .public)")
    }

    func error(_ message: String) {
        logger.error("\(message, privacy: .public)")
    }

    func debug(_ message: String) {
        logger.debug("\(message, privacy: .public)")
    }
}
