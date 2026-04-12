## MainMenu.gd — 타이틀 화면 (챕터/레벨 선택)
extends Control

const CHAPTERS := [
	{"id": 0, "title": "첫 교신",        "sub": "CHAPTER 0", "cipher": "시저 암호",      "levels": 3},
	{"id": 1, "title": "붉은 장미",       "sub": "CHAPTER 1", "cipher": "비즈네르 암호",  "levels": 3},
	{"id": 2, "title": "유령 네트워크",   "sub": "CHAPTER 2", "cipher": "단일 치환",      "levels": 3},
	{"id": 3, "title": "ENIGMA",          "sub": "CHAPTER 3", "cipher": "에니그마 머신",  "levels": 3},
	{"id": 4, "title": "최후의 암호",     "sub": "CHAPTER 4", "cipher": "플레이페어",     "levels": 3},
	{"id": 5, "title": "배신자의 암호",   "sub": "BONUS",     "cipher": "복합 암호",      "levels": 3},
]

const LEVEL_LABELS := ["입문", "보통", "심화"]

# ── 팔레트 ───────────────────────────────────────────────────────────
const C_BG       := Color(0.04, 0.05, 0.09)
const C_PANEL    := Color(0.065, 0.075, 0.12)
const C_INSET    := Color(0.05, 0.06, 0.10)
const C_GOLD     := Color(0.93, 0.87, 0.40)
const C_STAMP    := Color(0.72, 0.16, 0.16)
const C_MUTED    := Color(0.40, 0.40, 0.52)
const C_BORDER   := Color(0.18, 0.20, 0.32)
const C_BORDER_G := Color(0.50, 0.44, 0.15)

var _log_btn       : Button  = null
var _level_overlay : Control = null  # 레벨 선택 팝업
var _reset_overlay : Control = null  # 데이터 초기화 확인 팝업
var _end_btn       : Button  = null  # 엔딩 버튼 (모든 챕터 완료 시 활성화)
var _debug_buf     : String  = ""    # BOMBE 디버그 코드 입력 버퍼


func _ready() -> void:
	AudioManager.play_bgm("menu")
	_build_ui()


func _build_ui() -> void:
	var font_special_elite: FontFile = load("res://fonts/SpecialElite-Regular.ttf")
	var bg := ColorRect.new()
	bg.color = C_BG
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(bg)

	var outer := VBoxContainer.new()
	outer.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	outer.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(outer)

	var main_panel := PanelContainer.new()
	main_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	main_panel.custom_minimum_size.x = 760
	main_panel.add_theme_stylebox_override("panel", _make_style(C_PANEL, C_BORDER_G, 1, 0))
	outer.add_child(main_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   52)
	margin.add_theme_constant_override("margin_right",  52)
	margin.add_theme_constant_override("margin_top",    36)
	margin.add_theme_constant_override("margin_bottom", 36)
	main_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0)
	margin.add_child(vbox)

	# ─ TOP SECRET ─
	var stamp := Label.new()
	stamp.text = "◆   TOP SECRET  ·  BLETCHLEY PARK  ·  EYES ONLY   ◆"
	stamp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stamp.add_theme_font_override("font", font_special_elite)
	stamp.add_theme_font_size_override("font_size", 11)
	stamp.add_theme_color_override("font_color", C_STAMP)
	vbox.add_child(stamp)
	_add_gap(vbox, 8)
	vbox.add_child(_make_sep(C_BORDER_G))
	_add_gap(vbox, 14)

	# ─ 타이틀 ─
	var title := Label.new()
	title.text = "PROJECT ENIGMA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", font_special_elite)
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", C_GOLD)
	vbox.add_child(title)
	_add_gap(vbox, 4)

	var sub := Label.new()
	sub.text = "블레츨리 파크  —  암호 해독가 훈련 시뮬레이터  —  1942"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 14)
	sub.add_theme_color_override("font_color", C_MUTED)
	vbox.add_child(sub)
	_add_gap(vbox, 20)
	vbox.add_child(_make_sep(C_BORDER))
	_add_gap(vbox, 18)

	# ─ 임무 선택 헤더 ─
	var hdr_row := HBoxContainer.new()
	hdr_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(hdr_row)
	for txt in ["━━━━━━━━━  ", "임  무  선  택", "  ━━━━━━━━━"]:
		var lbl := Label.new()
		lbl.text = txt
		lbl.add_theme_color_override("font_color", C_MUTED if txt == "임  무  선  택" else C_BORDER)
		lbl.add_theme_font_size_override("font_size", 13)
		hdr_row.add_child(lbl)
	_add_gap(vbox, 12)

	# ─ 챕터 카드 구역 ─
	var ch_panel := PanelContainer.new()
	ch_panel.add_theme_stylebox_override("panel", _make_style(C_INSET, C_BORDER, 1, 0))
	vbox.add_child(ch_panel)

	var ch_margin := MarginContainer.new()
	ch_margin.add_theme_constant_override("margin_left",   16)
	ch_margin.add_theme_constant_override("margin_right",  16)
	ch_margin.add_theme_constant_override("margin_top",    14)
	ch_margin.add_theme_constant_override("margin_bottom", 14)
	ch_panel.add_child(ch_margin)

	var ch_vbox := VBoxContainer.new()
	ch_vbox.add_theme_constant_override("separation", 6)
	ch_margin.add_child(ch_vbox)

	for ch in CHAPTERS:
		var ch_dict: Dictionary = ch
		ch_vbox.add_child(_build_chapter_card(ch_dict))

	_add_gap(vbox, 10)

	# ─ 암호 알아보기 버튼 ─
	var museum_btn := Button.new()
	museum_btn.text = "◈  암호 알아보기  (CIPHER MUSEUM)"
	museum_btn.custom_minimum_size = Vector2(0, 44)
	museum_btn.add_theme_font_size_override("font_size", 14)
	museum_btn.add_theme_color_override("font_color", Color(0.62, 0.82, 0.90))
	var mb_sn := _make_style(Color(0.05, 0.08, 0.12), C_BORDER, 1, 0)
	mb_sn.content_margin_left = 22; mb_sn.content_margin_right = 22
	mb_sn.content_margin_top = 11;  mb_sn.content_margin_bottom = 11
	museum_btn.add_theme_stylebox_override("normal", mb_sn)
	var mb_sh := _make_style(Color(0.07, 0.12, 0.18), Color(0.30, 0.58, 0.70), 1, 0)
	mb_sh.content_margin_left = 22; mb_sh.content_margin_right = 22
	mb_sh.content_margin_top = 11;  mb_sh.content_margin_bottom = 11
	museum_btn.add_theme_stylebox_override("hover", mb_sh)
	museum_btn.add_theme_color_override("font_hover_color", Color(0.80, 0.94, 1.0))
	museum_btn.pressed.connect(func(): SceneTransition.fade_to("res://scenes/CipherMuseum.tscn"))
	vbox.add_child(museum_btn)

	_add_gap(vbox, 8)

	# ─ 작전 일지 버튼 ─
	var log_btn := Button.new()
	log_btn.text = "▶  작전 일지  (OPERATION LOG)"
	log_btn.custom_minimum_size = Vector2(0, 44)
	log_btn.add_theme_font_size_override("font_size", 14)
	log_btn.add_theme_color_override("font_color", Color(0.75, 0.72, 0.52))
	var lb_sn := _make_style(Color(0.06, 0.07, 0.11), C_BORDER, 1, 0)
	lb_sn.content_margin_left = 22; lb_sn.content_margin_right = 22
	lb_sn.content_margin_top = 11; lb_sn.content_margin_bottom = 11
	log_btn.add_theme_stylebox_override("normal", lb_sn)
	var lb_sh := _make_style(Color(0.09, 0.10, 0.17), C_BORDER_G, 1, 0)
	lb_sh.content_margin_left = 22; lb_sh.content_margin_right = 22
	lb_sh.content_margin_top = 11; lb_sh.content_margin_bottom = 11
	log_btn.add_theme_stylebox_override("hover", lb_sh)
	log_btn.add_theme_color_override("font_hover_color", C_GOLD)
	var lb_sd := _make_style(Color(0.05, 0.05, 0.08), Color(0.12, 0.12, 0.18), 1, 0)
	lb_sd.content_margin_left = 22; lb_sd.content_margin_right = 22
	lb_sd.content_margin_top = 11; lb_sd.content_margin_bottom = 11
	log_btn.add_theme_stylebox_override("disabled", lb_sd)
	log_btn.add_theme_color_override("font_disabled_color", Color(0.28, 0.28, 0.36))
	log_btn.disabled = GameManager.story_log.is_empty()
	log_btn.pressed.connect(func(): SceneTransition.fade_to("res://scenes/StoryLog.tscn"))
	vbox.add_child(log_btn)
	_log_btn = log_btn

	_add_gap(vbox, 8)

	# ─ 엔딩 버튼 (주요 15레벨 완료 시 활성화) ─
	var end_btn := Button.new()
	end_btn.text = "★  엔딩  (FINAL ASSESSMENT)"
	end_btn.custom_minimum_size = Vector2(0, 44)
	end_btn.add_theme_font_size_override("font_size", 14)
	end_btn.add_theme_color_override("font_color", C_GOLD)
	var eb_sn := _make_style(Color(0.07, 0.08, 0.05), Color(0.45, 0.38, 0.10), 1, 0)
	eb_sn.content_margin_left = 22; eb_sn.content_margin_right = 22
	eb_sn.content_margin_top = 11; eb_sn.content_margin_bottom = 11
	end_btn.add_theme_stylebox_override("normal", eb_sn)
	var eb_sh := _make_style(Color(0.11, 0.13, 0.07), C_GOLD, 1, 0)
	eb_sh.content_margin_left = 22; eb_sh.content_margin_right = 22
	eb_sh.content_margin_top = 11; eb_sh.content_margin_bottom = 11
	end_btn.add_theme_stylebox_override("hover", eb_sh)
	end_btn.add_theme_color_override("font_hover_color", C_GOLD)
	var eb_sd := _make_style(Color(0.05, 0.05, 0.08), Color(0.12, 0.12, 0.18), 1, 0)
	eb_sd.content_margin_left = 22; eb_sd.content_margin_right = 22
	eb_sd.content_margin_top = 11; eb_sd.content_margin_bottom = 11
	end_btn.add_theme_stylebox_override("disabled", eb_sd)
	end_btn.add_theme_color_override("font_disabled_color", Color(0.28, 0.28, 0.36))
	# 주요 15레벨(챕터 0~4) 모두 완료 여부 확인
	var all_main_complete := true
	for ch_i in range(5):
		for lv_i in range(1, 4):
			if not GameManager.is_level_complete(ch_i, lv_i):
				all_main_complete = false
				break
	end_btn.disabled = not all_main_complete
	end_btn.pressed.connect(func(): SceneTransition.fade_to("res://scenes/Ending.tscn"))
	vbox.add_child(end_btn)
	_end_btn = end_btn

	_add_gap(vbox, 8)

	# ─ 설정 버튼 ─
	var settings_btn := Button.new()
	settings_btn.text = "⚙  설정  (SETTINGS)"
	settings_btn.custom_minimum_size = Vector2(0, 44)
	settings_btn.add_theme_font_size_override("font_size", 14)
	settings_btn.add_theme_color_override("font_color", Color(0.62, 0.65, 0.78))
	var sb_sn := _make_style(Color(0.06, 0.07, 0.11), C_BORDER, 1, 0)
	sb_sn.content_margin_left = 22; sb_sn.content_margin_right = 22
	sb_sn.content_margin_top = 11; sb_sn.content_margin_bottom = 11
	settings_btn.add_theme_stylebox_override("normal", sb_sn)
	var sb_sh := _make_style(Color(0.09, 0.10, 0.17), Color(0.40, 0.44, 0.62), 1, 0)
	sb_sh.content_margin_left = 22; sb_sh.content_margin_right = 22
	sb_sh.content_margin_top = 11; sb_sh.content_margin_bottom = 11
	settings_btn.add_theme_stylebox_override("hover", sb_sh)
	settings_btn.add_theme_color_override("font_hover_color", Color(0.80, 0.84, 1.0))
	settings_btn.pressed.connect(func(): SceneTransition.fade_to("res://scenes/Settings.tscn"))
	vbox.add_child(settings_btn)

	_add_gap(vbox, 8)

	# ─ 종료 버튼 ─
	var quit_btn := Button.new()
	quit_btn.text = "✕  게임 종료  (QUIT)"
	quit_btn.custom_minimum_size = Vector2(0, 44)
	quit_btn.add_theme_font_size_override("font_size", 14)
	quit_btn.add_theme_color_override("font_color", Color(0.70, 0.35, 0.35))
	var qb_sn := _make_style(Color(0.07, 0.05, 0.05), Color(0.28, 0.14, 0.14), 1, 0)
	qb_sn.content_margin_left = 22; qb_sn.content_margin_right = 22
	qb_sn.content_margin_top = 11;  qb_sn.content_margin_bottom = 11
	quit_btn.add_theme_stylebox_override("normal", qb_sn)
	var qb_sh := _make_style(Color(0.12, 0.07, 0.07), Color(0.55, 0.22, 0.22), 1, 0)
	qb_sh.content_margin_left = 22; qb_sh.content_margin_right = 22
	qb_sh.content_margin_top = 11;  qb_sh.content_margin_bottom = 11
	quit_btn.add_theme_stylebox_override("hover", qb_sh)
	quit_btn.add_theme_color_override("font_hover_color", Color(1.0, 0.50, 0.50))
	quit_btn.pressed.connect(func(): get_tree().quit())
	vbox.add_child(quit_btn)

	_add_gap(vbox, 20)
	vbox.add_child(_make_sep(C_BORDER))
	_add_gap(vbox, 10)

	# ─ Footer: 버전 + 초기화 ─
	var footer_h := HBoxContainer.new()
	footer_h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(footer_h)

	var ver := Label.new()
	ver.text = "Phase 13  ·  Godot 4.6"
	ver.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ver.add_theme_font_size_override("font_size", 11)
	ver.add_theme_color_override("font_color", Color(0.23, 0.23, 0.30))
	footer_h.add_child(ver)

	var reset_btn := Button.new()
	reset_btn.text = "데이터 초기화"
	reset_btn.add_theme_font_size_override("font_size", 11)
	reset_btn.add_theme_color_override("font_color", Color(0.42, 0.22, 0.22))
	reset_btn.add_theme_stylebox_override("normal",  _make_style(Color(0.06, 0.05, 0.05), Color(0.30, 0.14, 0.14), 1, 8))
	reset_btn.add_theme_stylebox_override("hover",   _make_style(Color(0.10, 0.07, 0.07), Color(0.55, 0.20, 0.20), 1, 8))
	reset_btn.add_theme_stylebox_override("pressed", _make_style(Color(0.08, 0.05, 0.05), Color(0.70, 0.18, 0.18), 1, 8))
	reset_btn.pressed.connect(_on_reset_pressed)
	footer_h.add_child(reset_btn)

	# ─ 오버레이 ─
	_level_overlay = _build_level_overlay()
	add_child(_level_overlay)
	_reset_overlay = _build_reset_confirm()
	add_child(_reset_overlay)


func _build_chapter_card(ch: Dictionary) -> Control:
	var ch_id    : int    = ch["id"]
	var ch_title : String = ch["title"]
	var ch_sub   : String = ch["sub"]
	var cipher   : String = ch["cipher"]
	var lv_count : int    = ch["levels"]

	# 챕터 레벨 1이 해금돼 있어야 카드가 활성화됨
	var unlocked := GameManager.is_level_unlocked(ch_id, 1)
	var any_complete := GameManager.is_chapter_complete(ch_id)

	# ── 카드 버튼 ──
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0, 60)
	btn.add_theme_font_size_override("font_size", 17)

	var sn := _make_style(Color(0.07, 0.09, 0.14), C_BORDER, 1, 0)
	sn.content_margin_left = 20; sn.content_margin_right = 20
	sn.content_margin_top = 14; sn.content_margin_bottom = 14
	btn.add_theme_stylebox_override("normal", sn)

	var sh := _make_style(Color(0.10, 0.13, 0.21), C_BORDER_G, 1, 0)
	sh.content_margin_left = 20; sh.content_margin_right = 20
	sh.content_margin_top = 14; sh.content_margin_bottom = 14
	btn.add_theme_stylebox_override("hover", sh)
	btn.add_theme_color_override("font_hover_color", C_GOLD)

	var sd := _make_style(Color(0.05, 0.05, 0.08), Color(0.12, 0.12, 0.18), 1, 0)
	sd.content_margin_left = 20; sd.content_margin_right = 20
	sd.content_margin_top = 14; sd.content_margin_bottom = 14
	btn.add_theme_stylebox_override("disabled", sd)
	btn.add_theme_color_override("font_disabled_color", Color(0.28, 0.28, 0.36))

	if unlocked:
		# 완료된 레벨 별점 합산 표시
		var stars_total := 0
		var completed   := 0
		for lv in range(1, lv_count + 1):
			if GameManager.is_level_complete(ch_id, lv):
				stars_total += GameManager.get_level_stars(ch_id, lv)
				completed   += 1
		var progress_str := "%d / %d  ·  %d★" % [completed, lv_count, stars_total] if completed > 0 else "미시작"
		btn.text = "[  %s  —  %s  ]    %s  ( %s )" % [ch_sub, ch_title, cipher, progress_str]
		btn.disabled = false
		btn.pressed.connect(func(): _open_level_overlay(ch_id, ch_title, ch_sub, lv_count))
	else:
		btn.text = "[  %s  —  %s  ]    ░░░" % [ch_sub, ch_title]
		btn.disabled = true

	return btn


# ── 레벨 선택 오버레이 ─────────────────────────────────────────────────

func _build_level_overlay() -> Control:
	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.78)
	overlay.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.visible = false

	var outer := VBoxContainer.new()
	outer.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	outer.alignment = BoxContainer.ALIGNMENT_CENTER
	overlay.add_child(outer)

	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.custom_minimum_size = Vector2(580, 0)
	panel.add_theme_stylebox_override("panel", _make_style(Color(0.055, 0.065, 0.105), C_BORDER_G, 1, 0))
	outer.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   36)
	margin.add_theme_constant_override("margin_right",  36)
	margin.add_theme_constant_override("margin_top",    28)
	margin.add_theme_constant_override("margin_bottom", 28)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	margin.add_child(vbox)

	# 제목 라벨 (나중에 텍스트 교체)
	var title_lbl := Label.new()
	title_lbl.name = "TitleLbl"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 18)
	title_lbl.add_theme_color_override("font_color", C_GOLD)
	vbox.add_child(title_lbl)

	vbox.add_child(_make_sep(C_BORDER_G))

	# 레벨 버튼 행
	var btn_row := HBoxContainer.new()
	btn_row.name = "BtnRow"
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 16)
	vbox.add_child(btn_row)

	# 닫기 버튼
	var close_btn := Button.new()
	close_btn.text = "닫기"
	close_btn.custom_minimum_size = Vector2(100, 36)
	close_btn.add_theme_font_size_override("font_size", 13)
	close_btn.add_theme_stylebox_override("normal",  _make_style(Color(0.07, 0.08, 0.12), C_BORDER, 1, 10))
	close_btn.add_theme_stylebox_override("hover",   _make_style(Color(0.11, 0.13, 0.20), C_BORDER_G, 1, 10))
	close_btn.add_theme_color_override("font_color", C_MUTED)
	close_btn.pressed.connect(func(): overlay.visible = false)
	var close_row := HBoxContainer.new()
	close_row.alignment = BoxContainer.ALIGNMENT_CENTER
	close_row.add_child(close_btn)
	vbox.add_child(close_row)

	return overlay


func _open_level_overlay(ch_id: int, ch_title: String, ch_sub: String, lv_count: int) -> void:
	var title_lbl : Label       = _level_overlay.find_child("TitleLbl", true, false)
	var btn_row   : HBoxContainer = _level_overlay.find_child("BtnRow", true, false)

	if title_lbl != null:
		title_lbl.text = "[ %s  —  %s ]  레벨 선택" % [ch_sub, ch_title]

	if btn_row != null:
		for child in btn_row.get_children():
			child.queue_free()

		for lv in range(1, lv_count + 1):
			var lv_btn := _build_level_btn(ch_id, lv)
			btn_row.add_child(lv_btn)

	_level_overlay.visible = true


func _build_level_btn(ch_id: int, lv: int) -> Button:
	var unlocked := GameManager.is_level_unlocked(ch_id, lv)
	var complete  := GameManager.is_level_complete(ch_id, lv)
	var stars     := GameManager.get_level_stars(ch_id, lv)

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(148, 110)

	var diff_lbl : String = LEVEL_LABELS[lv - 1] if lv <= LEVEL_LABELS.size() else "LEVEL %d" % lv
	var star_str := "★".repeat(stars) + "☆".repeat(3 - stars) if complete else "─ ─ ─"
	btn.text = "LEVEL  %d\n%s\n\n%s" % [lv, diff_lbl, star_str]
	btn.add_theme_font_size_override("font_size", 15)

	if unlocked:
		var sn := _make_style(Color(0.07, 0.09, 0.14), C_BORDER_G if complete else C_BORDER, 1, 12)
		btn.add_theme_stylebox_override("normal", sn)
		btn.add_theme_stylebox_override("hover",  _make_style(Color(0.12, 0.15, 0.24), C_GOLD, 1, 12))
		btn.add_theme_color_override("font_color", C_GOLD if complete else Color(0.80, 0.78, 0.62))
		btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 0.85))
		btn.disabled = false
		btn.pressed.connect(func():
			_level_overlay.visible = false
			GameManager.current_chapter_id = ch_id
			GameManager.current_level_id   = lv
			SceneTransition.fade_to("res://scenes/Radio.tscn")
		)
	else:
		var sd := _make_style(Color(0.05, 0.05, 0.08), Color(0.12, 0.12, 0.18), 1, 12)
		btn.add_theme_stylebox_override("normal", sd)
		btn.add_theme_stylebox_override("disabled", sd)
		btn.add_theme_color_override("font_disabled_color", Color(0.28, 0.28, 0.36))
		btn.text = "LEVEL  %d\n%s\n\n[잠금]" % [lv, diff_lbl]
		btn.disabled = true

	return btn


# ── 초기화 확인 팝업 ────────────────────────────────────────────────────

func _on_reset_pressed() -> void:
	_reset_overlay.visible = true


func _build_reset_confirm() -> Control:
	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.72)
	overlay.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.visible = false

	var outer := VBoxContainer.new()
	outer.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	outer.alignment = BoxContainer.ALIGNMENT_CENTER
	overlay.add_child(outer)

	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.custom_minimum_size = Vector2(440, 0)
	panel.add_theme_stylebox_override("panel", _make_style(Color(0.06, 0.05, 0.05), Color(0.55, 0.18, 0.18), 1, 0))
	outer.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   32)
	margin.add_theme_constant_override("margin_right",  32)
	margin.add_theme_constant_override("margin_top",    28)
	margin.add_theme_constant_override("margin_bottom", 28)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	margin.add_child(vbox)

	var title_lbl := Label.new()
	title_lbl.text = "[ 데이터 초기화 ]"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 17)
	title_lbl.add_theme_color_override("font_color", Color(0.80, 0.28, 0.28))
	vbox.add_child(title_lbl)

	var body_lbl := Label.new()
	body_lbl.text = "모든 진행 기록, 별점, 작전 일지가 삭제됩니다.\n이 작업은 되돌릴 수 없습니다."
	body_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	body_lbl.add_theme_font_size_override("font_size", 14)
	body_lbl.add_theme_color_override("font_color", Color(0.72, 0.68, 0.60))
	vbox.add_child(body_lbl)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_row)

	var cancel_btn := Button.new()
	cancel_btn.text = "취소"
	cancel_btn.custom_minimum_size = Vector2(130, 40)
	cancel_btn.add_theme_font_size_override("font_size", 14)
	cancel_btn.add_theme_stylebox_override("normal",  _make_style(Color(0.08, 0.09, 0.15), C_BORDER, 1, 12))
	cancel_btn.add_theme_stylebox_override("hover",   _make_style(Color(0.12, 0.14, 0.22), C_BORDER_G, 1, 12))
	cancel_btn.pressed.connect(func(): overlay.visible = false)
	btn_row.add_child(cancel_btn)

	var confirm_btn := Button.new()
	confirm_btn.text = "초기화 확인"
	confirm_btn.custom_minimum_size = Vector2(130, 40)
	confirm_btn.add_theme_font_size_override("font_size", 14)
	confirm_btn.add_theme_color_override("font_color", Color(0.88, 0.36, 0.36))
	confirm_btn.add_theme_stylebox_override("normal", _make_style(Color(0.10, 0.05, 0.05), Color(0.50, 0.18, 0.18), 1, 12))
	confirm_btn.add_theme_stylebox_override("hover",  _make_style(Color(0.16, 0.07, 0.07), Color(0.72, 0.22, 0.22), 1, 12))
	confirm_btn.pressed.connect(func():
		GameManager.reset_save()
		overlay.visible = false
		# 씬 새로고침으로 버튼 상태 갱신
		SceneTransition.reload_scene()
	)
	btn_row.add_child(confirm_btn)

	return overlay


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


func _add_gap(parent: Control, height: int) -> void:
	var gap := Control.new()
	gap.custom_minimum_size.y = height
	parent.add_child(gap)


# ── 디버그: 메인 화면에서 BOMBE 타이핑 시 전 레벨 클리어 ──────────────

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed:
		return
	var ch: String = OS.get_keycode_string(event.keycode).to_upper()
	if ch.length() != 1:
		_debug_buf = ""
		return
	_debug_buf += ch
	if _debug_buf.length() > 5:
		_debug_buf = _debug_buf.right(5)
	if _debug_buf == "BOMBE":
		_debug_buf = ""
		_activate_debug_all()


func _activate_debug_all() -> void:
	for ch_i: int in range(6):
		for lv_i: int in range(1, 4):
			GameManager.level_stars["%d_%d" % [ch_i, lv_i]] = 1
	GameManager.save_game()
	SceneTransition.reload_scene()
