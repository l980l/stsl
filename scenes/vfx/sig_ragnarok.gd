# scenes/vfx/sig_ragnarok.gd
# 북유럽 신화 시그너처 — 라그나로크 (종말의 불).
# 적 HP 30% 미만 → 모든 적 STR +1 (전투당 1회).
# play(_caster_pos, target_pos) — caster 무시. target = 화면 중앙(broadcast).
# 화면 하단 가로 영역에서 위로 솟구치는 ember 파티클만.
extends Node2D

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


const COL_EMBER := Color(1.0, 0.772, 0.419)   # #ffc56b
const COL_RED   := Color(1.0, 0.227, 0.109)   # #ff3a1c 그라데이션 배경

const IMPACT_DELAY     := 0.1
const HOLD_TIME        := 1.4
const FADE_TIME        := 0.6
const SPAWN_W          := 75.0     # 원기둥 가로 반경 (= 발밑 ember spawn 반경)
const RECT_TOP_OFFSET  := -170.0   # 원기둥 위쪽 (발 기준 머리 위)
const RECT_BOT_OFFSET  := 20.0     # 원기둥 바닥 (발치 약간 아래)
const ELLIPSE_RY       := 22.0     # 바닥/위 타원 세로 반경 (납작)
const PSPEED           := 60.0

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
	if _glow_layer != null:
		_glow_layer.z_as_relative = false
		_glow_layer.z_index = int(pos.y) - 1

# 발밑 anchor — 미지정 시 _target 아래쪽 폴백
func _foot_pos() -> Vector2:
	return _ground_pos if _has_ground else _target + Vector2(0.0, 60.0)

var _age := -1.0
var _impact_emitted := false
var _particles: Array = []
var _ground_layer: Node2D
var _glow_layer: Node2D

func _ready() -> void:
	set_process(false)
	_ground_layer = _DrawLayer.new()
	_ground_layer.setup(self, true)
	add_child(_ground_layer)
	_ground_layer.set_meta("pass", "ground")
	_glow_layer = _DrawLayer.new()
	_glow_layer.setup(self, true)
	add_child(_glow_layer)
	_glow_layer.set_meta("pass", "glow")

func play(_caster_pos: Vector2, target_pos: Vector2) -> void:
	_target = target_pos
	_age = 0.0
	set_process(true)
	await get_tree().create_timer(IMPACT_DELAY + HOLD_TIME + FADE_TIME + 0.1).timeout
	if is_inside_tree():
		queue_free()

func _spawn_ember() -> void:
	if randf() > 0.6 * _scale():
		return
	var foot: Vector2 = _foot_pos()
	var ground_y: float = foot.y + RECT_BOT_OFFSET
	# 바닥 타원 영역 안 균등 (area uniform — sqrt 로 반경 분포)
	var ang: float = randf() * TAU
	var r_norm: float = sqrt(randf())
	var px: float = foot.x + cos(ang) * SPAWN_W * r_norm
	var py: float = ground_y + sin(ang) * ELLIPSE_RY * r_norm
	_particles.append({
		"pos": Vector2(px, py),
		"vel": Vector2(randf_range(-0.4, 0.4), -1.2 - randf() * 1.6),
		"life": 0.0,
		"max_life": 1.4 + randf() * 0.8,
		"size": 1.6 + randf() * 1.8,
	})

func _process(delta: float) -> void:
	_age += delta
	if not _impact_emitted and _age >= IMPACT_DELAY:
		_impact_emitted = true
		screen_effect.emit()
	if _age < IMPACT_DELAY + HOLD_TIME:
		for _i in range(2):
			_spawn_ember()

	var alive: Array = []
	for p in _particles:
		p["life"] += delta
		if p["life"] >= p["max_life"]:
			continue
		p["pos"] += p["vel"] * delta * PSPEED
		p["vel"] *= pow(0.99, delta * 60.0)
		alive.append(p)
	_particles = alive

	_ground_layer.queue_redraw()
	_glow_layer.queue_redraw()

func _global_alpha() -> float:
	var end_phase: float = IMPACT_DELAY + HOLD_TIME
	if _age < end_phase:
		return clampf(_age / 0.2, 0.0, 1.0)
	var t: float = (_age - end_phase) / FADE_TIME
	return clampf(1.0 - t, 0.0, 1.0)

# 발밑 원기둥 — 위 사각형 + 아래 반원을 하나의 polygon 으로 (겹침 없음, 색 통일).
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
	# 좌상 (투명)
	pts.append(Vector2(foot.x - SPAWN_W, top_y))
	cols.append(top_c)
	# 우상 (투명)
	pts.append(Vector2(foot.x + SPAWN_W, top_y))
	cols.append(top_c)
	# 우하 (진한) → 아래 반원 호 (오른쪽 → 왼쪽) → 좌하 (진한)
	var seg := 32
	for i in range(seg + 1):
		var a: float = PI * float(i) / float(seg)   # 0 (우끝) → PI (좌끝)
		pts.append(Vector2(foot.x + cos(a) * SPAWN_W, ground_y + sin(a) * ELLIPSE_RY))
		cols.append(bot_c)
	canvas.draw_polygon(pts, cols)

func _draw_glow_pass(canvas: CanvasItem) -> void:
	var ga: float = _global_alpha()
	if ga <= 0.0:
		return
	for p in _particles:
		var k: float = p["life"] / p["max_life"]
		var a: float = (1.0 - k) * ga
		var pr: float = p["size"]
		canvas.draw_circle(p["pos"], pr * 1.8, Color(COL_EMBER.r, COL_EMBER.g, COL_EMBER.b, a * 0.45))
		canvas.draw_circle(p["pos"], pr, Color(COL_EMBER.r, COL_EMBER.g, COL_EMBER.b, a))

# ── 가산 블렌드 레이어 ──
class _DrawLayer:
	extends Node2D
	var _fx: Node2D

	func setup(owner_fx: Node2D, additive: bool) -> void:
		_fx = owner_fx
		if additive:
			var m := CanvasItemMaterial.new()
			m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
			material = m

	func _draw() -> void:
		if get_meta("pass", "glow") == "ground":
			_fx._draw_ground_pass(self)
		else:
			_fx._draw_glow_pass(self)
