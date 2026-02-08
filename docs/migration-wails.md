# Wails 전환 계획

## 개요

Go 백엔드 + 웹 프론트엔드 기반 경량 크로스플랫폼 앱으로 전환. 현재 Wails v3 alpha 상태.

## 기술 스택

| 현재 (Python) | 전환 후 (Wails) |
|--------------|----------------|
| rumps | Wails 시스템 트레이 API |
| pyaudio | gordonklaus/portaudio (Go PortAudio 바인딩) |
| mlx_whisper | ggerganov/whisper.cpp Go 바인딩 |
| pyperclip | Go clipboard 패키지 |
| pyautogui | go-vgo/robotgo |
| pynput | **미지원** (v3 alpha에서 글로벌 단축키 미구현) |
| json config | encoding/json (표준 라이브러리) |

## 강점

- **Go 언어의 접근성**: Rust보다 낮은 학습 곡선, Python 개발자 전환 용이
- **경량 바이너리**: 10~15MB, 시스템 WebView 사용
- **간결한 코드**: Go의 심플한 문법, goroutine으로 동시성 처리 직관적
- **시스템 트레이**: 다크/라이트 모드 적응형 아이콘, 윈도우 연동 지원
- **크로스플랫폼**: macOS, Windows, Linux 지원
- **빠른 빌드**: Go 컴파일 속도 빠름

## 단점

- **v3 alpha 상태**: API 변경 가능성, 프로덕션 안정성 미검증
- **글로벌 단축키 미지원**: v3에서 아직 구현되지 않음 (GitHub Issue #3112). 이 앱의 핵심 기능이므로 치명적
- **whisper.cpp Go 바인딩 빌드 복잡**: C 라이브러리(libwhisper.a) 컴파일 + CGO 환경 변수 설정 필요
- **PortAudio 의존**: Go 오디오 라이브러리가 PortAudio 시스템 라이브러리에 의존
- **생태계 규모**: Tauri/Electron 대비 커뮤니티 작음, 플러그인/예제 부족
- **macOS 깊은 통합 제한**: 크로스플랫폼 추상화 레이어의 한계

## 구현 난이도: ★★★☆☆ (중간)

| 기능 | 난이도 | 비고 |
|------|--------|------|
| 메뉴바/시스템 트레이 | ★★☆☆☆ | v3 시스템 트레이 API 지원 |
| 오디오 녹음 | ★★★☆☆ | portaudio Go 바인딩, 시스템 라이브러리 필요 |
| Whisper 전사 | ★★★★☆ | C 라이브러리 빌드 + CGO 설정 복잡 |
| 글로벌 단축키 | ★★★★★ | **미지원** — 별도 구현 또는 3rd party 필요 |
| 클립보드 + 붙여넣기 | ★★☆☆☆ | clipboard + robotgo |
| 설정 관리 | ★☆☆☆☆ | Go 표준 라이브러리 json |
| **전체** | **★★★☆☆** | 글로벌 단축키 문제만 해결되면 수월 |

## 확장성

- **Go 생태계 활용**: 풍부한 Go 라이브러리 (HTTP 서버, DB, gRPC 등) 연동 용이
- **웹 UI**: React, Vue, Svelte 등으로 설정 화면, 전사 이력 UI 구축 가능
- **크로스플랫폼**: 코드베이스 공유로 Windows/Linux 지원
- **goroutine**: 동시성 처리가 자연스러워 스트리밍 전사 등 확장 편리
- **v3 안정화 대기**: 정식 릴리스 후 API 안정성 및 기능 추가 기대

## 핵심 의존성

```go
// go.mod
require (
    github.com/wailsapp/wails/v3 v3.0.0-alpha
    github.com/ggerganov/whisper.cpp/bindings/go v0.0.0
    github.com/gordonklaus/portaudio v0.0.0
    github.com/go-vgo/robotgo v1.0.0
    github.com/atotto/clipboard v0.1.4
)
```

**시스템 요구사항:**
```bash
# macOS
brew install portaudio
# whisper.cpp 빌드
cd whisper.cpp && make libwhisper.a
export C_INCLUDE_PATH=/path/to/whisper.cpp
export LIBRARY_PATH=/path/to/whisper.cpp
```

## 음성 인식 엔진

| 엔진 | 장점 | 단점 |
|------|------|------|
| **whisper.cpp Go 바인딩** | 공식 바인딩, 기본 기능 충분 | CGO 빌드 복잡, CoreML 연동 어려움 |
| **go-whisper** | 커뮤니티 패키지, OpenAI API 폴백 | 로컬 전사 성능은 동일 |

## 글로벌 단축키 우회 방안

Wails v3에서 글로벌 단축키가 미지원이므로 아래 방법을 고려해야 한다:

1. **CGO로 Carbon API 직접 호출**: macOS 전용, C 바인딩 작성 필요
2. **go-hook 등 3rd party**: 크로스플랫폼 키 이벤트 라이브러리 사용
3. **robotgo의 이벤트 리스너**: robotgo.EventHook으로 키 이벤트 감지 가능 (제한적)
4. **v3 정식 릴리스 대기**: 기능 추가될 가능성 있음

## 권장 아키텍처

```
Wails App
├── main.go              # 앱 진입점, 시스템 트레이 설정
├── audio.go             # PortAudio 녹음
├── whisper.go           # whisper.cpp 전사
├── hotkey.go            # 글로벌 단축키 (우회 구현)
├── clipboard.go         # 클립보드 + 붙여넣기
├── config.go            # JSON 설정 관리
└── frontend/            # 웹 프론트엔드
    └── ...
```
