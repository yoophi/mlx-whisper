import Foundation

protocol AudioRecording: AnyObject {
    func startRecording() throws
    func stopRecording() -> [Float]
    var onMicLevel: ((Float) -> Void)? { get set }
    var saveDebugAudioFile: Bool { get set }
}
