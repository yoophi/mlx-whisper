import Foundation

protocol Transcribing: Actor {
    func transcribe(audioSamples: [Float], language: String) async throws -> String
    func preload() async
    func switchModel(to modelName: String) async
}
