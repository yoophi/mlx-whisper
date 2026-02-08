import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("[App] Launched")

        let config = AppConfig.load()
        print("[App] Config: record_hotkey=\(config.recordHotkey), lang_hotkey=\(config.langHotkey), language=\(config.language), model=\(config.model)")

        let appState = AppState()
        appState.language = Language(rawValue: config.language) ?? .ko

        let notificationManager = NotificationManager()
        notificationManager.requestPermission()

        let audioRecorder = AudioRecorder()
        let clipboardManager = ClipboardManager()
        clipboardManager.requestAccessibilityIfNeeded()
        let hotkeyManager = HotkeyManager()

        // Capture statusBarController weakly for the progress callback
        var controller: StatusBarController?
        let transcriber = WhisperTranscriber(modelName: config.model) { status in
            print("[Model] \(status)")
            Task { @MainActor in
                controller?.handleModelStatusChange(status)
            }
        }

        let sbc = StatusBarController(
            appState: appState,
            config: config,
            audioRecorder: audioRecorder,
            transcriber: transcriber,
            clipboardManager: clipboardManager,
            hotkeyManager: hotkeyManager,
            notificationManager: notificationManager
        )
        controller = sbc
        statusBarController = sbc

        print("[App] Ready. Waiting for hotkey...")
    }

    func applicationWillTerminate(_ notification: Notification) {
        print("[App] Terminating")
        statusBarController = nil
    }
}
