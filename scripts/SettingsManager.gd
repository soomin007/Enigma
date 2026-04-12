## SettingsManager.gd — 게임 설정 저장/불러오기 (전역 싱글톤)
## BGM 볼륨, SFX 볼륨, 텍스트 속도, 언어를 관리한다.
extends Node

const SAVE_PATH := "user://settings.json"

# ── 기본값 ────────────────────────────────────────────────────────────
const DEFAULT_BGM_DB   := -6.0
const DEFAULT_SFX_DB   := -6.0
const DEFAULT_TEXT_SPD := 1.0   # 1.0 = 기본, 0.5 = 빠름, 2.0 = 느림
const DEFAULT_LANG     := "ko"

# ── 현재 설정값 ──────────────────────────────────────────────────────
var bgm_volume_db   : float  = DEFAULT_BGM_DB
var sfx_volume_db   : float  = DEFAULT_SFX_DB
var text_speed      : float  = DEFAULT_TEXT_SPD
var language        : String = DEFAULT_LANG


func _ready() -> void:
	load_settings()
	_apply_audio()


# ────────────────────────────────────────────────────────────────────
#  저장/불러오기
# ────────────────────────────────────────────────────────────────────

func save_settings() -> void:
	var data := {
		"bgm_volume_db" : bgm_volume_db,
		"sfx_volume_db" : sfx_volume_db,
		"text_speed"    : text_speed,
		"language"      : language,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SettingsManager: 설정 파일 저장 실패")
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()


func load_settings() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var text := file.get_as_text()
	file.close()

	var json := JSON.new()
	if json.parse(text) != OK:
		return
	var data: Dictionary = json.get_data()
	bgm_volume_db = data.get("bgm_volume_db", DEFAULT_BGM_DB)
	sfx_volume_db = data.get("sfx_volume_db", DEFAULT_SFX_DB)
	text_speed    = data.get("text_speed",    DEFAULT_TEXT_SPD)
	language      = data.get("language",      DEFAULT_LANG)


# ────────────────────────────────────────────────────────────────────
#  공개 설정 함수 (Settings UI에서 호출)
# ────────────────────────────────────────────────────────────────────

func set_bgm_volume(db: float) -> void:
	bgm_volume_db = clampf(db, -60.0, 0.0)
	_apply_audio()


func set_sfx_volume(db: float) -> void:
	sfx_volume_db = clampf(db, -60.0, 0.0)
	_apply_audio()


func set_text_speed(spd: float) -> void:
	text_speed = clampf(spd, 0.25, 3.0)


func get_text_speed_factor() -> float:
	return text_speed


func _apply_audio() -> void:
	var bgm_idx := AudioServer.get_bus_index("BGM")
	var sfx_idx := AudioServer.get_bus_index("SFX")
	if bgm_idx != -1:
		AudioServer.set_bus_volume_db(bgm_idx, bgm_volume_db)
	if sfx_idx != -1:
		AudioServer.set_bus_volume_db(sfx_idx, sfx_volume_db)
