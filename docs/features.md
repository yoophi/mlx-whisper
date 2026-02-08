# 기능 소개

macOS 메뉴바 상주형 음성 인식 앱으로, 단축키를 통해 음성을 녹음하고 MLX Whisper로 텍스트 전사 후 자동 붙여넣기한다.

## 핵심 기능

### 1. 음성 녹음
- 글로벌 단축키(기본값: `Ctrl+Shift+M`)로 녹음 시작/중지 토글
- 16kHz, 모노, 16bit PCM 포맷으로 녹음
- 백그라운드 스레드에서 녹음 수행

### 2. 음성 전사 (Speech-to-Text)
- MLX Whisper (`mlx-community/whisper-large-v3-turbo` 모델) 사용
- 녹음 종료 시 임시 WAV 파일 생성 후 전사
- 전사 완료 후 임시 파일 자동 삭제

### 3. 자동 붙여넣기
- 전사된 텍스트를 클립보드에 복사 (pyperclip)
- `Cmd+V` 단축키를 자동 실행하여 현재 커서 위치에 붙여넣기 (pyautogui)

### 4. 다국어 지원
- 지원 언어: 한국어(ko), English(en), 日本語(ja), 中文(zh), Tiếng Việt(vi)
- 메뉴에서 직접 언어 선택 가능
- 언어 순환 전환 단축키: `Cmd+Shift+Space`
- 메뉴바 아이콘에 현재 언어 배지 표시 (KR, EN, JP, CH, VN)

### 5. 단축키 설정
- 녹음 토글 단축키 변경 가능
  - `Ctrl+Shift+M` (기본값)
  - `Cmd+Shift+R`
  - `Alt+Space`
  - `Cmd+Alt+Space`
  - `Ctrl+Shift+Space`
- 언어 전환 단축키: `Cmd+Shift+Space` (고정)
- pynput 라이브러리를 이용한 글로벌 단축키 감지

### 6. 설정 파일
- 경로: `~/.config/voice-recorder/config.json`
- 저장 항목: 녹음 단축키, 언어 전환 단축키, 전사 언어, 모델 경로
- 구버전 호환: `hotkey` 키를 `record_hotkey`로 자동 마이그레이션

## 메뉴바 상태 표시

| 아이콘 | 상태 |
|--------|------|
| 🎤 + 언어배지 | 대기 중 |
| 🔴 + 언어배지 | 녹음 중 |
| ⏳ + 언어배지 | 전사 처리 중 |

## 스레드 구조

- **메인 스레드**: rumps 이벤트 루프, UI 업데이트, 알림 표시
- **녹음 스레드**: 오디오 데이터 수집 (daemon)
- **전사 스레드**: WAV 저장 + Whisper 전사 + 붙여넣기 (daemon)
- **핫키 리스너 스레드**: pynput 글로벌 키 감지

메인 스레드 안전성을 위해 `queue.Queue` 기반 UI 작업 큐와 `threading.Event` 기반 핫키 이벤트를 사용하며, 50ms 간격 타이머로 폴링 처리한다.
