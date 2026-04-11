## VigenereDecoder.gd — 비즈네르 암호 해독기 UI
## ChapterView가 동적으로 인스턴스화하여 _cipher_container에 삽입한다.
## 키워드 입력 시 실시간으로 평문을 갱신하고, 색상 하이라이트로 키·암호 대응을 시각화한다.
extends Control

signal decode_confirmed(plain_text: String)

# ── 팔레트 ───────────────────────────────────────────────────────────
const C_BG     := Color(0.07, 0.08, 0.12)
const C_GOLD   := Color(0.93, 0.87, 0.40)
const C_MUTED  := Color(0.50, 0.50, 0.62)
const C_GREEN  := Color(0.38, 0.88, 0.58)
const C_BORDER := Color(0.18, 0.20, 0.32)
const C_BORDER_G := Color(0.50, 0.44, 0.15)

# 키 위치별 색상 (최대 8개 순환)
const KEY_COLORS: Array = [
	Color(0.93, 0.72, 0.28),   # 황금
	Color(0.28, 0.82, 0.88),   # 청록
	Color(0.52, 0.88, 0.38),   # 연녹
	Color(0.88, 0.42, 0.72),   # 자홍
	Color(0.55, 0.72, 0.95),   # 하늘
	Color(0.95, 0.55, 0.38),   # 주황
	Color(0.72, 0.55, 0.95),   # 보라
	Color(0.88, 0.88, 0.42),   # 레몬
]

# ── 상태 ──────────────────────────────────────────────────────────
var _cipher_text : String = ""
var _key         : String = ""

# ── UI 노드 레퍼런스 ──────────────────────────────────────────────
var _lbl_cipher    : Label
var _lbl_result    : Label
var _key_edit      : LineEdit
var _lbl_key_len   : Label           # 키 길이 표시 라벨
var _breakdown_row : HBoxContainer   # 키 대응 시각화 행
var _hint_btn      : Button
var _confirm_btn   : Button


func _ready() -> void:
	_build_ui()
	_update_decoder()


## ChapterView에서 챕터 데이터를 넘겨 초기화
func setup(cipher_text: String, _params: Dictionary) -> void:
	_cipher_text = cipher_text.to_upper()
	_key         = ""
	if is_inside_tree():
		_key_edit.text = ""
		_lbl_cipher.text = _cipher_text
		_update_decoder()


# ────────────────────────────────────────────────────────────────────
#  UI 구성
# ────────────────────────────────────────────────────────────────────

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = C_BG
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(bg)

	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 0)
	root.offset_left   =  24
	root.offset_top    =  16
	root.offset_right  = -24
	root.offset_bottom = -16
	add_child(root)

	# ── 제목 ──
	var title_lbl := Label.new()
	title_lbl.text = "[ 비즈네르 암호 해독기  ·  VIGENÈRE CIPHER ]"
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
	_lbl_cipher.add_theme_font_size_override("font_size", 38)
	_lbl_cipher.add_theme_color_override("font_color", C_GOLD)
	root.add_child(_lbl_cipher)

	root.add_child(_make_gap(16))

	# ── 키워드 입력 ──
	var key_row := HBoxContainer.new()
	key_row.add_theme_constant_override("separation", 12)
	root.add_child(key_row)

	var key_lbl := Label.new()
	key_lbl.text = "키워드 입력"
	key_lbl.custom_minimum_size.x = 96
	key_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	key_lbl.add_theme_font_size_override("font_size", 15)
	key_lbl.add_theme_color_override("font_color", C_MUTED)
	key_row.add_child(key_lbl)

	_key_edit = LineEdit.new()
	_key_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_key_edit.custom_minimum_size.y = 40
	_key_edit.placeholder_text = "알파벳 키워드를 입력하십시오  (예: LEMON)"
	_key_edit.add_theme_font_size_override("font_size", 18)
	_key_edit.text_changed.connect(_on_key_changed)
	key_row.add_child(_key_edit)

	_lbl_key_len = Label.new()
	_lbl_key_len.text = "길이: ─"
	_lbl_key_len.custom_minimum_size.x = 72
	_lbl_key_len.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_lbl_key_len.add_theme_font_size_override("font_size", 13)
	_lbl_key_len.add_theme_color_override("font_color", Color(0.42, 0.72, 0.42))
	key_row.add_child(_lbl_key_len)

	root.add_child(_make_gap(14))
	root.add_child(_make_sep(C_BORDER))
	root.add_child(_make_gap(10))

	# ── 키 대응 시각화 ──
	var breakdown_hdr := Label.new()
	breakdown_hdr.text = "키 대응 시각화  (키 위치별 색상 구분)"
	breakdown_hdr.add_theme_font_size_override("font_size", 12)
	breakdown_hdr.add_theme_color_override("font_color", C_MUTED)
	root.add_child(breakdown_hdr)

	root.add_child(_make_gap(4))

	# 3행: 키 글자 / 암호 글자 / 평문 글자
	var breakdown_panel := PanelContainer.new()
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.055, 0.065, 0.10)
	panel_style.border_color = C_BORDER
	panel_style.border_width_left   = 1
	panel_style.border_width_right  = 1
	panel_style.border_width_top    = 1
	panel_style.border_width_bottom = 1
	panel_style.content_margin_left   = 8
	panel_style.content_margin_right  = 8
	panel_style.content_margin_top    = 8
	panel_style.content_margin_bottom = 8
	breakdown_panel.add_theme_stylebox_override("panel", panel_style)
	root.add_child(breakdown_panel)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 96
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode   = ScrollContainer.SCROLL_MODE_DISABLED
	breakdown_panel.add_child(scroll)

	_breakdown_row = HBoxContainer.new()
	_breakdown_row.add_theme_constant_override("separation", 2)
	scroll.add_child(_breakdown_row)

	root.add_child(_make_gap(12))
	root.add_child(_make_sep(C_BORDER))
	root.add_child(_make_gap(10))

	# ── 해독 결과 ──
	var result_hdr := Label.new()
	result_hdr.text = "해독 결과"
	result_hdr.add_theme_font_size_override("font_size", 12)
	result_hdr.add_theme_color_override("font_color", C_MUTED)
	root.add_child(result_hdr)

	_lbl_result = Label.new()
	_lbl_result.text = "─"
	_lbl_result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_result.add_theme_font_size_override("font_size", 38)
	_lbl_result.add_theme_color_override("font_color", C_GREEN)
	root.add_child(_lbl_result)

	root.add_child(_make_gap(14))

	# ── 하단 버튼 행 ──
	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 14)
	btn_row.alignment = BoxContainer.ALIGNMENT_END
	root.add_child(btn_row)

	_hint_btn = Button.new()
	_hint_btn.text = "단서 힌트"
	_hint_btn.add_theme_font_size_override("font_size", 14)
	_hint_btn.custom_minimum_size = Vector2(160, 42)
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


# ────────────────────────────────────────────────────────────────────
#  로직
# ────────────────────────────────────────────────────────────────────

func _on_key_changed(new_text: String) -> void:
	# 알파벳 이외 문자 자동 제거
	var cleaned := ""
	for ch in new_text.to_upper():
		var code := ch.unicode_at(0)
		if code >= 65 and code <= 90:
			cleaned += ch
	if cleaned != new_text.to_upper():
		_key_edit.text = cleaned
		_key_edit.caret_column = cleaned.length()

	_key = cleaned
	_update_decoder()


func _update_decoder() -> void:
	# 키 길이 라벨 갱신
	if _lbl_key_len != null:
		_lbl_key_len.text = "길이: %d" % _key.length() if _key.length() > 0 else "길이: ─"

	# 평문 갱신
	if _cipher_text.is_empty():
		return

	var plain := CipherLib.vigenere_decode(_cipher_text, _key) if _key.length() > 0 else _cipher_text
	_lbl_result.text = plain

	# 키 대응 시각화 갱신
	_rebuild_breakdown()


func _rebuild_breakdown() -> void:
	# 기존 열 제거
	for child in _breakdown_row.get_children():
		child.queue_free()

	if _cipher_text.is_empty():
		return

	if _key.is_empty():
		# 키 없음: 암호문만 단색으로 표시
		for ch in _cipher_text:
			_breakdown_row.add_child(_make_breakdown_cell("─", C_MUTED, ch, C_GOLD, "─", C_MUTED))
		return

	var breakdown : Array = CipherLib.vigenere_breakdown(_cipher_text, _key)
	for entry in breakdown:
		var e: Dictionary = entry
		var key_ch    : String = e.get("key_char", "")
		var cipher_ch : String = e.get("cipher_char", "")
		var plain_ch  : String = e.get("plain_char", "")
		var key_pos   : int    = e.get("key_pos", -1)

		var col : Color
		if key_pos >= 0:
			col = KEY_COLORS[key_pos % KEY_COLORS.size()]
		else:
			col = C_MUTED

		_breakdown_row.add_child(
			_make_breakdown_cell(key_ch, col, cipher_ch, C_GOLD, plain_ch, col.lightened(0.15))
		)


## 세로 3칸짜리 열 셀 (키 글자 / 암호 글자 / 평문 글자)
func _make_breakdown_cell(
		key_ch: String, key_color: Color,
		cipher_ch: String, cipher_color: Color,
		plain_ch: String, plain_color: Color
) -> Control:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)

	var k := Label.new()
	k.text = key_ch if key_ch != "" else "·"
	k.custom_minimum_size.x = 20
	k.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	k.add_theme_font_size_override("font_size", 13)
	k.add_theme_color_override("font_color", key_color)
	vbox.add_child(k)

	var c := Label.new()
	c.text = cipher_ch
	c.custom_minimum_size.x = 20
	c.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	c.add_theme_font_size_override("font_size", 16)
	c.add_theme_color_override("font_color", cipher_color)
	vbox.add_child(c)

	var p := Label.new()
	p.text = plain_ch
	p.custom_minimum_size.x = 20
	p.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p.add_theme_font_size_override("font_size", 16)
	p.add_theme_color_override("font_color", plain_color)
	vbox.add_child(p)

	return vbox


func _on_hint_pressed() -> void:
	# 비즈네르 암호는 다중 알파벳 치환이므로 빈도 분석이 유효하지 않음
	# 수집된 단서의 hint_value를 순서대로 제공
	GameManager.use_hint()


func _on_confirm() -> void:
	if _key.is_empty():
		return
	var plain := CipherLib.vigenere_decode(_cipher_text, _key)
	emit_signal("decode_confirmed", plain)


# ── 공통 헬퍼 ─────────────────────────────────────────────────────────

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
