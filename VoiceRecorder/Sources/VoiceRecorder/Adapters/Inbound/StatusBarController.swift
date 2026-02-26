import AppKit
import Combine

@MainActor
final class StatusBarController: NSObject {
    private let statusItem: NSStatusItem
    private let appState: AppState
    private var config: ConfigStoring
    private let hotkeyManager: HotkeyRegistering
    private let notifier: Notifying
    private let useCase: RecordAndTranscribeUseCase
    private let logger: Logging
    private var cancellables = Set<AnyCancellable>()

    init(
        appState: AppState,
        config: ConfigStoring,
        hotkeyManager: HotkeyRegistering,
        notifier: Notifying,
        useCase: RecordAndTranscribeUseCase,
        logger: Logging
    ) {
        self.appState = appState
        self.config = config
        self.hotkeyManager = hotkeyManager
        self.notifier = notifier
        self.useCase = useCase
        self.logger = logger
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        super.init()

        useCase.onStateChanged = { [weak self] in
            self?.refreshUI()
        }

        refreshUI()
        setupHotkeys()
        logger.info("Initialized. Title: \(appState.statusBarTitle)")

        useCase.preloadModel()
    }

    // MARK: - UI

    private func refreshUI() {
        statusItem.button?.title = appState.statusBarTitle
        statusItem.menu = MenuBuilder.build(
            appState: appState,
            config: config,
            target: self,
            toggleAction: #selector(toggleRecordingAction(_:)),
            setRecordHotkeyAction: #selector(setRecordHotkeyAction(_:)),
            setLanguageAction: #selector(setLanguageAction(_:)),
            setModelAction: #selector(setModelAction(_:)),
            setSaveDebugAudioFileAction: #selector(setSaveDebugAudioFileAction(_:)),
            quitAction: #selector(quitAction(_:))
        )
    }

    // MARK: - Hotkeys

    private func setupHotkeys() {
        hotkeyManager.registerRecordHotkey(config.recordHotkey) { [weak self] in
            Task { @MainActor in
                guard let self else { return }
                self.logger.debug("Record hotkey callback")
                self.useCase.toggleRecording(language: self.config.language)
            }
        }
        hotkeyManager.registerLangHotkey(config.langHotkey) { [weak self] in
            Task { @MainActor in
                self?.cycleLanguage()
            }
        }
    }

    // MARK: - Actions

    @objc private func toggleRecordingAction(_ sender: NSMenuItem) {
        logger.debug("Menu: toggle recording")
        useCase.toggleRecording(language: config.language)
    }

    @objc private func setRecordHotkeyAction(_ sender: NSMenuItem) {
        guard let key = sender.representedObject as? String else { return }
        logger.info("Menu: set record hotkey → \(key)")
        config.recordHotkey = key
        config.save()
        setupHotkeys()
        refreshUI()
        notifier.send(title: "음성 인식", body: "녹음 단축키: \(HotkeyManager.formatHotkey(key))")
    }

    @objc private func setLanguageAction(_ sender: NSMenuItem) {
        guard let code = sender.representedObject as? String,
              let lang = Language(rawValue: code) else { return }
        logger.info("Menu: set language → \(code)")
        config.language = code
        appState.language = lang
        config.save()
        refreshUI()
        notifier.send(title: "음성 인식", body: "전사 언어: \(lang.displayName)")
    }

    @objc private func setModelAction(_ sender: NSMenuItem) {
        guard let modelId = sender.representedObject as? String,
              modelId != config.model else { return }
        let label = MenuBuilder.availableModels.first(where: { $0.id == modelId })?.label ?? modelId
        logger.info("Menu: set model → \(modelId)")
        config.model = modelId
        config.save()
        refreshUI()
        notifier.send(title: "음성 인식", body: "모델 변경: \(label)")
        useCase.switchModel(to: modelId)
    }

    @objc private func setSaveDebugAudioFileAction(_ sender: NSMenuItem) {
        guard let enabled = sender.representedObject as? Bool else { return }
        logger.info("Menu: set save debug audio file → \(enabled)")
        config.saveDebugAudioFile = enabled
        config.save()
        useCase.setSaveDebugAudioFile(enabled)
        refreshUI()
        notifier.send(title: "음성 인식", body: enabled ? "디버그 오디오 저장: 켜짐" : "디버그 오디오 저장: 꺼짐")
    }

    @objc private func quitAction(_ sender: NSMenuItem) {
        logger.info("Quit")
        hotkeyManager.unregisterAll()
        NSApplication.shared.terminate(nil)
    }

    // MARK: - Language Cycling

    private func cycleLanguage() {
        let current = Language(rawValue: config.language) ?? .ko
        let next = current.next()
        logger.info("Cycle language: \(current.rawValue) → \(next.rawValue)")
        config.language = next.rawValue
        appState.language = next
        config.save()
        refreshUI()
        notifier.send(title: "음성 인식", body: "전사 언어 전환: \(next.displayName)")
    }
}
