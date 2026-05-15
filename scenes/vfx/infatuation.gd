# scenes/vfx/infatuation.gd
# 반함(enthrall) VFX — ui_sample/vfx/Infatuation VFX.html 재현 (스탯·캐릭터 노드 효과 제외).
# 매혹 임계치 도달로 enthrall 발동 시 .new() → add_child → play(caster_pos, target_pos).
# charm_kiss 보다 화려: fan 5개 하트 투사체 + 임팩트 버스트 + 만다라/체인/오라 BUFF_TIME.
# smoke/petal 은 일반 블렌드, heart/sparkle/만다라/체인/오라/shockwave 는 가산 블렌드.
extends Node2D

# 파티클 갯수 — GameSettings.particle_count_scale 적용 (하/중/상 = 0.25/0.5/1.0배)
func _pcount(n: int) -> int:
	var gs := get_node_or_null("/root/GameSettings")
	return n if gs == null else maxi(1, int(round(n * gs.particle_count_scale())))

const COL_HOT     := Color(1.0, 0.945, 0.910)  # 흰 따뜻한 톤
const COL_RED     := Color(1.0, 0.296, 0.376)  # #ff4b60 — 다이나믹 빨강
const COL_CRIMSON := Color(0.784, 0.094, 0.176) # #c8182d — 진홍
const COL_DARK    := Color(0.490, 0.027, 0.094) # 어두운 핏빛
const COL_PETAL   := Color(1.0, 0.475, 0.514)  # 핑크빨강 꽃잎

const ORB_OFFSET_Y    := -50.0  # 시전자 가슴 위
const ORB_CHARGE_FULL := 0.40
const CHARGE_TIME     := 0.55  # 차지(s)
const FLIGHT_TIME     := 0.55  # 하트 투사체 비행(s)
const IMPACT_DELAY    := CHARGE_TIME + FLIGHT_TIME  # battle_manager 동기화용 (큰 키스 명중)
const BUFF_TIME       := 3.0   # 반함 지속 — 만다라/체인/오라 표시(s)
const FAN_COUNT       := 4     # fan 하트 갯수 (큰 키스 1개 추가, 총 5개)
const RING_SQUASH     := 0.34
const PSPEED          := 60.0

## 화면 플래시 + 반함 SFX 트리거
signal screen_effect

var _caster := Vector2.ZERO
var _target := Vector2.ZERO
var _smoke_layer: Node2D
var _glow_layer: Node2D
var _charge_orb: Sprite2D
var _hearts: Array = []         # 비행 중인 하트 투사체
var _particles: Array = []
var _heart_pts: PackedVector2Array  # 하트 윤곽 캐시
var _impacted := false
var _mandala_age := -1.0
var _chains_age := -1.0
var _aura_age := -1.0
var _shock_age := -1.0
var _buff_timer := 0.0
var _spin_acc := 0.0  # 만다라/체인 회전 누적

# 하트 윤곽 (autoload 비의존 static — 단위 테스트 가능)
# 4개 큐빅 베지어 × 4점 샘플 = 16점. 좌표는 단위 스케일 기준 (+y=아래).
static func heart_shape() -> PackedVector2Array:
	var beziers := [
		[Vector2(0, 0.375), Vector2(-0.4375, 0.125), Vector2(-0.5625, -0.1875), Vector2(-0.375, -0.375)],
		[Vector2(-0.375, -0.375), Vector2(-0.1875, -0.5625), Vector2(0, -0.4375), Vector2(0, -0.25)],
		[Vector2(0, -0.25), Vector2(0, -0.4375), Vector2(0.1875, -0.5625), Vector2(0.375, -0.375)],
		[Vector2(0.375, -0.375), Vector2(0.5625, -0.1875), Vector2(0.4375, 0.125), Vector2(0, 0.375)],
	]
	var pts := PackedVector2Array()
	for bz in beziers:
		var a: Vector2 = bz[0]
		var c1: Vector2 = bz[1]
		var c2: Vector2 = bz[2]
		var d: Vector2 = bz[3]
		for i in range(4):
			var t := float(i) / 4.0
			var u := 1.0 - t
			pts.append(u*u*u*a + 3.0*u*u*t*c1 + 3.0*u*t*t*c2 + t*t*t*d)
	return pts

static func _make_orb_tex() -> GradientTexture2D:
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.42, 0.72, 1.0])
	grad.colors = PackedColorArray([
		Color(1, 1, 1, 1.0),
		Color(1.0, 0.471, 0.510, 0.95),  # 진한 핑크빨강
		Color(0.490, 0.027, 0.094, 0.85),
		Color(0.490, 0.027, 0.094, 0.0),
	])
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 256
	tex.height = 256
	return tex

func _ready() -> void:
	set_process(false)
	_heart_pts = heart_shape()
	_smoke_layer = _DrawLayer.new()
	_smoke_layer.setup(self, false)
	add_child(_smoke_layer)
	_charge_orb = Sprite2D.new()
	_charge_orb.texture = _make_orb_tex()
	_charge_orb.modulate = Color(1, 1, 1, 0.0)
	_charge_orb.scale = Vector2(0.10, 0.10)
	add_child(_charge_orb)
	_glow_layer = _DrawLayer.new()
	_glow_layer.setup(self, true)
	add_child(_glow_layer)

func play(caster_pos: Vector2, target_pos: Vector2) -> void:
	_caster = caster_pos
	_target = target_pos
	_charge_orb.position = caster_pos + Vector2(0.0, ORB_OFFSET_Y)
	_run()

func _run() -> void:
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_charge_orb, "modulate:a", 1.0, 0.18)
	tw.parallel().tween_property(_charge_orb, "scale", Vector2(ORB_CHARGE_FULL, ORB_CHARGE_FULL), CHARGE_TIME)
	set_process(true)
	await get_tree().create_timer(CHARGE_TIME).timeout
	if not is_inside_tree():
		return
	var tw2 := create_tween()
	tw2.tween_property(_charge_orb, "modulate:a", 0.0, 0.15)
	_fire_hearts()
	# 큰 키스 명중 후 BUFF_TIME 동안 표시 + 0.8s 페이드
	await get_tree().create_timer(FLIGHT_TIME + BUFF_TIME + 1.0).timeout
	if is_inside_tree():
		queue_free()

func _fire_hearts() -> void:
	var spread_y := [-30.0, -15.0, 15.0, 30.0]
	var delays := [0.0, 0.06, 0.04, 0.10]
	var src := _charge_orb.position
	for i in range(FAN_COUNT):
		_hearts.append({
			"src": src + Vector2(0.0, spread_y[i] * 0.4),
			"dst": _target + Vector2(0.0, spread_y[i]),
			"delay": delays[i], "age": 0.0, "dur": FLIGHT_TIME,
			"size": 18.0 + randf() * 4.0,
			"big": false, "tint": "crimson" if i % 2 == 1 else "rose",
			"sway": randf() * TAU,
			"pos": src,
		})
	# 큰 중심 하트 — "키스"
	_hearts.append({
		"src": src + Vector2(0.0, -4.0),
		"dst": _target + Vector2(0.0, -8.0),
		"delay": 0.12, "age": 0.0, "dur": FLIGHT_TIME + 0.04,
		"size": 30.0,
		"big": true, "tint": "rose",
		"sway": 0.0,
		"pos": src,
	})

func _process(delta: float) -> void:
	if _mandala_age >= 0.0: _mandala_age += delta
	if _chains_age >= 0.0: _chains_age += delta
	if _aura_age >= 0.0: _aura_age += delta
	if _shock_age >= 0.0: _shock_age += delta
	_spin_acc += delta

	# 하트 투사체 진행 — 포물선 + sway
	var live: Array = []
	for h in _hearts:
		if h["delay"] > 0.0:
			h["delay"] -= delta
			if h["delay"] > 0.0:
				live.append(h)
				continue
		h["age"] += delta
		var t: float = clampf(h["age"] / h["dur"], 0.0, 1.0)
		var x: float = lerpf(h["src"].x, h["dst"].x, t)
		var base_y: float = lerpf(h["src"].y, h["dst"].y, t)
		var arc_h: float = 40.0 if h["big"] else 55.0
		var arc: float = -sin(t * PI) * arc_h
		var wobble: float = sin((t + h["sway"]) * PI * 3.0) * 18.0 * sin(t * PI)
		h["pos"] = Vector2(x, base_y + arc + wobble)
		_spawn_trail(h["pos"], h["tint"])
		if t < 1.0:
			live.append(h)
		elif h["big"] and not _impacted:
			_impacted = true
			_on_impact()
	_hearts = live

	if _buff_timer > 0.0:
		_buff_timer -= delta
		_spawn_ambient()

	var damp: float = pow(0.992, delta * 60.0)
	var alive: Array = []
	for p in _particles:
		p["life"] += delta
		if p["life"] >= p["max_life"]:
			continue
		p["pos"] += p["vel"] * delta * PSPEED
		p["vel"].y += p["grav"] * delta * PSPEED
		p["vel"] *= damp
		if p["kind"] == "petal":
			p["rot"] += p["spin"] * delta * PSPEED
		alive.append(p)
	_particles = alive

	_smoke_layer.queue_redraw()
	_glow_layer.queue_redraw()

func _on_impact() -> void:
	_spawn_impact_burst()
	_mandala_age = 0.0
	_chains_age = 0.0
	_aura_age = 0.0
	_shock_age = 0.0
	_buff_timer = BUFF_TIME
	screen_effect.emit()

func _mk(pos: Vector2, vel: Vector2, max_life: float, r: float, kind: String,
		grav: float = 0.0, rot: float = 0.0, spin: float = 0.0, tint: String = "rose") -> Dictionary:
	return {"pos": pos, "vel": vel, "life": 0.0, "max_life": max_life, "r": r,
		"kind": kind, "grav": grav, "rot": rot, "spin": spin, "tint": tint}

func _spawn_trail(pos: Vector2, tint: String) -> void:
	_particles.append(_mk(pos + Vector2(randf_range(-4, 4), randf_range(-4, 4)),
		Vector2(randf_range(-0.4, 0.4), -0.3 - randf() * 0.5),
		0.7 + randf() * 0.5, 5.0 + randf() * 4.0, "heart_small", 0.0, 0.0, 0.0, tint))
	if randf() < 0.4:
		_particles.append(_mk(pos, Vector2(randf_range(-1, 1), randf_range(-1, 1) - 0.2),
			0.6 + randf() * 0.5, 1.2 + randf() * 1.0, "sparkle", 0.0, 0.0, 0.0, tint))

func _spawn_ambient() -> void:
	var ctr := _target + Vector2(0.0, -30.0)
	if randf() < 0.5:
		var tint := "crimson" if randf() < 0.4 else "rose"
		_particles.append(_mk(ctr + Vector2(randf_range(-50, 50), randf_range(-10, 30)),
			Vector2(randf_range(-0.3, 0.3), -0.5 - randf() * 0.7),
			1.4 + randf(), 6.0 + randf() * 5.0, "heart_small", 0.0, 0.0, 0.0, tint))
	if randf() < 0.3:
		var tint2 := "crimson" if randf() < 0.5 else "rose"
		_particles.append(_mk(ctr + Vector2(randf_range(-55, 55), randf_range(-20, 20)),
			Vector2(randf_range(-0.4, 0.4), -0.3 - randf() * 0.5),
			1.2 + randf(), 1.0 + randf(), "sparkle", 0.0, 0.0, 0.0, tint2))

func _spawn_impact_burst() -> void:
	var b := _target + Vector2(0.0, -40.0)
	# 임팩트 하트 26개 — 더 크고 빠르게
	for _i in range(_pcount(26)):
		var a := randf() * TAU
		var sp := 2.5 + randf() * 6.5  # 더 빠르게
		var tint := "crimson" if randf() < 0.45 else "rose"
		_particles.append(_mk(b, Vector2(cos(a) * sp, sin(a) * sp * 0.85 - 1.5),
			1.4 + randf() * 0.8, 14.0 + randf() * 16.0, "heart_small", -0.012,
			randf_range(-0.6, 0.6), 0.0, tint))
	# 꽃잎 40개 — 더 화려하게
	for _i in range(_pcount(40)):
		var a := randf() * TAU
		var sp := 1.5 + randf() * 4.0  # 속도 ↑
		_particles.append(_mk(b, Vector2(cos(a) * sp, sin(a) * sp * 0.7 - 0.8),
			1.6 + randf(), 6.0 + randf() * 7.0, "petal", 0.02,
			randf_range(-0.4, 0.4), randf_range(-0.08, 0.08)))
	# 별가루 60개 — 더 풍성하게
	for _i in range(_pcount(60)):
		var a := randf() * TAU
		var sp := 1.5 + randf() * 6.0
		var tint := "crimson" if randf() < 0.5 else "rose"
		_particles.append(_mk(b, Vector2(cos(a) * sp, sin(a) * sp - 0.5),
			1.0 + randf() * 0.7, 1.0 + randf() * 1.4, "sparkle", 0.01,
			0.0, 0.0, tint))
	# 빨강 smoke 22개
	for _i in range(_pcount(22)):
		var a := randf() * TAU
		var sp := 0.8 + randf() * 1.8
		_particles.append(_mk(b, Vector2(cos(a) * sp, sin(a) * sp * 0.6 - 0.4),
			1.4 + randf() * 0.9, 24.0 + randf() * 22.0, "smoke", -0.005))

# ── 일반 블렌드 — smoke, petal ──
func _draw_smoke_pass(canvas: CanvasItem) -> void:
	for p in _particles:
		if p["kind"] != "smoke":
			continue
		var k: float = p["life"] / p["max_life"]
		var a: float = (1.0 - k) * 0.35
		var r: float = p["r"] * (1.0 + k * 1.4)
		canvas.draw_circle(p["pos"], r, Color(1.0, 0.420, 0.500, a))  # 핏빛 연기
	for p in _particles:
		if p["kind"] != "petal":
			continue
		var k: float = p["life"] / p["max_life"]
		var a: float = 1.0 - k
		var poly := PackedVector2Array()
		var pr: float = p["r"]
		for i in range(12):
			var ang: float = TAU * float(i) / 12.0
			poly.append(p["pos"] + (Vector2(cos(ang) * 0.55, sin(ang)) * pr).rotated(p["rot"]))
		canvas.draw_colored_polygon(poly, Color(COL_PETAL, 0.92 * a))

# ── 가산 블렌드 — heart, sparkle, 만다라, 체인, 오라, shockwave ──
func _draw_glow_pass(canvas: CanvasItem) -> void:
	if _aura_age >= 0.0:
		_draw_aura(canvas)
	if _mandala_age >= 0.0:
		_draw_mandala(canvas)
	if _chains_age >= 0.0:
		_draw_chains(canvas)
	if _shock_age >= 0.0:
		_draw_shock(canvas)

	# 작은 하트 파티클
	for p in _particles:
		if p["kind"] != "heart_small":
			continue
		var k: float = p["life"] / p["max_life"]
		var a: float = 1.0 - k
		var col: Color = COL_CRIMSON if p["tint"] == "crimson" else COL_RED
		var poly := PackedVector2Array()
		for v in _heart_pts:
			poly.append(p["pos"] + v * p["r"])
		canvas.draw_colored_polygon(poly, Color(col, a))

	# sparkle
	for p in _particles:
		if p["kind"] != "sparkle":
			continue
		var k: float = p["life"] / p["max_life"]
		var a: float = 1.0 - k
		var col: Color
		if p["tint"] == "crimson":
			col = Color(1.0, 0.620, 0.620, a)
		else:
			col = Color(1.0, 0.835, 0.835, a)
		var pr: float = p["r"]
		canvas.draw_circle(p["pos"], pr, col)
		canvas.draw_rect(Rect2(p["pos"].x - pr * 2.5, p["pos"].y - 0.3, pr * 5.0, 0.6), col)
		canvas.draw_rect(Rect2(p["pos"].x - 0.3, p["pos"].y - pr * 2.5, 0.6, pr * 5.0), col)

	# 비행 중인 하트 투사체 (위에)
	for h in _hearts:
		if h["delay"] > 0.0:
			continue
		var pos: Vector2 = h["pos"]
		var size: float = h["size"]
		var col: Color = COL_CRIMSON if h["tint"] == "crimson" else COL_RED
		# halo
		canvas.draw_circle(pos, size * 1.4, Color(col.r, col.g, col.b, 0.3))
		canvas.draw_circle(pos, size * 0.7, Color(col.r, col.g, col.b, 0.5))
		# 하트 본체
		var poly := PackedVector2Array()
		for v in _heart_pts:
			poly.append(pos + v * size)
		canvas.draw_colored_polygon(poly, col)

# 발 아래 핑크/보라 오라 — 1.4s 펄스
func _draw_aura(canvas: CanvasItem) -> void:
	var grow: float = clampf(_aura_age / 0.4, 0.0, 1.0)
	var fade := 1.0
	if _aura_age > BUFF_TIME:
		fade = clampf(1.0 - (_aura_age - BUFF_TIME) / 0.5, 0.0, 1.0)
	if fade <= 0.0:
		return
	var pulse: float = 0.7 + sin(_aura_age * (TAU / 1.4)) * 0.15
	var alpha: float = grow * fade * pulse
	var rc := _target + Vector2(0.0, 60.0)
	canvas.draw_arc(rc, 80.0 * grow, 0.0, TAU, 48,
		Color(COL_RED, 0.5 * alpha), 14.0 * grow, true)
	canvas.draw_arc(rc, 60.0 * grow, 0.0, TAU, 36,
		Color(COL_CRIMSON, 0.4 * alpha), 10.0 * grow, true)

# 만다라 — target 머리 뒤 회전 (6s/회전, 흰원+점선원+8개 하트+중앙 하트)
func _draw_mandala(canvas: CanvasItem) -> void:
	var grow: float = clampf(_mandala_age / 0.5, 0.0, 1.0)
	var fade := 1.0
	if _mandala_age > BUFF_TIME:
		fade = clampf(1.0 - (_mandala_age - BUFF_TIME) / 0.5, 0.0, 1.0)
	if fade <= 0.0:
		return
	var sc: float = lerpf(0.3, 1.0, grow)
	var a: float = grow * fade
	var rc := _target + Vector2(0.0, -60.0)
	var rot: float = _spin_acc * (TAU / 6.0)
	# 외곽 원
	canvas.draw_arc(rc, 56.0 * sc, 0.0, TAU, 48, Color(COL_HOT, 0.7 * a), 1.5, true)
	# 점선 원
	var dr: float = 38.0 * sc
	for i in range(12):
		var a0: float = TAU * float(i) / 12.0 + rot
		var a1: float = a0 + TAU / 24.0
		var pts := PackedVector2Array()
		for k in range(4):
			var t: float = float(k) / 3.0
			var ang: float = lerpf(a0, a1, t)
			pts.append(rc + Vector2(cos(ang) * dr, sin(ang) * dr))
		canvas.draw_polyline(pts, Color(COL_HOT, a * 0.7), 1.0)
	# 8개 작은 하트 (외곽)
	for i in range(8):
		var ang: float = TAU * float(i) / 8.0 + rot
		var hpos := rc + Vector2(cos(ang) * 60.0 * sc, sin(ang) * 60.0 * sc)
		var poly := PackedVector2Array()
		for v in _heart_pts:
			poly.append(hpos + v * 8.0 * sc)
		canvas.draw_colored_polygon(poly, Color(COL_RED, 0.85 * a))
	# 중앙 큰 하트
	var poly := PackedVector2Array()
	for v in _heart_pts:
		poly.append(rc + v * 14.0 * sc)
	canvas.draw_colored_polygon(poly, Color(COL_HOT, a * 0.95))

# 체인 — target 허리 회전 (5s/회전, 점선 외곽 원+8개 하트, 누운 원근)
func _draw_chains(canvas: CanvasItem) -> void:
	var grow: float = clampf(_chains_age / 0.45, 0.0, 1.0)
	var fade := 1.0
	if _chains_age > BUFF_TIME:
		fade = clampf(1.0 - (_chains_age - BUFF_TIME) / 0.5, 0.0, 1.0)
	if fade <= 0.0:
		return
	var sc: float = lerpf(0.3, 1.0, grow)
	var a: float = grow * fade
	var rc := _target + Vector2(0.0, 0.0)
	var rot: float = _spin_acc * (TAU / 5.0)
	var radius: float = 70.0 * sc
	# 점선 외곽 원
	var seg_count := 18
	for i in range(seg_count):
		var a0: float = TAU * float(i) / seg_count + rot
		var a1: float = a0 + TAU / (seg_count * 2.0)
		var pts := PackedVector2Array()
		for k in range(4):
			var t: float = float(k) / 3.0
			var ang: float = lerpf(a0, a1, t)
			pts.append(rc + Vector2(cos(ang) * radius, sin(ang) * radius * RING_SQUASH))
		canvas.draw_polyline(pts, Color(COL_RED, a * 0.8), 2.0)
	# 8개 하트
	for i in range(8):
		var ang: float = TAU * float(i) / 8.0 + rot
		var hpos := rc + Vector2(cos(ang) * radius, sin(ang) * radius * RING_SQUASH)
		var poly := PackedVector2Array()
		for v in _heart_pts:
			poly.append(hpos + (v * 9.0 * sc).rotated(ang + PI * 0.5))
		canvas.draw_colored_polygon(poly, Color(COL_CRIMSON, a * 0.9))

# 하트 모양 충격파 — 0.85s 동안 10배 확장 (윤곽선만)
func _draw_shock(canvas: CanvasItem) -> void:
	if _shock_age > 0.85:
		return
	var t: float = _shock_age / 0.85
	var sc: float = lerpf(0.3, 10.0, t)
	var oa: float
	if t < 0.2:
		oa = t / 0.2
	else:
		oa = 1.0 - (t - 0.2) / 0.8
	var rc := _target + Vector2(0.0, -40.0)
	var thick: float = maxf(1.0, 4.0 - 3.0 * t)
	# 로즈 + 바이올렛 두 겹
	for tier in [["rose", COL_RED, sc],
				 ["crimson", COL_CRIMSON, sc * 0.85]]:
		var col: Color = tier[1]
		var sci: float = tier[2]
		var size: float = 16.0 * sci
		var poly := PackedVector2Array()
		for v in _heart_pts:
			poly.append(rc + v * size)
		poly.append(poly[0])
		canvas.draw_polyline(poly, Color(col, oa), thick, true)

# ── 블렌드 모드가 다른 두 그리기 레이어 ──
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
