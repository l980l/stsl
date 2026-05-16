# scenes/debug/background_preview.gd
# 배경 미리보기 — 신화/Act/시각/날씨 명시 선택 + 재생성 + 캐릭터/적 placeholder 토글.
# y_sort 검증, fg 배치 검증, env 매트릭스 빠른 점검용.
extends Node2D

const SBG := preload("res://scenes/components/scene_background.gd")
const CRITTERS := preload("res://scenes/components/scene_critters.gd")
const WEATHER := preload("res://scenes/components/weather_particles.gd")

# battle_scene.tscn 슬롯 좌표 그대로 (y_sort 검증용)
const HERO_SLOTS := [Vector2(345, 228), Vector2(77, 274), Vector2(610, 283)]
const ENEMY_SLOTS := [
	Vector2(1332, 216), Vector2(1593, 251), Vector2(1073, 281),
	Vector2(1084, 498), Vector2(1609, 484), Vector2(1354, 472),
]

const MYTHS := ["greek"]  # 1차 PR — greek 만
const TIMES := ["random", "dawn", "day", "dusk", "night"]
const WEATHERS := ["random", "clear", "cloudy", "overcast", "rain", "snow"]

var _scene_bg: Node2D = null
var _critters: Node2D = null
var _weather: Node2D = null
var _fg_nodes: Array = []        # spawn 된 fg Sprite2D (재생성 시 제거)
var _char_nodes: Array = []      # placeholder 노드들 (토글 시 제거)
var _info_lbl: Label = null

var _myth_opt: OptionButton
var _act_opt: OptionButton
var _time_opt: OptionButton
var _weather_opt: OptionButton
var _hero_checks: Array = []     # CheckBox × 3
var _enemy_checks: Array = []    # CheckBox × 6

func _ready() -> void:
	y_sort_enabled = true
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.05, 0.08)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.z_index = -1000
	add_child(bg)
	_build_ui()
	_regenerate()

func _build_ui() -> void:
	var cl := CanvasLayer.new()
	cl.layer = 100
	add_child(cl)
	var panel := VBoxContainer.new()
	panel.position = Vector2(20, 16)
	panel.add_theme_constant_override("separation", 6)
	cl.add_child(panel)

	var title := Label.new()
	title.text = "Background Preview — 옵션 선택 후 재생성"
	title.add_theme_font_size_override("font_size", 18)
	panel.add_child(title)

	# 신화 / Act / 시각 / 날씨 OptionButton 4개
	_myth_opt = _make_option_row(panel, "신화", MYTHS)
	_act_opt = _make_option_row(panel, "Act", ["1", "2", "3"])
	_time_opt = _make_option_row(panel, "시각", TIMES)
	_weather_opt = _make_option_row(panel, "날씨", WEATHERS)

	# 재생성 버튼
	var regen := Button.new()
	regen.text = "🔄 재생성 (Space)"
	regen.custom_minimum_size = Vector2(220, 40)
	regen.pressed.connect(_regenerate)
	panel.add_child(regen)

	# 캐릭터 placeholder 토글
	var sep := HSeparator.new()
	panel.add_child(sep)
	var slot_lbl := Label.new()
	slot_lbl.text = "── 캐릭터 placeholder ──"
	panel.add_child(slot_lbl)
	for i in 3:
		var cb := CheckBox.new()
		cb.text = "Hero %d (%d, %d)" % [i + 1, HERO_SLOTS[i].x, HERO_SLOTS[i].y]
		cb.button_pressed = true
		cb.toggled.connect(_on_chars_toggled)
		_hero_checks.append(cb)
		panel.add_child(cb)
	for i in 6:
		var cb := CheckBox.new()
		cb.text = "Enemy %d (%d, %d)" % [i + 1, ENEMY_SLOTS[i].x, ENEMY_SLOTS[i].y]
		cb.button_pressed = (i < 3)  # 기본 3마리만
		cb.toggled.connect(_on_chars_toggled)
		_enemy_checks.append(cb)
		panel.add_child(cb)

	# info label (env 표시)
	_info_lbl = Label.new()
	_info_lbl.add_theme_color_override("font_color", Color(0.9, 0.95, 0.7))
	panel.add_child(_info_lbl)

func _make_option_row(parent: Control, label: String, values: Array) -> OptionButton:
	var hb := HBoxContainer.new()
	parent.add_child(hb)
	var l := Label.new()
	l.text = label
	l.custom_minimum_size = Vector2(60, 0)
	hb.add_child(l)
	var opt := OptionButton.new()
	opt.custom_minimum_size = Vector2(180, 0)
	for v in values:
		opt.add_item(str(v))
	opt.selected = 0
	hb.add_child(opt)
	return opt

var _bg_debug_overlay: Node2D = null

func _input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and not ev.echo:
		if ev.keycode == KEY_SPACE:
			_regenerate()
		elif ev.keycode == KEY_D:
			toggle_bg_debug()

func toggle_bg_debug() -> void:
	if _bg_debug_overlay and is_instance_valid(_bg_debug_overlay):
		_bg_debug_overlay.queue_free()
		_bg_debug_overlay = null
		return
	_bg_debug_overlay = Node2D.new()
	_bg_debug_overlay.z_index = 5000
	add_child(_bg_debug_overlay)
	for n in _fg_nodes:
		if is_instance_valid(n) and n is Sprite2D:
			_draw_dbg_box(n, "FG", Color(1.0, 0.85, 0.2))
	for cn in _char_nodes:
		if is_instance_valid(cn) and cn is Sprite2D:
			_draw_dbg_box(cn, "CHAR", Color(0.4, 0.85, 1.0))

func _draw_dbg_box(node: Node2D, label: String, color: Color) -> void:
	var r: Rect2
	if node is Sprite2D:
		var lr: Rect2 = (node as Sprite2D).get_rect()
		r = Rect2(node.global_position + lr.position * node.scale, lr.size * node.scale)
	else:
		r = Rect2(node.global_position - Vector2(60, 96), Vector2(120, 192))
	var line := Line2D.new()
	line.points = PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y), r.position])
	line.default_color = color
	line.width = 2.0
	_bg_debug_overlay.add_child(line)
	var lbl := Label.new()
	lbl.text = "%s\nx=%d  pos.y=%d  z=%d  foot=%d" % [label, int(node.global_position.x), int(node.global_position.y), node.z_index, int(r.end.y)]
	lbl.position = Vector2(r.position.x, r.position.y - 50)
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_font_size_override("font_size", 14)
	_bg_debug_overlay.add_child(lbl)

func _regenerate() -> void:
	# 기존 정리
	if _scene_bg:
		_scene_bg.queue_free()
		_scene_bg = null
	if _critters:
		_critters.queue_free()
		_critters = null
	if _weather:
		_weather.queue_free()
		_weather = null
	for n in _fg_nodes:
		if is_instance_valid(n):
			n.queue_free()
	_fg_nodes.clear()

	# 옵션 읽기
	var myth: String = MYTHS[_myth_opt.selected]
	var act: int = _act_opt.selected + 1
	var time_choice: String = TIMES[_time_opt.selected]
	var weather_choice: String = WEATHERS[_weather_opt.selected]

	# 캐릭터 / UI 영역 Rect2 array (체크된 슬롯만 — 토글에 따라 fg 회피 영역 변동)
	var occupied: Array = _build_occupied_rects()

	_scene_bg = SBG.new()
	add_child(_scene_bg)
	if time_choice == "random" and weather_choice == "random":
		_scene_bg.setup(myth, act, randi(), occupied)
	else:
		_scene_bg.force_env(myth, act, randi(), time_choice, weather_choice, occupied)
	var actual_env: Dictionary = _scene_bg.current_env

	# fg specs spawn (battle_scene 패턴)
	for spec_v in _scene_bg.front_specs:
		var spec: Dictionary = spec_v
		if not ResourceLoader.exists(spec["path"]):
			continue
		var spr := Sprite2D.new()
		spr.texture = load(spec["path"])
		var sc: float = spec["scale"]
		spr.scale = Vector2(sc, sc)
		var anchor: Vector2 = spec["pos"]
		spr.position = anchor
		spr.offset = Vector2(0, -spr.texture.get_height() * 0.5)
		spr.modulate = actual_env.get("tint", Color.WHITE)
		add_child(spr)
		_fg_nodes.append(spr)

	# critters
	_critters = CRITTERS.new()
	add_child(_critters)
	_critters.setup(actual_env)

	# weather
	_weather = WEATHER.new()
	_weather.layer = -50
	add_child(_weather)
	_weather.setup(actual_env.get("weather", "clear"))

	# 캐릭터 placeholder 재생성
	_rebuild_char_placeholders()

	# info
	_info_lbl.text = "env: %s / Act %d / %s / %s\nfg %d개 / hero %d / enemy %d" % [
		myth, act,
		actual_env.get("time_of_day", "?"),
		actual_env.get("weather", "?"),
		_fg_nodes.size(),
		_count_active(_hero_checks),
		_count_active(_enemy_checks),
	]

func _on_chars_toggled(_pressed: bool) -> void:
	_rebuild_char_placeholders()

# 체크된 캐릭터 슬롯 — 240×280 panel 영역 + UI 영역
func _build_occupied_rects() -> Array:
	const SLOT_W := 240
	const SLOT_H := 280
	var rects: Array = []
	for i in 3:
		if _hero_checks[i].button_pressed:
			rects.append(Rect2(HERO_SLOTS[i].x, HERO_SLOTS[i].y, SLOT_W, SLOT_H))
	for i in 6:
		if _enemy_checks[i].button_pressed:
			rects.append(Rect2(ENEMY_SLOTS[i].x, ENEMY_SLOTS[i].y, SLOT_W, SLOT_H))
	return rects

func _rebuild_char_placeholders() -> void:
	for n in _char_nodes:
		if is_instance_valid(n):
			n.queue_free()
	_char_nodes.clear()
	for i in 3:
		if i < _hero_checks.size() and _hero_checks[i].button_pressed:
			_spawn_char_placeholder(HERO_SLOTS[i], Color(0.4, 0.7, 1.0, 0.85), "H%d" % (i + 1))
	for i in 6:
		if i < _enemy_checks.size() and _enemy_checks[i].button_pressed:
			_spawn_char_placeholder(ENEMY_SLOTS[i], Color(1.0, 0.4, 0.4, 0.85), "E%d" % (i + 1))

func _spawn_char_placeholder(slot_pos: Vector2, color: Color, label: String) -> void:
	# battle_scene 과 동일 변환:
	#   panel = slot_pos~slot_pos+(SLOT_W=240, SLOT_H=280)
	#   캐릭터 sprite 중심 = slot_pos + (120, 184), scale (1.44, 2.4) → 매우 길게
	# placeholder = panel 영역 (240×280) + sprite 위치 마커
	const SLOT_W := 240
	const SLOT_H := 280
	# 슬롯 panel 영역 (반투명 박스 — 캐릭터 영역 표시)
	var panel := ColorRect.new()
	panel.color = Color(color.r, color.g, color.b, 0.25)
	panel.size = Vector2(SLOT_W, SLOT_H)
	panel.position = slot_pos
	add_child(panel)
	_char_nodes.append(panel)
	# 실제 캐릭터 sprite placeholder — y_sort 기준 발 위치
	# battle_scene: char_node.position = (slot.x + 120, slot.y + 184), scale (1.44, 2.4)
	# 발 위치 = position.y + sprite_h*scale.y*0.5. 단순화: 발 = slot.y + SLOT_H
	var foot_y: float = slot_pos.y + SLOT_H
	var spr := Sprite2D.new()
	var pl_w := 110
	var pl_h := 200
	var img := Image.create(pl_w, pl_h, false, Image.FORMAT_RGBA8)
	img.fill(Color(color.r, color.g, color.b, 0.85))
	spr.texture = ImageTexture.create_from_image(img)
	spr.position = Vector2(slot_pos.x + SLOT_W * 0.5, foot_y)  # y_sort 기준 = 발
	spr.offset = Vector2(0, -pl_h * 0.5)  # 발이 origin 에 위치
	add_child(spr)
	_char_nodes.append(spr)
	# 라벨
	var lbl := Label.new()
	lbl.text = label
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.position = Vector2(slot_pos.x + SLOT_W * 0.5 - 18, slot_pos.y + 20)
	lbl.z_index = 50
	add_child(lbl)
	_char_nodes.append(lbl)

func _count_active(arr: Array) -> int:
	var n := 0
	for cb in arr:
		if cb.button_pressed:
			n += 1
	return n
