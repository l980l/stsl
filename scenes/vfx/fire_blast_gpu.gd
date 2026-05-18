# scenes/vfx/fire_blast_gpu.gd
# 화염 공격 GPU 하이브리드 — fire_blast.gd 와 동일 시각.
# trail/explosion/burn 의 ember·flame·smoke·fireball → GPUParticles2D.
# 차지 오브, 투사체 머리, 충격파 링, 열기 펄스 → CPU 폴리곤 그대로.
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

const COL_HOT   := Color(1.0, 0.949, 0.753)
const COL_MID   := Color(1.0, 0.706, 0.329)
const COL_DEEP  := Color(1.0, 0.353, 0.122)
const COL_SMOKE := Color(0.156, 0.110, 0.086)

const ORB_CHARGE_START := 0.12
const ORB_CHARGE_FULL  := 0.36
const CHARGE_TIME      := 0.32
const PROJ_FLIGHT      := 0.45
const IMPACT_DELAY     := CHARGE_TIME + PROJ_FLIGHT
const ARC_HEIGHT       := 120.0
const BURN_TIME        := 2.0

signal screen_effect

var _caster := Vector2.ZERO
var _target := Vector2.ZERO
var _charge_orb: Sprite2D
var _fx_layer: Node2D    # CPU 폴리곤 — 충격파/열기/투사체 머리
var _proj_t := -1.0
var _impacted := false
var _shock_life := -1.0
var _heat_life := -1.0

# GPU emitter
var _trail_smoke: GPUParticles2D
var _trail_flame: GPUParticles2D
var _trail_ember: GPUParticles2D
var _burn_flame: GPUParticles2D
var _burn_ember: GPUParticles2D

static func proj_pos(a: Vector2, b: Vector2, t: float, arc_h: float) -> Vector2:
	return a.lerp(b, t) + Vector2(0.0, -sin(t * PI) * arc_h)

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
	_charge_orb = Sprite2D.new()
	_charge_orb.texture = _make_orb_tex(COL_HOT, COL_MID, COL_DEEP)
	_charge_orb.modulate = Color(1, 1, 1, 0.0)
	_charge_orb.scale = Vector2(ORB_CHARGE_START, ORB_CHARGE_START)
	add_child(_charge_orb)
	_fx_layer = _DrawLayer.new()
	_fx_layer.setup(self)
	add_child(_fx_layer)

func play(caster_pos: Vector2, target_pos: Vector2) -> void:
	_caster = caster_pos
	_target = target_pos
	_charge_orb.position = caster_pos
	_run()

func _run() -> void:
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_charge_orb, "modulate:a", 1.0, 0.2)
	tw.parallel().tween_property(_charge_orb, "scale", Vector2(ORB_CHARGE_FULL, ORB_CHARGE_FULL), CHARGE_TIME)
	set_process(true)
	await get_tree().create_timer(CHARGE_TIME).timeout
	if not is_inside_tree():
		return
	var tw2 := create_tween()
	tw2.tween_property(_charge_orb, "modulate:a", 0.0, 0.12)
	_proj_t = 0.0
	_make_trail_emitters()
	await get_tree().create_timer(PROJ_FLIGHT + BURN_TIME + 1.5).timeout
	if is_inside_tree():
		queue_free()

# 비행 중 따라가는 trail (POINT spawn at 매 프레임 갱신 position)
# smoke 가장 먼저 add_child = 가장 뒤. flame/ember 가 위.
func _make_trail_emitters() -> void:
	_trail_smoke = _Helpers.make_emitter({
		"count": int(80 * _scale()), "lifetime": 0.6, "color": COL_SMOKE,
		"speed_min": 18.0, "speed_max": 54.0,
		"direction": Vector2.UP, "spread": 180.0,
		"gravity": -18.0, "size_min": 8.0, "size_max": 24.0,
		"additive": false, "mid_alpha": 0.18,
		"one_shot": false, "explosiveness": 0.0,
	})
	_trail_smoke.z_index = -1
	add_child(_trail_smoke)
	_trail_flame = _Helpers.make_emitter({
		"count": int(60 * _scale()), "lifetime": 0.4, "color": COL_HOT,
		"speed_min": 36.0, "speed_max": 90.0,
		"direction": Vector2.UP, "spread": 180.0,
		"gravity": -72.0, "size_min": 3.0, "size_max": 8.0,
		"texture": _Helpers.glow_circle_tex(),
		"one_shot": false, "explosiveness": 0.0,
	})
	add_child(_trail_flame)
	_trail_ember = _Helpers.make_emitter({
		"count": int(30 * _scale()), "lifetime": 0.9, "color": COL_DEEP,
		"speed_min": 60.0, "speed_max": 210.0,
		"direction": Vector2.UP, "spread": 180.0,
		"gravity": 72.0, "size_min": 1.4, "size_max": 2.6,
		"texture": _Helpers.glow_circle_tex(),
		"one_shot": false, "explosiveness": 0.0,
	})
	add_child(_trail_ember)

func _process(delta: float) -> void:
	if _proj_t >= 0.0:
		_proj_t += delta / PROJ_FLIGHT
		var pp := proj_pos(_caster, _target, clampf(_proj_t, 0.0, 1.0), ARC_HEIGHT)
		# trail emitter 위치를 투사체 머리에 동기
		if is_instance_valid(_trail_smoke):
			_trail_smoke.position = pp
			_trail_flame.position = pp
			_trail_ember.position = pp
		if _proj_t >= 1.0 and not _impacted:
			_on_impact()
	if _shock_life >= 0.0:
		_shock_life += delta / 0.6
	if _heat_life >= 0.0:
		_heat_life += delta / 1.2
	_fx_layer.queue_redraw()

func _on_impact() -> void:
	_impacted = true
	_proj_t = -1.0
	# trail emitter 끄기
	if is_instance_valid(_trail_smoke): _trail_smoke.emitting = false
	if is_instance_valid(_trail_flame): _trail_flame.emitting = false
	if is_instance_valid(_trail_ember): _trail_ember.emitting = false
	_spawn_explosion(_target)
	_make_burn_emitters()
	_shock_life = 0.0
	_heat_life = 0.0
	screen_effect.emit()

func _spawn_explosion(pos: Vector2) -> void:
	# smoke 먼저 add_child — 불 이펙트보다 뒤로. 색 연하게 (alpha 0.18 mid).
	var smoke := _Helpers.make_emitter({
		"count": _pcount(40), "lifetime": 1.85, "color": COL_SMOKE,
		"speed_min": 36.0, "speed_max": 132.0,
		"direction": Vector2.UP, "spread": 50.0,
		"gravity": -36.0, "damping": 4.0,
		"size_min": 26.0, "size_max": 56.0,
		"additive": false, "mid_alpha": 0.18,
		"emission_shape": "box", "emission_box": Vector2(30.0, 20.0),
	})
	smoke.position = pos
	smoke.z_index = -1
	add_child(smoke)
	# fireball — 글로우 텍스처 + 원본 3단계 색
	var fireball := _Helpers.make_emitter({
		"count": _pcount(70), "lifetime": 0.75, "color": COL_MID,
		"speed_min": 60.0, "speed_max": 360.0,
		"direction": Vector2.UP, "spread": 180.0,
		"gravity": -54.0, "damping": 5.0,
		"size_min": 14.0, "size_max": 36.0,
		"texture": _Helpers.glow_circle_tex(),
		"color_ramp": _Helpers.make_color_ramp(
			Color(1.0, 0.961, 0.824),
			Color(1.0, 0.667, 0.275),
			Color(0.863, 0.235, 0.078),
			0.9, 0.75, 0.0),
	})
	fireball.position = pos
	add_child(fireball)
	# ember — 글로우 텍스처 + rgba(255, 200-120k, 100-80k, 1-k)
	var ember := _Helpers.make_emitter({
		"count": _pcount(80), "lifetime": 1.05, "color": COL_HOT,
		"speed_min": 120.0, "speed_max": 540.0,
		"direction": Vector2.UP, "spread": 180.0,
		"gravity": 162.0, "damping": 5.0,
		"size_min": 1.6, "size_max": 3.2,
		"texture": _Helpers.glow_circle_tex(),
		"color_ramp": _Helpers.make_color_ramp(
			Color(1.0, 0.784, 0.392),
			Color(1.0, 0.549, 0.235),
			Color(1.0, 0.313, 0.078),
			1.0, 0.6, 0.0),
	})
	ember.position = pos
	add_child(ember)

func _make_burn_emitters() -> void:
	# flame 잔불 — flame 색 변화 (흰노랑→주황→진홍)
	_burn_flame = _Helpers.make_emitter({
		"count": int(25 * _scale()), "lifetime": 0.6, "color": COL_HOT,
		"speed_min": 24.0, "speed_max": 66.0,
		"direction": Vector2.UP, "spread": 18.0,
		"gravity": -72.0, "damping": 4.0,
		"size_min": 4.0, "size_max": 11.0,
		"texture": _Helpers.glow_circle_tex(),
		"emission_shape": "box", "emission_box": Vector2(20.0, 5.0),
		"one_shot": false, "explosiveness": 0.0,
		"color_ramp": _Helpers.make_color_ramp(
			Color(1.0, 0.922, 0.706),
			Color(1.0, 0.549, 0.196),
			Color(0.706, 0.157, 0.059),
			0.9, 0.7, 0.0),
	})
	_burn_flame.position = _target
	add_child(_burn_flame)
	_burn_ember = _Helpers.make_emitter({
		"count": int(20 * _scale()), "lifetime": 0.85, "color": COL_MID,
		"speed_min": 48.0, "speed_max": 102.0,
		"direction": Vector2.UP, "spread": 25.0,
		"gravity": 36.0, "damping": 4.0,
		"size_min": 1.2, "size_max": 2.2,
		"texture": _Helpers.glow_circle_tex(),
		"emission_shape": "box", "emission_box": Vector2(18.0, 4.0),
		"one_shot": false, "explosiveness": 0.0,
		"color_ramp": _Helpers.make_color_ramp(
			Color(1.0, 0.784, 0.392),
			Color(1.0, 0.549, 0.235),
			Color(1.0, 0.313, 0.078),
			1.0, 0.6, 0.0),
	})
	_burn_ember.position = _target
	add_child(_burn_ember)
	# BURN_TIME 후 끄기
	get_tree().create_timer(BURN_TIME).timeout.connect(func() -> void:
		if is_instance_valid(_burn_flame): _burn_flame.emitting = false
		if is_instance_valid(_burn_ember): _burn_ember.emitting = false)

# ── CPU 폴리곤 — 충격파/열기/투사체 머리 (원본 그대로) ──
func _draw_fx_pass(canvas: CanvasItem) -> void:
	if _heat_life >= 0.0 and _heat_life <= 1.0:
		var hscale: float
		var hop: float
		if _heat_life < 0.25:
			var u: float = _heat_life / 0.25
			hscale = lerpf(0.4, 1.0, u)
			hop = u
		else:
			var u: float = (_heat_life - 0.25) / 0.75
			hscale = lerpf(1.0, 1.6, u)
			hop = 1.0 - u
		canvas.draw_circle(_target, 130.0 * hscale, Color(COL_MID, 0.13 * hop))
	if _shock_life >= 0.0 and _shock_life <= 1.0:
		var rad: float = 14.0 + _shock_life * 340.0
		var sa: float = (1.0 - _shock_life) * 0.85
		canvas.draw_arc(_target, rad, 0.0, TAU, 48, Color(COL_MID, sa), 1.0 + 4.0 * (1.0 - _shock_life), true)
	if _proj_t >= 0.0:
		var pp := proj_pos(_caster, _target, clampf(_proj_t, 0.0, 1.0), ARC_HEIGHT)
		canvas.draw_circle(pp, 38.0, Color(COL_DEEP, 0.22))
		canvas.draw_circle(pp, 22.0, Color(COL_MID, 0.5))
		canvas.draw_circle(pp, 10.0, Color(COL_HOT, 0.9))
		canvas.draw_circle(pp, 5.0, Color(1, 1, 1, 1))

class _DrawLayer:
	extends Node2D
	var _fx: Node2D
	func setup(owner_fx: Node2D) -> void:
		_fx = owner_fx
		var m := CanvasItemMaterial.new()
		m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		material = m
	func _draw() -> void:
		_fx._draw_fx_pass(self)
