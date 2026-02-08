import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let appLogger = LoggerFactory.make(tag: "App")
        appLogger.info("Launched (logger: \(LoggerFactory.usePrintLogger ? "print" : "unified"))")

        let config = AppConfig.load()
        appLogger.info("Config: record_hotkey=\(config.recordHotkey), lang_hotkey=\(config.langHotkey), language=\(config.language), model=\(config.model)")

        let appState = AppState()
        appState.language = Language(rawValue: config.language) ?? .ko

        let notificationManager = NotificationManager(logger: LoggerFactory.make(tag: "Notification"))
        notificationManager.requestPermission()

        let audioRecorder = AudioRecorder(logger: LoggerFactory.make(tag: "Audio"))
        let clipboardManager = ClipboardManager(logger: LoggerFactory.make(tag: "Clipboard"))
        clipboardManager.requestAccessibilityIfNeeded()
        let hotkeyManager = HotkeyManager(logger: LoggerFactory.make(tag: "Hotkey"))

        var useCase: RecordAndTranscribeUseCase?

        let transcriber = WhisperTranscriber(
            modelName: config.model,
            logger: LoggerFactory.make(tag: "Transcriber")
        ) { status in
            Task { @MainActor in
                useCase?.handleModelStatusChange(status)
            }
        }

        let uc = RecordAndTranscribeUseCase(
            appState: appState,
            audioRecorder: audioRecorder,
            transcriber: transcriber,
            clipboard: clipboardManager,
            notifier: notificationManager,
            logger: LoggerFactory.make(tag: "Recording")
        )
        useCase = uc

        let sbc = StatusBarController(
            appState: appState,
            config: config,
            hotkeyManager: hotkeyManager,
            notifier: notificationManager,
            useCase: uc,
            logger: LoggerFactory.make(tag: "StatusBar")
        )
        statusBarController = sbc

        appLogger.info("Ready. Waiting for hotkey...")
    }

    func applicationWillTerminate(_ notification: Notification) {
        let logger = LoggerFactory.make(tag: "App")
        logger.info("Terminating")
        statusBarController = nil
    }
}
