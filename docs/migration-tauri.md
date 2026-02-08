# Tauri 전환 계획

## 개요

Rust 백엔드 + 웹 프론트엔드 기반 경량 크로스플랫폼 앱으로 전환. 현재 Tauri v2.10 안정 버전 사용.

## 기술 스택

| 현재 (Python) | 전환 후 (Tauri) |
|--------------|----------------|
| rumps | tray-icon (Tauri 내장 시스템 트레이) |
| pyaudio | cpal / tauri-plugin-mic-recorder |
| mlx_whisper | whisper-rs (whisper.cpp Rust 바인딩) + CoreML |
| pyperclip | tauri-plugin-clipboard-manager |
| pyautogui | enigo (Rust 키보드 시뮬레이션) |
| pynput | tauri-plugin-global-shortcut |
| json config | tauri-plugin-store 또는 serde_json |

## 강점

- **경량 바이너리**: 5~10MB (Electron 대비 1/15 수준)
- **낮은 메모리 사용**: 시스템 WebView 활용, Chromium 미포함
- **Rust 성능**: 백엔드 로직이 네이티브 속도로 실행
- **크로스플랫폼**: macOS, Windows, Linux 지원
- **풍부한 플러그인**: 시스템 트레이, 글로벌 단축키, 클립보드 등 공식 플러그인 제공
- **보안 모델**: IPC 기반 권한 시스템으로 프론트엔드-백엔드 격리
- **웹 UI 자유도**: React, Vue, Svelte 등 프론트엔드 프레임워크 자유 선택

## 단점

- **Rust 학습 곡선**: 소유권, 라이프타임 등 Rust 특유의 개념 습득 필요
- **macOS 마이크 권한 버그**: 서명된 앱에서 마이크 권한 팝업이 나타나지 않는 알려진 버그 (tauri#9928)
- **whisper-rs 빌드 복잡도**: whisper.cpp C 라이브러리 컴파일 + CoreML 플래그 설정 필요
- **디버깅**: Rust + WebView 양쪽 디버깅 필요
- **macOS 전용 기능 제한**: 크로스플랫폼 추상화로 인해 깊은 macOS 통합은 제한적

## 구현 난이도: ★★★☆☆ (중간)

| 기능 | 난이도 | 비고 |
|------|--------|------|
| 메뉴바/시스템 트레이 | ★★☆☆☆ | 공식 tray-icon 지원 |
| 오디오 녹음 | ★★★☆☆ | cpal 크레이트 사용, macOS 권한 이슈 주의 |
| Whisper 전사 | ★★★★☆ | whisper-rs 빌드 + CoreML 설정 복잡 |
| 글로벌 단축키 | ★☆☆☆☆ | tauri-plugin-global-shortcut 플러그인 |
| 클립보드 + 붙여넣기 | ★★☆☆☆ | 클립보드 플러그인 + enigo |
| 설정 관리 | ★☆☆☆☆ | tauri-plugin-store 또는 serde |
| **전체** | **★★★☆☆** | Rust 경험 있으면 수월, 없으면 ★★★★☆ |

## 확장성

- **크로스플랫폼 배포**: 동일 코드베이스로 Windows/Linux 지원 추가 가능
- **웹 UI 확장**: 설정 화면, 전사 이력, 실시간 파형 표시 등 웹 기술로 자유로운 UI 구축
- **플러그인 생태계**: Tauri 공식/커뮤니티 플러그인으로 기능 확장 용이
- **Rust 백엔드**: 고성능 오디오 처리, 스트리밍 전사 등 확장 가능
- **자동 업데이트**: tauri-plugin-updater로 앱 자동 업데이트 지원

## 핵심 의존성

```toml
# Cargo.toml
[dependencies]
tauri = { version = "2", features = ["tray-icon"] }
whisper-rs = "0.13"
cpal = "0.15"
enigo = "0.2"
serde = { version = "1", features = ["derive"] }
serde_json = "1"

# Tauri plugins
tauri-plugin-global-shortcut = "2"
tauri-plugin-clipboard-manager = "2"
tauri-plugin-notification = "2"
tauri-plugin-store = "2"
```

## 음성 인식 엔진

| 엔진 | 장점 | 단점 |
|------|------|------|
| **whisper-rs** | Rust 네이티브 바인딩, CoreML 가속 가능 | C 라이브러리 빌드 필요 |
| **whisper-rs + CoreML** | ANE 활용, 3~6배 속도 향상 | CoreML 모델 별도 생성 필요 |

## 권장 아키텍처

```
Tauri App
├── src-tauri/           # Rust 백엔드
│   ├── src/
│   │   ├── main.rs
│   │   ├── audio.rs      # cpal 녹음
│   │   ├── whisper.rs    # whisper-rs 전사
│   │   ├── hotkey.rs     # 글로벌 단축키 핸들러
│   │   ├── clipboard.rs  # 클립보드 + 붙여넣기
│   │   └── config.rs     # 설정 관리
│   └── Cargo.toml
└── src/                 # 웹 프론트엔드 (최소한의 트레이 메뉴)
    └── ...
```
