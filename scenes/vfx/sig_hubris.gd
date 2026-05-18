# scenes/vfx/sig_hubris.gd
# 그리스 신화 시그너처 — 휴브리스 (오만의 분노).
# ui_sample/vfx/Hubris VFX.html 재현. 적 단일 25+ 피해 → 다음 턴 STR +2 예고.
# play(_caster_pos, target_pos) — caster 무시. target = 발동 적 위치 (시전자 본인).
# ground: 발치 붉은 분노 ring 확장.
# glow: 머리 위 황금 halo + 3겹 zigzag 번개 cluster + sparks + flash.
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
const COL_GOLD      := Color(0.956, 0.862, 0.627)   # #f4dca0
const COL_GOLD_DEEP := Color(0.721, 0.564, 0.164)   # #b8902a
const COL_CYAN      := Color(0.603, 0.862, 1.0)     # #9adcff
const COL_RAGE      := Color(0.698, 0.164, 0.188)   # #b22a30
const COL_RAGE_DEEP := Color(0.290, 0.050, 0.062)   # #4a0c10

const IMPACT_DELAY := 0.1           # 번개 strike 즉시
const RAGE_DELAY   := 0.28          # 분노 ring 발동
const HOLD_TIME    := 0.55
const FADE_TIME    := 0.5
const HALO_R       := 56.0          # 머리 위 halo
const HEAD_OFFSET  := -140.0        # 적 몸체 중심 → 머리 위
const RAGE_R       := 70.0
const RAGE_SQUASH  := 0.32
const PSPEED       := 60.0

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
	await get_tree().create_timer(RAGE_DELAY + HOLD_TIME + FADE_TIME + 0.1).timeout
	if is_inside_tree():
		queue_free()

func _spawn_strike_sparks() -> void:
	var head: Vector2 = _target + Vector2(0.0, HEAD_OFFSET)
	for _i in range(_pcount(14)):
		var a := randf() * TAU
		var sp := 2.0 + randf() * 4.0
		_particles.append({
			"pos": head,
			"vel": Vector2(cos(a) * sp, sin(a) * sp * 0.7 - 0.5),
			"life": 0.0,
			"max_life": 0.45 + randf() * 0.35,
			"size": 1.2 + randf() * 1.4,
			"kind": "spark",
			"tint": "gold" if randf() < 0.7 else "cyan",
			"grav": 0.02,
		})

func _process(delta: float) -> void:
	_age += delta
	if not _impact_emitted and _age >= IMPACT_DELAY:
		_impact_emitted = true
		_spawn_strike_sparks()
		screen_effect.emit()

	var alive: Array = []
	for p in _particles:
		p["life"] += delta
		if p["life"] >= p["max_life"]:
			continue
		p["pos"] += p["vel"] * delta * PSPEED
		p["vel"].y += p.get("grav", 0.0) * delta * PSPEED
		p["vel"] *= pow(0.99, delta * 60.0)
		alive.append(p)
	_particles = alive

	_ground_layer.queue_redraw()
	_glow_layer.queue_redraw()

func _global_alpha() -> float:
	var end_phase: float = RAGE_DELAY + HOLD_TIME
	if _age < end_phase:
		return clampf(_age / 0.1, 0.0, 1.0)
	var t: float = (_age - end_phase) / FADE_TIME
	return clampf(1.0 - t, 0.0, 1.0)

# ── ground (캐릭터 뒤) — 분노 ring + 발치 dust ──
func _draw_ground_pass(canvas: CanvasItem) -> void:
	var ga: float = _global_alpha()
	if ga <= 0.0:
		return
	# 분노 ring (RAGE_DELAY 이후)
	if _age >= RAGE_DELAY:
		var t: float = (_age - RAGE_DELAY) / 0.9
		if t < 1.0:
			var sc: float = lerpf(0.4, 2.2, t)
			var alpha: float
			if t < 0.2:
				alpha = t / 0.2
			else:
				alpha = 1.0 - (t - 0.2) / 0.8 * 0.6
			alpha *= ga * 0.9
			var foot: Vector2 = _foot_pos()
			var r: float = RAGE_R * sc
			var seg := 40
			var pts := PackedVector2Array()
			for i in range(seg + 1):
				var a: float = TAU * float(i) / float(seg)
				pts.append(foot + Vector2(cos(a) * r, sin(a) * r * RAGE_SQUASH))
			canvas.draw_polyline(pts, Color(COL_RAGE, alpha), 2.0, true)
			# 내부 dim ring
			var pts2 := PackedVector2Array()
			for i in range(seg + 1):
				var a: float = TAU * float(i) / float(seg)
				pts2.append(foot + Vector2(cos(a) * r * 0.82, sin(a) * r * 0.82 * RAGE_SQUASH))
			canvas.draw_polyline(pts2, Color(COL_RAGE_DEEP, alpha * 0.6), 1.5, true)

# ── glow (캐릭터 앞) — 머리 위 halo + 3 zigzag bolts + sparks ──
func _draw_glow_pass(canvas: CanvasItem) -> void:
	var ga: float = _global_alpha()
	if ga <= 0.0:
		return
	_draw_halo(canvas, ga)
	if _impact_emitted:
		_draw_bolts(canvas, ga)
	for p in _particles:
		if p["kind"] != "spark":
			continue
		var k: float = p["life"] / p["max_life"]
		var a: float = (1.0 - k) * ga
		var col := _spark_color(p["tint"], a)
		var pr: float = p["size"]
		canvas.draw_circle(p["pos"], pr * 1.8, Color(col.r, col.g, col.b, col.a * 0.5))
		canvas.draw_circle(p["pos"], pr, col)

func _spark_color(tint: String, a: float) -> Color:
	match tint:
		"cyan": return Color(COL_CYAN.r, COL_CYAN.g, COL_CYAN.b, a)
		_:       return Color(COL_GOLD.r, COL_GOLD.g, COL_GOLD.b, a)

# 머리 위 황금 halo — 납작 ring (페이드 인/플리커/페이드 아웃)
func _draw_halo(canvas: CanvasItem, ga: float) -> void:
	var pop: float = clampf(_age / 0.18, 0.0, 1.0)
	if pop <= 0.0:
		return
	var fade: float = 1.0
	if _age > RAGE_DELAY + HOLD_TIME:
		fade = clampf(1.0 - (_age - RAGE_DELAY - HOLD_TIME) / FADE_TIME, 0.0, 1.0)
	if fade <= 0.0:
		return
	# 플리커 — 중간에 깜빡임
	var flick: float = 1.0
	if _age > 0.3 and _age < 0.4:
		flick = 0.4
	var alpha: float = pop * fade * ga * flick
	var head: Vector2 = _target + Vector2(0.0, HEAD_OFFSET - 36.0)
	var r: float = HALO_R * (0.95 + 0.05 * sin(_age * (TAU / 0.4)))
	# 외곽 원
	canvas.draw_arc(head, r, 0.0, TAU, 36, Color(COL_GOLD, alpha * 0.95), 2.0, true)
	# 내부 fill (옅은)
	var seg := 28
	var pts := PackedVector2Array()
	for i in range(seg + 1):
		var a: float = TAU * float(i) / float(seg)
		pts.append(head + Vector2(cos(a) * r * 0.95, sin(a) * r * 0.18))
	canvas.draw_polyline(pts, Color(COL_HOT, alpha * 0.6), 1.0, true)

# 3겹 zigzag 번개 cluster — 머리 위에서 적 위로
func _draw_bolts(canvas: CanvasItem, ga: float) -> void:
	var post: float = _age - IMPACT_DELAY
	if post < 0.0:
		return
	var fade: float = clampf(1.0 - post / 0.6, 0.0, 1.0)
	if fade <= 0.0:
		return
	var alpha: float = fade * ga
	var head: Vector2 = _target + Vector2(0.0, HEAD_OFFSET)
	# 3 bolt — 약간 오프셋 + 두께 차
	var bolt_data := [
		{"ox": 0.0,   "col": COL_GOLD, "w": 3.0},
		{"ox": 12.0,  "col": COL_CYAN, "w": 2.2},
		{"ox": -10.0, "col": COL_HOT,  "w": 1.6},
	]
	for entry in bolt_data:
		var ox: float = entry["ox"]
		# zigzag path — 4 segments
		var pts := PackedVector2Array()
		var top := head + Vector2(ox - 6.0, -50.0)
		var p1 := head + Vector2(ox + 8.0, -20.0)
		var p2 := head + Vector2(ox - 4.0, 12.0)
		var p3 := head + Vector2(ox + 6.0, 40.0)
		pts.append(top)
		pts.append(p1)
		pts.append(p2)
		pts.append(p3)
		canvas.draw_polyline(pts, Color(entry["col"], alpha), entry["w"], true)

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
