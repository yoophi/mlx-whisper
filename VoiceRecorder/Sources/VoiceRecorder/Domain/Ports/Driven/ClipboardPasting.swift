import Foundation

protocol ClipboardPasting {
    func copyAndPaste(_ text: String)
    func requestAccessibilityIfNeeded()
}
