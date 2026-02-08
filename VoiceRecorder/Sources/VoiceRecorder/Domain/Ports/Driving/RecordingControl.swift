import Foundation

@MainActor
protocol RecordingControl {
    func toggleRecording(language: String)
    func handleModelStatusChange(_ status: ModelStatus)
    func preloadModel()
}
