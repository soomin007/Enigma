## Settings.gd — 설정 메뉴 씬
## BGM/SFX 볼륨, 텍스트 속도, 언어 설정을 제공한다.
extends Control

# ── 팔레트 ───────────────────────────────────────────────────────────
const C_BG      := Color(0.04, 0.05, 0.09)
const C_PANEL   := Color(0.065, 0.075, 0.12)
const C_GOLD    := Color(0.93, 0.87, 0.40)
const C_MUTED   := Color(0.40, 0.40, 0.52)
const C_BORDER  := Color(0.18, 0.20, 0.32)
const C_BORDER_G := Color(0.50, 0.44, 0.15)

var _bgm_slider   : HSlider
var _sfx_slider   : HSlider
var _speed_slider : HSlider
var _bgm_lbl      : Label
var _sfx_lbl      : Label
var _speed_lbl    : Label


func _ready() -> void:
	self.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_build_ui()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = C_BG
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(bg)

	var root_v := VBoxContainer.new()
	root_v.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	root_v.add_theme_constant_override("separation", 0)
	add_child(root_v)

	root_v.add_child(_build_top_bar())

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root_v.add_child(scroll)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   0)
	margin.add_theme_constant_override("margin_right",  0)
	margin.add_theme_constant_override("margin_top",    0)
	margin.add_theme_constant_override("margin_bottom", 0)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(margin)

	var outer_v := VBoxContainer.new()
	outer_v.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	outer_v.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(outer_v)

	_add_gap(outer_v, 48)

	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.custom_minimum_size.x = 680
	panel.add_theme_stylebox_override("panel", _make_style(C_PANEL, C_BORDER_G, 1, 0))
	outer_v.add_child(panel)

	var pm := MarginContainer.new()
	pm.add_theme_constant_override("margin_left",   48)
	pm.add_theme_constant_override("margin_right",  48)
	pm.add_theme_constant_override("margin_top",    36)
	pm.add_theme_constant_override("margin_bottom", 36)
	panel.add_child(pm)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 28)
	pm.add_child(vbox)

	# 헤더
	var hdr := Label.new()
	hdr.text = "◆  설정  ·  SETTINGS"
	hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hdr.add_theme_font_size_override("font_size", 22)
	hdr.add_theme_color_override("font_color", C_GOLD)
	vbox.add_child(hdr)

	vbox.add_child(_make_sep(C_BORDER_G))

	# BGM 볼륨
	vbox.add_child(_make_slider_row(
		"BGM 볼륨",
		SettingsManager.bgm_volume_db,
		-40.0, 0.0,
		func(v: float):
			SettingsManager.set_bgm_volume(v)
			_bgm_lbl.text = "%d dB" % int(v),
		func(s: HSlider, lbl: Label):
			_bgm_slider = s
			_bgm_lbl    = lbl
	))

	# SFX 볼륨
	vbox.add_child(_make_slider_row(
		"SFX 볼륨",
		SettingsManager.sfx_volume_db,
		-40.0, 0.0,
		func(v: float):
			SettingsManager.set_sfx_volume(v)
			_sfx_lbl.text = "%d dB" % int(v),
		func(s: HSlider, lbl: Label):
			_sfx_slider = s
			_sfx_lbl    = lbl
	))

	vbox.add_child(_make_sep(C_BORDER))

	# 텍스트 속도
	vbox.add_child(_make_slider_row(
		"텍스트 속도",
		SettingsManager.text_speed,
		0.25, 3.0,
		func(v: float):
			SettingsManager.set_text_speed(v)
			_speed_lbl.text = _speed_label(v),
		func(s: HSlider, lbl: Label):
			_speed_slider = s
			_speed_lbl    = lbl,
		true
	))

	vbox.add_child(_make_sep(C_BORDER))

	# 언어 (스캐폴딩)
	var lang_row := HBoxContainer.new()
	lang_row.add_theme_constant_override("separation", 18)
	vbox.add_child(lang_row)

	var lang_key := Label.new()
	lang_key.text = "언어 (Language)"
	lang_key.add_theme_font_size_override("font_size", 15)
	lang_key.add_theme_color_override("font_color", C_MUTED)
	lang_key.custom_minimum_size.x = 200
	lang_row.add_child(lang_key)

	var lang_val := Label.new()
	lang_val.text = "한국어  ·  (추후 언어 선택 지원 예정)"
	lang_val.add_theme_font_size_override("font_size", 14)
	lang_val.add_theme_color_override("font_color", Color(0.55, 0.55, 0.65))
	lang_row.add_child(lang_val)

	vbox.add_child(_make_sep(C_BORDER))

	# 저장 + 닫기 버튼
	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_row)

	var save_btn := Button.new()
	save_btn.text = "저장 후 메뉴로"
	save_btn.custom_minimum_size = Vector2(200, 44)
	save_btn.add_theme_font_size_override("font_size", 15)
	save_btn.add_theme_color_override("font_color", C_GOLD)
	save_btn.add_theme_stylebox_override("normal",  _make_style(Color(0.08, 0.10, 0.07), C_BORDER_G, 1, 12))
	save_btn.add_theme_stylebox_override("hover",   _make_style(Color(0.12, 0.15, 0.09), C_GOLD, 1, 12))
	save_btn.add_theme_stylebox_override("pressed", _make_style(Color(0.06, 0.08, 0.05), C_GOLD, 2, 12))
	save_btn.pressed.connect(_on_save_and_back)
	btn_row.add_child(save_btn)

	var reset_btn := Button.new()
	reset_btn.text = "기본값으로 초기화"
	reset_btn.custom_minimum_size = Vector2(200, 44)
	reset_btn.add_theme_font_size_override("font_size", 14)
	reset_btn.add_theme_color_override("font_color", Color(0.72, 0.48, 0.48))
	reset_btn.add_theme_stylebox_override("normal",  _make_style(Color(0.08, 0.06, 0.06), C_BORDER, 1, 12))
	reset_btn.add_theme_stylebox_override("hover",   _make_style(Color(0.12, 0.08, 0.08), Color(0.55, 0.24, 0.24), 1, 12))
	reset_btn.pressed.connect(_on_reset_defaults)
	btn_row.add_child(reset_btn)


func _build_top_bar() -> Control:
	var bar := PanelContainer.new()
	bar.custom_minimum_size.y = 56
	var bar_style := StyleBoxFlat.new()
	bar_style.bg_color = Color(0.055, 0.065, 0.105)
	bar_style.border_color = C_BORDER_G
	bar_style.border_width_bottom = 1
	bar.add_theme_stylebox_override("panel", bar_style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",  16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top",    8)
	margin.add_theme_constant_override("margin_bottom", 8)
	bar.add_child(margin)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 14)
	margin.add_child(hbox)

	var back_btn := Button.new()
	back_btn.text = "◀  메뉴"
	back_btn.add_theme_font_size_override("font_size", 13)
	back_btn.custom_minimum_size.x = 88
	back_btn.add_theme_stylebox_override("normal",  _make_style(Color(0.08, 0.09, 0.15), C_BORDER, 1, 8))
	back_btn.add_theme_stylebox_override("hover",   _make_style(Color(0.12, 0.14, 0.22), C_BORDER_G, 1, 8))
	back_btn.add_theme_stylebox_override("pressed", _make_style(Color(0.06, 0.07, 0.12), C_GOLD, 1, 8))
	back_btn.pressed.connect(func():
		SettingsManager.save_settings()
		SceneTransition.fade_to("res://scenes/MainMenu.tscn")
	)
	hbox.add_child(back_btn)

	var title_lbl := Label.new()
	title_lbl.text = "설정  ·  SETTINGS"
	title_lbl.add_theme_font_size_override("font_size", 20)
	title_lbl.add_theme_color_override("font_color", C_GOLD)
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(title_lbl)

	return bar


func _make_slider_row(
		key: String, current_val: float,
		min_v: float, max_v: float,
		on_change: Callable, on_created: Callable,
		is_speed: bool = false) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)

	var key_lbl := Label.new()
	key_lbl.text = key
	key_lbl.add_theme_font_size_override("font_size", 15)
	key_lbl.add_theme_color_override("font_color", C_MUTED)
	key_lbl.custom_minimum_size.x = 200
	row.add_child(key_lbl)

	var slider := HSlider.new()
	slider.min_value = min_v
	slider.max_value = max_v
	slider.step      = 1.0 if not is_speed else 0.25
	slider.value     = current_val
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(slider)

	var val_lbl := Label.new()
	if is_speed:
		val_lbl.text = _speed_label(current_val)
	else:
		val_lbl.text = "%d dB" % int(current_val)
	val_lbl.add_theme_font_size_override("font_size", 14)
	val_lbl.add_theme_color_override("font_color", C_GOLD)
	val_lbl.custom_minimum_size.x = 80
	row.add_child(val_lbl)

	slider.value_changed.connect(on_change)
	on_created.call(slider, val_lbl)

	return row


func _speed_label(v: float) -> String:
	if v <= 0.5:
		return "빠름 (×%.2f)" % v
	elif v <= 1.1:
		return "기본 (×%.2f)" % v
	else:
		return "느림 (×%.2f)" % v


func _on_save_and_back() -> void:
	SettingsManager.save_settings()
	SceneTransition.fade_to("res://scenes/MainMenu.tscn")


func _on_reset_defaults() -> void:
	SettingsManager.set_bgm_volume(SettingsManager.DEFAULT_BGM_DB)
	SettingsManager.set_sfx_volume(SettingsManager.DEFAULT_SFX_DB)
	SettingsManager.set_text_speed(SettingsManager.DEFAULT_TEXT_SPD)
	if _bgm_slider != null:
		_bgm_slider.value = SettingsManager.DEFAULT_BGM_DB
	if _sfx_slider != null:
		_sfx_slider.value = SettingsManager.DEFAULT_SFX_DB
	if _speed_slider != null:
		_speed_slider.value = SettingsManager.DEFAULT_TEXT_SPD


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


func _add_gap(parent: Control, h: int) -> void:
	var gap := Control.new()
	gap.custom_minimum_size.y = h
	parent.add_child(gap)
