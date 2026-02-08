import Foundation

final class PrintLogger: Logging {
    private let tag: String

    init(tag: String) {
        self.tag = tag
    }

    func info(_ message: String) {
        print("[\(tag)] \(message)")
    }

    func error(_ message: String) {
        print("[\(tag)] \(message)")
    }

    func debug(_ message: String) {
        print("[\(tag)] \(message)")
    }
}
