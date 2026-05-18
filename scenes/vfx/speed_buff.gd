# scenes/vfx/speed_buff.gd
# 속도 버프 VFX — ui_sample/vfx/Speed Buff VFX.html 재현
# (영웅·적의 speed_bonus 부여 시. 카드 BUFF_SPEED / 적 BUFF status_type=speed_bonus / passive buff 모두 사용.)
# play(_caster, target_pos) — 첫 인자 무시, target 위치에서 발동.
# ground (캐릭터 뒤): 회전 chevron ring + 바닥 cyan dust
# glow  (캐릭터 앞): 머리 위 charge orb → peak shockwave + sparks + 가로 streak + 잔존 ambient
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


const COL_HOT  := Color(1.0, 1.0, 1.0)
const COL_ELEC := Color(0.658, 0.941, 1.0)         # #a8f0ff
const COL_MID  := Color(0.360, 0.862, 1.0)         # #5cdcff
const COL_DEEP := Color(0.117, 0.533, 0.784)       # #1e88c8
const COL_DUST := Color(0.627, 0.784, 0.941)       # 청회 dust

const CHARGE_TIME    := 0.35   # orb → peak
const IMPACT_DELAY   := CHARGE_TIME
const BUFF_TIME      := 0.7    # 잔존 ring + ambient
const FADE_TIME      := 0.3
const RING_RADIUS    := 110.0
const RING_SQUASH    := 0.32   # 바닥 perspective
const ORB_OFFSET_Y   := -80.0
const PSPEED         := 60.0

## 화면 플래시 + speed buff SFX 트리거 (peak 시점)
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
var _ground_layer: Node2D   # chevron ring + 바닥 dust
var _glow_layer: Node2D     # charge orb + sparks + streak + shockwave
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
	# 차지 orb (CHARGE_TIME)
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_charge_orb, "modulate:a", 1.0, 0.15)
	tw.parallel().tween_property(_charge_orb, "scale", Vector2(0.7, 0.7), CHARGE_TIME)
	set_process(true)
	await get_tree().create_timer(CHARGE_TIME + BUFF_TIME + FADE_TIME + 0.1).timeout
	if is_inside_tree():
		queue_free()

# peak 시 외곽 폭발 — sparks + chevron streak + 바닥 dust ring
func _spawn_peak_burst() -> void:
	var foot: Vector2 = _foot_pos()
	# sparks (외곽으로 튀는 작은 mote)
	for _i in range(_pcount(40)):
		var a := randf() * TAU
		var sp := 2.0 + randf() * 5.0
		_particles.append({
			"pos": _target,
			"vel": Vector2(cos(a) * sp, sin(a) * sp * 0.6 - 0.8),
			"life": 0.0,
			"max_life": 0.8 + randf() * 0.5,
			"size": 1.4 + randf() * 1.4,
			"kind": "spark",
			"grav": 0.02,
		})
	# chevron 가로 streak (가속감)
	for _i in range(_pcount(10)):
		var dir: float = -1.0 if randf() < 0.5 else 1.0
		var sp2 := 5.0 + randf() * 4.0
		var ang_jitter := randf_range(-0.25, 0.25)
		_particles.append({
			"pos": _target + Vector2(0.0, randf_range(-50.0, 30.0)),
			"vel": Vector2(cos(ang_jitter) * sp2 * dir, sin(ang_jitter) * sp2),
			"life": 0.0,
			"max_life": 0.5 + randf() * 0.3,
			"size": 2.0 + randf() * 1.4,
			"kind": "streak",
		})
	# 바닥 dust ring
	for _i in range(_pcount(14)):
		var a3 := randf() * TAU
		var sp3 := 1.5 + randf() * 2.5
		_particles.append({
			"pos": foot,
			"vel": Vector2(cos(a3) * sp3, sin(a3) * sp3 * 0.2 - 0.4 - randf() * 0.6),
			"life": 0.0,
			"max_life": 1.0 + randf() * 0.6,
			"size": 12.0 + randf() * 12.0,
			"kind": "dust",
			"grav": -0.005,
		})

# BUFF_TIME 동안 잔존 ambient — 발치 작은 zap + 가벼운 streak
func _spawn_ambient() -> void:
	var foot: Vector2 = _foot_pos()
	if randf() < 0.6 * _scale():
		_particles.append({
			"pos": Vector2(foot.x + randf_range(-60.0, 60.0), foot.y - randf() * 30.0),
			"vel": Vector2(randf_range(-1.4, 1.4), -0.3 - randf() * 0.5),
			"life": 0.0,
			"max_life": 0.6 + randf() * 0.4,
			"size": 1.2 + randf() * 1.2,
			"kind": "spark",
			"grav": 0.04,
		})
	if randf() < 0.3 * _scale():
		var dir: float = -1.0 if randf() < 0.5 else 1.0
		_particles.append({
			"pos": _target + Vector2(dir * 40.0 + randf_range(-15.0, 15.0), randf_range(-50.0, 30.0)),
			"vel": Vector2(dir * (2.0 + randf() * 2.0), 0.0),
			"life": 0.0,
			"max_life": 0.3 + randf() * 0.2,
			"size": 1.6 + randf() * 1.0,
			"kind": "streak",
		})

func _process(delta: float) -> void:
	_age += delta
	# peak burst (1회)
	if not _impact_emitted and _age >= CHARGE_TIME:
		_impact_emitted = true
		_spawn_peak_burst()
		screen_effect.emit()
		# orb 페이드아웃
		var tw := create_tween()
		tw.tween_property(_charge_orb, "modulate:a", 0.0, 0.12)
	# ambient — peak 후 BUFF_TIME 동안
	if _impact_emitted and _age < CHARGE_TIME + BUFF_TIME:
		_spawn_ambient()

	# 파티클 업데이트
	var alive: Array = []
	for p in _particles:
		p["life"] += delta
		if p["life"] >= p["max_life"]:
			continue
		p["pos"] += p["vel"] * delta * PSPEED
		p["vel"].y += p.get("grav", 0.0) * delta * PSPEED
		p["vel"] *= pow(0.992, delta * 60.0)
		alive.append(p)
	_particles = alive

	_ground_layer.queue_redraw()
	_glow_layer.queue_redraw()

func _global_alpha() -> float:
	if _age < CHARGE_TIME + BUFF_TIME:
		return clampf(_age / 0.15, 0.0, 1.0)
	var t: float = (_age - (CHARGE_TIME + BUFF_TIME)) / FADE_TIME
	return clampf(1.0 - t, 0.0, 1.0)

# ── ground (가산, 캐릭터 뒤) — chevron ring + 바닥 dust ──
func _draw_ground_pass(canvas: CanvasItem) -> void:
	var ga: float = _global_alpha()
	if ga <= 0.0:
		return
	_draw_chevron_ring(canvas, ga)
	for p in _particles:
		if p["kind"] != "dust":
			continue
		var k: float = p["life"] / p["max_life"]
		var a: float = (1.0 - k) * 0.4 * ga
		var r: float = p["size"] * (1.0 + k * 1.3)
		canvas.draw_circle(p["pos"], r, Color(COL_DUST, a))

# ── glow (가산, 캐릭터 앞) — sparks + streak + peak shockwave ──
func _draw_glow_pass(canvas: CanvasItem) -> void:
	var ga: float = _global_alpha()
	if ga <= 0.0:
		return
	for p in _particles:
		if p["kind"] != "spark":
			continue
		var k: float = p["life"] / p["max_life"]
		var a: float = (1.0 - k) * ga
		var col := Color(COL_ELEC.r, COL_ELEC.g, COL_ELEC.b, a)
		var pr: float = p["size"]
		canvas.draw_circle(p["pos"], pr * 1.8, Color(col.r, col.g, col.b, col.a * 0.45))
		canvas.draw_circle(p["pos"], pr, col)
		canvas.draw_rect(Rect2(p["pos"].x - pr * 2.5, p["pos"].y - 0.3, pr * 5.0, 0.6), col)
	for p in _particles:
		if p["kind"] != "streak":
			continue
		var k: float = p["life"] / p["max_life"]
		var a: float = (1.0 - k) * ga
		var sp: float = p["vel"].length()
		var ang: float = p["vel"].angle()
		var stl: float = min(sp * 1.6, 28.0)
		var dir := Vector2(cos(ang), sin(ang))
		# 메인 streak
		canvas.draw_line(p["pos"] - dir * stl, p["pos"], Color(COL_HOT, a), p["size"] * 0.7, true)
		# 후미 streak (옅음)
		canvas.draw_line(p["pos"] - dir * stl * 2.0, p["pos"] - dir * stl, Color(COL_ELEC, a * 0.5), p["size"] * 0.4, true)
	if _impact_emitted:
		_draw_sonic_shock(canvas, ga)

# 회전 chevron ring — 바닥 perspective ellipse + 가속 화살표
func _draw_chevron_ring(canvas: CanvasItem, ga: float) -> void:
	var grow: float = clampf(_age / 0.35, 0.0, 1.0)
	var fade: float = 1.0
	if _age > CHARGE_TIME + BUFF_TIME:
		fade = clampf(1.0 - (_age - CHARGE_TIME - BUFF_TIME) / FADE_TIME, 0.0, 1.0)
	if fade <= 0.0:
		return
	var alpha: float = grow * fade * ga * 0.9
	var foot: Vector2 = _foot_pos()
	var r: float = RING_RADIUS * grow
	# 외곽 원
	var seg := 48
	var ring_color := Color(COL_ELEC, alpha)
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
	# 회전 chevron — 3개 (가속 화살표), 회전 각 = _age * 1.0 rad/s
	var rot: float = _age * 1.0
	for i in range(3):
		var ang: float = rot + TAU * float(i) / 3.0
		var tip: Vector2 = foot + Vector2(cos(ang), sin(ang) * RING_SQUASH) * r * 0.55
		# 화살표 윗날개 / 아랫날개
		var perp_ang: float = ang + PI * 0.5
		var perp: Vector2 = Vector2(cos(perp_ang), sin(perp_ang) * RING_SQUASH) * r * 0.18
		var back_ang: float = ang + PI
		var back: Vector2 = tip + Vector2(cos(back_ang), sin(back_ang) * RING_SQUASH) * r * 0.22
		canvas.draw_line(back + perp, tip, Color(COL_ELEC, alpha), 2.5, true)
		canvas.draw_line(back - perp, tip, Color(COL_ELEC, alpha), 2.5, true)

# peak 시 수평 sonic shockwave (가로로 늘어남)
func _draw_sonic_shock(canvas: CanvasItem, ga: float) -> void:
	var t: float = (_age - CHARGE_TIME) / 0.45
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
	# 가로 더 길게 (scaleY 0.4)
	var rx: float = 30.0 * sc
	var ry: float = 30.0 * sc * 0.4
	var thick: float = lerpf(4.5, 1.0, t)
	# 가로 ellipse 윤곽
	var ctr := _target + Vector2(0.0, -20.0)
	var pts := PackedVector2Array()
	var seg := 48
	for i in range(seg + 1):
		var a: float = TAU * float(i) / float(seg)
		pts.append(ctr + Vector2(cos(a) * rx, sin(a) * ry))
	canvas.draw_polyline(pts, Color(COL_ELEC, alpha), thick, true)
	# 내층 옅은 윤곽
	var pts2 := PackedVector2Array()
	for i in range(seg + 1):
		var a: float = TAU * float(i) / float(seg)
		pts2.append(ctr + Vector2(cos(a) * rx * 0.85, sin(a) * ry * 0.85))
	canvas.draw_polyline(pts2, Color(COL_HOT, alpha * 0.6), thick * 0.5, true)

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
