import Foundation

enum ModelStatus: CustomStringConvertible {
    case notLoaded
    case downloading(Int)   // percentage 0-100
    case loading
    case ready
    case error(String)

    var description: String {
        switch self {
        case .notLoaded:          return "모델 미로드"
        case .downloading(let p): return "모델 다운로드 중... \(p)%"
        case .loading:            return "모델 로딩 중..."
        case .ready:              return "모델 준비 완료"
        case .error(let msg):     return "모델 오류: \(msg)"
        }
    }

    var menuTitle: String {
        switch self {
        case .notLoaded:          return "⬜ 모델: 대기 중"
        case .downloading(let p): return "📥 모델 다운로드 중... \(p)%"
        case .loading:            return "⏳ 모델 로딩 중..."
        case .ready:              return "✅ 모델 준비 완료"
        case .error(let msg):     return "❌ 오류: \(String(msg.prefix(40)))"
        }
    }
}
