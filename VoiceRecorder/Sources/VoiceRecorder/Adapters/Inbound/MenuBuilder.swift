import AppKit

@MainActor
struct MenuBuilder {
    static func build(
        appState: AppState,
        config: ConfigStoring,
        target: AnyObject,
        toggleAction: Selector,
        setRecordHotkeyAction: Selector,
        setLanguageAction: Selector,
        quitAction: Selector
    ) -> NSMenu {
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
        let recordItem = NSMenuItem(title: "\(statusText) (\(recordHK))", action: toggleAction, keyEquivalent: "")
        recordItem.target = target
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
            let item = NSMenuItem(title: "\(check)\(label)", action: setRecordHotkeyAction, keyEquivalent: "")
            item.target = target
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
            let item = NSMenuItem(title: "\(check)\(language.displayName)", action: setLanguageAction, keyEquivalent: "")
            item.target = target
            item.representedObject = language.rawValue
            langSubmenu.addItem(item)
        }
        let langMenuItem = NSMenuItem(title: "전사 언어", action: nil, keyEquivalent: "")
        langMenuItem.submenu = langSubmenu
        menu.addItem(langMenuItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "종료", action: quitAction, keyEquivalent: "")
        quitItem.target = target
        menu.addItem(quitItem)

        return menu
    }
}
