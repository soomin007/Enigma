## SubstitutionDecoder.gd — 단일 치환 암호 해독기 UI
## ChapterView가 동적으로 인스턴스화하여 _cipher_container에 삽입한다.
## 26칸 매핑 테이블로 암호→평문 대응을 입력하고, 실시간으로 해독 결과를 갱신한다.
extends Control

signal decode_confirmed(plain_text: String)

# ── 팔레트 ───────────────────────────────────────────────────────────
const C_BG       := Color(0.07, 0.08, 0.12)
const C_GOLD     := Color(0.93, 0.87, 0.40)
const C_MUTED    := Color(0.50, 0.50, 0.62)
const C_GREEN    := Color(0.38, 0.88, 0.58)
const C_BORDER   := Color(0.18, 0.20, 0.32)
const C_BORDER_G := Color(0.50, 0.44, 0.15)
const C_ACTIVE   := Color(0.22, 0.28, 0.48)   # 암호문에 등장하는 글자
const C_SOLVED   := Color(0.12, 0.28, 0.18)   # 매핑 완료된 글자

# 영어 빈도 순 (참고용 표시)
const ENG_FREQ_ORDER := "ETAOINSHRDLCUMWFGYPBVKJXQZ"

# ── 상태 ──────────────────────────────────────────────────────────
var _cipher_text    : String     = ""
## 암호→평문 매핑. 키: 암호 글자(A-Z), 값: 평문 글자(A-Z) 또는 ""
var _mapping        : Dictionary = {}
## 암호문에 등장하는 글자 집합 (A-Z)
var _cipher_used    : Dictionary = {}   # { "A": count, ... }

# ── UI 노드 레퍼런스 ──────────────────────────────────────────────
var _lbl_cipher    : Label
var _lbl_result    : Label
var _lbl_confidence: Label
var _map_edits       : Array[LineEdit] = []   # 인덱스 0=A, 1=B, ... 25=Z
var _map_cells       : Array[Control] = []    # 각 셀 컨테이너 (highlight용)
var _map_cipher_lbls : Array[Label]   = []    # 셀 상단 암호 글자 라벨 (색상 업데이트용)


func _ready() -> void:
	_build_ui()
	_init_mapping()
	_update_decoder()


## ChapterView에서 챕터 데이터를 넘겨 초기화
func setup(cipher_text: String, _params: Dictionary) -> void:
	_cipher_text = cipher_text.to_upper()
	_init_mapping()
	if is_inside_tree():
		_lbl_cipher.text = _cipher_text
		for edit in _map_edits:
			edit.text = ""
		_update_cell_styles()
		_update_decoder()


# ────────────────────────────────────────────────────────────────────
#  초기화
# ────────────────────────────────────────────────────────────────────

func _init_mapping() -> void:
	_mapping.clear()
	_cipher_used.clear()
	for i in 26:
		_mapping[char(65 + i)] = ""

	if _cipher_text.is_empty():
		return
	for ch in _cipher_text:
		var code := ch.unicode_at(0)
		if code >= 65 and code <= 90:
			_cipher_used[ch] = _cipher_used.get(ch, 0) + 1


# ────────────────────────────────────────────────────────────────────
#  UI 구성
# ────────────────────────────────────────────────────────────────────

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = C_BG
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(bg)

	var root := ScrollContainer.new()
	root.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	root.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.vertical_scroll_mode   = ScrollContainer.SCROLL_MODE_AUTO
	add_child(root)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 0)
	vbox.offset_left  = 24
	vbox.offset_right = -24
	root.add_child(vbox)

	# ── 제목 ──
	var title_lbl := Label.new()
	title_lbl.text = "[ 단일 치환 암호 해독기  ·  SUBSTITUTION CIPHER ]"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 16)
	title_lbl.add_theme_color_override("font_color", C_MUTED)
	vbox.add_child(title_lbl)

	vbox.add_child(_make_gap(8))
	vbox.add_child(_make_sep(C_BORDER_G))
	vbox.add_child(_make_gap(12))

	# ── 암호문 ──
	var cipher_hdr := Label.new()
	cipher_hdr.text = "감청 신호"
	cipher_hdr.add_theme_font_size_override("font_size", 12)
	cipher_hdr.add_theme_color_override("font_color", C_MUTED)
	vbox.add_child(cipher_hdr)

	_lbl_cipher = Label.new()
	_lbl_cipher.text = "─"
	_lbl_cipher.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_cipher.add_theme_font_size_override("font_size", 32)
	_lbl_cipher.add_theme_color_override("font_color", C_GOLD)
	vbox.add_child(_lbl_cipher)

	vbox.add_child(_make_gap(14))
	vbox.add_child(_make_sep(C_BORDER))
	vbox.add_child(_make_gap(10))

	# ── 빈도 분석 + 매핑 테이블 나란히 ──
	var two_col := HBoxContainer.new()
	two_col.add_theme_constant_override("separation", 16)
	vbox.add_child(two_col)

	two_col.add_child(_build_freq_panel())

	# 세로 구분선
	var vline := VSeparator.new()
	var vls := StyleBoxFlat.new()
	vls.bg_color = C_BORDER
	vline.add_theme_stylebox_override("separator", vls)
	two_col.add_child(vline)

	two_col.add_child(_build_mapping_table())

	vbox.add_child(_make_gap(12))
	vbox.add_child(_make_sep(C_BORDER))
	vbox.add_child(_make_gap(10))

	# ── 해독 결과 ──
	var result_hdr := Label.new()
	result_hdr.text = "해독 결과"
	result_hdr.add_theme_font_size_override("font_size", 12)
	result_hdr.add_theme_color_override("font_color", C_MUTED)
	vbox.add_child(result_hdr)

	_lbl_result = Label.new()
	_lbl_result.text = "─"
	_lbl_result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_result.add_theme_font_size_override("font_size", 30)
	_lbl_result.add_theme_color_override("font_color", C_GREEN)
	vbox.add_child(_lbl_result)

	vbox.add_child(_make_gap(8))

	# 확신도
	_lbl_confidence = Label.new()
	_lbl_confidence.text = "매핑 완료: 0 / 0 글자  (0%)"
	_lbl_confidence.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_confidence.add_theme_font_size_override("font_size", 13)
	_lbl_confidence.add_theme_color_override("font_color", C_MUTED)
	vbox.add_child(_lbl_confidence)

	vbox.add_child(_make_gap(14))

	# ── 하단 버튼 ──
	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_END
	btn_row.add_theme_constant_override("separation", 14)
	vbox.add_child(btn_row)

	var hint_btn := Button.new()
	hint_btn.text = "힌트 사용"
	hint_btn.add_theme_font_size_override("font_size", 14)
	hint_btn.custom_minimum_size = Vector2(120, 42)
	hint_btn.add_theme_stylebox_override("normal",  _make_style(Color(0.09, 0.08, 0.05), Color(0.60, 0.45, 0.20), 1, 10))
	hint_btn.add_theme_stylebox_override("hover",   _make_style(Color(0.14, 0.12, 0.06), Color(0.88, 0.65, 0.28), 1, 10))
	hint_btn.add_theme_stylebox_override("pressed", _make_style(Color(0.07, 0.06, 0.03), C_GOLD, 1, 10))
	hint_btn.add_theme_color_override("font_color", Color(0.82, 0.62, 0.28))
	hint_btn.pressed.connect(func(): GameManager.use_hint())
	btn_row.add_child(hint_btn)

	var clear_btn := Button.new()
	clear_btn.text = "초기화"
	clear_btn.add_theme_font_size_override("font_size", 14)
	clear_btn.custom_minimum_size = Vector2(90, 42)
	clear_btn.add_theme_stylebox_override("normal",  _make_style(Color(0.10, 0.08, 0.08), Color(0.38, 0.22, 0.22), 1, 10))
	clear_btn.add_theme_stylebox_override("hover",   _make_style(Color(0.16, 0.10, 0.10), Color(0.65, 0.28, 0.28), 1, 10))
	clear_btn.add_theme_stylebox_override("pressed", _make_style(Color(0.08, 0.06, 0.06), Color(0.80, 0.30, 0.30), 1, 10))
	clear_btn.add_theme_color_override("font_color", Color(0.80, 0.45, 0.45))
	clear_btn.pressed.connect(_on_clear)
	btn_row.add_child(clear_btn)

	var confirm_btn := Button.new()
	confirm_btn.text = "이 내용이 맞습니다  →  보고서 작성"
	confirm_btn.custom_minimum_size = Vector2(320, 42)
	confirm_btn.add_theme_font_size_override("font_size", 16)
	confirm_btn.add_theme_stylebox_override("normal",  _make_style(Color(0.08, 0.10, 0.07), Color(0.50, 0.44, 0.15), 1, 12))
	confirm_btn.add_theme_stylebox_override("hover",   _make_style(Color(0.12, 0.15, 0.09), C_GOLD, 1, 12))
	confirm_btn.add_theme_stylebox_override("pressed", _make_style(Color(0.06, 0.08, 0.05), C_GOLD, 2, 12))
	confirm_btn.add_theme_color_override("font_color", C_GOLD)
	confirm_btn.pressed.connect(_on_confirm)
	btn_row.add_child(confirm_btn)

	vbox.add_child(_make_gap(16))


# ────────────────────────────────────────────────────────────────────
#  빈도 분석 패널
# ────────────────────────────────────────────────────────────────────

func _build_freq_panel() -> Control:
	var panel := VBoxContainer.new()
	panel.custom_minimum_size.x = 220
	panel.add_theme_constant_override("separation", 6)

	var hdr := Label.new()
	hdr.text = "빈도 분석"
	hdr.add_theme_font_size_override("font_size", 13)
	hdr.add_theme_color_override("font_color", C_GOLD)
	panel.add_child(hdr)

	var sub := Label.new()
	sub.text = "영어 기준: E T A O I N S H R D …"
	sub.add_theme_font_size_override("font_size", 10)
	sub.add_theme_color_override("font_color", C_MUTED)
	panel.add_child(sub)

	panel.add_child(_make_gap(4))

	# 빈도 표 (암호문에 등장한 글자만, 높은 빈도 순)
	var freq_panel := PanelContainer.new()
	var fps := StyleBoxFlat.new()
	fps.bg_color = Color(0.055, 0.065, 0.10)
	fps.border_color = C_BORDER
	fps.border_width_left = 1; fps.border_width_right = 1
	fps.border_width_top  = 1; fps.border_width_bottom = 1
	fps.content_margin_left = 8; fps.content_margin_right = 8
	fps.content_margin_top  = 8; fps.content_margin_bottom = 8
	freq_panel.add_theme_stylebox_override("panel", fps)
	panel.add_child(freq_panel)

	var freq_vbox := VBoxContainer.new()
	freq_vbox.name = "FreqVBox"
	freq_vbox.add_theme_constant_override("separation", 4)
	freq_panel.add_child(freq_vbox)

	# 열 헤더
	var hdr_row := HBoxContainer.new()
	hdr_row.add_theme_constant_override("separation", 4)
	freq_vbox.add_child(hdr_row)
	for hdr_text in ["암호", "빈도", "횟수", "→ 영어"]:
		var lbl := Label.new()
		lbl.text = hdr_text
		lbl.add_theme_font_size_override("font_size", 10)
		lbl.add_theme_color_override("font_color", C_MUTED)
		match hdr_text:
			"암호":  lbl.custom_minimum_size.x = 24
			"빈도":  lbl.custom_minimum_size.x = 80; lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			"횟수":  lbl.custom_minimum_size.x = 30
			"→ 영어": lbl.custom_minimum_size.x = 50
		hdr_row.add_child(lbl)

	# 빈도 행은 _update_freq_display()에서 동적 생성
	return panel


# ────────────────────────────────────────────────────────────────────
#  매핑 테이블
# ────────────────────────────────────────────────────────────────────

func _build_mapping_table() -> Control:
	var panel := VBoxContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_constant_override("separation", 8)

	var hdr := Label.new()
	hdr.text = "치환 매핑  ( 암호 글자 → 평문 글자 입력 )"
	hdr.add_theme_font_size_override("font_size", 13)
	hdr.add_theme_color_override("font_color", C_GOLD)
	panel.add_child(hdr)

	var sub := Label.new()
	sub.text = "색상 셀: 암호문에 등장  /  녹색: 매핑 완료"
	sub.add_theme_font_size_override("font_size", 10)
	sub.add_theme_color_override("font_color", C_MUTED)
	panel.add_child(sub)

	# 13열 × 2행 그리드
	for row_start in [0, 13]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		panel.add_child(row)

		for i in 13:
			var idx: int = row_start + i
			row.add_child(_build_map_cell(idx))

	return panel


func _build_map_cell(cipher_idx: int) -> Control:
	var cipher_ch := char(65 + cipher_idx)

	# 셀 컨테이너
	var cell := PanelContainer.new()
	cell.custom_minimum_size = Vector2(38, 60)
	cell.add_theme_stylebox_override("panel", _make_style(C_BG, C_BORDER, 1, 0))
	_map_cells.append(cell)

	var cell_vbox := VBoxContainer.new()
	cell_vbox.add_theme_constant_override("separation", 2)
	cell.add_child(cell_vbox)

	# 암호 글자 라벨
	var cipher_lbl := Label.new()
	cipher_lbl.text = cipher_ch
	cipher_lbl.custom_minimum_size.x = 36
	cipher_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cipher_lbl.add_theme_font_size_override("font_size", 14)
	cipher_lbl.add_theme_color_override("font_color", C_MUTED)  # setup() 후 _update_cell_styles()로 갱신
	cell_vbox.add_child(cipher_lbl)
	_map_cipher_lbls.append(cipher_lbl)

	# 입력칸
	var edit := LineEdit.new()
	edit.max_length = 1
	edit.custom_minimum_size = Vector2(36, 28)
	edit.add_theme_font_size_override("font_size", 15)
	edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	edit.editable = false          # setup() 후 _update_cell_styles()에서 활성화
	edit.modulate = Color(1, 1, 1, 0.30)

	var edit_style := StyleBoxFlat.new()
	edit_style.bg_color = Color(0.08, 0.09, 0.14)
	edit_style.border_color = C_BORDER
	edit_style.border_width_left = 1; edit_style.border_width_right  = 1
	edit_style.border_width_top  = 1; edit_style.border_width_bottom = 1
	edit_style.content_margin_left = 2; edit_style.content_margin_right = 2
	edit_style.content_margin_top  = 2; edit_style.content_margin_bottom = 2
	edit.add_theme_stylebox_override("normal", edit_style)
	edit.add_theme_stylebox_override("read_only", edit_style)

	var captured_idx := cipher_idx
	edit.text_changed.connect(func(new_text: String): _on_map_changed(captured_idx, new_text))
	cell_vbox.add_child(edit)
	_map_edits.append(edit)

	return cell


# ────────────────────────────────────────────────────────────────────
#  로직
# ────────────────────────────────────────────────────────────────────

func _on_map_changed(cipher_idx: int, new_text: String) -> void:
	var ch := ""
	if not new_text.is_empty():
		var code := new_text.to_upper().unicode_at(0)
		if code >= 65 and code <= 90:
			ch = char(code)
		# 알파벳이 아니면 무시하고 지움
		_map_edits[cipher_idx].text = ch
		_map_edits[cipher_idx].caret_column = ch.length()

	var cipher_ch := char(65 + cipher_idx)

	# 같은 평문이 이미 다른 암호 글자에 매핑되어 있으면 그 매핑 제거
	if ch != "":
		for i in 26:
			if i != cipher_idx and _mapping.get(char(65 + i), "") == ch:
				_mapping[char(65 + i)] = ""
				_map_edits[i].text = ""

	_mapping[cipher_ch] = ch
	_update_cell_styles()
	_update_decoder()


func _update_cell_styles() -> void:
	for i in 26:
		if i >= _map_cells.size():
			break
		var cipher_ch   := char(65 + i)
		var cell        : Control = _map_cells[i]
		var has_mapping: bool = _mapping.get(cipher_ch, "") != ""
		var in_cipher:   bool = _cipher_used.has(cipher_ch)

		# 편집 가능 여부 갱신
		if i < _map_edits.size():
			_map_edits[i].editable = in_cipher
			_map_edits[i].modulate = Color(1, 1, 1, 1.0) if in_cipher else Color(1, 1, 1, 0.28)

		# 암호 글자 라벨 색상 갱신
		if i < _map_cipher_lbls.size():
			_map_cipher_lbls[i].add_theme_color_override("font_color",
				C_GREEN if has_mapping else (C_GOLD if in_cipher else C_MUTED))

		# 셀 배경·테두리 색상
		var bg_color : Color
		if has_mapping:
			bg_color = C_SOLVED
		elif in_cipher:
			bg_color = C_ACTIVE
		else:
			bg_color = C_BG

		var border_color : Color
		if has_mapping:
			border_color = C_GREEN.darkened(0.3)
		elif in_cipher:
			border_color = Color(0.30, 0.40, 0.65)
		else:
			border_color = C_BORDER

		cell.add_theme_stylebox_override("panel", _make_style(bg_color, border_color, 1, 0))


func _update_decoder() -> void:
	if _cipher_text.is_empty():
		return

	# 해독 결과 계산 (미매핑 글자는 _ 로 표시해 위치 파악 가능하게)
	var display_result := ""
	for i in _cipher_text.length():
		var ch: String = _cipher_text[i]
		var code: int = ch.unicode_at(0)
		if code >= 65 and code <= 90:
			var mapped: String = _mapping.get(ch, "")
			display_result += "_" if mapped == "" else mapped
		else:
			display_result += ch
	_lbl_result.text = display_result

	# 확신도 계산
	var total_types   := _cipher_used.size()
	var mapped_count  := 0
	for cipher_ch in _cipher_used:
		if _mapping.get(cipher_ch, "") != "":
			mapped_count += 1
	var pct := int(float(mapped_count) / float(total_types) * 100.0) if total_types > 0 else 0
	_lbl_confidence.text = "매핑 완료: %d / %d 글자  (%d%%)" % [mapped_count, total_types, pct]

	if pct >= 100:
		_lbl_confidence.add_theme_color_override("font_color", C_GREEN)
	elif pct >= 50:
		_lbl_confidence.add_theme_color_override("font_color", C_GOLD)
	else:
		_lbl_confidence.add_theme_color_override("font_color", C_MUTED)

	# 빈도 분석 갱신
	_update_freq_display()


func _update_freq_display() -> void:
	# FreqVBox 찾기 (멤버 참조 대신 이름으로)
	var freq_vbox : VBoxContainer = _find_named_child(self, "FreqVBox") as VBoxContainer
	if freq_vbox == null:
		return

	# 헤더(첫 번째 자식)는 남기고 나머지 제거
	var children := freq_vbox.get_children()
	for i in range(1, children.size()):
		children[i].queue_free()

	if _cipher_used.is_empty():
		return

	# 빈도 정렬
	var freq_pairs : Array = CipherLib.frequency_sorted(_cipher_text)
	var max_count  : int   = freq_pairs[0]["count"] if freq_pairs.size() > 0 else 1
	var eng_rank   := 0

	for pair in freq_pairs:
		var cipher_ch : String = pair["char"]
		var count     : int    = pair["count"]
		var plain_ch  : String = _mapping.get(cipher_ch, "")

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		freq_vbox.add_child(row)

		# 암호 글자
		var c_lbl := Label.new()
		c_lbl.text = cipher_ch
		c_lbl.custom_minimum_size.x = 24
		c_lbl.add_theme_font_size_override("font_size", 13)
		c_lbl.add_theme_color_override("font_color",
			C_GREEN if plain_ch != "" else C_GOLD)
		row.add_child(c_lbl)

		# 빈도 바
		var bar_bg := PanelContainer.new()
		bar_bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar_bg.custom_minimum_size.y = 14
		var bgs := StyleBoxFlat.new()
		bgs.bg_color = Color(0.10, 0.10, 0.15)
		bar_bg.add_theme_stylebox_override("panel", bgs)
		row.add_child(bar_bg)

		var bar_fill := Control.new()
		var fill_ratio := float(count) / float(max_count)
		bar_fill.size_flags_horizontal = Control.SIZE_FILL
		bar_fill.custom_minimum_size.x = 0
		bar_fill.set_anchors_and_offsets_preset(PRESET_LEFT_WIDE)
		var fill_color := C_GREEN.lerp(C_GOLD, 1.0 - fill_ratio)
		# 바를 ColorRect으로 직접 넣기
		var fill_rect := ColorRect.new()
		fill_rect.color = fill_color
		fill_rect.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
		# 비율로 right offset 조절
		fill_rect.anchor_right  = fill_ratio
		fill_rect.anchor_bottom = 1.0
		fill_rect.offset_right  = 0
		fill_rect.offset_bottom = 0
		bar_bg.add_child(fill_rect)

		# 횟수
		var n_lbl := Label.new()
		n_lbl.text = str(count)
		n_lbl.custom_minimum_size.x = 30
		n_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		n_lbl.add_theme_font_size_override("font_size", 12)
		n_lbl.add_theme_color_override("font_color", C_MUTED)
		row.add_child(n_lbl)

		# 영어 빈도 대응
		var eng_ch := ENG_FREQ_ORDER[eng_rank] if eng_rank < ENG_FREQ_ORDER.length() else "?"
		var eng_lbl := Label.new()
		eng_lbl.text = "→ %s" % eng_ch
		eng_lbl.custom_minimum_size.x = 50
		eng_lbl.add_theme_font_size_override("font_size", 11)
		eng_lbl.add_theme_color_override("font_color", Color(0.45, 0.45, 0.58))
		row.add_child(eng_lbl)
		eng_rank += 1


# ────────────────────────────────────────────────────────────────────
#  버튼 핸들러
# ────────────────────────────────────────────────────────────────────

func _on_clear() -> void:
	for i in 26:
		_mapping[char(65 + i)] = ""
		if i < _map_edits.size():
			_map_edits[i].text = ""
	_update_cell_styles()
	_update_decoder()


func _on_confirm() -> void:
	# 암호문에 등장한 모든 글자가 매핑되어 있는지 확인
	for cipher_ch in _cipher_used:
		if _mapping.get(cipher_ch, "") == "":
			GameManager.use_hint_with_text(
				"아직 매핑되지 않은 글자가 있습니다.\n모든 암호 글자(강조 표시)에 평문 글자를 입력한 후 제출하십시오."
			)
			return
	var plain := CipherLib.substitution_decode(_cipher_text, _mapping)
	emit_signal("decode_confirmed", plain)


# ────────────────────────────────────────────────────────────────────
#  유틸리티
# ────────────────────────────────────────────────────────────────────

func _find_named_child(node: Node, target_name: String) -> Node:
	if node.name == target_name:
		return node
	for child in node.get_children():
		var found := _find_named_child(child, target_name)
		if found != null:
			return found
	return null


func _make_style(bg: Color, border: Color, bw: int, pad: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.border_width_left   = bw; s.border_width_right  = bw
	s.border_width_top    = bw; s.border_width_bottom = bw
	s.content_margin_left   = pad; s.content_margin_right  = pad
	s.content_margin_top    = pad; s.content_margin_bottom = pad
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
