# scenes/debug/vfx_preview_gpu.gd
# GPU 하이브리드 VFX 프리뷰 — vfx_preview.gd 와 같은 패턴 (1:2 사각형, drag, 4-way, particle quality toggle)
# 단 신규 `*_gpu.gd` 5 개만 등록. 기존 vfx_preview.tscn 과 별개로 F6 실행해서 시각 비교.
extends Node2D

const WARRIOR_BUFF_GPU  := preload("res://scenes/vfx/warrior_buff_gpu.gd")
const HOLY_BUFF_GPU     := preload("res://scenes/vfx/holy_buff_gpu.gd")
const BOSS_DEATH_GPU    := preload("res://scenes/vfx/boss_death_gpu.gd")
const SIG_RAGNAROK_GPU  := preload("res://scenes/vfx/sig_ragnarok_gpu.gd")
const FIRE_BLAST_GPU    := preload("res://scenes/vfx/fire_blast_gpu.gd")

# Phase 1 등록 VFX (사용자 결정: 5 개 무거운 것)
const VFX_GPU := [
	{"name": "warrior_buff_gpu", "kind": "beam", "path": "res://scenes/vfx/warrior_buff_gpu.gd"},
	{"name": "holy_buff_gpu",    "kind": "beam", "path": "res://scenes/vfx/holy_buff_gpu.gd"},
	{"name": "boss_death_gpu",   "kind": "beam", "path": "res://scenes/vfx/boss_death_gpu.gd"},
	{"name": "sig_ragnarok_gpu", "kind": "beam", "path": "res://scenes/vfx/sig_ragnarok_gpu.gd"},
	{"name": "fire_blast_gpu",   "kind": "beam", "path": "res://scenes/vfx/fire_blast_gpu.gd"},
]

# 인게임 캐릭터 sprite 영역 (vfx_preview.gd 와 동일)
const _SPRITE_W := 96.0
const _SPRITE_H := 192.0
const _CHAR_FOOT_Y_OFFSET := 96.0

# caster 무시 / 타겟 위치 발치 anchor 사용하는 VFX (vfx_preview.gd 의 분기와 동일)
const _TARGET_ONLY_VFX := ["boss_death_gpu", "sig_ragnarok_gpu", "warrior_buff_gpu", "holy_buff_gpu"]

var _caster_pos := Vector2(420, 540)
var _target_pos := Vector2(1500, 540)
var _dragging: int = -1
var _auto := false
var _selected: Dictionary = VFX_GPU[0]
var _info: Label
var _impact_label: Label
var _compare_4way: bool = false

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.05, 0.08)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var panel := VBoxContainer.new()
	panel.position = Vector2(24, 8)
	add_child(panel)

	var title := Label.new()
	title.text = "GPU 하이브리드 VFX 프리뷰 — 버튼 선택 → 빈 곳 클릭으로 타겟 이동+재생 / [Space] 재생"
	panel.add_child(title)

	var gpu_lbl := Label.new()
	gpu_lbl.text = "── GPU 하이브리드 (Phase 1: 5 개) ──"
	gpu_lbl.add_theme_color_override("font_color", Color(0.7, 1.0, 0.7))
	panel.add_child(gpu_lbl)
	var grid := GridContainer.new()
	grid.columns = 5
	panel.add_child(grid)
	for entry in VFX_GPU:
		var b := Button.new()
		b.text = entry["name"]
		b.custom_minimum_size = Vector2(180.0, 0.0)
		b.pressed.connect(_select_and_play.bind(entry))
		grid.add_child(b)

	var auto_btn := CheckBox.new()
	auto_btn.text = "자동 반복 (1.8s)"
	auto_btn.toggled.connect(func(on: bool) -> void: _auto = on)
	panel.add_child(auto_btn)

	# 파티클 갯수 토글
	var pq_label := Label.new()
	pq_label.text = "파티클 갯수 (현재: %s)" % GameSettings.particle_key
	panel.add_child(pq_label)
	var pq_box := HBoxContainer.new()
	panel.add_child(pq_box)
	for k in GameSettings.PARTICLE_KEYS:
		var idx_str := str(GameSettings.PARTICLE_VALUES[GameSettings.PARTICLE_KEYS.find(k)])
		var pq_btn := Button.new()
		pq_btn.text = "x" + idx_str
		pq_btn.custom_minimum_size = Vector2(80, 0)
		pq_btn.pressed.connect(func() -> void:
			GameSettings.set_particle_quality(k)
			pq_label.text = "파티클 갯수 (현재: %s)" % GameSettings.particle_key
			_update_info())
		pq_box.add_child(pq_btn)

	var cmp_btn := CheckBox.new()
	cmp_btn.text = "4-way 비교 (x0.1 | x0.25 | x0.5 | x1.0 동시 spawn)"
	cmp_btn.toggled.connect(func(on: bool) -> void: _compare_4way = on)
	panel.add_child(cmp_btn)

	_info = Label.new()
	panel.add_child(_info)
	_update_info()

	_impact_label = Label.new()
	_impact_label.text = ""
	_impact_label.add_theme_font_size_override("font_size", 36)
	_impact_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	_impact_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_impact_label.add_theme_constant_override("outline_size", 6)
	_impact_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_impact_label.modulate.a = 0.0
	add_child(_impact_label)

	var t := Timer.new()
	t.wait_time = 1.8
	t.autostart = true
	t.timeout.connect(func() -> void:
		if _auto:
			_play(_selected))
	add_child(t)
	queue_redraw()

func _update_info() -> void:
	var s := "선택: %s (%s)\n" % [_selected["name"], _selected["kind"]]
	s += "GPU 하이브리드 — 표준 파티클은 GPUParticles2D, 폴리곤 effect 는 CPU 유지.\n"
	s += "기존 vfx_preview 와 비교하려면 F6 으로 vfx_preview.tscn 따로 실행."
	if _selected.get("kind", "") == "beam":
		var script: GDScript = load(_selected["path"]) as GDScript
		if script and "IMPACT_DELAY" in script:
			s += "\n임팩트 시점: %.2fs" % script.IMPACT_DELAY
	_info.text = s

func _select_and_play(entry: Dictionary) -> void:
	_selected = entry
	_update_info()
	_play(entry)

func _play(entry: Dictionary) -> void:
	var script: GDScript = load(entry["path"]) as GDScript
	if _compare_4way:
		var x_offsets := [-540.0, -180.0, 180.0, 540.0]
		var scales    := [0.1, 0.25, 0.5, 1.0]
		for i in 4:
			var fx_n: Node2D = script.new()
			add_child(fx_n)
			fx_n.position = Vector2.ZERO
			if "_particle_scale_override" in fx_n:
				fx_n.set("_particle_scale_override", scales[i])
			var t_pos: Vector2 = _target_pos + Vector2(x_offsets[i], 0.0)
			var c_pos: Vector2 = _caster_pos + Vector2(x_offsets[i], 0.0)
			if entry["name"] in _TARGET_ONLY_VFX:
				c_pos = t_pos
			_apply_ground_anchor(fx_n, c_pos, t_pos)
			if i == 2:
				if fx_n.has_signal("screen_effect"):
					fx_n.screen_effect.connect(_preview_flash)
					fx_n.screen_effect.connect(_show_impact_marker.bind("%s — 4way" % entry["name"]))
			fx_n.play(c_pos, t_pos)
			_spawn_compare_label(t_pos, "x" + str(scales[i]))
	else:
		var fx: Node2D = script.new()
		add_child(fx)
		fx.position = Vector2.ZERO
		if fx.has_signal("screen_effect"):
			fx.screen_effect.connect(_preview_flash)
			fx.screen_effect.connect(_show_impact_marker.bind(entry["name"]))
		if entry["name"] in _TARGET_ONLY_VFX:
			_apply_ground_anchor(fx, _target_pos, _target_pos)
			fx.play(_target_pos, _target_pos)
		else:
			_apply_ground_anchor(fx, _caster_pos, _target_pos)
			fx.play(_caster_pos, _target_pos)

func _apply_ground_anchor(fx: Node2D, _c_center: Vector2, t_center: Vector2) -> void:
	if not fx.has_method("set_ground_anchor"):
		return
	fx.set_ground_anchor(_foot_pos(t_center))

func _sprite_rect(center: Vector2) -> Rect2:
	return Rect2(center - Vector2(_SPRITE_W * 0.5, _SPRITE_H * 0.5), Vector2(_SPRITE_W, _SPRITE_H))

func _foot_pos(center: Vector2) -> Vector2:
	return center + Vector2(0.0, _CHAR_FOOT_Y_OFFSET)

func _spawn_compare_label(target_pos: Vector2, text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 28)
	lbl.add_theme_color_override("font_color", Color(0.85, 1.0, 0.85))
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	lbl.add_theme_constant_override("outline_size", 4)
	lbl.position = target_pos + Vector2(-40.0, -180.0)
	lbl.size = Vector2(80, 40)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(lbl)
	var tw := create_tween()
	tw.tween_interval(2.5)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.5)
	tw.tween_callback(lbl.queue_free)

func _show_impact_marker(vfx_name: String) -> void:
	_impact_label.text = "IMPACT — %s" % vfx_name
	_impact_label.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_impact_label, "modulate:a", 1.0, 0.05)
	tw.tween_interval(0.7)
	tw.tween_property(_impact_label, "modulate:a", 0.0, 0.3)

func _preview_flash() -> void:
	var r := ColorRect.new()
	r.color = Color(0.86, 0.92, 1.0)
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.modulate.a = 0.0
	add_child(r)
	var tw := create_tween()
	tw.tween_property(r, "modulate:a", 0.6, 0.03)
	tw.tween_property(r, "modulate:a", 0.0, 0.3)
	tw.tween_callback(r.queue_free)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		_play(_selected)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var m := get_global_mouse_position()
			if _sprite_rect(_caster_pos).has_point(m):
				_dragging = 0
			elif _sprite_rect(_target_pos).has_point(m):
				_dragging = 1
			else:
				_target_pos = m
				queue_redraw()
				_play(_selected)
		else:
			_dragging = -1
	elif event is InputEventMouseMotion and _dragging >= 0:
		if _dragging == 0:
			_caster_pos = get_global_mouse_position()
		else:
			_target_pos = get_global_mouse_position()
		queue_redraw()

func _draw() -> void:
	_draw_actor(_caster_pos, Color(1.0, 0.8, 0.3, 0.9), "시전자")
	_draw_actor(_target_pos, Color(1.0, 0.4, 0.4, 0.9), "타겟")

func _draw_actor(center: Vector2, col: Color, label: String) -> void:
	var rect := _sprite_rect(center)
	draw_rect(rect, Color(col.r, col.g, col.b, 0.10), true)
	draw_rect(rect, col, false, 1.5)
	draw_circle(center, 4.0, col)
	var foot := _foot_pos(center)
	draw_line(foot - Vector2(8.0, 0.0), foot + Vector2(8.0, 0.0), col, 2.0)
	draw_line(foot - Vector2(0.0, 4.0), foot + Vector2(0.0, 4.0), col, 2.0)
	var font := ThemeDB.fallback_font
	draw_string(font, rect.position + Vector2(-2.0, -6.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14)
	draw_string(font, foot + Vector2(10.0, 4.0), "foot", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(col.r, col.g, col.b, 0.7))
