## ChapterView.gd — 챕터 플레이 메인 씬
## 구성: [상단 바] / [좌: 단서 패널] + [우: 해독기 + 보고서]
extends Control

# ── 팔레트 ───────────────────────────────────────────────────────────
const C_BG       := Color(0.04, 0.05, 0.09)
const C_PANEL    := Color(0.065, 0.075, 0.12)
const C_INSET    := Color(0.055, 0.065, 0.10)
const C_GOLD     := Color(0.93, 0.87, 0.40)
const C_MUTED    := Color(0.40, 0.40, 0.52)
const C_BORDER   := Color(0.18, 0.20, 0.32)
const C_BORDER_G := Color(0.50, 0.44, 0.15)

const TYPE_COLORS := {
	"document"      : Color(0.28, 0.42, 0.68),
	"torn_paper"    : Color(0.62, 0.52, 0.32),
	"photo"         : Color(0.42, 0.44, 0.54),
	"interrogation" : Color(0.62, 0.28, 0.28),
	"map"           : Color(0.28, 0.58, 0.40),
}
const TYPE_ICONS := {
	"document"      : "[문서]",
	"torn_paper"    : "[메모]",
	"photo"         : "[사진]",
	"interrogation" : "[심문]",
	"map"           : "[지도]",
}

# ── 암호 방식별 소개 텍스트 ──────────────────────────────────────────
const CIPHER_INTROS := {
	"caesar": {
		"title": "[ 시저 암호  ·  CAESAR CIPHER ]",
		"body":
			"시저 암호는 알파벳을 일정 칸수(Shift)만큼 이동시키는 방식입니다.\n\n" +
			"예시:  평문  M A R C H  →  shift=5 →  암호문  R F W H M\n\n" +
			"복호화하려면 이동 칸수(Shift)와 방향(→ 또는 ←)을 찾아야 합니다.\n\n" +
			"단서 보드에서 이동값과 방향의 근거를 수집하십시오.\n" +
			"해독기의 슬라이더로 값을 맞춰가며 의미 있는 영어 단어가\n" +
			"나타나는 지점을 찾으십시오."
	},
	"vigenere": {
		"title": "[ 비즈네르 암호  ·  VIGENÈRE CIPHER ]",
		"body":
			"비즈네르 암호는 '키워드(Keyword)'를 사용하는 방식입니다.\n\n" +
			"키워드의 각 글자가 이동값이 되어 메시지 전체에 순환 적용됩니다.\n\n" +
			"예시  (키워드: WOLF)\n" +
			"  평문:     S   E   N   D\n" +
			"  키:       W   O   L   F    ← WOLF 반복\n" +
			"  이동값:  +22 +14 +11  +5\n" +
			"  암호문:   O   S   Y   I\n\n" +
			"해독하려면 키워드를 먼저 찾아야 합니다.\n" +
			"단서를 조합해 발신자의 개인 식별어를 추적하십시오."
	},
	"substitution": {
		"title": "[ 단일 치환 암호  ·  MONOALPHABETIC SUBSTITUTION ]",
		"body":
			"단일 치환 암호는 각 알파벳이 고정된 다른 글자 하나로 대체되는 방식입니다.\n\n" +
			"예시:  A→X, B→M, C→P, ...  (전문에 걸쳐 동일한 규칙 적용)\n\n" +
			"── 해독 전략: 빈도 분석 ──\n" +
			"영어에서 가장 자주 나타나는 글자 순서:\n" +
			"  1위 E (약 13%)   2위 T (약 9%)   3위 A (약 8%)\n\n" +
			"암호문에서 가장 많이 반복되는 글자 → E 또는 T일 가능성 높음\n" +
			"세 글자 단어 → THE, AND, FOR 가능성 높음\n\n" +
			"단서들이 치환표의 일부를 드러낼 것입니다.\n" +
			"알려진 대응 관계부터 하나씩 채워 나가십시오."
	},
	"enigma": {
		"title": "[ 에니그마 머신  ·  ENIGMA MACHINE ]",
		"body":
			"에니그마는 나치 독일군이 사용한 전기-기계식 암호 장치입니다.\n\n" +
			"── 구성 요소 ──\n" +
			"  로터 (Rotor)   : 3개. 키 입력마다 회전하며 신호 경로를 바꿈\n" +
			"  반사판 (Reflector) : 신호를 되돌려 보내는 고정 부품\n" +
			"  플러그보드 (Plugboard) : 입·출력 전 알파벳 쌍을 교환\n\n" +
			"── 해독 방법 ──\n" +
			"에니그마는 대칭 암호입니다 — 같은 설정으로 암호문을 입력하면\n" +
			"그대로 평문이 출력됩니다.\n\n" +
			"단서 보드에서 다음 세 가지를 찾으십시오:\n" +
			"  1. 로터 종류  (I ~ V, 슬롯별 순서)\n" +
			"  2. 각 로터의 초기 위치  (A ~ Z)\n" +
			"  3. 반사판 유형  (A 또는 B)\n\n" +
			"설정이 하나라도 틀리면 해독 결과는 의미 없는 문자열입니다."
	},
	"playfair": {
		"title": "[ 플레이페어 암호  ·  PLAYFAIR CIPHER ]",
		"body":
			"플레이페어 암호는 5×5 격자를 이용해 두 글자씩 묶어 처리하는 방식입니다.\n\n" +
			"── 격자 구성 ──\n" +
			"키워드의 알파벳(중복 제거)을 먼저 채우고, 나머지를 순서대로 채운다.\n" +
			"I 와 J 는 같은 칸을 사용한다.\n\n" +
			"── 암호화 규칙 (두 글자 쌍 처리) ──\n" +
			"  같은 행 : 각 글자를 오른쪽 칸으로 이동\n" +
			"  같은 열 : 각 글자를 아래 칸으로 이동\n" +
			"  사각형 : 행은 유지하고 열을 서로 교환\n\n" +
			"── 주의 ──\n" +
			"연속으로 같은 글자가 오면 X를 삽입한다.  (예: LL → LX L)\n" +
			"글자 수가 홀수이면 끝에 X를 추가한다.\n\n" +
			"단서 보드에서 격자 키워드를 찾아 해독기에 입력하십시오."
	}
}

# ── 레이아웃 노드 레퍼런스 ──────────────────────────────────────────
var _lbl_chapter_title : Label
var _lbl_frequency     : Label
var _lbl_date          : Label
var _lbl_timer         : Label    # 레벨 타이머 표시
var _hint_btn          : Button   # 힌트 버튼 직접 참조 (제한 시 비활성화)
var _lbl_cipher_header : Label    # 암호문 복사용 레이블

var _clue_list_vbox    : VBoxContainer   # 단서 카드 목록
var _cipher_container  : Control         # 해독기가 동적으로 올라오는 영역

var _level_start_time  : float = 0.0   # 씬 진입 시각 (복사용 — GameManager에도 있음)

# ── 타자기 상태 ──────────────────────────────────────────────────────
var _tw_label         : Label    = null
var _tw_full_text     : String   = ""
var _tw_pos           : int      = 0
var _tw_timer         : Timer    = null
var _tw_done_cb       : Callable
var _story_result_panel : Control = null   # 타자기 완료 후 페이드인
var _report_panel      : PanelContainer  # 보고서 (처음엔 숨김)

var _decoder           : Control         # 현재 로드된 해독기 인스턴스
var _report_inputs     : Dictionary = {} # { q_id: OptionButton }
var _q_container       : VBoxContainer   # 보고서 질문 컨테이너 직접 참조
var _decoded_rh_panel  : Control = null  # 레드 헤링 해설 패널 (완료 연출 시)

# ── BOMBE 이스터에그 ─────────────────────────────────────────────────
const _BOMBE_CODE  := "BOMBE"
var   _bombe_buffer : String = ""

# ── 오버레이 레퍼런스 ────────────────────────────────────────────────
var _popup_overlay      : Control   # 일반 팝업
var _popup_title_lbl    : Label
var _popup_body_lbl     : Label
var _cipher_intro_panel : Control   # 암호 방식 소개 (챕터 로드 시)
var _stamp_overlay      : Control   # DECODED 도장 (챕터 완료 시)


# ── 도장 드로어 (inner class) ────────────────────────────────────────
class _StampDraw extends Control:
	var stars_count: int = 0

	func _draw() -> void:
		var font: Font = ThemeDB.fallback_font
		if font == null:
			return
		var fsize    := 80
		var text     := "DECODED"
		var col      := Color(0.72, 0.10, 0.10, 0.84)
		var tsize    := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize)
		var cx       := size.x * 0.5
		var cy       := size.y * 0.40
		var xform    := Transform2D(deg_to_rad(-12.0), Vector2(cx, cy))
		draw_set_transform_matrix(xform)
		var pad  := Vector2(30.0, 18.0)
		var rw   := tsize.x + pad.x * 2.0
		var rh   := tsize.y + pad.y * 2.0
		# 외곽 테두리
		draw_rect(Rect2(-rw * 0.5, -rh * 0.5, rw, rh), col, false, 7.0)
		# 내곽 테두리
		draw_rect(Rect2(-rw * 0.5 + 11.0, -rh * 0.5 + 11.0, rw - 22.0, rh - 22.0),
				  Color(col.r, col.g, col.b, col.a * 0.65), false, 2.5)
		# 텍스트
		draw_string(font, Vector2(-tsize.x * 0.5, tsize.y * 0.28),
					text, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, col)
		# 트랜스폼 초기화 후 별점 그리기
		draw_set_transform_matrix(Transform2D())
		var star_text := "★".repeat(stars_count) + "☆".repeat(3 - stars_count)
		var sfsize    := 36
		var stsize    := font.get_string_size(star_text, HORIZONTAL_ALIGNMENT_LEFT, -1, sfsize)
		draw_string(font,
					Vector2(cx - stsize.x * 0.5, cy + rh * 0.5 + 64.0),
					star_text, HORIZONTAL_ALIGNMENT_LEFT, -1, sfsize,
					Color(0.93, 0.87, 0.40))


func _ready() -> void:
	self.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	AudioManager.play_bgm("gameplay")
	_level_start_time = Time.get_unix_time_from_system()
	_build_ui()
	_connect_signals()
	GameManager.load_chapter(GameManager.current_chapter_id)


func _process(_delta: float) -> void:
	if _lbl_timer == null or not is_instance_valid(_lbl_timer):
		return
	# 완료된 레벨이면 타이머 멈춤
	if GameManager.is_level_complete(GameManager.current_chapter_id, GameManager.current_level_id):
		return
	var elapsed: float = Time.get_unix_time_from_system() - _level_start_time
	var secs: int = int(elapsed)
	if secs < 60:
		_lbl_timer.text = "%d초" % secs
	else:
		_lbl_timer.text = "%d:%02d" % [secs / 60, secs % 60]


# ────────────────────────────────────────────────────────────────────
#  UI 구성
# ────────────────────────────────────────────────────────────────────

func _build_ui() -> void:
	# 전체 배경
	var bg := ColorRect.new()
	bg.color = C_BG
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(bg)

	# 루트 VBox
	var root_vbox := VBoxContainer.new()
	root_vbox.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	root_vbox.add_theme_constant_override("separation", 0)
	add_child(root_vbox)

	root_vbox.add_child(_build_top_bar())

	# 본문 (좌+우)
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 0)
	root_vbox.add_child(body)

	body.add_child(_build_clue_panel())

	var vline := VSeparator.new()
	var vline_style := StyleBoxFlat.new()
	vline_style.bg_color = C_BORDER_G
	vline.add_theme_stylebox_override("separator", vline_style)
	body.add_child(vline)

	body.add_child(_build_right_panel())

	_popup_overlay = _build_popup_overlay()
	add_child(_popup_overlay)


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

	# 뒤로 버튼
	var back_btn := Button.new()
	back_btn.text = "◀  메뉴"
	back_btn.add_theme_font_size_override("font_size", 13)
	back_btn.custom_minimum_size.x = 88
	back_btn.add_theme_stylebox_override("normal",  _make_style(Color(0.08, 0.09, 0.15), C_BORDER, 1, 8))
	back_btn.add_theme_stylebox_override("hover",   _make_style(Color(0.12, 0.14, 0.22), C_BORDER_G, 1, 8))
	back_btn.add_theme_stylebox_override("pressed", _make_style(Color(0.06, 0.07, 0.12), C_GOLD, 1, 8))
	back_btn.pressed.connect(func(): SceneTransition.fade_to("res://scenes/MainMenu.tscn"))
	hbox.add_child(back_btn)

	# 챕터 제목
	_lbl_chapter_title = Label.new()
	_lbl_chapter_title.text = "..."
	_lbl_chapter_title.add_theme_font_size_override("font_size", 20)
	_lbl_chapter_title.add_theme_color_override("font_color", C_GOLD)
	_lbl_chapter_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(_lbl_chapter_title)

	# 주파수
	_lbl_frequency = Label.new()
	_lbl_frequency.text = "─── kHz"
	_lbl_frequency.add_theme_font_size_override("font_size", 14)
	_lbl_frequency.add_theme_color_override("font_color", Color(0.30, 0.80, 0.55))
	hbox.add_child(_lbl_frequency)

	# 날짜
	_lbl_date = Label.new()
	_lbl_date.text = "────.──.──"
	_lbl_date.add_theme_font_size_override("font_size", 13)
	_lbl_date.add_theme_color_override("font_color", C_MUTED)
	hbox.add_child(_lbl_date)

	# 타이머
	_lbl_timer = Label.new()
	_lbl_timer.text = "0초"
	_lbl_timer.add_theme_font_size_override("font_size", 13)
	_lbl_timer.add_theme_color_override("font_color", Color(0.45, 0.72, 0.88))
	hbox.add_child(_lbl_timer)

	# 힌트 버튼
	var hint_btn := Button.new()
	hint_btn.text = "힌트 사용 (0/%d)" % GameManager.HINT_MAX
	hint_btn.add_theme_font_size_override("font_size", 13)
	hint_btn.add_theme_stylebox_override("normal",  _make_style(Color(0.08, 0.09, 0.15), C_BORDER, 1, 8))
	hint_btn.add_theme_stylebox_override("hover",   _make_style(Color(0.14, 0.10, 0.06), Color(0.75, 0.55, 0.25), 1, 8))
	hint_btn.add_theme_stylebox_override("pressed", _make_style(Color(0.10, 0.08, 0.04), Color(0.93, 0.72, 0.30), 1, 8))
	hint_btn.add_theme_stylebox_override("disabled", _make_style(Color(0.06, 0.06, 0.10), Color(0.20, 0.20, 0.28), 1, 8))
	hint_btn.add_theme_color_override("font_disabled_color", Color(0.32, 0.32, 0.40))
	hint_btn.pressed.connect(GameManager.use_hint)
	hbox.add_child(hint_btn)
	_hint_btn = hint_btn

	return bar


func _build_clue_panel() -> Control:
	var outer := PanelContainer.new()
	outer.custom_minimum_size.x = 278
	var outer_style := StyleBoxFlat.new()
	outer_style.bg_color = Color(0.055, 0.065, 0.10)
	outer.add_theme_stylebox_override("panel", outer_style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",  10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top",    8)
	margin.add_theme_constant_override("margin_bottom", 8)
	outer.add_child(margin)

	var panel := VBoxContainer.new()
	panel.add_theme_constant_override("separation", 6)
	margin.add_child(panel)

	# 헤더
	var hdr := Label.new()
	hdr.text = "단서 목록"
	hdr.add_theme_font_size_override("font_size", 14)
	hdr.add_theme_color_override("font_color", C_GOLD)
	hdr.custom_minimum_size.y = 32
	panel.add_child(hdr)

	var sep := HSeparator.new()
	var sep_style := StyleBoxFlat.new()
	sep_style.bg_color = C_BORDER_G
	sep.add_theme_stylebox_override("separator", sep_style)
	panel.add_child(sep)

	# 스크롤 가능한 단서 목록
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(scroll)

	_clue_list_vbox = VBoxContainer.new()
	_clue_list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_clue_list_vbox.add_theme_constant_override("separation", 6)
	scroll.add_child(_clue_list_vbox)

	var empty_lbl := Label.new()
	empty_lbl.name = "EmptyLabel"
	empty_lbl.text = "  단서를 수집하면\n  여기에 나타납니다."
	empty_lbl.add_theme_font_size_override("font_size", 12)
	empty_lbl.add_theme_color_override("font_color", Color(0.35, 0.35, 0.45))
	_clue_list_vbox.add_child(empty_lbl)

	return outer


func _build_right_panel() -> Control:
	var outer := MarginContainer.new()
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	outer.add_theme_constant_override("margin_bottom", 14)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 0)
	outer.add_child(vbox)

	# ── 암호문 헤더 + 복사 버튼 ──
	var cipher_hdr_row := HBoxContainer.new()
	cipher_hdr_row.add_theme_constant_override("separation", 8)
	vbox.add_child(cipher_hdr_row)

	_lbl_cipher_header = Label.new()
	_lbl_cipher_header.text = "암호문:"
	_lbl_cipher_header.add_theme_font_size_override("font_size", 12)
	_lbl_cipher_header.add_theme_color_override("font_color", C_MUTED)
	_lbl_cipher_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cipher_hdr_row.add_child(_lbl_cipher_header)

	var copy_btn := Button.new()
	copy_btn.text = "[ 복사 ]"
	copy_btn.add_theme_font_size_override("font_size", 11)
	copy_btn.add_theme_color_override("font_color", Color(0.55, 0.72, 0.88))
	copy_btn.add_theme_stylebox_override("normal",  _make_style(Color(0.07, 0.09, 0.14), C_BORDER, 1, 6))
	copy_btn.add_theme_stylebox_override("hover",   _make_style(Color(0.10, 0.13, 0.20), Color(0.40, 0.60, 0.80), 1, 6))
	copy_btn.add_theme_stylebox_override("pressed", _make_style(Color(0.06, 0.08, 0.12), Color(0.30, 0.50, 0.70), 1, 6))
	copy_btn.pressed.connect(func():
		var ct: String = GameManager.current_chapter.get("cipher_text", "")
		if not ct.is_empty():
			DisplayServer.clipboard_set(ct)
			copy_btn.text = "[ 복사됨 ✓ ]"
			# 1.5초 후 원래 텍스트 복원
			get_tree().create_timer(1.5).timeout.connect(func(): copy_btn.text = "[ 복사 ]")
	)
	cipher_hdr_row.add_child(copy_btn)

	_cipher_container = Control.new()
	_cipher_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cipher_container.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	vbox.add_child(_cipher_container)

	_report_panel = _build_report_panel()
	_report_panel.visible = false
	vbox.add_child(_report_panel)

	return outer


func _build_report_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.y = 190
	panel.add_theme_stylebox_override("panel", _make_style(C_PANEL, C_BORDER_G, 1, 0))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   18)
	margin.add_theme_constant_override("margin_right",  18)
	margin.add_theme_constant_override("margin_top",    14)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	var hdr := Label.new()
	hdr.name = "ReportHeader"
	hdr.text = "[ 보고서 작성 ]  —  수집한 정보를 바탕으로 아래 질문에 답하십시오."
	hdr.add_theme_font_size_override("font_size", 14)
	hdr.add_theme_color_override("font_color", C_GOLD)
	vbox.add_child(hdr)

	var sep := HSeparator.new()
	var sep_style := StyleBoxFlat.new()
	sep_style.bg_color = C_BORDER_G
	sep.add_theme_stylebox_override("separator", sep_style)
	vbox.add_child(sep)

	var q_container := VBoxContainer.new()
	q_container.name = "QuestionContainer"
	q_container.add_theme_constant_override("separation", 8)
	vbox.add_child(q_container)
	_q_container = q_container

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_END
	vbox.add_child(btn_row)

	var submit_btn := Button.new()
	submit_btn.text = "보고서 제출  →"
	submit_btn.add_theme_font_size_override("font_size", 16)
	submit_btn.add_theme_stylebox_override("normal",  _make_style(Color(0.08, 0.10, 0.07), C_BORDER_G, 1, 12))
	submit_btn.add_theme_stylebox_override("hover",   _make_style(Color(0.12, 0.15, 0.09), C_GOLD, 1, 12))
	submit_btn.add_theme_stylebox_override("pressed", _make_style(Color(0.06, 0.08, 0.05), C_GOLD, 2, 12))
	submit_btn.add_theme_color_override("font_color", C_GOLD)
	submit_btn.pressed.connect(_on_submit_report)
	btn_row.add_child(submit_btn)

	return panel


func _build_popup_overlay() -> Control:
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.75)
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
	panel.add_theme_stylebox_override("panel", _make_style(Color(0.07, 0.08, 0.13), C_BORDER_G, 1, 0))
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
	_popup_title_lbl.add_theme_color_override("font_color", C_GOLD)
	vbox.add_child(_popup_title_lbl)

	var sep := HSeparator.new()
	var sep_style := StyleBoxFlat.new()
	sep_style.bg_color = C_BORDER_G
	sep.add_theme_stylebox_override("separator", sep_style)
	vbox.add_child(sep)

	_popup_body_lbl = Label.new()
	_popup_body_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_popup_body_lbl.add_theme_font_size_override("font_size", 15)
	_popup_body_lbl.add_theme_color_override("font_color", Color(0.80, 0.78, 0.68))
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


# ── 암호 방식 소개 오버레이 ─────────────────────────────────────────

func _show_cipher_intro(cipher_type: String) -> void:
	if not CIPHER_INTROS.has(cipher_type):
		return
	if _cipher_intro_panel != null:
		_cipher_intro_panel.queue_free()

	var info: Dictionary = CIPHER_INTROS[cipher_type]
	_cipher_intro_panel = _build_cipher_intro(info["title"], info["body"])
	add_child(_cipher_intro_panel)


func _build_cipher_intro(title: String, body_text: String) -> Control:
	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.88)
	overlay.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	var outer_v := VBoxContainer.new()
	outer_v.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	outer_v.alignment = BoxContainer.ALIGNMENT_CENTER
	overlay.add_child(outer_v)

	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.custom_minimum_size   = Vector2(620, 0)
	var ps := _make_style(Color(0.05, 0.06, 0.10), C_BORDER_G, 2, 0)
	ps.shadow_color  = Color(0.0, 0.0, 0.0, 0.60)
	ps.shadow_size   = 12
	ps.shadow_offset = Vector2(4, 6)
	panel.add_theme_stylebox_override("panel", ps)
	outer_v.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   32)
	margin.add_theme_constant_override("margin_right",  32)
	margin.add_theme_constant_override("margin_top",    28)
	margin.add_theme_constant_override("margin_bottom", 28)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)

	# 상단 분류 태그
	var tag_lbl := Label.new()
	tag_lbl.text = "암호 해독 방법론  —  BLETCHLEY PARK CRYPTANALYSIS MANUAL"
	tag_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag_lbl.add_theme_font_size_override("font_size", 11)
	tag_lbl.add_theme_color_override("font_color", Color(0.75, 0.18, 0.18))
	vbox.add_child(tag_lbl)

	var sep1 := HSeparator.new()
	var ss1 := StyleBoxFlat.new()
	ss1.bg_color = Color(0.75, 0.18, 0.18, 0.50)
	sep1.add_theme_stylebox_override("separator", ss1)
	vbox.add_child(sep1)

	# 제목
	var title_lbl := Label.new()
	title_lbl.text = title
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 20)
	title_lbl.add_theme_color_override("font_color", C_GOLD)
	vbox.add_child(title_lbl)

	var sep2 := HSeparator.new()
	var ss2 := StyleBoxFlat.new()
	ss2.bg_color = C_BORDER_G
	sep2.add_theme_stylebox_override("separator", ss2)
	vbox.add_child(sep2)

	# 본문
	var body_lbl := Label.new()
	body_lbl.text = body_text
	body_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_lbl.add_theme_font_size_override("font_size", 15)
	body_lbl.add_theme_color_override("font_color", Color(0.82, 0.80, 0.70))
	vbox.add_child(body_lbl)

	var sep3 := HSeparator.new()
	var ss3 := StyleBoxFlat.new()
	ss3.bg_color = C_BORDER_G
	sep3.add_theme_stylebox_override("separator", ss3)
	vbox.add_child(sep3)

	# 시작 버튼
	var start_btn := Button.new()
	start_btn.text = "단서 보드를 열어 수사를 시작한다  →"
	start_btn.add_theme_font_size_override("font_size", 16)
	start_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	start_btn.custom_minimum_size = Vector2(360, 46)
	start_btn.add_theme_stylebox_override("normal",  _make_style(Color(0.08, 0.10, 0.07), C_BORDER_G, 1, 14))
	start_btn.add_theme_stylebox_override("hover",   _make_style(Color(0.12, 0.15, 0.09), C_GOLD, 1, 14))
	start_btn.add_theme_stylebox_override("pressed", _make_style(Color(0.06, 0.08, 0.05), C_GOLD, 2, 14))
	start_btn.add_theme_color_override("font_color", C_GOLD)
	start_btn.pressed.connect(func(): overlay.visible = false)
	vbox.add_child(start_btn)

	return overlay


# ── 타자기 ──────────────────────────────────────────────────────────

func _typewrite_cleanup() -> void:
	if _tw_timer != null and is_instance_valid(_tw_timer):
		_tw_timer.stop()
		_tw_timer.queue_free()
	_tw_timer = null
	AudioManager.stop_typewriter()


func _typewrite_start(label: Label, text: String, on_done: Callable) -> void:
	_typewrite_cleanup()
	_tw_label     = label
	_tw_full_text = text
	_tw_pos       = 0
	_tw_done_cb   = on_done
	_tw_label.text = ""
	if text.is_empty():
		on_done.call()
		return
	AudioManager.start_typewriter()
	_tw_timer = Timer.new()
	_tw_timer.one_shot = true
	_tw_timer.timeout.connect(_typewrite_tick)
	add_child(_tw_timer)
	_tw_timer.start(0.032)


func _typewrite_tick() -> void:
	if _tw_pos >= _tw_full_text.length():
		_typewrite_cleanup()
		if _tw_done_cb.is_valid():
			_tw_done_cb.call()
		return
	_tw_pos += 1
	_tw_label.text = _tw_full_text.substr(0, _tw_pos)
	var ch: String = _tw_full_text[_tw_pos - 1]
	var delay: float = 0.032
	match ch:
		".", "!", "?": delay = 0.10
		",":           delay = 0.07
		"\n":          delay = 0.28
		" ":           delay = 0.022
	# 텍스트 속도 설정 반영 (SettingsManager)
	delay *= SettingsManager.get_text_speed_factor()
	_tw_timer.start(delay)


func _typewrite_skip() -> void:
	if _tw_timer == null or not is_instance_valid(_tw_timer):
		return
	_typewrite_cleanup()
	if _tw_label != null and is_instance_valid(_tw_label):
		_tw_label.text = _tw_full_text
	if _tw_done_cb.is_valid():
		_tw_done_cb.call()


# ── DECODED 도장 + 작전 결과 오버레이 ───────────────────────────────

func _show_decoded_stamp(chapter_id: int, stars: int) -> void:
	if _stamp_overlay != null:
		_stamp_overlay.queue_free()
	_typewrite_cleanup()

	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.82)
	overlay.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.modulate = Color(1.0, 1.0, 1.0, 0.0)
	add_child(overlay)
	_stamp_overlay = overlay

	# 클릭 시 타자기 스킵
	overlay.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed:
			_typewrite_skip()
	)

	# ── 도장 ──
	var stamp := _StampDraw.new()
	stamp.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	stamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stamp.stars_count = stars
	var vp_half: Vector2 = get_viewport_rect().size * 0.5
	stamp.pivot_offset = vp_half
	stamp.position = Vector2(0.0, -get_viewport_rect().size.y * 0.7)
	stamp.scale = Vector2(1.0, 1.0)
	overlay.add_child(stamp)

	# ── 하단 전체 VBox (bottom-aligned) ──
	var outer_v := VBoxContainer.new()
	outer_v.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	outer_v.alignment = BoxContainer.ALIGNMENT_END
	outer_v.add_theme_constant_override("separation", 0)
	overlay.add_child(outer_v)

	# ── 작전 결과 보고서 패널 (타자기) ──
	var story_panel := PanelContainer.new()
	story_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	story_panel.custom_minimum_size = Vector2(620, 0)
	story_panel.modulate.a = 0.0
	var sp_style := StyleBoxFlat.new()
	sp_style.bg_color    = Color(0.04, 0.04, 0.06)
	sp_style.border_color = Color(0.60, 0.18, 0.18, 0.80)
	sp_style.border_width_left   = 1
	sp_style.border_width_right  = 1
	sp_style.border_width_top    = 2
	sp_style.border_width_bottom = 1
	sp_style.content_margin_left   = 28
	sp_style.content_margin_right  = 28
	sp_style.content_margin_top    = 16
	sp_style.content_margin_bottom = 18
	story_panel.add_theme_stylebox_override("panel", sp_style)
	# story_panel이 좌클릭을 흡수하므로 여기서도 스킵 처리
	story_panel.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton \
				and ev.button_index == MOUSE_BUTTON_LEFT and ev.pressed:
			_typewrite_skip()
	)
	outer_v.add_child(story_panel)

	var sp_vbox := VBoxContainer.new()
	sp_vbox.add_theme_constant_override("separation", 8)
	story_panel.add_child(sp_vbox)

	var sp_header := Label.new()
	sp_header.text = "[ 작전 결과 보고서  ·  AFTER ACTION REPORT ]"
	sp_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sp_header.add_theme_font_size_override("font_size", 12)
	sp_header.add_theme_color_override("font_color", Color(0.72, 0.22, 0.22))
	sp_vbox.add_child(sp_header)

	var sp_sep := HSeparator.new()
	var ss := StyleBoxFlat.new()
	ss.bg_color = Color(0.50, 0.15, 0.15, 0.60)
	sp_sep.add_theme_stylebox_override("separator", ss)
	sp_vbox.add_child(sp_sep)

	var story_text_lbl := Label.new()
	story_text_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	story_text_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	story_text_lbl.add_theme_font_size_override("font_size", 15)
	story_text_lbl.add_theme_color_override("font_color", Color(0.88, 0.84, 0.72))
	story_text_lbl.text = ""
	sp_vbox.add_child(story_text_lbl)

	var skip_hint := Label.new()
	skip_hint.text = "— 클릭하여 건너뛰기 —"
	skip_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	skip_hint.add_theme_font_size_override("font_size", 11)
	skip_hint.add_theme_color_override("font_color", Color(0.30, 0.30, 0.38))
	skip_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE   # 클릭이 story_panel로 전달되도록
	sp_vbox.add_child(skip_hint)

	# ── 결과 요약 패널 (타자기 완료 후 등장) ──
	var result_panel := PanelContainer.new()
	result_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	result_panel.custom_minimum_size = Vector2(620, 0)
	result_panel.modulate.a = 0.0
	result_panel.visible = false
	result_panel.add_theme_stylebox_override("panel",
		_make_style(Color(0.06, 0.07, 0.12), C_BORDER_G, 1, 0))
	outer_v.add_child(result_panel)
	_story_result_panel = result_panel

	# ── 레드 헤링 해설 패널 (결과 패널 위) ──────────────────────────────
	var extra_clues: Array = GameManager.current_chapter.get("extra_clues", [])
	if not extra_clues.is_empty():
		var rh_panel := PanelContainer.new()
		rh_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		rh_panel.custom_minimum_size = Vector2(620, 0)
		rh_panel.modulate.a = 0.0
		var rh_style := StyleBoxFlat.new()
		rh_style.bg_color    = Color(0.06, 0.05, 0.03)
		rh_style.border_color = Color(0.72, 0.52, 0.20, 0.80)
		rh_style.border_width_top  = 2
		rh_style.border_width_left = 1; rh_style.border_width_right = 1; rh_style.border_width_bottom = 1
		rh_style.content_margin_left = 24; rh_style.content_margin_right = 24
		rh_style.content_margin_top = 14; rh_style.content_margin_bottom = 14
		rh_panel.add_theme_stylebox_override("panel", rh_style)
		outer_v.add_child(rh_panel)

		var rh_vbox := VBoxContainer.new()
		rh_vbox.add_theme_constant_override("separation", 6)
		rh_panel.add_child(rh_vbox)

		var rh_hdr := Label.new()
		rh_hdr.text = "[ 레드 헤링 해설  ·  RED HERRING REVEAL ]"
		rh_hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rh_hdr.add_theme_font_size_override("font_size", 12)
		rh_hdr.add_theme_color_override("font_color", Color(0.80, 0.58, 0.18))
		rh_vbox.add_child(rh_hdr)

		var rh_sep := HSeparator.new()
		var rh_ss := StyleBoxFlat.new()
		rh_ss.bg_color = Color(0.60, 0.40, 0.12, 0.50)
		rh_sep.add_theme_stylebox_override("separator", rh_ss)
		rh_vbox.add_child(rh_sep)

		for ec in extra_clues:
			var ec_dict: Dictionary = ec
			var rh_lbl := Label.new()
			rh_lbl.text = "▸  [가짜 단서]  %s  —  %s" % [ec_dict.get("title", "?"), ec_dict.get("red_herring_note", "퍼즐 해결과 무관한 단서입니다.")]
			rh_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
			rh_lbl.add_theme_font_size_override("font_size", 13)
			rh_lbl.add_theme_color_override("font_color", Color(0.75, 0.65, 0.42))
			rh_vbox.add_child(rh_lbl)

		# 레드 헤링 패널: 결과 패널 페이드인 완료 후 자동으로 페이드인
		# _decoded_rh_panel 에 저장해 두고, 아래 애니메이션 콜백에서 사용
		_decoded_rh_panel = rh_panel

	var gap := Control.new()
	gap.custom_minimum_size.y = 40
	outer_v.add_child(gap)

	var rmargin := MarginContainer.new()
	rmargin.add_theme_constant_override("margin_left",   28)
	rmargin.add_theme_constant_override("margin_right",  28)
	rmargin.add_theme_constant_override("margin_top",    16)
	rmargin.add_theme_constant_override("margin_bottom", 16)
	result_panel.add_child(rmargin)

	var rvbox := VBoxContainer.new()
	rvbox.add_theme_constant_override("separation", 8)
	rmargin.add_child(rvbox)

	var log_data : Dictionary = GameManager.current_chapter.get("completion_log", {})
	var decoded  : String     = GameManager.get_decoded_message(chapter_id)
	var star_str := "★".repeat(stars) + "☆".repeat(3 - stars)

	var result_lbl := Label.new()
	result_lbl.text = "해독 결과:  %s" % decoded
	result_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_lbl.add_theme_font_size_override("font_size", 16)
	result_lbl.add_theme_color_override("font_color", Color(0.38, 0.88, 0.58))
	rvbox.add_child(result_lbl)

	var log_lbl := Label.new()
	log_lbl.text = "발신: %s  →  수신: %s   ·   %s" % [
		log_data.get("sender", "?"), log_data.get("receiver", "?"), star_str]
	log_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	log_lbl.add_theme_font_size_override("font_size", 13)
	log_lbl.add_theme_color_override("font_color", C_MUTED)
	rvbox.add_child(log_lbl)

	var verdict_lbl := Label.new()
	if stars == 3:
		verdict_lbl.text = "완벽한 해독.  블레츨리 파크가 당신을 주목합니다."
		verdict_lbl.add_theme_color_override("font_color", C_GOLD)
	elif stars == 2:
		verdict_lbl.text = "양호한 성과입니다."
		verdict_lbl.add_theme_color_override("font_color", Color(0.72, 0.85, 0.62))
	else:
		verdict_lbl.text = "임무는 완수했으나 개선이 필요합니다."
		verdict_lbl.add_theme_color_override("font_color", C_MUTED)
	verdict_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	verdict_lbl.add_theme_font_size_override("font_size", 13)
	rvbox.add_child(verdict_lbl)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 20)
	rvbox.add_child(btn_row)

	var menu_btn := Button.new()
	menu_btn.text = "◀  메뉴로"
	menu_btn.add_theme_font_size_override("font_size", 15)
	menu_btn.custom_minimum_size = Vector2(160, 44)
	menu_btn.add_theme_stylebox_override("normal",  _make_style(Color(0.08, 0.09, 0.15), C_BORDER, 1, 12))
	menu_btn.add_theme_stylebox_override("hover",   _make_style(Color(0.12, 0.14, 0.22), C_BORDER_G, 1, 12))
	menu_btn.add_theme_stylebox_override("pressed", _make_style(Color(0.06, 0.07, 0.12), C_GOLD, 1, 12))
	menu_btn.pressed.connect(func(): SceneTransition.fade_to("res://scenes/MainMenu.tscn"))
	btn_row.add_child(menu_btn)

	var log_btn := Button.new()
	log_btn.text = "작전 일지  ▶"
	log_btn.add_theme_font_size_override("font_size", 15)
	log_btn.custom_minimum_size = Vector2(160, 44)
	log_btn.add_theme_stylebox_override("normal",  _make_style(Color(0.07, 0.07, 0.11), C_BORDER, 1, 12))
	log_btn.add_theme_stylebox_override("hover",   _make_style(Color(0.10, 0.10, 0.18), C_BORDER_G, 1, 12))
	log_btn.add_theme_stylebox_override("pressed", _make_style(Color(0.06, 0.06, 0.09), C_GOLD, 1, 12))
	log_btn.add_theme_color_override("font_color", Color(0.70, 0.68, 0.50))
	log_btn.pressed.connect(func(): SceneTransition.fade_to("res://scenes/StoryLog.tscn"))
	btn_row.add_child(log_btn)

	# 다음 레벨 또는 다음 챕터 버튼 — 레벨 파일 존재 여부로 판단
	var cur_level := GameManager.current_level_id
	var next_level_path := "res://data/chapters/chapter_%02d_%02d.json" % [chapter_id, cur_level + 1]
	var next_ch_path    := "res://data/chapters/chapter_%02d_01.json" % (chapter_id + 1)

	if FileAccess.file_exists(next_level_path):
		var next_btn := Button.new()
		next_btn.text = "다음 레벨  →"
		next_btn.add_theme_font_size_override("font_size", 15)
		next_btn.custom_minimum_size = Vector2(180, 44)
		next_btn.add_theme_stylebox_override("normal",  _make_style(Color(0.08, 0.10, 0.07), C_BORDER_G, 1, 12))
		next_btn.add_theme_stylebox_override("hover",   _make_style(Color(0.12, 0.15, 0.09), C_GOLD, 1, 12))
		next_btn.add_theme_stylebox_override("pressed", _make_style(Color(0.06, 0.08, 0.05), C_GOLD, 2, 12))
		next_btn.add_theme_color_override("font_color", C_GOLD)
		next_btn.pressed.connect(func():
			GameManager.current_level_id = cur_level + 1
			SceneTransition.fade_to("res://scenes/Radio.tscn")
		)
		btn_row.add_child(next_btn)
	elif FileAccess.file_exists(next_ch_path):
		var next_btn := Button.new()
		next_btn.text = "다음 챕터  →"
		next_btn.add_theme_font_size_override("font_size", 15)
		next_btn.custom_minimum_size = Vector2(180, 44)
		next_btn.add_theme_stylebox_override("normal",  _make_style(Color(0.08, 0.10, 0.07), C_BORDER_G, 1, 12))
		next_btn.add_theme_stylebox_override("hover",   _make_style(Color(0.12, 0.15, 0.09), C_GOLD, 1, 12))
		next_btn.add_theme_stylebox_override("pressed", _make_style(Color(0.06, 0.08, 0.05), C_GOLD, 2, 12))
		next_btn.add_theme_color_override("font_color", C_GOLD)
		next_btn.pressed.connect(func():
			GameManager.current_chapter_id = chapter_id + 1
			GameManager.current_level_id   = 1
			SceneTransition.fade_to("res://scenes/Radio.tscn")
		)
		btn_row.add_child(next_btn)

	# ── 애니메이션 시퀀스 ──────────────────────────────────────────────
	var log_text: String = GameManager.current_chapter.get("completion_log_text", "")

	var tw: Tween = create_tween()
	tw.set_parallel(false)
	# 1) 배경 페이드인
	tw.tween_property(overlay, "modulate:a", 1.0, 0.18)
	# 2) 도장 낙하
	tw.tween_property(stamp, "position:y", 0.0, 0.22) \
		.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	# 3) 충격 찌부러짐 + 도장 SFX
	tw.tween_callback(func(): AudioManager.play_sfx("stamp"))
	tw.tween_property(stamp, "scale:y", 0.78, 0.06)
	# 4) 바운스 복원
	tw.tween_property(stamp, "scale:y", 1.0, 0.22) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# 5) 잠시 정지
	tw.tween_interval(0.32)
	# 6) 작전 보고서 패널 페이드인
	tw.tween_property(story_panel, "modulate:a", 1.0, 0.28) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# 7) 타자기 시작
	tw.tween_callback(func():
		_typewrite_start(story_text_lbl, log_text, func():
			# 타자기 완료 → 결과 패널 페이드인
			skip_hint.visible = false
			_story_result_panel.visible = true
			_story_result_panel.modulate.a = 0.0
			var tw2: Tween = create_tween()
			tw2.set_parallel(false)
			tw2.tween_property(_story_result_panel, "modulate:a", 1.0, 0.40) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			# 3. 레드 헤링 해설 패널 페이드인 (있는 경우)
			if _decoded_rh_panel != null and is_instance_valid(_decoded_rh_panel):
				tw2.tween_interval(0.20)
				tw2.tween_property(_decoded_rh_panel, "modulate:a", 1.0, 0.40) \
					.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		)
	)


# ────────────────────────────────────────────────────────────────────
#  신호 연결
# ────────────────────────────────────────────────────────────────────

func _connect_signals() -> void:
	GameManager.chapter_loaded.connect(_on_chapter_loaded)
	GameManager.clue_collected.connect(_on_clue_collected)
	GameManager.report_result.connect(_on_report_result)
	GameManager.hint_revealed.connect(_on_hint_revealed)
	GameManager.hint_exhausted.connect(_on_hint_exhausted)
	GameManager.chapter_completed.connect(_on_chapter_completed)


# ────────────────────────────────────────────────────────────────────
#  이벤트 핸들러
# ────────────────────────────────────────────────────────────────────

func _on_chapter_loaded(data: Dictionary) -> void:
	var level_tag := "  ·  LEVEL %d" % GameManager.current_level_id if GameManager.current_level_id > 0 else ""
	_lbl_chapter_title.text = "[ %s%s ]  %s" % [data.get("subtitle", ""), level_tag, data.get("title", "")]
	_lbl_frequency.text     = "%.1f kHz" % data.get("radio_frequency", 0.0)
	var log_data: Dictionary = data.get("completion_log", {})
	_lbl_date.text = log_data.get("date", "")
	# 암호문 헤더 업데이트 (복사 버튼 옆)
	var ct: String = data.get("cipher_text", "")
	if _lbl_cipher_header != null and is_instance_valid(_lbl_cipher_header):
		_lbl_cipher_header.text = "암호문:  %s" % ct
	# 레드 헤링 해설 패널 초기화
	_decoded_rh_panel = null
	# 힌트 버튼 초기화
	if _hint_btn != null and is_instance_valid(_hint_btn):
		_hint_btn.text = "힌트 사용 (0/%d)" % GameManager.HINT_MAX
		_hint_btn.disabled = false

	var all_clues: Array = data.get("clues", []) + data.get("extra_clues", [])
	all_clues.shuffle()
	_populate_clue_cards(all_clues)
	_load_decoder(data)
	_build_report_questions(data.get("report_questions", []))

	# 레벨 1에서만 암호 방식 소개 오버레이 표시 (같은 챕터 레벨 2+는 생략)
	if GameManager.current_level_id == 1:
		_show_cipher_intro(data.get("cipher_type", ""))


func _populate_clue_cards(clues: Array) -> void:
	for child in _clue_list_vbox.get_children():
		child.queue_free()

	if clues.is_empty():
		return

	for clue in clues:
		var clue_type: String = clue.get("type", "")
		var type_color: Color = TYPE_COLORS.get(clue_type, C_BORDER)
		var type_icon: String = TYPE_ICONS.get(clue_type, "[?]")

		var card_btn := Button.new()
		card_btn.text = "%s  %s" % [type_icon, clue.get("title", "")]
		card_btn.custom_minimum_size.y = 44
		card_btn.add_theme_font_size_override("font_size", 12)
		card_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT

		var sn := _make_style(Color(0.07, 0.09, 0.14), C_BORDER, 1, 0)
		sn.border_color = type_color.darkened(0.4)
		sn.border_width_left = 3
		sn.content_margin_left = 12
		sn.content_margin_right = 8
		sn.content_margin_top = 8
		sn.content_margin_bottom = 8
		card_btn.add_theme_stylebox_override("normal", sn)

		var sh := _make_style(Color(0.10, 0.13, 0.21), C_BORDER, 1, 0)
		sh.border_color = type_color
		sh.border_width_left = 3
		sh.content_margin_left = 12
		sh.content_margin_right = 8
		sh.content_margin_top = 8
		sh.content_margin_bottom = 8
		card_btn.add_theme_stylebox_override("hover", sh)
		card_btn.add_theme_color_override("font_hover_color", Color(0.88, 0.84, 0.62))

		var clue_id: String = clue["id"]
		card_btn.pressed.connect(func(): _on_clue_card_pressed(clue_id))
		_clue_list_vbox.add_child(card_btn)


func _on_clue_card_pressed(clue_id: String) -> void:
	var clue := GameManager.collect_clue(clue_id)
	if clue.is_empty():
		return
	AudioManager.play_sfx("paper")
	_show_popup(clue.get("title", "단서"), clue.get("content", ""))


func _on_clue_collected(_clue: Dictionary) -> void:
	pass  # 필요 시 카드 스타일 변경 (수집 표시)


func _load_decoder(data: Dictionary) -> void:
	for child in _cipher_container.get_children():
		child.queue_free()
	_decoder = null

	var cipher_type: String = data.get("cipher_type", "caesar")
	var scene_name  := cipher_type[0].to_upper() + cipher_type.substr(1) + "Decoder"
	var path        := "res://scenes/ciphers/%s.tscn" % scene_name

	if not ResourceLoader.exists(path):
		push_error("ChapterView: 해독기 씬 없음 — " + path)
		return

	_decoder = load(path).instantiate()
	_decoder.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_cipher_container.add_child(_decoder)

	if _decoder.has_method("setup"):
		_decoder.setup(data.get("cipher_text", ""), data.get("cipher_params", {}))

	if _decoder.has_signal("decode_confirmed"):
		_decoder.decode_confirmed.connect(_on_decode_confirmed)


func _on_decode_confirmed(plain_text: String) -> void:
	GameManager.register_decode(plain_text)
	_report_panel.visible = true


func _build_report_questions(questions: Array) -> void:
	_report_inputs.clear()
	for child in _q_container.get_children():
		child.queue_free()

	for q in questions:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		_q_container.add_child(row)

		var q_lbl := Label.new()
		q_lbl.text = q.get("question", "")
		q_lbl.add_theme_font_size_override("font_size", 14)
		q_lbl.add_theme_color_override("font_color", Color(0.80, 0.78, 0.68))
		q_lbl.custom_minimum_size.x = 280
		row.add_child(q_lbl)

		var opt := OptionButton.new()
		opt.add_theme_font_size_override("font_size", 14)
		opt.custom_minimum_size.x = 210
		opt.add_item("── 선택 ──")   # 인덱스 0: 미선택 플레이스홀더
		for choice in q.get("choices", []):
			opt.add_item(choice)
		opt.select(0)
		row.add_child(opt)

		_report_inputs[q["id"]] = opt


func _on_submit_report() -> void:
	# 미선택(인덱스 0) 항목이 있으면 제출 차단
	for qid in _report_inputs:
		var opt: OptionButton = _report_inputs[qid]
		if opt.selected == 0:
			_show_popup("미완성 보고서", "모든 항목을 선택한 뒤 제출하십시오.")
			return

	var answers: Dictionary = {}
	for qid in _report_inputs:
		var opt: OptionButton = _report_inputs[qid]
		# 인덱스 0은 플레이스홀더이므로 실제 선택값은 인덱스 1부터 시작
		answers[qid] = opt.get_item_text(opt.selected).to_upper()
	GameManager.submit_report(answers)


func _on_report_result(correct: bool, feedback: String) -> void:
	if correct:
		AudioManager.play_sfx("correct")
	elif feedback.begins_with("[RH]"):
		AudioManager.play_sfx("wrong")
		var msg := feedback.substr(4)
		_show_popup(
			"단서 재검토 권고",
			msg + "\n\n단서 보드를 재검토하십시오. 가짜 단서에 혼동됐을 수 있습니다."
		)
	else:
		AudioManager.play_sfx("wrong")
		_show_popup("재검토 요망", feedback + "\n\n해독기를 다시 확인하고 보고서를 수정하십시오.")


func _on_hint_revealed(hint_text: String) -> void:
	var used: int = GameManager.hint_count
	var max_h: int = GameManager.HINT_MAX
	if _hint_btn != null and is_instance_valid(_hint_btn):
		_hint_btn.text = "힌트 사용 (%d/%d)" % [used, max_h]
		if used >= max_h:
			_hint_btn.disabled = true
	_show_popup("힌트 [%d/%d]" % [used, max_h], hint_text)


func _on_hint_exhausted() -> void:
	if _hint_btn != null and is_instance_valid(_hint_btn):
		_hint_btn.disabled = true
	_show_popup("힌트 소진", "이번 임무에서 사용 가능한 힌트를 모두 소진했습니다.\n단서 보드를 다시 검토하십시오.")


func _on_chapter_completed(chapter_id: int, stars: int) -> void:
	# DECODED 도장 오버레이로 완료 처리 — 팝업 대신 전체 화면 연출
	_show_decoded_stamp(chapter_id, stars)
	# 타이머 중지 (완료됐으므로 더 이상 갱신 불필요)
	if _lbl_timer != null and is_instance_valid(_lbl_timer):
		var secs: int = int(GameManager.level_elapsed_secs)
		if secs < 60:
			_lbl_timer.text = "%d초 ✓" % secs
		else:
			_lbl_timer.text = "%d:%02d ✓" % [secs / 60, secs % 60]


# ────────────────────────────────────────────────────────────────────
#  팝업 유틸리티
# ────────────────────────────────────────────────────────────────────

func _show_popup(title: String, body: String) -> void:
	_popup_title_lbl.text = title
	_popup_body_lbl.text  = body
	_popup_overlay.visible = true
	# 항상 팝업이 최상위에 렌더링되도록 맨 뒤 자식으로 이동
	move_child(_popup_overlay, get_child_count() - 1)


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


# ────────────────────────────────────────────────────────────────────
#  BOMBE 이스터에그 — 키보드로 "BOMBE" 입력 시 현재 레벨 1성 강제 완료
# ────────────────────────────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key_event: InputEventKey = event
	if not key_event.pressed or key_event.echo:
		return

	# 7. 보고서 Enter 키 단축키 — 보고서 패널이 표시 중이고 모든 항목 선택 시
	if key_event.keycode == KEY_ENTER or key_event.keycode == KEY_KP_ENTER:
		if _report_panel != null and _report_panel.visible:
			_on_submit_report()
			return

	# BOMBE 이스터에그 (알파벳 키만 처리)
	var ch := char(key_event.unicode).to_upper()
	if ch.length() != 1 or ch < "A" or ch > "Z":
		return
	_bombe_buffer += ch
	if _bombe_buffer.length() > _BOMBE_CODE.length():
		_bombe_buffer = _bombe_buffer.right(_BOMBE_CODE.length())
	if _bombe_buffer == _BOMBE_CODE:
		_bombe_buffer = ""
		_trigger_bombe_easter_egg()


func _trigger_bombe_easter_egg() -> void:
	if GameManager.is_level_complete(GameManager.current_chapter_id, GameManager.current_level_id):
		return
	GameManager.debug_complete_level()
	_show_popup(
		"〔 B O M B E  A C T I V A T E D 〕",
		"튜링의 기계가 가동됐습니다.\n모든 경우의 수가 검토됐습니다.\n\n...이 임무는 완료 처리됩니다.\n(1성 기록)"
	)
