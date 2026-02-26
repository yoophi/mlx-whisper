# 녹음 상태 오버레이 아키텍처 다이어그램

## 1. 현재 VoiceRecorder 아키텍처

```mermaid
graph TB
    subgraph "Presentation Layer"
        A1[StatusBarController]
        A2[MenuBuilder]
    end
    
    subgraph "Domain Layer"
        B1[RecordAndTranscribeUseCase]
        B2[RecordingStatus]
        B3[RecordingControl Port]
    end
    
    subgraph "Infrastructure Layer"
        C1[AudioRecorder]
        C2[WhisperTranscriber]
        C3[ClipboardManager]
        C4[HotkeyManager]
        C5[NotificationManager]
        C6[AppState]
    end
    
    A4[Hotkey Press] --> C4
    C4 --> B3
    B3 --> B1
    B1 --> C1
    B1 --> C2
    B1 --> C3
    B1 --> B2
    B2 --> C6
    C6 --> A1
    A1 --> A2
```

## 2. Handy 오버레이 아키텍처 (참고)

```mermaid
graph TB
    subgraph "Rust Backend"
        R1[overlay.rs] --> |"NSPanel 생성"| R2[tauri_nspanel]
        R1 --> |"위치 계산"| R3[calculate_overlay_position]
        R1 --> |"상태 표시"| R4[show_overlay_state]
        R5[actions.rs] --> |"녹음 시작"| R4
        R5 --> |"전사 시작"| R4
        R5 --> |"완료/에러"| R6[hide_recording_overlay]
    end
    
    subgraph "React Frontend"
        F1[RecordingOverlay.tsx] --> |"수신"| F2["listen('show-overlay')"]
        F1 --> |"수신"| F3["listen('mic-level')"]
        F1 --> |"렌더링"| F4[마이크 레벨 바]
        F1 --> |"렌더링"| F5[전사 중 텍스트]
    end
    
    R4 --> |"emit"| F2
    R1 --> |"emit"| F3
```

## 3. 제안하는 Swift 오버레이 아키텍처

```mermaid
graph TB
    subgraph "Domain Layer"
        D1[RecordAndTranscribeUseCase]
        D2[RecordingStatus]
        D3["OverlayManaging Port<br/>(NEW)"]
    end
    
    subgraph "Adapter Layer - Outbound"
        E1[OverlayManager<br/>(NEW)]
        E2[OverlayPanelController<br/>(NEW)]
        E3[OverlayView<br/>(NEW)]
        E4[OverlayPosition<br/>(NEW)]
    end
    
    subgraph "Adapter Layer - Inbound"
        A1[StatusBarController]
    end
    
    subgraph "App Layer"
        AP1[AppDelegate]
    end
    
    D1 --> |"showRecording()"| D3
    D1 --> |"showProcessing()"| D3
    D1 --> |"hide()"| D3
    D3 --> |"구현"| E1
    E1 --> |"관리"| E2
    E2 --> |"NSPanel"| E5[NSPanel]
    E5 --> |"contentView"| E3
    E4 --> |"position"| E2
    
    AP1 --> |"DI"| E1
    D2 --> |"상태 변경"| D1
```

## 4. 상태 전환 흐름도

```mermaid
stateDiagram-v2
    [*] --> Idle
    Idle --> Recording: 단축키 누름<br/>(오버레이 표시)
    Recording --> Processing: 단축키 다시 누름<br/>(전사 중 표시)
    Processing --> Idle: 전사 완료<br/>(오버레이 숨기기)
    Processing --> Idle: 전사 실패<br/>(오버레이 숨기기)
    
    note right of Recording
        오버레이 상태: recording
        마이크 레벨 바 표시
        취소 버튼 활성화
    end note
    
    note right of Processing
        오버레이 상태: processing
        "전사 중..." 텍스트 표시
        취소 버튼 비활성화
    end note
```

## 5. 오버레이 UI 구조

```mermaid
graph LR
    subgraph "OverlayView (172x36)"
        O1[iconView] --> |"마이크 아이콘"| O2[NSImageView]
        O3[barsContainer] --> |"9개 레벨 바"| O4[NSStackView]
        O5[statusLabel] --> |"전사 중..."| O6[NSTextField]
        O7[cancelButton] --> |"X"| O8[NSButton]
    end
    
    style O1 fill:#ffcccc
    style O3 fill:#ccffcc
    style O5 fill:#ccccff
    style O7 fill:#ffffcc
```

## 6. NSPanel 윈도우 계층

```mermaid
graph TB
    subgraph "macOS Window Levels"
        L1[Desktop] --> L2[Normal Windows]
        L2 --> L3[Floating Windows]
        L3 --> L4["Menu Bar (NSStatusItem)"]
        L4 --> L5["Overlay Panel<br/>(NSPanel.Level.status)"]
        L5 --> L6[Modal Panels]
        L6 --> L7[Screen Saver]
    end
    
    style L5 fill:#ff6b6b,color:#fff
```

## 7. 의존성 주입 흐름

```mermaid
sequenceDiagram
    participant AD as AppDelegate
    participant AS as AppState
    participant AR as AudioRecorder
    participant WT as WhisperTranscriber
    participant CM as ClipboardManager
    participant NM as NotificationManager
    participant HM as HotkeyManager
    participant OM as OverlayManager (NEW)
    participant UC as RecordAndTranscribeUseCase
    participant SC as StatusBarController
    
    AD->>AS: 생성
    AD->>AR: 생성
    AD->>WT: 생성
    AD->>CM: 생성
    AD->>NM: 생성
    AD->>OM: 생성 (NEW)
    AD->>UC: 생성 (모든 의존성 주입)
    AD->>HM: 생성
    AD->>SC: 생성
    
    UC->>OM: overlay.showRecording()
    UC->>OM: overlay.showProcessing()
    UC->>OM: overlay.hide()
```

## 8. 파일 구조 변경

```mermaid
graph TB
    subgraph "Before"
        B1[Domain/Ports/Driven/]
        B2[Adapters/Outbound/]
    end
    
    subgraph "After"
        A1[Domain/Ports/Driven/]
        A2[Adapters/Outbound/]
        A3[Adapters/Outbound/Overlay/]
    end
    
    B1 --> |"추가"| A1X["OverlayManaging.swift"]
    B2 --> |"추가"| A2X["OverlayManager.swift"]
    A2X --> A3
    
    subgraph "새 파일들"
        A3 --> A3A[OverlayPanelController.swift]
        A3 --> A3B[OverlayView.swift]
        A3 --> A3C[OverlayPosition.swift]
    end
    
    style A1X fill:#90EE90
    style A2X fill:#90EE90
    style A3A fill:#87CEEB
    style A3B fill:#87CEEB
    style A3C fill:#87CEEB
```

## 9. Handy vs VoiceRecorder 기능 비교

```mermaid
graph LR
    subgraph "Handy (Rust/React)"
        H1[NSPanel via tauri_nspanel]
        H2[React 컴포넌트]
        H3[Tauri 이벤트]
        H4["emit('mic-level')"]
    end
    
    subgraph "VoiceRecorder (Swift)"
        V1[NSPanel native]
        V2[NSView + AppKit]
        V3[Protocol + Delegate]
        V4[OverlayManaging.updateMicLevel()]
    end
    
    H1 -.->|"동일"| V1
    H2 -.->|"변환"| V2
    H3 -.->|"변환"| V3
    H4 -.->|"변환"| V4
```

## 10. 타이밍 다이어그램

```mermaid
sequenceDiagram
    participant User
    participant Hotkey
    participant UseCase
    participant AudioRecorder
    participant Overlay
    participant Transcriber
    
    User->>Hotkey: Ctrl+Shift+M
    Hotkey->>UseCase: toggleRecording()
    UseCase->>AudioRecorder: startRecording()
    UseCase->>Overlay: showRecording()
    Note over Overlay: 마이크 레벨 바 표시
    
    loop 녹음 중
        AudioRecorder->>Overlay: updateMicLevel(level)
        Overlay->>Overlay: 바 높이 업데이트
    end
    
    User->>Hotkey: Ctrl+Shift+M
    Hotkey->>UseCase: toggleRecording()
    UseCase->>AudioRecorder: stopRecording()
    UseCase->>Overlay: showProcessing()
    Note over Overlay: "전사 중..." 표시
    UseCase->>Transcriber: transcribe()
    Transcriber-->>UseCase: 결과
    UseCase->>Overlay: hide()
    Note over Overlay: Fade-out 후 숨기기
```
