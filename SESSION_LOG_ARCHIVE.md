# PROJECT ENIGMA — 세션 로그

---

## 2026-04-11 | Phase 11 — 버그 수정 + 챕터 2 재설계 + 단서 텍스트 개선

### 수정된 버그
- **EnigmaDecoder.gd 띄어쓰기 버그**: `setup()`에서 공백 제거(`.replace(" ", "")`)하던 것 제거. 암호문 공백이 CipherLib.enigma_process를 통해 그대로 보존 → 해독 결과가 "SENDR EINFO RCEME NTSNO W"(5글자 강제 분할)가 아닌 "SEND REINFORCEMENTS NOW"로 표시
- **EvidenceBoard.gd z-order 2개 버그**:
  - 팝업 오버레이: `_build_ui()`에서 추가 → `_place_cards()` 끝(PinLayer 이후)으로 이동. 카드·핀 위에 팝업이 렌더됨
  - 드래그: `move_child(card, _pin_layer.get_index() - 1)` 추가 → 드래그 카드가 다른 카드 위·핀 아래에 렌더됨
- **VigenereDecoder.gd 힌트 버튼**: "빈도 분석 힌트" → "단서 힌트", 힌트 로직을 `GameManager.use_hint()`로 교체(비즈네르에 맞지 않는 빈도 분석 코드 제거)
- **chapter_01_02.json 레드 헤링**: "화훼 목록"에 실제 Vigenère 키 ROSE가 포함되어 있던 것 → 가족 편지 형식으로 교체(ROSE 제거)

### 챕터 2 재설계
- **chapter_02_01.json**: ROT+8 단순 이동 → WOLF 키워드 기반 진짜 치환 암호로 교체
  - 새 암호문: `LMKSWLS OWRA KMV` (CONTACT BASE NOW)
  - 새 단서 4개: 패턴 분석 보고서 + 금고 메모(W·O·L·F·A·B·C·D…) + 늑대 배지 사진 + 포로 심문("늑대")
- **chapter_02_03.json**: 완전 재설계 — PHANTOM 키워드, 새 스토리
  - 새 암호문: `SBT GJFT CR ITPQ SBT AJPRS AFJRT PFF TXCSR` (THE MOLE IS NEAR THE COAST CLOSE ALL EXITS)
  - 스토리 연결: 02_02(북쪽으로 도주) → 02_03(해안 도달, 출구 봉쇄)
  - 새 단서: 칠판 사진(P H A N T O M…) + 바닥 쪽지(일곱 글자) + 포로("보이지 않는 것") + 분석 보고서

### 챕터 3-3 단서 텍스트 개선 (chapter_03_03.json)
- 플러그보드 설명: "알파벳 순서상 각 쌍의 첫 세 글자가 서로 교차 연결됨" → "알파벳 맨 앞 세 글자와 맨 뒤 세 글자가 각각 대칭으로 교차 연결됨 (앞에서 첫째↔뒤에서 첫째, ...)"
- 로터 위치 유도: "작전 시작일, 코드명 이니셜, 시각" → "작전 시작일 숫자의 각 자릿수 합 / 서명 장교 코드명 이니셜 / 작전 완료 시각"으로 도출 방식 명시

### CLAUDE.md 챕터 표 업데이트
- 챕터별 파일 접두사 추가, 실제 구현 반영

---

## 2026-04-11 | Phase 10 — 단서 보드 비주얼 개편 + 레드 헤링 + 암호 박물관

---

## 이번 세션에서 한 일

### EvidenceBoard.gd — 단서 카드 비주얼 전면 개편
- `CARD_SIZE`: `Vector2(172, 112)` → `Vector2(200, 128)`
- `_place_cards()`: jitter(±10px/±7px) 추가, pad_x=248, pad_y=170
- `_make_card()`: 타입별 스타일 분기 (match 문 사용)
  - `document`: 황색 종이 bg(0.91, 0.87, 0.76), 좌측 5px 테두리, 회전 ±1.5°
  - `torn_paper`: 연한 메모지 bg(0.96, 0.93, 0.85), 얇은 테두리, 회전 ±4.5°
  - `photo`: 회색 bg + 흰 두꺼운 하단 테두리(폴라로이드), 회전 ±3.5°
  - `interrogation`: 밝은 회색 bg + 빨간 상단 5px 테두리, 회전 ±2.0°
- `card.pivot_offset = CARD_SIZE * 0.5` — 카드 중심 기준 회전
- `_ready()`: `extra_clues` 병합 → `_clues = _clues + extra_clues`

### extra_clues (레드 헤링) 전 챕터 레벨 추가
레드 헤링 카드는 `extra_clues` 별도 필드에 저장, EvidenceBoard에서 런타임 병합.

| 파일 | 가짜 단서 내용 | 설계 의도 |
|------|---------------|-----------|
| chapter_00_01 | "막사 낙서" — 7일 교대 불평 | shift=7로 오해 유도 |
| chapter_00_02 | "병사 업무 목록" — 3번 항목 긴급 표시 | 숫자 3이 암호와 무관 |
| chapter_00_03 | "취사반 식단표" — 9주차 메모 | 숫자 9 오해 유도 |
| chapter_01_01 | "주머니 편지" — 장미 언급 | key=ROSE 미리 노출 오해 |
| chapter_01_02 | "화훼 목록" — LILIE/VEILCHEN/ROSE 나열 | 진짜 키 희석 |
| chapter_01_03 | "전선 배치" — 프랑스/벨기에 등 열거 | ENGLAND 오해 유도 |
| chapter_02_01 | "인사 발령 목록" — 인원 전출 명단 | 치환 암호와 무관 |
| chapter_02_02 | "병사 낱말 연습" — G=A H=B 쓰다 지움 | 치환표 오인 유도 |
| chapter_02_03 | "보급 경로 코드" — A/B/G/K 경로 코드 | 치환 관계 오인 유도 |
| chapter_03_01 | "장비 점검 일지" — 로터 IV/V 언급 | 로터 종류 오해 유도 |
| chapter_03_02 | "개인 편지" — F 알파벳 100개 | 중앙 로터 F 오해 유도 |
| chapter_03_03 | "분실물 신고서" — 이니셜 W.K.O. | 실제 O.K.W. 역순 혼동 |
| chapter_04_01 | "체스 기보" — 5×5 격자 언급 | 격자 구성 오해 유도 |
| chapter_04_02 | "영국군 장교 명단" — W 이름 4명 나열 | WINSTON 중 W만 확인한 듯 |
| chapter_04_03 | "영국 저택 목록" — Blenheim 등 BL 시작 | BLETCHLEY 오해 유도 |

### CipherMuseum.gd + scenes/CipherMuseum.tscn — 신규 생성
- 메인 메뉴 "◈ 암호 알아보기 (CIPHER MUSEUM)" 버튼으로 접근
- 좌측 사이드바: 5개 암호 종류 버튼 (Caesar/Vigenère/Substitution/Enigma/Playfair)
- **에니그마 섹션** (핵심):
  - 10단계 신호 경로 시각화: 입력 → PB → R3 → R2 → R1 → REF → R1' → R2' → R3' → PB → 출력
  - 단계별 하이라이트 + 알파벳 표시
  - 로터 종류/위치/반사판/플러그보드 조작 가능
  - 텍스트 인코더: CipherLib.enigma_process() 실시간 호출
- 기타 섹션: 각 암호 원리 설명 + 인터랙티브 인코더

### MainMenu.gd — 암호 박물관 버튼 추가
- 챕터 카드 아래에 별도 버튼 블록
- 버튼 텍스트: `"◈  암호 알아보기  (CIPHER MUSEUM)"`
- 눌리면 `change_scene_to_file("res://scenes/CipherMuseum.tscn")`

### PRD.md 업데이트
- 챕터 구성표를 3레벨 체계로 갱신
- 씬/스크립트 구조도 현행화
- Phase 7/8 신규 항목 추가
- MVP 체크리스트 현행화

---

## 다음 세션 우선순위

1. **실행 검증** — Godot에서 챕터 0~4 전체 플로우 + CipherMuseum 동선 확인
2. **버그 수정** — 런타임 에러 수집 후 일괄 처리
3. **StoryLog.tscn** — 해독 기록 타임라인 씬 완성 (Phase 9)
4. **효과음** — 도장 소리, 라디오 잡음, 타자기 타이핑 (Phase 10)

---

## 2026-04-11 | Phase 9 — 다중 레벨 챕터 시스템 + Playfair 암호

---

## 이번 세션에서 한 일

### 시스템 구조 변경 (GameManager.gd — 이전 세션 완료)
- `current_level_id: int = 1` 추가
- `level_stars: Dictionary` (구형 `chapter_stars` 대체, 저장 포맷 마이그레이션 포함)
- `_lkey(ch, lv) -> "C_L"` 헬퍼 — 모든 딕셔너리 키
- `load_level(chapter_id, level_id)` → `chapter_%02d_%02d.json` 로드
- `is_level_unlocked()` : ch0/lv1 항상 해금, lv1→이전챕터완료, lvN→이전레벨완료
- `get_level_stars()` / `is_level_complete()` / `get_decoded_message()` 헬퍼
- `save_game()` / `load_game()` 모두 level_stars 키 사용, 구형 포맷 자동 마이그레이션

### MainMenu.gd 전면 재작성 (이전 세션 완료)
- CHAPTERS 5개 (ch0~ch4), 각 3레벨
- 챕터 카드 클릭 → 레벨 선택 오버레이 팝업
- 각 레벨 버튼: 잠금/해금/완료(별점) 상태 표시
- LEVEL_LABELS = ["입문", "보통", "심화"]

### 레벨 JSON 파일 15개 신규 생성
- chapter_00_01~03: Caesar shift=3/5/9
- chapter_01_01~03: Vigenère key=WAR/ROSE/ENGLAND
- chapter_02_01~03: Substitution 단계별 (같은 치환표)
- chapter_03_01~03: Enigma I/II/III (02, 03은 cipher_text에 _dev_note 포함)
- chapter_04_01~03: Playfair key=KEY/WINSTON/BLETCHLEY
  - chapter_04_03 평문: "HARRISON IS THE MOLE" — 스토리 최종 반전

### CipherLib.gd — Playfair 암호 추가
- `playfair_process(text, key, encrypt)`: 5×5 격자 기반 이중자 치환
- `_playfair_build_grid(key)`: 키워드 중복 제거 + 나머지 알파벳 채움 (I/J 통합)
- `_playfair_positions(grid)`: 격자 내 각 글자 좌표 딕셔너리
- `_playfair_prepare(text)`: 이중자 분할 (연속 중복→X 삽입, 홀수→X 패딩)

### PlayfairDecoder.gd + scenes/ciphers/PlayfairDecoder.tscn 신규 생성
- 5×5 격자 시각화 (키 글자 금색 강조)
- 키워드 LineEdit → 실시간 격자+해독 갱신
- `decode_confirmed` 신호 → ChapterView 보고서 활성화
- `setup(cipher_text, params)` 시그니처로 ChapterView 자동 연동

### ChapterView.gd — CIPHER_INTROS에 playfair 추가
- 격자 구성/규칙 설명 (같은행/같은열/사각형, X삽입 규칙)

### StoryLog.gd — level_id + difficulty 표시 추가
- 헤더: `[ CHAPTER N  LEVEL M  ·  난이도 ]  챕터명` 형식

---

### ⚠️ Enigma 레벨 2/3 cipher_text 미검증
- chapter_03_02.json, chapter_03_03.json의 `cipher_text`는 플레이스홀더
- `_dev_note` 필드에 검증 방법 명시
- 실제 값은 GDScript에서 CipherLib.enigma_process() 실행 필요

---

## 2026-04-10 | Phase 8 — 저장/불러오기 + 데이터 초기화

---

## 이번 세션에서 한 일

### GameManager.gd — 자동 저장/불러오기
- `SAVE_PATH = "user://enigma_save.json"` 상수 추가
- `_ready()` → `load_game()` 자동 호출 (게임 시작 시 저장 파일 복원)
- `save_game()`: `chapter_stars`, `decoded_messages`, `collected_clues`, `story_log` → JSON 직렬화
  - Dictionary int 키 → String 변환 후 저장 (JSON 호환)
- `load_game()`: 파일 있으면 파싱 후 복원, String 키 → int 재변환
- `reset_save()`: 전체 초기화 + `DirAccess.open("user://").remove("enigma_save.json")`
- `submit_report()` 정답 처리 후 `save_game()` 자동 호출

### MainMenu.gd — 초기화 버튼 + 확인 팝업
- 하단 footer에 "데이터 초기화" 버튼 추가 (빨간 계열, 존재감 낮게)
- 클릭 시 `_reset_overlay` 팝업 표시
- 팝업: "모든 기록 삭제 불가역" 경고 + 취소/초기화 확인 버튼
- 초기화 확인 시: `GameManager.reset_save()` → `_refresh_chapter_buttons()` → 작전 일지 버튼 비활성화
- `_log_btn` 멤버 변수로 작전 일지 버튼 참조 관리
- 버전 텍스트: `Phase 7` → `Phase 8`

---

## 2026-04-10 | Phase 7 — 작전 일지 + 타자기 연출

---

## 이번 세션에서 한 일

### completion_log_text 전 챕터 추가
- chapter_00 ~ chapter_04 JSON 모두에 `completion_log_text` 필드 추가
- 형식: 실제 사령부 작전 결과 보고서 스타일 (구체적 전과/수치 포함, 칭찬 문구 없음)
- 예시: "해독 결과는 아이젠하워 장군 사령부에 즉각 전달됐다. TORCH 작전 상륙 지점이 교란됐고 ... 사상자 수는 예상의 31% 수준에 그쳤다."

### GameManager.gd — story_log 기능
- `story_log: Array` 멤버 변수 추가
- `submit_report()` 정답 확인 시 `_save_story_log(stars)` 호출
- `_make_log_entry()`: chapter_id, title, subtitle, date, time, frequency, sender, receiver, decoded, stars, log_text 저장
- 재플레이 시 기존 항목 업데이트 (덮어쓰기)

### ChapterView.gd — 타자기 + 작전 결과 오버레이 완성
- `_show_decoded_stamp()` 전면 재작성:
  - 빨간 테두리 "작전 결과 보고서" 패널 + 타자기 Label
  - 결과 패널(별점/해독문/버튼)은 타자기 완료 후 페이드인
  - 클릭하면 타자기 즉시 완료 → 결과 패널 표시
- 타자기 함수 4종 추가:
  - `_typewrite_cleanup()`: 타이머 정리
  - `_typewrite_start(label, text, on_done)`: 타이머 기반 출력 시작
  - `_typewrite_tick()`: 문자 단위 출력, 구두점에서 딜레이 변화 (`.`→0.10s, `,`→0.07s, `\n`→0.28s, 공백→0.022s, 기본→0.032s)
  - `_typewrite_skip()`: 즉시 전체 출력 후 완료 콜백 호출
- 결과 패널에 "작전 일지 ▶" 버튼 추가 → `StoryLog.tscn` 이동

### StoryLog.gd + StoryLog.tscn 신규 생성
- `GameManager.story_log` 순서대로 엔트리 카드 렌더
- 각 카드: 챕터명 + 별점 / 일시·주파수·발신→수신 메타 / DECODED 평문 / 작전 결과 텍스트
- 빈 경우 "완료된 작전이 없습니다." 안내
- 상단 바: 총 별점 표시

### MainMenu.gd 업데이트
- CHAPTERS 배열에 `{"id": 4, "label": "CHAPTER 4  —  ENIGMA"}` 추가
- "▶  작전 일지" 버튼 추가: `story_log.is_empty()`이면 disabled
- 버전 텍스트: `Phase 5` → `Phase 7`

---

## 2026-04-10 | 퍼즐 설계 결함 수정 + CLAUDE.md 작성

---

## 이번 세션에서 한 일

### 지적받은 문제 (설계 결함)
1. **CIPHER_INTROS Caesar 예시가 챕터 0 정답**: ATTACK + shift=3 → 정답 스포일러
2. **EnigmaDecoder가 cipher_params를 초기값으로 로드**: 정답 설정 상태로 시작
3. **챕터 4 단서가 한 장에 답 전부 제공**: 사진 한 장에 `I II III / A A A / REF: B` 직접 기재
4. **hint_value가 완전한 정답**: "아담의 첫 글자는 A. 세 로터 모두 초기 위치 A. 반사판은 B." — 힌트가 아니라 스포일러

### 수정 내용

**EnigmaDecoder.gd:**
- `setup()` 함수에서 `cipher_params` 로드 제거
- 초기 오답 기본값: 로터 I/II/III, 위치 D/D/D, 반사판 A
- 플러그보드 안내 "챕터 4는 플러그보드 없음" → "단서에서 확인되지 않으면 비워두십시오"

**ChapterView.gd — CIPHER_INTROS:**
- Caesar 예시: `ATTACK shift=3` → `MARCH shift=5 → RFWHM` (챕터 정답과 무관)

**chapter_04.json — 단서 전면 재작성:**
- 각 단서가 **한 조각만** 제공:
  - doc01 (문서): "후기 표준 반사판" → 반사판 B 간접 암시
  - torn01 (메모): "세 자리 전부 리셋" + "플러그보드 비워둠" → 위치 AAA + 플러그보드 없음
  - photo01 (사진): "28 NOV — I / II / III, 나머지 소실" → 로터 순서만
  - interrogation01 (심문): "두 번째 거" → 반사판 B 확인 / "횃불" → TORCH 간접 암시만

### CLAUDE.md 신규 작성
- 퍼즐 디자인 7대 원칙 정립
- 핵심: 단서 단편화, 정보 비반복, hint_value = 방향 제시만, 해독기 초기값 = 오답, 예시 ≠ 정답
- 챕터별 풀이 경로 요약, 단서 작성 형식 정리

---

## 2026-04-10 | 버그 수정 + 콘텐츠·UX 개선

---

## 이번 세션에서 한 일

### 버그 수정
| 파일 | 오류 | 원인 | 수정 |
|------|------|------|------|
| `CipherLib.gd:191` | `Invalid operands 'float' and 'int' in operator '%'` | `enigma_process` 내부 `pos` 배열이 JSON 파싱 결과물(float)로 채워짐 → `%` 연산 불가 | `var pos := [int(rotor_positions[0]), ...]` 로 int 캐스팅 추가 |

### 보고서 OptionButton 기본값 수정
- 각 선택지 앞에 `"── 선택 ──"` 플레이스홀더(인덱스 0) 추가 → 기본 선택이 정답이 되는 문제 해소
- `_on_submit_report`에서 인덱스 0이 선택된 항목이 있으면 제출 차단 + 팝업 안내

### 도장(DECODED) 애니메이션 수정
- 기존: `scale=(2.2, 0.15)→(1.0, 1.0)` — 좌우 찌부러짐 → 펼쳐지는 느낌 (컨셉 불일치)
- 변경: `position.y = -viewport_height*0.7 → 0` (낙하) + 충격 시 `scale.y 1.0→0.78` + 바운스 복원
- 시퀀스: 배경 페이드인(0.18s) → 낙하(0.22s, QUART EASE_IN) → 찌부러짐(0.06s) → 바운스(0.22s, BACK EASE_OUT)

### chapter_01.json — 암호문 길이 확장
- 평문: `NORTH HARBOR MIDNIGHT` → `NORTH HARBOR MOVE AT MIDNIGHT`
- 암호문: `UVYAO OHYIVY TPKUPNOA` → `UVYAO OHYIVY TVCL HA TPKUPNOA`
- 목적: 해독 결과가 짧아서 허무한 문제 개선 (더 긴 문장 → 더 만족스러운 reveal)

### chapter_03.json — 치환 암호 텍스트 대폭 확장
- 평문: `THE MOLE IS ALIVE FLEE NOW` (14자) → `THE ENEMY HAS BEEN HERE THE MOLE IS ALIVE AND ON THE RUN FLEE NORTH NOW` (57자)
- 암호문: `RCT JLIT DQ GIDVT AITT KLW` → `RCT TKTJE CGQ HTTK CTNT RCT JLIT DQ GIDVT GKF LK RCT NOK AITT KLNRC KLW`
- 암호문 빈도 분포: T(13회/22.8%), K(7회), C(6회), R(4회), L(4회) — 빈도 분석이 실제로 작동하는 길이
- "RCT" 패턴이 세 번 반복 → THE 추론 경로 명확
- 분석 보고서 단서: 빈도 통계 T(13회)/K(7회)/C(6회)로 업데이트
- 찢긴 전문 조각: 반복 패턴 언급 추가
- 압수 메모지: G/H/O → G/H/P 로 수정 (G=A, H=B, P=C 연속성)
- 심문 기록: 방향(북쪽) 힌트 추가

---

## 2026-04-10 | Phase 6 — 에니그마 머신 해독기

---

## 이번 세션에서 한 일

### chapter_04.json 신규 작성
- **제목**: ENIGMA (챕터 4)
- **주파수**: 312.4 kHz
- **암호 방식**: enigma (rotors I/II/III, positions AAA, reflector B, plugboard 없음)
- **평문**: `TORCH NORTH SHORE`
- **암호문**: `OIXBM EMTHN JOPMS` (PowerShell로 직접 계산 검증 + 대칭성 확인)
- **단서 4개**: 감청 보고서(document), 암호병 낙서(torn_paper), 설정표 사진(photo), 포로 심문(interrogation)
- **보고서 3문항**: TORCH / NORTH / SHORE

### scripts/ciphers/EnigmaDecoder.gd 신규 작성
- VigenereDecoder.gd 패턴 동일하게 적용
- **로터 설정**: 슬롯 3개 × (종류 OptionButton + 초기위치 OptionButton A~Z)
- **반사판**: OptionButton (A/B)
- **플러그보드**: LineEdit 10행 (좌↔우, × 버튼, 중복/자기자신 자동 무효화)
- **실시간 복호화**: CipherLib.enigma_process() 호출, 결과 5자 간격 표시
- **ScrollContainer** 래핑 — 플러그보드까지 스크롤 가능
- 힌트 버튼 → GameManager.use_hint_with_text()

### scenes/ciphers/EnigmaDecoder.tscn 신규 작성
- VigenereDecoder.tscn 동일 구조 (GDScript 기반 런타임 UI)

### ChapterView.gd — CIPHER_INTROS에 enigma 항목 추가
- 에니그마 구성 요소(로터/반사판/플러그보드) 설명
- 해독 전략: 대칭 암호 원리, 단서에서 찾아야 할 3가지 명시

---

## 다음 세션 우선순위

1. **실행 검증** — Godot에서 챕터 0~4 전체 플로우 실행 후 에니그마 해독기 동작 확인
2. **효과음** — 도장 찍히는 소리, 라디오 잡음, 타자기 타이핑 (deferred)
3. **StoryLog.tscn** — 해독 기록 타임라인 씬 (Phase 7)

---

## 2026-04-10 | 폴리싱 세션 — 도장 애니메이션 + 보고서 문항 추가

---

## 이번 세션에서 한 일

### 버그 수정
| 파일 | 오류 | 원인 | 수정 |
|------|------|------|------|
| `SubstitutionDecoder.gd:336` | `Invalid assignment of property 'horizontal_alignment' on LineEdit` | Godot 4에서 `LineEdit`는 `.alignment` 사용 (`.horizontal_alignment` 없음) | `edit.alignment = HORIZONTAL_ALIGNMENT_CENTER` 로 수정 |

### ChapterView.gd 개선
- **Vigenere CIPHER_INTROS 예시 키 교체**: 챕터 2 정답(`ROSE`)을 예시로 사용하던 문제 수정
  - 변경 전: `예시 (키워드: ROSE)` — `MEET + ROSE → DSWX`
  - 변경 후: `예시 (키워드: WOLF)` — `SEND + WOLF → OSYI`
- **DECODED 도장 Tween 애니메이션 추가**:
  - 오버레이: `modulate.a` 0 → 1 (0.22초 페이드인)
  - 도장: `scale` (2.2, 0.15) → (1.0, 1.0) (0.45초, TRANS_BACK EASE_OUT, 딜레이 0.12초)
  - 효과: 세로로 찌그러진 상태에서 찰싹 찍히는 느낌

### chapter JSON 보고서 문항 추가 (챕터당 3문항으로 확대)
| 챕터 | 추가 문항 | 정답 |
|------|-----------|------|
| chapter_00.json | 통신에 담긴 적의 작전은? | ATTACK |
| chapter_01.json | 집결 지점은 해안의 어느 방향? | NORTH |
| chapter_02.json | 두 요원이 취하기로 한 행동은? | MEET |
| chapter_03.json | 이 통신이 언급하는 요원의 신분은? | MOLE |

### 심문 기록 재작성 (chapter 02, 03)
**chapter_02 — 포로 #21**: 꽃 이름을 직접 말하는 대신, 장교가 책상 위 물건을 "홱 덮었다"는 행동만 묘사. 플레이어가 사진 단서와 연결해야 함.

**chapter_03 — 포로 #29**: "살아있다는 내용"을 직접 진술하는 대신, 머리를 다쳐 기억이 불명확한 척 횡설수설하다가 "살아… 있다고"가 속삭이듯 불쑥 나옴.

---

## 2026-04-09 | 스토리·연출 개편 세션

---

## 이번 세션에서 한 일

### 버그 수정
| 파일 | 오류 | 원인 | 수정 |
|------|------|------|------|
| `EvidenceBoard.gd` | 압정(핀)이 카드 뒤에 렌더됨 | `parent._draw()`는 자식 노드보다 먼저 렌더됨 → 핀이 카드 아래에 깔림 | `PinLayer extends Control` inner class를 마지막 자식으로 추가 → 모든 카드 위에 렌더 |

### chapter 00~03 단서 텍스트 전면 재작성
**원칙 확립 (→ memory 저장됨):**
- 한자(漢字) 괄호 표기 절대 금지
- 게임 룰 직접 설명 금지 ("알파벳을 N칸 밀어라" 등)
- `document` 타입: `[최고 기밀] / 발신: / 분류번호:` 헤더 + `────` 구분선 + `████ 검열 ████`
- `torn_paper` 타입: 병사 낙서/투덜거림, 유용한 정보가 맥락 속에 자연스럽게 묻힘
- `interrogation` 타입: 포로가 횡설수설하며 무의식중에 단서를 흘리는 방식

| 챕터 | 주요 변경 |
|------|-----------|
| 00 | 훈령 CR-07(방향 언급 없이 "수치와 방향 엄수"), 병사 쪽지("W 선생이 또 바꿨다"), 달력 사진('W' 서명) |
| 01 | 심문: 딸 일곱 번째 생일 언급 → "일주일이 숫자가 됩니까?", 코드북 조각 'SHIFT → RIGHT / ALWAYS', 달력 'TAG 7' |
| 02 | 편지: 꽃 이름 없이 "내 책상 위에 두고 온 그 꽃", 사진 뒷면 'R.O.S.E', 매뉴얼: 키 = "발신자의 개인 식별어" |
| 03 | 분석 보고서: T(4회)/R(3회) 빈도 통계, 소각 종이 조각 'RCT --- --', 메모지 G/H/O 잔존 |

### RadioScene.gd — Harrison 인트로 연출
- 1942년 11월 1일 오전 06:12 블레츨리 파크 분위기로 시작
- Harrison 캐릭터가 "신참이군. 앉아." → 라디오 조작 지시
- 작업 지시서 형식으로 단계 표시, 시작 버튼 "책상 앞에 앉는다 →"

### ChapterView.gd — 암호 방식 소개 오버레이 (CIPHER_INTROS)
- 새 챕터 로드 시 해당 암호 방식 설명 오버레이 자동 표시
- Caesar: ATTACK 예시 (shift=7)
- Vigenère: SEND+WOLF 예시 (키 WOLF — 정답 ROSE 노출 방지)
- Substitution: 빈도 분석, E≈13% T≈9%, RCT=THE 접근법

### ChapterView.gd — DECODED 도장 (_StampDraw inner class)
- `_StampDraw extends Control` inner class, `_draw()` 오버라이드
- `draw_set_transform_matrix(deg_to_rad(-12.0))` 로 -12° 기울기
- 외곽/내곽 이중 테두리 + "DECODED" 텍스트 + 별점(★☆) 렌더
- 하단 결과 패널: 해독 평문, 발신/수신자, 별점 문구
- 버튼: "메뉴로" / "다음 챕터 →" (다음 JSON 존재 여부 확인)

---

## 2026-04-09 | UI 개선 + Phase 4 비즈네르 해독기 세션

---

## 이번 세션에서 한 일

### UI 전면 개선 (StyleBoxFlat 테마 도입)
| 파일 | 변경 내용 |
|------|-----------|
| `MainMenu.gd` | 중앙 패널(금색 테두리) + MarginContainer + 챕터 버튼 StyleBoxFlat(normal/hover/pressed/disabled) |
| `EvidenceBoard.gd` | 상단 바 MarginContainer + 카드 타입별 색상 테두리 + 코르크 격자 배경 + 팝업 여백 |
| `ChapterView.gd` | 상단 바/단서 패널/보고서 패널 MarginContainer + 단서 버튼 타입별 좌측 컬러 바 |

**공통 팔레트 확립:**
- `C_BG` = `Color(0.04, 0.05, 0.09)` 군청 배경
- `C_GOLD` = `Color(0.93, 0.87, 0.40)` 제목·강조
- `C_BORDER_G` = `Color(0.50, 0.44, 0.15)` 금색 테두리
- 카드 타입별: 문서(청), 쪽지(황갈), 사진(회), 심문(적), 지도(녹)

**_make_style() 헬퍼 패턴 (각 파일에 공통):**
```gdscript
func _make_style(bg: Color, border: Color, bw: int, pad: int) -> StyleBoxFlat:
    var s := StyleBoxFlat.new()
    s.bg_color = bg
    s.border_color = border
    s.border_width_left = bw; s.border_width_right = bw
    s.border_width_top = bw;  s.border_width_bottom = bw
    s.content_margin_left = pad; ...
    return s
```

### Phase 4 — 비즈네르 해독기 구현
- `scripts/ciphers/VigenereDecoder.gd` — 신규
  - 키워드 LineEdit + 실시간 평문 갱신
  - 키 위치별 8색 순환 색상 하이라이트 (키 글자 / 암호 글자 / 평문 글자 3행)
  - 빈도 분석 힌트 버튼 → `GameManager.use_hint_with_text()` 호출
- `scenes/ciphers/VigenereDecoder.tscn` — 신규
- `GameManager.gd` — `use_hint_with_text(hint_text)` 메서드 추가

**챕터 1~2 데이터 확인:** 이미 존재 및 검증 완료
- `chapter_01.json`: 시저 암호 (shift=7, "NORTH HARBOR MIDNIGHT")
- `chapter_02.json`: 비즈네르 암호 (key=ROSE, "MEET AT PIER SEVEN")

---

## 2026-04-09 | 버그 수정 + 콘텐츠 개편 세션

---

## 이번 세션에서 한 일

### 버그 수정
| 파일 | 오류 | 원인 | 수정 |
|------|------|------|------|
| `EvidenceBoard.gd` | 카드 간 실(연결선)이 전혀 보이지 않음 | `_draw()`로 그린 연결선을 `ColorRect bg` 자식이 덮어씀. RadioScene과 동일한 패턴. | `ColorRect bg` 제거, 배경을 `_draw()` 첫 줄에서 `draw_rect()`로 직접 처리 |

### 콘텐츠 개편
- `data/chapters/chapter_00.json` — 단서 텍스트 전면 개편
  - 기존: 직설적인 게임 지시문 스타일 ("이동값 단서: 요일 번호" 등)
  - 개편: 1942년 실제 군사 문서 느낌으로 (훈령, 야전 쪽지, 압수 사진 묘사)
  - 단서 자체의 퍼즐 해결력은 유지하면서 분위기만 교체

---

## 2026-04-08 | Phase 3 구현 세션

---

## 이번 세션에서 한 일

### 버그 수정
| 파일 | 오류 | 원인 | 수정 |
|------|------|------|------|
| `ChapterView.gd:373` | `Identifier "q_container" not declared` | `_build_report_panel()`의 지역변수 `q_container`를 함수 밖에서 사용 | `_q_container`(멤버 변수)로 변경 |
| `RadioScene.gd` | `null instance.text =` | `get_node("VBoxContainer/CipherText")` — Godot이 자동 생성한 이름(`@VBoxContainer@0`)과 불일치 | `_cipher_text_lbl` 멤버 변수 직접 참조로 교체 |
| `RadioScene`, `EvidenceBoard`, `ChapterView` | 화면이 좌상단 기준으로 잘림 | `PRESET_CENTER`를 뷰포트 확정 전에 실행 → 위치가 (0,0)으로 계산됨 | `PRESET_FULL_RECT VBox + SIZE_SHRINK_CENTER` 패턴으로 교체 |
| `RadioScene.gd` | 파형이 전혀 보이지 않음 | Godot 렌더 순서: `부모 _draw() → 자식 렌더`. `ColorRect` 자식이 파형 위를 덮음 | `ColorRect` 제거, 배경을 `_draw()` 첫 줄에서 직접 `draw_rect()` |

### Phase 3 구현
- `scripts/RadioScene.gd` + `scenes/Radio.tscn` — 라디오 감청 미니게임
- `scripts/EvidenceBoard.gd` + `scenes/EvidenceBoard.tscn` — 드래그 단서 보드
- `GameManager.gd` — `radio_tuned(chapter_id: int)` 신호 추가
- `MainMenu.gd` — `_start_chapter()` → `Radio.tscn` 연결, 버전 텍스트 Phase 3

### 게임 루프 (완성된 흐름)
```
MainMenu → Radio.tscn (감청) → EvidenceBoard.tscn (단서 보드) → ChapterView.tscn (해독+보고서)
```

---

## 칭찬받은 부분 ✓

- **`lerp()` 신호 강도 스무딩** — "lerp를 채택한 건 아주 좋은 선택이었어"
  - `_signal_strength`를 즉각 반영하지 않고 `lerp(current, target, delta * 4.0)`으로 부드럽게 전환
  - 빠르게 스크롤해도 파형이 0.25초간 반응 → 시각적 피드백 인식 가능

---

## 지적받은 부분 ✗ (다음 세션 주의사항)

### 1. UI 전반 (가장 강하게 지적)
> "UI가 너무 구려. 2D 그래픽인 점을 살리지 못하고 거의 텍스트 기반 게임처럼 구성"
> "버튼도 너무 테두리에 붙어서 가시성과 가독성이 매우 떨어져"

- 모든 UI 요소에 충분한 margin/padding 필수 (`MarginContainer` 또는 gap Control 사용)
- Label + Button 나열 방식에서 탈피, 시각적 구분감 필요
- 단색 패널보다 구역별 배경 분리, 아이콘/기호 활용

### 2. 라디오 다이얼 게임성
> "마구잡이로 스크롤을 돌리다 보면 미세 조정이고 뭐고 할 틈도 없이 정답에 턱 걸려버려"
> "신호 근접 화면은 보지도 못했고, 사인 파형이 있긴 한 건지조차 모르겠어"

**근본 원인**: 목표 주파수가 `snappedf(randf, 10.0)` → 10 kHz 단위. 코스 스텝(10 kHz)으로 정확히 걸림.
**수정 내용**:
  - 목표 주파수 → `snappedf(randf, 1.0)` + `fmod != 0` 보장 (10 배수 제외)
  - `LOCK_THRESHOLD`: 2.5 → 1.0 kHz (미세 조정 필수)
  - `TUNE_THRESHOLD`: 25 → 45 kHz (신호 감지 구간 확장)
  - 신호 강도 lerp 스무딩 추가

**의도된 플로우**: 코스 탐색(10 kHz) → 45 kHz 범위 내 파형 변화 확인 → 1 kHz 미세 조정 1~9회 → 동조

### 3. 단서 보드 콘텐츠
> "너무 직설적이고 오글거리는 내용이라 갈아엎으라 하고 싶다"

- 다음 세션에서 단서 텍스트 전면 개편 예정
- 간접적이고 분위기 있는 표현으로 교체 필요 (1942년 시대 문서 느낌)

---

## 확립된 코딩 규칙 (이번 세션에서 굳어진 것)

### 1. 레이아웃 — PRESET_CENTER 절대 금지
```gdscript
# ❌ 잘못된 방법 (뷰포트 확정 전 실행 시 좌상단 잘림)
panel.set_anchors_and_offsets_preset(PRESET_CENTER)

# ✅ 올바른 방법
var outer := VBoxContainer.new()
outer.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
outer.alignment = BoxContainer.ALIGNMENT_CENTER
var panel := PanelContainer.new()
panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
panel.custom_minimum_size = Vector2(600, 0)
outer.add_child(panel)
```

### 2. 동적 노드 참조 — get_node() 경로 금지
```gdscript
# ❌ 잘못된 방법 (Godot이 @VBoxContainer@0 같은 이름 자동 생성 → null 반환)
_cipher_panel.get_node("VBoxContainer/CipherText").text = "..."

# ✅ 올바른 방법
var _cipher_text_lbl : Label  # 멤버 변수 선언
# _build_ui() 안에서:
_cipher_text_lbl = Label.new()
vbox.add_child(_cipher_text_lbl)
# 나중에:
_cipher_text_lbl.text = "..."
```

### 3. 배경 렌더링 — _draw() 사용 시 ColorRect 자식 금지
```gdscript
# ❌ 잘못된 방법 (ColorRect 자식이 _draw() 내용을 덮어씀)
var bg := ColorRect.new()
bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
add_child(bg)

# ✅ 올바른 방법 (_draw()에서 배경 먼저 그림)
func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), BG_COLOR)
    # 이후 다른 draw_* 호출
```

### 4. 신호 강도 스무딩 패턴 (검증됨)
```gdscript
var _signal_strength : float = 0.0  # 표시용 (스무딩 적용)
var _signal_target   : float = 0.0  # 실제 계산값

func _process(delta: float) -> void:
    _signal_strength = lerp(_signal_strength, _signal_target, delta * 4.0)

func _refresh_display() -> void:
    # _signal_target만 업데이트, _signal_strength는 건드리지 않음
    _signal_target = 1.0 - (dist / TUNE_THRESHOLD)
```

---

## 현재 파일 구조

```
scripts/
├── GameManager.gd       ← 싱글톤. radio_tuned 신호 추가됨
├── MainMenu.gd          ← Radio.tscn으로 연결
├── RadioScene.gd        ← Phase 3 신규. _draw() 파형 시각화
├── EvidenceBoard.gd     ← Phase 3 신규. 드래그 카드 + 연결선
├── ChapterView.gd       ← q_container 버그 수정됨
├── CipherLib.gd
└── ciphers/
    └── CaesarDecoder.gd

scenes/
├── MainMenu.tscn
├── Radio.tscn           ← Phase 3 신규
├── EvidenceBoard.tscn   ← Phase 3 신규
├── ChapterView.tscn
└── ciphers/
    └── CaesarDecoder.tscn
```

---

## 다음 세션 우선순위

## [서버 에러로 인한 세션 강제 중단 기록] 04-11

### 완료된 작업 (저장됨)
- **버그 수정:** 작전 결과 보고서(story_panel)에서 좌클릭으로 스킵되지 않던 현상 수정 완료 (`ChapterView.gd` 에 `mouse_filter = IGNORE` 및 `gui_input` 연결 적용).
- **UI 개선:** 챕터 내 레벨 2 이상 진입 시 불필요한 암호 소개 오버레이가 뜨지 않도록 수정.
- **단서 전면 재설계 (CLAUDE.md 원칙 적용):**
  - `chapter_02_01.json`: 단일 치환 암호문(ROT+8) 및 단서 전면 재설계 완료.
  - `chapter_03_02.json`: 에니그마 암호문 갱신 및 단서(로터 순서, 반사판, 초기 위치)를 간접적으로 교차 검증하도록 재설계 완료.
  - `chapter_03_03.json`: 에니그마 암호문 파이썬 계산 및 `cipher_text` 갱신 완료 (`BRGFLHA RSY CFZKNAKR`).

### ✅ 재개 완료 (2026-04-11)
- **`chapter_03_03.json` 단서 수정 완료**
  - `c04c_doc01` content: 로터 구성(표준 순서 유지=I/II/III)과 반사판("알파 이후 첫 번째 유형"=B) 힌트를 문서 상단에 간접적으로 추가.
  - `c04c_doc01` hint_value: 로터·반사판·플러그보드 세 가지 모두 이 문서에서 찾을 수 있음을 안내하도록 갱신.
  - `c04c_photo01` hint_value: "좌측 로터" → "중앙 로터"로 수정 (O.K.W. 이니셜 O = 위치 O=14 = 중앙 로터 II 포지션에 해당).

---

## 2026-04-11 | 단서 보드 비주얼 개편 + Cipher Museum 신규 세션

### 이번 세션에서 한 일

#### 1. EvidenceBoard — 카드 비주얼 완전 개편
| 변경 | 내용 |
|------|------|
| CARD_SIZE | 172×112 → 200×128 (더 넉넉한 카드) |
| 랜덤 회전 | 카드마다 타입에 따라 ±1.5°~±4.5° 랜덤 기울기 + 중심 pivot |
| 위치 지터 | ±10px 랜덤 오프셋으로 자연스러운 코르크보드 느낌 |
| document | 두꺼운 왼쪽 청색 선 (5px), 크림 배경 |
| torn_paper | 얇은 테두리, 큰 회전 (±4.5°), 밝은 크림 배경 |
| photo | 폴라로이드 프레임 (7/7/7/12px 흰 테두리), 회색 중앙 |
| interrogation | 두꺼운 상단 적색 선 (5px), 근백색 배경 |
| hint 문구 | 타입별 차별화 ("· 클릭 ·", "[ 사진 ]", "[ 기록 ]") |

#### 2. 레드 헤링 clue 추가 (extra_clues 필드)
- JSON 파일에 `extra_clues` 배열 추가 (퍼즐과 무관한 분위기용 단서)
- EvidenceBoard.gd: `extra_clues`를 `clues`에 병합해서 보드에 표시
- 추가 대상: chapter_00_01, 01_01, 02_01, 03_01, 03_02, 03_03, 04_01
- 내용: 당직 불만 낙서, 연애편지(장미 언급 레드 헤링), 인사 발령 목록, 장비 점검 일지(로터 IV/V), 개인 편지, 분실물 신고서, 체스 기보 메모

#### 3. CipherMuseum 신규 씬 (Phase 9)
- `scripts/CipherMuseum.gd` — 신규 (~620줄)
- `scenes/CipherMuseum.tscn` — 신규
- 5종 암호 방식 인터랙티브 데모:
  - **Caesar**: Shift ◀▶ 컨트롤 + 알파벳 대응 테이블 실시간 갱신
  - **Vigenère**: 키워드 입력 → 암호문/키/이동값/평문 4행 분해표
  - **Substitution**: 영어 빈도 Top 10 막대 그래프 시각화
  - **Enigma**: 로터 I~V 타입 선택 + 위치 ▲▼ + 반사판 A/B + 입력글자 26버튼 + **10단계 신호 경로 시각화** + 텍스트 암호화 체험 (CipherLib 연동)
  - **Playfair**: 키워드 입력 → 5×5 격자 동적 생성 (키글자 금색 강조) + 쌍 암호화 체험
- MainMenu.gd: "◈ 암호 알아보기 (CIPHER MUSEUM)" 버튼 추가

#### 설계 원칙
- Enigma 경로 추적: 로터 스텝 없이 단일 입력 기준으로 각 단계 글자 표시 (교육 목적)
- `extra_clues`는 `clues`와 별도 JSON 필드 → 나중에 챕터별 레드 헤링만 관리 용이

---

1. ~~**EvidenceBoard 실 연결 버그**~~ ✅ 완료 (2026-04-09)
2. ~~**EvidenceBoard 콘텐츠 개편**~~ ✅ 완료 (2026-04-09)
3. ~~**전반적 UI 개선**~~ ✅ 완료 (2026-04-09, StyleBoxFlat 테마 전면 적용)
4. ~~**Phase 4 비즈네르 해독기**~~ ✅ 완료 (2026-04-09)
5. ~~**Phase 5 단일 치환 해독기**~~ ✅ 완료 (2026-04-09)
6. ~~**스토리·연출 개편**~~ ✅ 완료 (2026-04-09, chapter 00~03 전면 재작성, Harrison, CIPHER_INTROS, DECODED 도장)
7. ~~**DECODED 도장 Tween 애니메이션**~~ ✅ 완료 (2026-04-10)
8. ~~**보고서 문항 확대**~~ ✅ 완료 (2026-04-10, 챕터당 2~3문항)
9. ~~**Vigenere 예시 키 교체**~~ ✅ 완료 (2026-04-10, ROSE→WOLF)
10. ~~**Phase 6 에니그마 머신 UI**~~ ✅ 완료 (2026-04-10)
11. ~~**Phase 7 작전 일지 + 타자기 연출**~~ ✅ 완료 (2026-04-10)
12. ~~**Phase 8 저장/불러오기**~~ ✅ 완료 (2026-04-10)
13. ~~**단서 보드 비주얼 개편 + 레드 헤링**~~ ✅ 완료 (2026-04-11)
14. ~~**Phase 9 Cipher Museum**~~ ✅ 완료 (2026-04-11, 5종 암호 인터랙티브 데모)
15. **실행 검증** — Godot에서 챕터 0~4 전체 플로우 + Cipher Museum 동선 확인 권장
16. **효과음** — 도장 찍히는 소리, 라디오 잡음, 타자기 타이핑 (deferred)
17. **Phase 10 후보** — 나머지 챕터 레벨에도 extra_clues 추가 (ch_00_02~03, ch_01_02~03 등)
