import Foundation

protocol Logging {
    func info(_ message: String)
    func error(_ message: String)
    func debug(_ message: String)
}
