## RadioScene.gd — 라디오 감청 미니게임 (비주얼 리디자인)
## _draw()로 실시간 파형 시각화. 신호 강도에 따라 잡음→사인파로 변화.
## 목표 주파수는 매 판 랜덤. 스텝 10 kHz 기본 / 1 kHz 미세 조정.
extends Control

const FREQ_MIN       := 100.0
const FREQ_MAX       := 999.9
const TUNE_THRESHOLD := 45.0   # 신호 감지 시작 범위 (kHz) — 파형 변화 구간을 길게
const LOCK_THRESHOLD := 1.0    # 동조 완료 범위 (kHz) — 미세 조정 필수
const STEP_COARSE    := 10.0   # 기본 스텝
const STEP_FINE      := 1.0    # Shift 미세 조정

var _target_freq     : float = 437.5
var _current_freq    : float = 250.0
var _tuned           : bool  = false
var _signal_strength : float = 0.0   # 표시용 (스무딩 적용)
var _signal_target   : float = 0.0   # 실제 계산값

# 파형 애니메이션
var _wave_time       : float = 0.0

# UI 노드 직접 참조 (get_node 경로 사용 금지)
var _lbl_freq        : Label
var _signal_bar      : ProgressBar
var _status_lbl      : Label
var _quest_lbl       : Label
var _cipher_panel    : PanelContainer
var _cipher_text_lbl : Label
var _proceed_btn     : Button
var _intro_overlay   : Control
var _wave_placeholder: Control   # 파형 영역 레이아웃 예약


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	AudioManager.play_bgm("radio")
	GameManager.load_chapter(GameManager.current_chapter_id)

	# 목표 주파수: 1 kHz 단위 — 10 kHz 코스 스텝으로는 절대 정확히 걸리지 않음
	# (예: 437 kHz → 430, 440 둘 다 ±7 kHz 차이 → LOCK_THRESHOLD 1.0 불충족)
	_target_freq  = snappedf(randf_range(180.0, 870.0), 1.0)
	# 1~9 사이 나머지가 없으면 재추출 (코스 스텝 정렬 방지)
	while fmod(_target_freq, 10.0) == 0.0:
		_target_freq = snappedf(randf_range(180.0, 870.0), 1.0)
	_current_freq = snappedf(randf_range(FREQ_MIN + 100.0, FREQ_MAX - 100.0), 10.0)
	while absf(_current_freq - _target_freq) < TUNE_THRESHOLD * 3.0:
		_current_freq = snappedf(randf_range(FREQ_MIN + 100.0, FREQ_MAX - 100.0), 10.0)

	_build_ui()
	_refresh_display()
	AudioManager.start_radio_static()

	if GameManager.current_chapter_id == 0 and GameManager.current_level_id == 1:
		_intro_overlay.visible = true


func _process(delta: float) -> void:
	if _tuned:
		return
	# 신호 강도 스무딩 — 빠르게 지나쳐도 파형이 부드럽게 반응
	_signal_strength = lerp(_signal_strength, _signal_target, delta * 4.0)
	_signal_bar.value = _signal_strength * 100.0
	_wave_time += delta * (2.0 + _signal_strength * 3.5)
	AudioManager.set_radio_static_strength(_signal_strength)
	queue_redraw()


# ────────────────────────────────────────────────────────────────────
#  커스텀 드로우 — 파형 + 주파수 스케일
# ────────────────────────────────────────────────────────────────────

func _draw() -> void:
	# 전체 배경 — 여기서 그려야 자식 노드보다 먼저(아래) 렌더됨
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), Color(0.05, 0.05, 0.08))

	if _wave_placeholder == null or not _wave_placeholder.is_inside_tree():
		return
	if _wave_placeholder.size.x < 10:   # 레이아웃 미확정 시 스킵
		return
	var gp        := _wave_placeholder.global_position
	var gs        := _wave_placeholder.size
	var pad       := 20.0
	var wave_rect := Rect2(gp.x + pad, gp.y + 10.0,
						   gs.x - pad * 2.0, gs.y - 44.0)
	_draw_waveform(wave_rect)
	_draw_freq_scale(wave_rect)


func _draw_waveform(rect: Rect2) -> void:
	# 배경 + 테두리
	draw_rect(rect, Color(0.03, 0.07, 0.04))
	var border_col := Color(0.14, 0.40, 0.20).lerp(Color(0.22, 0.85, 0.42), _signal_strength)
	draw_rect(rect, border_col, false, 1.8)

	# 스캔 라인 (CRT 효과)
	var line_count := int(rect.size.y / 6.0)
	for i in line_count:
		var ly := rect.position.y + float(i) * 6.0
		draw_line(Vector2(rect.position.x, ly),
				  Vector2(rect.position.x + rect.size.x, ly),
				  Color(0.0, 0.0, 0.0, 0.12), 1.0)

	var cy    := rect.position.y + rect.size.y * 0.5
	var n     := int(rect.size.x)
	var amp_h := rect.size.y * 0.40

	var pts : PackedVector2Array
	pts.resize(n)

	for i in n:
		var t  := float(i) / float(n - 1)
		var x  := rect.position.x + float(i)

		# 신호 성분 — 정규화 사인파 (여러 배음)
		var sig := sin(t * TAU * 3.0 + _wave_time) * 0.58 \
				 + sin(t * TAU * 6.1 + _wave_time * 1.4) * 0.26 \
				 + sin(t * TAU * 12.3 + _wave_time * 0.6) * 0.16
		sig *= amp_h * _signal_strength

		# 잡음 성분 — 고주파 의사 랜덤 (시간에 따라 변화)
		var np := t * 143.7 + _wave_time * 2.1
		var noise := sin(np * 17.3) * cos(np * 11.7 + 0.6)  \
				   + sin(np * 5.9 + 2.0) * cos(np * 24.1) * 0.45 \
				   + sin(np * 3.1 + 0.9) * 0.28
		noise *= amp_h * (1.0 - _signal_strength * 0.90)

		pts[i] = Vector2(x, cy + sig + noise)

	# 파형 색상: 잡음(청회) → 신호(초록)
	var wave_col := Color(0.28, 0.30, 0.48).lerp(Color(0.22, 0.92, 0.48), _signal_strength)
	draw_polyline(pts, wave_col, 1.6, true)

	# 중심선
	draw_line(Vector2(rect.position.x, cy),
			  Vector2(rect.position.x + rect.size.x, cy),
			  Color(0.12, 0.30, 0.16, 0.30), 1.0)

	# 동조 완료 시 추가 시각 효과 (두꺼운 글로우)
	if _tuned:
		draw_rect(rect, Color(0.22, 0.92, 0.48, 0.06))
		draw_rect(Rect2(rect.position - Vector2(2, 2),
					   rect.size + Vector2(4, 4)),
				  Color(0.22, 0.92, 0.48, 0.30), false, 3.0)


func _draw_freq_scale(wave_rect: Rect2) -> void:
	var left_x    := wave_rect.position.x
	var right_x   := left_x + wave_rect.size.x
	var scale_y   := wave_rect.position.y + wave_rect.size.y + 12.0
	var scale_w   := wave_rect.size.x
	var freq_span := FREQ_MAX - FREQ_MIN

	# 베이스 라인
	draw_line(Vector2(left_x, scale_y), Vector2(right_x, scale_y),
			  Color(0.22, 0.24, 0.35), 1.2)

	# 틱 마크 (100 kHz)
	var tick := 100
	while float(tick) <= FREQ_MAX:
		if float(tick) >= FREQ_MIN:
			var tx := left_x + (float(tick) - FREQ_MIN) / freq_span * scale_w
			draw_line(Vector2(tx, scale_y - 5), Vector2(tx, scale_y + 5),
					  Color(0.28, 0.30, 0.42), 1.0)
		tick += 100

	# 신호 강도 히트맵 (감지 범위를 희미하게 표시, 정확한 위치는 숨김)
	if _signal_strength > 0.05:
		var cur_ratio := (_current_freq - FREQ_MIN) / freq_span
		var glow_w    := (TUNE_THRESHOLD / freq_span) * scale_w * _signal_strength
		var glow_x    := left_x + cur_ratio * scale_w - glow_w * 0.5
		draw_rect(Rect2(glow_x, scale_y - 3, glow_w, 6),
				  Color(0.22, 0.85, 0.42, _signal_strength * 0.35))

	# 현재 주파수 마커
	var cur_ratio := (_current_freq - FREQ_MIN) / freq_span
	var cur_x     := left_x + cur_ratio * scale_w

	draw_line(Vector2(cur_x, scale_y - 18), Vector2(cur_x, scale_y + 8),
			  Color(0.22, 0.92, 0.48), 2.5)
	var tri := PackedVector2Array([
		Vector2(cur_x,      scale_y - 24),
		Vector2(cur_x - 8,  scale_y - 14),
		Vector2(cur_x + 8,  scale_y - 14),
	])
	draw_colored_polygon(tri, Color(0.22, 0.92, 0.48))


# ────────────────────────────────────────────────────────────────────
#  UI 구성
# ────────────────────────────────────────────────────────────────────

func _build_ui() -> void:
	# 배경은 _draw()에서 직접 그림 — ColorRect 자식을 쓰면 파형 위를 덮어버림
	# (부모 _draw() → 자식 렌더 순서이므로 자식 ColorRect가 파형을 가림)

	# ── 루트 VBox (전체 화면) ──
	var root_vbox := VBoxContainer.new()
	root_vbox.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	root_vbox.add_theme_constant_override("separation", 0)
	add_child(root_vbox)

	# 상단 바
	root_vbox.add_child(_build_top_bar())

	# 파형 영역 예약 플레이스홀더
	_wave_placeholder = Control.new()
	_wave_placeholder.custom_minimum_size.y = 280
	_wave_placeholder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_wave_placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_vbox.add_child(_wave_placeholder)

	# 컨트롤 패널 (주파수 표시 + 버튼 영역)
	var ctrl_panel := _build_control_panel()
	ctrl_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(ctrl_panel)

	# 퀘스트 인디케이터 (우하단, 레이아웃 외부)
	_quest_lbl = Label.new()
	_quest_lbl.text = _quest_text(false)
	_quest_lbl.set_anchors_and_offsets_preset(PRESET_BOTTOM_RIGHT)
	_quest_lbl.position -= Vector2(380, 100)
	_quest_lbl.custom_minimum_size.x = 360
	_quest_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_quest_lbl.add_theme_font_size_override("font_size", 13)
	_quest_lbl.add_theme_color_override("font_color", Color(0.68, 0.65, 0.45))
	add_child(_quest_lbl)

	# 인트로 오버레이
	_intro_overlay = _build_intro_overlay()
	_intro_overlay.visible = false
	add_child(_intro_overlay)


func _build_top_bar() -> Control:
	var bar := PanelContainer.new()
	bar.custom_minimum_size.y = 56

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 0)
	bar.add_child(hbox)

	# 좌측 여백 + 뒤로 버튼
	_add_hgap(hbox, 12)
	var back_btn := Button.new()
	back_btn.text = "◀ 메뉴"
	back_btn.add_theme_font_size_override("font_size", 14)
	back_btn.custom_minimum_size.x = 90
	back_btn.pressed.connect(func():
		AudioManager.stop_radio_static()
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	)
	hbox.add_child(back_btn)

	_add_hgap(hbox, 20)

	# 제목
	var title := Label.new()
	title.text = "[ 무선 수신기  —  RADIO RECEIVER  —  BLETCHLEY PARK ]"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 17)
	title.add_theme_color_override("font_color", Color(0.93, 0.87, 0.40))
	hbox.add_child(title)

	# 챕터 이름
	_add_hgap(hbox, 20)
	var ch_lbl := Label.new()
	var sub   : String = GameManager.current_chapter.get("subtitle", "")
	var tit   : String = GameManager.current_chapter.get("title", "?")
	ch_lbl.text = ("%s [ %s ]" % [sub, tit]).strip_edges()
	ch_lbl.add_theme_font_size_override("font_size", 13)
	ch_lbl.add_theme_color_override("font_color", Color(0.50, 0.50, 0.62))
	hbox.add_child(ch_lbl)
	_add_hgap(hbox, 16)

	return bar


func _build_control_panel() -> Control:
	# 전체를 VBox로 감싸고 수직 중앙 정렬
	var outer := VBoxContainer.new()
	outer.alignment = BoxContainer.ALIGNMENT_CENTER
	outer.add_theme_constant_override("separation", 10)

	# 내용을 수평 중앙 배치
	var inner := VBoxContainer.new()
	inner.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	inner.custom_minimum_size.x = 640
	inner.add_theme_constant_override("separation", 10)
	outer.add_child(inner)

	# 주파수 표시
	_lbl_freq = Label.new()
	_lbl_freq.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_freq.add_theme_font_size_override("font_size", 64)
	_lbl_freq.add_theme_color_override("font_color", Color(0.22, 0.92, 0.48))
	inner.add_child(_lbl_freq)

	# 조작 안내
	var guide := Label.new()
	guide.text = "마우스 휠 · 방향키 ↑↓ : ±10 kHz     Shift + ↑↓ / 휠 : ±1 kHz"
	guide.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	guide.add_theme_font_size_override("font_size", 13)
	guide.add_theme_color_override("font_color", Color(0.35, 0.35, 0.48))
	inner.add_child(guide)

	# 신호 강도 바 행
	var bar_row := HBoxContainer.new()
	bar_row.add_theme_constant_override("separation", 12)
	inner.add_child(bar_row)

	var bar_lbl := Label.new()
	bar_lbl.text = "SIGNAL"
	bar_lbl.add_theme_font_size_override("font_size", 13)
	bar_lbl.add_theme_color_override("font_color", Color(0.40, 0.42, 0.55))
	bar_row.add_child(bar_lbl)

	_signal_bar = ProgressBar.new()
	_signal_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_signal_bar.custom_minimum_size.y = 22
	_signal_bar.max_value = 100.0
	_signal_bar.value    = 0.0
	_signal_bar.show_percentage = false
	bar_row.add_child(_signal_bar)

	# 상태 텍스트
	_status_lbl = Label.new()
	_status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_lbl.add_theme_font_size_override("font_size", 16)
	inner.add_child(_status_lbl)

	# 감청된 암호문 패널 (동조 후 표시)
	_cipher_panel = PanelContainer.new()
	_cipher_panel.visible = false
	inner.add_child(_cipher_panel)

	var cp_vbox := VBoxContainer.new()
	cp_vbox.add_theme_constant_override("separation", 6)
	_cipher_panel.add_child(cp_vbox)

	var cp_hdr := Label.new()
	cp_hdr.text = "▶ 감청된 암호문"
	cp_hdr.add_theme_font_size_override("font_size", 13)
	cp_hdr.add_theme_color_override("font_color", Color(0.93, 0.87, 0.40))
	cp_vbox.add_child(cp_hdr)

	_cipher_text_lbl = Label.new()
	_cipher_text_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cipher_text_lbl.add_theme_font_size_override("font_size", 22)
	_cipher_text_lbl.add_theme_color_override("font_color", Color(0.85, 0.88, 0.95))
	cp_vbox.add_child(_cipher_text_lbl)

	# 진행 버튼
	_proceed_btn = Button.new()
	_proceed_btn.text = "단서 보드로  →"
	_proceed_btn.add_theme_font_size_override("font_size", 18)
	_proceed_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_proceed_btn.custom_minimum_size = Vector2(260, 44)
	_proceed_btn.visible = false
	_proceed_btn.pressed.connect(_on_proceed)
	inner.add_child(_proceed_btn)

	return outer


func _build_intro_overlay() -> Control:
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.84)
	overlay.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	# PRESET_CENTER 금지 — VBox + SIZE_SHRINK_CENTER 사용
	var outer := VBoxContainer.new()
	outer.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	outer.alignment = BoxContainer.ALIGNMENT_CENTER
	outer.add_theme_constant_override("separation", 0)
	overlay.add_child(outer)

	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.custom_minimum_size   = Vector2(600, 0)
	outer.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   28)
	margin.add_theme_constant_override("margin_right",  28)
	margin.add_theme_constant_override("margin_top",    22)
	margin.add_theme_constant_override("margin_bottom", 22)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)

	var stamp := Label.new()
	stamp.text = "[ 최고 기밀  ·  BLETCHLEY PARK  ·  1942.11.01 ]"
	stamp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stamp.add_theme_font_size_override("font_size", 12)
	stamp.add_theme_color_override("font_color", Color(0.75, 0.18, 0.18))
	vbox.add_child(stamp)

	vbox.add_child(HSeparator.new())

	var title_lbl := Label.new()
	title_lbl.text = "\"첫 교신\""
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 22)
	title_lbl.add_theme_color_override("font_color", Color(0.93, 0.87, 0.40))
	vbox.add_child(title_lbl)

	vbox.add_child(HSeparator.new())

	var body := Label.new()
	body.text = \
		"1942년 11월 1일, 오전 06:12.\n" \
		+ "블레츨리 파크, 분석동 7호실.\n\n" \
		+ "낡은 책상 위로 문서 한 장이 툭 던져진다.\n\n" \
		+ "해리슨:  \"신참이군. 앉아.\"\n\n" \
		+ "         \"오늘 새벽에 독일 놈들 신호 하나를 포착했어.\n" \
		+ "          가장 기초적인 방식이야. 알파벳을 몇 칸씩 밀어서\n" \
		+ "          암호화하는 거지. 애들 장난 수준.\n\n" \
		+ "          일단 저 수신기 다이얼을 맞춰봐.\n" \
		+ "          주파수 잡히면 암호문이 뜰 거야.\n" \
		+ "          그 다음은... 직접 알아내봐.\"\n\n" \
		+ "해리슨이 문을 닫고 나간다."
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 15)
	body.add_theme_color_override("font_color", Color(0.82, 0.80, 0.70))
	vbox.add_child(body)

	vbox.add_child(HSeparator.new())

	var steps_hdr := Label.new()
	steps_hdr.text = "[ 작업 지시서 — Harrison 서명 ]"
	steps_hdr.add_theme_font_size_override("font_size", 13)
	steps_hdr.add_theme_color_override("font_color", Color(0.52, 0.52, 0.65))
	vbox.add_child(steps_hdr)

	var steps := Label.new()
	steps.text = \
		"  1.  무선 수신기  —  다이얼을 조정해 적군 신호 포착\n" \
		+ "  2.  단서 보드    —  압수된 문서·사진 검토\n" \
		+ "  3.  암호 해독기  —  이동값 추정 후 보고서 제출"
	steps.add_theme_font_size_override("font_size", 13)
	steps.add_theme_color_override("font_color", Color(0.72, 0.85, 0.62))
	vbox.add_child(steps)

	var start_btn := Button.new()
	start_btn.text = "책상 앞에 앉는다  →"
	start_btn.add_theme_font_size_override("font_size", 17)
	start_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	start_btn.custom_minimum_size = Vector2(260, 44)
	start_btn.pressed.connect(func(): overlay.visible = false)
	vbox.add_child(start_btn)

	return overlay


# ────────────────────────────────────────────────────────────────────
#  입력 처리
# ────────────────────────────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	if _tuned or _intro_overlay.visible:
		return

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if not mb.pressed:
			return
		var fine := Input.is_key_pressed(KEY_SHIFT)
		var step := STEP_FINE if fine else STEP_COARSE
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			_adjust_freq(step)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_adjust_freq(-step)

	elif event is InputEventKey and event.pressed and not event.echo:
		var ke   := event as InputEventKey
		var step := STEP_FINE if ke.shift_pressed else STEP_COARSE
		if ke.keycode == KEY_UP:
			_adjust_freq(step)
		elif ke.keycode == KEY_DOWN:
			_adjust_freq(-step)


func _adjust_freq(delta: float) -> void:
	_current_freq = snappedf(clampf(_current_freq + delta, FREQ_MIN, FREQ_MAX), 0.1)
	_refresh_display()
	_check_tune()


func _refresh_display() -> void:
	_lbl_freq.text = "%.1f  kHz" % _current_freq

	var dist := absf(_current_freq - _target_freq)
	if dist >= TUNE_THRESHOLD:
		_signal_target = 0.0
	else:
		_signal_target = 1.0 - (dist / TUNE_THRESHOLD)
	# _signal_strength / _signal_bar는 _process에서 스무딩 처리

	if _signal_target < 0.12:
		_status_lbl.text = "신호 없음  —  다른 주파수를 탐색하십시오"
		_status_lbl.add_theme_color_override("font_color", Color(0.32, 0.32, 0.42))
	elif _signal_target < 0.40:
		_status_lbl.text = "약한 신호 감지  —  계속 탐색하십시오"
		_status_lbl.add_theme_color_override("font_color", Color(0.55, 0.72, 0.42))
	elif _signal_target < 0.72:
		_status_lbl.text = "신호 강도 증가  —  현재 방향을 유지하십시오"
		_status_lbl.add_theme_color_override("font_color", Color(0.30, 0.85, 0.50))
	elif _signal_target < 0.95:
		_status_lbl.text = "강한 신호  —  Shift+방향키로 미세 조정하십시오"
		_status_lbl.add_theme_color_override("font_color", Color(0.22, 0.92, 0.48))
	else:
		_status_lbl.text = "[ 동조 가능  —  TUNE NOW ]"
		_status_lbl.add_theme_color_override("font_color", Color(0.93, 0.87, 0.40))


func _check_tune() -> void:
	if absf(_current_freq - _target_freq) <= LOCK_THRESHOLD:
		_on_tuned()


func _on_tuned() -> void:
	AudioManager.stop_radio_static()
	AudioManager.play_sfx("signal_lock")
	_tuned = true
	_current_freq    = _target_freq
	_signal_strength = 1.0
	_signal_target   = 1.0
	_lbl_freq.text   = "%.1f  kHz" % _current_freq
	_signal_bar.value = 100.0

	_status_lbl.text = "[ 동조 완료  —  SIGNAL LOCKED ]"
	_status_lbl.add_theme_color_override("font_color", Color(0.93, 0.87, 0.40))

	_cipher_text_lbl.text = GameManager.current_chapter.get("cipher_text", "")
	_cipher_panel.visible = true
	_proceed_btn.visible  = true

	_quest_lbl.text = _quest_text(true)
	_quest_lbl.add_theme_color_override("font_color", Color(0.42, 0.88, 0.42))

	queue_redraw()
	GameManager.radio_tuned.emit(GameManager.current_chapter_id)


func _on_proceed() -> void:
	get_tree().change_scene_to_file("res://scenes/EvidenceBoard.tscn")


# ────────────────────────────────────────────────────────────────────
#  유틸리티
# ────────────────────────────────────────────────────────────────────

func _quest_text(done: bool) -> String:
	if done:
		return "[ ✓ 임무 1/3 완료 ]\n신호 포착 성공. 단서 보드로 이동하십시오."
	return "[ 임무 1/3 ]\n주파수 다이얼을 조정해 적군의\n무선 신호를 포착하십시오.\n파형이 규칙적인 사인파가 될 때\n동조가 완료됩니다."


func _add_hgap(parent: HBoxContainer, width: int) -> void:
	var gap := Control.new()
	gap.custom_minimum_size.x = width
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(gap)
