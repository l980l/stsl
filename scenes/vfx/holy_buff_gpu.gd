# scenes/vfx/holy_buff_gpu.gd
# 신성 버프 GPU 하이브리드 — holy_buff.gd 정확 매핑 (2차 시도).
# CPU 폴리곤 (빛기둥/룬링/차지 오브): 원본 그대로.
# GPU 파티클 (mote/feather): 정확 색·크기·회전 매핑.
#   - mote 색: rgba(255, 235-20k, 170+30k, 1-k) — 흰주황→흰핑크 ramp + alpha linear
#   - mote 텍스처: sparkle (코어 원 + 십자 막대), size_base=4 → 원본 pr 정확 매칭
#   - feather: 텍스처 자체에 COL_FEATHER 외곽 + COL_HOT 내부 색 미리, modulate WHITE
#   - feather 회전: ±172°/s (burst, ±0.05 rad×60), ±138°/s (rising, ±0.04 rad×60)
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

const COL_HOT     := Color(1.0, 0.965, 0.776)
const COL_MID     := Color(1.0, 0.831, 0.439)
const COL_DEEP    := Color(0.8, 0.541, 0.102)
const COL_FEATHER := Color(1.0, 0.902, 0.627)

const ORB_CHARGE_START := 0.10
const ORB_CHARGE_FULL  := 0.45
const ORB_OFFSET_Y     := -90.0
const CHARGE_TIME      := 0.3
const IMPACT_DELAY     := CHARGE_TIME
const BUFF_TIME        := 1.5
const RING_SQUASH      := 0.34
const PILLAR_HEIGHT    := 240.0
const PILLAR_WIDTH     := 90.0
const RING_RADIUS      := 110.0

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

# CPU 폴리곤 레이어
var _charge_orb: Sprite2D
var _ground_layer: Node2D   # 룬링 (가산, 맨 아래)
var _glow_layer: Node2D     # 빛기둥 (가산)
var _ring_age := -1.0
var _pillar_age := -1.0
var _ring_spin := 0.0

# GPU emitter (z order: 룬링 → feather(일반) → 빛기둥 → mote(가산))
var _feather_burst: GPUParticles2D
var _feather_rising: GPUParticles2D
var _mote_burst: GPUParticles2D
var _mote_rising: GPUParticles2D

static func _make_orb_tex(c_core: Color, c_mid: Color, c_edge: Color) -> GradientTexture2D:
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.42, 0.72, 1.0])
	grad.colors = PackedColorArray([c_core, c_mid, c_edge, Color(c_edge.r, c_edge.g, c_edge.b, 0.0)])
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 256
	tex.height = 256
	return tex

func _ready() -> void:
	set_process(false)
	# z 순서:
	# 1. 룬링 (가산, 맨 아래 - 캐릭터 뒤로)
	_ground_layer = _GroundLayer.new()
	_ground_layer.setup(self)
	add_child(_ground_layer)
	# 2~3. feather emitter 자리 — _spawn_burst 에서 add (룬링 위, 빛기둥 아래)
	# 4. 차지 오브
	_charge_orb = Sprite2D.new()
	_charge_orb.texture = _make_orb_tex(COL_HOT, COL_MID, COL_DEEP)
	_charge_orb.modulate = Color(1, 1, 1, 0.0)
	_charge_orb.scale = Vector2(ORB_CHARGE_START, ORB_CHARGE_START)
	add_child(_charge_orb)
	# 5. 빛기둥 (가산)
	_glow_layer = _DrawLayer.new()
	_glow_layer.setup(self)
	add_child(_glow_layer)
	# 6~7. mote emitter 자리 — _spawn_burst 에서 add (빛기둥 위)

func play(_caster_pos: Vector2, target_pos: Vector2) -> void:
	_target = target_pos
	_charge_orb.position = target_pos + Vector2(0.0, ORB_OFFSET_Y)
	_run()

func _run() -> void:
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_charge_orb, "modulate:a", 1.0, 0.18)
	tw.parallel().tween_property(_charge_orb, "scale", Vector2(ORB_CHARGE_FULL, ORB_CHARGE_FULL), CHARGE_TIME)
	set_process(true)
	await get_tree().create_timer(CHARGE_TIME).timeout
	if not is_inside_tree():
		return
	var tw2 := create_tween()
	tw2.tween_property(_charge_orb, "modulate:a", 0.0, 0.15)
	_ring_age = 0.0
	_pillar_age = 0.0
	_spawn_burst()
	_spawn_rising()
	screen_effect.emit()
	get_tree().create_timer(BUFF_TIME).timeout.connect(func() -> void:
		if is_instance_valid(_mote_rising): _mote_rising.emitting = false
		if is_instance_valid(_feather_rising): _feather_rising.emitting = false)
	await get_tree().create_timer(BUFF_TIME + 1.5).timeout
	if is_inside_tree():
		queue_free()

func _spawn_burst() -> void:
	var ctr := _target + Vector2(0.0, -30.0)
	# feather burst (일반 블렌드) — 텍스처 자체 색 + modulate WHITE.
	# 원본: vel=(cos*sp, sin*sp-0.8), sp=1~4 → speed_min=60 speed_max=240, direction up bias.
	# grav 0.01*PSPEED=0.6 px/frame/s → 36 px/s². rot 초기 ±0.6rad=±34°. spin ±0.05rad×60=±172°/s.
	_feather_burst = _Helpers.make_emitter({
		"count": _pcount(10),
		"lifetime": 1.85,
		"color": Color.WHITE,  # 텍스처 색 그대로
		"speed_min": 60.0, "speed_max": 240.0,
		"direction": Vector2.UP, "spread": 180.0,
		"gravity": 36.0, "damping": 60.0,
		"size_min": 10.0, "size_max": 20.0,
		"size_base": 30.0,  # feather_tex 긴축 반경
		"angle_min": -34.4, "angle_max": 34.4,
		"angular_velocity_min": -172.0, "angular_velocity_max": 172.0,
		"additive": false,
		"texture": _Helpers.feather_tex(),
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	_feather_burst.position = ctr
	add_child(_feather_burst)
	move_child(_feather_burst, 1)  # _ground_layer(0) 다음 = 룬링 위, 차지오브/빛기둥/mote 아래
	# mote burst (가산 블렌드) — 원본 색 rgba(255, 235-20k, 170+30k, 1-k) 정확 매핑.
	# vel=(cos*sp, sin*sp-1.5), sp=2~7 → speed 120~420, direction up bias.
	# grav 0.025*60=1.5 → 90 px/s². size r=1.5~3.1.
	_mote_burst = _Helpers.make_emitter({
		"count": _pcount(25),
		"lifetime": 1.55,
		"color": Color(1.0, 235.0/255.0, 170.0/255.0),
		"speed_min": 120.0, "speed_max": 420.0,
		"direction": Vector2.UP, "spread": 180.0,
		"gravity": 90.0, "damping": 60.0,
		"size_min": 1.5, "size_max": 3.1,
		"size_base": 4.0,  # sparkle 코어 반경
		"texture": _Helpers.sparkle_tex(),
		"color_ramp": _Helpers.make_color_ramp(
			Color(1.0, 235.0/255.0, 170.0/255.0),   # k=0
			Color(1.0, 225.0/255.0, 185.0/255.0),   # k=0.5
			Color(1.0, 215.0/255.0, 200.0/255.0),   # k=1
			1.0, 0.5, 0.0),  # alpha linear (1-k)
	})
	_mote_burst.position = ctr
	add_child(_mote_burst)  # 마지막 = 빛기둥 위

func _spawn_rising() -> void:
	var ctr := _target + Vector2(0.0, -30.0)
	# feather rising — 0.2 확률/frame × 60fps = 12/s × lifetime 2.05 = ~25 동시.
	# vel.x=±0.3*60=±18, vel.y -36~-78. lifetime 2.05.
	# spin ±0.04*60=±138°/s.
	_feather_rising = _Helpers.make_emitter({
		"count": int(25 * _scale()),
		"lifetime": 2.05,
		"color": Color.WHITE,
		"speed_min": 36.0, "speed_max": 84.0,
		"direction": Vector2.UP, "spread": 30.0,
		"gravity": 0.0, "damping": 60.0,
		"size_min": 8.0, "size_max": 16.0,
		"size_base": 30.0,
		"angle_min": -22.9, "angle_max": 22.9,
		"angular_velocity_min": -138.0, "angular_velocity_max": 138.0,
		"additive": false,
		"texture": _Helpers.feather_tex(),
		"emission_shape": "box", "emission_box": Vector2(50.0, 1.0),
		"one_shot": false, "explosiveness": 0.0,
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	_feather_rising.position = ctr
	add_child(_feather_rising)
	move_child(_feather_rising, 2)  # feather_burst 다음
	# mote rising — 2/frame × 60fps = 120/s × lifetime 1.85 = ~222 동시.
	# vel.x=±0.3*60=±18, vel.y -60~-132. size 1.4~3.0.
	_mote_rising = _Helpers.make_emitter({
		"count": int(222 * _scale()),
		"lifetime": 1.85,
		"color": Color(1.0, 235.0/255.0, 170.0/255.0),
		"speed_min": 60.0, "speed_max": 192.0,
		"direction": Vector2.UP, "spread": 18.0,
		"gravity": 0.0, "damping": 60.0,
		"size_min": 1.4, "size_max": 3.0,
		"size_base": 4.0,
		"emission_shape": "box", "emission_box": Vector2(60.0, 10.0),
		"texture": _Helpers.sparkle_tex(),
		"one_shot": false, "explosiveness": 0.0,
		"color_ramp": _Helpers.make_color_ramp(
			Color(1.0, 235.0/255.0, 170.0/255.0),
			Color(1.0, 225.0/255.0, 185.0/255.0),
			Color(1.0, 215.0/255.0, 200.0/255.0),
			1.0, 0.5, 0.0),
	})
	_mote_rising.position = ctr
	add_child(_mote_rising)  # 마지막 = 위

func _process(delta: float) -> void:
	if _ring_age >= 0.0:
		_ring_age += delta
		_ring_spin += delta * (TAU / 8.0)
	if _pillar_age >= 0.0:
		_pillar_age += delta
	_glow_layer.queue_redraw()
	if _ground_layer:
		_ground_layer.queue_redraw()

# ── CPU 폴리곤 — 빛기둥 ──
func _draw_glow_pass(canvas: CanvasItem) -> void:
	if _pillar_age < 0.0:
		return
	_draw_pillar(canvas)

func _draw_pillar(canvas: CanvasItem) -> void:
	var grow: float = clampf(_pillar_age / 0.55, 0.0, 1.0)
	var fade := 1.0
	if _pillar_age > BUFF_TIME:
		fade = clampf(1.0 - (_pillar_age - BUFF_TIME) / 0.4, 0.0, 1.0)
	if fade <= 0.0:
		return
	var pulse: float = 0.85 + sin(_pillar_age * (TAU / 1.4)) * 0.10
	var alpha: float = grow * fade * pulse
	var bottom_y: float = _ground_pos.y if _has_ground else _target.y
	var top_y := bottom_y - PILLAR_HEIGHT * grow
	var w_bottom := PILLAR_WIDTH * grow
	var w_top := PILLAR_WIDTH * 0.3 * grow
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(_target.x - w_bottom, bottom_y),
		Vector2(_target.x + w_bottom, bottom_y),
		Vector2(_target.x + w_top, top_y),
		Vector2(_target.x - w_top, top_y),
	]), Color(COL_MID, 0.45 * alpha))
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(_target.x - w_bottom * 0.5, bottom_y),
		Vector2(_target.x + w_bottom * 0.5, bottom_y),
		Vector2(_target.x + w_top * 0.5, top_y),
		Vector2(_target.x - w_top * 0.5, top_y),
	]), Color(COL_HOT, 0.5 * alpha))

# ── CPU 폴리곤 — 룬링 ──
func _draw_ring(canvas: CanvasItem) -> void:
	var grow: float = clampf(_ring_age / 0.5, 0.0, 1.0)
	var fade := 1.0
	if _ring_age > BUFF_TIME:
		fade = clampf(1.0 - (_ring_age - BUFF_TIME) / 0.5, 0.0, 1.0)
	if fade <= 0.0:
		return
	var sc: float = lerpf(0.4, 1.0, grow)
	var a: float = grow * fade * 0.9
	var rc: Vector2 = _ground_pos if _has_ground else _target + Vector2(0.0, 30.0)
	for radius in [RING_RADIUS, RING_RADIUS * 0.87]:
		var rad := float(radius) * sc
		var pts := PackedVector2Array()
		for i in range(48):
			var ang := TAU * float(i) / 48.0
			pts.append(rc + Vector2(cos(ang) * rad, sin(ang) * rad * RING_SQUASH))
		pts.append(pts[0])
		canvas.draw_polyline(pts, Color(COL_MID, a), 1.5)
	var dotted_r := RING_RADIUS * 0.71 * sc
	for i in range(12):
		var a0 := TAU * float(i) / 12.0 + _ring_spin
		var a1 := a0 + TAU / 24.0
		var pts := PackedVector2Array()
		for k in range(5):
			var t := float(k) / 4.0
			var ang := lerpf(a0, a1, t)
			pts.append(rc + Vector2(cos(ang) * dotted_r, sin(ang) * dotted_r * RING_SQUASH))
		canvas.draw_polyline(pts, Color(COL_MID, a * 0.55), 1.0)
	var tri_r := RING_RADIUS * 0.91 * sc
	for sd in [1.0, -1.0]:
		var sign_dir: float = sd
		var tri := PackedVector2Array()
		for i in range(3):
			var ang: float = _ring_spin + sign_dir * (PI * 0.5) + TAU * float(i) / 3.0
			tri.append(rc + Vector2(cos(ang) * tri_r, sin(ang) * tri_r * RING_SQUASH))
		tri.append(tri[0])
		canvas.draw_polyline(tri, Color(COL_MID, a * 0.8), 1.5)

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
