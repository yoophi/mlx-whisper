import Foundation

/// 오버레이 관리자 (OverlayManaging 포트 구현체)
@MainActor
final class OverlayManager: OverlayManaging {
    
    // MARK: - Properties
    private let panelController: OverlayPanelController
    private var currentLevel: Float = 0
    private var levelUpdateTimer: Timer?
    
    // MARK: - Initialization
    
    init(position: OverlayPosition = .bottom) {
        self.panelController = OverlayPanelController()
        setPosition(position)
    }
    
    // MARK: - Public Methods
    
    func setPosition(_ position: OverlayPosition) {
        panelController.setPosition(position)
    }
    
    // MARK: - OverlayManaging Protocol
    
    func showRecording() {
        panelController.showRecording()
        startLevelUpdates()
    }
    
    func showProcessing() {
        stopLevelUpdates()
        panelController.showProcessing()
    }
    
    func hide() {
        stopLevelUpdates()
        panelController.hide()
    }
    
    func updateMicLevel(_ level: Float) {
        currentLevel = level
    }
    
    // MARK: - Private Methods
    
    private func startLevelUpdates() {
        stopLevelUpdates()
        
        // 60fps로 레벨 업데이트
        levelUpdateTimer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.panelController.updateMicLevel(self.currentLevel)
            }
        }
    }
    
    private func stopLevelUpdates() {
        levelUpdateTimer?.invalidate()
        levelUpdateTimer = nil
        currentLevel = 0
    }
}
