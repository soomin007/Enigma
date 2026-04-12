# PRD — Project ENIGMA
## 암호 해독가 추리 게임 | Godot 4 | 1인 개발

---

## 1. 게임 개요

| 항목 | 내용 |
|------|------|
| 장르 | 퍼즐 / 추리 / 어드벤처 |
| 플랫폼 | PC (Windows) |
| 엔진 | Godot 4.6 |
| 개발 언어 | GDScript |
| 참고작 | Return of the Obra Dinn, Papers Please, Her Story |
| 핵심 테마 | 2차 세계대전, 암호학, 추리 |

### 한 줄 소개
> 당신은 영국 블레츨리 파크 소속 암호 해독가.  
> 파편화된 적군 통신을 모아 숨겨진 음모를 밝혀내십시오.

---

## 2. 핵심 게임 루프

```
[라디오 감청] → [단서 수집] → [암호 해독] → [보고서 작성] → [다음 챕터 해금]
	  ↑                                                              |
	  └──────────────── 새 주파수 · 새 문서 잠금 해제 ←─────────────┘
```

### 루프 상세
1. **라디오 감청** — 다이얼을 돌려 잡음 속 신호를 찾아낸다 (미니게임)
2. **단서 수집** — 환경 내 문서·사진·심문 기록을 클릭해 단서 보드에 핀으로 고정
3. **암호 해독** — 수집한 단서로 해독기 UI를 직접 조작
4. **보고서 작성** — 빈칸 채우기 형식으로 추론 결과 제출 (오답 시 새 단서 해금)

---

## 3. 챕터 구성 및 암호 진행표

각 챕터는 3개의 레벨(입문/보통/심화)로 구성됨. JSON 파일명: `chapter_XX_0Y.json`

| 챕터 | 레벨 | 암호 유형 | 핵심 게임플레이 | 상태 |
|------|------|-----------|----------------|------|
| 0 (튜토리얼) | 1~3 | 시저 암호 | 이동값 슬라이더 조작 | ✅ 완료 |
| 1 "붉은 장미" | 1~3 | 비즈네르 암호 | 키워드 추적 (편지·사진에서 수집) | ✅ 완료 |
| 2 "유령 네트워크" | 1~3 | 단일 치환 암호 | 빈도 분석, 수작업 매핑 | ✅ 완료 |
| 3 "ENIGMA" | 1~3 | 에니그마 머신 | 로터·반사판·플러그보드 조작 | ✅ 완료 |
| 4 "플레이페어" | 1~3 | 플레이페어 암호 | 5×5 격자 키 행렬 조작 | ✅ 완료 |
| 5 "배신자의 암호" | 1~3 | 시저 암호 (보너스) | Harrison 시점 — 암호화 관점 플레이 | ✅ 완료 |

> **레드 헤링(가짜 단서)**: 모든 챕터의 JSON에 `extra_clues` 필드로 분리 저장. EvidenceBoard가 런타임에 `clues`와 병합해 표시.

---

## 4. 핵심 시스템 명세

### 4-1. 라디오 감청 시스템 (RadioScene)
- 아날로그 다이얼 UI (마우스 드래그)
- 주파수 범위: 100.0 ~ 999.9 kHz
- 정답 주파수 근처에서 잡음(static) 감소 → 신호음 증가
- 성공 시 암호문 텍스트 또는 모스 신호 표시
- **게임성 포인트**: 여러 주파수에 여러 메시지가 숨겨져 있음 (선택 수집)

### 4-2. 단서 보드 시스템 (EvidenceBoard)
- 코르크보드 배경, 드래그 가능한 카드
- **카드 타입별 시각 스타일**: document(황색 문서), torn_paper(연한 메모지), photo(폴라로이드), interrogation(붉은 상단 테두리)
- **랜덤 기울기**: 카드마다 타입별 각도 범위로 무작위 회전 (pivot_offset = 카드 중심)
- 카드 간 실(string) 연결로 관계 표시 (`connections` 배열에서 로드)
- **레드 헤링 카드 포함**: `extra_clues`에서 병합, 플레이어가 직접 걸러내야 함
- **게임성 포인트**: 퍼즐과 무관한 가짜 단서가 섞여 있어 추론 과정이 핵심

### 4-3. 암호 해독기 시스템 (CipherWorkbench)
모듈형 구조 — 챕터별 해독기 씬이 교체됨

#### 시저 해독기
- 슬라이더 or 스핀박스 (이동값 0~25)
- 실시간 평문 프리뷰
- 방향 토글 (오른쪽/왼쪽 이동)

#### 비즈네르 해독기
- 키워드 LineEdit (글자마다 실시간 갱신)
- 키워드 길이에 따른 색상 하이라이트 (어떤 키 글자가 어느 암호문에 대응하는지 시각화)
- 빈도 분석 힌트 버튼 (쓸수록 점수 감점)

#### 단일 치환 해독기
- 알파벳 26개 입력 칸 (A→? 매핑 테이블)
- 내장 빈도 분석 그래프 (영어 기준 ETAOIN 순서 표시)
- 드래그 앤 드롭으로 글자 교환
- 확신도(%) 표시

#### 에니그마 해독기
- 로터 3개: 각 로터 종류(I~V) 선택 + 초기 위치(A-Z) 설정
- 리플렉터 선택 (A/B)
- 플러그보드: 10쌍까지 글자 교환 설정
- 실물과 동일한 타자기식 입력 UI
- **게임성 포인트**: 잘못된 설정 → 의미 없는 문자열 → 실패 피드백

### 4-4. 보고서 시스템 (ReportForm)
- "다음 공격 지점은 ___입니다"
- "스파이의 정체는 ___입니다"
- 객관식 선택지 + 자유 입력 혼합
- 오답 시: "검토 후 재제출하십시오" + 추가 단서 1개 해금
- 정답 시: 다음 챕터 애니메이션 시퀀스

### 4-5. 스토리 로그 시스템 (StoryLog)
- 해독된 메시지 타임라인 형식으로 축적
- 날짜·발신지·수신지 메타데이터 표시
- 재열람 가능 (퍼즐 풀다 놓친 단서 복기용)
- 🔲 미구현

### 4-6. 암호 박물관 (CipherMuseum)
- 메인 메뉴에서 직접 접근 가능한 독립 씬
- 5가지 암호 방식 인터랙티브 데모: 시저, 비즈네르, 단일 치환, 에니그마, 플레이페어
- **에니그마 신호 경로 시각화**: 입력 → 플러그보드 → 로터3 → 로터2 → 로터1 → 반사판 → 역순 → 출력 (10단계 하이라이트)
- 텍스트 인코더: 실제 CipherLib 함수를 호출해 실시간 암호화 결과 표시

---

## 5. UI/UX 디자인 방향

| 요소 | 방향 |
|------|------|
| 전체 색조 | 어두운 군청색 + 낡은 종이 황색 + 타자기 흰색 |
| 폰트 | 모노스페이스 (타자기 느낌) |
| 효과음 | 라디오 잡음, 타자기 타이핑, 종이 넘기는 소리 |
| 화면 전환 | 서류 봉투가 열리는 애니메이션 |
| 해독 성공 | 타자기가 평문을 한 글자씩 출력하는 효과 |

---

## 6. 씬(Scene) 구조

```
res://
├── project.godot
├── scenes/
│   ├── MainMenu.tscn          ✅ (암호 박물관·스토리로그·설정 버튼 포함)
│   ├── Radio.tscn             ✅
│   ├── EvidenceBoard.tscn     ✅ (타입별 카드 스타일, 랜덤 회전, 레드 헤링 병합)
│   ├── ChapterView.tscn       ✅ (해독기 + 보고서 + DECODED 도장)
│   ├── CipherMuseum.tscn      ✅ (5종 암호 인터랙티브 데모)
│   ├── StoryLog.tscn          ✅
│   ├── Ending.tscn            ✅ (총 별점 기반 3종 엔딩)
│   ├── Settings.tscn          ✅ (BGM/SFX 볼륨, 텍스트 속도 설정)
│   └── ciphers/
│       ├── CaesarDecoder.tscn      ✅
│       ├── VigenereDecoder.tscn    ✅
│       ├── SubstitutionDecoder.tscn ✅
│       ├── EnigmaDecoder.tscn      ✅
│       └── PlayfairDecoder.tscn    ✅
├── scripts/
│   ├── GameManager.gd         ✅ autoload — 게임 상태·저장·힌트·보고서
│   ├── AudioManager.gd        ✅ autoload — BGM 크로스페이드·SFX·라디오 스태틱
│   ├── CipherLib.gd           ✅ autoload — 암호화/복호화 라이브러리
│   ├── SceneTransition.gd     ✅ autoload — 씬 전환 페이드 애니메이션
│   ├── SettingsManager.gd     ✅ autoload — 볼륨·속도 설정 저장/로드
│   ├── MainMenu.gd            ✅
│   ├── RadioScene.gd          ✅
│   ├── EvidenceBoard.gd       ✅
│   ├── ChapterView.gd         ✅
│   ├── CipherMuseum.gd        ✅
│   ├── PlayfairDecoder.gd     ✅
│   ├── StoryLog.gd            ✅
│   ├── Ending.gd              ✅
│   ├── Settings.gd            ✅
│   └── ciphers/
│       ├── CaesarDecoder.gd        ✅
│       ├── VigenereDecoder.gd      ✅
│       ├── SubstitutionDecoder.gd  ✅
│       └── EnigmaDecoder.gd        ✅
├── assets/
│   ├── fonts/
│   ├── sounds/
│   └── textures/
└── data/
	└── chapters/
		├── chapter_00.json        ✅ 챕터 선택 메타
		├── chapter_00_01~03.json  ✅ Caesar shift=3/5/9
		├── chapter_01.json        ✅
		├── chapter_01_01~03.json  ✅ Vigenère key=WAR/ROSE/ENGLAND
		├── chapter_02.json        ✅
		├── chapter_02_01~03.json  ✅ Substitution (keyword=WOLF/빈도분석/PHANTOM)
		├── chapter_03.json        ✅
		├── chapter_03_01~03.json  ✅ Enigma I/II/III (AAA B / 위치변경 / 플러그보드)
		├── chapter_04.json        ✅
		├── chapter_04_01~03.json  ✅ Playfair key=KEY/WINSTON/BLETCHLEY
		├── chapter_05.json        ✅ 보너스 챕터 메타 — 배신자의 암호
		└── chapter_05_01~03.json  ✅ Caesar (Harrison 시점)
```

---

## 7. GDScript 아키텍처

### 싱글톤: GameManager.gd
```gdscript
# 전역 게임 상태 관리
var current_chapter: int
var collected_clues: Array[String]
var decoded_messages: Array[Dictionary]
var report_answers: Dictionary
```

### 라이브러리: CipherLib.gd
```gdscript
# 암호/복호화 순수 함수 모음
func caesar_decode(cipher, shift, reverse) -> String
func vigenere_decode(cipher, key) -> String
func substitution_decode(cipher, mapping) -> String
func enigma_decode(cipher, rotors, reflector, plugboard) -> String
```

### 데이터: chapter_XX.json 구조
```json
{
  "chapter_id": 0,
  "title": "첫 교신",
  "radio_frequency": 437.5,
  "cipher_type": "caesar",
  "cipher_text": "DWWDFN DW GDZQ",
  "answer_plain": "ATTACK AT DAWN",
  "cipher_params": { "shift": 3 },
  "clues": [
	{ "id": "clue_00", "type": "document", "content": "..." }
  ],
  "report_questions": [
	{ "question": "공격 시각은?", "answer": "새벽" }
  ]
}
```

---

## 8. 개발 단계 로드맵

| 단계 | 내용 | 산출물 | 상태 |
|------|------|--------|------|
| Phase 1 | 핵심 시스템 기반 | CipherLib, GameManager, JSON 로더 | ✅ 완료 |
| Phase 2 | 시저 해독기 + 튜토리얼 완성 | 플레이 가능한 튜토리얼 | ✅ 완료 |
| Phase 3 | 라디오 씬 + 단서 보드 | 감청 → 보드 연결 루프 | ✅ 완료 (PinLayer, Harrison 인트로 포함) |
| Phase 4 | 비즈네르 해독기 | 챕터 2 | ✅ 완료 |
| Phase 5 | 단일 치환 해독기 | 챕터 3 | ✅ 완료 |
| Phase 5.5 | 스토리·연출 개편 | chapter 00~03 단서 전면 재작성, CIPHER_INTROS, DECODED 도장 Tween | ✅ 완료 |
| Phase 6 | 에니그마 + 플레이페어 해독기 | 챕터 4 (레벨 1~3) | ✅ 완료 |
| Phase 7 | 단서 보드 비주얼 개편 | 타입별 카드 스타일 + 랜덤 회전 + 레드 헤링 extra_clues | ✅ 완료 |
| Phase 8 | 암호 박물관 (CipherMuseum) | 메인 메뉴 독립 섹션, 에니그마 10단계 신호 경로 시각화 | ✅ 완료 |
| Phase 9 | 스토리 로그 씬 | 해독 기록 타임라인 | ✅ 완료 |
| Phase 10 | 런타임 암호문 동적 생성 + 랜덤 주파수 | JSON 구조 변경, GameManager 리팩토링 | ✅ 완료 |
| Phase 11 | 오디오 폴리싱 | AudioManager, 라디오 스태틱 lerp, BGM/SFX 전 씬 삽입 | ✅ 완료 |
| Phase 12 | 마무리 | 레드 헤링 오답 피드백, 밸런스 조정, 최종 버그 픽스, 빌드 | ✅ 완료 |
| Phase 13 | 폴리싱 II | 힌트 제한·타이머·엔딩 분기 등 품질 향상 아이디어 (하단 참고) | ✅ 완료 |
| Phase 14 | 최종 완성 | 엔딩·설정·씬전환·보너스 챕터 구현 + 보고서 선택지 균등화 | ✅ 완료 |

---

## 9. 스코어/평가 시스템

- 각 챕터 별점 1~3개
- 힌트 사용 횟수 → 별 감소
- 보고서 오답 횟수 → 별 감소
- 총 별 수 → 엔딩 분기 (3종)

---

## 10. MVP 범위 (최소 완성 기준)

- [x] 튜토리얼 (시저 암호) 완전 동작
- [x] 라디오 감청 씬 (파형 시각화, 랜덤 주파수, lerp 스무딩)
- [x] 단서 보드 (카드 드래그, 실 연결, PinLayer 압정 렌더)
- [x] 단서·보드 콘텐츠 개편 (chapter 00~03 전면 재작성 — 군사 문서/쪽지/심문 형식)
- [x] 전반적 UI 비주얼 개선 (StyleBoxFlat 테마, MarginContainer 여백)
- [x] 비즈네르 해독기 (VigenereDecoder.gd/tscn)
- [x] 단일 치환 해독기 (SubstitutionDecoder.gd/tscn)
- [x] 보고서 제출 + 정오답 판정 (챕터당 2~3문항)
- [x] 챕터 0~3 데이터 완성 (cipher_text, clues, report_questions, completion_log)
- [x] DECODED 도장 Tween 애니메이션 + 별점 표시
- [x] 암호 방식 소개 오버레이 (CIPHER_INTROS)
- [x] 에니그마 해독기 + 플레이페어 해독기 + 챕터 4 데이터 (레벨 1~3)
- [x] 단서 카드 타입별 시각 스타일 (document/torn_paper/photo/interrogation)
- [x] 레드 헤링(가짜 단서) extra_clues — 전 챕터 레벨에 추가 완료
- [x] 암호 박물관 (CipherMuseum) — 메인 메뉴 독립 섹션, 에니그마 신호 경로 시각화
- [x] 효과음 (라디오 잡음, 도장, 타자기, 정오답 SFX) — AudioManager + 라디오 스태틱 lerp 완성
- [x] 스토리 로그 씬 (해독 기록 타임라인) — StoryLog.gd + StoryLog.tscn + 메인 메뉴 연결 완료
- [x] 런타임 암호문 동적 생성 (Phase 10) — CipherLib.encrypt(), 랜덤 주파수, JSON cipher_text/radio_frequency 필드 제거
- [ ] 레드 헤링 오답 전용 피드백 (Phase 12)
- [ ] 최종 밸런스 조정 및 빌드 (Phase 12)

---

## 11. Phase 12 완료 — 마무리 폴리싱 (2026-04-12)

### 완료된 작업

1. **레드 헤링 오답 전용 피드백** — `specific_wrong_feedback` 딕셔너리, `[RH]` 프리픽스, "단서 재검토 권고" 팝업, 별점 환산 (2회=1회)
2. **ch_02_01 단서 재설계** — 분석 보고서 → 노획 암호 운용 교범 (IRON 예시로 치환 메커니즘 설명)
3. **점진적 힌트 시스템** — 전체 15개 레벨에 `"hints": [약, 중, 강]` 루트 배열 추가; `GameManager.use_hint()` 우선 활용
4. **BOMBE 이스터에그** — ChapterView에서 "BOMBE" 키 입력 시 현재 레벨 1성 강제 완료
5. **ch_00_03 레드 헤링 버그 수정** — 식단표 "9주차" → "3주차"
6. **오디오 폴리싱** — AudioManager, 라디오 스태틱 lerp, BGM 크로스페이드 (Phase 11 포함)

---

## 12. Phase 13 계획 — 품질 향상 아이디어

### 우선순위 아이디어 목록

1. **힌트 횟수 제한 (3회)**
   - 현재 힌트는 무제한; 3회로 제한하면 힌트 사용 결정에 긴장감 부여
   - GameManager.hint_count ≥ 3이면 힌트 버튼 비활성화

2. **레벨 타이머**
   - 씬 입장 시 타이머 시작; 완료 시 경과 시간 기록
   - StoryLog에 클리어 시간 표시; 빠른 클리어에 보너스 별점 또는 뱃지

3. **레드 헤링 최종 해설 (DECODED 후)**
   - 레벨 완료 시 "이것은 가짜 단서였습니다" 팝업으로 레드 헤링 설명
   - 플레이어가 어떤 단서가 함정이었는지 배우는 교육 효과

4. **암호문 복사 버튼**
   - 해독기 상단 암호문 텍스트 옆에 복사 아이콘
   - 종이에 손으로 풀고 싶은 플레이어를 위한 편의 기능

5. ~~**씬 전환 애니메이션**~~ → **✅ Phase 14에서 구현** (SceneTransition.gd)

6. **EvidenceBoard 연결선 순차 등장**
   - 단서 카드가 추가될 때마다 연결선이 하나씩 그려지는 연출
   - 복잡한 단서망이 쌓이는 시각적 만족감

7. **보고서 Enter 키 단축키**
   - 보고서 모든 항목 선택 완료 후 Enter로 제출 가능
   - 마우스 없이 키보드로 완료 가능한 접근성 향상

8. ~~**총 별점 기반 3종 엔딩**~~ → **✅ Phase 14에서 구현** (Ending.gd/tscn)

9. ~~**보너스 챕터 — Harrison 시점**~~ → **✅ Phase 14에서 구현** (chapter_05_01~03.json)

10. ~~**설정 메뉴**~~ → **✅ Phase 14에서 구현** (Settings.gd/tscn + SettingsManager.gd)

---

## 13. Phase 14 완료 — 최종 완성 (2026-04-12)

### 완료된 작업

1. **총 별점 기반 3종 엔딩** (`Ending.gd` / `Ending.tscn`)
   - 총 별점(최대 45) 구간별 분기: 40+ = "전설적 분석관", 25~39 = "유능한 요원", ~24 = "경험 부족"
   - 별점·랭크·스토리 텍스트·메인 메뉴 복귀 버튼

2. **설정 메뉴** (`Settings.gd` / `Settings.tscn` / `SettingsManager.gd`)
   - BGM 볼륨, SFX 볼륨, 텍스트 속도 HSlider
   - SettingsManager autoload — `user://enigma_settings.json` 저장/로드

3. **씬 전환 페이드 애니메이션** (`SceneTransition.gd`)
   - CanvasLayer layer=128, 0.22초 페이드 인/아웃
   - 전역 `SceneTransition.fade_to(scene_path)` API

4. **보너스 챕터 5 — 배신자의 암호** (`chapter_05.json` + `chapter_05_01~03.json`)
   - "내부 고발 파일 — 기밀 해제 1960년"
   - Harrison이 독일 정보국에 유출한 교신 기록 해독 (Caesar 암호)

5. **보고서 선택지 글자수 균등화**
   - 모든 챕터 보고서 OptionButton 선택지 길이를 4단어 내외로 통일
   - 선택지 길이 차이로 정답을 유추하는 메타게임 방지
