## EnigmaDecoder.gd — 에니그마 머신 해독기 UI
## ChapterView가 동적으로 인스턴스화하여 _cipher_container에 삽입한다.
## 로터 3개 + 반사판 + 플러그보드를 직접 조작하여 실시간 복호화를 확인한다.
extends Control

signal decode_confirmed(plain_text: String)

# ── 팔레트 ───────────────────────────────────────────────────────────
const C_BG       := Color(0.07, 0.08, 0.12)
const C_GOLD     := Color(0.93, 0.87, 0.40)
const C_MUTED    := Color(0.50, 0.50, 0.62)
const C_GREEN    := Color(0.38, 0.88, 0.58)
const C_RED      := Color(0.88, 0.38, 0.38)
const C_BORDER   := Color(0.18, 0.20, 0.32)
const C_BORDER_G := Color(0.50, 0.44, 0.15)
const C_PANEL    := Color(0.055, 0.065, 0.10)

const ROTOR_NAMES := ["I", "II", "III", "IV", "V"]
const REFLECTOR_NAMES := ["A", "B"]

# ── 상태 ──────────────────────────────────────────────────────────
var _cipher_text : String = ""

# 로터 설정: 각 인덱스는 슬롯 [왼, 가운데, 오른]
var _rotor_types     : Array = ["I", "II", "III"]   # 선택된 로터 이름
var _rotor_positions : Array = [0, 0, 0]             # 0~25 (A~Z)
var _reflector       : String = "B"

# 플러그보드: {"A": "B", "B": "A", ...} — _plugboard_pairs 는 입력 쌍 배열
var _plugboard       : Dictionary = {}
var _plugboard_pairs : Array = []   # [{"left": "A", "right": "B"}, ...]

# ── UI 노드 레퍼런스 ──────────────────────────────────────────────
var _lbl_cipher       : Label
var _lbl_result       : Label
var _lbl_result_color : Color = C_GREEN

# 로터 위젯 배열 (슬롯 0~2)
var _rotor_type_opts  : Array = []   # OptionButton x3
var _rotor_pos_opts   : Array = []   # OptionButton x3 (A~Z)

var _reflector_opt    : OptionButton

# 플러그보드 행 목록
var _plug_vbox        : VBoxContainer
var _plug_rows        : Array = []   # [HBoxContainer, ...]
var _plug_edits_left  : Array = []   # LineEdit x10
var _plug_edits_right : Array = []   # LineEdit x10

var _confirm_btn      : Button
var _hint_btn         : Button


func _ready() -> void:
	_build_ui()
	_update_decoder()


## ChapterView에서 챕터 데이터를 넘겨 초기화.
## cipher_params는 정답 검증용이므로 절대 초기 UI에 로드하지 않는다.
## 초기 상태는 항상 오답 설정 — 플레이어가 단서를 통해 직접 맞춰야 한다.
func setup(cipher_text: String, _params: Dictionary) -> void:
	_cipher_text = cipher_text.to_upper()   # 공백 유지 — enigma_process가 공백을 그대로 통과시킴
	_rotor_types     = ["I", "II", "III"]
	_rotor_positions = [3, 3, 3]   # D, D, D — 초기 오답
	_reflector       = "A"          # 오답 (단서에서 찾아야 함)
	_plugboard       = {}
	_plugboard_pairs.clear()

	if is_inside_tree():
		_sync_widgets_from_state()
		_update_decoder()


# ────────────────────────────────────────────────────────────────────
#  UI 구성
# ────────────────────────────────────────────────────────────────────

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = C_BG
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(bg)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode   = ScrollContainer.SCROLL_MODE_AUTO
	add_child(scroll)

	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 0)
	root.offset_left  =  24
	root.offset_right = -24
	scroll.add_child(root)

	# ── 제목 ──
	var title_lbl := Label.new()
	title_lbl.text = "[ 에니그마 머신  ·  ENIGMA MACHINE ]"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 16)
	title_lbl.add_theme_color_override("font_color", C_MUTED)
	root.add_child(title_lbl)

	root.add_child(_make_gap(8))
	root.add_child(_make_sep(C_BORDER_G))
	root.add_child(_make_gap(14))

	# ── 암호문 ──
	var cipher_hdr := Label.new()
	cipher_hdr.text = "감청 신호"
	cipher_hdr.add_theme_font_size_override("font_size", 12)
	cipher_hdr.add_theme_color_override("font_color", C_MUTED)
	root.add_child(cipher_hdr)

	_lbl_cipher = Label.new()
	_lbl_cipher.text = "─"
	_lbl_cipher.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_cipher.add_theme_font_size_override("font_size", 32)
	_lbl_cipher.add_theme_color_override("font_color", C_GOLD)
	_lbl_cipher.autowrap_mode = TextServer.AUTOWRAP_WORD
	root.add_child(_lbl_cipher)

	root.add_child(_make_gap(18))
	root.add_child(_make_sep(C_BORDER))
	root.add_child(_make_gap(14))

	# ──────────────────────────────────────────────
	#  로터 설정 패널
	# ──────────────────────────────────────────────
	var rotor_hdr := Label.new()
	rotor_hdr.text = "■ 로터 설정  (왼쪽 → 가운데 → 오른쪽)"
	rotor_hdr.add_theme_font_size_override("font_size", 14)
	rotor_hdr.add_theme_color_override("font_color", C_GOLD)
	root.add_child(rotor_hdr)

	root.add_child(_make_gap(8))

	var rotor_panel := _make_inset_panel()
	root.add_child(rotor_panel)

	var rotor_inner := VBoxContainer.new()
	rotor_inner.add_theme_constant_override("separation", 10)
	rotor_panel.add_child(rotor_inner)

	var slot_labels := ["왼쪽 로터", "가운데 로터", "오른쪽 로터"]
	for i in 3:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		rotor_inner.add_child(row)

		var slot_lbl := Label.new()
		slot_lbl.text = slot_labels[i]
		slot_lbl.custom_minimum_size.x = 100
		slot_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		slot_lbl.add_theme_font_size_override("font_size", 14)
		slot_lbl.add_theme_color_override("font_color", C_MUTED)
		row.add_child(slot_lbl)

		# 로터 종류 선택
		var type_lbl := Label.new()
		type_lbl.text = "종류:"
		type_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		type_lbl.add_theme_font_size_override("font_size", 13)
		type_lbl.add_theme_color_override("font_color", C_MUTED)
		row.add_child(type_lbl)

		var type_opt := OptionButton.new()
		type_opt.custom_minimum_size = Vector2(72, 36)
		type_opt.add_theme_font_size_override("font_size", 15)
		for rname in ROTOR_NAMES:
			type_opt.add_item(rname)
		type_opt.select(ROTOR_NAMES.find(_rotor_types[i]))
		var slot_i := i
		type_opt.item_selected.connect(func(idx: int): _on_rotor_type_changed(slot_i, idx))
		_rotor_type_opts.append(type_opt)
		row.add_child(type_opt)

		# 초기 위치 (A~Z)
		var pos_lbl := Label.new()
		pos_lbl.text = "초기 위치:"
		pos_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		pos_lbl.add_theme_font_size_override("font_size", 13)
		pos_lbl.add_theme_color_override("font_color", C_MUTED)
		row.add_child(pos_lbl)

		var pos_opt := OptionButton.new()
		pos_opt.custom_minimum_size = Vector2(72, 36)
		pos_opt.add_theme_font_size_override("font_size", 15)
		for pi in 26:
			pos_opt.add_item(char(65 + pi))
		pos_opt.select(_rotor_positions[i])
		pos_opt.item_selected.connect(func(idx: int): _on_rotor_pos_changed(slot_i, idx))
		_rotor_pos_opts.append(pos_opt)
		row.add_child(pos_opt)

	root.add_child(_make_gap(16))

	# ──────────────────────────────────────────────
	#  반사판 설정
	# ──────────────────────────────────────────────
	var ref_row := HBoxContainer.new()
	ref_row.add_theme_constant_override("separation", 14)
	root.add_child(ref_row)

	var ref_lbl := Label.new()
	ref_lbl.text = "■ 반사판 (Reflector)"
	ref_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ref_lbl.custom_minimum_size.x = 200
	ref_lbl.add_theme_font_size_override("font_size", 14)
	ref_lbl.add_theme_color_override("font_color", C_GOLD)
	ref_row.add_child(ref_lbl)

	_reflector_opt = OptionButton.new()
	_reflector_opt.custom_minimum_size = Vector2(80, 36)
	_reflector_opt.add_theme_font_size_override("font_size", 15)
	for rname in REFLECTOR_NAMES:
		_reflector_opt.add_item(rname)
	_reflector_opt.select(REFLECTOR_NAMES.find(_reflector))
	_reflector_opt.item_selected.connect(_on_reflector_changed)
	ref_row.add_child(_reflector_opt)

	root.add_child(_make_gap(16))
	root.add_child(_make_sep(C_BORDER))
	root.add_child(_make_gap(14))

	# ──────────────────────────────────────────────
	#  플러그보드 설정
	# ──────────────────────────────────────────────
	var plug_hdr_row := HBoxContainer.new()
	plug_hdr_row.add_theme_constant_override("separation", 12)
	root.add_child(plug_hdr_row)

	var plug_hdr := Label.new()
	plug_hdr.text = "■ 플러그보드  (Plugboard)  — 알파벳 교환 쌍 최대 10개"
	plug_hdr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	plug_hdr.add_theme_font_size_override("font_size", 14)
	plug_hdr.add_theme_color_override("font_color", C_GOLD)
	plug_hdr_row.add_child(plug_hdr)

	var plug_note := Label.new()
	plug_note.text = "(단서에서 교환 쌍이 확인되지 않으면 비워두십시오)"
	plug_note.add_theme_font_size_override("font_size", 12)
	plug_note.add_theme_color_override("font_color", C_MUTED)
	root.add_child(plug_note)

	root.add_child(_make_gap(8))

	var plug_panel := _make_inset_panel()
	root.add_child(plug_panel)

	_plug_vbox = VBoxContainer.new()
	_plug_vbox.add_theme_constant_override("separation", 6)
	plug_panel.add_child(_plug_vbox)

	_build_plug_rows()

	root.add_child(_make_gap(16))
	root.add_child(_make_sep(C_BORDER))
	root.add_child(_make_gap(14))

	# ──────────────────────────────────────────────
	#  해독 결과
	# ──────────────────────────────────────────────
	var result_hdr := Label.new()
	result_hdr.text = "해독 결과"
	result_hdr.add_theme_font_size_override("font_size", 12)
	result_hdr.add_theme_color_override("font_color", C_MUTED)
	root.add_child(result_hdr)

	_lbl_result = Label.new()
	_lbl_result.text = "─"
	_lbl_result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_result.add_theme_font_size_override("font_size", 32)
	_lbl_result.add_theme_color_override("font_color", C_GREEN)
	_lbl_result.autowrap_mode = TextServer.AUTOWRAP_WORD
	root.add_child(_lbl_result)

	root.add_child(_make_gap(18))

	# ── 하단 버튼 행 ──
	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 14)
	btn_row.alignment = BoxContainer.ALIGNMENT_END
	root.add_child(btn_row)

	_hint_btn = Button.new()
	_hint_btn.text = "설정 힌트"
	_hint_btn.add_theme_font_size_override("font_size", 14)
	_hint_btn.custom_minimum_size = Vector2(120, 42)
	_hint_btn.add_theme_stylebox_override("normal",  _make_style(Color(0.09, 0.08, 0.05), Color(0.60, 0.45, 0.20), 1, 10))
	_hint_btn.add_theme_stylebox_override("hover",   _make_style(Color(0.14, 0.12, 0.06), Color(0.88, 0.65, 0.28), 1, 10))
	_hint_btn.add_theme_stylebox_override("pressed", _make_style(Color(0.07, 0.06, 0.03), C_GOLD, 1, 10))
	_hint_btn.add_theme_color_override("font_color", Color(0.82, 0.62, 0.28))
	_hint_btn.pressed.connect(_on_hint_pressed)
	btn_row.add_child(_hint_btn)

	_confirm_btn = Button.new()
	_confirm_btn.text = "이 내용이 맞습니다  →  보고서 작성"
	_confirm_btn.custom_minimum_size = Vector2(320, 42)
	_confirm_btn.add_theme_font_size_override("font_size", 16)
	_confirm_btn.add_theme_stylebox_override("normal",  _make_style(Color(0.08, 0.10, 0.07), Color(0.50, 0.44, 0.15), 1, 12))
	_confirm_btn.add_theme_stylebox_override("hover",   _make_style(Color(0.12, 0.15, 0.09), C_GOLD, 1, 12))
	_confirm_btn.add_theme_stylebox_override("pressed", _make_style(Color(0.06, 0.08, 0.05), C_GOLD, 2, 12))
	_confirm_btn.add_theme_color_override("font_color", C_GOLD)
	_confirm_btn.pressed.connect(_on_confirm)
	btn_row.add_child(_confirm_btn)

	root.add_child(_make_gap(24))


func _build_plug_rows() -> void:
	for row in _plug_rows:
		if is_instance_valid(row):
			row.queue_free()
	_plug_rows.clear()
	_plug_edits_left.clear()
	_plug_edits_right.clear()

	for i in 10:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		_plug_vbox.add_child(row)
		_plug_rows.append(row)

		var num_lbl := Label.new()
		num_lbl.text = "%2d." % (i + 1)
		num_lbl.custom_minimum_size.x = 28
		num_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		num_lbl.add_theme_font_size_override("font_size", 13)
		num_lbl.add_theme_color_override("font_color", C_MUTED)
		row.add_child(num_lbl)

		var left_edit := _make_plug_edit()
		row.add_child(left_edit)
		_plug_edits_left.append(left_edit)

		var arrow_lbl := Label.new()
		arrow_lbl.text = "↔"
		arrow_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		arrow_lbl.add_theme_font_size_override("font_size", 16)
		arrow_lbl.add_theme_color_override("font_color", C_MUTED)
		row.add_child(arrow_lbl)

		var right_edit := _make_plug_edit()
		row.add_child(right_edit)
		_plug_edits_right.append(right_edit)

		# 양쪽 변경 시 플러그보드 재계산
		var row_i := i
		left_edit.text_changed.connect(func(_t: String): _on_plug_changed(row_i))
		right_edit.text_changed.connect(func(_t: String): _on_plug_changed(row_i))

		var clear_btn := Button.new()
		clear_btn.text = "×"
		clear_btn.custom_minimum_size = Vector2(32, 32)
		clear_btn.add_theme_stylebox_override("normal",  _make_style(Color(0.10, 0.06, 0.06), Color(0.40, 0.20, 0.20), 1, 4))
		clear_btn.add_theme_stylebox_override("hover",   _make_style(Color(0.18, 0.08, 0.08), C_RED, 1, 4))
		clear_btn.add_theme_color_override("font_color", C_RED)
		clear_btn.pressed.connect(func(): _clear_plug_row(row_i))
		row.add_child(clear_btn)


func _make_plug_edit() -> LineEdit:
	var edit := LineEdit.new()
	edit.custom_minimum_size = Vector2(48, 34)
	edit.max_length = 1
	edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	edit.add_theme_font_size_override("font_size", 18)
	edit.placeholder_text = "─"
	return edit


# ────────────────────────────────────────────────────────────────────
#  상태 ↔ 위젯 동기화
# ────────────────────────────────────────────────────────────────────

func _sync_widgets_from_state() -> void:
	for i in 3:
		_rotor_type_opts[i].select(ROTOR_NAMES.find(_rotor_types[i]))
		_rotor_pos_opts[i].select(_rotor_positions[i])
	_reflector_opt.select(REFLECTOR_NAMES.find(_reflector))


# ────────────────────────────────────────────────────────────────────
#  이벤트 핸들러
# ────────────────────────────────────────────────────────────────────

func _on_rotor_type_changed(slot: int, idx: int) -> void:
	_rotor_types[slot] = ROTOR_NAMES[idx]
	_update_decoder()


func _on_rotor_pos_changed(slot: int, idx: int) -> void:
	_rotor_positions[slot] = idx
	_update_decoder()


func _on_reflector_changed(idx: int) -> void:
	_reflector = REFLECTOR_NAMES[idx]
	_update_decoder()


func _on_plug_changed(row_i: int) -> void:
	# 알파벳 1글자만 허용, 대문자 자동 변환
	var l_edit: LineEdit = _plug_edits_left[row_i]
	var r_edit: LineEdit = _plug_edits_right[row_i]

	var lv := l_edit.text.to_upper()
	if lv.length() > 0 and (lv.unicode_at(0) < 65 or lv.unicode_at(0) > 90):
		lv = ""
	if l_edit.text != lv:
		l_edit.text = lv
		l_edit.caret_column = lv.length()

	var rv := r_edit.text.to_upper()
	if rv.length() > 0 and (rv.unicode_at(0) < 65 or rv.unicode_at(0) > 90):
		rv = ""
	if r_edit.text != rv:
		r_edit.text = rv
		r_edit.caret_column = rv.length()

	_rebuild_plugboard()
	_update_decoder()


func _clear_plug_row(row_i: int) -> void:
	var l_edit: LineEdit = _plug_edits_left[row_i]
	var r_edit: LineEdit = _plug_edits_right[row_i]
	l_edit.text = ""
	r_edit.text = ""
	_rebuild_plugboard()
	_update_decoder()


func _rebuild_plugboard() -> void:
	_plugboard.clear()
	var used : Array = []

	for i in 10:
		var l_edit: LineEdit = _plug_edits_left[i]
		var r_edit: LineEdit = _plug_edits_right[i]
		var lv := l_edit.text.to_upper()
		var rv := r_edit.text.to_upper()

		if lv.length() != 1 or rv.length() != 1:
			continue
		if lv == rv:
			continue
		if used.has(lv) or used.has(rv):
			continue

		_plugboard[lv] = rv
		_plugboard[rv] = lv
		used.append(lv)
		used.append(rv)


# ────────────────────────────────────────────────────────────────────
#  해독 갱신
# ────────────────────────────────────────────────────────────────────

func _update_decoder() -> void:
	if _lbl_cipher == null:
		return

	# 공백 5자 간격으로 표시
	var display_cipher := ""
	var alpha_only := _cipher_text.replace(" ", "")
	for i in alpha_only.length():
		if i > 0 and i % 5 == 0:
			display_cipher += " "
		display_cipher += alpha_only[i]
	_lbl_cipher.text = display_cipher

	if _cipher_text.is_empty():
		_lbl_result.text = "─"
		return

	var plain := CipherLib.enigma_process(
		_cipher_text,
		_rotor_types,
		_rotor_positions,
		_reflector,
		_plugboard
	)

	# 암호문의 공백이 enigma_process를 통해 원문 단어 경계로 그대로 보존됨
	_lbl_result.text = plain
	_lbl_result.add_theme_color_override("font_color", C_GREEN)


func _on_hint_pressed() -> void:
	var hint_text := (
		"■ 에니그마 설정 힌트\n\n" +
		"단서 보드의 문서와 낙서를 자세히 살펴보십시오.\n\n" +
		"로터 번호, 반사판 유형, 초기 위치가\n" +
		"각기 다른 형태로 기록되어 있습니다.\n\n" +
		"에니그마는 대칭 암호입니다 —\n" +
		"설정이 맞으면 암호문을 다시 입력했을 때 원문이 나옵니다."
	)
	GameManager.use_hint_with_text(hint_text)


func _on_confirm() -> void:
	var plain := CipherLib.enigma_process(
		_cipher_text,
		_rotor_types,
		_rotor_positions,
		_reflector,
		_plugboard
	)
	emit_signal("decode_confirmed", plain)


# ── 공통 헬퍼 ─────────────────────────────────────────────────────────

func _make_inset_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	var s := StyleBoxFlat.new()
	s.bg_color = C_PANEL
	s.border_color = C_BORDER
	s.border_width_left   = 1
	s.border_width_right  = 1
	s.border_width_top    = 1
	s.border_width_bottom = 1
	s.content_margin_left   = 16
	s.content_margin_right  = 16
	s.content_margin_top    = 14
	s.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", s)
	return panel


func _make_style(bg: Color, border: Color, bw: int, pad: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.border_width_left   = bw
	s.border_width_right  = bw
	s.border_width_top    = bw
	s.border_width_bottom = bw
	s.content_margin_left   = pad
	s.content_margin_right  = pad
	s.content_margin_top    = pad
	s.content_margin_bottom = pad
	return s


func _make_sep(color: Color) -> HSeparator:
	var sep := HSeparator.new()
	var s := StyleBoxFlat.new()
	s.bg_color = color
	sep.add_theme_stylebox_override("separator", s)
	return sep


func _make_gap(height: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size.y = height
	return c
