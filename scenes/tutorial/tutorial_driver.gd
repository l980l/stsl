# scenes/tutorial/tutorial_driver.gd
# 튜토리얼 레슨 스텝 시퀀스 구동 오버레이. 시그널·데이터 기반(battle 비의존).
class_name TutorialDriver
extends CanvasLayer

signal lesson_completed

var _steps: Array = []
var _idx: int = -1
var _label: Label = null
var _dim: ColorRect = null

func _ready() -> void:
	layer = 60
	_dim = ColorRect.new()
	_dim.color = Color(0, 0, 0, 0.45)
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_dim)
	_label = Label.new()
	_label.theme_type_variation = "TitleLabel"
	_label.add_theme_font_size_override("font_size", 28)
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_label.offset_left = -520
	_label.offset_right = 520
	_label.offset_top = -220
	_label.offset_bottom = -120
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)

func start(steps: Array) -> void:
	_steps = steps
	_idx = -1
	_advance()

func _advance() -> void:
	_idx += 1
	if _idx >= _steps.size():
		_render("")
		lesson_completed.emit()
		return
	_render(tr(_steps[_idx].get("text", "")))

func _render(text: String) -> void:
	if _label:
		_label.text = text

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
