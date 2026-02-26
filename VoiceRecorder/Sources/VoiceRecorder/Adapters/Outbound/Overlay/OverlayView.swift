import AppKit

/// 오버레이 상태
enum OverlayState {
    case recording
    case processing
}

/// 오버레이 UI 뷰 (마이크 레벨 바 + 상태 텍스트)
final class OverlayView: NSView {
    
    // MARK: - Constants (Handy 프로젝트 기반)
    private static let overlayWidth: CGFloat = 172
    private static let overlayHeight: CGFloat = 36
    private static let cornerRadius: CGFloat = 18
    private static let barCount = 9
    private static let barWidth: CGFloat = 6
    private static let barGap: CGFloat = 3
    private static let barMinHeight: CGFloat = 4
    private static let barMaxHeight: CGFloat = 20
    
    // MARK: - UI Components
    private let iconView = NSImageView()
    private let barsContainer = NSStackView()
    private let statusLabel = NSTextField(labelWithString: "전사 중...")
    private var bars: [NSView] = []
    
    // MARK: - State
    private var currentState: OverlayState = .recording
    private var smoothedLevels: [Float] = Array(repeating: 0, count: barCount)
    
    // MARK: - Initialization
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        wantsLayer = true
        
        // 배경 스타일 (Handy: background: #000000cc, border-radius: 18px)
        layer?.backgroundColor = NSColor.black.withAlphaComponent(0.8).cgColor
        layer?.cornerRadius = Self.cornerRadius
        
        // 메인 컨테이너 (horizontal stack)
        let container = NSStackView()
        container.orientation = .horizontal
        container.alignment = .centerY
        container.spacing = 8
        container.edgeInsets = NSEdgeInsets(top: 6, left: 8, bottom: 6, right: 8)
        
        // 아이콘 (마이크)
        iconView.image = NSImage(systemSymbolName: "mic.fill", accessibilityDescription: "마이크")
        iconView.contentTintColor = .white
        iconView.symbolConfiguration = .init(pointSize: 14, weight: .medium)
        iconView.setContentHuggingPriority(.required, for: .horizontal)
        container.addArrangedSubview(iconView)
        
        // 마이크 레벨 바 컨테이너
        barsContainer.orientation = .horizontal
        barsContainer.alignment = .bottom
        barsContainer.spacing = Self.barGap
        barsContainer.distribution = .fillEqually
        barsContainer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        
        for _ in 0..<Self.barCount {
            let bar = NSView()
            bar.wantsLayer = true
            bar.layer?.backgroundColor = NSColor(white: 1.0, alpha: 0.9).cgColor // #ffe5ee 대신 흰색
            bar.layer?.cornerRadius = 2
            bar.translatesAutoresizingMaskIntoConstraints = false
            bar.widthAnchor.constraint(equalToConstant: Self.barWidth).isActive = true
            bar.heightAnchor.constraint(equalToConstant: Self.barMinHeight).isActive = true
            bars.append(bar)
            barsContainer.addArrangedSubview(bar)
        }
        container.addArrangedSubview(barsContainer)
        
        // 상태 라벨 (전사 중 표시용)
        statusLabel.font = .systemFont(ofSize: 12, weight: .medium)
        statusLabel.textColor = .white
        statusLabel.alignment = .center
        statusLabel.isHidden = true
        statusLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        container.addArrangedSubview(statusLabel)
        
        // 컨테이너 추가
        container.translatesAutoresizingMaskIntoConstraints = false
        addSubview(container)
        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor),
            container.topAnchor.constraint(equalTo: topAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        // 초기 상태
        setState(.recording)
    }
    
    // MARK: - Public Methods
    
    /// 오버레이 상태 설정
    func setState(_ state: OverlayState) {
        currentState = state
        
        switch state {
        case .recording:
            iconView.isHidden = false
            barsContainer.isHidden = false
            statusLabel.isHidden = true
            // 바 높이 초기화
            for bar in bars {
                bar.layer?.frame.size.height = Self.barMinHeight
            }
            
        case .processing:
            iconView.isHidden = false
            barsContainer.isHidden = true
            statusLabel.isHidden = false
            statusLabel.stringValue = "전사 중..."
            startPulsingAnimation()
        }
    }
    
    /// 마이크 레벨 업데이트 (Handy: smoothed = prev * 0.7 + target * 0.3)
    func updateMicLevels(_ levels: [Float]) {
        guard currentState == .recording else { return }
        
        for (index, bar) in bars.enumerated() {
            let target = levels[safe: index] ?? 0
            
            // 스무딩 적용
            smoothedLevels[index] = smoothedLevels[index] * 0.7 + target * 0.3
            
            let level = smoothedLevels[index]
            
            // 높이 계산 (Handy: 4 + pow(v, 0.7) * 16, cap at 20)
            let height = Self.barMinHeight + CGFloat(pow(Double(level), 0.7)) * (Self.barMaxHeight - Self.barMinHeight)
            
            // 투명도 계산 (Handy: max(0.2, v * 1.7))
            let opacity = max(0.2, CGFloat(level) * 1.7)
            
            // 애니메이션 없이 즉시 업데이트 (더 빠른 반응)
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            bar.layer?.frame.size.height = min(height, Self.barMaxHeight)
            bar.layer?.opacity = Float(opacity)
            CATransaction.commit()
        }
    }
    
    // MARK: - Private Methods
    
    private func startPulsingAnimation() {
        // 전사 중 텍스트 깜빡임 애니메이션
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.75
            context.allowsImplicitAnimation = true
            statusLayer?.opacity = 0.6
        } completionHandler: { [weak self] in
            guard self?.currentState == .processing else { return }
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.75
                context.allowsImplicitAnimation = true
                self?.statusLayer?.opacity = 1.0
            } completionHandler: { [weak self] in
                guard self?.currentState == .processing else { return }
                self?.startPulsingAnimation()
            }
        }
    }
    
    private var statusLayer: CALayer? {
        statusLabel.layer
    }
}

// MARK: - Array Extension

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
