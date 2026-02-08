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

```
VoiceRecorder/
├── Package.swift                          # WhisperKit, HotKey 의존성
├── Makefile                               # 빌드, 번들, 실행, 설치
└── Sources/VoiceRecorder/
    ├── App/
    │   ├── main.swift                     # 진입점 (.accessory 모드)
    │   └── AppDelegate.swift              # 컨트롤러 초기화
    ├── Models/
    │   ├── AppState.swift                 # 녹음/모델 상태
    │   └── Language.swift                 # 언어 enum
    ├── Config/
    │   └── AppConfig.swift                # JSON 설정 로드/저장
    ├── MenuBar/
    │   └── StatusBarController.swift      # NSStatusItem + 녹음 오케스트레이션
    ├── Audio/
    │   └── AudioRecorder.swift            # AVAudioEngine 16kHz 모노 녹음
    ├── Transcription/
    │   └── WhisperTranscriber.swift       # WhisperKit 전사 (actor)
    ├── Hotkey/
    │   └── HotkeyManager.swift            # 글로벌 단축키 관리
    ├── Clipboard/
    │   └── ClipboardManager.swift         # 클립보드 + Cmd+V 시뮬레이션
    └── Notifications/
        └── NotificationManager.swift      # 알림 센터
```

## 기술 스택

- **Swift 5.9+** / Swift Package Manager
- **WhisperKit** — Apple Silicon 네이티브 음성 인식 (CoreML)
- **HotKey** — Carbon API 기반 글로벌 단축키
- **AVAudioEngine** — 하드웨어 마이크 녹음, 16kHz 모노 변환
- **CGEvent** — Cmd+V 키보드 이벤트 시뮬레이션

## Python 버전

이전 Python 기반 버전은 `app.py`에 있습니다 (mlx-whisper + rumps + pynput 사용).
