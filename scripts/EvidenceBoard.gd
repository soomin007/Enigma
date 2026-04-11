## EvidenceBoard.gd — 단서 보드 씬
## 단서 카드를 드래그해 배치하고, 연결 모드에서 카드 간 실을 연결한다.
## _draw()로 연결선을 그리며, 카드 클릭 시 내용 팝업을 표시한다.
extends Control

const CARD_SIZE     := Vector2(200, 128)
const BOARD_TOP     := 60.0
const CONNECT_COLOR := Color(0.78, 0.56, 0.28, 0.88)

# ── 팔레트 ───────────────────────────────────────────────────────────
const C_BG       := Color(0.16, 0.12, 0.08)   # 코르크 배경 (따뜻한 갈색)
const C_PANEL    := Color(0.07, 0.08, 0.12)
const C_GOLD     := Color(0.93, 0.87, 0.40)
const C_BORDER   := Color(0.20, 0.22, 0.32)
const C_BORDER_G := Color(0.50, 0.44, 0.15)
const C_MUTED    := Color(0.38, 0.36, 0.26)

# 카드 타입별 테두리 색상
const TYPE_COLORS := {
	"document"      : Color(0.28, 0.42, 0.68),   # 청색 — 공문서
	"torn_paper"    : Color(0.62, 0.52, 0.32),   # 황갈 — 야전 쪽지
	"photo"         : Color(0.42, 0.44, 0.54),   # 회색 — 사진
	"interrogation" : Color(0.62, 0.28, 0.28),   # 적색 — 심문 기록
	"map"           : Color(0.28, 0.58, 0.40),   # 녹색 — 지도
}
const TYPE_LABELS := {
	"document"      : "[ 공문서 ]",
	"torn_paper"    : "[ 쪽지  ]",
	"photo"         : "[ 사진  ]",
	"interrogation" : "[ 심문  ]",
	"map"           : "[ 지도  ]",
}

var _clues       : Array = []   # 챕터 단서 딕셔너리 배열
var _cards       : Array = []   # Control 노드 배열 (카드)
var _connections : Array = []   # [int, int] 쌍 배열 (연결된 카드 인덱스)

var _dragging_idx  : int     = -1
var _drag_offset   : Vector2 = Vector2.ZERO
var _drag_moved    : bool    = false

var _connect_mode  : bool = false
var _connect_first : int  = -1
var _connect_btn   : Button

var _popup_overlay   : Control
var _popup_title_lbl : Label   # 직접 참조 — get_node() 경로 사용 안 함
var _popup_body_lbl  : Label

var _pin_layer : Control   # 카드보다 위에 렌더되는 압정 전용 오버레이


# ── 압정 오버레이 (카드 위에 렌더하기 위해 카드 추가 이후에 자식으로 삽입) ──
class PinLayer extends Control:
	var board: Control   # EvidenceBoard 인스턴스 참조

	func _draw() -> void:
		if board == null:
			return
		var cs := Vector2(200.0, 128.0)   # CARD_SIZE 와 동일
		for card in board._cards:
			var pin_x: float = card.position.x + cs.x * 0.5
			var pin_y: float = card.position.y - 2.0
			# 핀 그림자
			draw_circle(Vector2(pin_x + 1.0, pin_y + 2.0), 6.0, Color(0.0, 0.0, 0.0, 0.30))
			# 핀 머리 (빨강)
			draw_circle(Vector2(pin_x, pin_y), 6.0, Color(0.72, 0.14, 0.14))
			draw_circle(Vector2(pin_x - 1.0, pin_y - 1.0), 2.5, Color(0.90, 0.40, 0.40, 0.70))
			# 핀 몸통 (금속)
			draw_line(Vector2(pin_x, pin_y + 4.0), Vector2(pin_x, pin_y + 10.0),
					  Color(0.52, 0.52, 0.58), 1.5)


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	_clues = GameManager.current_chapter.get("clues", [])
	var extra_clues: Array = GameManager.current_chapter.get("extra_clues", [])
	_clues = _clues + extra_clues   # 레드 헤링 포함 (플레이어가 직접 걸러내야 함)
	_build_ui()
	_place_cards()


# ── 커스텀 드로우: 배경 + 연결선 ──────────────────────────────────────

func _draw() -> void:
	# 배경은 _draw()에서 직접 그림 — ColorRect 자식을 쓰면 자식이 위에 렌더되어 연결선을 덮어버림
	var vp := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, vp), C_BG)

	# 코르크 결 — 가로 방향 미세 줄 (자연스러운 나뭇결 느낌)
	var board_area := Rect2(0.0, BOARD_TOP, vp.x, vp.y - BOARD_TOP)
	var y_grain := board_area.position.y
	while y_grain < board_area.end.y:
		var alpha := 0.04 + (sin(y_grain * 0.37) * 0.5 + 0.5) * 0.04
		draw_line(Vector2(0.0, y_grain), Vector2(vp.x, y_grain),
				  Color(0.0, 0.0, 0.0, alpha), 1.0)
		y_grain += 4.0

	# 보드 테두리 (안쪽 프레임)
	draw_rect(Rect2(4, BOARD_TOP + 2, vp.x - 8, vp.y - BOARD_TOP - 6),
			  Color(0.10, 0.07, 0.04, 0.60), false, 3.0)
	draw_rect(Rect2(8, BOARD_TOP + 6, vp.x - 16, vp.y - BOARD_TOP - 14),
			  Color(0.25, 0.18, 0.10, 0.30), false, 1.5)

	# 연결선
	for pair in _connections:
		var a_idx: int = pair[0]
		var b_idx: int = pair[1]
		if a_idx >= _cards.size() or b_idx >= _cards.size():
			continue
		var card_a: Control = _cards[a_idx]
		var card_b: Control = _cards[b_idx]
		var pa := card_a.position + CARD_SIZE * 0.5
		var pb := card_b.position + CARD_SIZE * 0.5
		# 실 그림자
		draw_line(pa + Vector2(1.5, 1.5), pb + Vector2(1.5, 1.5),
				  Color(0.0, 0.0, 0.0, 0.35), 3.5)
		draw_line(pa, pb, CONNECT_COLOR, 2.2)
		# 실 고정점 (양쪽 끝)
		draw_circle(pa, 3.5, CONNECT_COLOR)
		draw_circle(pb, 3.5, CONNECT_COLOR)


# ── UI 구성 ──────────────────────────────────────────────────────────

func _build_ui() -> void:
	# 배경은 _draw()에서 직접 처리 (ColorRect 자식은 연결선 위를 덮으므로 사용 금지)

	# 상단 바
	var top_bar := PanelContainer.new()
	top_bar.set_anchors_and_offsets_preset(PRESET_TOP_WIDE)
	top_bar.custom_minimum_size.y = BOARD_TOP

	var bar_style := StyleBoxFlat.new()
	bar_style.bg_color = Color(0.06, 0.07, 0.11)
	bar_style.border_color = C_BORDER_G
	bar_style.border_width_bottom = 1
	top_bar.add_theme_stylebox_override("panel", bar_style)
	add_child(top_bar)

	var bar_margin := MarginContainer.new()
	bar_margin.add_theme_constant_override("margin_left",  14)
	bar_margin.add_theme_constant_override("margin_right", 14)
	bar_margin.add_theme_constant_override("margin_top",    8)
	bar_margin.add_theme_constant_override("margin_bottom", 8)
	top_bar.add_child(bar_margin)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	bar_margin.add_child(hbox)

	# 뒤로 버튼
	var back_btn := Button.new()
	back_btn.text = "◀  메뉴"
	back_btn.add_theme_font_size_override("font_size", 13)
	back_btn.custom_minimum_size.x = 88
	back_btn.add_theme_stylebox_override("normal",  _make_style(Color(0.08, 0.09, 0.15), C_BORDER, 1, 8))
	back_btn.add_theme_stylebox_override("hover",   _make_style(Color(0.12, 0.14, 0.22), C_BORDER_G, 1, 8))
	back_btn.add_theme_stylebox_override("pressed", _make_style(Color(0.06, 0.07, 0.12), C_GOLD, 1, 8))
	back_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/MainMenu.tscn"))
	hbox.add_child(back_btn)

	# 타이틀
	var title_lbl := Label.new()
	title_lbl.text = "단서 보드  ·  EVIDENCE BOARD"
	title_lbl.add_theme_font_size_override("font_size", 17)
	title_lbl.add_theme_color_override("font_color", C_GOLD)
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(title_lbl)

	# 연결 모드 버튼
	_connect_btn = Button.new()
	_connect_btn.text = "연결 모드  OFF"
	_connect_btn.add_theme_font_size_override("font_size", 13)
	_connect_btn.toggle_mode = true
	_connect_btn.add_theme_stylebox_override("normal",   _make_style(Color(0.08, 0.09, 0.15), C_BORDER, 1, 10))
	_connect_btn.add_theme_stylebox_override("hover",    _make_style(Color(0.10, 0.12, 0.20), C_BORDER_G, 1, 10))
	_connect_btn.add_theme_stylebox_override("pressed",  _make_style(Color(0.10, 0.18, 0.10), Color(0.30, 0.72, 0.30), 1, 10))
	_connect_btn.toggled.connect(_on_connect_mode_toggled)
	hbox.add_child(_connect_btn)

	# 해독기로 버튼
	var proceed_btn := Button.new()
	proceed_btn.text = "해독기로  →"
	proceed_btn.add_theme_font_size_override("font_size", 15)
	proceed_btn.add_theme_stylebox_override("normal",  _make_style(Color(0.10, 0.12, 0.08), C_BORDER_G, 1, 12))
	proceed_btn.add_theme_stylebox_override("hover",   _make_style(Color(0.15, 0.18, 0.10), C_GOLD, 1, 12))
	proceed_btn.add_theme_stylebox_override("pressed", _make_style(Color(0.08, 0.10, 0.06), C_GOLD, 2, 12))
	proceed_btn.add_theme_color_override("font_color", C_GOLD)
	proceed_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ChapterView.tscn"))
	hbox.add_child(proceed_btn)

	# 안내 라벨 (보드 상단)
	var guide_lbl := Label.new()
	guide_lbl.text = "드래그: 위치 변경   ·   클릭: 내용 열람   ·   연결 모드 ON → 두 카드를 순서대로 클릭해 실로 연결"
	guide_lbl.position = Vector2(16, BOARD_TOP + 6)
	guide_lbl.add_theme_font_size_override("font_size", 11)
	guide_lbl.add_theme_color_override("font_color", C_MUTED)
	add_child(guide_lbl)

	# 팝업 오버레이는 _place_cards() 이후에 추가 (카드·핀보다 위에 렌더되어야 함)
	_popup_overlay = _build_popup()


func _place_cards() -> void:
	var cols    := 4
	var start_x := 32.0
	var start_y := BOARD_TOP + 42.0
	var pad_x   := 248.0
	var pad_y   := 170.0

	for i in _clues.size():
		var clue: Dictionary = _clues[i]
		var col := i % cols
		var row := i / cols
		var jitter_x := randf_range(-10.0, 10.0)
		var jitter_y := randf_range(-7.0, 7.0)
		var pos := Vector2(start_x + col * pad_x + jitter_x, start_y + row * pad_y + jitter_y)
		_cards.append(_make_card(clue, pos))

	# 카드를 모두 추가한 후에 핀 레이어를 올림 — 나중에 추가된 자식이 위에 렌더됨
	var pin := PinLayer.new()
	pin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	pin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pin.board = self
	add_child(pin)
	_pin_layer = pin

	# 팝업 오버레이를 가장 마지막에 추가 — 카드·핀 위에서 렌더됨
	add_child(_popup_overlay)


func _make_card(clue: Dictionary, pos: Vector2) -> Control:
	var clue_type: String = clue.get("type", "")
	var type_color: Color = TYPE_COLORS.get(clue_type, C_BORDER)
	var type_label: String = TYPE_LABELS.get(clue_type, "[ ? ]")

	# ── 타입별 스타일 파라미터 ──
	var bg_color      : Color
	var border_l      : int
	var border_t      : int
	var border_r      : int
	var border_b      : int
	var border_col    : Color
	var rotation_deg  : float
	var title_color   : Color
	var hint_text     : String
	var hint_color    : Color

	match clue_type:
		"document":
			# 공문서: 크림색, 두꺼운 좌측 청색 선
			bg_color   = Color(0.91, 0.87, 0.76)
			border_col = type_color
			border_l   = 5;  border_t = 2;  border_r = 1;  border_b = 1
			rotation_deg = randf_range(-1.5, 1.5)
			title_color  = Color(0.18, 0.14, 0.09)
			hint_text    = "열람"
			hint_color   = Color(0.42, 0.37, 0.28)
		"torn_paper":
			# 쪽지: 밝은 크림, 큰 기울기, 얇은 테두리
			bg_color   = Color(0.96, 0.93, 0.85)
			border_col = type_color
			border_l   = 1;  border_t = 1;  border_r = 1;  border_b = 2
			rotation_deg = randf_range(-4.5, 4.5)
			title_color  = Color(0.20, 0.16, 0.10)
			hint_text    = "· 클릭 ·"
			hint_color   = Color(0.50, 0.44, 0.30)
		"photo":
			# 사진: 폴라로이드 — 두꺼운 흰 테두리 + 회색 중앙
			bg_color   = Color(0.62, 0.60, 0.56)
			border_col = Color(0.94, 0.91, 0.86)
			border_l   = 7;  border_t = 7;  border_r = 7;  border_b = 12
			rotation_deg = randf_range(-3.5, 3.5)
			title_color  = Color(0.94, 0.91, 0.86)
			hint_text    = "[ 사진 ]"
			hint_color   = Color(0.82, 0.78, 0.70)
		"interrogation":
			# 심문 기록: 근백색, 두꺼운 상단 적색 선
			bg_color   = Color(0.91, 0.89, 0.86)
			border_col = type_color
			border_l   = 1;  border_t = 5;  border_r = 1;  border_b = 1
			rotation_deg = randf_range(-2.0, 2.0)
			title_color  = Color(0.18, 0.12, 0.12)
			hint_text    = "[ 기록 ]"
			hint_color   = type_color.darkened(0.3)
		_:
			bg_color   = Color(0.88, 0.84, 0.72)
			border_col = type_color.darkened(0.1)
			border_l   = 3;  border_t = 2;  border_r = 1;  border_b = 1
			rotation_deg = randf_range(-2.5, 2.5)
			title_color  = Color(0.16, 0.12, 0.08)
			hint_text    = "클릭해서 열람"
			hint_color   = Color(0.45, 0.40, 0.30)

	var card := PanelContainer.new()
	card.position     = pos
	card.custom_minimum_size = CARD_SIZE
	card.pivot_offset = CARD_SIZE * 0.5
	card.rotation_degrees = rotation_deg
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var card_style := StyleBoxFlat.new()
	card_style.bg_color            = bg_color
	card_style.border_color        = border_col
	card_style.border_width_left   = border_l
	card_style.border_width_right  = border_r
	card_style.border_width_top    = border_t
	card_style.border_width_bottom = border_b
	card_style.content_margin_left   = 10
	card_style.content_margin_right  = 9
	card_style.content_margin_top    = 9
	card_style.content_margin_bottom = 7
	card_style.shadow_color  = Color(0.0, 0.0, 0.0, 0.50)
	card_style.shadow_size   = 7
	card_style.shadow_offset = Vector2(3, 5)
	card.add_theme_stylebox_override("panel", card_style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(vbox)

	# 타입 배지
	var type_lbl := Label.new()
	type_lbl.text = type_label
	type_lbl.add_theme_font_size_override("font_size", 10)
	var badge_color : Color
	if clue_type == "photo":
		badge_color = Color(0.84, 0.80, 0.72)
	else:
		badge_color = type_color.darkened(0.15)
	type_lbl.add_theme_color_override("font_color", badge_color)
	type_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(type_lbl)

	# 구분선
	var sep := HSeparator.new()
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sep_style := StyleBoxFlat.new()
	sep_style.bg_color = border_col.darkened(0.1) if clue_type != "photo" else Color(0.78, 0.74, 0.68)
	sep.add_theme_stylebox_override("separator", sep_style)
	vbox.add_child(sep)

	# 카드 제목
	var title_lbl := Label.new()
	title_lbl.text = clue.get("title", "단서")
	title_lbl.add_theme_font_size_override("font_size", 12)
	title_lbl.add_theme_color_override("font_color", title_color)
	title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_lbl.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(title_lbl)

	# 클릭 안내
	var hint_lbl := Label.new()
	hint_lbl.text = hint_text
	hint_lbl.add_theme_font_size_override("font_size", 9)
	hint_lbl.add_theme_color_override("font_color", hint_color)
	hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint_lbl.size_flags_vertical  = Control.SIZE_EXPAND_FILL
	hint_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_BOTTOM
	hint_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(hint_lbl)

	add_child(card)
	return card


func _build_popup() -> Control:
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.78)
	overlay.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	overlay.visible = false
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	# PRESET_CENTER 금지 — VBox + SIZE_SHRINK_CENTER로 중앙 정렬
	var center_vbox := VBoxContainer.new()
	center_vbox.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	center_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	overlay.add_child(center_vbox)

	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.custom_minimum_size   = Vector2(540, 0)
	var popup_style := _make_style(Color(0.90, 0.86, 0.74), C_BORDER_G, 2, 0)
	popup_style.shadow_color  = Color(0.0, 0.0, 0.0, 0.50)
	popup_style.shadow_size   = 8
	popup_style.shadow_offset = Vector2(3, 5)
	panel.add_theme_stylebox_override("panel", popup_style)
	center_vbox.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   28)
	margin.add_theme_constant_override("margin_right",  28)
	margin.add_theme_constant_override("margin_top",    22)
	margin.add_theme_constant_override("margin_bottom", 22)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	_popup_title_lbl = Label.new()
	_popup_title_lbl.add_theme_font_size_override("font_size", 18)
	_popup_title_lbl.add_theme_color_override("font_color", Color(0.22, 0.15, 0.06))
	vbox.add_child(_popup_title_lbl)

	var sep := HSeparator.new()
	var sep_style := StyleBoxFlat.new()
	sep_style.bg_color = C_BORDER_G
	sep.add_theme_stylebox_override("separator", sep_style)
	vbox.add_child(sep)

	_popup_body_lbl = Label.new()
	_popup_body_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_popup_body_lbl.add_theme_font_size_override("font_size", 14)
	_popup_body_lbl.add_theme_color_override("font_color", Color(0.18, 0.14, 0.10))
	vbox.add_child(_popup_body_lbl)

	var close_btn := Button.new()
	close_btn.text = "[ 닫기 ]"
	close_btn.add_theme_font_size_override("font_size", 14)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_btn.custom_minimum_size = Vector2(160, 38)
	close_btn.add_theme_stylebox_override("normal",  _make_style(Color(0.08, 0.09, 0.15), C_BORDER, 1, 10))
	close_btn.add_theme_stylebox_override("hover",   _make_style(Color(0.12, 0.14, 0.22), C_BORDER_G, 1, 10))
	close_btn.add_theme_stylebox_override("pressed", _make_style(Color(0.06, 0.07, 0.12), C_GOLD, 1, 10))
	close_btn.pressed.connect(func(): overlay.visible = false)
	vbox.add_child(close_btn)

	overlay.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed:
			overlay.visible = false
	)

	return overlay


# ── 입력 처리 ─────────────────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	if _popup_overlay.visible:
		return

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_on_board_press(mb.position)
			else:
				_on_board_release()

	elif event is InputEventMouseMotion:
		if _dragging_idx >= 0:
			_cards[_dragging_idx].position = event.position - _drag_offset
			_drag_moved = true
			queue_redraw()
			_pin_layer.queue_redraw()


func _on_board_press(pos: Vector2) -> void:
	_drag_moved = false
	_dragging_idx = -1

	for i in _cards.size():
		var card: Control = _cards[i]
		if Rect2(card.position, CARD_SIZE).has_point(pos):
			if _connect_mode:
				_handle_connect(i)
			else:
				_dragging_idx = i
				_drag_offset  = pos - card.position
				# 드래그 카드를 PinLayer 바로 아래로 올려 다른 카드 위에 렌더
				move_child(card, _pin_layer.get_index() - 1)
			return


func _on_board_release() -> void:
	if _dragging_idx >= 0:
		if not _drag_moved:
			_show_clue_popup(_dragging_idx)
		_dragging_idx = -1


# ── 연결 모드 ─────────────────────────────────────────────────────────

func _handle_connect(card_idx: int) -> void:
	if _connect_first < 0:
		_connect_first = card_idx
		_set_card_highlight(card_idx, true)
		return

	if _connect_first == card_idx:
		_set_card_highlight(card_idx, false)
		_connect_first = -1
		return

	var pair_fwd := [_connect_first, card_idx]
	var pair_rev := [card_idx, _connect_first]
	var removed  := false
	for i in _connections.size():
		var p: Array = _connections[i]
		if p == pair_fwd or p == pair_rev:
			_connections.remove_at(i)
			removed = true
			break
	if not removed:
		_connections.append(pair_fwd)

	_set_card_highlight(_connect_first, false)
	_connect_first = -1
	queue_redraw()
	_pin_layer.queue_redraw()


func _on_connect_mode_toggled(pressed: bool) -> void:
	_connect_mode = pressed
	_connect_btn.text = "연결 모드  ON" if pressed else "연결 모드  OFF"
	if not pressed and _connect_first >= 0:
		_set_card_highlight(_connect_first, false)
		_connect_first = -1


func _set_card_highlight(idx: int, on: bool) -> void:
	var card: Control = _cards[idx]
	card.modulate = Color(1.0, 0.88, 0.28) if on else Color(1, 1, 1)


# ── 팝업 ─────────────────────────────────────────────────────────────

func _show_clue_popup(idx: int) -> void:
	if idx >= _clues.size():
		return
	var clue: Dictionary = _clues[idx]
	AudioManager.play_sfx("paper")
	GameManager.collect_clue(clue.get("id", ""))
	_popup_title_lbl.text = clue.get("title", "단서")
	_popup_body_lbl.text  = clue.get("content", "")
	_popup_overlay.visible = true


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
