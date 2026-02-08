import AppKit

@MainActor
final class StatusBarController: NSObject {
    private let statusItem: NSStatusItem
    private let appState: AppState
    private var config: AppConfig
    private let audioRecorder: AudioRecorder
    private let transcriber: WhisperTranscriber
    private let clipboardManager: ClipboardManager
    private let hotkeyManager: HotkeyManager
    private let notificationManager: NotificationManager

    init(
        appState: AppState,
        config: AppConfig,
        audioRecorder: AudioRecorder,
        transcriber: WhisperTranscriber,
        clipboardManager: ClipboardManager,
        hotkeyManager: HotkeyManager,
        notificationManager: NotificationManager
    ) {
        self.appState = appState
        self.config = config
        self.audioRecorder = audioRecorder
        self.transcriber = transcriber
        self.clipboardManager = clipboardManager
        self.hotkeyManager = hotkeyManager
        self.notificationManager = notificationManager

        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        super.init()

        updateTitle()
        buildMenu()
        setupHotkeys()
        print("[StatusBar] Initialized. Title: \(appState.statusBarTitle)")

        // Pre-download model in background
        Task {
            await transcriber.preload()
        }
    }

    // MARK: - Model Status (called from background)

    func handleModelStatusChange(_ status: ModelStatus) {
        appState.modelStatus = status
        updateTitle()
        buildMenu()
        print("[StatusBar] Model status: \(status)")
    }

    // MARK: - Title

    private func updateTitle() {
        statusItem.button?.title = appState.statusBarTitle
    }

    // MARK: - Menu

    private func buildMenu() {
        let menu = NSMenu()

        let recordHK = HotkeyManager.formatHotkey(config.recordHotkey)
        let langHK = HotkeyManager.formatHotkey(config.langHotkey)
        let langCode = config.language
        let lang = Language(rawValue: langCode) ?? .ko

        // Model status
        let modelItem = NSMenuItem(title: appState.modelStatus.menuTitle, action: nil, keyEquivalent: "")
        modelItem.isEnabled = false
        menu.addItem(modelItem)

        menu.addItem(NSMenuItem.separator())

        // Recording toggle
        let statusText: String
        switch appState.recordingStatus {
        case .idle:       statusText = "녹음 시작"
        case .recording:  statusText = "🔴 녹음 중지"
        case .processing: statusText = "⏳ 처리 중..."
        }
        let recordItem = NSMenuItem(title: "\(statusText) (\(recordHK))", action: #selector(toggleRecordingAction(_:)), keyEquivalent: "")
        recordItem.target = self
        recordItem.isEnabled = appState.recordingStatus != .processing
        menu.addItem(recordItem)

        // Language info
        let langInfo = NSMenuItem(title: "언어 전환: \(langHK)  (현재: \(lang.displayName))", action: nil, keyEquivalent: "")
        langInfo.isEnabled = false
        menu.addItem(langInfo)

        menu.addItem(NSMenuItem.separator())

        // Hotkey submenu
        let hotkeySubmenu = NSMenu()
        let hotkeys: [(String, String)] = [
            ("ctrl+shift+m", "⌃⇧M"),
            ("cmd+shift+r", "⌘⇧R"),
            ("alt+space", "⌥Space"),
            ("cmd+alt+space", "⌘⌥Space"),
            ("ctrl+shift+space", "⌃⇧Space"),
        ]
        for (key, label) in hotkeys {
            let check = config.recordHotkey == key ? "✓ " : "   "
            let item = NSMenuItem(title: "\(check)\(label)", action: #selector(setRecordHotkeyAction(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = key
            hotkeySubmenu.addItem(item)
        }
        let hotkeyMenuItem = NSMenuItem(title: "녹음 단축키 설정", action: nil, keyEquivalent: "")
        hotkeyMenuItem.submenu = hotkeySubmenu
        menu.addItem(hotkeyMenuItem)

        // Language submenu
        let langSubmenu = NSMenu()
        for language in Language.allCases {
            let check = lang == language ? "✓ " : "   "
            let item = NSMenuItem(title: "\(check)\(language.displayName)", action: #selector(setLanguageAction(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = language.rawValue
            langSubmenu.addItem(item)
        }
        let langMenuItem = NSMenuItem(title: "전사 언어", action: nil, keyEquivalent: "")
        langMenuItem.submenu = langSubmenu
        menu.addItem(langMenuItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "종료", action: #selector(quitAction(_:)), keyEquivalent: "")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    // MARK: - Hotkeys

    private func setupHotkeys() {
        hotkeyManager.registerRecordHotkey(config.recordHotkey) { [weak self] in
            print("[StatusBar] 🔑 Record hotkey callback!")
            Task { @MainActor in
                self?.toggleRecording()
            }
        }
        hotkeyManager.registerLangHotkey(config.langHotkey) { [weak self] in
            print("[StatusBar] 🔑 Lang hotkey callback!")
            Task { @MainActor in
                self?.cycleLanguage()
            }
        }
    }

    // MARK: - Actions

    @objc private func toggleRecordingAction(_ sender: NSMenuItem) {
        print("[StatusBar] Menu: toggle recording")
        toggleRecording()
    }

    @objc private func setRecordHotkeyAction(_ sender: NSMenuItem) {
        guard let key = sender.representedObject as? String else { return }
        print("[StatusBar] Menu: set record hotkey → \(key)")
        config.recordHotkey = key
        config.save()
        setupHotkeys()
        buildMenu()
        notificationManager.send(title: "음성 인식", body: "녹음 단축키: \(HotkeyManager.formatHotkey(key))")
    }

    @objc private func setLanguageAction(_ sender: NSMenuItem) {
        guard let code = sender.representedObject as? String,
              let lang = Language(rawValue: code) else { return }
        print("[StatusBar] Menu: set language → \(code)")
        config.language = code
        appState.language = lang
        config.save()
        updateTitle()
        buildMenu()
        notificationManager.send(title: "음성 인식", body: "전사 언어: \(lang.displayName)")
    }

    @objc private func quitAction(_ sender: NSMenuItem) {
        print("[StatusBar] Quit")
        hotkeyManager.unregisterAll()
        NSApplication.shared.terminate(nil)
    }

    // MARK: - Recording State Machine

    private func toggleRecording() {
        print("[Recording] Toggle — current status: \(appState.recordingStatus)")
        switch appState.recordingStatus {
        case .idle:
            startRecording()
        case .recording:
            stopRecording()
        case .processing:
            print("[Recording] Ignoring — still processing")
        }
    }

    private func startRecording() {
        guard appState.recordingStatus == .idle else { return }
        print("[Recording] ▶️ Starting...")

        do {
            try audioRecorder.startRecording()
        } catch {
            print("[Recording] ❌ Audio error: \(error.localizedDescription)")
            notificationManager.send(title: "오디오 오류", body: String(String(describing: error).prefix(120)))
            return
        }

        appState.recordingStatus = .recording
        updateTitle()
        buildMenu()
        print("[Recording] 🔴 Recording started")
    }

    private func stopRecording() {
        guard appState.recordingStatus == .recording else { return }
        print("[Recording] ⏹️ Stopping...")

        let samples = audioRecorder.stopRecording()
        print("[Recording] Recorded \(samples.count) samples (\(String(format: "%.1f", Double(samples.count) / 16000.0))s)")

        guard !samples.isEmpty else {
            print("[Recording] ⚠️ No samples recorded")
            appState.recordingStatus = .idle
            updateTitle()
            buildMenu()
            return
        }

        appState.recordingStatus = .processing
        updateTitle()
        buildMenu()

        transcribeAndPaste(samples)
    }

    // MARK: - Transcription

    private func transcribeAndPaste(_ samples: [Float]) {
        let language = config.language
        let transcriber = self.transcriber
        let clipboardManager = self.clipboardManager
        let notificationManager = self.notificationManager

        print("[Transcribe] ⏳ Starting (lang=\(language), samples=\(samples.count))...")

        Task.detached(priority: .userInitiated) {
            do {
                let text = try await transcriber.transcribe(audioSamples: samples, language: language)
                let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                print("[Transcribe] ✅ Result: \"\(trimmed)\"")

                await MainActor.run {
                    if !trimmed.isEmpty {
                        clipboardManager.copyAndPaste(trimmed)
                        let preview = trimmed.count > 50 ? String(trimmed.prefix(50)) + "..." : trimmed
                        notificationManager.send(title: "음성 인식 완료", body: preview)
                    } else {
                        notificationManager.send(title: "음성 인식", body: "인식된 텍스트가 없습니다.")
                    }
                }
            } catch {
                print("[Transcribe] ❌ Error: \(error)")
                await MainActor.run {
                    notificationManager.send(title: "오류", body: String(String(describing: error).prefix(160)))
                }
            }

            await MainActor.run { [weak self] in
                self?.appState.recordingStatus = .idle
                self?.updateTitle()
                self?.buildMenu()
                print("[Recording] 🎤 Back to idle")
            }
        }
    }

    // MARK: - Language Cycling

    private func cycleLanguage() {
        let current = Language(rawValue: config.language) ?? .ko
        let next = current.next()
        print("[Language] 🌐 Cycle: \(current.rawValue) → \(next.rawValue)")
        config.language = next.rawValue
        appState.language = next
        config.save()
        updateTitle()
        buildMenu()
        notificationManager.send(title: "음성 인식", body: "전사 언어 전환: \(next.displayName)")
    }
}
