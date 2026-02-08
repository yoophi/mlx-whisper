import AppKit
import Carbon.HIToolbox

final class ClipboardManager {

    /// 앱 시작 시 호출 — 접근성 권한이 없으면 시스템 허용 다이얼로그를 띄움
    func requestAccessibilityIfNeeded() {
        let trusted = AXIsProcessTrusted()
        print("[Clipboard] Accessibility permission: \(trusted ? "✅ granted" : "❌ not granted")")

        if !trusted {
            // 시스템 설정 다이얼로그 표시
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
            AXIsProcessTrustedWithOptions(options)
            print("[Clipboard] ⚠️ 접근성 권한 요청 다이얼로그를 표시했습니다.")
            print("[Clipboard] ⚠️ 시스템 설정 > 개인정보 보호 > 접근성에서 VoiceRecorder를 허용하세요.")
        }
    }

    func copyAndPaste(_ text: String) {
        copyToClipboard(text)
        print("[Clipboard] Copied \(text.count) chars")

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
            print("[Clipboard] ❌ 접근성 권한 없음 — Cmd+V 시뮬레이션 불가")
            print("[Clipboard] ❌ 시스템 설정 > 개인정보 보호 > 접근성에서 VoiceRecorder를 허용하세요.")
            print("[Clipboard] 💡 텍스트는 클립보드에 복사되었습니다. 수동으로 Cmd+V로 붙여넣기 가능합니다.")
            return
        }

        print("[Clipboard] Simulating Cmd+V")
        let source = CGEventSource(stateID: .hidSystemState)

        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: true)
        keyDown?.flags = .maskCommand
        keyDown?.post(tap: .cghidEventTap)

        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: false)
        keyUp?.flags = .maskCommand
        keyUp?.post(tap: .cghidEventTap)
    }
}
