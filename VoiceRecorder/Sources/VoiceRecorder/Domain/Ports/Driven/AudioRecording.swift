import Foundation

protocol AudioRecording {
    func startRecording() throws
    func stopRecording() -> [Float]
}
