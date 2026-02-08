# 의존성 라이브러리

## 외부 라이브러리

| 라이브러리 | 용도 | 비고 |
|-----------|------|------|
| **rumps** | macOS 메뉴바 앱 프레임워크 | 앱 구조, 메뉴, 타이머, 알림 |
| **pyaudio** | 마이크 오디오 녹음 | PortAudio 바인딩 |
| **mlx_whisper** | 음성 → 텍스트 전사 | Apple Silicon MLX 기반 Whisper |
| **pyperclip** | 클립보드 복사 | 전사 텍스트를 클립보드에 저장 |
| **pyautogui** | GUI 자동화 | `Cmd+V` 붙여넣기 자동 실행 |
| **pynput** | 글로벌 키보드 리스너 | 단축키 감지 (녹음 토글, 언어 전환) |

## 표준 라이브러리

| 모듈 | 용도 |
|------|------|
| `threading` | 녹음/전사 백그라운드 스레드, Event 동기화 |
| `tempfile` | 임시 WAV 파일 생성 |
| `wave` | WAV 파일 쓰기 |
| `json` | 설정 파일 읽기/쓰기 |
| `os` | 임시 파일 삭제 |
| `pathlib` | 설정 파일 경로 처리 |
| `queue` | 스레드 안전 UI 작업 큐 |
| `traceback` | 에러 스택트레이스 출력 |
| `time` | 붙여넣기 전 딜레이 |

## 기본 설정값

```json
{
  "record_hotkey": "ctrl+shift+m",
  "lang_hotkey": "cmd+shift+space",
  "language": "ko",
  "model": "mlx-community/whisper-large-v3-turbo"
}
```
