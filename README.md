# VoiceRecorder

macOS 메뉴바 음성 인식 앱. 글로벌 단축키로 음성을 녹음하고, WhisperKit으로 텍스트 전사 후 활성 앱에 자동 붙여넣기합니다.

## 기능

- 메뉴바 상주 (Dock 아이콘 없음)
- 글로벌 단축키로 녹음 시작/중지 (`Ctrl+Shift+M`)
- WhisperKit 기반 온디바이스 음성 인식 (네트워크 불필요, 첫 실행 시 모델 자동 다운로드)
- 전사 결과 클립보드 복사 + 자동 Cmd+V 붙여넣기
- 5개 언어 지원: 한국어, English, 日本語, 中文, Tiếng Việt
- 단축키로 언어 순환 전환 (`Cmd+Shift+Space`)
- 메뉴에서 단축키/언어 변경 가능
- 설정 자동 저장 (`~/.config/voice-recorder/config.json`)

## 요구사항

- macOS 14 (Sonoma) 이상
- Apple Silicon (M1/M2/M3/M4)
- Xcode Command Line Tools (`xcode-select --install`)

## 빌드 & 실행

### 터미널 (Make)

```bash
cd VoiceRecorder

# 빌드 + 실행
make run

# 빌드만
make build

# .app 번들 생성
make bundle

# /Applications에 설치
make install

# 정리
make clean
```

### Xcode

```bash
open VoiceRecorder/Package.swift
```

또는 Xcode에서 **File > Open** → `VoiceRecorder/Package.swift` 선택.

1. 상단 Scheme에서 **VoiceRecorder**, Run Destination에서 **My Mac** 선택
2. **Signing & Capabilities**에서 Team을 본인 Apple ID로 설정
3. `Cmd+R`로 빌드 & 실행

### 로깅

기본적으로 Apple Unified Logging(`os.Logger`, subsystem: `com.voicerecorder.app`)을 사용합니다.

#### 로그 확인 방법

**터미널 — `log stream` (가장 간편):**

```bash
# VoiceRecorder 로그만 실시간 스트리밍
log stream --predicate 'subsystem == "com.voicerecorder.app"' --level debug
```

**Console.app (GUI):**

1. Console.app 실행 (`Cmd+Space` → "Console")
2. 좌측에서 본인 Mac 선택
3. 우측 상단 검색창에 `com.voicerecorder.app` 입력 → 필터에서 **Subsystem** 선택
4. 메뉴 **Action > Include Debug Messages** 체크 (debug 레벨 포함)

**Xcode:**

Xcode에서 `Cmd+R`로 실행하면 하단 콘솔 창에 `os.Logger` 로그가 바로 표시됩니다.

#### print 로거로 전환

터미널에 `[Tag] ...` 형식으로 직접 출력하려면 `--print-log` 인자를 추가합니다:

```bash
# 터미널 직접 실행
./VoiceRecorder.app/Contents/MacOS/VoiceRecorder --print-log

# Xcode에서 설정
# Product > Scheme > Edit Scheme (Cmd+<) > Run > Arguments > Arguments Passed On Launch
# → --print-log 추가
```

## 권한 설정

앱 실행 시 다음 권한이 필요합니다:

| 권한 | 위치 | 용도 |
|------|------|------|
| 마이크 | 시스템 설정 > 개인정보 보호 > 마이크 | 음성 녹음 |
| 접근성 | 시스템 설정 > 개인정보 보호 > 접근성 | Cmd+V 자동 붙여넣기 |

- 마이크 권한은 첫 녹음 시 시스템 다이얼로그로 요청됩니다.
- 접근성 권한은 앱 시작 시 자동으로 다이얼로그가 표시됩니다. 허용 후 앱을 재시작하세요.
- 접근성 권한이 없어도 녹음/전사/클립보드 복사는 동작합니다. 수동으로 Cmd+V로 붙여넣기 가능합니다.

## 사용법

1. `make run`으로 앱 실행 — 메뉴바에 `🎤KR` 표시
2. 첫 실행 시 모델 자동 다운로드 (~1.5GB, 메뉴바에 `📥` 진행률 표시)
3. `Ctrl+Shift+M`으로 녹음 시작 (`🔴`) → 다시 누르면 녹음 중지 (`⏳` 전사 중)
4. 전사 완료 시 텍스트가 활성 앱에 자동 붙여넣기됨 → `🎤`로 복귀
5. `Cmd+Shift+Space`로 언어 전환 (KR → EN → VN → JP → CH)

## 메뉴 구조

```
🎤KR
├── ✅ 모델 준비 완료
├── ─────────────────
├── 녹음 시작 (⌃⇧M)
├── 언어 전환: ⌘⇧Space  (현재: 한국어)
├── ─────────────────
├── 녹음 단축키 설정 ▸
│   ├── ✓ ⌃⇧M
│   ├──    ⌘⇧R
│   ├──    ⌥Space
│   ├──    ⌘⌥Space
│   └──    ⌃⇧Space
├── 전사 언어 ▸
│   ├── ✓ 한국어
│   ├──    English
│   ├──    日本語
│   ├──    中文
│   └──    Tiếng Việt
├── ─────────────────
└── 종료
```

## 설정

설정 파일: `~/.config/voice-recorder/config.json`

```json
{
  "lang_hotkey": "cmd+shift+space",
  "language": "ko",
  "model": "openai_whisper-large-v3_turbo",
  "record_hotkey": "ctrl+shift+m"
}
```

### 사용 가능한 모델

| 모델 | 크기 | 설명 |
|------|------|------|
| `openai_whisper-large-v3_turbo` | ~1.5GB | 기본값. 빠르고 정확 |
| `openai_whisper-large-v3_turbo_954MB` | ~954MB | turbo 양자화 버전 |
| `openai_whisper-large-v3` | ~3GB | 최고 정확도 |
| `openai_whisper-large-v3_947MB` | ~947MB | large-v3 양자화 버전 |

모델은 첫 실행 시 Hugging Face에서 자동 다운로드되며 `~/.voice-recorder/`에 캐시됩니다.

## 프로젝트 구조

Hexagonal Architecture (Ports & Adapters) 패턴을 따릅니다.

```
VoiceRecorder/
├── Package.swift                              # WhisperKit, HotKey 의존성
├── Makefile                                   # 빌드, 번들, 실행, 설치
└── Sources/VoiceRecorder/
    ├── App/
    │   ├── main.swift                         # 진입점 (.accessory 모드)
    │   └── AppDelegate.swift                  # Composition Root
    ├── Domain/
    │   ├── Entities/
    │   │   ├── Language.swift                 # 언어 enum
    │   │   ├── RecordingStatus.swift          # 녹음 상태 enum
    │   │   └── ModelStatus.swift              # 모델 상태 enum
    │   ├── Ports/
    │   │   ├── Driving/
    │   │   │   └── RecordingControl.swift     # 인바운드 포트 (앱 구동)
    │   │   └── Driven/
    │   │       ├── AudioRecording.swift       # 오디오 녹음 포트
    │   │       ├── Transcribing.swift         # 전사 포트
    │   │       ├── ClipboardPasting.swift     # 클립보드 포트
    │   │       ├── HotkeyRegistering.swift    # 단축키 포트
    │   │       ├── Notifying.swift            # 알림 포트
    │   │       ├── ConfigStoring.swift        # 설정 저장 포트
    │   │       └── Logging.swift              # 로깅 포트
    │   └── UseCases/
    │       └── RecordAndTranscribeUseCase.swift  # 핵심 비즈니스 로직
    └── Adapters/
        ├── Inbound/
        │   ├── StatusBarController.swift      # NSStatusItem UI
        │   └── MenuBuilder.swift              # NSMenu 생성
        └── Outbound/
            ├── AudioRecorder.swift            # AVAudioEngine 16kHz 녹음
            ├── WhisperTranscriber.swift        # WhisperKit 전사 (actor)
            ├── ClipboardManager.swift         # 클립보드 + Cmd+V 시뮬레이션
            ├── HotkeyManager.swift            # 글로벌 단축키 관리
            ├── NotificationManager.swift      # 알림 센터
            ├── AppConfig.swift                # JSON 설정 로드/저장
            ├── AppState.swift                 # @MainActor 상태 관리
            ├── UnifiedLogger.swift            # os.Logger 기반 (기본)
            ├── PrintLogger.swift              # print() 기반 (--print-log)
            └── LoggerFactory.swift            # 로거 생성 팩토리
```

## 기술 스택

- **Swift 5.9+** / Swift Package Manager
- **WhisperKit** — Apple Silicon 네이티브 음성 인식 (CoreML)
- **HotKey** — Carbon API 기반 글로벌 단축키
- **AVAudioEngine** — 하드웨어 마이크 녹음, 16kHz 모노 변환
- **CGEvent** — Cmd+V 키보드 이벤트 시뮬레이션

## Python 버전

이전 Python 기반 버전은 `app.py`에 있습니다 (mlx-whisper + rumps + pynput 사용).
