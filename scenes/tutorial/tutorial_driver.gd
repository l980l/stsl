# scenes/tutorial/tutorial_driver.gd
# 튜토리얼 레슨 스텝 시퀀스 구동 오버레이. 시그널·데이터 기반(battle 비의존).
class_name TutorialDriver
extends CanvasLayer

signal lesson_completed
signal step_changed  # 현재 스텝이 바뀔 때마다 (battle_scene 이 카드 게이팅 재적용)

var _steps: Array = []
var _idx: int = -1
var _label: Label = null
var _dim: ColorRect = null
var _breathe_tween: Tween = null

func _ready() -> void:
	layer = 60
	_dim = ColorRect.new()
	_dim.color = Color(0, 0, 0, 0.25)
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_dim)
	# 상단 중앙 안내 문구 — 배경 없이 텍스트만, 흰색↔황금 breathe 애니메이션.
	_label = Label.new()
	_label.theme_type_variation = "TitleLabel"
	_label.add_theme_font_size_override("font_size", 32)
	_label.add_theme_color_override("font_color", SacredPalette.BONE_100)
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_label.offset_left = -560
	_label.offset_right = 560
	_label.offset_top = 150
	_label.offset_bottom = 280
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)
	_label.visible = false

# 안내 문구 호흡 애니메이션 — 흰색 → 황금 → 흰색 반복.
func _start_breathe() -> void:
	if _breathe_tween != null and _breathe_tween.is_valid():
		return
	var c_white: Color = SacredPalette.BONE_100
	var c_gold: Color = SacredPalette.BRASS_300
	_label.add_theme_color_override("font_color", c_white)
	_breathe_tween = create_tween().set_loops()
	_breathe_tween.tween_property(_label, "theme_override_colors/font_color", c_gold, 1.4).set_trans(Tween.TRANS_SINE)
	_breathe_tween.tween_property(_label, "theme_override_colors/font_color", c_white, 1.4).set_trans(Tween.TRANS_SINE)

func _stop_breathe() -> void:
	if _breathe_tween != null and _breathe_tween.is_valid():
		_breathe_tween.kill()
	_breathe_tween = null

func start(steps: Array) -> void:
	_steps = steps
	_idx = -1
	_advance()

func _advance() -> void:
	_idx += 1
	if _idx >= _steps.size():
		_render("")
		step_changed.emit()
		lesson_completed.emit()
		return
	_render(tr(_steps[_idx].get("text", "")))
	step_changed.emit()

func _render(text: String) -> void:
	if _label == null:
		return
	_label.text = text
	_label.visible = text != ""
	if text != "":
		_start_breathe()
	else:
		_stop_breathe()

func notify(event: String, data: Dictionary = {}) -> void:
	if is_finished():
		return
	var step: Dictionary = _steps[_idx]
	if step.get("complete_event", "") != event:
		return
	var check = step.get("complete_check", null)
	if check is Callable and not check.call(data):
		return
	_advance()

func current_step() -> Dictionary:
	if _idx < 0 or _idx >= _steps.size():
		return {}
	return _steps[_idx]

func current_allowed_cards() -> Array:
	var step: Dictionary = current_step()
	return step.get("allowed_cards", [])

func is_finished() -> bool:
	return _idx >= _steps.size()
