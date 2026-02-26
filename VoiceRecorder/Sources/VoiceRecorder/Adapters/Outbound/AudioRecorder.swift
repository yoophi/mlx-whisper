import AVFoundation
import Foundation

final class AudioRecorder: AudioRecording {
    private let engine = AVAudioEngine()
    private var samples: [Float] = []
    private let lock = NSLock()
    private var isRecording = false
    private let logger: Logging
    
    var onMicLevel: ((Float) -> Void)?
    var saveDebugAudioFile: Bool = false

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
                
                // 마이크 레벨 계산 및 콜백
                let rms = sqrt(newSamples.reduce(0) { $0 + $1 * $1 } / Float(count))
                let level = min(1.0, rms * 10) // 스케일링
                self.onMicLevel?(level)
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
        
        if saveDebugAudioFile && !result.isEmpty {
            saveToWavFile(samples: result)
        }
        
        return result
    }
    
    /// 녹음된 샘플을 WAV 파일로 저장
    private func saveToWavFile(samples: [Float]) {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "recording_\(Date().timeIntervalSince1970).wav"
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        do {
            // WAV 파일 생성
            let sampleRate: Double = 16000
            let channels: UInt16 = 1
            let bitsPerSample: UInt16 = 16
            let byteRate = UInt32(sampleRate * Double(channels) * Double(bitsPerSample) / 8)
            let blockAlign = UInt16(channels * bitsPerSample / 8)
            let dataSize = UInt32(samples.count * 2) // 16-bit = 2 bytes per sample
            
            var data = Data()
            
            // RIFF header
            data.append(contentsOf: "RIFF".utf8)
            data.append(contentsOf: withUnsafeBytes(of: UInt32(36 + dataSize).littleEndian) { Array($0) })
            data.append(contentsOf: "WAVE".utf8)
            
            // fmt chunk
            data.append(contentsOf: "fmt ".utf8)
            data.append(contentsOf: withUnsafeBytes(of: UInt32(16).littleEndian) { Array($0) }) // chunk size
            data.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian) { Array($0) })  // PCM format
            data.append(contentsOf: withUnsafeBytes(of: channels.littleEndian) { Array($0) })
            data.append(contentsOf: withUnsafeBytes(of: UInt32(sampleRate).littleEndian) { Array($0) })
            data.append(contentsOf: withUnsafeBytes(of: byteRate.littleEndian) { Array($0) })
            data.append(contentsOf: withUnsafeBytes(of: blockAlign.littleEndian) { Array($0) })
            data.append(contentsOf: withUnsafeBytes(of: bitsPerSample.littleEndian) { Array($0) })
            
            // data chunk
            data.append(contentsOf: "data".utf8)
            data.append(contentsOf: withUnsafeBytes(of: dataSize.littleEndian) { Array($0) })
            
            // PCM 데이터 (Float -> Int16)
            for sample in samples {
                let intSample = Int16(max(-1.0, min(1.0, sample)) * 32767.0)
                data.append(contentsOf: withUnsafeBytes(of: intSample.littleEndian) { Array($0) })
            }
            
            try data.write(to: fileURL)
            logger.info("💾 Saved recording to: \(fileURL.path)")
        } catch {
            logger.error("Failed to save WAV file: \(error)")
        }
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
