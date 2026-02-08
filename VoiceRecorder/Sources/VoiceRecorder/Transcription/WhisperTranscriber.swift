import Foundation
import WhisperKit

actor WhisperTranscriber {
    private var whisperKit: WhisperKit?
    private let modelName: String
    private var isLoading = false
    private let onProgress: @Sendable (ModelStatus) -> Void

    init(modelName: String, onProgress: @escaping @Sendable (ModelStatus) -> Void) {
        self.modelName = modelName
        self.onProgress = onProgress
    }

    private static let modelBaseURL: URL = {
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".voice-recorder")
    }()

    private func ensureModel() async throws {
        if whisperKit != nil { return }
        guard !isLoading else {
            print("[Transcriber] Model already loading, waiting...")
            while isLoading {
                try await Task.sleep(nanoseconds: 100_000_000)
            }
            return
        }

        isLoading = true
        defer { isLoading = false }

        let baseURL = WhisperTranscriber.modelBaseURL
        try FileManager.default.createDirectory(at: baseURL, withIntermediateDirectories: true)
        print("[Transcriber] Model storage: \(baseURL.path)")

        // Step 1: Download model with progress
        print("[Transcriber] 📥 Downloading model: \(modelName)...")
        onProgress(.downloading(0))

        let modelURL = try await WhisperKit.download(
            variant: modelName,
            downloadBase: baseURL,
            progressCallback: { [onProgress] progress in
                let pct = Int(progress.fractionCompleted * 100)
                print("[Transcriber] 📥 Download: \(pct)% (\(progress.completedUnitCount / 1_000_000)MB / \(progress.totalUnitCount / 1_000_000)MB)")
                onProgress(.downloading(pct))
            }
        )
        print("[Transcriber] 📥 Download complete: \(modelURL.path)")

        // Step 2: Load model into memory
        print("[Transcriber] ⏳ Loading model into memory...")
        onProgress(.loading)

        let config = WhisperKitConfig(
            model: modelName,
            downloadBase: baseURL,
            modelFolder: modelURL.path,
            verbose: true,
            logLevel: .info
        )
        whisperKit = try await WhisperKit(config)

        print("[Transcriber] ✅ Model loaded successfully")
        onProgress(.ready)
    }

    func transcribe(audioSamples: [Float], language: String) async throws -> String {
        print("[Transcriber] Transcribing \(audioSamples.count) samples, language=\(language)")
        try await ensureModel()

        guard let wk = whisperKit else {
            throw TranscriberError.modelNotLoaded
        }

        let options = DecodingOptions(language: language)
        let results = try await wk.transcribe(audioArray: audioSamples, decodeOptions: options)

        let text = results.map { $0.text }.joined(separator: " ")
        print("[Transcriber] Result: \"\(text)\"")
        return text
    }

    /// Pre-download and load the model in the background
    func preload() async {
        do {
            try await ensureModel()
        } catch {
            print("[Transcriber] ❌ Preload failed: \(error)")
            onProgress(.error(String(String(describing: error).prefix(100))))
        }
    }
}

enum TranscriberError: LocalizedError {
    case modelNotLoaded

    var errorDescription: String? {
        switch self {
        case .modelNotLoaded: return "WhisperKit 모델이 로드되지 않았습니다."
        }
    }
}
