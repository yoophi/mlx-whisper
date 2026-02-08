import Foundation

protocol Notifying {
    func requestPermission()
    func send(title: String, body: String)
}
