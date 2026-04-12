## GameManager.gd
## 전역 싱글톤 — 게임 진행 상태를 관리하고 씬 간 신호를 중계한다.
## autoload 이름: GameManager
extends Node

const SAVE_PATH := "user://enigma_save.json"

# ───────────────────────────────────────────────
#  신호 (Signals)
# ───────────────────────────────────────────────

signal chapter_loaded(data: Dictionary)
signal clue_collected(clue: Dictionary)
signal decode_succeeded(chapter_id: int, plain_text: String)
signal report_result(correct: bool, feedback: String)
signal chapter_completed(chapter_id: int, stars: int)
signal hint_revealed(hint_text: String)
signal hint_exhausted()
signal radio_tuned(chapter_id: int)


# ───────────────────────────────────────────────
#  게임 상태 변수
# ───────────────────────────────────────────────

var current_chapter_id : int        = 0
var current_level_id   : int        = 1
var current_chapter    : Dictionary = {}

## 레벨별 수집된 단서 ID 목록  { "C_L": [clue_id, ...] }
var collected_clues    : Dictionary = {}

## 레벨별 해독된 평문           { "C_L": plain_text }
var decoded_messages   : Dictionary = {}

## 레벨별 획득 별점              { "C_L": 1~3 }
var level_stars        : Dictionary = {}

const HINT_MAX := 3   # 레벨당 최대 힌트 사용 횟수

var hint_count              : int = 0
var wrong_report_count      : int = 0
var red_herring_wrong_count : int = 0   # specific_wrong_feedback 히트 횟수 (2회 = 일반 오답 1회)
var _hint_index             : int = 0

## 레벨 타이머 (Unix 시각)
var _level_start_time  : float = 0.0
var level_elapsed_secs : float = 0.0

## 완료된 레벨 작전 기록
var story_log : Array = []


# ───────────────────────────────────────────────
#  내부 헬퍼
# ───────────────────────────────────────────────

## 현재 챕터+레벨을 "C_L" 문자열 키로 반환
func _lkey(chapter_id: int = -1, level_id: int = -1) -> String:
	if chapter_id == -1:
		chapter_id = current_chapter_id
	if level_id == -1:
		level_id = current_level_id
	return "%d_%d" % [chapter_id, level_id]


# ───────────────────────────────────────────────
#  초기화 + 저장/불러오기
# ───────────────────────────────────────────────

func _ready() -> void:
	load_game()


func save_game() -> void:
	var data := {
		"level_stars"      : level_stars,
		"decoded_messages" : decoded_messages,
		"collected_clues"  : collected_clues,
		"story_log"        : story_log,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("GameManager: 저장 파일을 열 수 없습니다 — " + SAVE_PATH)
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var text := file.get_as_text()
	file.close()

	var json := JSON.new()
	if json.parse(text) != OK:
		push_warning("GameManager: 저장 파일 파싱 실패")
		return

	var data: Dictionary = json.get_data()

	# 신규 포맷 (level_stars 키)
	if data.has("level_stars"):
		level_stars      = data.get("level_stars", {})
		decoded_messages = data.get("decoded_messages", {})
		collected_clues  = data.get("collected_clues", {})
	else:
		# 구형 포맷 마이그레이션 (chapter_stars int 키 → "C_1" 문자열 키)
		var old_stars: Dictionary = data.get("chapter_stars", {})
		for k in old_stars:
			level_stars["%s_1" % k] = int(old_stars[k])

	var log_in: Array = data.get("story_log", [])
	story_log.clear()
	for entry in log_in:
		var entry_dict: Dictionary = entry
		story_log.append(entry_dict)


func reset_save() -> void:
	level_stars        = {}
	decoded_messages   = {}
	collected_clues    = {}
	story_log          = []
	current_chapter_id = 0
	current_level_id   = 1
	if FileAccess.file_exists(SAVE_PATH):
		var dir := DirAccess.open("user://")
		if dir != null:
			dir.remove("enigma_save.json")


# ───────────────────────────────────────────────
#  레벨 로드
# ───────────────────────────────────────────────

## chapter_id, level_id 번 레벨 JSON을 불러와 current_chapter에 저장한다.
func load_level(chapter_id: int, level_id: int) -> void:
	current_chapter_id      = chapter_id
	current_level_id        = level_id
	hint_count              = 0
	wrong_report_count      = 0
	red_herring_wrong_count = 0
	_hint_index             = 0

	var key := _lkey()
	if not collected_clues.has(key):
		collected_clues[key] = []

	# 타이머 시작
	_level_start_time  = Time.get_unix_time_from_system()
	level_elapsed_secs = 0.0

	var path := "res://data/chapters/chapter_%02d_%02d.json" % [chapter_id, level_id]
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("GameManager: 레벨 파일을 열 수 없습니다 — " + path)
		return

	var text := file.get_as_text()
	file.close()

	var json   := JSON.new()
	if json.parse(text) != OK:
		push_error("GameManager: JSON 파싱 실패 — " + path)
		return

	current_chapter = json.get_data()

	# ── 런타임 암호문 동적 생성 ──────────────────────────────
	# JSON의 plain_text + cipher_params 로 cipher_text 를 계산한다.
	# JSON 에 cipher_text 가 하드코딩되어 있어도 런타임 값으로 덮어쓴다.
	var plain  : String     = current_chapter.get("plain_text", "")
	var ctype  : String     = current_chapter.get("cipher_type", "")
	var params : Dictionary = current_chapter.get("cipher_params", {})
	if not plain.is_empty() and not ctype.is_empty():
		current_chapter["cipher_text"] = CipherLib.encrypt(plain, ctype, params)

	# ── 주파수 런타임 랜덤화 ────────────────────────────────
	# 100.0 ~ 999.9 kHz, 소수점 1자리 고정
	current_chapter["radio_frequency"] = snappedf(randf_range(100.0, 999.9), 0.1)

	emit_signal("chapter_loaded", current_chapter)


## 하위 호환 래퍼 — RadioScene/ChapterView 등에서 그대로 사용 가능
func load_chapter(id: int) -> void:
	load_level(id, current_level_id)


# ───────────────────────────────────────────────
#  단서 수집
# ───────────────────────────────────────────────

func collect_clue(clue_id: String) -> Dictionary:
	var clue := _find_clue(clue_id)
	if clue.is_empty():
		push_warning("GameManager: 단서를 찾을 수 없습니다 — " + clue_id)
		return {}

	var key := _lkey()
	var level_clues: Array = collected_clues.get(key, [])
	if not level_clues.has(clue_id):
		level_clues.append(clue_id)
		collected_clues[key] = level_clues
		emit_signal("clue_collected", clue)

	return clue


func _find_clue(clue_id: String) -> Dictionary:
	for pool_key in ["clues", "extra_clues"]:
		if not current_chapter.has(pool_key):
			continue
		for clue in current_chapter[pool_key]:
			var c: Dictionary = clue
			if c["id"] == clue_id:
				return c
	return {}


func get_collected_clues() -> Array:
	var key := _lkey()
	var ids: Array = collected_clues.get(key, [])
	var result: Array = []
	for id in ids:
		var clue := _find_clue(id)
		if not clue.is_empty():
			result.append(clue)
	return result


# ───────────────────────────────────────────────
#  해독 성공 등록
# ───────────────────────────────────────────────

func register_decode(plain_text: String) -> void:
	var key := _lkey()
	decoded_messages[key] = plain_text
	emit_signal("decode_succeeded", current_chapter_id, plain_text)


# ───────────────────────────────────────────────
#  보고서 검증
# ───────────────────────────────────────────────

func submit_report(answers: Dictionary) -> void:
	var questions: Array = current_chapter.get("report_questions", [])
	var all_correct         := true
	var feedback            := ""
	var is_red_herring_miss := false

	for q in questions:
		var q_dict   : Dictionary = q
		var qid      : String = q_dict["id"]
		var expected : String = q_dict["answer_key"].to_upper().strip_edges()
		var given    : String = answers.get(qid, "").to_upper().strip_edges()

		if given != expected:
			all_correct = false
			# specific_wrong_feedback 우선 확인
			var specific_fb: Dictionary = q_dict.get("specific_wrong_feedback", {})
			if specific_fb.has(given):
				feedback            = "[RH]" + specific_fb[given]
				is_red_herring_miss = true
			else:
				feedback = q_dict.get("wrong_feedback", q_dict["question"] + " — 다시 확인하십시오.")
			break

	if all_correct:
		level_elapsed_secs = Time.get_unix_time_from_system() - _level_start_time
		var stars := _calculate_stars()
		var key   := _lkey()
		level_stars[key] = stars
		_save_story_log(stars)
		save_game()
		emit_signal("report_result", true, "보고서 채택. 임무 완수.")
		emit_signal("chapter_completed", current_chapter_id, stars)
	else:
		if is_red_herring_miss:
			red_herring_wrong_count += 1
		else:
			wrong_report_count += 1
		emit_signal("report_result", false, feedback)


func _save_story_log(stars: int) -> void:
	var log_data: Dictionary = current_chapter.get("completion_log", {})
	var key := _lkey()
	for i in story_log.size():
		var entry: Dictionary = story_log[i]
		if entry.get("level_key", "") == key:
			story_log[i] = _make_log_entry(log_data, stars)
			return
	story_log.append(_make_log_entry(log_data, stars))


func _make_log_entry(log_data: Dictionary, stars: int) -> Dictionary:
	var secs: int = int(level_elapsed_secs)
	var time_str: String
	if secs < 60:
		time_str = "%d초" % secs
	else:
		time_str = "%d분 %02d초" % [secs / 60, secs % 60]
	# 3분 이내 클리어 시 속도 뱃지
	var speed_badge: bool = level_elapsed_secs > 0.0 and level_elapsed_secs < 180.0

	return {
		"level_key"   : _lkey(),
		"chapter_id"  : current_chapter_id,
		"level_id"    : current_level_id,
		"title"       : current_chapter.get("title", ""),
		"subtitle"    : current_chapter.get("subtitle", ""),
		"difficulty"  : current_chapter.get("difficulty", ""),
		"date"        : log_data.get("date", ""),
		"time"        : log_data.get("time", ""),
		"frequency"   : "%.1f kHz" % current_chapter.get("radio_frequency", 0.0),
		"sender"      : log_data.get("sender", ""),
		"receiver"    : log_data.get("receiver", ""),
		"decoded"     : log_data.get("decoded", decoded_messages.get(_lkey(), "")),
		"stars"       : stars,
		"log_text"    : current_chapter.get("completion_log_text", ""),
		"clear_time"  : time_str,
		"speed_badge" : speed_badge,
	}


func _calculate_stars() -> int:
	# 레드 헤링 오답은 2회 = 일반 오답 1회로 환산
	var effective_wrong := wrong_report_count + (red_herring_wrong_count / 2)
	if hint_count == 0 and effective_wrong == 0:
		return 3
	elif hint_count <= 1 and effective_wrong <= 1:
		return 2
	else:
		return 1


# ───────────────────────────────────────────────
#  힌트
# ───────────────────────────────────────────────

func use_hint_with_text(hint_text: String) -> void:
	if hint_count >= HINT_MAX:
		emit_signal("hint_exhausted")
		return
	hint_count += 1
	emit_signal("hint_revealed", hint_text)


func use_hint() -> void:
	if hint_count >= HINT_MAX:
		emit_signal("hint_exhausted")
		return
	# 루트 레벨 hints 배열 우선 사용 (점진적 강도 힌트)
	var root_hints: Array = current_chapter.get("hints", [])
	if root_hints.size() > 0:
		var idx := mini(_hint_index, root_hints.size() - 1)
		var hint_text: String = root_hints[idx]
		_hint_index = mini(_hint_index + 1, root_hints.size() - 1)
		hint_count += 1
		emit_signal("hint_revealed", hint_text)
		return

	# fallback: 수집된 단서의 hint_value 순환
	var key       := _lkey()
	var clue_ids  : Array = collected_clues.get(key, [])
	var hint_pool : Array = []

	for cid in clue_ids:
		var clue := _find_clue(cid)
		if clue.has("hint_value") and not clue["hint_value"].is_empty():
			hint_pool.append(clue["hint_value"])

	if hint_pool.is_empty():
		emit_signal("hint_revealed", "수집된 단서에서 힌트를 찾을 수 없습니다.")
		return

	var idx  := mini(_hint_index, hint_pool.size() - 1)
	var text : String = hint_pool[idx]
	_hint_index = mini(_hint_index + 1, hint_pool.size() - 1)

	hint_count += 1
	emit_signal("hint_revealed", text)


## BOMBE 이스터에그: 현재 레벨을 1성으로 강제 완료
func debug_complete_level() -> void:
	if is_level_complete(current_chapter_id, current_level_id):
		return
	var stars := 1
	var key   := _lkey()
	level_stars[key] = stars
	_save_story_log(stars)
	save_game()
	emit_signal("chapter_completed", current_chapter_id, stars)


# ───────────────────────────────────────────────
#  조회 헬퍼
# ───────────────────────────────────────────────

func get_level_stars(chapter_id: int, level_id: int) -> int:
	return level_stars.get(_lkey(chapter_id, level_id), 0)

## MainMenu 호환용 — 챕터 레벨1 별점 반환
func get_stars(chapter_id: int) -> int:
	return get_level_stars(chapter_id, 1)

func is_level_complete(chapter_id: int, level_id: int) -> bool:
	return level_stars.has(_lkey(chapter_id, level_id))

## 챕터 레벨1을 완료했으면 챕터 완료로 간주
func is_chapter_complete(chapter_id: int) -> bool:
	return is_level_complete(chapter_id, 1)

## 레벨 해금 규칙:
## - 챕터 0 레벨 1: 항상 해금
## - 챕터 N 레벨 1: 챕터 N-1 레벨 1 완료 시 해금
## - 챕터 N 레벨 M(M>1): 챕터 N 레벨 M-1 완료 시 해금
func is_level_unlocked(chapter_id: int, level_id: int) -> bool:
	if chapter_id == 0 and level_id == 1:
		return true
	if level_id == 1:
		return is_level_complete(chapter_id - 1, 1)
	return is_level_complete(chapter_id, level_id - 1)

func get_decoded_message(chapter_id: int, level_id: int = -1) -> String:
	if level_id == -1:
		level_id = current_level_id
	return decoded_messages.get(_lkey(chapter_id, level_id), "")

func total_stars() -> int:
	var total := 0
	for s in level_stars.values():
		total += int(s)
	return total
