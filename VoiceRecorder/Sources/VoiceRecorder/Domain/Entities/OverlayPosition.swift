import Foundation

/// 오버레이 표시 위치
enum OverlayPosition: String, Codable, CaseIterable {
    case none = "none"
    case top = "top"
    case bottom = "bottom"
    
    var displayName: String {
        switch self {
        case .none: return "없음"
        case .top: return "상단"
        case .bottom: return "하단"
        }
    }
}
