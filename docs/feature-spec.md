# app.py 기능 명세서

`VoiceRecorderApp` 클래스가 제공하는 모든 기능을 코드 기반으로 상세 정리한 문서.

---

## 1. 메뉴바 앱 (macOS Status Bar)

### 1.1 상태 아이콘 표시
- **위치**: macOS 상단 메뉴바 (시스템 트레이)
- **구현**: `rumps.App` 상속, `super().__init__("🎤", quit_button=None)`
- **아이콘 형식**: 이모지 + 언어 배지 조합
- **상태별 표시**:

| 상태 | 아이콘 예시 | 발생 시점 |
|------|-----------|----------|
| 대기 중 | `🎤KR` | 앱 시작 시, 전사 완료 후 |
| 녹음 중 | `🔴KR` | `start_recording()` 호출 시 |
| 전사 처리 중 | `⏳KR` | `stop_recording()` 호출 시 |

- **언어 배지 매핑** (`LANG_BADGE`, line 18):
  - `ko` → `KR`, `en` → `EN`, `vi` → `VN`, `ja` → `JP`, `zh` → `CH`
  - 매핑에 없는 언어 코드는 `.upper()` 처리

### 1.2 드롭다운 메뉴 구성
- **구현**: `build_menu()` (line 145-204)
- **메뉴 항목 (위에서 아래 순서)**:

| 순서 | 항목 | 동작 |
|------|------|------|
| 1 | `녹음 시작 (⌃⇧M)` 또는 `🔴 녹음 중지 (⌃⇧M)` | 클릭 시 녹음 토글 |
| 2 | `언어 전환: ⌘⇧Space (현재: ko)` | 정보 표시 전용 (클릭 불가) |
| 3 | ── 구분선 ── | |
| 4 | `녹음 단축키 설정` ▸ (서브메뉴) | 5개 단축키 선택지 |
| 5 | `전사 언어` ▸ (서브메뉴) | 5개 언어 선택지 |
| 6 | ── 구분선 ── | |
| 7 | `종료` | 앱 종료 |

- **메뉴 동적 갱신**: 녹음 상태 변경, 단축키 변경, 언어 변경 시 `build_menu()` 재호출로 전체 메뉴 재구성
- **체크 표시**: 현재 선택된 단축키/언어 앞에 `✓` 표시, 미선택 항목은 공백 3칸

---

## 2. 오디오 녹음

### 2.1 오디오 설정
- **구현**: `__init__()` (line 29-32)
- **파라미터**:

| 설정 | 값 | 비고 |
|------|-----|------|
| 포맷 | `pyaudio.paInt16` | 16bit PCM |
| 채널 | `1` | 모노 |
| 샘플레이트 | `16000` Hz | Whisper 권장 값 |
| 청크 크기 | `1024` samples | 약 64ms 단위 |

### 2.2 녹음 시작
- **구현**: `start_recording()` (line 355-393)
- **동작 순서**:
  1. 중복 녹음 방지: `self.is_recording`이 `True`면 즉시 리턴
  2. 상태 플래그 설정: `self.is_recording = True`, `self.frames = []`
  3. 메뉴바 아이콘 변경: `🔴` + 언어배지
  4. 메뉴 재구성: `build_menu()`
  5. PyAudio 스트림 열기: `self.audio.open(input=True)`
  6. 녹음 스레드 시작: daemon 스레드에서 `self.stream.read()` 반복
- **오류 처리**: 스트림 열기 실패 시 상태 복원 + 알림 표시
- **녹음 스레드**: `exception_on_overflow=False`로 오버플로 에러 무시, 오류 발생 시 알림 후 루프 종료

### 2.3 녹음 중지
- **구현**: `stop_recording()` (line 395-426)
- **동작 순서**:
  1. 상태 플래그 해제: `self.is_recording = False`
  2. 메뉴바 아이콘 변경: `⏳` + 언어배지
  3. 녹음 스레드 대기: `join(timeout=1)`
  4. 스트림 정리: `stop_stream()` → `close()`
  5. 빈 프레임 확인: 녹음 데이터 없으면 대기 상태로 복귀
  6. 프레임 스냅샷 생성: `self.frames[:]`로 복사 후 원본 초기화
  7. 전사 스레드 시작: daemon 스레드에서 `transcribe_and_paste()` 실행

### 2.4 녹음 토글
- **구현**: `toggle_recording(sender)` (line 348-353)
- **동작**: `self.is_recording` 상태에 따라 `start_recording()` 또는 `stop_recording()` 호출
- **트리거**: 메뉴 클릭 또는 글로벌 단축키

---

## 3. 음성 전사 (Speech-to-Text)

### 3.1 전사 처리
- **구현**: `transcribe_and_paste(frames_snapshot)` (line 431-484)
- **실행 환경**: 백그라운드 daemon 스레드
- **동작 순서**:
  1. **WAV 파일 생성**: `tempfile.NamedTemporaryFile(suffix=".wav")`로 임시 파일 생성
  2. **WAV 데이터 쓰기**: `wave.open()`으로 PCM 데이터를 WAV 포맷으로 저장
     - 채널: 1 (모노)
     - 샘플 너비: `pyaudio.paInt16`에 해당하는 바이트 수
     - 프레임레이트: 16000 Hz
  3. **MLX Whisper 호출**: `mlx_whisper.transcribe()` 실행
     - `path_or_hf_repo`: 설정에서 읽은 모델 경로 (기본값: `mlx-community/whisper-large-v3-turbo`)
     - `language`: 설정에서 읽은 언어 코드
  4. **결과 처리**: `result.get("text")` 추출 후 `.strip()`
  5. **임시 파일 삭제**: `os.unlink(temp_path)` (finally 블록에서 항상 실행)
  6. **UI 복원**: 메뉴바 아이콘을 `🎤` + 언어배지로 복원

### 3.2 전사 결과 없는 경우
- **조건**: `text`가 빈 문자열일 때
- **동작**: `"인식된 텍스트가 없습니다."` 알림 표시

---

## 4. 클립보드 복사 및 자동 붙여넣기

### 4.1 클립보드 복사
- **구현**: `transcribe_and_paste()` 내부 (line 455)
- **라이브러리**: `pyperclip.copy(text)`
- **조건**: 전사 텍스트가 비어있지 않을 때만 실행

### 4.2 자동 붙여넣기
- **구현**: `transcribe_and_paste()` 내부 (line 458-466)
- **동작 순서**:
  1. `time.sleep(0.1)` — 클립보드 반영을 위한 100ms 딜레이
  2. 메인 UI 큐에 `do_paste` 등록
  3. 메인 루프에서 `pyautogui.hotkey("command", "v")` 실행
- **이유**: 현재 커서 위치에 전사 텍스트를 자동으로 입력하기 위함
- **오류 처리**: 붙여넣기 실패 시 `"붙여넣기 오류"` 알림

### 4.3 완료 알림
- **구현**: line 468
- **내용**: `"음성 인식 완료"` + 전사 텍스트 처음 50자 (50자 초과 시 `...` 추가)

---

## 5. 글로벌 단축키

### 5.1 단축키 등록 및 감지
- **구현**: `setup_hotkey()` (line 262-298)
- **라이브러리**: `pynput.keyboard.Listener`
- **감지 방식**:
  - `on_press`: 현재 눌린 키를 `current_keys` set에 추가, 등록된 단축키 조합이 subset이면 이벤트 발생
  - `on_release`: 키 해제 시 `current_keys`에서 제거, fired 플래그 리셋
- **중복 발화 방지**: `fired_record`, `fired_lang` 플래그로 키를 누르고 있는 동안 한 번만 실행

### 5.2 등록된 단축키

| 단축키 | 기능 | 변경 가능 |
|--------|------|----------|
| `Ctrl+Shift+M` (기본값) | 녹음 토글 | ✅ 메뉴에서 변경 |
| `Cmd+Shift+Space` (고정) | 언어 순환 전환 | ❌ 고정 |

### 5.3 키 정규화
- **구현**: `_norm_key(key)` (line 222-240)
- **역할**: 좌/우 구분 modifier 키를 통합
  - `ctrl_l`, `ctrl_r` → `ctrl`
  - `shift_l`, `shift_r` → `shift`
  - `alt_l`, `alt_r`, `alt_gr` → `alt`
  - `cmd_l`, `cmd_r` → `cmd`
  - 문자 키 → `("char", 소문자)` 튜플

### 5.4 단축키 문자열 파싱
- **구현**: `parse_hotkey_for_pynput(hotkey)` (line 242-260)
- **입력**: `"ctrl+shift+m"` 형태의 문자열
- **출력**: pynput 키 객체의 set
- **지원하는 키**: `cmd`, `shift`, `alt`, `ctrl`, `space`, 단일 문자

### 5.5 이벤트 전달 방식
- **pynput 스레드** → `threading.Event.set()` → **메인 루프 타이머**에서 감지 후 처리
- 직접 메인 스레드 함수를 호출하지 않고 Event 객체를 통해 간접 전달 (스레드 안전)

---

## 6. 설정 관리

### 6.1 설정 파일
- **경로**: `~/.config/voice-recorder/config.json`
- **인코딩**: UTF-8
- **포맷**: JSON (indent=2, ensure_ascii=False)

### 6.2 설정 항목

| 키 | 기본값 | 설명 |
|----|--------|------|
| `record_hotkey` | `"ctrl+shift+m"` | 녹음 토글 단축키 |
| `lang_hotkey` | `"cmd+shift+space"` | 언어 순환 전환 단축키 |
| `language` | `"ko"` | 전사 언어 코드 |
| `model` | `"mlx-community/whisper-large-v3-turbo"` | Whisper 모델 경로 |

### 6.3 설정 로드
- **구현**: `load_config()` (line 61-94)
- **동작**:
  1. 기본값 딕셔너리 정의
  2. 설정 파일 존재 시 JSON 로드 (실패 시 빈 딕셔너리)
  3. **구버전 호환**: `"hotkey"` 키가 있고 `"record_hotkey"`가 없으면 자동 마이그레이션
  4. 기본값과 병합: `{**default_config, **cfg}` (사용자 설정이 우선)
  5. `record_hotkey`, `lang_hotkey`가 빈 값이면 기본값으로 폴백

### 6.4 설정 저장
- **구현**: `save_config()` (line 96-100)
- **동작**: 디렉토리 자동 생성 (`mkdir(parents=True, exist_ok=True)`) 후 JSON 저장

---

## 7. 녹음 단축키 설정

### 7.1 선택 가능한 단축키
- **구현**: `build_menu()` 내부 hotkeys 리스트 (line 171-177)

| 단축키 문자열 | 표시 라벨 |
|-------------|----------|
| `ctrl+shift+m` | `⌃⇧M` |
| `cmd+shift+r` | `⌘⇧R` |
| `alt+space` | `⌥Space` |
| `cmd+alt+space` | `⌘⌥Space` |
| `ctrl+shift+space` | `⌃⇧Space` |

### 7.2 단축키 변경 처리
- **구현**: `set_record_hotkey(hotkey)` (line 303-309)
- **동작 순서**:
  1. config에 새 단축키 저장
  2. 설정 파일 저장
  3. 단축키 리스너 재설정 (`setup_hotkey()`)
  4. 메뉴 재구성
  5. 변경 알림 표시

### 7.3 단축키 표시 포맷
- **구현**: `format_hotkey(hotkey)` (line 206-217)
- **치환 규칙**:
  - `cmd` → `⌘`, `shift` → `⇧`, `alt` → `⌥`, `ctrl` → `⌃`
  - `space` → `Space`, `+` → (제거)
  - 빈 문자열 → `"-"`

---

## 8. 언어 설정

### 8.1 지원 언어
- **구현**: `build_menu()` 내부 languages 리스트 (line 188-194)

| 코드 | 언어명 | 메뉴바 배지 |
|------|--------|-----------|
| `ko` | 한국어 | `KR` |
| `en` | English | `EN` |
| `ja` | 日本語 | `JP` |
| `zh` | 中文 | `CH` |
| `vi` | Tiếng Việt | `VN` |

### 8.2 직접 언어 선택
- **구현**: `set_language(lang)` (line 311-323)
- **트리거**: 메뉴의 `전사 언어` 서브메뉴에서 항목 클릭
- **동작**: config 저장 → 메뉴 재구성 → 변경 알림

### 8.3 언어 순환 전환
- **구현**: `cycle_language()` (line 325-344)
- **트리거**: `Cmd+Shift+Space` 글로벌 단축키
- **순환 순서**: `ko` → `en` → `vi` → `ja` → `zh` → `ko` → ...
- **현재 언어가 리스트에 없는 경우**: `ko`로 리셋
- **메뉴바 아이콘 갱신**: 현재 상태(🎤/🔴/⏳) 유지하며 언어 배지만 변경

---

## 9. 알림 시스템

### 9.1 macOS 알림 센터 연동
- **구현**: `_notify(title, subtitle, message)` (line 109-117)
- **라이브러리**: `rumps.notification()`
- **스레드 안전**: 메인 UI 큐를 통해 실행 (백그라운드 스레드에서 직접 호출하지 않음)
- **오류 처리**: 알림 실패는 무시 (치명적이지 않음)

### 9.2 발생하는 알림 목록

| 제목 | 내용 | 발생 시점 |
|------|------|----------|
| `음성 인식` | `녹음 단축키: ⌃⇧M` | 녹음 단축키 변경 시 |
| `음성 인식` | `전사 언어: 한국어` | 언어 직접 선택 시 |
| `음성 인식` | `전사 언어 전환: en` | 언어 순환 전환 시 |
| `음성 인식 완료` | 전사 텍스트 (최대 50자) | 전사 성공 시 |
| `음성 인식` | `인식된 텍스트가 없습니다.` | 전사 결과 없을 때 |
| `오디오 오류` | 에러 메시지 (최대 120자) | 마이크/스트림 오류 시 |
| `붙여넣기 오류` | 에러 메시지 (최대 120자) | pyautogui 실패 시 |
| `오류` | 에러 메시지 (최대 160자) | 전사 과정 예외 발생 시 |

---

## 10. 스레드 및 동시성 관리

### 10.1 스레드 구조

| 스레드 | 유형 | 역할 | 생명주기 |
|--------|------|------|---------|
| 메인 스레드 | rumps 이벤트 루프 | UI 업데이트, 알림, 이벤트 처리 | 앱 전체 |
| pynput 리스너 | daemon | 글로벌 키보드 이벤트 감지 | 앱 전체 (단축키 변경 시 재생성) |
| 녹음 스레드 | daemon | `stream.read()` 반복, 프레임 수집 | 녹음 시작 ~ 중지 |
| 전사 스레드 | daemon | WAV 저장 + Whisper 전사 + 붙여넣기 | 녹음 중지 ~ 전사 완료 |

### 10.2 스레드 간 통신

| 발신 | 수신 | 매체 | 용도 |
|------|------|------|------|
| pynput 리스너 | 메인 루프 | `threading.Event` (`_toggle_event`) | 녹음 토글 신호 |
| pynput 리스너 | 메인 루프 | `threading.Event` (`_lang_event`) | 언어 전환 신호 |
| 전사 스레드 | 메인 루프 | `queue.Queue` (`_uiq`) | UI 업데이트 및 알림 작업 |
| 녹음 스레드 | 메인 루프 | `queue.Queue` (`_uiq`) | 오류 알림 |

### 10.3 메인 루프 타이머
- **구현**: `_drain_mainloop(_)` (line 119-140)
- **주기**: 50ms (`rumps.Timer(callback, 0.05)`)
- **처리 순서**:
  1. `_toggle_event` 확인 → `toggle_recording()` 호출
  2. `_lang_event` 확인 → `cycle_language()` 호출
  3. UI 큐에서 최대 50개 작업 실행 (과도한 처리 방지)
- **오류 처리**: UI 큐 작업 실행 중 예외 발생 시 `traceback.print_exc()`로 출력 후 계속 진행

---

## 11. 앱 종료

### 11.1 종료 처리
- **구현**: `quit_app(sender)` (line 489-514)
- **트리거**: 메뉴에서 `종료` 클릭
- **정리 순서** (각 단계 개별 try/except):
  1. 핫키 리스너 중지: `self.hotkey_listener.stop()`
  2. UI 타이머 중지: `self._ui_timer.stop()`
  3. 오디오 스트림 닫기: `self.stream.close()`
  4. PyAudio 종료: `self.audio.terminate()`
  5. 앱 종료: `rumps.quit_application()`
- **오류 격리**: 각 정리 단계가 독립적으로 실패해도 다음 단계 계속 진행

---

## 12. 기능 흐름도

### 12.1 녹음 → 전사 → 붙여넣기 전체 흐름

```
[사용자] Ctrl+Shift+M 누름
    │
    ▼
[pynput 리스너 스레드] on_press → _toggle_event.set()
    │
    ▼
[메인 루프 타이머] _drain_mainloop → _toggle_event 감지
    │
    ▼
[메인 스레드] toggle_recording() → start_recording()
    ├─ 아이콘: 🎤KR → 🔴KR
    ├─ 메뉴 재구성
    ├─ PyAudio 스트림 열기
    └─ 녹음 스레드 시작
         │
         ▼
    [녹음 스레드] stream.read() 반복 → frames 수집
         │
[사용자] Ctrl+Shift+M 다시 누름
         │
         ▼
[메인 스레드] toggle_recording() → stop_recording()
    ├─ 아이콘: 🔴KR → ⏳KR
    ├─ 녹음 스레드 join
    ├─ 스트림 정리
    ├─ frames 스냅샷 생성
    └─ 전사 스레드 시작
         │
         ▼
    [전사 스레드] transcribe_and_paste()
         ├─ 임시 WAV 파일 저장
         ├─ mlx_whisper.transcribe() 호출
         ├─ pyperclip.copy(text)
         ├─ 100ms 대기
         ├─ UI 큐에 do_paste 등록 → [메인 스레드] pyautogui.hotkey("command", "v")
         ├─ 알림: "음성 인식 완료"
         ├─ 임시 파일 삭제
         └─ UI 큐에 아이콘 복원 등록 → [메인 스레드] ⏳KR → 🎤KR
```

### 12.2 언어 순환 전환 흐름

```
[사용자] Cmd+Shift+Space 누름
    │
    ▼
[pynput 리스너 스레드] on_press → _lang_event.set()
    │
    ▼
[메인 루프 타이머] _drain_mainloop → _lang_event 감지
    │
    ▼
[메인 스레드] cycle_language()
    ├─ 현재 언어에서 다음 언어로 전환: ko → en → vi → ja → zh → ko
    ├─ config 저장
    ├─ 메뉴 재구성
    ├─ 알림: "전사 언어 전환: en"
    └─ 아이콘 배지 갱신 (현재 상태 아이콘 유지)
```
