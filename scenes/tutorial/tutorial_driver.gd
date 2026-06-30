# scenes/tutorial/tutorial_driver.gd
# 튜토리얼 레슨 스텝 시퀀스 구동 오버레이. 시그널·데이터 기반(battle 비의존).
class_name TutorialDriver
extends CanvasLayer

signal lesson_completed
signal step_changed  # 현재 스텝이 바뀔 때마다 (battle_scene 이 카드 게이팅 재적용)

var _steps: Array = []
var _idx: int = -1
var _label: Label = null
var _banner: PanelContainer = null
var _dim: ColorRect = null

func _ready() -> void:
	layer = 60
	_dim = ColorRect.new()
	_dim.color = Color(0, 0, 0, 0.25)
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_dim)
	# 상단 중앙 안내 배너 — 어두운 바탕 + 황동 밑줄로 어떤 배경 위에서도 읽히게.
	var P := SacredPalette
	_banner = PanelContainer.new()
	_banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_banner.offset_top = 56
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.04, 0.06, 0.88)
	sb.border_color = P.BRASS_500
	sb.border_width_bottom = 2
	sb.content_margin_left = 48
	sb.content_margin_right = 48
	sb.content_margin_top = 18
	sb.content_margin_bottom = 18
	sb.corner_radius_top_left = 4
	sb.corner_radius_top_right = 4
	sb.corner_radius_bottom_left = 4
	sb.corner_radius_bottom_right = 4
	_banner.add_theme_stylebox_override("panel", sb)
	add_child(_banner)
	_label = Label.new()
	_label.theme_type_variation = "TitleLabel"
	_label.add_theme_font_size_override("font_size", 30)
	_label.add_theme_color_override("font_color", P.BONE_100)
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.custom_minimum_size = Vector2(1000, 0)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner.add_child(_label)
	_banner.visible = false

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
	if _label:
		_label.text = text
	if _banner:
		_banner.visible = text != ""

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
