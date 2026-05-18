# scenes/vfx/summon_circle.gd
# 소환 VFX — ui_sample/vfx/Summon VFX.html 재현 (적 SUMMON intent 발동 시).
# 시전자 발치에 회전하는 보라 마법진 + 솟구치는 빛기둥 + 마법진에서 솟는 motes/rune.
# peak 시 짧은 shockwave + screen_effect emit, 페이드 후 자유.
extends Node2D

# 파티클 갯수 — GameSettings.particle_count_scale 적용 (하/중/상 = 0.25/0.5/1.0배)
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
const COL_VIOLET  := Color(0.603, 0.486, 1.0)        # #9a7cff
const COL_LIGHT   := Color(0.784, 0.721, 1.0)        # #c8b8ff
const COL_CYAN    := Color(0.360, 0.862, 1.0)        # #5cdcff
const COL_MAGENTA := Color(1.0, 0.360, 0.815)        # #ff5cd0
const COL_DEEP    := Color(0.290, 0.117, 0.603)      # #4a1e9a
const COL_HAZE    := Color(0.705, 0.627, 1.0)        # 보라 dust

const CHANNEL_TIME := 0.4    # 마법진 등장
const PEAK_DELAY   := 0.6    # peak burst 시점 (screen_effect)
const IMPACT_DELAY := PEAK_DELAY
const HOLD_TIME    := 0.5    # 소환수 등장 hold
const FADE_TIME    := 0.45
const CIRCLE_R     := 130.0  # 외곽 마법진 반경
const CIRCLE_R2    := 90.0   # 안쪽 마법진 반경
const PILLAR_W     := 140.0
const PILLAR_H     := 220.0
const PSPEED       := 60.0
const RING_SQUASH  := 0.32   # 바닥 마법진 perspective (3D rotateX(72deg))

## 화면 플래시 + summon SFX 트리거 (peak 시점)
signal screen_effect

var _caster := Vector2.ZERO
var _ground_pos := Vector2.ZERO
var _has_ground: bool = false

func set_ground_anchor(pos: Vector2) -> void:
	_ground_pos = pos
	_has_ground = true
	if _ground_layer != null:
		_ground_layer.z_as_relative = false
		_ground_layer.z_index = int(pos.y) - 1

func _foot_pos() -> Vector2:
	return _ground_pos if _has_ground else _caster

var _age := -1.0
var _impact_emitted := false
var _particles: Array = []
var _ground_layer: Node2D   # 마법진 + 바닥 haze (캐릭터 뒤)
var _glow_layer: Node2D     # pillar + rising motes + peak shock + rune (캐릭터 앞)

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

func play(caster_pos: Vector2, _target_pos: Vector2) -> void:
	_caster = caster_pos
	_age = 0.0
	set_process(true)
	await get_tree().create_timer(PEAK_DELAY + HOLD_TIME + FADE_TIME + 0.2).timeout
	if is_inside_tree():
		queue_free()

# 마법진에서 솟구치는 mote + rune
func _spawn_rising(n: int) -> void:
	var foot: Vector2 = _foot_pos()
	for _i in range(n):
		var ang := randf() * TAU
		var r0 := 20.0 + randf() * (CIRCLE_R * 0.7)
		var sx := foot.x + cos(ang) * r0
		var sy := foot.y + sin(ang) * r0 * RING_SQUASH
		var tint_r := randf()
		var tint: String = "magenta" if tint_r < 0.3 else ("cyan" if tint_r < 0.6 else "violet")
		_particles.append({
			"pos": Vector2(sx, sy),
			"vel": Vector2(randf_range(-0.2, 0.2), -1.0 - randf() * 1.2),
			"life": 0.0,
			"max_life": 1.0 + randf() * 0.7,
			"size": 1.4 + randf() * 1.4,
			"kind": "mote",
			"tint": tint,
		})
	if randf() < 0.4 * _scale():
		_particles.append({
			"pos": Vector2(foot.x + randf_range(-CIRCLE_R * 0.6, CIRCLE_R * 0.6), foot.y - 2.0),
			"vel": Vector2(randf_range(-0.2, 0.2), -0.5 - randf() * 0.5),
			"life": 0.0,
			"max_life": 1.2 + randf() * 0.6,
			"size": 8.0 + randf() * 8.0,
			"kind": "rune",
			"rot": randf() * TAU,
			"spin": randf_range(-0.04, 0.04),
			"glyph": ["◇", "◯", "✦", "✧", "△", "▽"][randi() % 6],
		})

# peak 시 외곽 폭발 — motes + rune + 바닥 haze ring
func _spawn_peak_burst() -> void:
	var foot: Vector2 = _foot_pos()
	for _i in range(_pcount(40)):
		var a := randf() * TAU
		var sp := 2.0 + randf() * 5.0
		var tint_r := randf()
		var tint: String = "violet" if tint_r < 0.5 else ("cyan" if tint_r < 0.75 else "magenta")
		_particles.append({
			"pos": Vector2(foot.x, foot.y - 30.0),
			"vel": Vector2(cos(a) * sp, sin(a) * sp - 1.5),
			"life": 0.0,
			"max_life": 1.0 + randf() * 0.6,
			"size": 1.4 + randf() * 1.4,
			"kind": "mote",
			"tint": tint,
			"grav": 0.018,
		})
	for _i in range(_pcount(10)):
		var a := randf() * TAU
		var sp := 1.0 + randf() * 2.5
		_particles.append({
			"pos": Vector2(foot.x, foot.y - 20.0),
			"vel": Vector2(cos(a) * sp, sin(a) * sp - 1.0),
			"life": 0.0,
			"max_life": 1.2 + randf() * 0.6,
			"size": 10.0 + randf() * 8.0,
			"kind": "rune",
			"rot": randf() * TAU,
			"spin": randf_range(-0.06, 0.06),
			"glyph": ["◇", "◯", "✦", "✧", "△", "▽", "✺"][randi() % 7],
		})
	for _i in range(_pcount(16)):
		var a := randf() * TAU
		var sp := 1.5 + randf() * 2.5
		_particles.append({
			"pos": foot,
			"vel": Vector2(cos(a) * sp, sin(a) * sp * 0.2 - 0.5 - randf() * 0.5),
			"life": 0.0,
			"max_life": 1.0 + randf() * 0.6,
			"size": 16.0 + randf() * 14.0,
			"kind": "haze",
			"grav": -0.005,
		})

func _process(delta: float) -> void:
	_age += delta
	# Phase 1: channel — 마법진 등장
	# Phase 2: rising motes
	if _age > CHANNEL_TIME and _age < PEAK_DELAY + 0.2:
		_spawn_rising(_pcount(3))
	# Phase 3: peak burst (1회)
	if not _impact_emitted and _age >= PEAK_DELAY:
		_impact_emitted = true
		_spawn_peak_burst()
		screen_effect.emit()
	# Phase 4: 사라지기 전까지 약한 잔류 motes
	if _age > PEAK_DELAY and _age < PEAK_DELAY + HOLD_TIME * 0.5:
		_spawn_rising(_pcount(2))

	# 파티클 업데이트
	var alive: Array = []
	for p in _particles:
		p["life"] += delta
		if p["life"] >= p["max_life"]:
			continue
		p["pos"] += p["vel"] * delta * PSPEED
		p["vel"].y += p.get("grav", 0.0) * delta * PSPEED
		p["vel"] *= pow(0.992, delta * 60.0)
		if p.has("spin"):
			p["rot"] = p.get("rot", 0.0) + p["spin"] * delta * PSPEED
		alive.append(p)
	_particles = alive

	_ground_layer.queue_redraw()
	_glow_layer.queue_redraw()

func _global_alpha() -> float:
	# 전체 페이드: PEAK + HOLD 이후 FADE_TIME 동안 0 으로
	if _age < PEAK_DELAY + HOLD_TIME:
		return clampf(_age / 0.2, 0.0, 1.0)
	var t: float = (_age - (PEAK_DELAY + HOLD_TIME)) / FADE_TIME
	return clampf(1.0 - t, 0.0, 1.0)

# ── ground (가산 블렌드, 캐릭터 뒤) — 마법진 2개 + 바닥 haze ──
func _draw_ground_pass(canvas: CanvasItem) -> void:
	var ga: float = _global_alpha()
	if ga <= 0.0:
		return
	var foot: Vector2 = _foot_pos()
	# 외곽 마법진 (회전)
	_draw_magic_circle(canvas, foot, CIRCLE_R, _age * 0.7, ga, false)
	# 안쪽 마법진 (역회전, hexagram)
	if _age > 0.1:
		_draw_magic_circle(canvas, foot, CIRCLE_R2, -_age * 0.9, ga * 0.85, true)
	# 바닥 haze
	for p in _particles:
		if p["kind"] != "haze":
			continue
		var k: float = p["life"] / p["max_life"]
		var a: float = (1.0 - k) * 0.4 * ga
		var r: float = p["size"] * (1.0 + k * 1.3)
		canvas.draw_circle(p["pos"], r, Color(COL_HAZE, a))

# ── glow (가산 블렌드, 캐릭터 앞) — pillar + rising motes + peak shock + rune ──
func _draw_glow_pass(canvas: CanvasItem) -> void:
	var ga: float = _global_alpha()
	if ga <= 0.0:
		return
	_draw_pillar(canvas, ga)
	for p in _particles:
		if p["kind"] != "mote":
			continue
		var k: float = p["life"] / p["max_life"]
		var a: float = (1.0 - k) * ga
		var col := _mote_color(p["tint"], a)
		var pr: float = p["size"]
		canvas.draw_circle(p["pos"], pr * 1.8, Color(col.r, col.g, col.b, col.a * 0.5))
		canvas.draw_circle(p["pos"], pr, col)
	for p in _particles:
		if p["kind"] != "rune":
			continue
		var k: float = p["life"] / p["max_life"]
		var a: float = (1.0 - k) * ga
		var col := Color(COL_LIGHT, a)
		# rune = 작은 별 (4점) — text rendering 대신 단순 polygon
		var r: float = p["size"]
		var rot: float = p.get("rot", 0.0)
		var pts := PackedVector2Array()
		for i in range(8):
			var ang: float = TAU * float(i) / 8.0 + rot
			var rr: float = r if i % 2 == 0 else r * 0.45
			pts.append(p["pos"] + Vector2(cos(ang) * rr, sin(ang) * rr))
		pts.append(pts[0])
		canvas.draw_polyline(pts, col, 1.2, true)
	if _impact_emitted:
		_draw_peak_shock(canvas, ga)

func _mote_color(tint: String, a: float) -> Color:
	match tint:
		"cyan":    return Color(0.627, 0.901, 1.0, a)
		"magenta": return Color(1.0, 0.627, 0.901, a)
		_:          return Color(COL_LIGHT.r, COL_LIGHT.g, COL_LIGHT.b, a)

# 회전하는 바닥 마법진 — 외곽 원 + 별 + 4 마커
func _draw_magic_circle(canvas: CanvasItem, ctr: Vector2, radius: float, rot: float, ga: float, inner: bool) -> void:
	var grow: float = clampf(_age / CHANNEL_TIME, 0.0, 1.0)
	var alpha: float = grow * ga * 0.9
	if alpha <= 0.0:
		return
	var r: float = radius * grow
	# 외곽 원 (perspective ellipse)
	var seg := 48
	var ring_color := Color(COL_LIGHT, alpha)
	var pts := PackedVector2Array()
	for i in range(seg + 1):
		var a: float = TAU * float(i) / float(seg)
		pts.append(ctr + Vector2(cos(a) * r, sin(a) * r * RING_SQUASH))
	canvas.draw_polyline(pts, ring_color, 2.0, true)
	# 안쪽 점선원 (보조)
	var dot_color := Color(COL_VIOLET, alpha * 0.6)
	for i in range(12):
		var a0: float = TAU * float(i) / 12.0
		var a1: float = a0 + TAU / 24.0
		var dr: float = r * 0.78
		var arc := PackedVector2Array()
		for k in range(4):
			var t: float = float(k) / 3.0
			var ang: float = lerpf(a0, a1, t)
			arc.append(ctr + Vector2(cos(ang) * dr, sin(ang) * dr * RING_SQUASH))
		canvas.draw_polyline(arc, dot_color, 1.0, true)
	# 별 (pentagram 외곽 / hexagram 안쪽)
	var star_color := Color(COL_LIGHT, alpha * 0.95)
	if inner:
		# hexagram = 두 삼각형
		var hr: float = r * 0.65
		_draw_triangle(canvas, ctr, hr, rot, star_color, RING_SQUASH)
		_draw_triangle(canvas, ctr, hr, rot + PI, star_color, RING_SQUASH)
	else:
		# pentagram = 5각 별 윤곽
		var pr: float = r * 0.8
		var sp := PackedVector2Array()
		for i in range(5):
			var ang: float = -PI * 0.5 + rot + TAU * float((i * 2) % 5) / 5.0
			sp.append(ctr + Vector2(cos(ang) * pr, sin(ang) * pr * RING_SQUASH))
		sp.append(sp[0])
		canvas.draw_polyline(sp, star_color, 1.8, true)
	# 4 마커 (✦ 단순 다이아몬드)
	for i in range(4):
		var ang: float = rot + TAU * float(i) / 4.0
		var mp := ctr + Vector2(cos(ang) * r * 1.02, sin(ang) * r * 1.02 * RING_SQUASH)
		var sz: float = 4.0
		canvas.draw_colored_polygon(PackedVector2Array([
			mp + Vector2(0, -sz), mp + Vector2(sz, 0),
			mp + Vector2(0, sz), mp + Vector2(-sz, 0),
		]), Color(COL_MAGENTA, alpha * 0.95))

func _draw_triangle(canvas: CanvasItem, ctr: Vector2, r: float, rot: float, color: Color, sq: float) -> void:
	var p := PackedVector2Array()
	for i in range(3):
		var ang: float = -PI * 0.5 + rot + TAU * float(i) / 3.0
		p.append(ctr + Vector2(cos(ang) * r, sin(ang) * r * sq))
	p.append(p[0])
	canvas.draw_polyline(p, color, 1.5, true)

# 마법진에서 위로 솟는 빛 기둥 (보라 → 시안 → 마젠타 그라데이션)
func _draw_pillar(canvas: CanvasItem, ga: float) -> void:
	var rise: float = clampf((_age - CHANNEL_TIME) / 0.4, 0.0, 1.0)
	if rise <= 0.0:
		return
	# 페이드 — peak 이후 빠르게 사라짐 (1.0s)
	var fade: float = 1.0
	if _age > PEAK_DELAY:
		fade = clampf(1.0 - (_age - PEAK_DELAY) / 0.8, 0.0, 1.0)
	var alpha: float = rise * fade * ga
	if alpha <= 0.0:
		return
	var foot: Vector2 = _foot_pos()
	var h: float = PILLAR_H * rise
	var w: float = PILLAR_W
	var bottom_y: float = foot.y
	var top_y: float = foot.y - h
	# 외층 (보라)
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(foot.x - w * 0.55, bottom_y),
		Vector2(foot.x + w * 0.55, bottom_y),
		Vector2(foot.x + w * 0.20, top_y),
		Vector2(foot.x - w * 0.20, top_y),
	]), Color(COL_VIOLET, alpha * 0.7))
	# 코어 (밝은 라이트)
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(foot.x - w * 0.32, bottom_y),
		Vector2(foot.x + w * 0.32, bottom_y),
		Vector2(foot.x + w * 0.10, top_y),
		Vector2(foot.x - w * 0.10, top_y),
	]), Color(COL_LIGHT, alpha * 0.6))

# peak 시 한 번의 shockwave ring
func _draw_peak_shock(canvas: CanvasItem, ga: float) -> void:
	var t: float = (_age - PEAK_DELAY) / 0.55
	if t < 0.0 or t > 1.0:
		return
	var sc: float = lerpf(0.2, 12.0, t)
	var alpha: float
	if t < 0.25:
		alpha = t / 0.25
	else:
		alpha = 1.0 - (t - 0.25) / 0.75
	alpha *= ga
	if alpha <= 0.0:
		return
	var rad: float = 20.0 * sc
	var thick: float = lerpf(5.0, 1.0, t)
	var foot: Vector2 = _foot_pos()
	canvas.draw_arc(foot + Vector2(0, -30.0), rad, 0.0, TAU, 48, Color(COL_VIOLET, alpha), thick, true)
	canvas.draw_arc(foot + Vector2(0, -30.0), rad * 0.85, 0.0, TAU, 36, Color(COL_HOT, alpha * 0.7), thick * 0.5, true)

# ── 블렌드 분리 레이어 — meta("pass") 로 ground/glow 분기 ──
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
