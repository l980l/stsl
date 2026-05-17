# scenes/vfx/summon_burst.gd
# 병사 소환 VFX — ui_sample/vfx/Soldier Summon VFX.html 재현
# (검·병사 모델은 실제 캐릭터/토큰 노드에서 처리. VFX 는 황금 광채 / 파티클만.)
#
# 흐름:
#  1) 영웅 위치에서 황금 callRing 확장 (CHARGE_TIME) → screen_effect emit (impact)
#  2) 각 spawn_positions 에 spawnPillar + 솟구치는 sparkle + 바닥 dust ring
#  3) pillar/파티클 페이드 후 자유
#
# 사용:
#   var fx := SummonBurst.new()
#   fx.set_spawn_positions([slot1, slot2, ...])
#   add_child(fx)
#   fx.play(caster_pos, fallback_target)
extends Node2D

# 파티클 갯수 — GameSettings.particle_count_scale 적용 (하/중/상 = 0.25/0.5/1.0배)
var _particle_scale_override: float = -1.0

func _pcount(n: int) -> int:
	if _particle_scale_override > 0.0:
		return maxi(1, int(round(n * _particle_scale_override)))
	var gs := get_node_or_null("/root/GameSettings")
	return n if gs == null else maxi(1, int(round(n * gs.particle_count_scale())))


const COL_HOT  := Color(1.0, 0.913, 0.659)   # #ffe9a8 — 코어 황금
const COL_MID  := Color(0.784, 0.572, 0.196) # #c89232 — 중간 황금
const COL_DEEP := Color(0.416, 0.267, 0.031) # #6a4408 — 그림자 황금
const COL_DUST := Color(0.745, 0.588, 0.392) # 황갈 흙먼지

const CHARGE_TIME    := 0.32   # callRing 확장 + 임팩트 동기화
const IMPACT_DELAY   := CHARGE_TIME
const RING_FADE_TIME := 0.45
const PILLAR_GROW    := 0.25
const PILLAR_HOLD    := 0.45
const PILLAR_FADE    := 0.5
const RING_MAX_R     := 180.0
const PILLAR_W       := 70.0
const PILLAR_H       := 180.0
const PSPEED         := 60.0

## 화면 플래시 + summon SFX 트리거
signal screen_effect

var _caster := Vector2.ZERO
var _spawn_positions: Array = []  # Vector2 of summon points

var _ring_age := -1.0
var _pillar_age := -1.0
var _particles: Array = []
var _smoke_layer: Node2D   # 일반 블렌드 — dust
var _glow_layer: Node2D    # 가산 블렌드 — ring/pillar/sparkle

func set_spawn_positions(positions: Array) -> void:
	_spawn_positions = positions.duplicate()

func _ready() -> void:
	set_process(false)
	_smoke_layer = _DrawLayer.new()
	_smoke_layer.setup(self, false)
	add_child(_smoke_layer)
	_glow_layer = _DrawLayer.new()
	_glow_layer.setup(self, true)
	add_child(_glow_layer)

# caster_pos = 영웅 위치, target_pos = spawn_positions 비었을 때 폴백
func play(caster_pos: Vector2, target_pos: Vector2) -> void:
	_caster = caster_pos
	if _spawn_positions.is_empty():
		_spawn_positions = [target_pos]
	_run()

func _run() -> void:
	_ring_age = 0.0
	set_process(true)
	await get_tree().create_timer(CHARGE_TIME).timeout
	if not is_inside_tree():
		return
	screen_effect.emit()
	_pillar_age = 0.0
	for pos in _spawn_positions:
		_spawn_burst(pos)
	await get_tree().create_timer(PILLAR_GROW + PILLAR_HOLD + PILLAR_FADE + 0.3).timeout
	if is_inside_tree():
		queue_free()

# 각 spawn 지점에서 솟구치는 sparkle + 바닥 dust ring
func _spawn_burst(ctr: Vector2) -> void:
	# 사방으로 튀는 황금 sparkle
	for _i in range(_pcount(20)):
		var a := randf() * TAU
		var sp := 1.5 + randf() * 4.0
		_particles.append(_mk(ctr, Vector2(cos(a) * sp, sin(a) * sp * 0.4 - 1.6),
			1.0 + randf() * 0.7, 1.4 + randf() * 1.4, "spark", 0.04))
	# 위로 솟구치는 컬럼형 sparkle
	for _i in range(_pcount(12)):
		_particles.append(_mk(ctr + Vector2(randf_range(-22.0, 22.0), 0.0),
			Vector2(randf_range(-0.3, 0.3), -1.2 - randf() * 1.2),
			0.9 + randf() * 0.5, 1.2 + randf() * 1.2, "spark", 0.0))
	# 바닥 dust ring
	for _i in range(_pcount(14)):
		var a2 := randf() * TAU
		var sp2 := 1.0 + randf() * 3.0
		_particles.append(_mk(ctr, Vector2(cos(a2) * sp2, sin(a2) * sp2 * 0.2 - 0.4 - randf() * 0.5),
			1.1 + randf() * 0.7, 14.0 + randf() * 12.0, "dust", -0.005))

func _mk(pos: Vector2, vel: Vector2, max_life: float, r: float, kind: String,
		grav: float = 0.0) -> Dictionary:
	return {"pos": pos, "vel": vel, "life": 0.0, "max_life": max_life, "r": r,
		"kind": kind, "grav": grav}

func _process(delta: float) -> void:
	if _ring_age >= 0.0:
		_ring_age += delta
	if _pillar_age >= 0.0:
		_pillar_age += delta

	var damp: float = pow(0.992, delta * 60.0)
	var alive: Array = []
	for p in _particles:
		p["life"] += delta
		if p["life"] >= p["max_life"]:
			continue
		p["pos"] += p["vel"] * delta * PSPEED
		p["vel"].y += p["grav"] * delta * PSPEED
		p["vel"] *= damp
		alive.append(p)
	_particles = alive

	_smoke_layer.queue_redraw()
	_glow_layer.queue_redraw()

# ── dust (일반 블렌드) ──
func _draw_smoke_pass(canvas: CanvasItem) -> void:
	for p in _particles:
		if p["kind"] != "dust":
			continue
		var k: float = p["life"] / p["max_life"]
		var a: float = (1.0 - k) * 0.4
		var r: float = p["r"] * (1.0 + k * 1.4)
		canvas.draw_circle(p["pos"], r, Color(COL_DUST, a))

# ── glow (가산 블렌드) — callRing, spawnPillar, sparkle ──
func _draw_glow_pass(canvas: CanvasItem) -> void:
	if _ring_age >= 0.0:
		_draw_call_ring(canvas)
	if _pillar_age >= 0.0:
		for pos in _spawn_positions:
			_draw_pillar(canvas, pos)
	for p in _particles:
		if p["kind"] != "spark":
			continue
		var k: float = p["life"] / p["max_life"]
		var a: float = 1.0 - k
		var col := Color(1.0, (220.0 - 40.0 * k) / 255.0, (140.0 - 60.0 * k) / 255.0, a)
		var pr: float = p["r"]
		canvas.draw_circle(p["pos"], pr, col)
		canvas.draw_rect(Rect2(p["pos"].x - pr * 2.5, p["pos"].y - 0.3, pr * 5.0, 0.6), col)

# 영웅 위치에서 황금 ring 확장 (HTML callRing)
func _draw_call_ring(canvas: CanvasItem) -> void:
	var t: float = clampf(_ring_age / CHARGE_TIME, 0.0, 1.0)
	var post_t: float = 0.0
	var alpha: float
	if _ring_age <= CHARGE_TIME:
		alpha = clampf(t * 4.0, 0.0, 1.0)
	else:
		post_t = clampf((_ring_age - CHARGE_TIME) / RING_FADE_TIME, 0.0, 1.0)
		alpha = clampf(1.0 - post_t, 0.0, 1.0)
	if alpha <= 0.0:
		return
	var sc: float = lerpf(0.2, 1.0, t) + post_t * 1.3
	var rad: float = RING_MAX_R * sc
	var thick: float = lerpf(8.0, 1.5, t + post_t * 0.5)
	canvas.draw_arc(_caster, rad, 0.0, TAU, 64, Color(COL_HOT, alpha), thick, true)
	canvas.draw_arc(_caster, rad * 0.92, 0.0, TAU, 48, Color(COL_MID, alpha * 0.7), thick * 0.5, true)

# 각 spawn 지점 황금 컬럼 (HTML spawnPillar)
func _draw_pillar(canvas: CanvasItem, ctr: Vector2) -> void:
	var grow: float = clampf(_pillar_age / PILLAR_GROW, 0.0, 1.0)
	var fade: float = 1.0
	if _pillar_age > PILLAR_GROW + PILLAR_HOLD:
		fade = clampf(1.0 - (_pillar_age - PILLAR_GROW - PILLAR_HOLD) / PILLAR_FADE, 0.0, 1.0)
	if fade <= 0.0:
		return
	var w: float = PILLAR_W
	var h: float = PILLAR_H * grow
	var alpha: float = grow * fade
	var bottom_y: float = ctr.y + 20.0
	var top_y: float = bottom_y - h
	# 외측 (밝은 황금)
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(ctr.x - w * 0.55, bottom_y),
		Vector2(ctr.x + w * 0.55, bottom_y),
		Vector2(ctr.x + w * 0.20, top_y),
		Vector2(ctr.x - w * 0.20, top_y),
	]), Color(COL_HOT, 0.78 * alpha))
	# 내측 (코어 황금)
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(ctr.x - w * 0.32, bottom_y),
		Vector2(ctr.x + w * 0.32, bottom_y),
		Vector2(ctr.x + w * 0.08, top_y),
		Vector2(ctr.x - w * 0.08, top_y),
	]), Color(COL_MID, 0.6 * alpha))
	# 발치 글로우 ring
	canvas.draw_arc(Vector2(ctr.x, bottom_y - 4.0), 28.0 * grow, 0.0, TAU, 24,
		Color(COL_HOT, alpha * 0.8), 3.0, true)

# 가산/일반 블렌드 분리 레이어
class _DrawLayer:
	extends Node2D
	var _fx: Node2D
	var _additive := false

	func setup(owner_fx: Node2D, additive: bool) -> void:
		_fx = owner_fx
		_additive = additive
		if additive:
			var m := CanvasItemMaterial.new()
			m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
			material = m

	func _draw() -> void:
		if _additive:
			_fx._draw_glow_pass(self)
		else:
			_fx._draw_smoke_pass(self)
