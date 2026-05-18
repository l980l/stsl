# scenes/vfx/warrior_buff_gpu.gd
# 전사 버프 GPU 하이브리드 — warrior_buff.gd 와 동일 시각.
# ember/dust/flame/chunk → GPUParticles2D. 차지오브/오라/룬링/충격파 → CPU 폴리곤 그대로.
extends Node2D

const _Helpers = preload("res://scenes/vfx/gpu_particle_helpers.gd")

var _particle_scale_override: float = -1.0

func _pcount(n: int) -> int:
	if _particle_scale_override > 0.0:
		return maxi(1, int(round(n * _particle_scale_override)))
	var gs := get_node_or_null("/root/GameSettings")
	return n if gs == null else maxi(1, int(round(n * gs.particle_count_scale())))

func _scale() -> float:
	if _particle_scale_override > 0.0:
		return _particle_scale_override
	var gs := get_node_or_null("/root/GameSettings")
	return 1.0 if gs == null else gs.particle_count_scale()

const COL_HOT   := Color(1.0, 0.941, 0.753)
const COL_MID   := Color(1.0, 0.478, 0.165)
const COL_DEEP  := Color(0.784, 0.188, 0.078)
const COL_DUST  := Color(0.784, 0.549, 0.353)
const COL_CHUNK := Color(0.431, 0.275, 0.157)

const ORB_CHARGE_START := 0.10
const ORB_CHARGE_FULL  := 0.45
const ORB_OFFSET_Y     := -80.0
const CHARGE_TIME      := 0.3
const IMPACT_DELAY     := CHARGE_TIME
const BUFF_TIME        := 1.5
const RING_SQUASH      := 0.34
const RING_RADIUS      := 130.0
const AURA_HEIGHT      := 260.0
const AURA_WIDTH       := 80.0
const SHOCK_TIME       := 0.55

signal screen_effect

var _target := Vector2.ZERO
var _ground_pos := Vector2.ZERO
var _has_ground: bool = false

func set_ground_anchor(pos: Vector2) -> void:
	_ground_pos = pos
	_has_ground = true
	if _ground_layer != null:
		_ground_layer.z_as_relative = false
		_ground_layer.z_index = int(pos.y) - 1

var _charge_orb: Sprite2D
var _glow_layer: Node2D
var _ground_layer: Node2D
var _ring_age := -1.0
var _aura_age := -1.0
var _shock_age := -1.0
var _ring_spin := 0.0

# GPU emitter
var _ember_rising: GPUParticles2D
var _flame_rising: GPUParticles2D

static func _make_orb_tex(c_core: Color, c_mid: Color, c_edge: Color) -> GradientTexture2D:
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.42, 0.72, 1.0])
	grad.colors = PackedColorArray([c_core, c_mid, c_edge, Color(c_edge.r, c_edge.g, c_edge.b, 0.0)])
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 256; tex.height = 256
	return tex

func _ready() -> void:
	set_process(false)
	_ground_layer = _GroundLayer.new()
	_ground_layer.setup(self)
	add_child(_ground_layer)
	_charge_orb = Sprite2D.new()
	_charge_orb.texture = _make_orb_tex(COL_HOT, COL_MID, COL_DEEP)
	_charge_orb.modulate = Color(1, 1, 1, 0.0)
	_charge_orb.scale = Vector2(ORB_CHARGE_START, ORB_CHARGE_START)
	add_child(_charge_orb)
	_glow_layer = _DrawLayer.new()
	_glow_layer.setup(self)
	add_child(_glow_layer)

func play(_caster_pos: Vector2, target_pos: Vector2) -> void:
	_target = target_pos
	_charge_orb.position = target_pos + Vector2(0.0, ORB_OFFSET_Y)
	_run()

func _run() -> void:
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_charge_orb, "modulate:a", 1.0, 0.15)
	tw.parallel().tween_property(_charge_orb, "scale", Vector2(ORB_CHARGE_FULL, ORB_CHARGE_FULL), CHARGE_TIME)
	set_process(true)
	await get_tree().create_timer(CHARGE_TIME).timeout
	if not is_inside_tree():
		return
	var tw2 := create_tween()
	tw2.tween_property(_charge_orb, "modulate:a", 0.0, 0.12)
	_ring_age = 0.0
	_aura_age = 0.0
	_shock_age = 0.0
	_spawn_burst()
	_spawn_rising()
	screen_effect.emit()
	get_tree().create_timer(BUFF_TIME).timeout.connect(func() -> void:
		if is_instance_valid(_ember_rising): _ember_rising.emitting = false
		if is_instance_valid(_flame_rising): _flame_rising.emitting = false)
	await get_tree().create_timer(BUFF_TIME + 1.5).timeout
	if is_inside_tree():
		queue_free()

func _spawn_burst() -> void:
	var ctr := _target + Vector2(0.0, -30.0)
	var floor_y: Vector2 = _ground_pos if _has_ground else _target + Vector2(0.0, 30.0)
	# ember 30 at ctr — speed 120~480, y -120 bias (UP spread), lifetime 1.5, size 1.5~3.1, gravity 144 (down)
	var ember_burst := _Helpers.make_emitter({
		"count": _pcount(30), "lifetime": 1.5, "color": COL_MID,
		"speed_min": 120.0, "speed_max": 480.0,
		"direction": Vector2.UP, "spread": 90.0,
		"gravity": 144.0, "damping": 5.0,
		"size_min": 1.5, "size_max": 3.1,
	})
	ember_burst.position = ctr
	add_child(ember_burst)
	# dust 14 at floor — speed 120~360, mostly horizontal (sin*0.3), upward bias, large 22~40, slight up gentle
	var dust_burst := _Helpers.make_emitter({
		"count": _pcount(14), "lifetime": 1.95, "color": COL_DUST,
		"speed_min": 120.0, "speed_max": 360.0,
		"direction": Vector2.UP, "spread": 75.0,
		"gravity": -18.0, "damping": 4.0,
		"size_min": 22.0, "size_max": 40.0,
		"additive": false, "mid_alpha": 0.3,
	})
	dust_burst.position = floor_y
	add_child(dust_burst)
	# flame 10 at ctr — speed 120~360, upward, lifetime 0.85, size 14~28, up gentle
	var flame_burst := _Helpers.make_emitter({
		"count": _pcount(10), "lifetime": 0.85, "color": COL_HOT,
		"speed_min": 120.0, "speed_max": 360.0,
		"direction": Vector2.UP, "spread": 90.0,
		"gravity": -72.0, "damping": 4.0,
		"size_min": 14.0, "size_max": 28.0,
	})
	flame_burst.position = ctr
	add_child(flame_burst)
	# chunk 8 at floor — speed 180~480, y -180~-270, lifetime 1.35, size 3~7, gravity 1152 (down strong), rotation
	var chunk_burst := _Helpers.make_chunk_emitter(COL_CHUNK, _pcount(8), 1.35, 180.0, 480.0, 1152.0, 3.0, 7.0)
	chunk_burst.position = floor_y
	add_child(chunk_burst)

func _spawn_rising() -> void:
	var floor_y: float = _ground_pos.y if _has_ground else _target.y + 30.0
	# ember 2/frame * 60fps * 1.5s * lifetime 1.65 ≈ 198 동시. spawn box (75, 5)
	_ember_rising = _Helpers.make_emitter({
		"count": int(198 * _scale()), "lifetime": 1.65, "color": COL_MID,
		"speed_min": 72.0, "speed_max": 162.0,
		"direction": Vector2.UP, "spread": 18.0,
		"gravity": 72.0, "damping": 4.0,
		"size_min": 1.6, "size_max": 3.2,
		"emission_shape": "box", "emission_box": Vector2(75.0, 5.0),
		"one_shot": false, "explosiveness": 0.0,
	})
	_ember_rising.position = Vector2(_target.x, floor_y)
	add_child(_ember_rising)
	# flame 0.4 확률/frame * 60 = 24/sec * lifetime 0.95 ≈ 23 동시
	_flame_rising = _Helpers.make_emitter({
		"count": int(23 * _scale()), "lifetime": 0.95, "color": COL_HOT,
		"speed_min": 90.0, "speed_max": 150.0,
		"direction": Vector2.UP, "spread": 12.0,
		"gravity": -72.0, "damping": 4.0,
		"size_min": 8.0, "size_max": 18.0,
		"emission_shape": "box", "emission_box": Vector2(50.0, 3.0),
		"one_shot": false, "explosiveness": 0.0,
	})
	_flame_rising.position = Vector2(_target.x, floor_y - 5.0)
	add_child(_flame_rising)

func _process(delta: float) -> void:
	if _ring_age >= 0.0:
		_ring_age += delta
		_ring_spin += delta * (TAU / 4.0)
	if _aura_age >= 0.0:
		_aura_age += delta
	if _shock_age >= 0.0:
		_shock_age += delta
	_glow_layer.queue_redraw()
	if _ground_layer:
		_ground_layer.queue_redraw()

# ── CPU 폴리곤 — 오라/충격파 (원본 그대로) ──
func _draw_glow_pass(canvas: CanvasItem) -> void:
	if _aura_age >= 0.0:
		_draw_aura(canvas)
	if _shock_age >= 0.0:
		_draw_shock(canvas)

func _draw_aura(canvas: CanvasItem) -> void:
	var grow: float = clampf(_aura_age / 0.4, 0.0, 1.0)
	var fade := 1.0
	if _aura_age > BUFF_TIME:
		fade = clampf(1.0 - (_aura_age - BUFF_TIME) / 0.4, 0.0, 1.0)
	if fade <= 0.0:
		return
	var flicker: float = 0.85 + sin(_aura_age * (TAU / 0.25)) * 0.10
	var alpha: float = grow * fade * flicker
	var bottom_y: float = _ground_pos.y if _has_ground else _target.y
	var top_y := bottom_y - AURA_HEIGHT * grow
	var w_b := AURA_WIDTH * grow
	var w_t := AURA_WIDTH * 0.4 * grow
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(_target.x - w_b, bottom_y), Vector2(_target.x + w_b, bottom_y),
		Vector2(_target.x + w_t, top_y), Vector2(_target.x - w_t, top_y),
	]), Color(COL_DEEP, 0.45 * alpha))
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(_target.x - w_b * 0.5, bottom_y), Vector2(_target.x + w_b * 0.5, bottom_y),
		Vector2(_target.x + w_t * 0.5, top_y), Vector2(_target.x - w_t * 0.5, top_y),
	]), Color(COL_MID, 0.55 * alpha))

func _draw_shock(canvas: CanvasItem) -> void:
	if _shock_age > SHOCK_TIME:
		return
	var t := _shock_age / SHOCK_TIME
	var sc: float = lerpf(0.2, 12.0, t)
	var oa: float
	if t < 0.25:
		oa = t / 0.25
	else:
		oa = 1.0 - (t - 0.25) / 0.75
	var thick: float = lerpf(6.0, 1.0, t)
	var rc := _target + Vector2(0.0, -50.0)
	var rad := 20.0 * sc
	canvas.draw_arc(rc, rad, 0.0, TAU, 48, Color(COL_MID, oa), thick, true)
	canvas.draw_arc(rc, rad * 0.85, 0.0, TAU, 36, Color(COL_HOT, oa * 0.7), thick * 0.5, true)

# ── CPU 폴리곤 — 가시 룬링 (원본 그대로) ──
func _draw_ring(canvas: CanvasItem) -> void:
	var grow: float = clampf(_ring_age / 0.35, 0.0, 1.0)
	var fade := 1.0
	if _ring_age > BUFF_TIME:
		fade = clampf(1.0 - (_ring_age - BUFF_TIME) / 0.5, 0.0, 1.0)
	if fade <= 0.0:
		return
	var sc: float = lerpf(0.3, 1.0, grow)
	var a: float = grow * fade * 0.95
	var rc: Vector2 = _ground_pos if _has_ground else _target + Vector2(0.0, 30.0)
	for radius in [RING_RADIUS, RING_RADIUS * 0.91]:
		var rad := float(radius) * sc
		var pts := PackedVector2Array()
		for i in range(48):
			var ang: float = TAU * float(i) / 48.0
			pts.append(rc + Vector2(cos(ang) * rad, sin(ang) * rad * RING_SQUASH))
		pts.append(pts[0])
		canvas.draw_polyline(pts, Color(COL_MID, a), 2.0)
	var spike_r := RING_RADIUS * sc
	for i in range(16):
		var ang: float = TAU * float(i) / 16.0 + _ring_spin
		var base := rc + Vector2(cos(ang) * spike_r, sin(ang) * spike_r * RING_SQUASH)
		var tip := rc + Vector2(cos(ang) * (spike_r + 18.0), sin(ang) * (spike_r + 18.0) * RING_SQUASH)
		var perp := Vector2(-sin(ang), cos(ang) * RING_SQUASH) * 6.0
		canvas.draw_colored_polygon(PackedVector2Array([
			base + perp, base - perp, tip,
		]), Color(COL_MID, a))
	var dotted_r := RING_RADIUS * 0.62 * sc
	for i in range(12):
		var a0: float = TAU * float(i) / 12.0 + _ring_spin
		var a1: float = a0 + TAU / 24.0
		var pts := PackedVector2Array()
		for k in range(5):
			var t: float = float(k) / 4.0
			var ang: float = lerpf(a0, a1, t)
			pts.append(rc + Vector2(cos(ang) * dotted_r, sin(ang) * dotted_r * RING_SQUASH))
		canvas.draw_polyline(pts, Color(COL_DEEP, a * 0.7), 1.5)

func _draw_ground_pass(canvas: CanvasItem) -> void:
	if _ring_age >= 0.0:
		_draw_ring(canvas)

class _DrawLayer:
	extends Node2D
	var _fx: Node2D
	func setup(owner_fx: Node2D) -> void:
		_fx = owner_fx
		var m := CanvasItemMaterial.new()
		m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		material = m
	func _draw() -> void:
		_fx._draw_glow_pass(self)

class _GroundLayer:
	extends Node2D
	var _fx: Node2D
	func setup(owner_fx: Node2D) -> void:
		_fx = owner_fx
		var m := CanvasItemMaterial.new()
		m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		material = m
	func _draw() -> void:
		_fx._draw_ground_pass(self)
