# scenes/vfx/warrior_buff.gd
# 전사 버프 VFX — ui_sample/vfx/Warrior Buff VFX.html 재현 (스탯 텍스트·주먹 엠블럼 제외).
# Joan 외 영웅의 POWER 카드 — 일반 강화 버프 (성스러운 색감이 아닌 분노/불꽃).
# play 의 첫 인자(caster) 무시 — 버프는 대상 위치에서 발동.
# dust/chunk 는 일반 블렌드, ember/flame/룬링/오라/충격파는 가산 블렌드 — 2레이어.
extends Node2D

const COL_HOT   := Color(1.0, 0.941, 0.753) # #fff0c0 — 흰주황 코어
const COL_MID   := Color(1.0, 0.478, 0.165) # #ff7a2a — 분노 주황
const COL_DEEP  := Color(0.784, 0.188, 0.078) # #c83014 — 진홍
const COL_DUST  := Color(0.784, 0.549, 0.353) # 갈황 흙먼지
const COL_CHUNK := Color(0.431, 0.275, 0.157) # 어두운 갈색 파편

# 크기/타이밍 — 이 상수만 만지면 된다.
const ORB_CHARGE_START := 0.10  # 차지 구체 시작 스케일
const ORB_CHARGE_FULL  := 0.45  # 차지 완료 스케일
const ORB_OFFSET_Y     := -80.0
const CHARGE_TIME      := 0.3
const IMPACT_DELAY     := CHARGE_TIME  # battle_manager 동기화용
const BUFF_TIME        := 1.5
const RING_SQUASH      := 0.34
const RING_RADIUS      := 130.0
const AURA_HEIGHT      := 180.0
const AURA_WIDTH       := 80.0
const SHOCK_TIME       := 0.55
const PSPEED           := 60.0

## 화면 플래시 + 버프 SFX 트리거
signal screen_effect

var _target := Vector2.ZERO
var _charge_orb: Sprite2D
var _smoke_layer: Node2D  # 일반 블렌드 — dust, chunk
var _glow_layer: Node2D   # 가산 블렌드 — ember, flame, 룬링, 오라, 충격파
var _particles: Array = []
var _ring_age := -1.0
var _aura_age := -1.0
var _shock_age := -1.0
var _buff_timer := 0.0
var _ring_spin := 0.0     # HTML 4s/회전

static func _make_orb_tex(c_core: Color, c_mid: Color, c_edge: Color) -> GradientTexture2D:
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.42, 0.72, 1.0])
	grad.colors = PackedColorArray([c_core, c_mid, c_edge, Color(c_edge.r, c_edge.g, c_edge.b, 0.0)])
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
	_smoke_layer = _DrawLayer.new()
	_smoke_layer.setup(self, false)
	add_child(_smoke_layer)

	_charge_orb = Sprite2D.new()
	_charge_orb.texture = _make_orb_tex(COL_HOT, COL_MID, COL_DEEP)
	_charge_orb.modulate = Color(1, 1, 1, 0.0)
	_charge_orb.scale = Vector2(ORB_CHARGE_START, ORB_CHARGE_START)
	add_child(_charge_orb)

	_glow_layer = _DrawLayer.new()
	_glow_layer.setup(self, true)
	add_child(_glow_layer)

# 첫 인자(caster) 무시 — 버프는 대상 위치에서 발동
func play(_caster_pos: Vector2, target_pos: Vector2) -> void:
	_target = target_pos
	_charge_orb.position = target_pos + Vector2(0.0, ORB_OFFSET_Y)
	_run()

func _run() -> void:
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_charge_orb, "modulate:a", 1.0, 0.15)
	tw.parallel().tween_property(_charge_orb, "scale", Vector2(ORB_CHARGE_FULL, ORB_CHARGE_FULL), CHARGE_TIME)
	set_process(true)
	await get_tree().create_timer(CHARGE_TIME).timeout
	if not is_inside_tree():
		return
	var tw2 := create_tween()
	tw2.tween_property(_charge_orb, "modulate:a", 0.0, 0.12)
	_ring_age = 0.0
	_aura_age = 0.0
	_shock_age = 0.0
	_buff_timer = BUFF_TIME
	_spawn_burst()
	screen_effect.emit()
	await get_tree().create_timer(BUFF_TIME + 1.5).timeout
	if is_inside_tree():
		queue_free()

func _mk(pos: Vector2, vel: Vector2, max_life: float, r: float, kind: String,
		grav: float = 0.0, rot: float = 0.0, spin: float = 0.0) -> Dictionary:
	return {"pos": pos, "vel": vel, "life": 0.0, "max_life": max_life, "r": r,
		"kind": kind, "grav": grav, "rot": rot, "spin": spin}

# 발동 순간 — ember 30 + dust 14 + flame 10 + chunk 8 (HTML 의 1/3 정도)
func _spawn_burst() -> void:
	var ctr := _target + Vector2(0.0, -30.0)
	var floor_y := _target + Vector2(0.0, 30.0)
	for _i in range(30):
		var a := randf() * TAU
		var sp := 2.0 + randf() * 6.0
		_particles.append(_mk(ctr, Vector2(cos(a) * sp, sin(a) * sp * 0.9 - 2.0),
			1.1 + randf() * 0.8, 1.5 + randf() * 1.6, "ember", 0.04))
	for _i in range(14):
		var a := randf() * TAU
		var sp := 2.0 + randf() * 4.0
		_particles.append(_mk(floor_y, Vector2(cos(a) * sp, sin(a) * sp * 0.3 - 0.8 - randf()),
			1.5 + randf() * 0.9, 22.0 + randf() * 18.0, "dust", -0.005))
	for _i in range(10):
		var a := randf() * TAU
		var sp := 2.0 + randf() * 4.0
		_particles.append(_mk(ctr, Vector2(cos(a) * sp, sin(a) * sp - 2.0),
			0.6 + randf() * 0.5, 14.0 + randf() * 14.0, "flame", -0.02))
	for _i in range(8):
		var a := randf() * TAU
		var sp := 3.0 + randf() * 5.0
		_particles.append(_mk(floor_y, Vector2(cos(a) * sp, sin(a) * sp * 0.4 - 3.0 - randf() * 1.5),
			1.0 + randf() * 0.7, 3.0 + randf() * 4.0, "chunk", 0.32,
			randf() * TAU, randf_range(-0.4, 0.4)))

# BUFF_TIME 동안 매 프레임 — 잔불 솟구침
func _spawn_rising() -> void:
	var floor_y := _target.y + 30.0
	for _i in range(2):
		_particles.append(_mk(Vector2(_target.x + randf_range(-75.0, 75.0), floor_y + randf_range(-5.0, 5.0)),
			Vector2(randf_range(-0.6, 0.6), -1.2 - randf() * 1.5),
			1.2 + randf() * 0.9, 1.6 + randf() * 1.6, "ember", 0.02))
	if randf() < 0.4:
		_particles.append(_mk(Vector2(_target.x + randf_range(-50.0, 50.0), floor_y - 5.0),
			Vector2(randf_range(-0.3, 0.3), -1.5 - randf()),
			0.7 + randf() * 0.5, 8.0 + randf() * 10.0, "flame", -0.02))

func _process(delta: float) -> void:
	if _ring_age >= 0.0:
		_ring_age += delta
		_ring_spin += delta * (TAU / 4.0)
	if _aura_age >= 0.0:
		_aura_age += delta
	if _shock_age >= 0.0:
		_shock_age += delta
	if _buff_timer > 0.0:
		_buff_timer -= delta
		_spawn_rising()

	var damp: float = pow(0.992, delta * 60.0)
	var alive: Array = []
	for p in _particles:
		p["life"] += delta
		if p["life"] >= p["max_life"]:
			continue
		p["pos"] += p["vel"] * delta * PSPEED
		p["vel"].y += p["grav"] * delta * PSPEED
		p["vel"] *= damp
		if p["kind"] == "chunk":
			p["rot"] += p["spin"] * delta * PSPEED
		alive.append(p)
	_particles = alive

	_smoke_layer.queue_redraw()
	_glow_layer.queue_redraw()

# ── 일반 블렌드 — dust, chunk ──
func _draw_smoke_pass(canvas: CanvasItem) -> void:
	for p in _particles:
		if p["kind"] != "dust":
			continue
		var k: float = p["life"] / p["max_life"]
		var a: float = (1.0 - k) * 0.5
		var r: float = p["r"] * (1.0 + k * 1.4)
		canvas.draw_circle(p["pos"], r, Color(COL_DUST, a))
	for p in _particles:
		if p["kind"] != "chunk":
			continue
		var a: float = (1.0 - p["life"] / p["max_life"]) * 0.9
		var r: float = p["r"]
		var fwd := Vector2(cos(p["rot"]), sin(p["rot"]))
		var side := Vector2(-fwd.y, fwd.x)
		canvas.draw_colored_polygon(PackedVector2Array([
			p["pos"] + fwd * -r + side * (-r * 0.7), p["pos"] + fwd * r + side * (-r * 0.7),
			p["pos"] + fwd * r + side * (r * 0.7), p["pos"] + fwd * -r + side * (r * 0.7),
		]), Color(COL_CHUNK, a))

# ── 가산 블렌드 — flame, ember, 룬링, 오라, 충격파 ──
func _draw_glow_pass(canvas: CanvasItem) -> void:
	if _aura_age >= 0.0:
		_draw_aura(canvas)
	if _ring_age >= 0.0:
		_draw_ring(canvas)
	if _shock_age >= 0.0:
		_draw_shock(canvas)
	# flame — 시간에 따라 흰주황→주황→진홍
	for p in _particles:
		if p["kind"] != "flame":
			continue
		var k: float = p["life"] / p["max_life"]
		var a: float = 1.0 - k
		var col: Color
		if k < 0.25:
			col = Color(COL_HOT.r, COL_HOT.g, COL_HOT.b, 0.85 * a)
		elif k < 0.55:
			col = Color(COL_MID.r, COL_MID.g, COL_MID.b, 0.7 * a)
		else:
			col = Color(COL_DEEP.r, COL_DEEP.g, COL_DEEP.b, 0.5 * a)
		var r: float = p["r"] * (1.0 + k * 0.7)
		canvas.draw_circle(p["pos"], r, col)
	# ember
	for p in _particles:
		if p["kind"] != "ember":
			continue
		var k: float = p["life"] / p["max_life"]
		var a: float = 1.0 - k
		# HTML rgba(255, 200-120k, 90-80k, a)
		var col := Color(1.0, (200.0 - 120.0 * k) / 255.0, (90.0 - 80.0 * k) / 255.0, a)
		var pr: float = p["r"]
		canvas.draw_circle(p["pos"], pr, col)
		canvas.draw_rect(Rect2(p["pos"].x - pr * 2.5, p["pos"].y - 0.3, pr * 5.0, 0.6), col)

# 분노 오라 — 빛기둥과 유사하지만 더 작고 빠른 깜빡임 (HTML auraFlicker 0.25s)
func _draw_aura(canvas: CanvasItem) -> void:
	var grow: float = clampf(_aura_age / 0.4, 0.0, 1.0)
	var fade := 1.0
	if _aura_age > BUFF_TIME:
		fade = clampf(1.0 - (_aura_age - BUFF_TIME) / 0.4, 0.0, 1.0)
	if fade <= 0.0:
		return
	var flicker: float = 0.85 + sin(_aura_age * (TAU / 0.25)) * 0.10
	var alpha: float = grow * fade * flicker
	var bottom_y := _target.y
	var top_y := _target.y - AURA_HEIGHT * grow
	var w_b := AURA_WIDTH * grow
	var w_t := AURA_WIDTH * 0.4 * grow
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(_target.x - w_b, bottom_y),
		Vector2(_target.x + w_b, bottom_y),
		Vector2(_target.x + w_t, top_y),
		Vector2(_target.x - w_t, top_y),
	]), Color(COL_DEEP, 0.45 * alpha))
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(_target.x - w_b * 0.5, bottom_y),
		Vector2(_target.x + w_b * 0.5, bottom_y),
		Vector2(_target.x + w_t * 0.5, top_y),
		Vector2(_target.x - w_t * 0.5, top_y),
	]), Color(COL_MID, 0.55 * alpha))

# 가시 룬링 — 외곽 두 동심원 + 16개 가시 (회전) + 점선 안쪽원
func _draw_ring(canvas: CanvasItem) -> void:
	var grow: float = clampf(_ring_age / 0.35, 0.0, 1.0)
	var fade := 1.0
	if _ring_age > BUFF_TIME:
		fade = clampf(1.0 - (_ring_age - BUFF_TIME) / 0.5, 0.0, 1.0)
	if fade <= 0.0:
		return
	var sc: float = lerpf(0.3, 1.0, grow)
	var a: float = grow * fade * 0.95
	var rc := _target + Vector2(0.0, 30.0)
	for radius in [RING_RADIUS, RING_RADIUS * 0.91]:
		var rad := float(radius) * sc
		var pts := PackedVector2Array()
		for i in range(48):
			var ang: float = TAU * float(i) / 48.0
			pts.append(rc + Vector2(cos(ang) * rad, sin(ang) * rad * RING_SQUASH))
		pts.append(pts[0])
		canvas.draw_polyline(pts, Color(COL_MID, a), 2.0)
	# 16 가시 — 외곽 링에서 18px 돌출
	var spike_r := RING_RADIUS * sc
	for i in range(16):
		var ang: float = TAU * float(i) / 16.0 + _ring_spin
		var base := rc + Vector2(cos(ang) * spike_r, sin(ang) * spike_r * RING_SQUASH)
		var tip := rc + Vector2(cos(ang) * (spike_r + 18.0), sin(ang) * (spike_r + 18.0) * RING_SQUASH)
		var perp := Vector2(-sin(ang), cos(ang) * RING_SQUASH) * 6.0
		canvas.draw_colored_polygon(PackedVector2Array([
			base + perp, base - perp, tip,
		]), Color(COL_MID, a))
	# 안쪽 점선원 — 부분 호 12개로 근사
	var dotted_r := RING_RADIUS * 0.62 * sc
	for i in range(12):
		var a0: float = TAU * float(i) / 12.0 + _ring_spin
		var a1: float = a0 + TAU / 24.0
		var pts := PackedVector2Array()
		for k in range(5):
			var t: float = float(k) / 4.0
			var ang: float = lerpf(a0, a1, t)
			pts.append(rc + Vector2(cos(ang) * dotted_r, sin(ang) * dotted_r * RING_SQUASH))
		canvas.draw_polyline(pts, Color(COL_DEEP, a * 0.7), 1.5)

# 충격파 — 둥근 링 한 번에 12배 확장 (0.55s)
func _draw_shock(canvas: CanvasItem) -> void:
	if _shock_age > SHOCK_TIME:
		return
	var t := _shock_age / SHOCK_TIME
	var sc: float = lerpf(0.2, 12.0, t)
	var oa: float
	if t < 0.25:
		oa = t / 0.25
	else:
		oa = 1.0 - (t - 0.25) / 0.75
	var thick: float = lerpf(6.0, 1.0, t)
	var rc := _target + Vector2(0.0, -50.0)
	var rad := 20.0 * sc
	canvas.draw_arc(rc, rad, 0.0, TAU, 48, Color(COL_MID, oa), thick, true)
	canvas.draw_arc(rc, rad * 0.85, 0.0, TAU, 36, Color(COL_HOT, oa * 0.7), thick * 0.5, true)

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
