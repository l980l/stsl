# scenes/vfx/sig_karma.gd
# 불교 신화 시그너처 — 인과응보 (KARMA).
# ui_sample/vfx/Karma VFX.html 재현. 적 사망 → 누적 피해 25% 를 모든 영웅에 회복.
# play(caster_pos, target_pos) — caster = 시체(적), target = 첫 영웅(빔 대표).
# 추가로 set_hero_positions(arr) 로 다중 영웅 위치 전달 시 모두에게 빔.
# ground: 시체 위 부드러운 wash + 회전 lotus 베이스.
# glow: lotus bloom + 3겹 expanding ring + 각 영웅에 빔 + 각 영웅 머리 halo + 꽃잎.
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


const COL_HOT     := Color(1.0, 1.0, 1.0)
const COL_BONE    := Color(0.964, 0.945, 0.901)   # #f6f1e6
const COL_LOTUS   := Color(1.0, 0.721, 0.831)     # #ffb8d4
const COL_LOTUS_D := Color(0.850, 0.478, 0.627)   # #d97aa0
const COL_GOLD    := Color(0.956, 0.862, 0.627)   # #f4dca0

const BLOOM_DELAY  := 0.0
const RINGS_DELAY  := 0.15
const BEAMS_DELAY  := 0.55
const IMPACT_DELAY := BEAMS_DELAY     # SFX + screen flash
const HOLD_TIME    := 1.0
const FADE_TIME    := 0.55
const LOTUS_R      := 50.0
const RING_R       := 70.0
const HALO_R       := 36.0
const PSPEED       := 60.0

signal screen_effect

var _caster := Vector2.ZERO
var _target := Vector2.ZERO
var _hero_positions: Array = []   # Vector2 array — 다중 빔 타겟
var _ground_pos := Vector2.ZERO
var _has_ground: bool = false

func set_ground_anchor(pos: Vector2) -> void:
	_ground_pos = pos
	_has_ground = true
	if _ground_layer != null:
		_ground_layer.z_as_relative = false
		_ground_layer.z_index = int(pos.y) - 1

# 다중 영웅 위치 (시체 → 영웅별 빔)
func set_hero_positions(positions: Array) -> void:
	_hero_positions = positions.duplicate()

func _foot_pos() -> Vector2:
	return _ground_pos if _has_ground else _caster + Vector2(0.0, 30.0)

func _targets() -> Array:
	if _hero_positions.is_empty():
		return [_target]
	return _hero_positions

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

func play(caster_pos: Vector2, target_pos: Vector2) -> void:
	_caster = caster_pos
	_target = target_pos
	_age = 0.0
	set_process(true)
	await get_tree().create_timer(BEAMS_DELAY + HOLD_TIME + FADE_TIME + 0.1).timeout
	if is_inside_tree():
		queue_free()

func _spawn_petal() -> void:
	if randf() > 0.5 * _scale():
		return
	var ang := randf() * TAU
	var sp := 0.6 + randf() * 1.0
	_particles.append({
		"pos": _caster,
		"vel": Vector2(cos(ang) * sp, sin(ang) * sp * 0.5 - 0.3),
		"life": 0.0,
		"max_life": 1.8 + randf() * 0.8,
		"size": 2.2 + randf() * 1.6,
		"kind": "petal",
		"rot": randf() * TAU,
		"rot_v": randf_range(-1.5, 1.5),
	})

func _process(delta: float) -> void:
	_age += delta
	if not _impact_emitted and _age >= IMPACT_DELAY:
		_impact_emitted = true
		screen_effect.emit()
	if _age >= RINGS_DELAY and _age < RINGS_DELAY + HOLD_TIME:
		_spawn_petal()

	var alive: Array = []
	for p in _particles:
		p["life"] += delta
		if p["life"] >= p["max_life"]:
			continue
		p["pos"] += p["vel"] * delta * PSPEED
		p["vel"] *= pow(0.99, delta * 60.0)
		if p.has("rot"):
			p["rot"] += p["rot_v"] * delta
		alive.append(p)
	_particles = alive

	_ground_layer.queue_redraw()
	_glow_layer.queue_redraw()

func _global_alpha() -> float:
	var end_phase: float = BEAMS_DELAY + HOLD_TIME
	if _age < end_phase:
		return clampf(_age / 0.15, 0.0, 1.0)
	var t: float = (_age - end_phase) / FADE_TIME
	return clampf(1.0 - t, 0.0, 1.0)

# ── ground — 시체 위 부드러운 wash (분홍 빛) ──
func _draw_ground_pass(canvas: CanvasItem) -> void:
	var ga: float = _global_alpha()
	if ga <= 0.0:
		return
	var grow: float = clampf(_age / 0.4, 0.0, 1.0)
	var alpha: float = grow * ga * 0.5
	var foot: Vector2 = _foot_pos()
	# 바닥 ellipse (납작)
	var seg := 32
	var pts := PackedVector2Array()
	for i in range(seg + 1):
		var a: float = TAU * float(i) / float(seg)
		pts.append(foot + Vector2(cos(a) * 90.0 * grow, sin(a) * 30.0 * grow))
	canvas.draw_colored_polygon(pts, Color(COL_LOTUS, alpha * 0.6))
	canvas.draw_colored_polygon(pts, Color(COL_GOLD, alpha * 0.25))

# ── glow — lotus + 3 rings + beams + hero halos + petals ──
func _draw_glow_pass(canvas: CanvasItem) -> void:
	var ga: float = _global_alpha()
	if ga <= 0.0:
		return
	_draw_lotus(canvas, ga)
	if _age >= RINGS_DELAY:
		_draw_rings(canvas, ga)
	if _age >= BEAMS_DELAY:
		_draw_beams(canvas, ga)
		_draw_hero_halos(canvas, ga)
	_draw_petals(canvas, ga)

# 시체 위에 피어나는 연꽃 — 4 잎 ellipse 회전 + 중심 황금 원
func _draw_lotus(canvas: CanvasItem, ga: float) -> void:
	var bloom: float = clampf(_age / 0.5, 0.0, 1.0)
	if bloom <= 0.0:
		return
	var fade: float = 1.0
	if _age > BEAMS_DELAY + HOLD_TIME:
		fade = clampf(1.0 - (_age - BEAMS_DELAY - HOLD_TIME) / FADE_TIME, 0.0, 1.0)
	var alpha: float = bloom * fade * ga
	var ctr: Vector2 = _caster + Vector2(0.0, -20.0)
	var r: float = LOTUS_R * bloom
	# 4 외곽 잎 (분홍)
	for i in range(4):
		var ang: float = TAU * float(i) / 4.0
		var seg := 16
		var pts := PackedVector2Array()
		for k in range(seg + 1):
			var t: float = TAU * float(k) / float(seg)
			var lx: float = cos(t) * r * 0.32
			var ly: float = sin(t) * r * 0.7
			# 회전
			var rx: float = lx * cos(ang) - ly * sin(ang)
			var ry: float = lx * sin(ang) + ly * cos(ang)
			pts.append(ctr + Vector2(rx, ry))
		canvas.draw_colored_polygon(pts, Color(COL_LOTUS, alpha * 0.5))
	# 4 내곽 잎 (황금, 45도 회전)
	for i in range(4):
		var ang: float = TAU * float(i) / 4.0 + PI / 4.0
		var seg := 12
		var pts2 := PackedVector2Array()
		for k in range(seg + 1):
			var t: float = TAU * float(k) / float(seg)
			var lx: float = cos(t) * r * 0.20
			var ly: float = sin(t) * r * 0.50
			var rx: float = lx * cos(ang) - ly * sin(ang)
			var ry: float = lx * sin(ang) + ly * cos(ang)
			pts2.append(ctr + Vector2(rx, ry))
		canvas.draw_colored_polygon(pts2, Color(COL_GOLD, alpha * 0.55))
	# 중심 — 흰 코어
	canvas.draw_circle(ctr, r * 0.12, Color(COL_HOT.r, COL_HOT.g, COL_HOT.b, alpha))

# 3 expanding karma rings (staggered)
func _draw_rings(canvas: CanvasItem, ga: float) -> void:
	var ring_cols := [COL_HOT, COL_LOTUS, COL_GOLD]
	for ri in range(3):
		var delay: float = RINGS_DELAY + float(ri) * 0.18
		var t: float = (_age - delay) / 1.4
		if t < 0.0 or t > 1.0:
			continue
		var sc: float = lerpf(0.2, 2.5, t)
		var alpha: float
		if t < 0.2:
			alpha = t / 0.2
		else:
			alpha = 1.0 - (t - 0.2) / 0.8
		alpha *= ga * 0.85
		var rad: float = RING_R * sc
		canvas.draw_arc(_caster + Vector2(0.0, -20.0), rad, 0.0, TAU, 48,
			Color(ring_cols[ri], alpha), 2.0, true)

# 시체 → 각 영웅 빔
func _draw_beams(canvas: CanvasItem, ga: float) -> void:
	var post: float = _age - BEAMS_DELAY
	var t: float = clampf(post / 0.8, 0.0, 1.0)
	if t <= 0.0:
		return
	var fade: float = 1.0
	if _age > BEAMS_DELAY + HOLD_TIME:
		fade = clampf(1.0 - (_age - BEAMS_DELAY - HOLD_TIME) / FADE_TIME, 0.0, 1.0)
	var alpha: float = fade * ga
	var origin: Vector2 = _caster + Vector2(0.0, -20.0)
	for hp in _targets():
		var dir: Vector2 = hp - origin
		var dist: float = dir.length()
		if dist < 1.0:
			continue
		# 빔 progress — 0..t 만큼 그림
		var head: Vector2 = origin + dir * t
		# 외곽 — lotus 색
		canvas.draw_line(origin, head, Color(COL_LOTUS, alpha * 0.85), 3.0, true)
		# 코어 — 흰
		canvas.draw_line(origin, head, Color(COL_HOT.r, COL_HOT.g, COL_HOT.b, alpha), 1.4, true)
		# 끝부분 글로우
		if t > 0.5:
			canvas.draw_circle(head, 8.0, Color(COL_GOLD.r, COL_GOLD.g, COL_GOLD.b, alpha * 0.5))
			canvas.draw_circle(head, 4.0, Color(COL_HOT.r, COL_HOT.g, COL_HOT.b, alpha))

# 빔이 영웅에 도달 후 — 머리 위 황금 halo
func _draw_hero_halos(canvas: CanvasItem, ga: float) -> void:
	var post: float = _age - BEAMS_DELAY - 0.5
	if post < 0.0:
		return
	var pop: float = clampf(post / 0.25, 0.0, 1.0)
	var fade: float = 1.0
	if _age > BEAMS_DELAY + HOLD_TIME:
		fade = clampf(1.0 - (_age - BEAMS_DELAY - HOLD_TIME) / FADE_TIME, 0.0, 1.0)
	var alpha: float = pop * fade * ga
	for hp in _targets():
		var head: Vector2 = hp + Vector2(0.0, -50.0)
		var r: float = HALO_R * pop
		canvas.draw_arc(head, r, 0.0, TAU, 32, Color(COL_GOLD, alpha * 0.95), 1.6, true)
		# 납작 inner glow
		var seg := 20
		var pts := PackedVector2Array()
		for i in range(seg + 1):
			var a: float = TAU * float(i) / float(seg)
			pts.append(head + Vector2(cos(a) * r * 0.95, sin(a) * r * 0.2))
		canvas.draw_polyline(pts, Color(COL_HOT.r, COL_HOT.g, COL_HOT.b, alpha * 0.6), 1.0, true)

# 꽃잎 입자 — 시체에서 부유
func _draw_petals(canvas: CanvasItem, ga: float) -> void:
	for p in _particles:
		if p["kind"] != "petal":
			continue
		var k: float = p["life"] / p["max_life"]
		var a: float = (1.0 - k) * ga * 0.85
		var pr: float = p["size"]
		var rot: float = p.get("rot", 0.0)
		# 작은 회전 ellipse (꽃잎 모양 근사)
		var pts := PackedVector2Array()
		var seg := 10
		for i in range(seg + 1):
			var t: float = TAU * float(i) / float(seg)
			var lx: float = cos(t) * pr * 1.6
			var ly: float = sin(t) * pr * 0.9
			var rx: float = lx * cos(rot) - ly * sin(rot)
			var ry: float = lx * sin(rot) + ly * cos(rot)
			pts.append(p["pos"] + Vector2(rx, ry))
		canvas.draw_colored_polygon(pts, Color(COL_LOTUS_D.r, COL_LOTUS_D.g, COL_LOTUS_D.b, a))

# ── 블렌드 분리 레이어 ──
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
