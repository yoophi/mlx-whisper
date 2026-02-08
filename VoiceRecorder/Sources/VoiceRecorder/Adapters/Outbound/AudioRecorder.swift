import AVFoundation
import Foundation

final class AudioRecorder: AudioRecording {
    private let engine = AVAudioEngine()
    private var samples: [Float] = []
    private let lock = NSLock()
    private var isRecording = false
    private let logger: Logging

    init(logger: Logging) {
        self.logger = logger
    }

    func startRecording() throws {
        let inputNode = engine.inputNode
        let hwFormat = inputNode.outputFormat(forBus: 0)

        logger.info("Hardware format: sampleRate=\(hwFormat.sampleRate), channels=\(hwFormat.channelCount)")

        guard hwFormat.sampleRate > 0 else {
            throw AudioRecorderError.noInputDevice
        }

        samples = []

        guard let targetFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: 16000,
            channels: 1,
            interleaved: false
        ) else {
            throw AudioRecorderError.formatError
        }

        guard let converter = AVAudioConverter(from: hwFormat, to: targetFormat) else {
            throw AudioRecorderError.converterError
        }

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: hwFormat) { [weak self] buffer, _ in
            guard let self else { return }

            let frameCount = AVAudioFrameCount(
                Double(buffer.frameLength) * 16000.0 / hwFormat.sampleRate
            )
            guard frameCount > 0 else { return }

            guard let convertedBuffer = AVAudioPCMBuffer(
                pcmFormat: targetFormat,
                frameCapacity: frameCount
            ) else { return }

            var error: NSError?
            let status = converter.convert(to: convertedBuffer, error: &error) { _, outStatus in
                outStatus.pointee = .haveData
                return buffer
            }

            guard status != .error, error == nil else { return }

            if let channelData = convertedBuffer.floatChannelData?[0] {
                let count = Int(convertedBuffer.frameLength)
                let newSamples = Array(UnsafeBufferPointer(start: channelData, count: count))
                self.lock.lock()
                self.samples.append(contentsOf: newSamples)
                self.lock.unlock()
            }
        }

        engine.prepare()
        try engine.start()
        isRecording = true
        logger.info("Engine started, recording...")
    }

    func stopRecording() -> [Float] {
        guard isRecording else { return [] }
        isRecording = false

        engine.inputNode.removeTap(onBus: 0)
        engine.stop()

        lock.lock()
        let result = samples
        samples = []
        lock.unlock()

        logger.info("Stopped. \(result.count) samples (\(String(format: "%.1f", Double(result.count) / 16000.0))s)")
        return result
    }
}

enum AudioRecorderError: LocalizedError {
    case noInputDevice
    case formatError
    case converterError

    var errorDescription: String? {
        switch self {
        case .noInputDevice: return "마이크를 찾을 수 없습니다."
        case .formatError: return "오디오 포맷 생성 실패"
        case .converterError: return "오디오 컨버터 생성 실패"
        }
    }
}
