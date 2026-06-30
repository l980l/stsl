# scenes/tutorial/tutorial_driver.gd
# 튜토리얼 레슨 스텝 시퀀스 구동 오버레이. 시그널·데이터 기반(battle 비의존).
class_name TutorialDriver
extends CanvasLayer

signal lesson_completed
signal step_changed  # 현재 스텝이 바뀔 때마다 (battle_scene 이 카드 게이팅 재적용)

var _steps: Array = []
var _idx: int = -1
var _label: Label = null
var _msg_bg: TextureRect = null
var _breathe_tween: Tween = null
var _click_catcher: Control = null

func _ready() -> void:
	layer = 60
	# 화면 클릭 캐처 — complete_event == "screen_clicked" 스텝에서만 STOP(클릭 가로채 다음으로),
	# 그 외 스텝에선 IGNORE 로 게임 입력을 통과시킨다. 라벨/배경보다 뒤(아래)에 둬 시각은 가리지 않음.
	_click_catcher = Control.new()
	_click_catcher.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_click_catcher.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_click_catcher.gui_input.connect(_on_catcher_input)
	add_child(_click_catcher)
	# 화면 전체 디밍은 사용 안 함 — 카드 게이팅(비활성 카드 어둡게)으로 강조하므로 불필요.
	# 안내 문구 뒤에만 어두운 띠 (배틀씬 메시지와 동일한 좌우 페이드 그라디언트) → 가독성 확보.
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	grad.colors = PackedColorArray([Color(0, 0, 0, 0), Color(0, 0, 0, 0.62), Color(0, 0, 0, 0)])
	var grad_tex := GradientTexture1D.new()
	grad_tex.gradient = grad
	_msg_bg = TextureRect.new()
	_msg_bg.texture = grad_tex
	_msg_bg.stretch_mode = TextureRect.STRETCH_SCALE
	_msg_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_msg_bg.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_msg_bg.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_msg_bg.offset_left = -660
	_msg_bg.offset_right = 660
	_msg_bg.offset_top = 146
	_msg_bg.offset_bottom = 266
	add_child(_msg_bg)
	_msg_bg.visible = false
	# 상단 중앙 안내 문구 — 흰색↔황금 breathe 애니메이션.
	_label = Label.new()
	_label.theme_type_variation = "TitleLabel"
	_label.add_theme_font_size_override("font_size", 32)
	_label.add_theme_color_override("font_color", SacredPalette.BONE_100)
	_label.autowrap_mode = TextServer.AUTOWRAP_OFF  # 줄바꿈 안 함 — 폭은 fit_text 로 폰트 축소
	_label.clip_text = false
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_label.offset_left = -560
	_label.offset_right = 560
	_label.offset_top = 148
	_label.offset_bottom = 264
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
	_breathe_tween.tween_property(_label, "theme_override_colors/font_color", c_gold, 0.5).set_trans(Tween.TRANS_SINE)
	_breathe_tween.tween_property(_label, "theme_override_colors/font_color", c_white, 0.5).set_trans(Tween.TRANS_SINE)

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
	if _msg_bg:
		_msg_bg.visible = text != ""
	if text != "":
		# 줄바꿈 없이 폭(1120)에 맞춰 폰트 자동 축소 (32 → 최소 18)
		LabelUtils.fit_text(_label, 32, 18, 1120.0)
		_start_breathe()
	else:
		_stop_breathe()
	_update_click_catcher()

# 현재 스텝이 화면 클릭으로 완료되는 스텝이면 클릭 캐처 활성화.
func _update_click_catcher() -> void:
	if _click_catcher == null:
		return
	var ev: String = current_step().get("complete_event", "")
	_click_catcher.mouse_filter = Control.MOUSE_FILTER_STOP if ev == "screen_clicked" else Control.MOUSE_FILTER_IGNORE

func _on_catcher_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		notify("screen_clicked")

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
