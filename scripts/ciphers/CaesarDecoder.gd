## CaesarDecoder.gd — 시저 암호 해독기 UI
## ChapterView가 동적으로 인스턴스화하여 _cipher_container에 삽입한다.
extends Control

signal decode_confirmed(plain_text: String)

# ── 상태 ──────────────────────────────────────────────────────────
var _cipher_text  : String = ""
var _shift        : int    = 0
var _shift_right  : bool   = true   # true = 암호화 시 오른쪽 이동 (복호 시 왼쪽)

# ── UI 노드 레퍼런스 ──────────────────────────────────────────────
var _lbl_cipher   : Label
var _lbl_result   : Label
var _slider       : HSlider
var _lbl_shift_val: Label
var _btn_forward  : Button   # 암호화 방향: 앞으로(오른쪽)
var _btn_backward : Button   # 암호화 방향: 뒤로(왼쪽)
var _map_top_row  : Array[Label] = []  # 암호 알파벳 26개 라벨
var _map_bot_row  : Array[Label] = []  # 평문 알파벳 26개 라벨


# ────────────────────────────────────────────────────────────────────
#  초기화
# ────────────────────────────────────────────────────────────────────

## ChapterView에서 챕터 데이터를 넘겨 초기화
func setup(cipher_text: String, params: Dictionary) -> void:
	_cipher_text = cipher_text.to_upper()
	_shift       = params.get("shift", 0) as int
	_shift_right = params.get("shift_right", true) as bool

	# 슬라이더와 토글을 기본값으로 (플레이어가 직접 맞춰야 하므로 0으로 시작)
	_slider.value     = 0
	_shift            = 0
	_shift_right      = true
	_btn_forward.disabled  = false
	_btn_backward.disabled = false

	_lbl_cipher.text = _cipher_text
	_update_decoder()


func _ready() -> void:
	_build_ui()
	_update_decoder()


# ────────────────────────────────────────────────────────────────────
#  UI 구성
# ────────────────────────────────────────────────────────────────────

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.07, 0.08, 0.12)
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(bg)

	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 0)
	# 내부 여백
	root.offset_left   =  24
	root.offset_top    =  20
	root.offset_right  = -24
	root.offset_bottom = -20
	add_child(root)

	# ── 제목 ──
	var title_lbl := Label.new()
	title_lbl.text = "[ 시저 암호 해독기 · CAESAR CIPHER ]"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 16)
	title_lbl.add_theme_color_override("font_color", Color(0.60, 0.60, 0.75))
	root.add_child(title_lbl)

	root.add_child(_make_gap(10))
	root.add_child(HSeparator.new())
	root.add_child(_make_gap(14))

	# ── 암호문 표시 ──
	var cipher_hdr := Label.new()
	cipher_hdr.text = "감청 신호"
	cipher_hdr.add_theme_font_size_override("font_size", 13)
	cipher_hdr.add_theme_color_override("font_color", Color(0.50, 0.50, 0.62))
	root.add_child(cipher_hdr)

	_lbl_cipher = Label.new()
	_lbl_cipher.text = "─"
	_lbl_cipher.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_cipher.add_theme_font_size_override("font_size", 46)
	_lbl_cipher.add_theme_color_override("font_color", Color(0.93, 0.87, 0.40))
	root.add_child(_lbl_cipher)

	root.add_child(_make_gap(20))

	# ── 이동값 슬라이더 ──
	var shift_row := HBoxContainer.new()
	shift_row.add_theme_constant_override("separation", 14)
	root.add_child(shift_row)

	var shift_lbl := Label.new()
	shift_lbl.text = "이동값"
	shift_lbl.custom_minimum_size.x = 60
	shift_lbl.add_theme_font_size_override("font_size", 16)
	shift_row.add_child(shift_lbl)

	_slider = HSlider.new()
	_slider.min_value = 0
	_slider.max_value = 25
	_slider.step      = 1
	_slider.value     = 0
	_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_slider.value_changed.connect(_on_shift_changed)
	shift_row.add_child(_slider)

	_lbl_shift_val = Label.new()
	_lbl_shift_val.text = " 0"
	_lbl_shift_val.custom_minimum_size.x = 36
	_lbl_shift_val.add_theme_font_size_override("font_size", 22)
	_lbl_shift_val.add_theme_color_override("font_color", Color(0.90, 0.85, 0.40))
	shift_row.add_child(_lbl_shift_val)

	root.add_child(_make_gap(10))

	# ── 방향 토글 ──
	var dir_row := HBoxContainer.new()
	dir_row.add_theme_constant_override("separation", 10)
	root.add_child(dir_row)

	var dir_lbl := Label.new()
	dir_lbl.text = "암호화 방향"
	dir_lbl.custom_minimum_size.x = 100
	dir_lbl.add_theme_font_size_override("font_size", 15)
	dir_row.add_child(dir_lbl)

	_btn_forward = Button.new()
	_btn_forward.text = "▶  앞으로 이동 (Right)"
	_btn_forward.custom_minimum_size = Vector2(220, 38)
	_btn_forward.add_theme_font_size_override("font_size", 14)
	_btn_forward.pressed.connect(func(): _set_direction(true))
	dir_row.add_child(_btn_forward)

	_btn_backward = Button.new()
	_btn_backward.text = "◀  뒤로 이동 (Left)"
	_btn_backward.custom_minimum_size = Vector2(200, 38)
	_btn_backward.add_theme_font_size_override("font_size", 14)
	_btn_backward.pressed.connect(func(): _set_direction(false))
	dir_row.add_child(_btn_backward)

	root.add_child(_make_gap(18))
	root.add_child(HSeparator.new())
	root.add_child(_make_gap(10))

	# ── 알파벳 대응표 ──
	var map_lbl := Label.new()
	map_lbl.text = "알파벳 대응표  (암호 → 평문)"
	map_lbl.add_theme_font_size_override("font_size", 13)
	map_lbl.add_theme_color_override("font_color", Color(0.50, 0.50, 0.62))
	root.add_child(map_lbl)

	root.add_child(_make_gap(4))
	root.add_child(_build_alphabet_map())

	root.add_child(_make_gap(18))
	root.add_child(HSeparator.new())
	root.add_child(_make_gap(10))

	# ── 해독 결과 ──
	var result_hdr := Label.new()
	result_hdr.text = "해독 결과"
	result_hdr.add_theme_font_size_override("font_size", 13)
	result_hdr.add_theme_color_override("font_color", Color(0.50, 0.50, 0.62))
	root.add_child(result_hdr)

	_lbl_result = Label.new()
	_lbl_result.text = "─"
	_lbl_result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_result.add_theme_font_size_override("font_size", 46)
	_lbl_result.add_theme_color_override("font_color", Color(0.38, 0.88, 0.58))
	root.add_child(_lbl_result)

	root.add_child(_make_gap(16))

	# ── 확정 버튼 ──
	var confirm_row := HBoxContainer.new()
	confirm_row.alignment = BoxContainer.ALIGNMENT_END
	root.add_child(confirm_row)

	var confirm_btn := Button.new()
	confirm_btn.text = "이 내용이 맞습니다  →  보고서 작성"
	confirm_btn.custom_minimum_size = Vector2(320, 48)
	confirm_btn.add_theme_font_size_override("font_size", 17)
	confirm_btn.pressed.connect(_on_confirm)
	confirm_row.add_child(confirm_btn)


func _build_alphabet_map() -> Control:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)

	# 행 1: 암호 알파벳 (고정)
	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 2)
	vbox.add_child(top_row)

	# 행 2: 평문 알파벳 (이동값·방향에 따라 변경)
	var bot_row := HBoxContainer.new()
	bot_row.add_theme_constant_override("separation", 2)
	vbox.add_child(bot_row)

	for i in 26:
		var top_lbl := Label.new()
		top_lbl.text = char(65 + i)
		top_lbl.custom_minimum_size.x = 24
		top_lbl.horizontal_alignment  = HORIZONTAL_ALIGNMENT_CENTER
		top_lbl.add_theme_font_size_override("font_size", 13)
		top_lbl.add_theme_color_override("font_color", Color(0.85, 0.82, 0.50))
		top_row.add_child(top_lbl)
		_map_top_row.append(top_lbl)

		var bot_lbl := Label.new()
		bot_lbl.text = char(65 + i)
		bot_lbl.custom_minimum_size.x = 24
		bot_lbl.horizontal_alignment  = HORIZONTAL_ALIGNMENT_CENTER
		bot_lbl.add_theme_font_size_override("font_size", 13)
		bot_lbl.add_theme_color_override("font_color", Color(0.38, 0.88, 0.58))
		bot_row.add_child(bot_lbl)
		_map_bot_row.append(bot_lbl)

	return vbox


# ────────────────────────────────────────────────────────────────────
#  로직
# ────────────────────────────────────────────────────────────────────

func _on_shift_changed(value: float) -> void:
	_shift = int(value)
	_lbl_shift_val.text = "%2d" % _shift
	_update_decoder()


func _set_direction(right: bool) -> void:
	_shift_right = right
	# 선택된 버튼 비활성화 (현재 선택 표시)
	_btn_forward.disabled  = right
	_btn_backward.disabled = not right
	_update_decoder()


func _update_decoder() -> void:
	if _cipher_text.is_empty():
		return

	# 평문 계산
	var plain := CipherLib.caesar_decode(_cipher_text, _shift, _shift_right)
	_lbl_result.text = plain

	# 알파벳 대응표 갱신
	for i in 26:
		var decoded_char := CipherLib.caesar_decode(char(65 + i), _shift, _shift_right)
		_map_bot_row[i].text = decoded_char

		# 암호문에 포함된 글자 강조
		if _cipher_text.contains(char(65 + i)):
			_map_top_row[i].add_theme_color_override("font_color", Color(0.93, 0.87, 0.40))
		else:
			_map_top_row[i].add_theme_color_override("font_color", Color(0.50, 0.50, 0.62))


func _on_confirm() -> void:
	var plain := CipherLib.caesar_decode(_cipher_text, _shift, _shift_right)
	emit_signal("decode_confirmed", plain)


# ────────────────────────────────────────────────────────────────────
#  유틸리티
# ────────────────────────────────────────────────────────────────────

func _make_gap(height: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size.y = height
	return c
