# scenes/vfx/sig_ragnarok_gpu.gd
# 라그나로크 시그너처 GPU 하이브리드 — sig_ragnarok.gd 와 동일 시각.
# ember 파티클만 GPUParticles2D 로 대체, 발밑 원기둥 폴리곤은 CPU 그대로.
extends Node2D

const _Helpers = preload("res://scenes/vfx/gpu_particle_helpers.gd")

var _particle_scale_override: float = -1.0

func _pcount(n: int) -> int:
	if _particle_scale_override > 0.0:
		return maxi(1, int(round(n * _particle_scale_override)))
	var gs := get_node_or_null("/root/GameSettings")
	return n if gs == null else maxi(1, int(round(n * gs.particle_count_scale())))

const COL_EMBER := Color(1.0, 0.772, 0.419)
const COL_RED   := Color(1.0, 0.227, 0.109)

const IMPACT_DELAY     := 0.1
const HOLD_TIME        := 1.4
const FADE_TIME        := 0.6
const SPAWN_W          := 75.0
const RECT_TOP_OFFSET  := -170.0
const RECT_BOT_OFFSET  := 20.0
const ELLIPSE_RY       := 22.0

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

func _foot_pos() -> Vector2:
	return _ground_pos if _has_ground else _target + Vector2(0.0, 60.0)

var _age := -1.0
var _impact_emitted := false
var _ground_layer: Node2D
var _ember_emitter: GPUParticles2D

func _ready() -> void:
	set_process(false)
	_ground_layer = _DrawLayer.new()
	_ground_layer.setup(self)
	add_child(_ground_layer)

func play(_caster_pos: Vector2, target_pos: Vector2) -> void:
	_target = target_pos
	_age = 0.0
	set_process(true)
	# ember GPU emitter — 발밑 box 영역에서 위로 솟구침. lifetime 1.4~2.2 평균 1.8s
	# 원본 매 프레임 2회 × 0.6 확률 ≈ 1.2/frame * 60 = 72/sec * 1.8s = 130 동시 파티클
	var foot: Vector2 = _foot_pos()
	var spawn_pos := Vector2(foot.x, foot.y + RECT_BOT_OFFSET)
	_ember_emitter = _Helpers.make_emitter({
		"count": _pcount(220),
		"lifetime": 1.8,
		"color": COL_EMBER,
		"speed_min": 72.0, "speed_max": 168.0,
		"size_min": 1.6, "size_max": 3.4,  # 원본 그대로 (솔리드 텍스처)
		"emission_shape": "box",
		"emission_box": Vector2(SPAWN_W, ELLIPSE_RY),
		"direction": Vector2.UP, "spread": 18.0,
		"damping": 6.0, "one_shot": false,
		"explosiveness": 0.0,
	})
	_ember_emitter.position = spawn_pos
	_ember_emitter.z_index = int(spawn_pos.y) - 1
	add_child(_ember_emitter)
	# HOLD_TIME 종료 시 emitter 끄기
	get_tree().create_timer(IMPACT_DELAY + HOLD_TIME).timeout.connect(func() -> void:
		if is_instance_valid(_ember_emitter):
			_ember_emitter.emitting = false)
	await get_tree().create_timer(IMPACT_DELAY + HOLD_TIME + FADE_TIME + 0.1).timeout
	if is_inside_tree():
		queue_free()

func _process(delta: float) -> void:
	_age += delta
	if not _impact_emitted and _age >= IMPACT_DELAY:
		_impact_emitted = true
		screen_effect.emit()
	_ground_layer.queue_redraw()

func _global_alpha() -> float:
	var end_phase: float = IMPACT_DELAY + HOLD_TIME
	if _age < end_phase:
		return clampf(_age / 0.2, 0.0, 1.0)
	var t: float = (_age - end_phase) / FADE_TIME
	return clampf(1.0 - t, 0.0, 1.0)

# 발밑 원기둥 폴리곤 — 원본 그대로 (CPU 유지)
func _draw_ground_pass(canvas: CanvasItem) -> void:
	var ga: float = _global_alpha()
	if ga <= 0.0:
		return
	var foot: Vector2 = _foot_pos()
	var top_y: float = foot.y + RECT_TOP_OFFSET
	var ground_y: float = foot.y + RECT_BOT_OFFSET
	var top_c := Color(COL_RED.r, COL_RED.g, COL_RED.b, 0.0)
	var bot_c := Color(COL_RED.r, COL_RED.g, COL_RED.b, ga * 0.6)
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	pts.append(Vector2(foot.x - SPAWN_W, top_y))
	cols.append(top_c)
	pts.append(Vector2(foot.x + SPAWN_W, top_y))
	cols.append(top_c)
	var seg := 32
	for i in range(seg + 1):
		var a: float = PI * float(i) / float(seg)
		pts.append(Vector2(foot.x + cos(a) * SPAWN_W, ground_y + sin(a) * ELLIPSE_RY))
		cols.append(bot_c)
	canvas.draw_polygon(pts, cols)

class _DrawLayer:
	extends Node2D
	var _fx: Node2D
	func setup(owner_fx: Node2D) -> void:
		_fx = owner_fx
		var m := CanvasItemMaterial.new()
		m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		material = m
	func _draw() -> void:
		_fx._draw_ground_pass(self)
