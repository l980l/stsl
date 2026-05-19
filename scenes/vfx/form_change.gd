# scenes/vfx/form_change.gd
# 폼 변환 VFX — ui_sample/vfx/Form Change VFX.html 재현 (FORM_SWITCH intent).
# play(_caster, target_pos) — caster 무시, target = 적 자기 위치.
# ground (캐릭터 뒤): 발치 황동 ring · charge halo · pillar 하단 base
# glow  (캐릭터 앞): pillar light · cracks · cyan shatter shards · shock ring · brass sparks
# 시퀀스: charge 0.5s → pillar 0.15s → crack 0.15s → SHATTER (screen_effect) → reveal 0.4s → fade
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


const COL_HOT       := Color(1.0, 1.0, 1.0)
const COL_CYAN      := Color(0.36, 0.862, 1.0)         # #5cdcff — 이전 폼
const COL_CYAN_DEEP := Color(0.10, 0.290, 0.480)       # #1a4a7a
const COL_BRASS     := Color(0.909, 0.784, 0.470)      # #e8c878 — 새 폼
const COL_BRASS_HOT := Color(1.0, 0.953, 0.752)        # #fff3c0
const COL_BRASS_DEEP := Color(0.584, 0.454, 0.129)     # #957421
const COL_CRACK     := Color(1.0, 0.839, 0.502)        # #ffd680

const CHARGE_TIME   := 0.5
const PILLAR_DELAY  := 0.15      # charge 끝 → pillar 등장
const CRACK_DELAY   := 0.15      # pillar 끝 → crack 시작
const IMPACT_DELAY  := CHARGE_TIME + PILLAR_DELAY + CRACK_DELAY  # SHATTER + screen_effect
const REVEAL_TIME   := 0.4
const HOLD_TIME     := 0.4
const FADE_TIME     := 0.4

const RING_RADIUS   := 90.0
const RING_SQUASH   := 0.34
const HALO_W        := 130.0
const HALO_H        := 190.0
const PILLAR_W      := 110.0
const PILLAR_H      := 380.0
const SHOCK_R       := 40.0
const PSPEED        := 60.0

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
var _glow_layer: Node2D
var _particles: Array = []
var _shatter_spawned: bool = false
var _reveal_spawned: bool = false

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
	await get_tree().create_timer(IMPACT_DELAY + REVEAL_TIME + HOLD_TIME + FADE_TIME + 0.1).timeout
	if is_inside_tree():
		queue_free()

func _process(delta: float) -> void:
	_age += delta
	# charge phase — cyan motes 위로 (이전 폼 누출)
	if _age < CHARGE_TIME:
		if randf() < 0.7 * _scale():
			_spawn_cyan_mote()
	# SHATTER 시점 — screen_effect emit + cyan shards burst
	if not _impact_emitted and _age >= IMPACT_DELAY:
		_impact_emitted = true
		screen_effect.emit()
	if not _shatter_spawned and _age >= IMPACT_DELAY:
		_shatter_spawned = true
		_spawn_shatter_burst()
	# REVEAL 시점 — brass sparks + ground dust
	if not _reveal_spawned and _age >= IMPACT_DELAY + 0.05:
		_reveal_spawned = true
		_spawn_reveal_burst()
	# 파티클 갱신
	var alive: Array = []
	for p in _particles:
		p["life"] += delta
		if p["life"] >= p["max_life"]:
			continue
		p["pos"] += p["vel"] * delta * PSPEED
		p["vel"].y += p.get("grav", 0.0) * delta * PSPEED
		p["vel"] *= 0.992
		alive.append(p)
	_particles = alive
	_ground_layer.queue_redraw()
	_glow_layer.queue_redraw()

func _global_alpha() -> float:
	var end_phase: float = IMPACT_DELAY + REVEAL_TIME + HOLD_TIME
	if _age < end_phase:
		return clampf(_age / 0.08, 0.0, 1.0)
	var t: float = (_age - end_phase) / FADE_TIME
	return clampf(1.0 - t, 0.0, 1.0)

func _spawn_cyan_mote() -> void:
	var foot := _foot_pos()
	var angle: float = randf() * TAU
	_particles.append({
		"pos": _target + Vector2(cos(angle) * 35.0, randf_range(-30.0, 30.0)),
		"vel": Vector2(randf_range(-0.4, 0.4), -1.2 - randf() * 1.4),
		"life": 0.0, "max_life": 0.9 + randf() * 0.5,
		"size": 1.4 + randf() * 1.6, "kind": "cyan_mote", "grav": -0.005 * PSPEED,
	})

func _spawn_shatter_burst() -> void:
	# cyan shard burst — 이전 폼 폭발
	var cnt: int = _pcount(50)
	for _i in range(cnt):
		var a: float = randf() * TAU
		var sp: float = 3.0 + randf() * 7.0
		_particles.append({
			"pos": _target + Vector2(0.0, randf_range(-35.0, 35.0)),
			"vel": Vector2(cos(a), sin(a)) * sp,
			"life": 0.0, "max_life": 0.7 + randf() * 0.5,
			"size": 1.4 + randf() * 1.4, "kind": "cyan_shard", "grav": 0.04 * PSPEED,
		})

func _spawn_reveal_burst() -> void:
	# brass sparks burst — 새 폼 등장
	var cnt: int = _pcount(70)
	for _i in range(cnt):
		var a: float = randf() * TAU
		var sp: float = 3.0 + randf() * 9.0
		_particles.append({
			"pos": _target,
			"vel": Vector2(cos(a), sin(a)) * sp,
			"life": 0.0, "max_life": 0.8 + randf() * 0.6,
			"size": 1.4 + randf() * 1.6, "kind": "brass_spark", "grav": 0.025 * PSPEED,
		})
	# ground dust (캐릭터 뒤 — ground layer 에서 그림)
	var foot := _foot_pos()
	var dust_cnt: int = _pcount(20)
	for _i in range(dust_cnt):
		var a2: float = randf_range(-PI * 0.9, -PI * 0.1)  # 위쪽 반원
		var sp2: float = 2.0 + randf() * 4.0
		_particles.append({
			"pos": foot + Vector2(randf_range(-50.0, 50.0), 0.0),
			"vel": Vector2(cos(a2), sin(a2)) * sp2,
			"life": 0.0, "max_life": 1.0 + randf() * 0.6,
			"size": 8.0 + randf() * 8.0, "kind": "ground_dust", "grav": 0.012 * PSPEED,
		})
	# brass embers (drifting)
	var em_cnt: int = _pcount(18)
	for _i in range(em_cnt):
		_particles.append({
			"pos": _target + Vector2(randf_range(-25.0, 25.0), randf_range(-40.0, 40.0)),
			"vel": Vector2(randf_range(-0.8, 0.8), -0.4 - randf() * 1.2),
			"life": 0.0, "max_life": 1.4 + randf() * 0.8,
			"size": 1.6 + randf() * 1.4, "kind": "brass_ember", "grav": -0.004 * PSPEED,
		})

# ── ground pass — 캐릭터 발치/뒤 ──
func _draw_ground_pass(canvas: CanvasItem) -> void:
	var ga := _global_alpha()
	if ga <= 0.0:
		return
	var foot := _foot_pos()
	# charge phase — 발치 황금 ring (pulse) + halo
	if _age < IMPACT_DELAY:
		var t: float = clampf(_age / CHARGE_TIME, 0.0, 1.0)
		var pulse: float = 0.85 + 0.15 * sin(_age * 8.0)
		# halo
		var ha_alpha: float = ga * 0.5 * t * pulse
		canvas.draw_circle(_target, HALO_W * pulse,
			Color(COL_BRASS.r, COL_BRASS.g, COL_BRASS.b, ha_alpha * 0.35))
		# 발치 ring (squashed)
		_draw_squashed_ring(canvas, foot, RING_RADIUS * pulse, RING_SQUASH,
			Color(COL_BRASS.r, COL_BRASS.g, COL_BRASS.b, ga * 0.85), 3.0)
		_draw_squashed_ring(canvas, foot, RING_RADIUS * pulse * 0.75, RING_SQUASH,
			Color(COL_BRASS_HOT.r, COL_BRASS_HOT.g, COL_BRASS_HOT.b, ga * 0.65), 1.8)
	# (pillar 는 glow pass 로 이동됨 — 캐릭터 앞에 표시)
	# ground dust 파티클 (캐릭터 뒤)
	for p in _particles:
		if p["kind"] != "ground_dust":
			continue
		var k: float = p["life"] / p["max_life"]
		var a: float = (1.0 - k) * ga * 0.55
		var r: float = p["size"] * (1.0 + k * 1.2)
		canvas.draw_circle(p["pos"], r, Color(0.78, 0.67, 0.47, a))

# ── glow pass — 캐릭터 앞 ──
func _draw_glow_pass(canvas: CanvasItem) -> void:
	var ga := _global_alpha()
	if ga <= 0.0:
		return
	var foot := _foot_pos()
	# pillar (발바닥→위) — 캐릭터 앞 빛줄기. 발바닥에서 시작해 위로 자라남.
	var pillar_start: float = CHARGE_TIME
	var pillar_end: float = IMPACT_DELAY + REVEAL_TIME + HOLD_TIME * 0.5
	if _age >= pillar_start and _age < pillar_end:
		var pt: float = clampf((_age - pillar_start) / (PILLAR_DELAY + CRACK_DELAY), 0.0, 1.0)
		var base_y: float = foot.y
		var top_y: float = base_y - PILLAR_H * pt
		var pa: float = ga * 0.55 * pt
		canvas.draw_rect(Rect2(foot.x - PILLAR_W * 0.5, top_y,
			PILLAR_W, base_y - top_y),
			Color(COL_BRASS_HOT.r, COL_BRASS_HOT.g, COL_BRASS_HOT.b, pa))
		# 내곽 — 더 밝은 코어
		var core_w: float = PILLAR_W * 0.25
		canvas.draw_rect(Rect2(foot.x - core_w * 0.5, top_y,
			core_w, base_y - top_y),
			Color(1.0, 1.0, 1.0, pa * 1.3))
	# cracks — IMPACT_DELAY 직전 (CRACK_DELAY 동안) 위로 기어올라가는 빛 균열
	var crack_start: float = IMPACT_DELAY - CRACK_DELAY
	if _age >= crack_start and _age < IMPACT_DELAY + 0.2:
		_draw_cracks(canvas, ga, clampf((_age - crack_start) / CRACK_DELAY, 0.0, 1.2))
	# SHOCK ring — IMPACT 직후 짧게
	if _age >= IMPACT_DELAY and _age < IMPACT_DELAY + 0.5:
		var st: float = (_age - IMPACT_DELAY) / 0.5
		var sa: float = (1.0 - st) * ga
		var sr: float = SHOCK_R + 220.0 * st
		_draw_squashed_ring(canvas, _foot_pos(), sr, RING_SQUASH * 1.3,
			Color(COL_BRASS_HOT.r, COL_BRASS_HOT.g, COL_BRASS_HOT.b, sa * 0.8), 3.0)
	# reveal flash — IMPACT 시 흰 원
	if _age >= IMPACT_DELAY and _age < IMPACT_DELAY + 0.25:
		var ft: float = (_age - IMPACT_DELAY) / 0.25
		var fa: float = (1.0 - ft) * ga * 0.85
		canvas.draw_circle(_target, 60.0 + 40.0 * ft,
			Color(COL_HOT.r, COL_HOT.g, COL_HOT.b, fa))
	# 파티클 (cyan_mote / cyan_shard / brass_spark / brass_ember)
	_draw_particles(canvas, ga)

func _draw_squashed_ring(canvas: CanvasItem, c: Vector2, radius: float, squash: float, col: Color, width: float) -> void:
	var seg: int = 36
	var pts := PackedVector2Array()
	for i in range(seg + 1):
		var ang: float = TAU * float(i) / float(seg)
		pts.append(c + Vector2(cos(ang) * radius, sin(ang) * radius * squash))
	for i in range(pts.size() - 1):
		canvas.draw_line(pts[i], pts[i + 1], col, width, true)

func _draw_cracks(canvas: CanvasItem, ga: float, t: float) -> void:
	# 캐릭터 중심에서 위로 5가닥 균열 — 진행도 t 만큼 그려짐
	var origin := _target + Vector2(0.0, 60.0)  # 발치 근처 시작
	var paths: Array = [
		[Vector2(0, 0), Vector2(-4, -20), Vector2(4, -50), Vector2(-6, -90), Vector2(0, -120)],
		[Vector2(0, -20), Vector2(-18, -34), Vector2(-30, -56), Vector2(-24, -80)],
		[Vector2(0, -42), Vector2(20, -58), Vector2(30, -82), Vector2(22, -104)],
		[Vector2(0, -64), Vector2(-16, -84), Vector2(-22, -108), Vector2(-10, -130)],
		[Vector2(0, -86), Vector2(16, -102), Vector2(28, -124), Vector2(14, -148)],
	]
	for path_idx in range(paths.size()):
		var delay: float = float(path_idx) * 0.08
		var pt: float = clampf((t - delay) / 0.4, 0.0, 1.0)
		if pt <= 0.0:
			continue
		var p: Array = paths[path_idx]
		var seg_count: int = p.size() - 1
		var end_seg: int = int(round(float(seg_count) * pt))
		for i in range(end_seg):
			var s: Vector2 = origin + p[i]
			var e: Vector2 = origin + p[i + 1]
			canvas.draw_line(s, e,
				Color(COL_CRACK.r, COL_CRACK.g, COL_CRACK.b, ga * 0.95), 2.4, true)
			# 글로우 (넓고 옅게)
			canvas.draw_line(s, e,
				Color(COL_CRACK.r, COL_CRACK.g, COL_CRACK.b, ga * 0.35), 6.0, true)

func _draw_particles(canvas: CanvasItem, ga: float) -> void:
	for p in _particles:
		var kind: String = p["kind"]
		if kind == "ground_dust":
			continue  # ground pass 에서 그림
		var k: float = p["life"] / p["max_life"]
		var a: float = (1.0 - k) * ga
		var pr: float = p["size"]
		if kind == "cyan_mote":
			canvas.draw_circle(p["pos"], pr,
				Color(0.55, 0.90, 1.0, a * 0.85))
		elif kind == "cyan_shard":
			canvas.draw_circle(p["pos"], pr,
				Color(0.55 + 0.25 * a, 0.86 - 0.24 * k, 1.0, a))
			# streak (얇은 가로선)
			canvas.draw_rect(Rect2(p["pos"].x - pr * 2.0, p["pos"].y - 0.3, pr * 4.0, 0.6),
				Color(0.55 + 0.25 * a, 0.86 - 0.24 * k, 1.0, a))
		elif kind == "brass_spark":
			canvas.draw_circle(p["pos"], pr,
				Color(1.0, 0.90 - 0.16 * k, 0.62 - 0.31 * k, a))
			canvas.draw_rect(Rect2(p["pos"].x - pr * 2.0, p["pos"].y - 0.3, pr * 4.0, 0.6),
				Color(1.0, 0.90 - 0.16 * k, 0.62 - 0.31 * k, a))
		elif kind == "brass_ember":
			canvas.draw_circle(p["pos"], pr,
				Color(1.0, 0.78 - 0.24 * k, 0.43 - 0.16 * k, a * 0.9))

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
		match get_meta("pass", "glow"):
			"ground": _fx._draw_ground_pass(self)
			_:       _fx._draw_glow_pass(self)
