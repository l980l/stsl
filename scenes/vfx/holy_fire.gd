# scenes/vfx/holy_fire.gd
# 시전자→타겟 성스러운 화염 VFX — fire_blast 의 황금/홀리 색감 변종.
# Joan of Arc 의 saints_flame 등 — battle_scene 이 holy_fire damage_type 공격 시 .new() → add_child → play.
# 노드는 position (0,0)으로 add_child해야 한다 (좌표를 global로 받아 그대로 그림).
# 어두운 연기는 가산 블렌드로 안 보이므로 연기(일반)·불꽃(가산) 2개 레이어로 분리해 그린다.
extends Node2D

# 파티클 갯수 — GameSettings.particle_count_scale 적용 (하/중/상 = 0.25/0.5/1.0배)
var _particle_scale_override: float = -1.0  # vfx_preview 3-way 비교용 (음수=GameSettings)

func _pcount(n: int) -> int:
	if _particle_scale_override > 0.0:
		return maxi(1, int(round(n * _particle_scale_override)))
	var gs := get_node_or_null("/root/GameSettings")
	return n if gs == null else maxi(1, int(round(n * gs.particle_count_scale())))

const COL_HOT   := Color(1.0, 0.965, 0.85)    # 거의 흰 코어
const COL_MID   := Color(1.0, 0.820, 0.4)     # #ffd166 — 황금
const COL_DEEP  := Color(0.784, 0.573, 0.196) # #c89232 — 진금빛
const COL_SMOKE := Color(0.165, 0.137, 0.078) # 어두운 황갈색 — 그을음

# 크기/타이밍 — 이 상수만 만지면 된다.
const ORB_CHARGE_START := 0.12  # 차지 구체 시작
const ORB_CHARGE_FULL  := 0.36  # 차지 완료
const CHARGE_TIME      := 0.32  # 차지 시간(s)
const PROJ_FLIGHT      := 0.45  # 투사체 비행 시간(s)
const IMPACT_DELAY     := CHARGE_TIME + PROJ_FLIGHT  # battle_manager 동기화용
const ARC_HEIGHT       := 120.0 # 포물선 최고점 높이(px)
const BURN_TIME        := 2.0   # 명중 후 잔불(DoT) 지속(s)
const PSPEED           := 60.0  # HTML(dt*0.06) → Godot(delta*60) 환산 계수

## 투사체 명중 순간 — 화면 플래시·흔들림·SFX·피격 피드백 요청 (battle_scene이 수신)
signal screen_effect

var _caster := Vector2.ZERO
var _target := Vector2.ZERO
var _charge_orb: Sprite2D
var _smoke_layer: Node2D
var _fire_layer: Node2D
var _particles: Array = []
var _proj_t := -1.0
var _impacted := false
var _shock_life := -1.0
var _heat_life := -1.0
var _burn_timer := 0.0

static func proj_pos(a: Vector2, b: Vector2, t: float, arc_h: float) -> Vector2:
	return a.lerp(b, t) + Vector2(0.0, -sin(t * PI) * arc_h)

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
	var orb_tex := _make_orb_tex(COL_HOT, COL_MID, COL_DEEP)
	_smoke_layer = _DrawLayer.new()
	_smoke_layer.setup(self, false)
	add_child(_smoke_layer)
	_charge_orb = Sprite2D.new()
	_charge_orb.texture = orb_tex
	_charge_orb.modulate = Color(1, 1, 1, 0.0)
	_charge_orb.scale = Vector2(ORB_CHARGE_START, ORB_CHARGE_START)
	add_child(_charge_orb)
	_fire_layer = _DrawLayer.new()
	_fire_layer.setup(self, true)
	add_child(_fire_layer)

func play(caster_pos: Vector2, target_pos: Vector2) -> void:
	_caster = caster_pos
	_target = target_pos
	_charge_orb.position = caster_pos
	_run()

func _run() -> void:
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_charge_orb, "modulate:a", 1.0, 0.2)
	tw.parallel().tween_property(_charge_orb, "scale", Vector2(ORB_CHARGE_FULL, ORB_CHARGE_FULL), CHARGE_TIME)
	set_process(true)
	await get_tree().create_timer(CHARGE_TIME).timeout
	if not is_inside_tree():
		return
	var tw2 := create_tween()
	tw2.tween_property(_charge_orb, "modulate:a", 0.0, 0.12)
	_proj_t = 0.0
	await get_tree().create_timer(PROJ_FLIGHT + BURN_TIME + 1.5).timeout
	if is_inside_tree():
		queue_free()

func _spawn_trail(pos: Vector2) -> void:
	for _i in range(_pcount(8)):
		_particles.append(_mk(pos + _rand_off(8.0),
			Vector2(randf_range(-0.3, 0.3), -0.3 - randf() * 0.6),
			0.38 + randf() * 0.42, 8.0 + randf() * 16.0, "smoke", -0.005))
	for _i in range(_pcount(6)):
		_particles.append(_mk(pos + _rand_off(6.0),
			Vector2(randf_range(-0.75, 0.75), randf_range(-0.6, 0.6)),
			0.22 + randf() * 0.22, 3.0 + randf() * 5.0, "flame", -0.02))
	for _i in range(_pcount(3)):
		_particles.append(_mk(pos,
			Vector2(randf_range(-1.75, 1.75), randf_range(-1.75, 1.75) - 0.4),
			0.5 + randf() * 0.5, 1.4 + randf() * 1.2, "ember", 0.02))

func _spawn_explosion(pos: Vector2) -> void:
	for _i in range(_pcount(70)):
		var a := randf() * TAU
		var sp := 1.0 + randf() * 5.0
		_particles.append(_mk(pos,
			Vector2(cos(a) * sp, sin(a) * sp * 0.85 - 1.2),
			0.5 + randf() * 0.5, 14.0 + randf() * 22.0, "fireball", -0.015))
	for _i in range(_pcount(80)):
		var a := randf() * TAU
		var sp := 2.0 + randf() * 7.0
		_particles.append(_mk(pos,
			Vector2(cos(a) * sp, sin(a) * sp - 0.6),
			0.7 + randf() * 0.7, 1.6 + randf() * 1.6, "ember", 0.045))
	for _i in range(_pcount(40)):
		var a := -PI / 2.0 + randf_range(-0.8, 0.8)
		var sp := 0.6 + randf() * 1.6
		_particles.append(_mk(pos + Vector2(randf_range(-30.0, 30.0), randf_range(-20.0, 20.0)),
			Vector2(cos(a) * sp, sin(a) * sp),
			1.4 + randf() * 0.9, 26.0 + randf() * 30.0, "smoke", -0.01))

func _spawn_burn() -> void:
	if randf() < 0.7:
		_particles.append(_mk(_target + Vector2(randf_range(-20.0, 20.0), randf_range(-5.0, 5.0)),
			Vector2(randf_range(-0.2, 0.2), -0.4 - randf() * 0.7),
			0.38 + randf() * 0.42, 4.0 + randf() * 7.0, "flame", -0.02))
	if randf() < 0.4:
		_particles.append(_mk(_target + Vector2(randf_range(-18.0, 18.0), randf_range(-4.0, 4.0)),
			Vector2(randf_range(-0.3, 0.3), -0.8 - randf() * 0.9),
			0.6 + randf() * 0.5, 1.2 + randf() * 1.0, "ember", 0.01))

func _mk(pos: Vector2, vel: Vector2, max_life: float, r: float, kind: String, grav: float) -> Dictionary:
	return {"pos": pos, "vel": vel, "life": 0.0, "max_life": max_life, "r": r, "kind": kind, "grav": grav}

func _rand_off(m: float) -> Vector2:
	return Vector2(randf_range(-m, m), randf_range(-m, m))

func _process(delta: float) -> void:
	if _proj_t >= 0.0:
		_proj_t += delta / PROJ_FLIGHT
		_spawn_trail(proj_pos(_caster, _target, clampf(_proj_t, 0.0, 1.0), ARC_HEIGHT))
		if _proj_t >= 1.0 and not _impacted:
			_on_impact()

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

	if _burn_timer > 0.0:
		_burn_timer -= delta
		_spawn_burn()

	if _shock_life >= 0.0:
		_shock_life += delta / 0.6
	if _heat_life >= 0.0:
		_heat_life += delta / 1.2

	_smoke_layer.queue_redraw()
	_fire_layer.queue_redraw()

func _on_impact() -> void:
	_impacted = true
	_proj_t = -1.0
	_spawn_explosion(_target)
	_shock_life = 0.0
	_heat_life = 0.0
	_burn_timer = BURN_TIME
	screen_effect.emit()

# 황금 톤 색 변환 — 흰노랑 → 황금 → 진금빛 (fire 의 주황·진홍을 황금 계열로)
func _fire_color(kind: String, k: float) -> Color:
	if kind == "fireball":
		if k < 0.25:
			return Color(1.0, 0.961, 0.824, 0.9)
		elif k < 0.55:
			return Color(1.0, 0.820, 0.4, 0.75)
		return Color(0.784, 0.573, 0.196, 0.55)
	if k < 0.3:
		return Color(1.0, 0.949, 0.753, 0.9)
	elif k < 0.6:
		return Color(1.0, 0.820, 0.4, 0.7)
	return Color(0.6, 0.4, 0.15, 0.45)

func _draw_smoke_pass(canvas: CanvasItem) -> void:
	for p in _particles:
		if p["kind"] != "smoke":
			continue
		var k: float = p["life"] / p["max_life"]
		var a: float = (1.0 - k) * 0.35
		var r: float = p["r"] * (1.0 + k * 1.6)
		canvas.draw_circle(p["pos"], r, Color(COL_SMOKE, a))

func _draw_fire_pass(canvas: CanvasItem) -> void:
	for p in _particles:
		var kind: String = p["kind"]
		if kind != "flame" and kind != "fireball":
			continue
		var k: float = p["life"] / p["max_life"]
		var c := _fire_color(kind, k)
		var r: float = p["r"] * (1.0 + k * 0.8)
		canvas.draw_circle(p["pos"], r, Color(c.r, c.g, c.b, c.a * (1.0 - k)))
	# 불씨 — 황금 톤 (fire 의 빨강 → 황금)
	for p in _particles:
		if p["kind"] != "ember":
			continue
		var k: float = p["life"] / p["max_life"]
		var a: float = 1.0 - k
		canvas.draw_circle(p["pos"], p["r"], Color(1.0, 0.961 - 0.157 * k, 0.745 - 0.235 * k, a))
	if _heat_life >= 0.0 and _heat_life <= 1.0:
		var hscale: float
		var hop: float
		if _heat_life < 0.25:
			var u: float = _heat_life / 0.25
			hscale = lerpf(0.4, 1.0, u)
			hop = u
		else:
			var u: float = (_heat_life - 0.25) / 0.75
			hscale = lerpf(1.0, 1.6, u)
			hop = 1.0 - u
		canvas.draw_circle(_target, 130.0 * hscale, Color(COL_MID, 0.13 * hop))
	if _shock_life >= 0.0 and _shock_life <= 1.0:
		var rad: float = 14.0 + _shock_life * 340.0
		var sa: float = (1.0 - _shock_life) * 0.85
		canvas.draw_arc(_target, rad, 0.0, TAU, 48, Color(COL_MID, sa), 1.0 + 4.0 * (1.0 - _shock_life), true)
	if _proj_t >= 0.0:
		var pp := proj_pos(_caster, _target, clampf(_proj_t, 0.0, 1.0), ARC_HEIGHT)
		canvas.draw_circle(pp, 38.0, Color(COL_DEEP, 0.22))
		canvas.draw_circle(pp, 22.0, Color(COL_MID, 0.5))
		canvas.draw_circle(pp, 10.0, Color(COL_HOT, 0.9))
		canvas.draw_circle(pp, 5.0, Color(1, 1, 1, 1))

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
			_fx._draw_fire_pass(self)
		else:
			_fx._draw_smoke_pass(self)
