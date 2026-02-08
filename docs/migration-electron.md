# Electron 전환 계획

## 개요

Node.js + Chromium 기반 크로스플랫폼 데스크톱 앱으로 전환. 현재 Electron v40 안정 버전.

## 기술 스택

| 현재 (Python) | 전환 후 (Electron) |
|--------------|-------------------|
| rumps | Tray API (Electron 내장) |
| pyaudio | Web Audio API + getUserMedia |
| mlx_whisper | whisper-node-addon / nodejs-whisper |
| pyperclip | clipboard API (Electron 내장) |
| pyautogui | robotjs |
| pynput | globalShortcut (Electron 내장) |
| json config | electron-store / fs JSON |

## 강점

- **가장 빠른 개발 속도**: JavaScript/TypeScript 웹 기술 그대로 사용
- **최대 생태계**: npm 패키지 100만+, 거의 모든 기능에 대한 라이브러리 존재
- **풍부한 내장 API**: 시스템 트레이, 글로벌 단축키, 클립보드, 알림 모두 내장
- **크로스플랫폼**: macOS, Windows, Linux 완벽 지원
- **UI 자유도**: 웹 기술로 제한 없는 UI 구축
- **검증된 안정성**: VS Code, Slack, Discord 등 대규모 프로덕션 사용 사례
- **디버깅 용이**: Chrome DevTools 내장

## 단점

- **과도한 리소스 사용**: Chromium 엔진 포함으로 메모리 150MB+ 기본 소모
- **거대한 앱 크기**: 최소 150MB+ (메뉴바 앱으로는 과도함)
- **느린 시작 시간**: Chromium 초기화로 인한 앱 시작 지연
- **Whisper 통합 미성숙**: whisper-node-addon은 실험적 단계, API 변경 가능
- **배터리 소모**: 백그라운드 Chromium 프로세스로 인한 전력 소모
- **macOS 통합 제한**: 네이티브 macOS 기능 접근에 제약
- **보안**: Node.js + Chromium 취약점 관리 필요, 잦은 업데이트 필수

## 구현 난이도: ★★☆☆☆ (낮음)

| 기능 | 난이도 | 비고 |
|------|--------|------|
| 메뉴바/시스템 트레이 | ★☆☆☆☆ | Tray API 내장, 코드 몇 줄 |
| 오디오 녹음 | ★☆☆☆☆ | Web Audio API / getUserMedia 표준 |
| Whisper 전사 | ★★★☆☆ | Node addon 빌드 또는 whisper.cpp 서브프로세스 |
| 글로벌 단축키 | ★☆☆☆☆ | globalShortcut 모듈 내장 |
| 클립보드 + 붙여넣기 | ★☆☆☆☆ | clipboard 내장 + robotjs |
| 설정 관리 | ★☆☆☆☆ | electron-store 패키지 |
| **전체** | **★★☆☆☆** | 웹 개발 경험 있으면 가장 쉬움 |

## 확장성

- **UI 확장 무제한**: React/Vue/Svelte로 복잡한 설정 UI, 전사 이력, 실시간 파형 등 자유롭게 구축
- **npm 생태계**: 거의 모든 기능에 대한 패키지 존재
- **크로스플랫폼 완벽 지원**: 동일 코드베이스로 3대 OS 지원
- **자동 업데이트**: electron-updater로 자동 업데이트 구현 용이
- **WebGPU/WebAssembly**: 브라우저 기반 ML 추론으로 Whisper 대체 가능 (whisper.cpp WASM)
- **플러그인 시스템**: Node.js 모듈 시스템으로 플러그인 아키텍처 구축 용이

## 핵심 의존성

```json
{
  "dependencies": {
    "electron": "^40.0.0",
    "electron-store": "^10.0.0",
    "robotjs": "^0.6.0"
  },
  "devDependencies": {
    "electron-builder": "^25.0.0"
  }
}
```

**Whisper 옵션:**
```json
// 옵션 A: Node addon (실험적)
{ "@kutalia/whisper-node-addon": "latest" }

// 옵션 B: 안정적인 커뮤니티 패키지
{ "nodejs-whisper": "latest" }

// 옵션 C: whisper.cpp 서브프로세스 호출
// 별도 바이너리 번들링
```

## 음성 인식 엔진

| 엔진 | 장점 | 단점 |
|------|------|------|
| **whisper-node-addon** | Electron 자동 감지, GPU 가속 | 실험적, API 불안정 |
| **nodejs-whisper** | 성숙한 커뮤니티 패키지 | 성능 제한적 |
| **whisper.cpp 서브프로세스** | 가장 안정적, CoreML 활용 가능 | 별도 바이너리 번들링 필요 |
| **whisper.cpp WASM** | 추가 바이너리 불필요 | 성능 낮음 |

## 메뉴바 앱으로서의 적합성

Electron은 메뉴바 전용 앱에는 **과도한 선택**이다:

- 단순 메뉴바 앱에 Chromium 런타임은 리소스 낭비
- 사용자가 항시 실행하는 백그라운드 앱이므로 메모리/배터리 영향 큼
- [menubar](https://github.com/nicoquiroga/menubar-app) 같은 경량화 래퍼가 있으나 근본적 한계는 동일

**그럼에도 선택하는 경우:**
- 웹 개발 팀이 빠르게 프로토타이핑할 때
- 추후 복잡한 UI (전사 이력 대시보드, 실시간 파형 등)가 필요할 때
- 크로스플랫폼이 필수이고 개발 리소스가 제한적일 때

## 권장 아키텍처

```
Electron App
├── main/                # Main process
│   ├── index.js          # 앱 진입점, Tray 설정
│   ├── audio.js          # 오디오 녹음 관리
│   ├── whisper.js        # Whisper 전사
│   ├── hotkey.js         # globalShortcut 등록
│   └── config.js         # electron-store 설정
├── renderer/            # Renderer process (최소 트레이 UI)
│   └── ...
├── preload.js           # IPC 브릿지
└── package.json
```
