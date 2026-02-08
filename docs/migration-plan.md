# macOS Native Application 전환 계획

현재 Python 기반 메뉴바 앱(`app.py`)을 네이티브/크로스플랫폼 앱으로 전환하기 위한 프레임워크별 비교 분석.

## 현재 앱 구성 요약

| 기능 | 현재 구현 |
|------|----------|
| 메뉴바 앱 | rumps (NSStatusItem 래퍼) |
| 오디오 녹음 | pyaudio (PortAudio 바인딩) |
| 음성 전사 | mlx_whisper (Apple Silicon MLX) |
| 클립보드 + 붙여넣기 | pyperclip + pyautogui |
| 글로벌 단축키 | pynput |
| 설정 관리 | JSON 파일 (~/.config/) |

## 핵심 전환 과제

**mlx_whisper는 Python 전용**이므로, 각 프레임워크에서 대체 음성 인식 엔진이 필요하다.

| 프레임워크 | 대체 엔진 | 비고 |
|-----------|----------|------|
| Swift | WhisperKit (CoreML) / MLXAudio Swift | 네이티브, 최고 성능 |
| Tauri | whisper-rs (whisper.cpp Rust 바인딩) | CoreML 가속 가능 |
| Wails | Go whisper.cpp 바인딩 | C 라이브러리 컴파일 필요 |
| Electron | whisper-node-addon / nodejs-whisper | 실험적 단계 |

## 프레임워크별 상세 비교

→ 개별 상세 문서 참조:
- [Native Swift](./migration-swift.md)
- [Tauri (Rust)](./migration-tauri.md)
- [Wails (Go)](./migration-wails.md)
- [Electron (Node.js)](./migration-electron.md)

## 종합 비교표

| 항목 | Swift Native | Tauri | Wails | Electron |
|------|:-----------:|:-----:|:-----:|:--------:|
| **구현 난이도** | ★★★★☆ | ★★★☆☆ | ★★★☆☆ | ★★☆☆☆ |
| **성능** | ★★★★★ | ★★★★☆ | ★★★★☆ | ★★☆☆☆ |
| **앱 크기** | ~5-15MB | ~5-10MB | ~10-15MB | ~150MB+ |
| **메모리 사용** | 최소 | 적음 | 적음 | 많음 (Chromium) |
| **macOS 통합도** | ★★★★★ | ★★★☆☆ | ★★★☆☆ | ★★☆☆☆ |
| **크로스플랫폼** | macOS only | Win/Mac/Linux | Win/Mac/Linux | Win/Mac/Linux |
| **생태계 성숙도** | ★★★★★ | ★★★★☆ | ★★☆☆☆ (v3 alpha) | ★★★★★ |
| **Whisper 통합** | WhisperKit (네이티브) | whisper-rs | Go 바인딩 | Node addon |
| **글로벌 단축키** | 안정 (3rd party) | 안정 (플러그인) | 미구현 (v3) | 안정 (내장) |
| **확장성** | macOS 심층 기능 | 웹 UI 자유도 | 웹 UI 자유도 | 최대 유연성 |

> ★ 점수가 높을수록 난이도 높음(구현 난이도) 또는 우수함(나머지 항목)

## 권장 선택 가이드

### macOS 전용 + 최고 품질 → **Swift Native**
- Apple Silicon 최적화, 최소 리소스, 네이티브 UX
- WhisperKit으로 최고 수준의 음성 인식 성능
- 단점: macOS 전용, Swift/AppKit 학습 곡선

### 크로스플랫폼 + 경량 → **Tauri**
- 작은 바이너리, 낮은 메모리, Rust 성능
- whisper-rs + CoreML 가속으로 준수한 전사 성능
- 단점: Rust 학습 곡선, macOS 마이크 권한 버그 존재

### 빠른 프로토타이핑 + 웹 기술 → **Electron**
- 가장 빠른 개발 속도, 풍부한 npm 생태계
- 단점: 메모리/디스크 과다 사용, 메뉴바 앱으로는 과도함

### Go 생태계 활용 → **Wails**
- Go 백엔드 + 웹 프론트엔드, 경량
- 단점: v3 alpha 상태, 글로벌 단축키 미지원
