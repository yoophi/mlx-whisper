import Foundation

/// 오버레이 관리 포트 (Driven Port)
@MainActor
protocol OverlayManaging {
    /// 녹음 중 오버레이 표시
    func showRecording()
    
    /// 전사 중 오버레이 표시
    func showProcessing()
    
    /// 오버레이 숨기기
    func hide()
    
    /// 마이크 레벨 업데이트 (0.0 ~ 1.0)
    func updateMicLevel(_ level: Float)
}
