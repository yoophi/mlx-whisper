import Foundation

enum Language: String, CaseIterable, Codable {
    case ko
    case en
    case ja
    case zh
    case vi

    var badge: String {
        switch self {
        case .ko: return "KR"
        case .en: return "EN"
        case .ja: return "JP"
        case .zh: return "CH"
        case .vi: return "VN"
        }
    }

    var displayName: String {
        switch self {
        case .ko: return "한국어"
        case .en: return "English"
        case .ja: return "日本語"
        case .zh: return "中文"
        case .vi: return "Tiếng Việt"
        }
    }

    /// Cycle order: ko → en → vi → ja → zh → ko
    private static let cycleOrder: [Language] = [.ko, .en, .vi, .ja, .zh]

    func next() -> Language {
        let order = Language.cycleOrder
        guard let idx = order.firstIndex(of: self) else { return .ko }
        return order[(idx + 1) % order.count]
    }
}
