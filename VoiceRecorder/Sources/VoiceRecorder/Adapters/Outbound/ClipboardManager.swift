import AppKit
import Carbon.HIToolbox

final class ClipboardManager: ClipboardPasting {
    private let logger: Logging

    init(logger: Logging) {
        self.logger = logger
    }

    func requestAccessibilityIfNeeded() {
        let trusted = AXIsProcessTrusted()
        logger.info("Accessibility permission: \(trusted ? "granted" : "not granted")")

        if !trusted {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
            AXIsProcessTrustedWithOptions(options)
            logger.info("접근성 권한 요청 다이얼로그를 표시했습니다.")
            logger.info("시스템 설정 > 개인정보 보호 > 접근성에서 VoiceRecorder를 허용하세요.")
        }
    }

    func copyAndPaste(_ text: String) {
        copyToClipboard(text)
        logger.info("Copied \(text.count) chars")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.simulatePaste()
        }
    }

    func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    private func simulatePaste() {
        guard AXIsProcessTrusted() else {
            logger.error("접근성 권한 없음 — Cmd+V 시뮬레이션 불가")
            logger.info("텍스트는 클립보드에 복사되었습니다. 수동으로 Cmd+V로 붙여넣기 가능합니다.")
            return
        }

        logger.debug("Simulating Cmd+V")
        let source = CGEventSource(stateID: .hidSystemState)

        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: true)
        keyDown?.flags = .maskCommand
        keyDown?.post(tap: .cghidEventTap)

        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: false)
        keyUp?.flags = .maskCommand
        keyUp?.post(tap: .cghidEventTap)
    }
}
