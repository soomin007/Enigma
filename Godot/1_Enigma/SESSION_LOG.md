# PROJECT ENIGMA — 세션 로그 (현재 세션)
> Phase 1~10 상세 기록은 `SESSION_LOG_ARCHIVE.md` 참조

---

## 현재 진행 중: Phase 11 — 오디오 폴리싱

### 완료된 작업 (2026-04-11 ~ 2026-04-12)

**AudioManager.gd (autoload 싱글톤)**
- BGM 플레이어 (크로스페이드) + SFX 풀 6채널 + 타자기 전용 + 라디오 스태틱 전용
- `VOL_BGM_DEFAULT = -6.0 dB`, `VOL_SFX_DEFAULT = -8.0 dB`
- `_ensure_buses()`: BGM/SFX 오디오 버스 코드 자동 생성 (에디터 불필요)
- Audio Bus는 에디터가 아닌 코드로 자동 생성됨

**라디오 스태틱 lerp 시스템**
- `start_radio_static()` → `radio_signal.ogg` 루프 재생
- `set_radio_static_strength(strength)` → strength 0→1에 따라 볼륨 `-6dB → -60dB` 보간
- RadioScene `_process()`에서 매 프레임 호출 → 주파수 근접할수록 잡음이 자연스럽게 줄어듦
- 동조 완료·뒤로가기 시 `stop_radio_static()` 호출

**씬별 오디오 호출 삽입 완료**
- MainMenu: `play_bgm("menu")`
- RadioScene: `play_bgm("radio")` + `start_radio_static()` / `stop_radio_static()`
- EvidenceBoard: `play_sfx("paper")`
- ChapterView: `play_bgm("gameplay")` + `start_typewriter()` + `play_sfx("stamp")` + `correct/wrong`

**Phase 11 이전 완료 사항**
- extra_clues (레드 헤링) ChapterView에서 미표시 버그 수정 (`clues + extra_clues` 병합)
- 런타임 암호문 동적 생성 (Phase 10): JSON에서 cipher_text/radio_frequency 제거, 실행 시 계산

### 현재 오디오 파일 상태

| 키 | 파일 | 상태 |
|----|------|------|
| BGM `"menu"` | `res://sounds/A_Room_Without_Windows.mp3` | ✅ |
| BGM `"radio"` | `""` (비어있음) | 라디오 스태틱이 음향 대체 — BGM 불필요 |
| BGM `"gameplay"` | `res://sounds/A_Room_Without_Windows.mp3` | ✅ (menu와 동일 파일 공유, 씬간 끊김 없음) |
| SFX `signal_lock` | `res://sounds/walkie_talkie_over_beep.wav` | ✅ |
| SFX `paper` (랜덤 3종) | `flipping-page.wav` / `page-turn.wav` / `paper_flip.wav` | ✅ |
| SFX `typewriter` | `res://sounds/type-writing.wav` | ✅ |
| SFX `stamp` | `res://sounds/sfx_stamp.wav` | ✅ |
| SFX `correct` | `res://sounds/sfx_correct.wav` | ✅ |
| SFX `wrong` | `res://sounds/sfx_wrong.mp3` | ✅ |
| SFX `radio_signal` (스태틱 루프) | `res://sounds/radio_signal.ogg` | ✅ |

---

## Phase 12 완료 (2026-04-12) — 마무리 폴리싱

**레드 헤링 오답 전용 피드백 시스템**
- `report_questions[].specific_wrong_feedback` 딕셔너리로 오답별 전용 메시지 관리
- GameManager.submit_report(): specific_wrong_feedback 히트 시 `[RH]` 프리픽스 추가
- ChapterView._on_report_result(): `[RH]` 감지 → "단서 재검토 권고" 전용 팝업
- 레드 헤링 오답은 별점 계산 시 2배 감점 (일반 오답의 2회 = 1회)
- 전체 15개 레벨 JSON에 specific_wrong_feedback 완비

**점진적 힌트 시스템**
- 전체 15개 레벨 JSON에 루트 레벨 `"hints": [약, 중, 강]` 배열 추가
- GameManager.use_hint(): hints 배열 우선 사용, fallback으로 per-clue hint_value 순환

**ch_02_01 단서 재설계**
- c03a_doc01: "통신 분석 보고서" → "노획 암호 운용 교범 (발췌)"
- IRON 예시로 키워드→치환표 메커니즘 직접 설명

**BOMBE 이스터에그 (ChapterView)**
- ChapterView._input()에서 "BOMBE" 타이핑 감지 → GameManager.debug_complete_level() → 1성 강제 완료
- 팝업: "튜링의 기계가 가동됐습니다"

**기타 버그 수정**
- chapter_00_03.json 레드 헤링 식단표: "9주차" → "3주차"

---

## Phase 13 완료 (2026-04-12) — 폴리싱 II (10개 신규 기능)

**1. 힌트 횟수 제한 (3회)**
- GameManager.HINT_MAX=3, use_hint()/use_hint_with_text() 체크
- hint_exhausted 신호, ChapterView 힌트 버튼 "힌트 사용(N/3)" + 소진 시 비활성화

**2. 레벨 타이머**
- GameManager._level_start_time + level_elapsed_secs 추적
- ChapterView _process() 타이머 표시, StoryLog에 클리어 시간·⚡ 속도뱃지(3분 이내) 표시

**3. 레드 헤링 해설 (DECODED 후)**
- ChapterView._show_decoded_stamp(): 타자기 완료 후 extra_clues 기반 "가짜 단서 해설" 패널 페이드인
- extra_clues[].red_herring_note 필드로 해설 텍스트 제공

**4. 암호문 복사 버튼**
- ChapterView 우측 패널 상단에 "암호문:" 헤더 + "[ 복사 ]" 버튼
- DisplayServer.clipboard_set() 사용, 1.5초 후 "[ 복사됨 ✓ ]" 피드백

**5. 씬 전환 애니메이션**
- SceneTransition.gd (CanvasLayer layer=128) — fade_to(path)/reload_scene()
- 모든 change_scene_to_file 호출 23개 교체

**6. EvidenceBoard 연결선 순차 등장**
- _connection_alphas Array 추가; 새 연결 생성 시 0→1 Tween (0.35초)
- _draw()에서 알파 곱 적용; 제거 시 알파 배열도 동기화

**7. 보고서 Enter 키 단축키**
- ChapterView._input(): Enter/KP_Enter 감지 시 _on_submit_report() 호출

**8. 총 별점 기반 3종 엔딩**
- Ending.gd + Ending.tscn 신규 씬
- 40+★→"전설적 분석관", 25~39★→"유능한 요원", ~24★→"경험 부족"
- StoryLog/MainMenu에 15레벨 완료 시 엔딩 버튼 표시

**9. 보너스 챕터 5 (Harrison 시점) — 초기 설계**
- chapter_05_{01~03}.json: Caesar shift=7(탄생월) / Vigenère key=JUDAS / Enigma II·IV·V H·A·R B + A↔Z B↔X
- 내부 배신자 해리슨의 독일 정보 유출 서사

**10. 설정 메뉴**
- SettingsManager.gd (autoload) + Settings.gd + Settings.tscn
- BGM/SFX 볼륨 슬라이더(-40~0dB), 텍스트 속도 슬라이더(0.25~3.0x), 언어 스캐폴딩
- user://settings.json 저장/불러오기; ChapterView 타자기 속도 text_speed_factor 반영

---

## Phase 14 완료 (2026-04-12) — 보고서 선택지 균등화 + 보너스 챕터 재설계

**보고서 선택지 글자수 균등화 (ch0~ch5 전체 15레벨)**
- 문제: 정답과 오답 선택지 글자수가 달라 글자수만으로 정답 추측 가능
- 해결: 모든 선택지를 정답 글자수와 동일하게 맞춤 (±0)
- 수정 파일 19개 (chapter_{00~05}_{01~03}.json + MainMenu.gd)

주요 변경 예시:
| 레벨 | 질문 | 이전 선택지 | 변경 후 |
|------|------|------------|---------|
| ch00_01 q1 | 작전 시각 | MIDNIGHT(8)/DUSK(4)/DAWN(4)/NOON(4) | DARK/DUSK/DAWN/NOON (모두 4) |
| ch02_02 q2 | 요원 상태 | ALIVE(5)/MISSING(7)/CAPTURED(8)/DEAD(4) | ALIVE/DYING/FOUND/TAKEN (모두 5) |
| ch04_02 q1 | 접선 행동 | RENDEZVOUS(10)/MEET(4)/SIGNAL(6)/CONTACT(7) | .../CONFERENCE/ENGAGEMENT/CORRESPOND (모두 10) |
| ch05_02 q2 | 유출 상태 | COMPROMISED(11)/CAPTURED(8)/SECURED(7)/CHANGED(7) | .../SURRENDERED/CONFISCATED/NEUTRALIZED (모두 11) |

**보너스 챕터(ch5) 단서 재설계**
- ch5_01: shift=7 직접 노출 제거 → "7월에 태어났다" 일기/신원기록/심문 간접 조합
- ch5_02: "JUDAS ISCARIOT" 직접 노출 제거 → 성경 구절·은화·코드명 은유로만 암시
- ch5_03: 가짜 단서 제목의 "(오해 유발)" 개발자 주석 제거; 보고서 질문을 에니그마 설정값이 아닌 해독 평문 내용으로 전환
- ch5_03 크리티컬 버그 수정: `"positions": ["H","A","R"]` → `"rotor_positions": [7, 0, 17]`

**MainMenu 신규 기능**
- 종료 버튼 (✕ 게임 종료): 설정 버튼 아래에 배치, `get_tree().quit()` 호출
- BOMBE 디버그 코드: 메인 화면에서 B-O-M-B-E 순서로 타이핑 시 전체 레벨(ch0~5, lv1~3) 1성 완료 처리 후 씬 리로드
  - `_debug_buf: String`, `_input()`, `_activate_debug_all()` 추가

**Git 커밋:** `9e79a38` → GitHub 푸시 완료
