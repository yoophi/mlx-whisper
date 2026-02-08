# Native Swift 전환 계획

## 개요

현재 Python 앱을 Swift/SwiftUI + AppKit 기반 네이티브 macOS 메뉴바 앱으로 전환.

## 기술 스택

| 현재 (Python) | 전환 후 (Swift) |
|--------------|----------------|
| rumps | NSStatusItem + NSMenu |
| pyaudio | AVFoundation (AVAudioRecorder / AVCaptureSession) |
| mlx_whisper | WhisperKit (CoreML) 또는 MLXAudio Swift |
| pyperclip | NSPasteboard |
| pyautogui | CGEvent (Quartz) |
| pynput | KeyboardShortcuts / HotKey 패키지 |
| json config | UserDefaults 또는 JSON (Codable) |

## 강점

- **최고 성능**: Apple Silicon 네이티브, 메모리/CPU 사용 최소
- **최소 앱 크기**: 5~15MB (Whisper 모델 제외)
- **완전한 macOS 통합**: NSStatusItem, 알림 센터, 접근성 API 직접 사용
- **WhisperKit**: CoreML 기반, Apple Neural Engine(ANE) 활용으로 최고의 전사 성능
- **MLXAudio Swift**: MLX 네이티브, Python mlx_whisper 대비 4배 이상 빠름 (lightning-whisper-mlx 기준 10배)
- **배포 용이**: .app 번들 또는 Mac App Store 배포 가능
- **코드 서명/공증**: Xcode에서 자연스럽게 처리

## 단점

- **macOS 전용**: 크로스플랫폼 불가
- **학습 곡선**: Swift, AppKit/SwiftUI, Xcode 빌드 시스템 숙지 필요
- **개발 속도**: Python 대비 초기 개발 시간 증가
- **UI 커스터마이징**: 메뉴바 앱의 커스텀 UI는 NSPopover/SwiftUI 조합 필요

## 구현 난이도: ★★★★☆ (높음)

| 기능 | 난이도 | 비고 |
|------|--------|------|
| 메뉴바 앱 구조 | ★★☆☆☆ | NSStatusItem 기본 패턴 확립 |
| 오디오 녹음 | ★★☆☆☆ | AVFoundation 표준 API |
| Whisper 전사 | ★★★☆☆ | WhisperKit SPM 통합, 모델 관리 필요 |
| 글로벌 단축키 | ★★☆☆☆ | KeyboardShortcuts 패키지 사용 시 간단 |
| 클립보드 + 붙여넣기 | ★★★☆☆ | NSPasteboard 쉬움, CGEvent 시뮬레이션에 접근성 권한 필요 |
| 설정 관리 | ★☆☆☆☆ | UserDefaults 또는 Codable JSON |
| **전체** | **★★★★☆** | Swift/Xcode 경험 없으면 러닝커브 큼 |

## 확장성

- **macOS 심층 기능**: Shortcuts.app 통합, 위젯, Spotlight 연동, Share Extension
- **실시간 전사**: AVAudioEngine 스트리밍 + WhisperKit으로 실시간 STT 가능
- **다중 모델**: CoreML 모델 교체로 다양한 크기/언어 모델 지원
- **SwiftUI**: 설정 화면, 전사 이력 등 풍부한 UI 확장 용이
- **visionOS/iOS 확장**: 동일 코드베이스로 Apple 플랫폼 확장 가능

## 핵심 의존성

```
// Package.swift
dependencies: [
    .package(url: "https://github.com/argmaxinc/WhisperKit", from: "0.9.0"),
    .package(url: "https://github.com/sindresorhus/KeyboardShortcuts", from: "2.0.0"),
]
```

## 음성 인식 엔진 선택지

| 엔진 | 장점 | 단점 |
|------|------|------|
| **WhisperKit** | CoreML 네이티브, ANE 활용, SPM 통합 | macOS 14.0+ 필요 |
| **MLXAudio Swift** | MLX 네이티브, 최고 속도 | 문서 부족, 상대적으로 새로움 |
| **whisper.cpp + CoreML** | 검증된 안정성, C 라이브러리 | Swift 브릿징 필요 |

## 권장 아키텍처

```
App (SwiftUI App lifecycle)
├── StatusBarController      // NSStatusItem + NSMenu 관리
├── AudioRecorder           // AVFoundation 녹음
├── WhisperTranscriber      // WhisperKit 전사
├── HotkeyManager          // KeyboardShortcuts 글로벌 단축키
├── ClipboardManager       // NSPasteboard + CGEvent 붙여넣기
└── ConfigManager          // UserDefaults / JSON 설정
```
