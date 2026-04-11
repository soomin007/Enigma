## CipherMuseum.gd — 암호 박물관 (교육용 인터랙티브 데모)
## 5종 암호 방식의 작동 원리를 시각적으로 설명하고 체험할 수 있는 섹션.
extends Control

# ── 팔레트 ─────────────────────────────────────────────────────────
const C_BG       := Color(0.04, 0.05, 0.09)
const C_PANEL    := Color(0.065, 0.075, 0.12)
const C_INSET    := Color(0.05, 0.06, 0.10)
const C_GOLD     := Color(0.93, 0.87, 0.40)
const C_MUTED    := Color(0.40, 0.40, 0.52)
const C_BORDER   := Color(0.18, 0.20, 0.32)
const C_BORDER_G := Color(0.50, 0.44, 0.15)
const C_STAMP    := Color(0.72, 0.16, 0.16)
const C_DIM_TEXT := Color(0.62, 0.60, 0.48)

# ── Enigma 로터 배선 (CipherLib 복사 — path trace 전용) ─────────────
const _ROTOR_WIRING: Dictionary = {
	"I":   "EKMFLGDQVZNTOWYHXUSPAIBRCJ",
	"II":  "AJDKSIRUXBLHWTMCQGZNPYFVOE",
	"III": "BDFHJLCPRTXVZNYEIWGAKMUSQO",
	"IV":  "ESOVPZJAYQUIRHXLNFTGKDCMWB",
	"V":   "VZBRGITYUPSDNHLXAWMJQOFECK",
}
const _REFLECTOR_WIRING: Dictionary = {
	"A": "EJMZALYXVBWFCRQUONTSPIKHGD",
	"B": "YRUHQSLDPXNGOKMIEBFZCWVJAT",
}

# ── 에니그마 데모 상태 ───────────────────────────────────────────────
var _e_rotors    : Array  = ["I", "II", "III"]
var _e_positions : Array  = [0, 0, 0]
var _e_reflector : String = "B"
var _e_plugboard : Dictionary = {}   # 비어있음 (데모 기본)
var _e_input     : int    = 0        # 0=A, 25=Z

# ── 시저 데모 상태 ──────────────────────────────────────────────────
var _c_shift : int = 3

# ── UI 참조 ────────────────────────────────────────────────────────
var _active_cipher  : String = "enigma"
var _content_scroll : ScrollContainer
var _content_vbox   : VBoxContainer
var _sidebar_btns   : Dictionary = {}

# Enigma UI refs
var _e_rotor_type_btns : Array = [[], [], []]  # [slot_idx][type_btn_idx]
var _e_pos_lbls        : Array = []            # Label x3
var _e_reflector_btns  : Dictionary = {}
var _e_input_btns      : Array = []            # Button x26
var _e_path_lbls       : Array = []            # Label x10 (path steps)
var _e_output_lbl      : Label = null
var _e_text_in         : LineEdit = null
var _e_text_out        : Label   = null

# Caesar UI refs
var _c_shift_lbl  : Label = null
var _c_cipher_row : Label = null

# Vigenère UI refs
var _v_key_input  : LineEdit = null
var _v_table_vbox : VBoxContainer = null
const _V_SAMPLE_CIPHER : String = "JSOPM"
const _V_SAMPLE_KEY    : String = "CODE"

# Playfair UI refs
var _pf_key_input   : LineEdit = null
var _pf_grid_lbls   : Array    = []    # 5×5 Label array
var _pf_in_a        : LineEdit = null
var _pf_in_b        : LineEdit = null
var _pf_out_lbl     : Label   = null


# ─────────────────────────────────────────────────────────────────────
func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_build_ui()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = C_BG
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(bg)

	var root_vbox := VBoxContainer.new()
	root_vbox.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	root_vbox.add_theme_constant_override("separation", 0)
	add_child(root_vbox)

	root_vbox.add_child(_build_top_bar())

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 0)
	root_vbox.add_child(body)

	body.add_child(_build_sidebar())

	var content_bg := PanelContainer.new()
	content_bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_bg.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	var cb_style := _make_style(C_INSET, C_BORDER, 0, 0)
	content_bg.add_theme_stylebox_override("panel", cb_style)
	body.add_child(content_bg)

	_content_scroll = ScrollContainer.new()
	_content_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_scroll.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	_content_scroll.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	content_bg.add_child(_content_scroll)

	_switch_cipher("enigma")


func _build_top_bar() -> Control:
	var bar := PanelContainer.new()
	bar.custom_minimum_size.y = 60
	var s := _make_style(Color(0.06, 0.07, 0.11), C_BORDER_G, 0, 0)
	s.border_width_bottom = 1
	bar.add_theme_stylebox_override("panel", s)

	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left",  16)
	m.add_theme_constant_override("margin_right", 16)
	m.add_theme_constant_override("margin_top",    8)
	m.add_theme_constant_override("margin_bottom", 8)
	bar.add_child(m)

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 14)
	m.add_child(hb)

	var back := Button.new()
	back.text = "◀  메뉴"
	back.custom_minimum_size.x = 90
	back.add_theme_font_size_override("font_size", 13)
	back.add_theme_stylebox_override("normal",  _make_style(Color(0.08, 0.09, 0.15), C_BORDER,   1, 8))
	back.add_theme_stylebox_override("hover",   _make_style(Color(0.12, 0.14, 0.22), C_BORDER_G, 1, 8))
	back.add_theme_stylebox_override("pressed", _make_style(Color(0.06, 0.07, 0.12), C_GOLD,     1, 8))
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/MainMenu.tscn"))
	hb.add_child(back)

	var title := Label.new()
	title.text = "CIPHER MUSEUM  ·  암호 해독가 훈련소"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", C_GOLD)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(title)

	var sub := Label.new()
	sub.text = "BLETCHLEY PARK  ·  1942"
	sub.add_theme_font_size_override("font_size", 12)
	sub.add_theme_color_override("font_color", C_MUTED)
	hb.add_child(sub)

	return bar


func _build_sidebar() -> Control:
	var sb := PanelContainer.new()
	sb.custom_minimum_size.x = 224
	sb.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	var s := _make_style(Color(0.055, 0.065, 0.105), C_BORDER, 0, 0)
	s.border_width_right = 1
	sb.add_theme_stylebox_override("panel", s)

	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left",  14)
	m.add_theme_constant_override("margin_right", 14)
	m.add_theme_constant_override("margin_top",   18)
	m.add_theme_constant_override("margin_bottom",14)
	sb.add_child(m)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	m.add_child(vb)

	var hdr := Label.new()
	hdr.text = "■  암호 방식 선택"
	hdr.add_theme_font_size_override("font_size", 11)
	hdr.add_theme_color_override("font_color", C_MUTED)
	vb.add_child(hdr)
	_add_gap(vb, 8)

	var cipher_defs : Array = [
		["caesar",       "시저 암호\nCaesar Cipher",          "CH.0"],
		["vigenere",     "비즈네르 암호\nVigenère Cipher",    "CH.1"],
		["substitution", "단일 치환\nSubstitution Cipher",    "CH.2"],
		["enigma",       "에니그마 머신\nEnigma Machine",     "CH.3"],
		["playfair",     "플레이페어\nPlayfair Cipher",       "CH.4"],
	]

	for entry in cipher_defs:
		var cid: String = entry[0]
		var btn := Button.new()
		btn.text = entry[1]
		btn.custom_minimum_size = Vector2(0, 58)
		btn.add_theme_font_size_override("font_size", 13)
		btn.add_theme_stylebox_override("normal",  _make_style(Color(0.07, 0.08, 0.13), C_BORDER, 1, 10))
		btn.add_theme_stylebox_override("hover",   _make_style(Color(0.10, 0.12, 0.20), C_BORDER_G, 1, 10))
		btn.pressed.connect(_switch_cipher.bind(cid))
		_sidebar_btns[cid] = btn
		vb.add_child(btn)

	return sb


func _switch_cipher(cid: String) -> void:
	_active_cipher = cid

	for key in _sidebar_btns:
		var btn: Button = _sidebar_btns[key]
		var active: bool = key == cid
		btn.add_theme_stylebox_override("normal",
			_make_style(Color(0.09, 0.14, 0.09) if active else Color(0.07, 0.08, 0.13),
						C_GOLD if active else C_BORDER, 2 if active else 1, 10))
		btn.add_theme_color_override("font_color", C_GOLD if active else C_DIM_TEXT)

	if _content_vbox != null:
		_content_vbox.queue_free()
		_content_vbox = null

	_content_vbox = VBoxContainer.new()
	_content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_vbox.add_theme_constant_override("separation", 0)
	_content_scroll.add_child(_content_vbox)

	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left",   40)
	m.add_theme_constant_override("margin_right",  40)
	m.add_theme_constant_override("margin_top",    30)
	m.add_theme_constant_override("margin_bottom", 30)
	m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_vbox.add_child(m)

	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 20)
	inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	m.add_child(inner)

	match cid:
		"caesar":       _build_caesar_content(inner)
		"vigenere":     _build_vigenere_content(inner)
		"substitution": _build_substitution_content(inner)
		"enigma":       _build_enigma_content(inner)
		"playfair":     _build_playfair_content(inner)


# ═══════════════════════════════════════════════════════════════════════
#  시저 암호
# ═══════════════════════════════════════════════════════════════════════

func _build_caesar_content(p: Control) -> void:
	_add_section_title(p, "시저 암호  ·  Caesar Cipher", "CHAPTER 0")

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 40)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.add_child(body)

	var desc := _make_desc_vbox(body, 360)
	_add_desc_text(desc, "시저 암호는 알파벳을 일정 칸수(Shift)만큼 이동시키는\n가장 기초적인 암호입니다.\n\n■ 작동 방식\n모든 글자를 같은 거리만큼 이동.\nShift=3이면 A→D, B→E, Z→C.\n\n■ 복호화\n암호화와 반대 방향으로 같은 거리만큼 이동.\n같은 Shift값으로 반대 방향을 적용하면 원문 복원.\n\n■ 약점\n전체 경우의 수가 26가지뿐이므로\n모든 경우를 시험해보면 즉시 해독 가능.\n빈도 분석으로도 수초 내에 특정됨.")

	var demo := VBoxContainer.new()
	demo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	demo.add_theme_constant_override("separation", 12)
	body.add_child(demo)

	# Shift 컨트롤
	var sr := HBoxContainer.new()
	sr.add_theme_constant_override("separation", 10)
	demo.add_child(sr)

	var sh := Label.new()
	sh.text = "Shift 값:"
	sh.add_theme_font_size_override("font_size", 16)
	sh.add_theme_color_override("font_color", C_GOLD)
	sr.add_child(sh)

	var dec_btn := Button.new()
	dec_btn.text = "◀"
	dec_btn.custom_minimum_size = Vector2(38, 36)
	dec_btn.add_theme_stylebox_override("normal", _make_style(Color(0.08, 0.09, 0.15), C_BORDER, 1, 6))
	dec_btn.add_theme_stylebox_override("hover",  _make_style(Color(0.12, 0.14, 0.22), C_BORDER_G, 1, 6))
	sr.add_child(dec_btn)

	_c_shift_lbl = Label.new()
	_c_shift_lbl.text = str(_c_shift)
	_c_shift_lbl.custom_minimum_size.x = 44
	_c_shift_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_c_shift_lbl.add_theme_font_size_override("font_size", 26)
	_c_shift_lbl.add_theme_color_override("font_color", C_GOLD)
	sr.add_child(_c_shift_lbl)

	var inc_btn := Button.new()
	inc_btn.text = "▶"
	inc_btn.custom_minimum_size = Vector2(38, 36)
	inc_btn.add_theme_stylebox_override("normal", _make_style(Color(0.08, 0.09, 0.15), C_BORDER, 1, 6))
	inc_btn.add_theme_stylebox_override("hover",  _make_style(Color(0.12, 0.14, 0.22), C_BORDER_G, 1, 6))
	sr.add_child(inc_btn)

	dec_btn.pressed.connect(func():
		_c_shift = (_c_shift - 1 + 26) % 26
		_c_shift_lbl.text = str(_c_shift)
		_caesar_update()
	)
	inc_btn.pressed.connect(func():
		_c_shift = (_c_shift + 1) % 26
		_c_shift_lbl.text = str(_c_shift)
		_caesar_update()
	)

	# 알파벳 대응표
	var tpan := PanelContainer.new()
	tpan.add_theme_stylebox_override("panel", _make_style(Color(0.05, 0.06, 0.10), C_BORDER, 1, 0))
	demo.add_child(tpan)

	var tm := MarginContainer.new()
	tm.add_theme_constant_override("margin_left",  14)
	tm.add_theme_constant_override("margin_right", 14)
	tm.add_theme_constant_override("margin_top",   10)
	tm.add_theme_constant_override("margin_bottom",10)
	tpan.add_child(tm)

	var tvb := VBoxContainer.new()
	tvb.add_theme_constant_override("separation", 5)
	tm.add_child(tvb)

	var plain_lbl := Label.new()
	plain_lbl.text = "평문:  " + _alphabet_row(0)
	plain_lbl.add_theme_font_size_override("font_size", 13)
	plain_lbl.add_theme_color_override("font_color", Color(0.80, 0.78, 0.62))
	tvb.add_child(plain_lbl)

	_c_cipher_row = Label.new()
	_c_cipher_row.text = "암호:  " + _alphabet_row(_c_shift)
	_c_cipher_row.add_theme_font_size_override("font_size", 13)
	_c_cipher_row.add_theme_color_override("font_color", C_GOLD)
	tvb.add_child(_c_cipher_row)


func _caesar_update() -> void:
	if _c_cipher_row:
		_c_cipher_row.text = "암호:  " + _alphabet_row(_c_shift)


func _alphabet_row(shift: int) -> String:
	var r := ""
	for i in 26:
		if i > 0: r += " "
		r += char((i + shift) % 26 + 65)
	return r


# ═══════════════════════════════════════════════════════════════════════
#  비즈네르 암호
# ═══════════════════════════════════════════════════════════════════════

func _build_vigenere_content(p: Control) -> void:
	_add_section_title(p, "비즈네르 암호  ·  Vigenère Cipher", "CHAPTER 1")

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 40)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.add_child(body)

	var desc := _make_desc_vbox(body, 360)
	_add_desc_text(desc, "비즈네르 암호는 '키워드(Keyword)'를 사용하는\n암호입니다. 키워드의 각 글자가 이동값이 되어\n메시지 전체에 순환 적용됩니다.\n\n■ 작동 방식\n키워드가 WOLF라면:\n  평문 S E N D → 이동값 W(22) O(14) L(11) F(5)\n  암호문 O S Y I\n\n■ 시저 암호와의 차이\n모든 글자에 동일한 이동값이 아니라\n키워드 길이만큼 이동값이 순환 변화.\n→ 단순 빈도 분석만으로는 해독 불가.\n\n■ 해독 전략\n키워드 길이 추정(Kasiski 검사) →\n키워드 각 위치의 이동값 추정(빈도 분석) →\n키워드 복원.")

	var demo := VBoxContainer.new()
	demo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	demo.add_theme_constant_override("separation", 14)
	body.add_child(demo)

	var ki_row := HBoxContainer.new()
	ki_row.add_theme_constant_override("separation", 10)
	demo.add_child(ki_row)

	var ki_lbl := Label.new()
	ki_lbl.text = "키워드:"
	ki_lbl.add_theme_font_size_override("font_size", 16)
	ki_lbl.add_theme_color_override("font_color", C_GOLD)
	ki_row.add_child(ki_lbl)

	_v_key_input = LineEdit.new()
	_v_key_input.placeholder_text = "KEY"
	_v_key_input.text = _V_SAMPLE_KEY
	_v_key_input.custom_minimum_size = Vector2(160, 36)
	_v_key_input.add_theme_font_size_override("font_size", 16)
	_v_key_input.add_theme_stylebox_override("normal", _make_style(Color(0.08, 0.09, 0.15), C_BORDER_G, 1, 8))
	ki_row.add_child(_v_key_input)

	var apply_btn := Button.new()
	apply_btn.text = "적용"
	apply_btn.add_theme_stylebox_override("normal", _make_style(Color(0.08, 0.10, 0.08), C_BORDER_G, 1, 10))
	apply_btn.add_theme_stylebox_override("hover",  _make_style(Color(0.10, 0.14, 0.10), C_GOLD, 1, 10))
	apply_btn.add_theme_color_override("font_color", C_GOLD)
	ki_row.add_child(apply_btn)

	# 샘플 암호문 표시
	var sample_lbl := Label.new()
	sample_lbl.text = "체험 암호문: %s" % _V_SAMPLE_CIPHER
	sample_lbl.add_theme_font_size_override("font_size", 13)
	sample_lbl.add_theme_color_override("font_color", C_MUTED)
	demo.add_child(sample_lbl)

	# 분석표 영역
	var table_pan := PanelContainer.new()
	table_pan.add_theme_stylebox_override("panel", _make_style(Color(0.05, 0.06, 0.10), C_BORDER, 1, 0))
	demo.add_child(table_pan)

	var tm := MarginContainer.new()
	tm.add_theme_constant_override("margin_left",  14)
	tm.add_theme_constant_override("margin_right", 14)
	tm.add_theme_constant_override("margin_top",   12)
	tm.add_theme_constant_override("margin_bottom",12)
	table_pan.add_child(tm)

	_v_table_vbox = VBoxContainer.new()
	_v_table_vbox.add_theme_constant_override("separation", 6)
	tm.add_child(_v_table_vbox)

	_vigenere_update()

	apply_btn.pressed.connect(_vigenere_update)
	_v_key_input.text_submitted.connect(func(_t): _vigenere_update())


func _vigenere_update() -> void:
	if _v_table_vbox == null:
		return
	for c in _v_table_vbox.get_children():
		c.queue_free()

	var key: String = _v_key_input.text.to_upper() if _v_key_input.text.strip_edges() != "" else _V_SAMPLE_KEY
	var cipher: String = _V_SAMPLE_CIPHER
	var breakdown := CipherLib.vigenere_breakdown(cipher, key)

	var c_row_txt := "암호문:  "
	var k_row_txt := "키:      "
	var s_row_txt := "이동값:  "
	var p_row_txt := "평문:    "

	for item in breakdown:
		var bd: Dictionary = item
		var cc: String = bd.get("cipher_char", " ")
		var kc: String = bd.get("key_char", " ")
		var pc: String = bd.get("plain_char", " ")
		var kp: int    = bd.get("key_pos", -1)
		var shift_val: int = kp if kp >= 0 else 0

		c_row_txt += cc + "  "
		k_row_txt += (kc if kc != "" else " ") + "  "
		s_row_txt += (str(kp >= 0) if kp >= 0 else " ") + "  "
		p_row_txt += pc + "  "
		if cc == " ": s_row_txt = s_row_txt.rstrip("  ") + "   "

	# 컬러 행 (3행)
	var colors : Array = [Color(0.80, 0.78, 0.62), C_GOLD, Color(0.60, 0.80, 0.60), C_GOLD]
	var texts  : Array = [c_row_txt, k_row_txt, _vigenere_shift_row(cipher, key), p_row_txt]
	var prefixes : Array = ["암호문: ", "키:     ", "이동값: ", "평문:   "]
	var row_colors : Array = [
		Color(0.80, 0.78, 0.62),
		Color(0.60, 0.72, 0.90),
		Color(0.80, 0.70, 0.40),
		C_GOLD,
	]

	for i in 4:
		var lbl := Label.new()
		lbl.text = prefixes[i] + texts[i]
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.add_theme_color_override("font_color", row_colors[i])
		_v_table_vbox.add_child(lbl)

	# 결과
	var plain := CipherLib.vigenere_decode(cipher, key)
	var res_lbl := Label.new()
	res_lbl.text = "→  복호화 결과: \"%s\"" % plain
	res_lbl.add_theme_font_size_override("font_size", 16)
	res_lbl.add_theme_color_override("font_color", C_GOLD)
	_v_table_vbox.add_child(res_lbl)


func _vigenere_shift_row(cipher: String, key: String) -> String:
	var clean_key := key.to_upper()
	if clean_key.is_empty(): return ""
	var result := ""
	var idx := 0
	for ch in cipher.to_upper():
		var code := ch.unicode_at(0)
		if code >= 65 and code <= 90:
			var k_val := clean_key[idx % clean_key.length()].unicode_at(0) - 65
			result += str(k_val) + " "
			idx += 1
		else:
			result += "  "
	return result


# ═══════════════════════════════════════════════════════════════════════
#  단일 치환 암호
# ═══════════════════════════════════════════════════════════════════════

func _build_substitution_content(p: Control) -> void:
	_add_section_title(p, "단일 치환 암호  ·  Substitution Cipher", "CHAPTER 2")

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 40)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.add_child(body)

	var desc := _make_desc_vbox(body, 360)
	_add_desc_text(desc, "단일 치환 암호는 알파벳 26자가 각각 다른\n하나의 글자로 고정 대체되는 암호입니다.\n\n■ 작동 방식\nA→X, B→M, C→P, ... 모든 글자에 고정 규칙.\n암호화 전문에 걸쳐 동일한 치환표 적용.\n\n■ 해독 전략: 빈도 분석\n영어 글자 출현 빈도는 언어 특성상 일정.\n  E ≈ 12.7%  T ≈ 9.1%  A ≈ 8.2%\n  O ≈ 7.5%  I ≈ 7.0%  N ≈ 6.7%\n\n암호문에서 가장 많이 나오는 글자 → E\n세 글자 단어 패턴 → THE, AND, FOR\n두 글자 단어 → IS, IT, AT, TO\n\n■ 약점\n빈도 패턴은 치환해도 보존됨.\n긴 텍스트일수록 빈도 분석 효과가 커짐.")

	var demo := VBoxContainer.new()
	demo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	demo.add_theme_constant_override("separation", 12)
	body.add_child(demo)

	var freq_title := Label.new()
	freq_title.text = "영어 알파벳 출현 빈도 (높은 순)"
	freq_title.add_theme_font_size_override("font_size", 14)
	freq_title.add_theme_color_override("font_color", C_GOLD)
	demo.add_child(freq_title)

	# 빈도 막대 그래프
	var freq_order : String = "ETAOINSHRDLCUMWFGYPBVKJXQZ"
	var freq_vals  : Dictionary = {
		"E": 12.7, "T": 9.1, "A": 8.2, "O": 7.5, "I": 7.0, "N": 6.7,
		"S": 6.3, "H": 6.1, "R": 6.0, "D": 4.3, "L": 4.0, "C": 2.8,
		"U": 2.8, "M": 2.4, "W": 2.4, "F": 2.2, "G": 2.0, "Y": 2.0,
		"P": 1.9, "B": 1.5, "V": 1.0, "K": 0.8, "J": 0.15, "X": 0.15,
		"Q": 0.1, "Z": 0.07,
	}
	var bar_pan := PanelContainer.new()
	bar_pan.add_theme_stylebox_override("panel", _make_style(Color(0.04, 0.05, 0.09), C_BORDER, 1, 0))
	demo.add_child(bar_pan)

	var bm := MarginContainer.new()
	bm.add_theme_constant_override("margin_left",  12)
	bm.add_theme_constant_override("margin_right", 12)
	bm.add_theme_constant_override("margin_top",   10)
	bm.add_theme_constant_override("margin_bottom",10)
	bar_pan.add_child(bm)

	var bar_vb := VBoxContainer.new()
	bar_vb.add_theme_constant_override("separation", 3)
	bm.add_child(bar_vb)

	for i in 10:  # 상위 10개만 표시
		var ch : String = freq_order[i]
		var pct : float = freq_vals.get(ch, 0.0)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		bar_vb.add_child(row)

		var ch_lbl := Label.new()
		ch_lbl.text = ch
		ch_lbl.custom_minimum_size.x = 18
		ch_lbl.add_theme_font_size_override("font_size", 13)
		ch_lbl.add_theme_color_override("font_color", C_GOLD if i < 3 else C_DIM_TEXT)
		row.add_child(ch_lbl)

		var bar_ctrl := ColorRect.new()
		bar_ctrl.custom_minimum_size = Vector2(pct * 28.0, 14)
		bar_ctrl.color = C_GOLD.darkened(0.2 + float(i) * 0.04) if i < 3 else C_BORDER_G.darkened(float(i) * 0.05)
		row.add_child(bar_ctrl)

		var pct_lbl := Label.new()
		pct_lbl.text = "%.1f%%" % pct
		pct_lbl.add_theme_font_size_override("font_size", 11)
		pct_lbl.add_theme_color_override("font_color", C_MUTED)
		row.add_child(pct_lbl)

	var tip_lbl := Label.new()
	tip_lbl.text = "→ 암호문에서 가장 많이 나오는 글자부터 E, T, A 순서로 대응시키며 패턴을 맞춰 나간다."
	tip_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip_lbl.add_theme_font_size_override("font_size", 13)
	tip_lbl.add_theme_color_override("font_color", Color(0.60, 0.80, 0.60))
	demo.add_child(tip_lbl)


# ═══════════════════════════════════════════════════════════════════════
#  에니그마 머신 — 메인 인터랙티브 데모
# ═══════════════════════════════════════════════════════════════════════

func _build_enigma_content(p: Control) -> void:
	_e_rotor_type_btns = [[], [], []]
	_e_pos_lbls.clear()
	_e_reflector_btns.clear()
	_e_input_btns.clear()
	_e_path_lbls.clear()
	_e_output_lbl = null
	_e_text_in    = null
	_e_text_out   = null

	_add_section_title(p, "에니그마 머신  ·  Enigma Machine", "CHAPTER 3")

	var intro := Label.new()
	intro.text = "에니그마는 1939년부터 나치 독일군이 사용한 전기-기계식 암호 장치입니다.  같은 설정으로 암호문을 입력하면 그대로 평문이 출력되는 '대칭 암호'입니다."
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.add_theme_font_size_override("font_size", 14)
	intro.add_theme_color_override("font_color", C_DIM_TEXT)
	p.add_child(intro)

	p.add_child(_make_sep_h())

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 36)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.add_child(body)

	# ─ 좌: 구성 요소 설명 ─
	var left := VBoxContainer.new()
	left.custom_minimum_size.x = 360
	left.add_theme_constant_override("separation", 14)
	body.add_child(left)

	_add_component_block(left, "■ 로터 (Rotor)",
		"26접점 전기 원판. 입력 신호가 내부 배선을\n통해 다른 위치로 출력됨.\n\n키를 누를 때마다 오른쪽 로터가 한 칸 전진.\n일정 위치(노치)에서 다음 로터도 전진.\n→ 같은 글자를 눌러도 매번 다른 암호글자 출력.")

	_add_component_block(left, "■ 반사판 (Reflector)",
		"신호를 로터 역방향으로 되돌려 보내는\n고정 부품. A형과 B형이 있음.\n\n덕분에 에니그마는 대칭 암호:\n같은 설정으로 암호문 입력 → 평문 출력.")

	_add_component_block(left, "■ 플러그보드 (Plugboard)",
		"입출력 전 알파벳 쌍을 물리 케이블로 교환.\nA↔Z로 연결하면 A→Z, Z→A로 변환.\n\n이론적 경우의 수: 약 10²³가지.\n에니그마 전체 보안 중 최대 기여 부품.")

	_add_component_block(left, "⚠  치명적 약점",
		"에니그마는 어떤 설정에서도\n같은 글자로 암호화되지 않는다.\n( A → A 절대 불가능 )\n\n알란 튜링은 이 약점을 이용해\n봄브(Bombe) 해독기를 설계했다.")

	# ─ 우: 인터랙티브 데모 ─
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 14)
	body.add_child(right)

	# 로터 설정
	_add_demo_label(right, "로터 구성  (좌 → 중 → 우)")
	right.add_child(_build_enigma_rotor_panel())

	# 반사판
	_add_demo_label(right, "반사판")
	right.add_child(_build_enigma_reflector_panel())

	# 입력 글자
	_add_demo_label(right, "입력 글자 선택")
	right.add_child(_build_enigma_input_grid())

	# 신호 경로
	_add_demo_label(right, "신호 경로 시각화  (단일 입력 기준, 로터 스텝 미적용)")
	right.add_child(_build_enigma_path_display())

	# 출력
	var out_row := HBoxContainer.new()
	out_row.add_theme_constant_override("separation", 10)
	right.add_child(out_row)
	var ol := Label.new()
	ol.text = "출력 글자:"
	ol.add_theme_font_size_override("font_size", 18)
	ol.add_theme_color_override("font_color", C_DIM_TEXT)
	out_row.add_child(ol)
	_e_output_lbl = Label.new()
	_e_output_lbl.add_theme_font_size_override("font_size", 32)
	_e_output_lbl.add_theme_color_override("font_color", C_GOLD)
	out_row.add_child(_e_output_lbl)

	right.add_child(_make_sep_h())
	_add_demo_label(right, "텍스트 암호화 체험  (로터 스텝 포함)")
	right.add_child(_build_enigma_text_encoder())

	_enigma_update()


func _build_enigma_rotor_panel() -> Control:
	var pan := PanelContainer.new()
	pan.add_theme_stylebox_override("panel", _make_style(Color(0.05, 0.07, 0.11), C_BORDER, 1, 0))

	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left",  14)
	m.add_theme_constant_override("margin_right", 14)
	m.add_theme_constant_override("margin_top",   12)
	m.add_theme_constant_override("margin_bottom",12)
	pan.add_child(m)

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 20)
	m.add_child(hb)

	var rotor_types := ["I", "II", "III", "IV", "V"]
	var slot_names  := ["슬롯 I (좌)", "슬롯 II (중)", "슬롯 III (우)"]

	for slot in 3:
		var svb := VBoxContainer.new()
		svb.add_theme_constant_override("separation", 6)
		hb.add_child(svb)

		var slot_lbl := Label.new()
		slot_lbl.text = slot_names[slot]
		slot_lbl.add_theme_font_size_override("font_size", 11)
		slot_lbl.add_theme_color_override("font_color", C_MUTED)
		svb.add_child(slot_lbl)

		# 로터 타입 버튼 행
		var type_row := HBoxContainer.new()
		type_row.add_theme_constant_override("separation", 3)
		svb.add_child(type_row)

		_e_rotor_type_btns[slot] = []
		for ti in rotor_types.size():
			var rt: String = rotor_types[ti]
			var tb := Button.new()
			tb.text = rt
			tb.custom_minimum_size = Vector2(32, 28)
			tb.add_theme_font_size_override("font_size", 11)
			var is_active: bool = _e_rotors[slot] == rt
			tb.add_theme_stylebox_override("normal",
				_make_style(Color(0.10, 0.14, 0.10) if is_active else Color(0.07, 0.08, 0.13),
							C_GOLD if is_active else C_BORDER, 1 if is_active else 1, 4))
			tb.add_theme_color_override("font_color", C_GOLD if is_active else C_DIM_TEXT)

			var captured_slot := slot
			var captured_rt   := rt
			tb.pressed.connect(func():
				_e_rotors[captured_slot] = captured_rt
				_update_rotor_type_btns(captured_slot, captured_rt)
				_enigma_update()
			)
			type_row.add_child(tb)
			_e_rotor_type_btns[slot].append(tb)

		# 위치 컨트롤
		var pos_row := HBoxContainer.new()
		pos_row.add_theme_constant_override("separation", 4)
		svb.add_child(pos_row)

		var dn_btn := Button.new()
		dn_btn.text = "▼"
		dn_btn.custom_minimum_size = Vector2(28, 30)
		dn_btn.add_theme_font_size_override("font_size", 10)
		dn_btn.add_theme_stylebox_override("normal", _make_style(Color(0.08, 0.09, 0.15), C_BORDER, 1, 4))
		pos_row.add_child(dn_btn)

		var pos_lbl := Label.new()
		pos_lbl.text = char(_e_positions[slot] + 65)
		pos_lbl.custom_minimum_size.x = 36
		pos_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pos_lbl.add_theme_font_size_override("font_size", 22)
		pos_lbl.add_theme_color_override("font_color", C_GOLD)
		pos_row.add_child(pos_lbl)
		_e_pos_lbls.append(pos_lbl)

		var up_btn := Button.new()
		up_btn.text = "▲"
		up_btn.custom_minimum_size = Vector2(28, 30)
		up_btn.add_theme_font_size_override("font_size", 10)
		up_btn.add_theme_stylebox_override("normal", _make_style(Color(0.08, 0.09, 0.15), C_BORDER, 1, 4))
		pos_row.add_child(up_btn)

		var captured_s := slot
		dn_btn.pressed.connect(func():
			_e_positions[captured_s] = (_e_positions[captured_s] - 1 + 26) % 26
			var pl: Label = _e_pos_lbls[captured_s]
			pl.text = char(_e_positions[captured_s] + 65)
			_enigma_update()
		)
		up_btn.pressed.connect(func():
			_e_positions[captured_s] = (_e_positions[captured_s] + 1) % 26
			var pl: Label = _e_pos_lbls[captured_s]
			pl.text = char(_e_positions[captured_s] + 65)
			_enigma_update()
		)

	return pan


func _update_rotor_type_btns(slot: int, active_rt: String) -> void:
	var btns: Array = _e_rotor_type_btns[slot]
	var rotor_types := ["I", "II", "III", "IV", "V"]
	for ti in btns.size():
		var tb: Button = btns[ti]
		var is_active: bool = rotor_types[ti] == active_rt
		tb.add_theme_stylebox_override("normal",
			_make_style(Color(0.10, 0.14, 0.10) if is_active else Color(0.07, 0.08, 0.13),
						C_GOLD if is_active else C_BORDER, 1, 4))
		tb.add_theme_color_override("font_color", C_GOLD if is_active else C_DIM_TEXT)


func _build_enigma_reflector_panel() -> Control:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)

	for ref_type in ["A", "B"]:
		var rb := Button.new()
		rb.text = "반사판  " + ref_type
		rb.custom_minimum_size = Vector2(110, 36)
		rb.add_theme_font_size_override("font_size", 14)
		var is_active: bool = _e_reflector == ref_type
		rb.add_theme_stylebox_override("normal",
			_make_style(Color(0.10, 0.14, 0.10) if is_active else Color(0.07, 0.08, 0.13),
						C_GOLD if is_active else C_BORDER, 2 if is_active else 1, 10))
		rb.add_theme_color_override("font_color", C_GOLD if is_active else C_DIM_TEXT)
		var captured: String = ref_type
		rb.pressed.connect(func():
			_e_reflector = captured
			for key in _e_reflector_btns:
				var b: Button = _e_reflector_btns[key]
				var act: bool = key == captured
				b.add_theme_stylebox_override("normal",
					_make_style(Color(0.10, 0.14, 0.10) if act else Color(0.07, 0.08, 0.13),
								C_GOLD if act else C_BORDER, 2 if act else 1, 10))
				b.add_theme_color_override("font_color", C_GOLD if act else C_DIM_TEXT)
			_enigma_update()
		)
		_e_reflector_btns[ref_type] = rb
		hb.add_child(rb)

	return hb


func _build_enigma_input_grid() -> Control:
	var grid := GridContainer.new()
	grid.columns = 13
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)

	for i in 26:
		var ch := char(i + 65)
		var btn := Button.new()
		btn.text = ch
		btn.custom_minimum_size = Vector2(44, 36)
		btn.add_theme_font_size_override("font_size", 14)
		var is_active := i == _e_input
		btn.add_theme_stylebox_override("normal",
			_make_style(Color(0.10, 0.14, 0.10) if is_active else Color(0.07, 0.08, 0.13),
						C_GOLD if is_active else C_BORDER, 2 if is_active else 1, 6))
		btn.add_theme_color_override("font_color", C_GOLD if is_active else C_DIM_TEXT)
		var cap_i := i
		btn.pressed.connect(func():
			_e_input = cap_i
			for j in _e_input_btns.size():
				var b: Button = _e_input_btns[j]
				var act := j == cap_i
				b.add_theme_stylebox_override("normal",
					_make_style(Color(0.10, 0.14, 0.10) if act else Color(0.07, 0.08, 0.13),
								C_GOLD if act else C_BORDER, 2 if act else 1, 6))
				b.add_theme_color_override("font_color", C_GOLD if act else C_DIM_TEXT)
			_enigma_update()
		)
		_e_input_btns.append(btn)
		grid.add_child(btn)

	return grid


func _build_enigma_path_display() -> Control:
	var stage_names := ["입력", "PB→", "R-III", "R-II", "R-I", "반사판", "I←R", "II←R", "III←R", "출력"]

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 100
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 0)
	hb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(hb)

	for i in 10:
		if i > 0:
			var arrow := Label.new()
			arrow.text = " → "
			arrow.add_theme_font_size_override("font_size", 14)
			arrow.add_theme_color_override("font_color", Color(0.38, 0.38, 0.48))
			arrow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			arrow.size_flags_vertical = Control.SIZE_EXPAND_FILL
			hb.add_child(arrow)

		var stage_vb := VBoxContainer.new()
		stage_vb.add_theme_constant_override("separation", 3)
		hb.add_child(stage_vb)

		var name_lbl := Label.new()
		name_lbl.text = stage_names[i]
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_font_size_override("font_size", 10)
		name_lbl.add_theme_color_override("font_color", C_MUTED)
		stage_vb.add_child(name_lbl)

		var is_ref := i == 5
		var is_io  := i == 0 or i == 9
		var box_bg     := Color(0.15, 0.12, 0.05) if is_ref else (Color(0.08, 0.12, 0.08) if is_io else Color(0.07, 0.08, 0.13))
		var box_border := C_GOLD if is_ref else (Color(0.30, 0.60, 0.30) if is_io else C_BORDER)

		var box_pan := PanelContainer.new()
		box_pan.custom_minimum_size = Vector2(56, 56)
		box_pan.add_theme_stylebox_override("panel", _make_style(box_bg, box_border, 2 if is_ref else 1, 0))
		stage_vb.add_child(box_pan)

		var letter_lbl := Label.new()
		letter_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		letter_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		letter_lbl.add_theme_font_size_override("font_size", 26)
		letter_lbl.add_theme_color_override("font_color", C_GOLD if is_ref else (Color(0.70, 0.90, 0.70) if is_io else Color(0.80, 0.78, 0.90)))
		letter_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		letter_lbl.size_flags_vertical   = Control.SIZE_EXPAND_FILL
		box_pan.add_child(letter_lbl)
		_e_path_lbls.append(letter_lbl)

	return scroll


func _build_enigma_text_encoder() -> Control:
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)

	var in_row := HBoxContainer.new()
	in_row.add_theme_constant_override("separation", 10)
	vb.add_child(in_row)

	var in_lbl := Label.new()
	in_lbl.text = "텍스트 입력:"
	in_lbl.add_theme_font_size_override("font_size", 14)
	in_lbl.add_theme_color_override("font_color", C_DIM_TEXT)
	in_row.add_child(in_lbl)

	_e_text_in = LineEdit.new()
	_e_text_in.placeholder_text = "HELLO"
	_e_text_in.custom_minimum_size = Vector2(300, 36)
	_e_text_in.add_theme_font_size_override("font_size", 16)
	_e_text_in.add_theme_stylebox_override("normal", _make_style(Color(0.07, 0.08, 0.13), C_BORDER_G, 1, 8))
	in_row.add_child(_e_text_in)

	var enc_btn := Button.new()
	enc_btn.text = "암호화"
	enc_btn.add_theme_stylebox_override("normal", _make_style(Color(0.08, 0.10, 0.08), C_BORDER_G, 1, 12))
	enc_btn.add_theme_stylebox_override("hover",  _make_style(Color(0.10, 0.14, 0.10), C_GOLD, 1, 12))
	enc_btn.add_theme_color_override("font_color", C_GOLD)
	in_row.add_child(enc_btn)

	var out_row := HBoxContainer.new()
	out_row.add_theme_constant_override("separation", 10)
	vb.add_child(out_row)

	var out_lbl := Label.new()
	out_lbl.text = "암호화 결과:"
	out_lbl.add_theme_font_size_override("font_size", 14)
	out_lbl.add_theme_color_override("font_color", C_DIM_TEXT)
	out_row.add_child(out_lbl)

	_e_text_out = Label.new()
	_e_text_out.add_theme_font_size_override("font_size", 18)
	_e_text_out.add_theme_color_override("font_color", C_GOLD)
	out_row.add_child(_e_text_out)

	enc_btn.pressed.connect(func():
		var txt := _e_text_in.text.strip_edges().to_upper()
		if txt.is_empty(): return
		var encoded := CipherLib.enigma_process(txt, _e_rotors, _e_positions, _e_reflector, _e_plugboard)
		_e_text_out.text = encoded
	)
	_e_text_in.text_submitted.connect(func(_t):
		enc_btn.emit_signal("pressed")
	)

	var note := Label.new()
	note.text = "※ 같은 설정으로 출력값을 다시 암호화하면 원문이 복원됩니다."
	note.add_theme_font_size_override("font_size", 12)
	note.add_theme_color_override("font_color", C_MUTED)
	vb.add_child(note)

	return vb


# ── Enigma 단일 경로 추적 ───────────────────────────────────────────

func _enigma_update() -> void:
	if _e_path_lbls.is_empty(): return
	var stages := _enigma_trace_single(_e_input)
	for i in min(stages.size(), _e_path_lbls.size()):
		var lbl: Label = _e_path_lbls[i]
		lbl.text = char(stages[i] + 65)
	if _e_output_lbl != null and stages.size() >= 10:
		var out_ch := char(stages[9] + 65)
		_e_output_lbl.text = out_ch
		var same: bool = stages[9] == _e_input
		_e_output_lbl.add_theme_color_override("font_color",
			Color(0.85, 0.25, 0.25) if same else C_GOLD)


func _enigma_trace_single(input_n: int) -> Array:
	var stages : Array = []
	var sig := input_n
	stages.append(sig)

	# 플러그보드 입력
	var ch_in := char(sig + 65)
	if _e_plugboard.has(ch_in):
		sig = _e_plugboard[ch_in].unicode_at(0) - 65
	stages.append(sig)

	# 로터 순방향 (III → II → I)
	sig = _rtrace_fwd(_ROTOR_WIRING[_e_rotors[2]], _e_positions[2], sig)
	stages.append(sig)
	sig = _rtrace_fwd(_ROTOR_WIRING[_e_rotors[1]], _e_positions[1], sig)
	stages.append(sig)
	sig = _rtrace_fwd(_ROTOR_WIRING[_e_rotors[0]], _e_positions[0], sig)
	stages.append(sig)

	# 반사판
	sig = _REFLECTOR_WIRING[_e_reflector][sig].unicode_at(0) - 65
	stages.append(sig)

	# 로터 역방향 (I → II → III)
	sig = _rtrace_bwd(_ROTOR_WIRING[_e_rotors[0]], _e_positions[0], sig)
	stages.append(sig)
	sig = _rtrace_bwd(_ROTOR_WIRING[_e_rotors[1]], _e_positions[1], sig)
	stages.append(sig)
	sig = _rtrace_bwd(_ROTOR_WIRING[_e_rotors[2]], _e_positions[2], sig)
	stages.append(sig)

	# 플러그보드 출력
	var ch_out := char(sig + 65)
	if _e_plugboard.has(ch_out):
		sig = _e_plugboard[ch_out].unicode_at(0) - 65
	stages.append(sig)

	return stages


func _rtrace_fwd(wiring: String, pos: int, sig: int) -> int:
	var entry    := (sig + pos) % 26
	var exit_val := wiring[entry].unicode_at(0) - 65
	return (exit_val - pos + 26) % 26


func _rtrace_bwd(wiring: String, pos: int, sig: int) -> int:
	var entry    := (sig + pos) % 26
	var exit_pos := wiring.find(char(entry + 65))
	return (exit_pos - pos + 26) % 26


# ═══════════════════════════════════════════════════════════════════════
#  플레이페어 암호
# ═══════════════════════════════════════════════════════════════════════

func _build_playfair_content(p: Control) -> void:
	_add_section_title(p, "플레이페어 암호  ·  Playfair Cipher", "CHAPTER 4")

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 40)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.add_child(body)

	var desc := _make_desc_vbox(body, 360)
	_add_desc_text(desc, "플레이페어 암호는 5×5 격자를 이용해\n두 글자씩 묶어 처리하는 암호입니다.\n\n■ 격자 구성\n키워드의 알파벳(중복 제거)을 먼저 채우고\n나머지 알파벳을 순서대로 채운다.\nI와 J는 같은 칸 사용.\n\n■ 암호화 규칙 (두 글자 쌍)\n  같은 행: 각 글자 → 오른쪽 이동\n  같은 열: 각 글자 → 아래 이동\n  사각형: 행 유지, 열 교환\n\n■ 전처리 규칙\n  연속 같은 글자 → X 삽입 (LL → LXL)\n  홀수 길이 → 끝에 X 추가\n\n■ 해독\n규칙을 반대로 적용 (오른쪽→왼쪽, 아래→위)\n단, 격자 키워드를 먼저 찾아야 한다.")

	var demo := VBoxContainer.new()
	demo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	demo.add_theme_constant_override("separation", 14)
	body.add_child(demo)

	var ki_row := HBoxContainer.new()
	ki_row.add_theme_constant_override("separation", 10)
	demo.add_child(ki_row)

	var ki_lbl := Label.new()
	ki_lbl.text = "키워드:"
	ki_lbl.add_theme_font_size_override("font_size", 16)
	ki_lbl.add_theme_color_override("font_color", C_GOLD)
	ki_row.add_child(ki_lbl)

	_pf_key_input = LineEdit.new()
	_pf_key_input.placeholder_text = "KEY"
	_pf_key_input.text = "KEY"
	_pf_key_input.custom_minimum_size = Vector2(160, 36)
	_pf_key_input.add_theme_font_size_override("font_size", 16)
	_pf_key_input.add_theme_stylebox_override("normal", _make_style(Color(0.08, 0.09, 0.15), C_BORDER_G, 1, 8))
	ki_row.add_child(_pf_key_input)

	var apply_btn := Button.new()
	apply_btn.text = "격자 생성"
	apply_btn.add_theme_stylebox_override("normal", _make_style(Color(0.08, 0.10, 0.08), C_BORDER_G, 1, 10))
	apply_btn.add_theme_stylebox_override("hover",  _make_style(Color(0.10, 0.14, 0.10), C_GOLD, 1, 10))
	apply_btn.add_theme_color_override("font_color", C_GOLD)
	ki_row.add_child(apply_btn)

	# 5×5 격자
	var grid_pan := PanelContainer.new()
	grid_pan.add_theme_stylebox_override("panel", _make_style(Color(0.04, 0.05, 0.09), C_BORDER, 1, 0))
	demo.add_child(grid_pan)

	var gm := MarginContainer.new()
	gm.add_theme_constant_override("margin_left",  12)
	gm.add_theme_constant_override("margin_right", 12)
	gm.add_theme_constant_override("margin_top",   10)
	gm.add_theme_constant_override("margin_bottom",10)
	grid_pan.add_child(gm)

	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	gm.add_child(grid)

	_pf_grid_lbls = []
	for _r in 5:
		for _c in 5:
			var cell_pan := PanelContainer.new()
			cell_pan.custom_minimum_size = Vector2(48, 44)
			cell_pan.add_theme_stylebox_override("panel", _make_style(Color(0.07, 0.08, 0.13), C_BORDER, 1, 0))

			var cell_lbl := Label.new()
			cell_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			cell_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
			cell_lbl.add_theme_font_size_override("font_size", 20)
			cell_lbl.add_theme_color_override("font_color", Color(0.80, 0.78, 0.62))
			cell_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			cell_lbl.size_flags_vertical   = Control.SIZE_EXPAND_FILL
			cell_pan.add_child(cell_lbl)
			grid.add_child(cell_pan)
			_pf_grid_lbls.append(cell_lbl)

	# 쌍 체험
	var pair_row := HBoxContainer.new()
	pair_row.add_theme_constant_override("separation", 8)
	demo.add_child(pair_row)

	var pi_lbl := Label.new()
	pi_lbl.text = "평문 쌍:"
	pi_lbl.add_theme_font_size_override("font_size", 14)
	pi_lbl.add_theme_color_override("font_color", C_DIM_TEXT)
	pair_row.add_child(pi_lbl)

	_pf_in_a = LineEdit.new()
	_pf_in_a.placeholder_text = "FL"
	_pf_in_a.text = "FL"
	_pf_in_a.custom_minimum_size = Vector2(70, 34)
	_pf_in_a.max_length = 2
	_pf_in_a.add_theme_font_size_override("font_size", 16)
	_pf_in_a.add_theme_stylebox_override("normal", _make_style(Color(0.07, 0.08, 0.13), C_BORDER, 1, 8))
	pair_row.add_child(_pf_in_a)

	var pair_enc_btn := Button.new()
	pair_enc_btn.text = "→ 암호화"
	pair_enc_btn.add_theme_stylebox_override("normal", _make_style(Color(0.08, 0.10, 0.08), C_BORDER_G, 1, 10))
	pair_enc_btn.add_theme_color_override("font_color", C_GOLD)
	pair_row.add_child(pair_enc_btn)

	_pf_out_lbl = Label.new()
	_pf_out_lbl.add_theme_font_size_override("font_size", 18)
	_pf_out_lbl.add_theme_color_override("font_color", C_GOLD)
	pair_row.add_child(_pf_out_lbl)

	_playfair_update_grid()

	apply_btn.pressed.connect(func(): _playfair_update_grid())
	_pf_key_input.text_submitted.connect(func(_t): _playfair_update_grid())
	pair_enc_btn.pressed.connect(func(): _playfair_encode_pair())


func _playfair_update_grid() -> void:
	if _pf_grid_lbls.is_empty(): return
	var key := _pf_key_input.text.strip_edges()
	if key.is_empty(): key = "KEY"

	var grid := CipherLib._playfair_build_grid(key)
	var key_set: Dictionary = {}
	for ch in key.to_upper():
		if ch != "J": key_set[ch] = true
		else: key_set["I"] = true

	for r in 5:
		for c in 5:
			var ch: String = grid[r][c]
			var idx := r * 5 + c
			var lbl: Label = _pf_grid_lbls[idx]
			lbl.text = ch
			var is_key := key_set.has(ch)
			lbl.add_theme_color_override("font_color", C_GOLD if is_key else Color(0.70, 0.68, 0.55))
			var cell_pan: PanelContainer = lbl.get_parent()
			cell_pan.add_theme_stylebox_override("panel",
				_make_style(Color(0.14, 0.12, 0.06) if is_key else Color(0.07, 0.08, 0.13),
							C_GOLD if is_key else C_BORDER, 1, 0))


func _playfair_encode_pair() -> void:
	if _pf_out_lbl == null: return
	var inp := _pf_in_a.text.strip_edges().to_upper()
	if inp.length() < 2: return
	var key := _pf_key_input.text.strip_edges()
	if key.is_empty(): key = "KEY"
	var result := CipherLib.playfair_process(inp.substr(0, 2), key, true)
	_pf_out_lbl.text = result


# ═══════════════════════════════════════════════════════════════════════
#  공통 UI 헬퍼
# ═══════════════════════════════════════════════════════════════════════

func _add_section_title(parent: Control, title: String, sub: String) -> void:
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	parent.add_child(vb)

	var stamp := Label.new()
	stamp.text = "◆  " + sub + "  ◆"
	stamp.add_theme_font_size_override("font_size", 11)
	stamp.add_theme_color_override("font_color", C_STAMP)
	vb.add_child(stamp)

	var t := Label.new()
	t.text = title
	t.add_theme_font_size_override("font_size", 28)
	t.add_theme_color_override("font_color", C_GOLD)
	vb.add_child(t)

	parent.add_child(_make_sep_h())


func _add_component_block(parent: Control, title: String, body_text: String) -> void:
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	parent.add_child(vb)

	var t := Label.new()
	t.text = title
	t.add_theme_font_size_override("font_size", 14)
	t.add_theme_color_override("font_color", C_GOLD)
	vb.add_child(t)

	var b := Label.new()
	b.text = body_text
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.add_theme_font_size_override("font_size", 13)
	b.add_theme_color_override("font_color", C_DIM_TEXT)
	vb.add_child(b)


func _add_demo_label(parent: Control, text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", C_MUTED)
	parent.add_child(lbl)


func _make_desc_vbox(parent: Control, min_width: int) -> VBoxContainer:
	var vb := VBoxContainer.new()
	vb.custom_minimum_size.x = min_width
	vb.add_theme_constant_override("separation", 8)
	parent.add_child(vb)
	return vb


func _add_desc_text(parent: Control, text: String) -> void:
	var pan := PanelContainer.new()
	pan.add_theme_stylebox_override("panel", _make_style(Color(0.055, 0.065, 0.105), C_BORDER, 1, 0))
	parent.add_child(pan)

	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left",  16)
	m.add_theme_constant_override("margin_right", 16)
	m.add_theme_constant_override("margin_top",   14)
	m.add_theme_constant_override("margin_bottom",14)
	pan.add_child(m)

	var lbl := Label.new()
	lbl.text = text
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", C_DIM_TEXT)
	m.add_child(lbl)


func _make_sep_h() -> HSeparator:
	var sep := HSeparator.new()
	var s := StyleBoxFlat.new()
	s.bg_color = C_BORDER
	sep.add_theme_stylebox_override("separator", s)
	return sep


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


func _add_gap(parent: Control, h: int) -> void:
	var g := Control.new()
	g.custom_minimum_size.y = h
	parent.add_child(g)
