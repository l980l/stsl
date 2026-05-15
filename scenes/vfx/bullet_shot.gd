# scenes/vfx/bullet_shot.gd
# 시전자→타겟 총알 투사체 VFX — ui_sample/vfx/Bullet Attack VFX.html 재현 (데미지 숫자 제외).
# battle_scene이 bullet damage_type 공격 시 .new() → add_child → play(caster, target).
# 노드는 position (0,0)으로 add_child해야 한다 (좌표를 global로 받아 그대로 그림).
# 어두운 연기·먼지·파편·탄피·탄흔은 일반 블렌드, 트레이서·스파크·머즐플래시·총알머리는 가산 — 2레이어.
extends Node2D

const COL_HOT     := Color(1, 1, 1)             # 흰 코어
const COL_STEEL   := Color(0.812, 0.831, 0.867) # #cfd4dd
const COL_AIM     := Color(1.0, 0.251, 0.251)   # #ff4040 — 조준 레이저
const COL_TRACER  := Color(1.0, 0.816, 0.416)   # #ffd06a — 황금 트레이서
const COL_MUZZLE  := Color(1.0, 0.965, 0.8)     # #fff6cc — 머즐 플래시
const COL_CASING  := Color(0.784, 0.643, 0.290) # #c8a44a — 탄피 황동
const COL_PRIMER  := Color(0.314, 0.235, 0.078) # rgba(80,60,20) — 탄피 캡
const COL_DUST    := Color(0.706, 0.627, 0.549) # rgba(180,160,140) — 명중 먼지
const COL_SMOKE   := Color(0.706, 0.706, 0.745) # rgba(180,180,190) — 머즐 연기

# 크기/타이밍 — 이 상수만 만지면 된다.
const DRAW_TIME   := 0.30  # 조준 시간(s)
const FLIGHT_TIME := 0.11  # 총알 비행 시간(s) — 매우 빠름
const IMPACT_DELAY := DRAW_TIME + FLIGHT_TIME  # battle_manager 동기화용
const HOLE_TIME   := 1.5   # 탄흔 유지 시간(s)
const PSPEED      := 60.0  # HTML(dt*0.06) → Godot(delta*60) 환산 계수

## 명중 순간 — 화면 플래시·흔들림·SFX·피격 피드백 요청 (battle_scene이 수신)
signal screen_effect

var _caster := Vector2.ZERO
var _target := Vector2.ZERO
var _normal_layer: Node2D  # 일반 블렌드 — 연기·먼지·파편·탄피·탄흔
var _glow_layer: Node2D    # 가산 블렌드 — 트레이서·스파크·조준선·머즐플래시·총알머리
var _particles: Array = []  # [{pos, vel, life, max_life, r, kind, grav, rot, spin}]
var _trail_pts: PackedVector2Array = PackedVector2Array()
var _aim_t := -1.0       # <0 = 비활성, 경과 초 (조준 레이저)
var _bullet_t := -1.0    # <0 = 비활성, 0~1 = 총알 비행
var _muzzle_age := -1.0  # <0 = 비활성, 경과 초 (머즐 플래시)
var _hole_age := -1.0    # <0 = 비활성, 경과 초 (탄흔)
var _impacted := false
var _impact_ang := 0.0

# ── 총알 위치 (autoload 비의존 static — 단위 테스트 가능) ──
static func bullet_pos(a: Vector2, b: Vector2, t: float) -> Vector2:
	return a.lerp(b, clampf(t, 0.0, 1.0))

func _ready() -> void:
	set_process(false)
	_normal_layer = _DrawLayer.new()
	_normal_layer.setup(self, false)
	add_child(_normal_layer)
	_glow_layer = _DrawLayer.new()
	_glow_layer.setup(self, true)
	add_child(_glow_layer)

# caster_pos / target_pos 는 global 좌표 (노드가 (0,0)에 있다는 전제)
func play(caster_pos: Vector2, target_pos: Vector2) -> void:
	_caster = caster_pos + Vector2(0.0, -20.0)
	_target = target_pos
	_run()

func _run() -> void:
	# 1) 조준
	_aim_t = 0.0
	set_process(true)
	await get_tree().create_timer(DRAW_TIME).timeout
	if not is_inside_tree():
		return
	# 2) 발사 — 머즐 플래시 + 탄피 + 총알
	_aim_t = -1.0
	_muzzle_age = 0.0
	_spawn_muzzle()
	_bullet_t = 0.0
	# 3) 비행·명중·탄흔은 _process에서. 정리.
	await get_tree().create_timer(FLIGHT_TIME + HOLE_TIME + 1.0).timeout
	if is_inside_tree():
		queue_free()

func _mk(pos: Vector2, vel: Vector2, max_life: float, r: float, kind: String,
		grav: float, rot: float = 0.0, spin: float = 0.0) -> Dictionary:
	return {"pos": pos, "vel": vel, "life": 0.0, "max_life": max_life, "r": r,
		"kind": kind, "grav": grav, "rot": rot, "spin": spin}

# 발사 — 머즐 스파크 + 머즐 연기 + 탄피 사출
func _spawn_muzzle() -> void:
	var dir := (_target - _caster).normalized()
	# 스파크 — 총구 앞쪽 부채꼴
	for _i in range(14):
		var ang := dir.angle() + randf_range(-0.25, 0.25)
		var sp := 4.0 + randf() * 7.0
		_particles.append(_mk(_caster, Vector2(cos(ang) * sp, sin(ang) * sp),
			0.26 + randf() * 0.22, 1.2 + randf() * 1.4, "spark", 0.04))
	# 머즐 연기
	for _i in range(14):
		var ang := dir.angle() + randf_range(-0.8, 0.8)
		var sp := 0.6 + randf() * 1.6
		_particles.append(_mk(_caster, Vector2(cos(ang) * sp, sin(ang) * sp * 0.7 - 0.3 - randf() * 0.5),
			1.1 + randf() * 0.9, 9.0 + randf() * 10.0, "smoke", -0.005))
	# 탄피 1개 — 위로 튀고 떨어짐 (일반 회전 사각형)
	var side := Vector2(-dir.y, dir.x)
	_particles.append(_mk(_caster + side * -8.0,
		side * randf_range(-0.6, -0.4) + Vector2(0.0, -3.0 - randf()),
		1.6, 5.0, "casing", 0.32, randf() * TAU, randf_range(-0.5, 0.5)))

# 명중 — 튕기는 스파크 + 먼지 + 파편
func _spawn_impact(pos: Vector2, ang: float) -> void:
	for _i in range(28):
		var a := ang + PI + randf_range(-0.7, 0.7)
		var sp := 2.0 + randf() * 7.0
		_particles.append(_mk(pos, Vector2(cos(a) * sp, sin(a) * sp - 1.0),
			0.38 + randf() * 0.4, 1.0 + randf() * 1.3, "spark", 0.18))
	for _i in range(18):
		var a := ang + PI + randf_range(-0.5, 0.5)
		var sp := 0.4 + randf() * 2.2
		_particles.append(_mk(pos, Vector2(cos(a) * sp, sin(a) * sp * 0.5 - 0.6),
			0.7 + randf() * 0.5, 9.0 + randf() * 10.0, "dust", -0.008))
	for _i in range(8):
		var a := ang + PI + randf_range(-0.45, 0.45)
		var sp := 3.0 + randf() * 5.0
		_particles.append(_mk(pos, Vector2(cos(a) * sp, sin(a) * sp - 2.0),
			0.8 + randf() * 0.5, 2.0 + randf() * 2.0, "chip", 0.3,
			randf() * TAU, randf_range(-0.35, 0.35)))

func _process(delta: float) -> void:
	if _aim_t >= 0.0:
		_aim_t += delta
	if _muzzle_age >= 0.0:
		_muzzle_age += delta
	if _hole_age >= 0.0:
		_hole_age += delta

	# 총알 비행 — 트레일 갱신
	if _bullet_t >= 0.0 and _bullet_t < 1.0:
		_bullet_t += delta / FLIGHT_TIME
		_trail_pts.append(bullet_pos(_caster, _target, clampf(_bullet_t, 0.0, 1.0)))
		while _trail_pts.size() > 14:
			_trail_pts.remove_at(0)
		if _bullet_t >= 1.0 and not _impacted:
			_on_impact()
	elif _trail_pts.size() > 0:
		_trail_pts.remove_at(0)

	# 파티클 물리 (HTML frame() 포팅)
	var damp: float = pow(0.992, delta * 60.0)
	var alive: Array = []
	for p in _particles:
		p["life"] += delta
		if p["life"] >= p["max_life"]:
			continue
		p["pos"] += p["vel"] * delta * PSPEED
		p["vel"].y += p["grav"] * delta * PSPEED
		p["vel"] *= damp
		if p["kind"] == "chip" or p["kind"] == "casing":
			p["rot"] += p["spin"] * delta * PSPEED
		alive.append(p)
	_particles = alive

	_normal_layer.queue_redraw()
	_glow_layer.queue_redraw()

func _on_impact() -> void:
	_impacted = true
	_impact_ang = (_target - _caster).angle()
	_spawn_impact(_target, _impact_ang)
	_hole_age = 0.0
	screen_effect.emit()

# ── 그리기 패스 ──
func _draw_normal_pass(canvas: CanvasItem) -> void:
	# 머즐 연기 + 명중 먼지
	for p in _particles:
		var kind: String = p["kind"]
		if kind != "smoke" and kind != "dust":
			continue
		var k: float = p["life"] / p["max_life"]
		var a: float = (1.0 - k) * 0.45
		var r: float = p["r"] * (1.0 + k * 1.4)
		var col := COL_SMOKE if kind == "smoke" else COL_DUST
		canvas.draw_circle(p["pos"], r, Color(col, a))

	# 파편 (회전 사각형)
	for p in _particles:
		if p["kind"] != "chip":
			continue
		var a: float = (1.0 - p["life"] / p["max_life"]) * 0.9
		var r: float = p["r"]
		var fwd := Vector2(cos(p["rot"]), sin(p["rot"]))
		var side := Vector2(-fwd.y, fwd.x)
		canvas.draw_colored_polygon(PackedVector2Array([
			p["pos"] + fwd * -r + side * (-r * 0.5), p["pos"] + fwd * r + side * (-r * 0.5),
			p["pos"] + fwd * r + side * (r * 0.5), p["pos"] + fwd * -r + side * (r * 0.5),
		]), Color(COL_STEEL, a))

	# 탄피 (황동 + 어두운 캡)
	for p in _particles:
		if p["kind"] != "casing":
			continue
		var k: float = p["life"] / p["max_life"]
		var a: float = 1.0 - maxf(0.0, (k - 0.7) / 0.3)
		var r: float = p["r"]
		var fwd := Vector2(cos(p["rot"]), sin(p["rot"]))
		var side := Vector2(-fwd.y, fwd.x)
		# 몸통
		canvas.draw_colored_polygon(PackedVector2Array([
			p["pos"] + fwd * -r + side * (-r * 0.5), p["pos"] + fwd * r + side * (-r * 0.5),
			p["pos"] + fwd * r + side * (r * 0.5), p["pos"] + fwd * -r + side * (r * 0.5),
		]), Color(COL_CASING, 0.95 * a))
		# 캡 (왼쪽 짧은 부분 어둡게)
		canvas.draw_colored_polygon(PackedVector2Array([
			p["pos"] + fwd * -r + side * (-r * 0.5), p["pos"] + fwd * (-r * 0.5) + side * (-r * 0.5),
			p["pos"] + fwd * (-r * 0.5) + side * (r * 0.5), p["pos"] + fwd * -r + side * (r * 0.5),
		]), Color(COL_PRIMER, 0.95 * a))

	# 탄흔 (검은 원 + 균열)
	if _hole_age >= 0.0:
		_draw_bullet_hole(canvas)

func _draw_glow_pass(canvas: CanvasItem) -> void:
	# 조준 레이저
	if _aim_t >= 0.0:
		var prog := clampf(_aim_t / (DRAW_TIME * 0.6), 0.0, 1.0)
		var laser_end := _caster.lerp(_target, prog)
		canvas.draw_line(_caster, laser_end, Color(COL_AIM, 0.85), 1.5)
		var dot_pulse := 4.0 + 2.0 * sin(_aim_t * 18.0)
		canvas.draw_circle(laser_end, dot_pulse, Color(COL_AIM, 0.9))

	# 머즐 플래시 (총구 앞쪽 황금 섬광)
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
		canvas.draw_circle(mc, 22.0 * msc, Color(COL_TRACER, 0.55 * ma))
		canvas.draw_circle(mc, 12.0 * msc, Color(COL_MUZZLE, 0.85 * ma))
		canvas.draw_circle(mc, 5.0 * msc, Color(COL_HOT, ma))

	# 트레이서 (3중 황금 streak)
	if _trail_pts.size() >= 2:
		canvas.draw_polyline(_trail_pts, Color(COL_TRACER, 0.55), 6.0, true)
		canvas.draw_polyline(_trail_pts, Color(COL_MUZZLE, 0.95), 2.5, true)
		canvas.draw_polyline(_trail_pts, Color(COL_HOT, 1.0), 1.0, true)

	# 총알 머리 (작은 흰 점 + 황금 글로우)
	if _bullet_t >= 0.0 and _bullet_t < 1.0:
		var bp := bullet_pos(_caster, _target, clampf(_bullet_t, 0.0, 1.0))
		canvas.draw_circle(bp, 10.0, Color(COL_TRACER, 0.45))
		canvas.draw_circle(bp, 6.0, Color(COL_MUZZLE, 0.7))
		canvas.draw_circle(bp, 1.6, Color(COL_HOT, 1.0))

	# 명중 스파크 (밝은 점 + 가로 streak)
	for p in _particles:
		if p["kind"] != "spark":
			continue
		var k: float = p["life"] / p["max_life"]
		var a: float = 1.0 - k
		var col := Color(1.0, 0.902 - 0.157 * k, 0.706 - 0.314 * k, a)
		var pr: float = p["r"]
		canvas.draw_circle(p["pos"], pr, col)
		canvas.draw_rect(Rect2(p["pos"].x - pr * 3.0, p["pos"].y - 0.3, pr * 6.0, 0.6), col)

func _draw_bullet_hole(canvas: CanvasItem) -> void:
	var fade := 1.0
	if _hole_age > HOLE_TIME:
		fade = clampf(1.0 - (_hole_age - HOLE_TIME) / 0.4, 0.0, 1.0)
	if fade <= 0.0:
		return
	# 검은 원 + 외곽 + 균열선 4개
	canvas.draw_circle(_target, 6.0, Color(0.0, 0.0, 0.0, 0.95 * fade))
	canvas.draw_arc(_target, 9.0, 0.0, TAU, 24, Color(0.1, 0.1, 0.1, 0.7 * fade), 0.8, true)
	for i in range(4):
		var ang := deg_to_rad(45.0 * float(i))
		var p1 := _target + Vector2(cos(ang), sin(ang)) * 3.0
		var p2 := _target + Vector2(cos(ang), sin(ang)) * 9.0
		canvas.draw_line(p1, p2, Color(0.0, 0.0, 0.0, fade), 1.0)

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
			_fx._draw_normal_pass(self)
