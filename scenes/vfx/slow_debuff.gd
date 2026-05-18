# scenes/vfx/slow_debuff.gd
# 속도 감소 VFX — ui_sample/vfx/Slow Debuff VFX.html 재현 (speed_penalty 부여 시).
# play(_caster, target_pos) — 첫 인자 무시, target 위치에서 발동.
# ground (캐릭터 뒤): 보라 goop puddle + 역방향 chevron ring + 바닥 mist
# glow  (캐릭터 앞): 머리 위 charge orb → spiral motes (외곽→타겟 수렴) + 잔존 drip/bubble
extends Node2D

# 파티클 갯수 — GameSettings.particle_count_scale 적용
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


const COL_HOT  := Color(0.784, 0.705, 1.0)         # #c8b4ff 보라 라이트
const COL_MID  := Color(0.478, 0.360, 0.784)       # #7a5cc8 중간 보라
const COL_DEEP := Color(0.227, 0.117, 0.415)       # #3a1e6a 어두운 보라
const COL_GOOP := Color(0.368, 0.266, 0.501)       # #5e4480 점액

const CHARGE_TIME    := 0.4    # orb → peak
const IMPACT_DELAY   := CHARGE_TIME
const DEBUFF_TIME    := 0.8    # 잔존 ring + drip
const FADE_TIME      := 0.35
const RING_RADIUS    := 110.0
const RING_SQUASH    := 0.32
const GOOP_W         := 200.0
const GOOP_H         := 40.0
const ORB_OFFSET_Y   := -80.0
const PSPEED         := 60.0

## 화면 플래시 (어두운 보라) + SFX 트리거 (peak 시점)
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
var _ground_layer: Node2D   # goop + chevron ring + mist (캐릭터 뒤)
var _glow_layer: Node2D     # charge orb + spiral + drip + bubble (캐릭터 앞)
var _charge_orb: Sprite2D

static func _make_orb_tex(c_core: Color, c_mid: Color, c_edge: Color) -> GradientTexture2D:
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.42, 0.72, 1.0])
	grad.colors = PackedColorArray([c_core, c_mid, c_edge, Color(c_edge.r, c_edge.g, c_edge.b, 0.0)])
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 128
	tex.height = 128
	return tex

func _ready() -> void:
	set_process(false)
	_ground_layer = _DrawLayer.new()
	_ground_layer.setup(self, true)
	add_child(_ground_layer)
	_ground_layer.set_meta("pass", "ground")
	_charge_orb = Sprite2D.new()
	_charge_orb.texture = _make_orb_tex(COL_HOT, COL_MID, COL_DEEP)
	_charge_orb.modulate = Color(1, 1, 1, 0.0)
	_charge_orb.scale = Vector2(0.15, 0.15)
	add_child(_charge_orb)
	_glow_layer = _DrawLayer.new()
	_glow_layer.setup(self, true)
	add_child(_glow_layer)
	_glow_layer.set_meta("pass", "glow")

func play(_caster_pos: Vector2, target_pos: Vector2) -> void:
	_target = target_pos
	_charge_orb.position = target_pos + Vector2(0.0, ORB_OFFSET_Y)
	_age = 0.0
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_charge_orb, "modulate:a", 1.0, 0.18)
	tw.parallel().tween_property(_charge_orb, "scale", Vector2(0.7, 0.7), CHARGE_TIME)
	set_process(true)
	await get_tree().create_timer(CHARGE_TIME + DEBUFF_TIME + FADE_TIME + 0.1).timeout
	if is_inside_tree():
		queue_free()

# peak 시 — 외곽에서 타겟으로 수렴하는 spiral motes + 바닥 mist
func _spawn_peak_burst() -> void:
	var foot: Vector2 = _foot_pos()
	# spiral motes (외곽 → 타겟, 나선 수렴)
	for _i in range(_pcount(20)):
		var ang := randf() * TAU
		var dist := 110.0 + randf() * 50.0
		var sx := _target.x + cos(ang) * dist
		var sy := _target.y + sin(ang) * dist * 0.4 - 30.0
		_particles.append({
			"pos": Vector2(sx, sy),
			"vel": Vector2.ZERO,  # spiral 은 _process 에서 위치 계산
			"life": 0.0,
			"max_life": 0.8 + randf() * 0.4,
			"size": 1.4 + randf() * 1.2,
			"kind": "spiral",
			"start_ang": ang,
			"start_dist": dist,
		})
	# 바닥 mist (보라 안개)
	for _i in range(_pcount(14)):
		var a2 := randf() * TAU
		var sp := 1.0 + randf() * 2.0
		_particles.append({
			"pos": foot,
			"vel": Vector2(cos(a2) * sp, sin(a2) * sp * 0.2 - 0.3 - randf() * 0.4),
			"life": 0.0,
			"max_life": 1.0 + randf() * 0.5,
			"size": 12.0 + randf() * 12.0,
			"kind": "mist",
			"grav": -0.005,
		})

# 잔존 동안 — 발치 drip + bubble + mist
func _spawn_ambient() -> void:
	var foot: Vector2 = _foot_pos()
	if randf() < 0.35 * _scale():
		_particles.append({
			"pos": Vector2(foot.x + randf_range(-70.0, 70.0), foot.y - 18.0 + randf_range(-8.0, 8.0)),
			"vel": Vector2(randf_range(-0.2, 0.2), 0.4 + randf() * 0.4),
			"life": 0.0,
			"max_life": 0.8 + randf() * 0.4,
			"size": 2.4 + randf() * 1.4,
			"kind": "drip",
			"grav": 0.03,
		})
	if randf() < 0.5 * _scale():
		_particles.append({
			"pos": Vector2(foot.x + randf_range(-80.0, 80.0), foot.y - 2.0),
			"vel": Vector2(randf_range(-0.2, 0.2), -0.2 - randf() * 0.3),
			"life": 0.0,
			"max_life": 1.4 + randf() * 0.6,
			"size": 12.0 + randf() * 10.0,
			"kind": "mist",
			"grav": -0.003,
		})
	if randf() < 0.2 * _scale():
		_particles.append({
			"pos": Vector2(foot.x + randf_range(-60.0, 60.0), foot.y - 2.0),
			"vel": Vector2(randf_range(-0.1, 0.1), -0.3 - randf() * 0.2),
			"life": 0.0,
			"max_life": 0.5 + randf() * 0.3,
			"size": 3.0 + randf() * 2.0,
			"kind": "bubble",
		})

func _process(delta: float) -> void:
	_age += delta
	if not _impact_emitted and _age >= CHARGE_TIME:
		_impact_emitted = true
		_spawn_peak_burst()
		screen_effect.emit()
		var tw := create_tween()
		tw.tween_property(_charge_orb, "modulate:a", 0.0, 0.15)
	if _impact_emitted and _age < CHARGE_TIME + DEBUFF_TIME:
		_spawn_ambient()

	var alive: Array = []
	for p in _particles:
		p["life"] += delta
		if p["life"] >= p["max_life"]:
			continue
		if p["kind"] == "spiral":
			# 나선 수렴 — start_ang + t*1.5pi, dist = start_dist * (1-t)
			var t: float = p["life"] / p["max_life"]
			var ang: float = p["start_ang"] + t * PI * 1.5
			var dist: float = p["start_dist"] * (1.0 - t)
			p["pos"] = _target + Vector2(cos(ang) * dist, sin(ang) * dist * 0.4 - 20.0)
		else:
			p["pos"] += p["vel"] * delta * PSPEED
			p["vel"].y += p.get("grav", 0.0) * delta * PSPEED
			p["vel"] *= pow(0.992, delta * 60.0)
		alive.append(p)
	_particles = alive

	_ground_layer.queue_redraw()
	_glow_layer.queue_redraw()

func _global_alpha() -> float:
	if _age < CHARGE_TIME + DEBUFF_TIME:
		return clampf(_age / 0.15, 0.0, 1.0)
	var t: float = (_age - (CHARGE_TIME + DEBUFF_TIME)) / FADE_TIME
	return clampf(1.0 - t, 0.0, 1.0)

# ── ground (가산, 캐릭터 뒤) — goop puddle + 역chevron ring + mist ──
func _draw_ground_pass(canvas: CanvasItem) -> void:
	var ga: float = _global_alpha()
	if ga <= 0.0:
		return
	_draw_goop(canvas, ga)
	_draw_chevron_ring(canvas, ga)
	for p in _particles:
		if p["kind"] != "mist":
			continue
		var k: float = p["life"] / p["max_life"]
		var a: float = (1.0 - k) * 0.4 * ga
		var r: float = p["size"] * (1.0 + k * 1.3)
		canvas.draw_circle(p["pos"], r, Color(COL_MID, a))

# ── glow (가산, 캐릭터 앞) — spiral motes + drip + bubble ──
func _draw_glow_pass(canvas: CanvasItem) -> void:
	var ga: float = _global_alpha()
	if ga <= 0.0:
		return
	for p in _particles:
		if p["kind"] != "spiral":
			continue
		var k: float = p["life"] / p["max_life"]
		var a: float = (1.0 - k) * ga
		var col := Color(COL_HOT.r, COL_HOT.g, COL_HOT.b, a)
		var pr: float = p["size"]
		canvas.draw_circle(p["pos"], pr * 1.6, Color(col.r, col.g, col.b, col.a * 0.45))
		canvas.draw_circle(p["pos"], pr, col)
		canvas.draw_rect(Rect2(p["pos"].x - pr * 2.5, p["pos"].y - 0.3, pr * 5.0, 0.6), col)
	for p in _particles:
		if p["kind"] != "drip":
			continue
		var k: float = p["life"] / p["max_life"]
		var a: float = (1.0 - k) * ga
		# 보라 방울 — 세로로 늘어난 ellipse
		var pts := PackedVector2Array()
		var seg := 14
		for i in range(seg + 1):
			var ag: float = TAU * float(i) / float(seg)
			pts.append(p["pos"] + Vector2(cos(ag) * p["size"] * 0.65, sin(ag) * p["size"] * 1.4))
		canvas.draw_colored_polygon(pts, Color(COL_MID, 0.92 * a))
	for p in _particles:
		if p["kind"] != "bubble":
			continue
		var k: float = p["life"] / p["max_life"]
		var a: float = (1.0 - k) * ga
		canvas.draw_circle(p["pos"], p["size"], Color(COL_MID, 0.3 * a))
		canvas.draw_arc(p["pos"], p["size"], 0.0, TAU, 16, Color(COL_HOT, 0.65 * a), 1.0, true)

# 발치 보라 goop puddle (납작한 ellipse)
func _draw_goop(canvas: CanvasItem, ga: float) -> void:
	var grow: float = clampf(_age / 0.5, 0.0, 1.0)
	var fade: float = 1.0
	if _age > CHARGE_TIME + DEBUFF_TIME:
		fade = clampf(1.0 - (_age - CHARGE_TIME - DEBUFF_TIME) / FADE_TIME, 0.0, 1.0)
	if fade <= 0.0:
		return
	var alpha: float = grow * fade * ga * 0.85
	var foot: Vector2 = _foot_pos()
	var pts := PackedVector2Array()
	var seg := 32
	var w: float = GOOP_W * 0.5 * grow
	var h: float = GOOP_H * 0.5 * grow
	for i in range(seg + 1):
		var a: float = TAU * float(i) / float(seg)
		pts.append(foot + Vector2(cos(a) * w, sin(a) * h))
	# bubble 효과 — 시간에 따라 약간 변형
	canvas.draw_colored_polygon(pts, Color(COL_GOOP, alpha))
	# 내층 (어두운)
	var pts2 := PackedVector2Array()
	for i in range(seg + 1):
		var a: float = TAU * float(i) / float(seg)
		pts2.append(foot + Vector2(cos(a) * w * 0.65, sin(a) * h * 0.65))
	canvas.draw_colored_polygon(pts2, Color(COL_DEEP, alpha * 0.7))

# 역방향 chevron ring — 외곽 원 + 안쪽 점선 원 + 3개 역방향 화살표 (감속)
func _draw_chevron_ring(canvas: CanvasItem, ga: float) -> void:
	var grow: float = clampf((_age - 0.1) / 0.4, 0.0, 1.0)
	if grow <= 0.0:
		return
	var fade: float = 1.0
	if _age > CHARGE_TIME + DEBUFF_TIME:
		fade = clampf(1.0 - (_age - CHARGE_TIME - DEBUFF_TIME) / FADE_TIME, 0.0, 1.0)
	if fade <= 0.0:
		return
	var alpha: float = grow * fade * ga * 0.85
	var foot: Vector2 = _foot_pos()
	var r: float = RING_RADIUS * grow
	# 외곽 원
	var seg := 48
	var ring_color := Color(COL_HOT, alpha)
	var pts := PackedVector2Array()
	for i in range(seg + 1):
		var a: float = TAU * float(i) / float(seg)
		pts.append(foot + Vector2(cos(a) * r, sin(a) * r * RING_SQUASH))
	canvas.draw_polyline(pts, ring_color, 2.0, true)
	# 안쪽 점선 원
	for i in range(12):
		var a0: float = TAU * float(i) / 12.0
		var a1: float = a0 + TAU / 24.0
		var dr: float = r * 0.78
		var arc := PackedVector2Array()
		for k in range(4):
			var t: float = float(k) / 3.0
			var ang2: float = lerpf(a0, a1, t)
			arc.append(foot + Vector2(cos(ang2) * dr, sin(ang2) * dr * RING_SQUASH))
		canvas.draw_polyline(arc, Color(COL_MID, alpha * 0.55), 1.0, true)
	# 역방향 chevron — 감속 표시 (방향 뒤집기), 회전 -0.5 rad/s
	var rot: float = -_age * 0.5
	for i in range(3):
		var ang: float = rot + TAU * float(i) / 3.0
		var tip: Vector2 = foot + Vector2(cos(ang), sin(ang) * RING_SQUASH) * r * 0.55
		var perp_ang: float = ang + PI * 0.5
		var perp: Vector2 = Vector2(cos(perp_ang), sin(perp_ang) * RING_SQUASH) * r * 0.18
		# 화살표 방향 반대 (앞으로가 아니라 뒤로) — tip 에서 외곽 방향
		var fwd: Vector2 = Vector2(cos(ang), sin(ang) * RING_SQUASH) * r * 0.22
		canvas.draw_line(tip + fwd + perp, tip, Color(COL_HOT, alpha), 2.5, true)
		canvas.draw_line(tip + fwd - perp, tip, Color(COL_HOT, alpha), 2.5, true)

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
