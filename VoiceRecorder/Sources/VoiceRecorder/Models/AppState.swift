import Foundation

enum RecordingStatus {
    case idle
    case recording
    case processing
}

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

@MainActor
final class AppState: ObservableObject {
    @Published var recordingStatus: RecordingStatus = .idle
    @Published var language: Language = .ko
    @Published var modelStatus: ModelStatus = .notLoaded

    var statusBarTitle: String {
        let badge = language.badge
        switch modelStatus {
        case .downloading(let p):
            return "📥\(p)%"
        case .loading:
            return "⏳\(badge)"
        case .error:
            return "❌\(badge)"
        default:
            break
        }
        switch recordingStatus {
        case .idle:       return "🎤\(badge)"
        case .recording:  return "🔴\(badge)"
        case .processing: return "⏳\(badge)"
        }
    }
}
