## StoryLog.gd — 작전 일지 씬
## 완료된 챕터의 작전 결과를 타임라인 형태로 표시한다.
extends Control

# ── 팔레트 ───────────────────────────────────────────────────────────
const C_BG      := Color(0.04, 0.05, 0.09)
const C_PANEL   := Color(0.065, 0.075, 0.12)
const C_GOLD    := Color(0.93, 0.87, 0.40)
const C_MUTED   := Color(0.40, 0.40, 0.52)
const C_BORDER  := Color(0.18, 0.20, 0.32)
const C_BORDER_G := Color(0.50, 0.44, 0.15)
const C_RED     := Color(0.70, 0.18, 0.18)


func _ready() -> void:
	self.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_build_ui()


func _build_ui() -> void:
	# 배경
	var bg := ColorRect.new()
	bg.color = C_BG
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(bg)

	# 루트 VBox
	var root_v := VBoxContainer.new()
	root_v.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	root_v.add_theme_constant_override("separation", 0)
	add_child(root_v)

	# 상단 바
	root_v.add_child(_build_top_bar())

	# 스크롤 영역
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root_v.add_child(scroll)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   48)
	margin.add_theme_constant_override("margin_right",  48)
	margin.add_theme_constant_override("margin_top",    32)
	margin.add_theme_constant_override("margin_bottom", 48)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(margin)

	var content_v := VBoxContainer.new()
	content_v.add_theme_constant_override("separation", 32)
	content_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(content_v)

	var logs: Array = GameManager.story_log
	if logs.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "완료된 작전이 없습니다."
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.add_theme_font_size_override("font_size", 16)
		empty_lbl.add_theme_color_override("font_color", C_MUTED)
		content_v.add_child(empty_lbl)
	else:
		for entry in logs:
			var entry_dict: Dictionary = entry
			content_v.add_child(_build_entry(entry_dict))


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
	back_btn.add_theme_stylebox_override("normal",
		_make_style(Color(0.08, 0.09, 0.15), C_BORDER, 1, 8))
	back_btn.add_theme_stylebox_override("hover",
		_make_style(Color(0.12, 0.14, 0.22), C_BORDER_G, 1, 8))
	back_btn.add_theme_stylebox_override("pressed",
		_make_style(Color(0.06, 0.07, 0.12), C_GOLD, 1, 8))
	back_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/MainMenu.tscn"))
	hbox.add_child(back_btn)

	var title_lbl := Label.new()
	title_lbl.text = "작전 일지  ·  OPERATION LOG"
	title_lbl.add_theme_font_size_override("font_size", 20)
	title_lbl.add_theme_color_override("font_color", C_GOLD)
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(title_lbl)

	var total_lbl := Label.new()
	total_lbl.text = "총 별점: %d" % GameManager.total_stars()
	total_lbl.add_theme_font_size_override("font_size", 14)
	total_lbl.add_theme_color_override("font_color", C_GOLD)
	hbox.add_child(total_lbl)

	return bar


func _build_entry(entry: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var ps := StyleBoxFlat.new()
	ps.bg_color           = Color(0.055, 0.062, 0.098)
	ps.border_color       = C_BORDER_G
	ps.border_width_left  = 3
	ps.border_width_right = 1
	ps.border_width_top   = 1
	ps.border_width_bottom = 1
	ps.content_margin_left   = 24
	ps.content_margin_right  = 24
	ps.content_margin_top    = 20
	ps.content_margin_bottom = 20
	panel.add_theme_stylebox_override("panel", ps)

	var main_v := VBoxContainer.new()
	main_v.add_theme_constant_override("separation", 10)
	panel.add_child(main_v)

	# ── 헤더 행 (챕터명 + 별점) ──
	var header_h := HBoxContainer.new()
	header_h.add_theme_constant_override("separation", 16)
	main_v.add_child(header_h)

	var subtitle  : String = entry.get("subtitle", "CHAPTER ?")
	var ch_title  : String = entry.get("title", "")
	var level_id  : int    = entry.get("level_id", 1)
	var difficulty: String = entry.get("difficulty", "")
	var level_tag := "  LEVEL %d" % level_id
	var diff_tag  := ("  ·  %s" % difficulty) if not difficulty.is_empty() else ""
	var title_lbl := Label.new()
	title_lbl.text = "[ %s%s%s ]  %s" % [subtitle, level_tag, diff_tag, ch_title]
	title_lbl.add_theme_font_size_override("font_size", 18)
	title_lbl.add_theme_color_override("font_color", C_GOLD)
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_h.add_child(title_lbl)

	var stars: int = entry.get("stars", 0)
	var star_lbl := Label.new()
	star_lbl.text = "★".repeat(stars) + "☆".repeat(3 - stars)
	star_lbl.add_theme_font_size_override("font_size", 22)
	star_lbl.add_theme_color_override("font_color", C_GOLD)
	header_h.add_child(star_lbl)

	# ── 구분선 ──
	var hsep := HSeparator.new()
	var sep_style := StyleBoxFlat.new()
	sep_style.bg_color = Color(0.40, 0.36, 0.14, 0.50)
	hsep.add_theme_stylebox_override("separator", sep_style)
	main_v.add_child(hsep)

	# ── 메타 행 (날짜 / 시각 / 주파수 / 발신→수신) ──
	var meta_h := HBoxContainer.new()
	meta_h.add_theme_constant_override("separation", 28)
	main_v.add_child(meta_h)

	var meta_items := [
		["일시",   "%s  %s" % [entry.get("date", ""), entry.get("time", "")]],
		["주파수", entry.get("frequency", "")],
		["발신",   entry.get("sender", "")],
		["수신",   entry.get("receiver", "")],
	]
	for item in meta_items:
		var item_arr: Array = item
		var pair_v := VBoxContainer.new()
		pair_v.add_theme_constant_override("separation", 2)
		meta_h.add_child(pair_v)

		var key_lbl := Label.new()
		key_lbl.text = item_arr[0]
		key_lbl.add_theme_font_size_override("font_size", 11)
		key_lbl.add_theme_color_override("font_color", C_MUTED)
		pair_v.add_child(key_lbl)

		var val_lbl := Label.new()
		val_lbl.text = item_arr[1]
		val_lbl.add_theme_font_size_override("font_size", 13)
		val_lbl.add_theme_color_override("font_color", Color(0.80, 0.78, 0.68))
		pair_v.add_child(val_lbl)

	# ── 해독 결과 ──
	var decoded_lbl := Label.new()
	decoded_lbl.text = "DECODED:  %s" % entry.get("decoded", "")
	decoded_lbl.add_theme_font_size_override("font_size", 15)
	decoded_lbl.add_theme_color_override("font_color", Color(0.38, 0.88, 0.58))
	main_v.add_child(decoded_lbl)

	# ── 작전 결과 텍스트 ──
	var log_text: String = entry.get("log_text", "")
	if not log_text.is_empty():
		var log_lbl := Label.new()
		log_lbl.text = log_text
		log_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		log_lbl.add_theme_font_size_override("font_size", 14)
		log_lbl.add_theme_color_override("font_color", Color(0.72, 0.70, 0.60))
		main_v.add_child(log_lbl)

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
