# Plan: app.py → Native Swift macOS Menu Bar App 전환

## Context

현재 Python 기반 메뉴바 음성 인식 앱(`app.py`)을 Swift Package 기반 네이티브 macOS 앱으로 전환한다. 사용자가 선택한 기술 스택: **WhisperKit** (음성 인식), **HotKey** (글로벌 단축키), **Swift Package** (프로젝트 구조).

## 프로젝트 구조

```
VoiceRecorder/
├── Package.swift
├── Sources/VoiceRecorder/
│   ├── App/
│   │   ├── main.swift                 # 진입점, .accessory 모드
│   │   └── AppDelegate.swift          # 컨트롤러 초기화, 라이프사이클
│   ├── Models/
│   │   ├── AppState.swift             # 앱 상태 (recording status, config)
│   │   └── Language.swift             # 언어 enum (badge, displayName, cycle)
│   ├── Config/
│   │   └── AppConfig.swift            # Codable JSON 설정 (~/.config/voice-recorder/)
│   ├── MenuBar/
│   │   └── StatusBarController.swift  # NSStatusItem + NSMenu + 녹음/전사 오케스트레이션
│   ├── Audio/
│   │   └── AudioRecorder.swift        # AVAudioEngine 16kHz 모노 녹음
│   ├── Transcription/
│   │   └── WhisperTranscriber.swift   # WhisperKit 모델 로드 + 전사 (actor)
│   ├── Hotkey/
│   │   └── HotkeyManager.swift        # HotKey 라이브러리 래퍼, 핫키 문자열 파싱
│   ├── Clipboard/
│   │   └── ClipboardManager.swift     # NSPasteboard + CGEvent Cmd+V 시뮬레이션
│   └── Notifications/
│       └── NotificationManager.swift  # UNUserNotificationCenter 래퍼
└── Makefile                           # swift build + .app 번들 생성
```

## 의존성

```swift
// Package.swift - macOS 14+
dependencies: [
    .package(url: "https://github.com/argmaxinc/WhisperKit.git", from: "0.15.0"),
    .package(url: "https://github.com/soffes/HotKey.git", from: "0.2.1"),
]
```

## 구현 순서 (11개 파일)

### Step 1: Package.swift
- executableTarget `VoiceRecorder`
- WhisperKit, HotKey 의존성
- AVFoundation, AppKit, Carbon, UserNotifications 프레임워크 링크

### Step 2: Models (AppState.swift, Language.swift)
- `Language` enum: `ko/en/ja/zh/vi`, badge/displayName/cycleOrder/next()
- `AppState`: `@MainActor ObservableObject`, recordingStatus(.idle/.recording/.processing), statusBarTitle 계산

### Step 3: AppConfig.swift
- `~/.config/voice-recorder/config.json` 로드/저장
- 기본값: recordHotkey=`ctrl+shift+m`, langHotkey=`cmd+shift+space`, language=`ko`, model=`large-v3-turbo`
- 구버전 호환: `hotkey` → `record_hotkey` 자동 마이그레이션
- `decodeIfPresent`로 부분 JSON 처리 (Python의 `{**default, **cfg}` 동작 재현)

### Step 4: main.swift + AppDelegate.swift
- `NSApplication.shared.setActivationPolicy(.accessory)` — Dock 아이콘 없는 메뉴바 전용 앱
- AppDelegate에서 모든 컨트롤러 초기화 및 연결

### Step 5: HotkeyManager.swift
- `parseHotkey("ctrl+shift+m")` → HotKey의 `(Key, NSEvent.ModifierFlags)` 변환
- `formatHotkey()` — Python과 동일한 ⌘⇧⌃⌥ 심볼 치환
- HotKey `keyDownHandler`가 메인 스레드에서 직접 실행 → Python의 Event+타이머 폴링 불필요

### Step 6: StatusBarController.swift (가장 큰 파일)
- `NSStatusItem` 생성, 이모지+배지 타이틀 표시
- `buildMenu()` — Python과 동일한 메뉴 구조 (녹음 토글, 언어 정보, 단축키 서브메뉴, 언어 서브메뉴, 종료)
- `NSMenuItem.representedObject`로 단축키/언어 코드 전달
- `toggleRecording()` / `startRecording()` / `stopRecording()` 상태 머신
- `transcribeAndPaste()` — `Task.detached`로 백그라운드 전사, `await MainActor.run`으로 UI 복귀

### Step 7: AudioRecorder.swift
- `AVAudioEngine.inputNode.installTap()` — 하드웨어 녹음
- `AVAudioConverter`로 하드웨어 샘플레이트 → 16kHz 모노 변환
- `[Float]` 버퍼 축적 (NSLock 보호)
- `stopRecording()` → `[Float]` 반환 (WhisperKit이 직접 소비, 임시 WAV 파일 불필요)

### Step 8: WhisperTranscriber.swift
- `actor` 선언으로 스레드 안전
- `WhisperKit(WhisperKitConfig(model:))` — 모델 로드 (최초 실행 시 자동 다운로드)
- `whisperKit.transcribe(audioArray:, decodeOptions:)` — `[Float]` 직접 전사

### Step 9: ClipboardManager.swift
- `NSPasteboard.general.setString()` — 클립보드 복사
- `CGEvent(keyboardEventSource:, virtualKey: kVK_ANSI_V)` + `.maskCommand` — Cmd+V 시뮬레이션
- 100ms 딜레이 후 붙여넣기 (Python과 동일)
- 접근성 권한 필요 (`AXIsProcessTrusted()` 체크)

### Step 10: NotificationManager.swift
- `UNUserNotificationCenter` — 권한 요청 + 알림 전송
- Python의 8종 알림 메시지 그대로 재현

### Step 11: Makefile
- `swift build -c release`
- 빌드 결과물을 `VoiceRecorder.app/Contents/MacOS/`에 복사
- `Info.plist` 생성 (NSMicrophoneUsageDescription 포함)

## Python → Swift 주요 변경점

| 항목 | Python | Swift |
|------|--------|-------|
| 스레드 모델 | threading.Event + 50ms 타이머 폴링 | HotKey 메인스레드 직접 콜백 (이벤트 기반) |
| UI 큐 | queue.Queue → 메인루프 drain | `@MainActor` + `await MainActor.run` |
| 전사 입력 | 임시 WAV 파일 | `[Float]` 배열 직접 전달 (파일 I/O 제거) |
| 모델 이름 | `mlx-community/whisper-large-v3-turbo` | `large-v3-turbo` (WhisperKit 명명 규칙) |

## 검증 방법

1. `swift build` 성공 확인
2. 실행 후 메뉴바에 🎤KR 아이콘 표시 확인
3. Ctrl+Shift+M 단축키로 녹음 시작/중지 확인 (🎤→🔴→⏳→🎤 전환)
4. 전사 결과가 클립보드에 복사되고 Cmd+V로 붙여넣기 되는지 확인
5. Cmd+Shift+Space로 언어 순환 전환 확인 (KR→EN→VN→JP→CH)
6. 메뉴에서 단축키/언어 변경 후 `~/.config/voice-recorder/config.json` 저장 확인
7. 알림 센터에 알림 표시 확인
