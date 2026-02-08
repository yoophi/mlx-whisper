# 녹음 중 Overlay UI 표시 — 프레임워크별 지원 현황

녹음 중 화면 위에 항상 떠 있는 상태 표시 오버레이(예: 빨간 녹음 인디케이터, 파형 시각화 등)를 구현하기 위한 프레임워크별 기능 비교.

## 요구되는 오버레이 특성

| 특성 | 설명 |
|------|------|
| Always-on-top | 다른 윈도우 위에 항상 표시 |
| 투명 배경 | 윈도우 배경이 투명하여 콘텐츠만 보임 |
| Frameless | 타이틀바/테두리 없는 윈도우 |
| 클릭 통과 | 오버레이를 클릭하면 아래 윈도우로 이벤트 전달 |
| 윈도우 레벨 제어 | floating, screenSaver 등 세밀한 z-order 제어 |
| 커스텀 형태 | 원형, 둥근 모서리 등 비사각형 윈도우 |

## 종합 비교표

| 기능 | Swift | Tauri | Electron | Wails |
|------|:-----:|:-----:|:--------:|:-----:|
| Always-on-top | ✅ | ✅ | ✅ | ✅ |
| 투명 배경 | ✅ | ✅ | ✅ | ⚠️ 제한적 |
| Frameless 윈도우 | ✅ | ✅ | ✅ | ✅ |
| 클릭 통과 | ✅ | ✅ | ✅ | ❌ |
| 윈도우 레벨 세밀 제어 | ✅ | ❌ | ⚠️ 제한적 | ❌ |
| 커스텀 형태 (원형 등) | ✅ | ✅ | ✅ | ⚠️ 제한적 |
| 네이티브 블러/비주얼 이펙트 | ✅ | ❌ | ❌ | ❌ |
| **종합 적합도** | **★★★★★** | **★★★★☆** | **★★★★☆** | **★★☆☆☆** |

## Swift Native — 최고 수준

macOS 네이티브 API로 오버레이의 모든 측면을 완벽하게 제어할 수 있다.

### 핵심 API

- **NSPanel**: 유틸리티 윈도우, `nonactivatingPanel` 스타일로 포커스를 가져가지 않음
- **NSWindow.Level**: `.floating`, `.statusBar`, `.screenSaver` 등 세밀한 레벨 제어
- **ignoresMouseEvents**: 클릭이 아래 윈도우로 통과
- **NSVisualEffectView**: macOS 네이티브 블러/바이브런시 효과

### 구현 예시

```swift
let overlay = NSPanel(
    contentRect: NSRect(x: 0, y: 0, width: 80, height: 80),
    styleMask: [.borderless, .nonactivatingPanel],
    backing: .buffered, defer: false
)
overlay.level = .floating          // 항상 위에 표시
overlay.isOpaque = false           // 투명 배경 활성화
overlay.backgroundColor = .clear   // 배경 투명
overlay.ignoresMouseEvents = true  // 클릭 통과
overlay.hasShadow = false          // 그림자 제거
overlay.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
// → 모든 데스크톱 Space + 전체화면 앱 위에서도 표시
```

### 강점

- `NSWindow.Level`로 `.floating`, `.tornOffMenu`, `.statusBar`, `.screenSaver` 등 7단계 이상의 레벨 선택 가능
- `NSVisualEffectView`로 macOS 네이티브 블러 효과 적용 가능
- SwiftUI `View`를 `NSHostingView`로 감싸서 오버레이 콘텐츠로 사용 가능
- Core Animation으로 녹음 파형, 펄스 애니메이션 등 부드러운 효과 구현
- `collectionBehavior`로 전체화면 앱 위, 모든 Space에서 표시 등 세밀 제어

### 제약

- macOS 전용
- AppKit/SwiftUI 숙지 필요

---

## Tauri — 충분히 가능

Tauri v2는 투명 윈도우, 클릭 통과 등 오버레이에 필요한 주요 기능을 공식 지원한다.

### 핵심 API

- **tauri.conf.json**: `always_on_top`, `transparent`, `decorations` 등 윈도우 속성 선언적 설정
- **WebviewWindow**: Rust 측에서 프로그래밍 방식 윈도우 생성
- **set_ignore_cursor_events**: 클릭 통과 설정

### 구현 예시

**설정 (tauri.conf.json)**:
```json
{
  "app": {
    "windows": [
      {
        "label": "overlay",
        "url": "/overlay",
        "width": 80,
        "height": 80,
        "always_on_top": true,
        "transparent": true,
        "decorations": false,
        "resizable": false,
        "skip_taskbar": true,
        "shadow": false
      }
    ]
  }
}
```

**Rust 측 (클릭 통과)**:
```rust
use tauri::Manager;

fn setup_overlay(app: &tauri::App) -> Result<(), Box<dyn std::error::Error>> {
    let overlay = app.get_webview_window("overlay")
        .expect("overlay window not found");
    overlay.set_ignore_cursor_events(true)?;
    Ok(())
}
```

**프론트엔드 (overlay.html)**:
```html
<style>
  body { background: transparent; margin: 0; }
  .indicator {
    width: 60px; height: 60px;
    background: rgba(255, 59, 48, 0.9);
    border-radius: 50%;
    animation: pulse 1.5s infinite;
  }
  @keyframes pulse {
    0%, 100% { transform: scale(1); opacity: 1; }
    50% { transform: scale(1.1); opacity: 0.7; }
  }
</style>
<div class="indicator"></div>
```

### 강점

- 웹 기술(HTML/CSS)로 오버레이 디자인 자유도 높음
- CSS 애니메이션으로 녹음 인디케이터, 파형 등 시각 효과 구현 용이
- 크로스플랫폼 (macOS/Windows/Linux)
- `skip_taskbar`으로 독/태스크바에 표시되지 않음

### 제약

- 윈도우 레벨(z-order) 세밀 제어 불가 — `always_on_top`은 단일 레벨만 제공
- macOS 전체화면 앱 위 표시는 추가 네이티브 코드 필요
- 네이티브 블러/비주얼 이펙트 직접 사용 불가
- macOS에서 `transparent: true` 사용 시 일부 WebView 렌더링 이슈 가능

---

## Electron — 충분히 가능

Electron은 오버레이 윈도우 구현에 필요한 API를 모두 내장하고 있으며, 가장 많은 레퍼런스가 존재한다.

### 핵심 API

- **BrowserWindow**: `alwaysOnTop`, `transparent`, `frame`, `focusable` 등 옵션
- **setIgnoreMouseEvents**: 클릭 통과
- **setAlwaysOnTop(flag, level)**: macOS에서 윈도우 레벨 부분적 제어

### 구현 예시

**Main process**:
```javascript
const { BrowserWindow } = require('electron');

function createOverlay() {
    const overlay = new BrowserWindow({
        width: 80,
        height: 80,
        alwaysOnTop: true,
        transparent: true,
        frame: false,
        resizable: false,
        skipTaskbar: true,
        focusable: false,
        hasShadow: false,
        webPreferences: {
            preload: path.join(__dirname, 'preload.js'),
        },
    });

    // 클릭 통과
    overlay.setIgnoreMouseEvents(true);

    // macOS: 윈도우 레벨 제어 (제한적)
    // 'floating', 'torn-off-menu', 'modal-panel',
    // 'main-menu', 'status', 'pop-up-menu', 'screen-saver'
    overlay.setAlwaysOnTop(true, 'floating');

    // 모든 데스크톱 Space에서 표시
    overlay.setVisibleOnAllWorkspaces(true, {
        visibleOnFullScreen: true,
    });

    overlay.loadFile('overlay.html');
    return overlay;
}
```

**overlay.html**:
```html
<style>
  html, body { background: transparent; margin: 0; overflow: hidden; }
  .recording-dot {
    width: 60px; height: 60px;
    background: rgba(255, 59, 48, 0.9);
    border-radius: 50%;
    animation: pulse 1.5s ease-in-out infinite;
  }
  @keyframes pulse {
    0%, 100% { opacity: 1; }
    50% { opacity: 0.5; }
  }
</style>
<div class="recording-dot"></div>
```

### 강점

- `setAlwaysOnTop(true, level)`로 macOS 윈도우 레벨 부분적 제어 가능 (`floating`, `status`, `screen-saver` 등)
- `setVisibleOnAllWorkspaces(true, { visibleOnFullScreen: true })`로 전체화면 앱 위 + 모든 Space 표시
- 가장 많은 오버레이 구현 예제와 커뮤니티 레퍼런스 존재
- 웹 기술로 풍부한 UI/애니메이션

### 제약

- 오버레이 윈도우 하나에 별도 Chromium 렌더러 프로세스 생성 → 메모리 추가 소모
- 메뉴바 앱 + 오버레이 조합이면 Chromium 프로세스 2개 이상 → 리소스 과다
- 투명 윈도우 렌더링 성능이 네이티브 대비 떨어질 수 있음

---

## Wails — 제한적

Wails v3 alpha는 기본적인 윈도우 옵션은 제공하지만, 오버레이에 필요한 핵심 기능이 부족하다.

### 핵심 API

- **WebviewWindowOptions**: `AlwaysOnTop`, `Frameless` 등 기본 옵션
- 투명 배경, 클릭 통과는 공식 API 미지원

### 구현 예시

```go
overlayWindow := app.NewWebviewWindowWithOptions(application.WebviewWindowOptions{
    Name:        "overlay",
    Title:       "",
    Width:       80,
    Height:      80,
    AlwaysOnTop: true,
    Frameless:   true,
    URL:         "/overlay",
    // transparent, ignoreMouseEvents 등은 공식 옵션에 없음
})
```

### 강점

- Always-on-top + Frameless 기본 지원
- Go 백엔드에서 윈도우 제어 로직 구현 용이

### 제약

- **투명 배경**: v3 alpha에서 플랫폼별로 불안정하거나 미지원. macOS WebView 투명 배경 설정을 위해 네이티브 코드 패치가 필요할 수 있음
- **클릭 통과(ignoreMouseEvents)**: 공식 API 없음. macOS에서 구현하려면 CGO를 통해 `NSWindow.ignoresMouseEvents`를 직접 설정해야 함
- **윈도우 레벨 제어**: `AlwaysOnTop` 단일 옵션만 존재, 세밀한 레벨 제어 불가
- **전체화면 앱 위 표시**: 별도 네이티브 코드 필요
- **v3 alpha 불안정성**: 윈도우 관련 API가 변경될 수 있음

### 우회 방안

```go
// CGO를 통한 네이티브 NSWindow 접근 (macOS 전용)
/*
#cgo CFLAGS: -x objective-c
#cgo LDFLAGS: -framework Cocoa
#import <Cocoa/Cocoa.h>

void setWindowIgnoresMouseEvents(void* nsWindow) {
    NSWindow* window = (__bridge NSWindow*)nsWindow;
    [window setIgnoresMouseEvents:YES];
    [window setBackgroundColor:[NSColor clearColor]];
    [window setOpaque:NO];
}
*/
import "C"
```

이 방식은 macOS 전용이며 Wails 내부 구현에 의존하므로 유지보수 부담이 크다.

---

## 오버레이 UI 유형별 적합도

메뉴바 음성 녹음 앱에서 활용 가능한 오버레이 유형별 프레임워크 적합도.

### 1. 최소 인디케이터 (녹음 점)

화면 구석에 작은 빨간 점으로 녹음 상태 표시.

| 프레임워크 | 적합도 | 비고 |
|-----------|--------|------|
| Swift | ★★★★★ | NSPanel + Core Animation |
| Tauri | ★★★★☆ | 투명 윈도우 + CSS 애니메이션 |
| Electron | ★★★★☆ | BrowserWindow + CSS |
| Wails | ★★☆☆☆ | 투명 배경/클릭 통과 우회 필요 |

### 2. 파형/볼륨 시각화

녹음 중 실시간 오디오 파형 또는 볼륨 미터 표시.

| 프레임워크 | 적합도 | 비고 |
|-----------|--------|------|
| Swift | ★★★★★ | Core Animation + AVAudioEngine 실시간 데이터 |
| Electron | ★★★★☆ | Web Audio API + Canvas/WebGL |
| Tauri | ★★★☆☆ | 프론트엔드 Canvas + Rust IPC로 오디오 데이터 전달 |
| Wails | ★★☆☆☆ | 투명 윈도우 이슈 + Go→프론트엔드 데이터 전달 |

### 3. 전사 결과 플로팅 표시

전사 완료 후 결과 텍스트를 일시적으로 화면에 표시.

| 프레임워크 | 적합도 | 비고 |
|-----------|--------|------|
| Swift | ★★★★★ | NSPanel + 페이드 애니메이션 |
| Electron | ★★★★☆ | BrowserWindow + CSS transition |
| Tauri | ★★★★☆ | 투명 윈도우 + CSS transition |
| Wails | ★★★☆☆ | 기본 윈도우로 가능, 투명 배경 불안정 |

---

## 결론

**Swift > Tauri ≈ Electron >> Wails** 순으로 오버레이 구현 적합도가 높다.

- **Swift**: macOS 오버레이의 모든 것을 네이티브로 제어. 성능, 품질, 유연성 모두 최고
- **Tauri**: 실용적으로 충분. 웹 기술로 디자인 자유도 높고, 클릭 통과/투명 배경 공식 지원
- **Electron**: Tauri와 동급 기능이나, 오버레이 하나에 Chromium 프로세스 추가 생성이라는 리소스 부담
- **Wails**: 기본적인 Always-on-top 윈도우는 가능하나, 투명 배경/클릭 통과에 네이티브 우회 코드가 필요하여 오버레이 용도로는 부적합
