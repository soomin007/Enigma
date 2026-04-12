## SceneTransition.gd — 씬 전환 페이드 애니메이션 (전역 싱글톤)
## 모든 씬 전환은 fade_to()를 사용한다.
## CanvasLayer로 동작하므로 씬이 변경되어도 오버레이가 유지된다.
extends CanvasLayer

const FADE_DURATION := 0.22

var _overlay : ColorRect
var _tween   : Tween = null


func _ready() -> void:
	layer = 128   # 모든 UI 위에 렌더
	_overlay = ColorRect.new()
	_overlay.color = Color(0.0, 0.0, 0.0, 1.0)
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_overlay)
	# 게임 첫 시작 시 페이드인
	_do_fade_in()


## 씬을 페이드 아웃 후 전환한다. 모든 씬 전환에 이 함수를 사용한다.
func fade_to(path: String) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_tween = create_tween()
	_tween.set_parallel(false)
	_tween.tween_property(_overlay, "color:a", 1.0, FADE_DURATION) \
		  .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_tween.tween_callback(func():
		get_tree().change_scene_to_file(path)
	)
	_tween.tween_interval(0.04)
	_tween.tween_callback(_do_fade_in)


## 현재 씬을 다시 로드 (설정 초기화 등)
func reload_scene() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_tween = create_tween()
	_tween.set_parallel(false)
	_tween.tween_property(_overlay, "color:a", 1.0, FADE_DURATION) \
		  .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_tween.tween_callback(func():
		get_tree().reload_current_scene()
	)
	_tween.tween_interval(0.04)
	_tween.tween_callback(_do_fade_in)


func _do_fade_in() -> void:
	# 실행 중인 Tween에 스텝을 추가하면 오류가 나므로, 항상 새 Tween을 만든다.
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_overlay, "color:a", 0.0, FADE_DURATION) \
		  .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween.tween_callback(func(): _overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE)
