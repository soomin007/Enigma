## PlayfairDecoder.gd
## 5×5 Playfair 격자 시각화 + 실시간 복호화 해독기 UI
## ChapterView에서 cipher_type == "playfair" 일 때 생성된다.
extends Control

signal decode_confirmed(plain_text: String)

# ── 팔레트 ─────────────────────────────────────────────────────────────
const C_BG         := Color(0.04,  0.05,  0.09)
const C_PANEL      := Color(0.065, 0.075, 0.12)
const C_GOLD       := Color(0.93,  0.87,  0.40)
const C_GREEN      := Color(0.22,  0.92,  0.48)
const C_MUTED      := Color(0.40,  0.40,  0.52)
const C_BORDER     := Color(0.18,  0.20,  0.32)
const C_BORDER_G   := Color(0.50,  0.44,  0.15)
const C_CELL_BG    := Color(0.08,  0.09,  0.15)
const C_CELL_HOVER := Color(0.14,  0.16,  0.26)
const C_KEY_CELL   := Color(0.12,  0.18,  0.10)

# ── 상태 변수 ───────────────────────────────────────────────────────────
var _cipher_text  : String = ""
var _current_key  : String = ""

var _key_input    : LineEdit
var _grid_labels  : Array  = []   # Array of Label (25개)
var _decoded_lbl  : Label
var _cipher_lbl   : Label


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_build_ui()


## ChapterView._load_decoder() 에서 setup(cipher_text, cipher_params) 로 호출됨
func setup(cipher_text: String, _params: Dictionary = {}) -> void:
	_cipher_text = cipher_text
	if _cipher_lbl != null:
		_cipher_lbl.text = cipher_text
	_refresh()


# ─────────────────────────────────────────────────────────────────────
#  UI 구성
# ─────────────────────────────────────────────────────────────────────

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = C_BG
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(bg)

	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 0)
	add_child(root)

	root.add_child(_build_top_bar())

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   56)
	margin.add_theme_constant_override("margin_right",  56)
	margin.add_theme_constant_override("margin_top",    32)
	margin.add_theme_constant_override("margin_bottom", 48)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 28)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(content)

	content.add_child(_build_cipher_panel())
	content.add_child(_build_key_panel())
	content.add_child(_build_grid_panel())
	content.add_child(_build_decoded_panel())


func _build_top_bar() -> Control:
	var bar := PanelContainer.new()
	bar.custom_minimum_size.y = 50

	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.055, 0.065, 0.105)
	ps.border_color = C_BORDER_G
	ps.border_width_bottom = 1
	bar.add_theme_stylebox_override("panel", ps)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",  16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top",    8)
	margin.add_theme_constant_override("margin_bottom", 8)
	bar.add_child(margin)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 14)
	margin.add_child(hbox)

	var title := Label.new()
	title.text = "플레이페어 해독기  ·  PLAYFAIR DECODER"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", C_GOLD)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(title)

	var hint := Label.new()
	hint.text = "키워드를 입력하면 격자가 자동 생성됩니다"
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", C_MUTED)
	hbox.add_child(hint)

	return bar


func _build_cipher_panel() -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var ps := _make_style(C_PANEL, C_BORDER, 1)
	panel.add_theme_stylebox_override("panel", ps)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   20)
	margin.add_theme_constant_override("margin_right",  20)
	margin.add_theme_constant_override("margin_top",    16)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	var hdr := Label.new()
	hdr.text = "▶  암호문"
	hdr.add_theme_font_size_override("font_size", 12)
	hdr.add_theme_color_override("font_color", C_MUTED)
	vbox.add_child(hdr)

	_cipher_lbl = Label.new()
	_cipher_lbl.text = _cipher_text
	_cipher_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cipher_lbl.add_theme_font_size_override("font_size", 26)
	_cipher_lbl.add_theme_color_override("font_color", Color(0.82, 0.85, 0.95))
	_cipher_lbl.add_theme_constant_override("outline_size", 0)
	vbox.add_child(_cipher_lbl)

	return panel


func _build_key_panel() -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var ps := _make_style(C_PANEL, C_BORDER_G, 1)
	panel.add_theme_stylebox_override("panel", ps)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   20)
	margin.add_theme_constant_override("margin_right",  20)
	margin.add_theme_constant_override("margin_top",    16)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	var hdr := Label.new()
	hdr.text = "격자 키워드  (영문, J=I 통합)"
	hdr.add_theme_font_size_override("font_size", 13)
	hdr.add_theme_color_override("font_color", C_GOLD)
	vbox.add_child(hdr)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	vbox.add_child(row)

	_key_input = LineEdit.new()
	_key_input.placeholder_text = "키워드 입력 (예: KEY)"
	_key_input.max_length = 25
	_key_input.custom_minimum_size = Vector2(320, 40)
	_key_input.add_theme_font_size_override("font_size", 20)
	_key_input.text_changed.connect(_on_key_changed)
	row.add_child(_key_input)

	var clear_btn := Button.new()
	clear_btn.text = "지우기"
	clear_btn.custom_minimum_size.x = 80
	clear_btn.pressed.connect(func():
		_key_input.text = ""
		_on_key_changed("")
	)
	row.add_child(clear_btn)

	return panel


func _build_grid_panel() -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var ps := _make_style(C_PANEL, C_BORDER, 1)
	panel.add_theme_stylebox_override("panel", ps)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   20)
	margin.add_theme_constant_override("margin_right",  20)
	margin.add_theme_constant_override("margin_top",    16)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	var hdr := Label.new()
	hdr.text = "5 × 5  격자"
	hdr.add_theme_font_size_override("font_size", 13)
	hdr.add_theme_color_override("font_color", C_GOLD)
	vbox.add_child(hdr)

	# 격자 컨테이너: 수평 중앙 배치
	var grid_outer := HBoxContainer.new()
	grid_outer.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(grid_outer)

	var grid_v := VBoxContainer.new()
	grid_v.add_theme_constant_override("separation", 4)
	grid_outer.add_child(grid_v)

	_grid_labels.clear()
	for r in 5:
		var row_h := HBoxContainer.new()
		row_h.add_theme_constant_override("separation", 4)
		grid_v.add_child(row_h)
		for c in 5:
			var cell := Label.new()
			cell.custom_minimum_size = Vector2(52, 52)
			cell.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			cell.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
			cell.add_theme_font_size_override("font_size", 22)
			cell.add_theme_color_override("font_color", C_MUTED)
			var cs := StyleBoxFlat.new()
			cs.bg_color = C_CELL_BG
			cs.border_color = C_BORDER
			cs.border_width_left   = 1
			cs.border_width_right  = 1
			cs.border_width_top    = 1
			cs.border_width_bottom = 1
			cs.corner_radius_top_left     = 4
			cs.corner_radius_top_right    = 4
			cs.corner_radius_bottom_left  = 4
			cs.corner_radius_bottom_right = 4
			cell.add_theme_stylebox_override("normal", cs)
			row_h.add_child(cell)
			_grid_labels.append(cell)

	return panel


func _build_decoded_panel() -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var ps := _make_style(Color(0.04, 0.08, 0.06), C_BORDER_G, 1)
	panel.add_theme_stylebox_override("panel", ps)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   20)
	margin.add_theme_constant_override("margin_right",  20)
	margin.add_theme_constant_override("margin_top",    16)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	var hdr := Label.new()
	hdr.text = "▶  해독 결과"
	hdr.add_theme_font_size_override("font_size", 12)
	hdr.add_theme_color_override("font_color", C_MUTED)
	vbox.add_child(hdr)

	_decoded_lbl = Label.new()
	_decoded_lbl.text = "키워드를 입력하면 해독이 시작됩니다"
	_decoded_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_decoded_lbl.add_theme_font_size_override("font_size", 28)
	_decoded_lbl.add_theme_color_override("font_color", C_MUTED)
	vbox.add_child(_decoded_lbl)

	var confirm_btn := Button.new()
	confirm_btn.text = "이 결과가 평문이다  →"
	confirm_btn.add_theme_font_size_override("font_size", 16)
	confirm_btn.custom_minimum_size = Vector2(240, 42)
	confirm_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	confirm_btn.pressed.connect(_on_confirm_pressed)
	vbox.add_child(confirm_btn)

	return panel


# ─────────────────────────────────────────────────────────────────────
#  로직
# ─────────────────────────────────────────────────────────────────────

func _on_key_changed(new_text: String) -> void:
	_current_key = new_text.to_upper().strip_edges()
	_refresh()


func _refresh() -> void:
	_update_grid()
	_update_decoded()


func _update_grid() -> void:
	if _current_key.is_empty():
		for lbl in _grid_labels:
			var cell : Label = lbl
			cell.text = ""
			var cs := cell.get_theme_stylebox("normal") as StyleBoxFlat
			if cs:
				cs.bg_color = C_CELL_BG
				cs.border_color = C_BORDER
			cell.add_theme_color_override("font_color", C_MUTED)
		return

	# 격자 생성
	var grid := CipherLib._playfair_build_grid(_current_key)
	# 키 글자 셋 (강조 표시용)
	var key_chars : Dictionary = {}
	for ch in _current_key.to_upper():
		var c : String = ch
		if c == "J":
			c = "I"
		key_chars[c] = true

	for idx in 25:
		var cell : Label = _grid_labels[idx]
		var r  := idx / 5
		var col := idx % 5
		var ch : String = grid[r][col]
		cell.text = ch

		var cs := cell.get_theme_stylebox("normal") as StyleBoxFlat
		if cs:
			if key_chars.has(ch):
				cs.bg_color = C_KEY_CELL
				cs.border_color = C_GOLD
			else:
				cs.bg_color = C_CELL_BG
				cs.border_color = C_BORDER
		cell.add_theme_color_override("font_color",
			C_GOLD if key_chars.has(ch) else Color(0.72, 0.78, 0.88))


func _update_decoded() -> void:
	if _current_key.is_empty() or _cipher_text.is_empty():
		_decoded_lbl.text = "키워드를 입력하면 해독이 시작됩니다"
		_decoded_lbl.add_theme_color_override("font_color", C_MUTED)
		return

	var result := CipherLib.playfair_process(_cipher_text, _current_key, false)
	_decoded_lbl.text = result
	_decoded_lbl.add_theme_color_override("font_color", C_GREEN)


func _on_confirm_pressed() -> void:
	var result := get_decoded_text()
	if not result.is_empty():
		emit_signal("decode_confirmed", result)


func get_decoded_text() -> String:
	if _current_key.is_empty():
		return ""
	return CipherLib.playfair_process(_cipher_text, _current_key, false)


# ─────────────────────────────────────────────────────────────────────
#  유틸리티
# ─────────────────────────────────────────────────────────────────────

func _make_style(bg: Color, border: Color, bw: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.border_width_left   = bw
	s.border_width_right  = bw
	s.border_width_top    = bw
	s.border_width_bottom = bw
	s.content_margin_left   = 0
	s.content_margin_right  = 0
	s.content_margin_top    = 0
	s.content_margin_bottom = 0
	return s
