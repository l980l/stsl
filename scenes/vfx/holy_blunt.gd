# scenes/vfx/holy_blunt.gd
# 시전자→타겟 성스러운 둔기 공격 VFX — blunt_smash 베이스 + 황금/홀리 변종.
# blunt 와 차별화: 옆으로 튀는 흙 파티클 → 깃털, 별폭발 → 십자가 폭발.
# Joan of Arc 의 orleans_charge 등 — battle_scene 이 holy_blunt damage_type 공격 시 .new() → add_child → play.
# 노드는 position (0,0)으로 add_child해야 한다 (좌표를 global로 받아 그대로 그림).
# 깃털·균열은 일반 블렌드, 스트라이크·스파크·충격파·십자가 폭발은 가산 블렌드 — 2레이어로 그린다.
extends Node2D

const COL_HOT         := Color(1, 1, 1)             # 흰 코어
const COL_FEATHER_HI  := Color(1.0, 0.980, 0.902)   # 깃털 본체 — 흰빛
const COL_FEATHER_MID := Color(1.0, 0.882, 0.612)   # 깃털 음영 — 황금 톤
const COL_FEATHER_RIB := Color(0.627, 0.486, 0.196) # 깃털 중심선 — 어두운 황금
const COL_HIT_RING    := Color(1.0, 0.816, 0.416)   # #ffd06a — 황금 충격
const COL_CRACK       := Color(0.451, 0.314, 0.118) # 어두운 황금 균열

const WINDUP_TIME := 0.35
const SLAM_TIME   := 0.25
const ARC_RADIUS  := 90.0
const ARC_OFFSET  := -30.0
const STUN_TIME   := 2.0
const DUST_SCALE  := 0.5
const PSPEED      := 60.0

signal screen_effect

var _caster := Vector2.ZERO
var _target := Vector2.ZERO
var _smoke_layer: Node2D
var _glow_layer: Node2D
var _particles: Array = []
var _cracks: Array = []
var _strike_age := -1.0
var _ring_life := -1.0
var _burst_age := -1.0
var _crater_age := -1.0
var _crack_age := -1.0

# 깃털 윤곽 — 길쭉한 잎 모양 (12점, 한쪽 끝이 살짝 뾰족). length=깃털 전체 길이.
static func feather_poly(center: Vector2, length: float, ang: float) -> PackedVector2Array:
	var fwd := Vector2(cos(ang), sin(ang))
	var side := Vector2(-fwd.y, fwd.x)
	var w := length * 0.32
	var pts := PackedVector2Array()
	for i in range(6):
		var t := float(i) / 5.0
		var x := lerpf(-length * 0.5, length * 0.5, t)
		var y_off := sin(PI * t) * w * (1.0 - t * 0.3)
		pts.append(center + fwd * x + side * y_off)
	for i in range(5, -1, -1):
		var t := float(i) / 5.0
		var x := lerpf(-length * 0.5, length * 0.5, t)
		var y_off := -sin(PI * t) * w * (1.0 - t * 0.3)
		pts.append(center + fwd * x + side * y_off)
	return pts

# 십자가 윤곽 — 12점, length=세로 길이, arm=가로팔 절반, thick=두께 절반.
static func cross_poly(center: Vector2, length: float, arm: float, thick: float, rot: float) -> PackedVector2Array:
	var fwd := Vector2(cos(rot), sin(rot))
	var side := Vector2(-fwd.y, fwd.x)
	var L := length * 0.5
	return PackedVector2Array([
		center + fwd * L - side * thick,
		center + fwd * L + side * thick,
		center + fwd * thick + side * thick,
		center + fwd * thick + side * arm,
		center - fwd * thick + side * arm,
		center - fwd * thick + side * thick,
		center - fwd * L + side * thick,
		center - fwd * L - side * thick,
		center - fwd * thick - side * thick,
		center - fwd * thick - side * arm,
		center + fwd * thick - side * arm,
		center + fwd * thick - side * thick,
	])

func _ready() -> void:
	set_process(false)
	_smoke_layer = _DrawLayer.new()
	_smoke_layer.setup(self, false)
	add_child(_smoke_layer)
	_glow_layer = _DrawLayer.new()
	_glow_layer.setup(self, true)
	add_child(_glow_layer)

func play(caster_pos: Vector2, target_pos: Vector2) -> void:
	_caster = caster_pos + Vector2(0.0, -30.0)
	_target = target_pos
	_run()

func _run() -> void:
	set_process(true)
	await get_tree().create_timer(WINDUP_TIME).timeout
	if not is_inside_tree():
		return
	_strike_age = 0.0
	await get_tree().create_timer(SLAM_TIME).timeout
	if not is_inside_tree():
		return
	_on_impact()
	await get_tree().create_timer(STUN_TIME + 1.0).timeout
	if is_inside_tree():
		queue_free()

func _mk(pos: Vector2, vel: Vector2, max_life: float, r: float, kind: String,
		grav: float, rot: float = 0.0, spin: float = 0.0) -> Dictionary:
	return {"pos": pos, "vel": vel, "life": 0.0, "max_life": max_life, "r": r,
		"kind": kind, "grav": grav, "rot": rot, "spin": spin}

func _spawn_impact_feathers() -> void:
	var gy := _target + Vector2(0.0, 80.0)
	# 큰 깃털 — 옆으로 튀는 메인 (blunt 의 chunk 대체)
	for _i in range(20):
		var a := randf() * TAU
		var sp := 3.0 + randf() * 6.0
		_particles.append(_mk(gy, Vector2(cos(a) * sp, sin(a) * sp * 0.45 - 2.5 - randf() * 2.0),
			1.4 + randf() * 0.7, 9.0 + randf() * 5.0, "feather", 0.06,
			randf() * TAU, randf_range(-0.6, 0.6)))
	# 작은 깃털 — 흩어지는 잔깃털 (blunt 의 dust 80개 대체)
	for _i in range(28):
		var a := randf() * TAU
		var sp := 2.0 + randf() * 5.0
		_particles.append(_mk(gy, Vector2(cos(a) * sp, sin(a) * sp * 0.25 - 0.8 - randf() * 1.2) * DUST_SCALE,
			1.6 + randf() * 0.7, 5.0 + randf() * 3.0, "feather_small", 0.03,
			randf() * TAU, randf_range(-0.4, 0.4)))
	# 위로 솟는 작은 깃털 기둥 (blunt 의 위쪽 dust 대체)
	for _i in range(14):
		_particles.append(_mk(gy + Vector2(randf_range(-20.0, 20.0) * DUST_SCALE, 0.0),
			Vector2(randf_range(-0.4, 0.4), -3.5 - randf() * 3.0),
			1.4 + randf() * 0.7, 5.0 + randf() * 3.0, "feather_small", 0.02,
			randf() * TAU, randf_range(-0.5, 0.5)))
	# 스파크 — 그대로 유지
	for _i in range(30):
		var a := randf() * TAU
		var sp := 2.0 + randf() * 6.0
		_particles.append(_mk(gy + Vector2(0.0, -10.0), Vector2(cos(a) * sp, sin(a) * sp - 2.0),
			0.5 + randf() * 0.5, 1.0 + randf() * 1.4, "spark", 0.15))

func _spawn_cracks() -> void:
	var gy := _target + Vector2(0.0, 80.0)
	for i in range(8):
		var ang := PI + float(i) / 8.0 * PI + randf_range(-0.1, 0.1)
		var ln: float = 60.0 + randf() * 80.0
		var x2 := gy.x + cos(ang) * ln
		var y2 := gy.y + sin(ang) * ln * 0.3
		var segs := PackedVector2Array([gy])
		for k in range(1, 7):
			var t := float(k) / 6.0
			segs.append(Vector2(
				gy.x + (x2 - gy.x) * t + randf_range(-4.0, 4.0),
				gy.y + (y2 - gy.y) * t + randf_range(-2.0, 2.0)))
		_cracks.append(segs)

func _process(delta: float) -> void:
	if _strike_age >= 0.0:
		_strike_age += delta
	if _ring_life >= 0.0:
		_ring_life += delta / 0.55
	if _burst_age >= 0.0:
		_burst_age += delta
	if _crater_age >= 0.0:
		_crater_age += delta
	if _crack_age >= 0.0:
		_crack_age += delta

	var damp: float = pow(0.992, delta * 60.0)
	var alive: Array = []
	for p in _particles:
		p["life"] += delta
		if p["life"] >= p["max_life"]:
			continue
		p["pos"] += p["vel"] * delta * PSPEED
		p["vel"].y += p["grav"] * delta * PSPEED
		p["vel"] *= damp
		if p["kind"] == "feather" or p["kind"] == "feather_small":
			p["rot"] += p["spin"] * delta * PSPEED
		alive.append(p)
	_particles = alive

	_smoke_layer.queue_redraw()
	_glow_layer.queue_redraw()

func _on_impact() -> void:
	_spawn_impact_feathers()
	_spawn_cracks()
	_ring_life = 0.0
	_burst_age = 0.0
	_crater_age = 0.0
	_crack_age = 0.0
	screen_effect.emit()

func _draw_smoke_pass(canvas: CanvasItem) -> void:
	if _crater_age >= 0.0:
		var grow: float = clampf(_crater_age / 0.35, 0.0, 1.0)
		var fade := 1.0
		if _crater_age > STUN_TIME:
			fade = clampf(1.0 - (_crater_age - STUN_TIME) / 0.6, 0.0, 1.0)
		if fade > 0.0:
			var cc := _target + Vector2(0.0, 80.0)
			var crater := PackedVector2Array()
			for i in range(28):
				var ang := TAU * float(i) / 28.0
				crater.append(cc + Vector2(cos(ang) * 100.0 * grow, sin(ang) * 14.0 * grow))
			canvas.draw_colored_polygon(crater, Color(0.0, 0.0, 0.0, 0.6 * fade))

	if _crack_age >= 0.0:
		var grow_c: float = minf(1.0, _crack_age / 1.5 * 4.0)
		var fade_c: float = maxf(0.0, 1.0 - maxf(0.0, (_crack_age / 1.5 - 0.6) / 0.4))
		if fade_c > 0.0:
			for ln in _cracks:
				var n_segs := (ln as PackedVector2Array).size()
				var cut := int(float(n_segs) * grow_c)
				if cut < 1:
					continue
				var pts := PackedVector2Array()
				for i in range(min(cut + 1, n_segs)):
					pts.append(ln[i])
				if pts.size() >= 2:
					canvas.draw_polyline(pts, Color(COL_CRACK, 0.9 * fade_c), 2.5, true)

	# 작은 깃털 — 배경(흰색 본체)
	for p in _particles:
		if p["kind"] != "feather_small":
			continue
		var k: float = p["life"] / p["max_life"]
		var a: float = (1.0 - k) * 0.85
		var len_v: float = p["r"] * 2.4
		canvas.draw_colored_polygon(
			feather_poly(p["pos"], len_v, p["rot"]),
			Color(COL_FEATHER_HI, a))

	# 큰 깃털 — 본체 + 중심선
	for p in _particles:
		if p["kind"] != "feather":
			continue
		var k: float = p["life"] / p["max_life"]
		var a: float = (1.0 - k) * 0.95
		var len_v: float = p["r"] * 2.6
		canvas.draw_colored_polygon(
			feather_poly(p["pos"], len_v, p["rot"]),
			Color(COL_FEATHER_HI, a))
		# 음영 — 한쪽 절반만 살짝 어둡게
		var fwd := Vector2(cos(p["rot"]), sin(p["rot"]))
		var side := Vector2(-fwd.y, fwd.x)
		canvas.draw_line(
			p["pos"] - fwd * (len_v * 0.45),
			p["pos"] + fwd * (len_v * 0.45),
			Color(COL_FEATHER_RIB, a * 0.7), 1.2)
		# 깃대(중심선) 약간 더 진하게 ribbon 표현
		var nudge := side * (len_v * 0.06)
		canvas.draw_line(
			p["pos"] - fwd * (len_v * 0.4) + nudge,
			p["pos"] + fwd * (len_v * 0.4) + nudge,
			Color(COL_FEATHER_MID, a * 0.5), 1.0)

func _draw_glow_pass(canvas: CanvasItem) -> void:
	if _strike_age >= 0.0 and _strike_age < SLAM_TIME:
		_draw_strike(canvas)

	# 스파크 — 황금 톤
	for p in _particles:
		if p["kind"] != "spark":
			continue
		var k: float = p["life"] / p["max_life"]
		var a: float = 1.0 - k
		var col := Color(1.0, 0.961 - 0.157 * k, 0.745 - 0.314 * k, a)
		var pr: float = p["r"]
		canvas.draw_circle(p["pos"], pr, col)
		canvas.draw_rect(Rect2(p["pos"].x - pr * 3.0, p["pos"].y - 0.3, pr * 6.0, 0.6), col)

	if _ring_life >= 0.0 and _ring_life <= 1.0:
		var sc: float = lerpf(0.2, 2.2, _ring_life)
		var oa: float
		if _ring_life < 0.25:
			oa = _ring_life / 0.25
		else:
			oa = 1.0 - (_ring_life - 0.25) / 0.75
		var rc := _target + Vector2(0.0, 30.0)
		canvas.draw_arc(rc, 60.0 * sc, 0.0, TAU, 48, Color(COL_HIT_RING, 0.95 * oa), 6.0, true)
		canvas.draw_arc(rc, 40.0 * sc, 0.0, TAU, 36, Color(COL_HOT, 0.8 * oa), 2.0, true)

	if _burst_age >= 0.0 and _burst_age < 0.55:
		_draw_burst(canvas)

func _draw_strike(canvas: CanvasItem) -> void:
	var t := _strike_age / SLAM_TIME
	var prog: float
	var oa: float
	if t < 0.35:
		prog = t / 0.35
		oa = clampf(t / 0.1, 0.0, 1.0)
	elif t < 0.7:
		prog = 1.0
		oa = 1.0
	else:
		prog = 1.0
		oa = clampf(1.0 - (t - 0.7) / 0.3, 0.0, 1.0)
	var center := _caster + Vector2(0.0, ARC_OFFSET)
	var dir_x: float = 1.0 if _target.x >= _caster.x else -1.0
	var start_ang := deg_to_rad(-180.0)
	var end_ang := deg_to_rad(30.0)
	var current_end := lerpf(start_ang, end_ang, prog)
	var n := 22
	var pts := PackedVector2Array()
	for i in range(n + 1):
		var a := lerpf(start_ang, current_end, float(i) / float(n))
		pts.append(center + Vector2(cos(a) * dir_x, sin(a)) * ARC_RADIUS)
	canvas.draw_polyline(pts, Color(COL_HIT_RING, 0.85 * oa), 10.0)
	canvas.draw_polyline(pts, Color(COL_HOT, 0.9 * oa), 4.0)

func _draw_burst(canvas: CanvasItem) -> void:
	var t := _burst_age / 0.55
	var sc: float
	var oa: float
	var rot_deg: float
	if t < 0.2:
		sc = lerpf(0.2, 1.05, t / 0.2)
		oa = t / 0.2
		rot_deg = lerpf(-20.0, 0.0, t / 0.2)
	else:
		sc = lerpf(1.05, 1.3, (t - 0.2) / 0.8)
		oa = 1.0 - (t - 0.2) / 0.8
		rot_deg = lerpf(0.0, 10.0, (t - 0.2) / 0.8)
	var rot := deg_to_rad(rot_deg)
	var bc := _target + Vector2(0.0, -10.0)
	# 외곽 큰 십자가 — 황금
	canvas.draw_colored_polygon(
		cross_poly(bc, 150.0 * sc, 50.0 * sc, 16.0 * sc, rot),
		Color(COL_FEATHER_HI, 0.85 * oa))
	# 안쪽 작은 십자가 — 흰 (살짝 회전 어긋남)
	canvas.draw_colored_polygon(
		cross_poly(bc, 100.0 * sc, 32.0 * sc, 9.0 * sc, rot + deg_to_rad(8.0)),
		Color(COL_HOT, 0.9 * oa))
	# 중심 흰 원
	canvas.draw_circle(bc, 14.0 * sc, Color(COL_HOT, oa))

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
