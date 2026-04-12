## Ending.gd — 총 별점 기반 3종 엔딩 씬
## 총 별점에 따라 "전설적 분석관" / "유능한 요원" / "경험 부족" 분기 표시
extends Control

# ── 팔레트 ───────────────────────────────────────────────────────────
const C_BG      := Color(0.04, 0.05, 0.09)
const C_PANEL   := Color(0.065, 0.075, 0.12)
const C_GOLD    := Color(0.93, 0.87, 0.40)
const C_MUTED   := Color(0.40, 0.40, 0.52)
const C_BORDER  := Color(0.18, 0.20, 0.32)
const C_BORDER_G := Color(0.50, 0.44, 0.15)

# ── 엔딩 분기 데이터 ─────────────────────────────────────────────────
# 기준: 15개 레벨(챕터 0~4) 총 별점 최대 45점
const ENDING_DATA := [
	{
		"min_stars"   : 40,
		"rank"        : "전설적 분석관",
		"rank_en"     : "LEGENDARY CRYPTANALYST",
		"rank_color"  : Color(1.0, 0.88, 0.22),
		"border_color": Color(0.85, 0.72, 0.18),
		"text"        : "당신의 분석은 블레츨리 파크 역사에 기록될 것입니다.\n\n" +
						"모든 교신이 해독됐습니다. 단 한 건의 오류도 없이.\n" +
						"처칠 수상은 당신의 보고서를 직접 읽었으며,\n" +
						"'이 나라에서 가장 가치 있는 정보 자산'이라 평했습니다.\n\n" +
						"전쟁은 끝나지 않았지만, 당신 덕분에\n" +
						"연합군은 한 발 앞서 나가고 있습니다.\n\n" +
						"— BLETCHLEY PARK, 1942년 12월 —",
	},
	{
		"min_stars"   : 25,
		"rank"        : "유능한 요원",
		"rank_en"     : "CAPABLE INTELLIGENCE OFFICER",
		"rank_color"  : Color(0.70, 0.88, 0.55),
		"border_color": Color(0.40, 0.65, 0.28),
		"text"        : "임무를 완수했습니다. 고난과 시행착오가 있었지만,\n" +
						"결국 당신은 모든 암호를 해독해냈습니다.\n\n" +
						"당신의 보고서는 작전 계획에 반영됐으며,\n" +
						"몇 건의 교신에서 적의 움직임을 미리 파악할 수 있었습니다.\n\n" +
						"더 많은 경험을 쌓으면, 당신은\n" +
						"이 곳에서 가장 뛰어난 분석관이 될 것입니다.\n\n" +
						"— BLETCHLEY PARK, 1942년 12월 —",
	},
	{
		"min_stars"   : 0,
		"rank"        : "경험 부족",
		"rank_en"     : "NOVICE ANALYST",
		"rank_color"  : Color(0.72, 0.60, 0.48),
		"border_color": Color(0.50, 0.40, 0.28),
		"text"        : "임무는 완수됐습니다. 그러나 대가가 있었습니다.\n\n" +
						"수많은 힌트와 재시도 끝에 겨우 답을 얻어냈습니다.\n" +
						"적은 우리보다 앞서 있었고, 일부 작전은 지연됐습니다.\n\n" +
						"하지만 포기하지 않고 끝까지 임무를 완수한 것,\n" +
						"그것만으로도 이미 충분히 가치 있습니다.\n\n" +
						"암호학은 하루아침에 익히는 기술이 아닙니다.\n" +
						"다시 도전해보십시오.\n\n" +
						"— BLETCHLEY PARK, 1942년 12월 —",
	},
]


func _ready() -> void:
	self.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	AudioManager.play_bgm("menu")
	_build_ui()


func _build_ui() -> void:
	var total: int = GameManager.total_stars()
	var ending_entry: Dictionary = ENDING_DATA[ENDING_DATA.size() - 1]
	for entry in ENDING_DATA:
		var e: Dictionary = entry
		if total >= e["min_stars"]:
			ending_entry = e
			break

	# 배경
	var bg := ColorRect.new()
	bg.color = C_BG
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(bg)

	var root_v := VBoxContainer.new()
	root_v.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	root_v.alignment = BoxContainer.ALIGNMENT_CENTER
	root_v.add_theme_constant_override("separation", 0)
	add_child(root_v)

	_add_gap(root_v, 40)

	# TOP SECRET 배너
	var stamp_lbl := Label.new()
	stamp_lbl.text = "◆   TOP SECRET  ·  BLETCHLEY PARK  ·  FINAL ASSESSMENT   ◆"
	stamp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stamp_lbl.add_theme_font_size_override("font_size", 11)
	stamp_lbl.add_theme_color_override("font_color", Color(0.72, 0.16, 0.16))
	root_v.add_child(stamp_lbl)

	_add_gap(root_v, 12)

	# 메인 패널
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.custom_minimum_size.x = 720
	var rank_color: Color = ending_entry["border_color"]
	var ps := StyleBoxFlat.new()
	ps.bg_color          = Color(0.055, 0.065, 0.105)
	ps.border_color      = rank_color
	ps.border_width_left = 3; ps.border_width_right  = 1
	ps.border_width_top  = 3; ps.border_width_bottom = 1
	ps.content_margin_left   = 52; ps.content_margin_right  = 52
	ps.content_margin_top    = 40; ps.content_margin_bottom = 40
	panel.add_theme_stylebox_override("panel", ps)
	root_v.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 18)
	panel.add_child(vbox)

	# 계급
	var rank_lbl := Label.new()
	rank_lbl.text = ending_entry["rank_en"]
	rank_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rank_lbl.add_theme_font_size_override("font_size", 14)
	rank_lbl.add_theme_color_override("font_color", ending_entry["rank_color"])
	vbox.add_child(rank_lbl)

	var rank_ko := Label.new()
	rank_ko.text = ending_entry["rank"]
	rank_ko.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rank_ko.add_theme_font_size_override("font_size", 36)
	rank_ko.add_theme_color_override("font_color", ending_entry["rank_color"])
	vbox.add_child(rank_ko)

	# 총 별점
	var star_total_lbl := Label.new()
	star_total_lbl.text = "총 별점: %d / 45" % total
	star_total_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	star_total_lbl.add_theme_font_size_override("font_size", 18)
	star_total_lbl.add_theme_color_override("font_color", C_GOLD)
	vbox.add_child(star_total_lbl)

	vbox.add_child(_make_sep(rank_color))

	# 엔딩 텍스트
	var text_lbl := Label.new()
	text_lbl.text = ending_entry["text"]
	text_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	text_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	text_lbl.add_theme_font_size_override("font_size", 15)
	text_lbl.add_theme_color_override("font_color", Color(0.84, 0.80, 0.70))
	vbox.add_child(text_lbl)

	vbox.add_child(_make_sep(rank_color))

	# 버튼
	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 24)
	vbox.add_child(btn_row)

	var menu_btn := Button.new()
	menu_btn.text = "◀  메뉴로"
	menu_btn.custom_minimum_size = Vector2(180, 44)
	menu_btn.add_theme_font_size_override("font_size", 15)
	menu_btn.add_theme_stylebox_override("normal",  _make_style(C_PANEL, C_BORDER, 1, 12))
	menu_btn.add_theme_stylebox_override("hover",   _make_style(C_PANEL, C_BORDER_G, 1, 12))
	menu_btn.pressed.connect(func(): SceneTransition.fade_to("res://scenes/MainMenu.tscn"))
	btn_row.add_child(menu_btn)

	var log_btn := Button.new()
	log_btn.text = "작전 일지 보기  ▶"
	log_btn.custom_minimum_size = Vector2(200, 44)
	log_btn.add_theme_font_size_override("font_size", 15)
	log_btn.add_theme_color_override("font_color", C_GOLD)
	log_btn.add_theme_stylebox_override("normal",  _make_style(C_PANEL, C_BORDER_G, 1, 12))
	log_btn.add_theme_stylebox_override("hover",   _make_style(C_PANEL, C_GOLD, 1, 12))
	log_btn.pressed.connect(func(): SceneTransition.fade_to("res://scenes/StoryLog.tscn"))
	btn_row.add_child(log_btn)

	_add_gap(root_v, 40)


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
