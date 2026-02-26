import Foundation
import WhisperKit

actor WhisperTranscriber: Transcribing {
    private var whisperKit: WhisperKit?
    private var modelName: String
    private var isLoading = false
    private let onProgress: @Sendable (ModelStatus) -> Void
    private let logger: Logging

    init(modelName: String, logger: Logging, onProgress: @escaping @Sendable (ModelStatus) -> Void) {
        self.modelName = modelName
        self.logger = logger
        self.onProgress = onProgress
    }

    private static let modelBaseURL: URL = {
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".voice-recorder")
    }()

    private func ensureModel() async throws {
        if whisperKit != nil { return }
        guard !isLoading else {
            logger.info("Model already loading, waiting...")
            while isLoading {
                try await Task.sleep(nanoseconds: 100_000_000)
            }
            return
        }

        isLoading = true
        defer { isLoading = false }

        let baseURL = WhisperTranscriber.modelBaseURL
        try FileManager.default.createDirectory(at: baseURL, withIntermediateDirectories: true)
        logger.info("Model storage: \(baseURL.path)")

        // Step 1: Download model with progress
        logger.info("Downloading model: \(modelName)...")
        onProgress(.downloading(0))

        let modelURL = try await WhisperKit.download(
            variant: modelName,
            downloadBase: baseURL,
            progressCallback: { [onProgress, logger] progress in
                let pct = Int(progress.fractionCompleted * 100)
                logger.info("Download: \(pct)% (\(progress.completedUnitCount / 1_000_000)MB / \(progress.totalUnitCount / 1_000_000)MB)")
                onProgress(.downloading(pct))
            }
        )
        logger.info("Download complete: \(modelURL.path)")

        // Step 2: Load model into memory
        logger.info("Loading model into memory...")
        onProgress(.loading)

        let config = WhisperKitConfig(
            model: modelName,
            downloadBase: baseURL,
            modelFolder: modelURL.path,
            verbose: true,
            logLevel: .info
        )
        whisperKit = try await WhisperKit(config)

        logger.info("Model loaded successfully")
        onProgress(.ready)
    }

    func transcribe(audioSamples: [Float], language: String) async throws -> String {
        logger.info("Transcribing \(audioSamples.count) samples, language=\(language)")
        try await ensureModel()

        guard let wk = whisperKit else {
            throw TranscriberError.modelNotLoaded
        }

        // 환각(hallucination) 방지를 위한 임계값 설정
        let options = DecodingOptions(
            language: language,
            temperature: 0.0,
            skipSpecialTokens: true,
            withoutTimestamps: true,
            compressionRatioThreshold: 2.4,
            logProbThreshold: -1.0,
            noSpeechThreshold: 0.6
        )
        let results = try await wk.transcribe(audioArray: audioSamples, decodeOptions: options)

        let text = results.map { $0.text }.joined(separator: " ")
        logger.info("Result: \"\(text)\"")
        return text
    }

    func preload() async {
        do {
            try await ensureModel()
        } catch {
            logger.error("Preload failed: \(error)")
            onProgress(.error(String(String(describing: error).prefix(100))))
        }
    }

    func switchModel(to newModelName: String) async {
        logger.info("Switching model: \(modelName) → \(newModelName)")
        modelName = newModelName
        whisperKit = nil
        await preload()
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
