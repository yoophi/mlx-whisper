import AppKit
import Carbon.HIToolbox
import HotKey

final class HotkeyManager: HotkeyRegistering {
    private var recordHotKey: HotKey?
    private var langHotKey: HotKey?
    private let logger: Logging

    init(logger: Logging) {
        self.logger = logger
    }

    func registerRecordHotkey(_ hotkeyString: String, handler: @escaping () -> Void) {
        recordHotKey = nil
        guard let (key, modifiers) = parseHotkey(hotkeyString) else {
            logger.error("Failed to parse record hotkey: \(hotkeyString)")
            return
        }
        logger.info("Registering record hotkey: \(hotkeyString)")
        let hk = HotKey(key: key, modifiers: modifiers)
        hk.keyDownHandler = { [logger] in
            logger.debug("Record hotkey FIRED!")
            handler()
        }
        recordHotKey = hk
        logger.info("Record hotkey registered successfully")
    }

    func registerLangHotkey(_ hotkeyString: String, handler: @escaping () -> Void) {
        langHotKey = nil
        guard let (key, modifiers) = parseHotkey(hotkeyString) else {
            logger.error("Failed to parse lang hotkey: \(hotkeyString)")
            return
        }
        logger.info("Registering lang hotkey: \(hotkeyString)")
        let hk = HotKey(key: key, modifiers: modifiers)
        hk.keyDownHandler = { [logger] in
            logger.debug("Lang hotkey FIRED!")
            handler()
        }
        langHotKey = hk
        logger.info("Lang hotkey registered successfully")
    }

    func unregisterAll() {
        logger.info("Unregistering all hotkeys")
        recordHotKey = nil
        langHotKey = nil
    }

    // MARK: - Parsing

    func parseHotkey(_ hotkeyString: String) -> (Key, NSEvent.ModifierFlags)? {
        let parts = hotkeyString.lowercased().split(separator: "+").map { String($0).trimmingCharacters(in: .whitespaces) }
        guard !parts.isEmpty else { return nil }

        var modifiers: NSEvent.ModifierFlags = []
        var keyPart: String?

        for part in parts {
            switch part {
            case "cmd", "command":
                modifiers.insert(.command)
            case "shift":
                modifiers.insert(.shift)
            case "alt", "option":
                modifiers.insert(.option)
            case "ctrl", "control":
                modifiers.insert(.control)
            default:
                keyPart = part
            }
        }

        guard let kp = keyPart, let key = keyFromString(kp) else {
            logger.error("Unknown key: \(keyPart ?? "nil") in \(hotkeyString)")
            return nil
        }
        return (key, modifiers)
    }

    private func keyFromString(_ str: String) -> Key? {
        switch str {
        case "a": return .a
        case "b": return .b
        case "c": return .c
        case "d": return .d
        case "e": return .e
        case "f": return .f
        case "g": return .g
        case "h": return .h
        case "i": return .i
        case "j": return .j
        case "k": return .k
        case "l": return .l
        case "m": return .m
        case "n": return .n
        case "o": return .o
        case "p": return .p
        case "q": return .q
        case "r": return .r
        case "s": return .s
        case "t": return .t
        case "u": return .u
        case "v": return .v
        case "w": return .w
        case "x": return .x
        case "y": return .y
        case "z": return .z
        case "0": return .zero
        case "1": return .one
        case "2": return .two
        case "3": return .three
        case "4": return .four
        case "5": return .five
        case "6": return .six
        case "7": return .seven
        case "8": return .eight
        case "9": return .nine
        case "space": return .space
        case "return", "enter": return .return
        case "tab": return .tab
        case "escape", "esc": return .escape
        case "delete", "backspace": return .delete
        case "f1": return .f1
        case "f2": return .f2
        case "f3": return .f3
        case "f4": return .f4
        case "f5": return .f5
        case "f6": return .f6
        case "f7": return .f7
        case "f8": return .f8
        case "f9": return .f9
        case "f10": return .f10
        case "f11": return .f11
        case "f12": return .f12
        default: return nil
        }
    }

    // MARK: - Formatting

    static func formatHotkey(_ hotkey: String) -> String {
        if hotkey.isEmpty { return "-" }
        var result = hotkey.lowercased()
        let replacements: [(String, String)] = [
            ("cmd", "⌘"), ("command", "⌘"),
            ("shift", "⇧"),
            ("alt", "⌥"), ("option", "⌥"),
            ("ctrl", "⌃"), ("control", "⌃"),
            ("space", "Space"),
            ("+", ""),
        ]
        for (key, symbol) in replacements {
            result = result.replacingOccurrences(of: key, with: symbol)
        }
        return result
    }
}
