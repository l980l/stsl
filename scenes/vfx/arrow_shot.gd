# scenes/vfx/arrow_shot.gd
# 시전자→타겟 화살 투사체 VFX — ui_sample/vfx/Projectile Attack VFX.html 재현 (데미지 숫자 제외).
# battle_scene이 projectile damage_type 공격 시 .new() → add_child → play(caster, target).
# 노드는 position (0,0)으로 add_child해야 한다 (좌표를 global로 받아 그대로 그림).
# 화살·먼지·파편은 또렷한 일반 블렌드, 트레일·스파크·조준선·발사섬광은 가산 블렌드 — 2레이어로 그린다.
extends Node2D

const COL_HOT     := Color(1, 1, 1)             # 흰 코어
const COL_STEEL   := Color(0.812, 0.831, 0.867) # #cfd4dd — 화살촉
const COL_AIM     := Color(1.0, 0.251, 0.251)   # #ff4040 — 조준 레이저
const COL_FEATHER := Color(0.784, 0.220, 0.220) # #c83838 — 깃
const COL_SHAFT   := Color(0.761, 0.659, 0.471) # #c2a878 — 화살대
const COL_DUST    := Color(0.706, 0.706, 0.745) # rgba(180,180,190) — 먼지
const COL_SPARK   := Color(1.0, 0.902, 0.706)   # rgba(255,230,180) — 스파크

# 크기/타이밍 — 이 상수만 만지면 된다.
const DRAW_TIME   := 0.45  # 시위 당기기·조준 시간(s)
const FLIGHT_TIME := 0.3   # 화살 비행 시간(s)
const STUCK_TIME  := 1.5   # 타겟에 박힌 화살 유지 시간(s)
const ARROW_LEN   := 44.0  # 화살 길이(px)
const PSPEED      := 60.0  # HTML(dt*0.06) → Godot(delta*60) 환산 계수

## 화살 명중 순간 — 화면 플래시·흔들림·SFX·피격 피드백 요청 (battle_scene이 수신)
signal screen_effect

var _caster := Vector2.ZERO
var _target := Vector2.ZERO
var _normal_layer: Node2D  # 일반 블렌드 — 화살·먼지·파편·박힌 화살
var _glow_layer: Node2D    # 가산 블렌드 — 트레일·스파크·조준선·발사 섬광
var _particles: Array = []  # [{pos, vel, life, max_life, r, kind, grav, rot, spin}]
var _trail_pts: PackedVector2Array = PackedVector2Array()  # 화살 위치 히스토리
var _aim_t := -1.0       # <0 = 비활성, 경과 초 (조준 레이저)
var _arrow_t := -1.0     # <0 = 비활성, 0~1 = 화살 비행
var _muzzle_age := -1.0  # <0 = 비활성, 경과 초 (발사 섬광)
var _stuck_age := -1.0   # <0 = 비활성, 경과 초 (박힌 화살)
var _impacted := false
var _impact_ang := 0.0   # 명중 각도 (스파크·박힌 화살 방향)

# ── 화살 위치 (autoload 비의존 static — 단위 테스트 가능) ──
static func arrow_pos(a: Vector2, b: Vector2, t: float) -> Vector2:
	return a.lerp(b, clampf(t, 0.0, 1.0))

func _ready() -> void:
	set_process(false)
	# 화살·먼지·파편 레이어 — 일반 블렌드, 아래
	_normal_layer = _DrawLayer.new()
	_normal_layer.setup(self, false)
	add_child(_normal_layer)
	# 트레일·스파크·조준선 레이어 — 가산 블렌드, 위
	_glow_layer = _DrawLayer.new()
	_glow_layer.setup(self, true)
	add_child(_glow_layer)

# caster_pos / target_pos 는 global 좌표 (노드가 (0,0)에 있다는 전제)
func play(caster_pos: Vector2, target_pos: Vector2) -> void:
	_caster = caster_pos + Vector2(0.0, -20.0)  # 손 높이로 살짝 올림
	_target = target_pos
	_run()

func _run() -> void:
	# 1) 시위 당기기 + 조준 레이저 (0.45s)
	_aim_t = 0.0
	set_process(true)
	await get_tree().create_timer(DRAW_TIME).timeout
	if not is_inside_tree():
		return
	# 2) 발사 — 조준선 사라짐, 발사 섬광, 화살 비행 시작
	_aim_t = -1.0
	_muzzle_age = 0.0
	_arrow_t = 0.0
	# 3) 비행·명중·박힌 화살은 _process에서. 정리.
	await get_tree().create_timer(FLIGHT_TIME + STUCK_TIME + 1.0).timeout
	if is_inside_tree():
		queue_free()

func _mk(pos: Vector2, vel: Vector2, max_life: float, r: float, kind: String,
		grav: float, rot: float = 0.0, spin: float = 0.0) -> Dictionary:
	return {"pos": pos, "vel": vel, "life": 0.0, "max_life": max_life, "r": r,
		"kind": kind, "grav": grav, "rot": rot, "spin": spin}

# 명중 — 튕겨나가는 스파크 + 먼지 구름 + 작은 파편
func _spawn_impact(pos: Vector2, ang: float) -> void:
	for _i in range(22):
		var a := ang + PI + randf_range(-0.7, 0.7)
		var sp := 2.0 + randf() * 6.0
		_particles.append(_mk(pos, Vector2(cos(a) * sp, sin(a) * sp - 0.8),
			0.4 + randf() * 0.4, 1.0 + randf() * 1.3, "spark", 0.12))
	for _i in range(14):
		var a := ang + PI + randf_range(-0.5, 0.5)
		var sp := 0.5 + randf() * 1.8
		_particles.append(_mk(pos, Vector2(cos(a) * sp, sin(a) * sp * 0.6 - 0.4),
			0.6 + randf() * 0.5, 8.0 + randf() * 8.0, "dust", -0.008))
	for _i in range(6):
		var a := ang + PI + randf_range(-0.4, 0.4)
		var sp := 3.0 + randf() * 4.0
		_particles.append(_mk(pos, Vector2(cos(a) * sp, sin(a) * sp - 1.5),
			0.7 + randf() * 0.5, 2.0 + randf() * 2.0, "chip", 0.25,
			randf() * TAU, randf_range(-0.3, 0.3)))

func _process(delta: float) -> void:
	# 조준 레이저 / 발사 섬광 / 박힌 화살 진행
	if _aim_t >= 0.0:
		_aim_t += delta
	if _muzzle_age >= 0.0:
		_muzzle_age += delta
	if _stuck_age >= 0.0:
		_stuck_age += delta

	# 화살 비행 — 위치 히스토리(트레일) 갱신
	if _arrow_t >= 0.0 and _arrow_t < 1.0:
		_arrow_t += delta / FLIGHT_TIME
		_trail_pts.append(arrow_pos(_caster, _target, clampf(_arrow_t, 0.0, 1.0)))
		while _trail_pts.size() > 12:
			_trail_pts.remove_at(0)
		if _arrow_t >= 1.0 and not _impacted:
			_on_impact()
	elif _trail_pts.size() > 0:
		# 비행 종료 — 트레일 잔상 점차 소멸
		_trail_pts.remove_at(0)

	# 파티클 물리 (HTML frame() 포팅) — 수명 만료 시 제거
	var damp: float = pow(0.992, delta * 60.0)
	var alive: Array = []
	for p in _particles:
		p["life"] += delta
		if p["life"] >= p["max_life"]:
			continue
		p["pos"] += p["vel"] * delta * PSPEED
		p["vel"].y += p["grav"] * delta * PSPEED
		p["vel"] *= damp
		if p["kind"] == "chip":
			p["rot"] += p["spin"] * delta * PSPEED
		alive.append(p)
	_particles = alive

	_normal_layer.queue_redraw()
	_glow_layer.queue_redraw()

func _on_impact() -> void:
	_impacted = true
	_impact_ang = (_target - _caster).angle()
	_spawn_impact(_target, _impact_ang)
	_stuck_age = 0.0
	screen_effect.emit()

# ── 화살 모양 그리기 (대 + 촉 + 깃) ──
func _draw_arrow(canvas: CanvasItem, pos: Vector2, ang: float, alpha: float) -> void:
	var fwd := Vector2(cos(ang), sin(ang))
	var side := Vector2(-fwd.y, fwd.x)
	var l := ARROW_LEN
	# 화살대 (사각형) — 촉이 pos, 꽁무니가 -l
	canvas.draw_colored_polygon(PackedVector2Array([
		pos + fwd * -l + side * -1.2, pos + fwd * -8.0 + side * -1.2,
		pos + fwd * -8.0 + side * 1.2, pos + fwd * -l + side * 1.2,
	]), Color(COL_SHAFT, alpha))
	# 화살촉 (삼각형)
	canvas.draw_colored_polygon(PackedVector2Array([
		pos, pos + fwd * -8.0 + side * -3.5, pos + fwd * -8.0 + side * 3.5,
	]), Color(COL_STEEL, alpha))
	# 깃 (꽁무니 삼각 2개)
	canvas.draw_colored_polygon(PackedVector2Array([
		pos + fwd * -l + side * -2.0, pos + fwd * (-l + 8.0), pos + fwd * (-l - 3.0) + side * 5.0,
	]), Color(COL_FEATHER, alpha))
	canvas.draw_colored_polygon(PackedVector2Array([
		pos + fwd * -l + side * 2.0, pos + fwd * (-l + 8.0), pos + fwd * (-l - 3.0) + side * -5.0,
	]), Color(COL_FEATHER, alpha))

# ── 그리기 패스 — _DrawLayer 가 블렌드 모드별로 호출 ──
func _draw_normal_pass(canvas: CanvasItem) -> void:
	# 먼지 구름
	for p in _particles:
		if p["kind"] != "dust":
			continue
		var k: float = p["life"] / p["max_life"]
		var a: float = (1.0 - k) * 0.45
		var r: float = p["r"] * (1.0 + k * 1.4)
		canvas.draw_circle(p["pos"], r, Color(COL_DUST, a))
	# 작은 파편 (회전 사각형)
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
	# 비행 중 화살
	if _arrow_t >= 0.0 and _arrow_t < 1.0:
		var ap := arrow_pos(_caster, _target, clampf(_arrow_t, 0.0, 1.0))
		_draw_arrow(canvas, ap, (_target - _caster).angle(), 1.0)
	# 타겟에 박힌 화살
	if _stuck_age >= 0.0:
		var slide := clampf(_stuck_age / 0.18, 0.0, 1.0)
		var fade := 1.0
		if _stuck_age > STUCK_TIME:
			fade = clampf(1.0 - (_stuck_age - STUCK_TIME) / 0.4, 0.0, 1.0)
		if fade > 0.0:
			var fwd := Vector2(cos(_impact_ang), sin(_impact_ang))
			# 등장 시 살짝 밀려 들어옴 + 촉이 박혀 화살이 약간 앞으로 나와 보이게
			var spos := _target - fwd * (20.0 * (1.0 - slide)) + fwd * 24.0
			_draw_arrow(canvas, spos, _impact_ang, fade)

func _draw_glow_pass(canvas: CanvasItem) -> void:
	# 조준 레이저 (시전자 → 타겟, 시위 당기는 동안 길이가 자람)
	if _aim_t >= 0.0:
		var prog := clampf(_aim_t / (DRAW_TIME * 0.6), 0.0, 1.0)
		var laser_end := _caster.lerp(_target, prog)
		canvas.draw_line(_caster, laser_end, Color(COL_AIM, 0.85), 1.5)
		var dot_pulse := 4.0 + 2.0 * sin(_aim_t * 18.0)
		canvas.draw_circle(laser_end, dot_pulse, Color(COL_AIM, 0.9))

	# 발사 섬광 (시전자 손)
	if _muzzle_age >= 0.0 and _muzzle_age < 0.14:
		var u := _muzzle_age / 0.14
		var msc: float
		var ma: float
		if u < 0.4:
			msc = lerpf(0.3, 1.2, u / 0.4)
			ma = u / 0.4
		else:
			msc = lerpf(1.2, 0.9, (u - 0.4) / 0.6)
			ma = 1.0 - (u - 0.4) / 0.6
		canvas.draw_circle(_caster, 24.0 * msc, Color(COL_SPARK, 0.5 * ma))
		canvas.draw_circle(_caster, 13.0 * msc, Color(COL_HOT, ma))

	# 화살 트레일 (모션 블러 리본 — 3중 레이어)
	if _trail_pts.size() >= 2:
		canvas.draw_polyline(_trail_pts, Color(COL_HOT, 0.25), 10.0, true)
		canvas.draw_polyline(_trail_pts, Color(COL_HOT, 0.75), 4.0, true)
		canvas.draw_polyline(_trail_pts, Color(COL_HOT, 1.0), 1.5, true)

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

# ── 블렌드 모드가 다른 두 그리기 레이어 ──
# 화살·먼지·파편은 또렷한 일반 블렌드, 트레일·스파크·조준선은 글로우용 가산 블렌드.
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
