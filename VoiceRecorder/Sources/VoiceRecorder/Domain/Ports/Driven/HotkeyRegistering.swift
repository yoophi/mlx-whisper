import Foundation

protocol HotkeyRegistering {
    func registerRecordHotkey(_ hotkeyString: String, handler: @escaping () -> Void)
    func registerLangHotkey(_ hotkeyString: String, handler: @escaping () -> Void)
    func unregisterAll()
}
