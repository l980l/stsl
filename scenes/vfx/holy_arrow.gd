# scenes/vfx/holy_arrow.gd
# 시전자→타겟 성스러운 화살(빛의 화살) VFX — bullet_shot 의 빠른 트레이서 + holy_slash 의 후광·잔상.
# Joan of Arc 의 holy_bolt 등 — battle_scene 이 holy_bolt damage_type 공격 시 .new() → add_child → play.
# 노드는 position (0,0)으로 add_child해야 한다 (좌표를 global로 받아 그대로 그림).
# 어두운 안개·깃털은 일반 블렌드, 후광·트레이서·빛입자·빛상처·십자잔상은 가산 — 2레이어.
extends Node2D

# 파티클 갯수 — GameSettings.particle_count_scale 적용 (하/중/상 = 0.25/0.5/1.0배)
var _particle_scale_override: float = -1.0  # vfx_preview 3-way 비교용 (음수=GameSettings)

func _pcount(n: int) -> int:
	if _particle_scale_override > 0.0:
		return maxi(1, int(round(n * _particle_scale_override)))
	var gs := get_node_or_null("/root/GameSettings")
	return n if gs == null else maxi(1, int(round(n * gs.particle_count_scale())))

const COL_HOT     := Color(1, 1, 1)             # 흰 코어
const COL_MID     := Color(1.0, 0.949, 0.753)   # #fff2c0 — 성광
const COL_GOLD    := Color(1.0, 0.820, 0.4)     # #ffd166 — 황금
const COL_DEEP    := Color(0.784, 0.573, 0.196) # #c89232 — 진금빛
const COL_AIM     := Color(1.0, 0.251, 0.251)   # #ff4040 — 조준 레이저
const COL_HAZE    := Color(1.0, 0.941, 0.784)   # rgba(255,240,200) — 안개
const COL_FEATHER := Color(1.0, 0.980, 0.863)   # rgba(255,250,220) — 깃털

# 크기/타이밍 — 이 상수만 만지면 된다.
const DRAW_TIME    := 0.15  # 조준 시간(s)
const FLIGHT_TIME  := 0.11  # 빛의 화살 비행 시간(s) — 매우 빠름
const IMPACT_DELAY := DRAW_TIME + FLIGHT_TIME  # battle_manager 동기화용
const STUCK_TIME   := 1.5   # 명중 후 십자가 박힌 채 유지 시간(s)
const HALO_RADIUS  := 56.0  # 시전자 뒤 후광 반경(px)
const PSPEED       := 60.0  # HTML(dt*0.06) → Godot(delta*60) 환산 계수

## 명중 순간 — 화면 플래시·흔들림·SFX·피격 피드백 요청 (battle_scene이 수신)
signal screen_effect

var _caster := Vector2.ZERO
var _target := Vector2.ZERO
var _smoke_layer: Node2D  # 일반 블렌드 — 안개·깃털
var _glow_layer: Node2D   # 가산 블렌드 — 후광·트레이서·빛입자·머즐·화살머리·조준선·빛상처·십자
var _particles: Array = []  # [{pos, vel, life, max_life, r, kind, grav, rot, spin}]
var _trail_pts: PackedVector2Array = PackedVector2Array()
var _aim_t := -1.0       # <0 = 비활성, 경과 초 (조준 레이저)
var _bullet_t := -1.0    # <0 = 비활성, 0~1 = 화살 비행
var _muzzle_age := -1.0  # <0 = 비활성, 경과 초 (머즐 플래시)
var _halo_age := -1.0    # <0 = 비활성, 경과 초 (시전자 뒤 후광)
var _stuck_age := -1.0   # <0 = 비활성, 경과 초 (타겟에 박힌 십자가)
var _impact_ang := 0.0   # 명중 시 비행 각도 — 박힌 십자가 방향
var _channeling := false
var _impacted := false

# ── 위치 보간 (autoload 비의존 static — 단위 테스트 가능) ──
static func arrow_pos(a: Vector2, b: Vector2, t: float) -> Vector2:
	return a.lerp(b, clampf(t, 0.0, 1.0))

func _ready() -> void:
	set_process(false)
	_smoke_layer = _DrawLayer.new()
	_smoke_layer.setup(self, false)
	add_child(_smoke_layer)
	_glow_layer = _DrawLayer.new()
	_glow_layer.setup(self, true)
	add_child(_glow_layer)

# caster_pos / target_pos 는 global 좌표 (노드가 (0,0)에 있다는 전제)
func play(caster_pos: Vector2, target_pos: Vector2) -> void:
	_caster = caster_pos + Vector2(0.0, -20.0)
	_target = target_pos
	_run()

func _run() -> void:
	# 1) 조준 — 빨간 조준선 + 등 뒤 후광 + 채널 빛 입자
	_aim_t = 0.0
	_halo_age = 0.0
	_channeling = true
	set_process(true)
	await get_tree().create_timer(DRAW_TIME).timeout
	if not is_inside_tree():
		return
	# 2) 발사 — 머즐 플래시 + 빛의 화살
	_aim_t = -1.0
	_channeling = false
	_muzzle_age = 0.0
	_spawn_muzzle()
	_bullet_t = 0.0
	# 3) 비행·명중·박힌 십자가는 _process 에서. 정리.
	await get_tree().create_timer(FLIGHT_TIME + STUCK_TIME + 1.0).timeout
	if is_inside_tree():
		queue_free()

func _mk(pos: Vector2, vel: Vector2, max_life: float, r: float, kind: String,
		grav: float, rot: float = 0.0, spin: float = 0.0) -> Dictionary:
	return {"pos": pos, "vel": vel, "life": 0.0, "max_life": max_life, "r": r,
		"kind": kind, "grav": grav, "rot": rot, "spin": spin}

# 조준 중 시전자 손에서 피어오르는 빛 입자
func _spawn_channel_mote() -> void:
	_particles.append(_mk(_caster + Vector2(randf_range(-11.0, 11.0), randf_range(-30.0, -14.0)),
		Vector2(randf_range(-0.3, 0.3), -0.4 - randf() * 0.6),
		0.9 + randf() * 0.6, 1.4 + randf() * 1.4, "mote", -0.005))

# 발사 — 황금 머즐 스파크 (탄피 없음 — 마법 화살)
func _spawn_muzzle() -> void:
	var dir := (_target - _caster).normalized()
	for _i in range(_pcount(14)):
		var ang := dir.angle() + randf_range(-0.25, 0.25)
		var sp := 4.0 + randf() * 7.0
		_particles.append(_mk(_caster, Vector2(cos(ang) * sp, sin(ang) * sp),
			0.26 + randf() * 0.22, 1.2 + randf() * 1.4, "spark", 0.04))

# 명중 — 튕기는 스파크 + 안개만 (별가루·깃털·빛 상처는 사용하지 않음)
func _spawn_impact(pos: Vector2, ang: float) -> void:
	for _i in range(_pcount(20)):
		var a := ang + PI + randf_range(-0.7, 0.7)
		var sp := 2.0 + randf() * 6.0
		_particles.append(_mk(pos, Vector2(cos(a) * sp, sin(a) * sp - 1.0),
			0.4 + randf() * 0.4, 1.0 + randf() * 1.3, "spark", 0.18))
	for _i in range(_pcount(14)):
		var a := randf() * TAU
		var sp := 0.5 + randf() * 1.6
		_particles.append(_mk(pos, Vector2(cos(a) * sp, sin(a) * sp * 0.6 - 0.4),
			1.2 + randf() * 0.7, 11.0 + randf() * 9.0, "haze", -0.008))

func _process(delta: float) -> void:
	# 채널 중 빛 입자
	if _channeling and randf() < 0.7:
		_spawn_channel_mote()

	if _aim_t >= 0.0:
		_aim_t += delta
	if _muzzle_age >= 0.0:
		_muzzle_age += delta
	if _halo_age >= 0.0:
		_halo_age += delta
	if _stuck_age >= 0.0:
		_stuck_age += delta

	# 화살 비행 — 트레일 갱신
	if _bullet_t >= 0.0 and _bullet_t < 1.0:
		_bullet_t += delta / FLIGHT_TIME
		_trail_pts.append(arrow_pos(_caster, _target, clampf(_bullet_t, 0.0, 1.0)))
		while _trail_pts.size() > 14:
			_trail_pts.remove_at(0)
		if _bullet_t >= 1.0 and not _impacted:
			_on_impact()
	elif _trail_pts.size() > 0:
		_trail_pts.remove_at(0)

	# 파티클 물리
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

func _on_impact() -> void:
	_impacted = true
	_impact_ang = (_target - _caster).angle()
	_spawn_impact(_target, _impact_ang)
	_stuck_age = 0.0
	screen_effect.emit()

# ── 그리기 패스 ──
func _draw_smoke_pass(canvas: CanvasItem) -> void:
	# 황금 안개 (깃털·빛입자는 사용하지 않음)
	for p in _particles:
		if p["kind"] != "haze":
			continue
		var k: float = p["life"] / p["max_life"]
		var a: float = (1.0 - k) * 0.4
		var r: float = p["r"] * (1.0 + k * 1.3)
		canvas.draw_circle(p["pos"], r, Color(COL_HAZE, a))

func _draw_glow_pass(canvas: CanvasItem) -> void:
	# 시전자 뒤 후광
	if _halo_age >= 0.0:
		_draw_halo(canvas)
	# 조준 레이저
	if _aim_t >= 0.0:
		var prog := clampf(_aim_t / (DRAW_TIME * 0.6), 0.0, 1.0)
		var laser_end := _caster.lerp(_target, prog)
		canvas.draw_line(_caster, laser_end, Color(COL_AIM, 0.85), 1.5)
		var dot_pulse := 4.0 + 2.0 * sin(_aim_t * 18.0)
		canvas.draw_circle(laser_end, dot_pulse, Color(COL_AIM, 0.9))
	# 머즐 플래시 (황금)
	if _muzzle_age >= 0.0 and _muzzle_age < 0.18:
		var u := _muzzle_age / 0.18
		var msc: float
		var ma: float
		if u < 0.3:
			msc = lerpf(0.3, 1.2, u / 0.3)
			ma = u / 0.3
		else:
			msc = lerpf(1.2, 1.4, (u - 0.3) / 0.7)
			ma = 1.0 - (u - 0.3) / 0.7
		var dir := (_target - _caster).normalized()
		var mc := _caster + dir * 22.0
		canvas.draw_circle(mc, 22.0 * msc, Color(COL_GOLD, 0.55 * ma))
		canvas.draw_circle(mc, 12.0 * msc, Color(COL_MID, 0.85 * ma))
		canvas.draw_circle(mc, 5.0 * msc, Color(COL_HOT, ma))
	# 트레이서 (3중 황금 streak — bullet과 동일 색감)
	if _trail_pts.size() >= 2:
		canvas.draw_polyline(_trail_pts, Color(COL_GOLD, 0.55), 6.0, true)
		canvas.draw_polyline(_trail_pts, Color(COL_MID, 0.95), 2.5, true)
		canvas.draw_polyline(_trail_pts, Color(COL_HOT, 1.0), 1.0, true)
	# 화살 머리 — 가로로 날아가는 십자가 (긴 축이 비행 방향)
	if _bullet_t >= 0.0 and _bullet_t < 1.0:
		var bp := arrow_pos(_caster, _target, clampf(_bullet_t, 0.0, 1.0))
		_draw_cross(canvas, bp, (_target - _caster).angle(), 1.0)
	# 빛 입자 (밝은 점 + 십자)
	for p in _particles:
		if p["kind"] != "mote":
			continue
		var k: float = p["life"] / p["max_life"]
		var a: float = 1.0 - k
		var pr: float = p["r"]
		var pos: Vector2 = p["pos"]
		var col := Color(1.0, 0.961 - 0.078 * k, 0.745 + 0.078 * k, a)
		canvas.draw_circle(pos, pr, col)
		canvas.draw_rect(Rect2(pos.x - pr * 2.5, pos.y - 0.3, pr * 5.0, 0.6), col)
		canvas.draw_rect(Rect2(pos.x - 0.3, pos.y - pr * 2.5, 0.6, pr * 5.0), col)
	# 명중 스파크
	for p in _particles:
		if p["kind"] != "spark":
			continue
		var k: float = p["life"] / p["max_life"]
		var a: float = 1.0 - k
		var col := Color(1.0, 0.902 - 0.157 * k, 0.706 - 0.314 * k, a)
		var pr: float = p["r"]
		canvas.draw_circle(p["pos"], pr, col)
		canvas.draw_rect(Rect2(p["pos"].x - pr * 3.0, p["pos"].y - 0.3, pr * 6.0, 0.6), col)
	# 박힌 십자가 — 비행 끝나면 타겟에 잠시 꽂혀 있다가 fade
	if _stuck_age >= 0.0:
		_draw_stuck_cross(canvas)

func _draw_cross(canvas: CanvasItem, pos: Vector2, ang: float, alpha: float) -> void:
	var fwd := Vector2(cos(ang), sin(ang))
	var side := Vector2(-fwd.y, fwd.x)
	canvas.draw_circle(pos, 14.0, Color(COL_GOLD, 0.4 * alpha))
	# 가로(긴) 막대 — 비행/박힘 방향
	var hlen := 18.0
	var hthick := 4.0
	canvas.draw_colored_polygon(PackedVector2Array([
		pos + fwd * -hlen + side * -hthick, pos + fwd * hlen + side * -hthick,
		pos + fwd * hlen + side * hthick, pos + fwd * -hlen + side * hthick,
	]), Color(COL_MID, 0.95 * alpha))
	# 세로(짧은) 막대 — 십자 가로지름
	var vlen := 9.0
	var vthick := 4.0
	canvas.draw_colored_polygon(PackedVector2Array([
		pos + fwd * -vthick + side * -vlen, pos + fwd * vthick + side * -vlen,
		pos + fwd * vthick + side * vlen, pos + fwd * -vthick + side * vlen,
	]), Color(COL_MID, 0.95 * alpha))
	canvas.draw_circle(pos, 2.5, Color(COL_HOT, alpha))

# 명중 후 타겟에 박힌 채로 잠시 머물다 fade — arrow_shot 의 stuck arrow 와 동일 패턴
func _draw_stuck_cross(canvas: CanvasItem) -> void:
	var slide: float = clampf(_stuck_age / 0.18, 0.0, 1.0)
	var fade := 1.0
	if _stuck_age > STUCK_TIME:
		fade = clampf(1.0 - (_stuck_age - STUCK_TIME) / 0.4, 0.0, 1.0)
	if fade <= 0.0:
		return
	# 슬라이드 인 — 박힐 때 약간 뒤에서 들어옴
	var fwd := Vector2(cos(_impact_ang), sin(_impact_ang))
	var spos: Vector2 = _target - fwd * (20.0 * (1.0 - slide))
	_draw_cross(canvas, spos, _impact_ang, fade)

func _draw_halo(canvas: CanvasItem) -> void:
	var ap: float = clampf(_halo_age / 0.35, 0.0, 1.0)
	var fade := 1.0
	if _halo_age > DRAW_TIME:
		fade = clampf(1.0 - (_halo_age - DRAW_TIME) / 0.3, 0.0, 1.0)
	var a: float = ap * fade * 0.7
	if a <= 0.0:
		return
	var hc := _caster + Vector2(-30.0, -30.0)
	canvas.draw_arc(hc, HALO_RADIUS, 0.0, TAU, 40, Color(COL_MID, 0.85 * a), 2.0, true)
	canvas.draw_arc(hc, HALO_RADIUS * 0.78, 0.0, TAU, 32, Color(COL_GOLD, 0.55 * a), 1.0, true)

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
