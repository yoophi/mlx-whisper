import AppKit

/// NSPanel 기반 오버레이 윈도우 컨트롤러
/// Handy 프로젝트의 overlay.rs를 Swift로 변환
final class OverlayPanelController {
    
    // MARK: - Constants (Handy 프로젝트 기반)
    private static let overlayWidth: CGFloat = 172
    private static let overlayHeight: CGFloat = 36
    private static let topOffset: CGFloat = 46      // macOS menu bar 고려
    private static let bottomOffset: CGFloat = 15
    private static let fadeAnimationDuration: Double = 0.3
    
    // MARK: - Properties
    private var panel: NSPanel?
    private let overlayView: OverlayView
    private var position: OverlayPosition = .bottom
    private var isVisible: Bool = false
    
    // MARK: - Initialization
    
    init() {
        self.overlayView = OverlayView()
        setupPanel()
    }
    
    // MARK: - Setup
    
    private func setupPanel() {
        let panel = NSPanel(
            contentRect: NSRect(
                x: 0,
                y: 0,
                width: Self.overlayWidth,
                height: Self.overlayHeight
            ),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        // Handy의 tauri_nspanel 설정 대응
        panel.level = .floating          // Floating above document windows
        panel.collectionBehavior = [
            .canJoinAllSpaces,             // can_join_all_spaces
            .fullScreenAuxiliary           // full_screen_auxiliary
        ]
        panel.isFloatingPanel = true       // is_floating_panel: true
        panel.becomesKeyOnlyIfNeeded = true // can_become_key_window: false
        panel.hidesOnDeactivate = false
        
        // 투명 배경
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        
        // 컨텐츠 뷰 설정
        overlayView.frame = NSRect(
            x: 0,
            y: 0,
            width: Self.overlayWidth,
            height: Self.overlayHeight
        )
        panel.contentView = overlayView
        
        // 초기에는 숨김
        panel.alphaValue = 0
        panel.orderOut(nil)
        
        self.panel = panel
    }
    
    // MARK: - Public Methods
    
    /// 오버레이 위치 설정
    func setPosition(_ newPosition: OverlayPosition) {
        self.position = newPosition
        if isVisible {
            updatePosition()
        }
    }
    
    /// 녹음 중 오버레이 표시
    func showRecording() {
        guard position != .none else { return }
        
        overlayView.setState(.recording)
        showPanel()
    }
    
    /// 전사 중 오버레이 표시
    func showProcessing() {
        guard position != .none else { return }
        
        overlayView.setState(.processing)
        showPanel()
    }
    
    /// 오버레이 숨기기
    func hide() {
        hidePanel()
    }
    
    /// 마이크 레벨 업데이트
    func updateMicLevel(_ level: Float) {
        // 여러 개의 바에 분배 (중앙 바가 가장 크게)
        var levels: [Float] = []
        for i in 0..<9 {
            let centerDistance = abs(Float(i) - 4.0) / 4.0
            let adjustedLevel = level * (1.0 - centerDistance * 0.5)
            // 약간의 랜덤 변화 추가 (자연스러운 느낌)
            let noise = Float.random(in: -0.1...0.1)
            levels.append(max(0, min(1, adjustedLevel + noise)))
        }
        overlayView.updateMicLevels(levels)
    }
    
    // MARK: - Private Methods
    
    private func showPanel() {
        guard let panel else { return }
        
        updatePosition()
        
        if !isVisible {
            panel.orderFrontRegardless()
            panel.alphaValue = 0
            
            // Fade-in 애니메이션
            NSAnimationContext.runAnimationGroup { context in
                context.duration = Self.fadeAnimationDuration
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                panel.animator().alphaValue = 1
            }
            isVisible = true
        }
    }
    
    private func hidePanel() {
        guard let panel, isVisible else { return }
        
        // Fade-out 애니메이션
        NSAnimationContext.runAnimationGroup { context in
            context.duration = Self.fadeAnimationDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().alphaValue = 0
        } completionHandler: { [weak self] in
            panel.orderOut(nil)
            self?.isVisible = false
        }
    }
    
    /// 오버레이 위치 업데이트 (Handy의 calculate_overlay_position 대응)
    private func updatePosition() {
        guard let panel else { return }
        
        let screen = getScreenWithCursor()
        let frame = screen?.visibleFrame ?? NSScreen.main?.visibleFrame ?? .zero
        
        // 화면 중앙 상단/하단에 배치
        let x = frame.origin.x + (frame.width - Self.overlayWidth) / 2
        let y: CGFloat
        
        switch position {
        case .top:
            // 상단: 화면 상단에서 topOffset 만큼 아래
            y = frame.origin.y + frame.height - Self.overlayHeight - Self.topOffset
        case .bottom:
            // 하단: 화면 하단에서 bottomOffset 만큼 위
            y = frame.origin.y + Self.bottomOffset
        case .none:
            return
        }
        
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }
    
    /// 마우스 커서가 있는 화면 감지 (Handy의 get_monitor_with_cursor 대응)
    private func getScreenWithCursor() -> NSScreen? {
        let mouseLocation = NSEvent.mouseLocation
        return NSScreen.screens.first { screen in
            screen.frame.contains(mouseLocation)
        } ?? NSScreen.main
    }
}
