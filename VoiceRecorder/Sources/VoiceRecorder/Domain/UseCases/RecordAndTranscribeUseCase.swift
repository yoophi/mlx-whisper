import Foundation

@MainActor
final class RecordAndTranscribeUseCase: RecordingControl {
    private let appState: AppState
    private let audioRecorder: AudioRecording
    private let transcriber: any Transcribing
    private let clipboard: ClipboardPasting
    private let notifier: Notifying
    private let logger: Logging
    private let overlay: OverlayManaging

    var onStateChanged: (() -> Void)?

    init(
        appState: AppState,
        audioRecorder: AudioRecording,
        transcriber: any Transcribing,
        clipboard: ClipboardPasting,
        notifier: Notifying,
        logger: Logging,
        overlay: OverlayManaging
    ) {
        self.appState = appState
        self.audioRecorder = audioRecorder
        self.transcriber = transcriber
        self.clipboard = clipboard
        self.notifier = notifier
        self.logger = logger
        self.overlay = overlay
    }

    // MARK: - RecordingControl

    func toggleRecording(language: String) {
        logger.info("Toggle — current status: \(appState.recordingStatus)")
        switch appState.recordingStatus {
        case .idle:
            startRecording()
        case .recording:
            stopRecording(language: language)
        case .processing:
            logger.info("Ignoring — still processing")
        }
    }

    func handleModelStatusChange(_ status: ModelStatus) {
        appState.modelStatus = status
        logger.info("Model status: \(status)")
        onStateChanged?()
    }

    func preloadModel() {
        let transcriber = self.transcriber
        Task {
            await transcriber.preload()
        }
    }

    func switchModel(to modelName: String) {
        let transcriber = self.transcriber
        Task {
            await transcriber.switchModel(to: modelName)
        }
    }

    func setSaveDebugAudioFile(_ enabled: Bool) {
        audioRecorder.saveDebugAudioFile = enabled
        logger.info("Debug audio save: \(enabled ? "enabled" : "disabled")")
    }

    // MARK: - Private

    private func startRecording() {
        guard appState.recordingStatus == .idle else { return }
        logger.info("Starting recording...")

        do {
            try audioRecorder.startRecording()
        } catch {
            logger.error("Audio error: \(error.localizedDescription)")
            notifier.send(title: "오디오 오류", body: String(String(describing: error).prefix(120)))
            return
        }

        appState.recordingStatus = .recording
        overlay.showRecording()
        onStateChanged?()
        logger.info("Recording started")
    }

    private func stopRecording(language: String) {
        guard appState.recordingStatus == .recording else { return }
        logger.info("Stopping recording...")

        let samples = audioRecorder.stopRecording()
        logger.info("Recorded \(samples.count) samples (\(String(format: "%.1f", Double(samples.count) / 16000.0))s)")

        guard !samples.isEmpty else {
            logger.info("No samples recorded")
            appState.recordingStatus = .idle
            overlay.hide()
            onStateChanged?()
            return
        }

        appState.recordingStatus = .processing
        overlay.showProcessing()
        onStateChanged?()

        transcribeAndPaste(samples, language: language)
    }

    private func transcribeAndPaste(_ samples: [Float], language: String) {
        let transcriber = self.transcriber
        let clipboard = self.clipboard
        let notifier = self.notifier
        let logger = self.logger

        logger.info("Starting transcription (lang=\(language), samples=\(samples.count))...")

        Task.detached(priority: .userInitiated) {
            do {
                let text = try await transcriber.transcribe(audioSamples: samples, language: language)
                let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                logger.info("Transcription result: \"\(trimmed)\"")

                await MainActor.run {
                    if !trimmed.isEmpty {
                        clipboard.copyAndPaste(trimmed)
                        let preview = trimmed.count > 50 ? String(trimmed.prefix(50)) + "..." : trimmed
                        notifier.send(title: "음성 인식 완료", body: preview)
                    } else {
                        notifier.send(title: "음성 인식", body: "인식된 텍스트가 없습니다.")
                    }
                }
            } catch {
                logger.error("Transcription error: \(error)")
                await MainActor.run {
                    notifier.send(title: "오류", body: String(String(describing: error).prefix(160)))
                }
            }

            await MainActor.run { [weak self] in
                self?.appState.recordingStatus = .idle
                self?.overlay.hide()
                self?.onStateChanged?()
                logger.info("Back to idle")
            }
        }
    }
}
