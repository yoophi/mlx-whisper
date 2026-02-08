import Foundation

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
