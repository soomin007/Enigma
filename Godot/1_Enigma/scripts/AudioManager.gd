## AudioManager.gd — 전역 오디오 매니저
## BGM 페이드 전환 + 효과음 재생 + Audio Bus 자동 생성을 담당한다.
extends Node

# ── BGM 경로 (파일 준비 후 채울 것) ────────────────────────────────
const BGM_PATHS: Dictionary = {
	"menu"     : "res://sounds/A_Room_Without_Windows.mp3",
	"radio"    : "",   # 라디오 스태틱이 음향 담당 — BGM 없음
	"gameplay" : "res://sounds/A_Room_Without_Windows.mp3",
}

# ── SFX 경로 ────────────────────────────────────────────────────────
# 값이 Array 이면 랜덤으로 1개 선택해 재생
const SFX_PATHS: Dictionary = {
	"signal_lock" : "res://sounds/walkie_talkie_over_beep.wav",
	"paper"       : "res://sounds/paper_flip.wav",
	"typewriter"  : "res://sounds/type-writing.wav",
	"stamp"       : "res://sounds/sfx_stamp.wav",
	"correct"     : "res://sounds/sfx_correct.wav",
	"wrong"       : "res://sounds/sfx_wrong.mp3",
}

const BUS_BGM := "BGM"
const BUS_SFX := "SFX"
const VOL_BGM_DEFAULT  := -6.0    # dB
const VOL_SFX_DEFAULT  := -6.0     # dB
const FADE_DB_PER_SEC  := 18.0    # 페이드 속도
const VOL_STATIC_MAX   := -6.0    # 신호 없을 때 라디오 스태틱 최대 볼륨
const VOL_STATIC_SILENT := -60.0  # 신호 완전 수신 시 스태틱 무음

var _bgm_player        : AudioStreamPlayer
var _sfx_pool          : Array[AudioStreamPlayer] = []
var _typewriter_player : AudioStreamPlayer          # 타자기 전용 (길이 있는 단일 파일)
var _radio_static_player : AudioStreamPlayer        # 라디오 잡음 전용 (루프)
const POOL_SIZE        := 6

var _fade_target  : float  = VOL_BGM_DEFAULT
var _fading       : bool   = false
var _queued_bgm   : String = ""


func _ready() -> void:
	_ensure_buses()

	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.bus = BUS_BGM
	_bgm_player.volume_db = VOL_BGM_DEFAULT
	add_child(_bgm_player)

	_typewriter_player = AudioStreamPlayer.new()
	_typewriter_player.bus = BUS_SFX
	_typewriter_player.volume_db = VOL_SFX_DEFAULT
	add_child(_typewriter_player)

	_radio_static_player = AudioStreamPlayer.new()
	_radio_static_player.bus = BUS_SFX
	_radio_static_player.volume_db = VOL_STATIC_MAX
	add_child(_radio_static_player)

	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = BUS_SFX
		p.volume_db = VOL_SFX_DEFAULT
		add_child(p)
		_sfx_pool.append(p)


# ── Audio Bus 자동 생성 ──────────────────────────────────────────────
func _ensure_buses() -> void:
	if AudioServer.get_bus_index(BUS_BGM) == -1:
		var idx := AudioServer.bus_count
		AudioServer.add_bus(idx)
		AudioServer.set_bus_name(idx, BUS_BGM)
		AudioServer.set_bus_volume_db(idx, 0.0)

	if AudioServer.get_bus_index(BUS_SFX) == -1:
		var idx := AudioServer.bus_count
		AudioServer.add_bus(idx)
		AudioServer.set_bus_name(idx, BUS_SFX)
		AudioServer.set_bus_volume_db(idx, 0.0)


# ── 페이드 처리 ──────────────────────────────────────────────────────
func _process(delta: float) -> void:
	if not _fading:
		return

	var step := FADE_DB_PER_SEC * delta
	if _bgm_player.volume_db > _fade_target:
		_bgm_player.volume_db = maxf(_bgm_player.volume_db - step, _fade_target)
	else:
		_bgm_player.volume_db = minf(_bgm_player.volume_db + step, _fade_target)

	if absf(_bgm_player.volume_db - _fade_target) < 0.1:
		_bgm_player.volume_db = _fade_target
		_fading = false
		if _bgm_player.volume_db <= -60.0:
			_bgm_player.stop()
			if not _queued_bgm.is_empty():
				_start_bgm(_queued_bgm)
				_queued_bgm = ""


# ── BGM ─────────────────────────────────────────────────────────────

func play_bgm(key: String, cross_fade: bool = true) -> void:
	var path: String = BGM_PATHS.get(key, "")
	if path.is_empty():
		return   # 파일 미준비 — 조용히 무시
	if _bgm_player.playing and _bgm_player.stream != null:
		if _bgm_player.stream.resource_path == path:
			return   # 이미 같은 트랙
	if cross_fade and _bgm_player.playing:
		_queued_bgm  = key
		_fade_target = -80.0
		_fading      = true
	else:
		_start_bgm(key)


func stop_bgm() -> void:
	_bgm_player.stop()
	_fading     = false
	_queued_bgm = ""


func fade_out_bgm() -> void:
	if not _bgm_player.playing:
		return
	_queued_bgm  = ""
	_fade_target = -80.0
	_fading      = true


func _start_bgm(key: String) -> void:
	var path: String = BGM_PATHS.get(key, "")
	if path.is_empty() or not ResourceLoader.exists(path):
		return
	var stream: AudioStream = load(path)
	# MP3/OGG 루프 설정 — 에디터 import 설정 없이 코드에서 강제 적용
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	elif stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	_bgm_player.stream    = stream
	_bgm_player.volume_db = VOL_BGM_DEFAULT
	_bgm_player.play()


# ── SFX 원샷 ────────────────────────────────────────────────────────

## 효과음 1회 재생. 값이 Array면 랜덤 선택.
func play_sfx(key: String) -> void:
	var entry = SFX_PATHS.get(key, null)
	if entry == null:
		push_warning("AudioManager: 알 수 없는 SFX 키 — " + key)
		return

	var path: String
	if entry is Array:
		var arr: Array = entry
		path = arr[randi() % arr.size()]
	else:
		path = entry

	if not ResourceLoader.exists(path):
		push_warning("AudioManager: SFX 파일 없음 — " + path)
		return

	var stream: AudioStream = load(path)
	for p: AudioStreamPlayer in _sfx_pool:
		if not p.playing:
			p.stream = stream
			p.play()
			return
	# 풀이 꽉 찼으면 첫 번째 채널 강제 재사용
	var first: AudioStreamPlayer = _sfx_pool[0]
	first.stream = stream
	first.play()


# ── 타자기 전용 ──────────────────────────────────────────────────────

## 타자기 애니메이션 시작 시 호출 — 파일 끝까지 1회 재생
func start_typewriter() -> void:
	var path: String = SFX_PATHS.get("typewriter", "")
	if path.is_empty() or not ResourceLoader.exists(path):
		return
	if _typewriter_player.playing:
		return   # 이미 재생 중이면 중단하지 않음
	_typewriter_player.stream = load(path)
	_typewriter_player.play()


## 타자기 애니메이션 완료·스킵 시 호출
func stop_typewriter() -> void:
	_typewriter_player.stop()


# ── 라디오 잡음 전용 ─────────────────────────────────────────────────

## 라디오 씬 진입 시 호출 — radio_signal.ogg 루프 재생
func start_radio_static() -> void:
	var path := "res://sounds/radio_signal.ogg"
	if not ResourceLoader.exists(path):
		return
	var stream: AudioStream = load(path)
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	elif stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	_radio_static_player.stream    = stream
	_radio_static_player.volume_db = VOL_STATIC_MAX
	_radio_static_player.play()


## _process에서 매 프레임 호출 — strength(0~1)에 반비례하여 볼륨 조절
## strength=0 → 잡음 최대, strength=1 → 무음
func set_radio_static_strength(strength: float) -> void:
	if not _radio_static_player.playing:
		return
	_radio_static_player.volume_db = lerpf(VOL_STATIC_MAX, VOL_STATIC_SILENT, strength)


## 동조 완료 또는 씬 이탈 시 호출
func stop_radio_static() -> void:
	_radio_static_player.stop()


# ── 볼륨 제어 (SettingsManager에서 호출) ─────────────────────────────

func apply_settings() -> void:
	var bgm_idx := AudioServer.get_bus_index(BUS_BGM)
	var sfx_idx := AudioServer.get_bus_index(BUS_SFX)
	if bgm_idx != -1:
		AudioServer.set_bus_volume_db(bgm_idx, SettingsManager.bgm_volume_db)
	if sfx_idx != -1:
		AudioServer.set_bus_volume_db(sfx_idx, SettingsManager.sfx_volume_db)
