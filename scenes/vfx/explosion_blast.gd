# scenes/vfx/explosion_blast.gd
# 시전자→타겟 폭발 공격 VFX — ui_sample/vfx/Explosion Attack VFX.html 재현 (데미지 숫자 제외).
# battle_scene이 explosive damage_type 공격 시 .new() → add_child → play(caster, target).
# 노드는 position (0,0)으로 add_child해야 한다 (좌표를 global로 받아 그대로 그림).
# 어두운 연기·먼지는 일반 블렌드, 불꽃·불씨·충격파는 가산 블렌드 — 2레이어로 그린다.
extends Node2D

const COL_HOT   := Color(1.0, 0.965, 0.8)     # #fff6cc — 흰노랑 코어
const COL_MID   := Color(1.0, 0.604, 0.227)   # #ff9a3a — 주황
const COL_DEEP  := Color(0.847, 0.227, 0.094) # #d83a18 — 진홍
const COL_WARN  := Color(1.0, 0.227, 0.227)   # #ff3a3a — 조준 경고
const COL_SMOKE := Color(0.196, 0.125, 0.086) # rgba(50,32,22) — 폭연
const COL_DUST  := Color(0.706, 0.510, 0.314) # rgba(180,130,80) — 흙먼지
const COL_CHUNK := Color(0.392, 0.275, 0.157) # rgba(100,70,40) — 파편

# 크기/타이밍 — 이 상수만 만지면 된다.
const BOMB_FLIGHT   := 0.55  # 폭탄 포물선 비행 시간(s)
const IMPACT_DELAY  := BOMB_FLIGHT  # battle_manager 동기화용 (차지 없음, 던지자마자 비행)
const ARC_HEIGHT    := 180.0 # 포물선 최고점 높이(px)
const SMOKE_TIME    := 0.8   # 폭발 후 잔류 연기 지속(s)
const BLAST_SCALE   := 0.4   # 폭발 파티클·충격파·분화구 크기 배율
const PSPEED        := 60.0  # HTML(dt*0.06) → Godot(delta*60) 환산 계수

## 폭발 순간 — 화면 플래시·흔들림·SFX·피격 피드백 요청 (battle_scene이 수신)
signal screen_effect

var _caster := Vector2.ZERO
var _target := Vector2.ZERO
var _smoke_layer: Node2D  # 일반 블렌드 — 연기·먼지·파편·분화구·폭탄·레티클
var _fire_layer: Node2D   # 가산 블렌드 — 불꽃·불씨·충격파
var _particles: Array = []  # [{pos, vel, life, max_life, r, kind, grav, rot, spin}]
var _bomb_t := -1.0       # <0 = 비활성, 0~1 = 폭탄 비행
var _bomb_rot := 0.0      # 폭탄 회전 각도
var _reticle_age := -1.0  # <0 = 비활성, 경과 초 (조준 경고)
var _crater_age := -1.0   # <0 = 비활성, 경과 초 (분화구)
var _shock_life := -1.0   # <0 = 비활성, 0~1 = 큰 충격파
var _shock2_life := -1.0  # <0 = 비활성, 0~1 = 작은 충격파
var _smoke_timer := 0.0   # 잔류 연기 남은 시간

# ── 포물선 투사체 위치 (autoload 비의존 static — 단위 테스트 가능) ──
static func proj_pos(a: Vector2, b: Vector2, t: float, arc_h: float) -> Vector2:
	return a.lerp(b, t) + Vector2(0.0, -sin(t * PI) * arc_h)

func _ready() -> void:
	set_process(false)
	# 연기·먼지·파편 레이어 — 일반 블렌드, 아래
	_smoke_layer = _DrawLayer.new()
	_smoke_layer.setup(self, false)
	add_child(_smoke_layer)
	# 불꽃·불씨·충격파 레이어 — 가산 블렌드, 위
	_fire_layer = _DrawLayer.new()
	_fire_layer.setup(self, true)
	add_child(_fire_layer)

# caster_pos / target_pos 는 global 좌표 (노드가 (0,0)에 있다는 전제)
func play(caster_pos: Vector2, target_pos: Vector2) -> void:
	_caster = caster_pos + Vector2(0.0, -30.0)
	_target = target_pos
	_run()

func _run() -> void:
	# 1) 폭탄 투척 — 포물선 비행 (0.55s)
	_bomb_t = 0.0
	_reticle_age = 0.0
	set_process(true)
	await get_tree().create_timer(BOMB_FLIGHT).timeout
	if not is_inside_tree():
		return
	# 2) 착탄 즉시 폭발 (대기 없음)
	_bomb_t = -1.0
	_detonate()
	# 4) 잔류 연기·페이드는 _process에서. 정리.
	await get_tree().create_timer(SMOKE_TIME + 1.5).timeout
	if is_inside_tree():
		queue_free()

func _mk(pos: Vector2, vel: Vector2, max_life: float, r: float, kind: String,
		grav: float, rot: float = 0.0, spin: float = 0.0) -> Dictionary:
	return {"pos": pos, "vel": vel, "life": 0.0, "max_life": max_life, "r": r,
		"kind": kind, "grav": grav, "rot": rot, "spin": spin}

# 대폭발 — 흰 코어 + 화염구 + 불꽃 + 불씨 + 흙먼지 + 버섯구름 연기 + 파편
func _spawn_fireball(pos: Vector2) -> void:
	var bs := BLAST_SCALE
	for _i in range(10):
		var a := randf() * TAU
		var sp := 1.0 + randf() * 3.0
		_particles.append(_mk(pos, Vector2(cos(a) * sp, sin(a) * sp - 1.0) * bs,
			0.2 + randf() * 0.2, (18.0 + randf() * 16.0) * bs, "core", -0.01))
	for _i in range(50):
		var a := randf() * TAU
		var sp := 2.0 + randf() * 7.0
		_particles.append(_mk(pos, Vector2(cos(a) * sp, sin(a) * sp * 0.85 - 2.0) * bs,
			0.7 + randf() * 0.7, (18.0 + randf() * 30.0) * bs, "fireball", -0.025))
	for _i in range(30):
		var a := randf() * TAU
		var sp := 4.0 + randf() * 8.0
		_particles.append(_mk(pos, Vector2(cos(a) * sp, sin(a) * sp * 0.7 - 3.0) * bs,
			0.4 + randf() * 0.5, (8.0 + randf() * 14.0) * bs, "flame", -0.015))
	for _i in range(70):
		var a := randf() * TAU
		var sp := 3.0 + randf() * 11.0
		_particles.append(_mk(pos, Vector2(cos(a) * sp, sin(a) * sp - 2.0) * bs,
			1.0 + randf() * 1.1, (1.4 + randf() * 1.8) * bs, "ember", 0.06))
	for _i in range(35):
		var a := randf() * TAU
		var sp := 2.0 + randf() * 5.0
		_particles.append(_mk(pos + Vector2(randf_range(-15.0, 15.0), 20.0 + randf_range(-4.0, 4.0)) * bs,
			Vector2(cos(a) * sp, sin(a) * sp * 0.3 - 0.5 - randf() * 1.2) * bs,
			1.6 + randf() * 1.2, (24.0 + randf() * 22.0) * bs, "dust", -0.005))
	for _i in range(25):
		var a := -PI / 2.0 + randf_range(-0.45, 0.45)
		var sp := 1.2 + randf() * 2.4
		_particles.append(_mk(pos + Vector2(randf_range(-20.0, 20.0), -10.0) * bs,
			Vector2(cos(a) * sp, sin(a) * sp) * bs,
			2.2 + randf() * 1.5, (34.0 + randf() * 30.0) * bs, "smoke", -0.018))
	for _i in range(15):
		var a := -PI / 2.0 + randf_range(-PI / 2.0, PI / 2.0)
		var sp := 4.0 + randf() * 8.0
		_particles.append(_mk(pos, Vector2(cos(a) * sp, sin(a) * sp - 2.0) * bs,
			1.1 + randf() * 0.9, (3.0 + randf() * 5.0) * bs, "chunk", 0.35,
			randf() * TAU, randf_range(-0.4, 0.4)))

func _spawn_ambient_smoke() -> void:
	_particles.append(_mk(_target + Vector2(randf_range(-30.0, 30.0), -20.0) * BLAST_SCALE,
		Vector2(randf_range(-0.4, 0.4), -0.6 - randf() * 0.7) * BLAST_SCALE,
		2.0 + randf() * 1.2, (20.0 + randf() * 18.0) * BLAST_SCALE, "smoke", -0.01))

func _process(delta: float) -> void:
	# 폭탄 비행 (회전)
	if _bomb_t >= 0.0 and _bomb_t < 1.0:
		_bomb_t += delta / BOMB_FLIGHT
		_bomb_rot += delta * 9.4

	# 레티클 / 분화구 / 충격파 진행
	if _reticle_age >= 0.0:
		_reticle_age += delta
	if _crater_age >= 0.0:
		_crater_age += delta
	if _shock_life >= 0.0:
		_shock_life += delta / 0.75
	if _shock2_life >= 0.0:
		_shock2_life += delta / 0.55

	# 잔류 연기
	if _smoke_timer > 0.0:
		_smoke_timer -= delta
		if randf() < 0.6:
			_spawn_ambient_smoke()

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
		if p["kind"] == "chunk":
			p["rot"] += p["spin"] * delta * PSPEED
		alive.append(p)
	_particles = alive

	_smoke_layer.queue_redraw()
	_fire_layer.queue_redraw()

func _detonate() -> void:
	_reticle_age = -1.0
	_spawn_fireball(_target)
	_crater_age = 0.0
	_shock_life = 0.0
	_shock2_life = 0.0
	_smoke_timer = SMOKE_TIME
	screen_effect.emit()

# fireball/flame 의 수명별 색 (alpha 포함)
func _fire_color(kind: String, k: float) -> Color:
	if kind == "core":
		return Color(1.0, 0.980, 0.902, 0.95)
	if kind == "fireball":
		if k < 0.2:
			return Color(1.0, 0.980, 0.863, 0.95)
		elif k < 0.5:
			return Color(1.0, 0.588, 0.235, 0.8)
		return Color(0.863, 0.235, 0.078, 0.55)
	if k < 0.3:
		return Color(1.0, 0.902, 0.667, 0.9)
	elif k < 0.6:
		return Color(1.0, 0.549, 0.196, 0.7)
	return Color(0.706, 0.157, 0.059, 0.45)

# ── 그리기 패스 — _DrawLayer 가 블렌드 모드별로 호출 ──
func _draw_smoke_pass(canvas: CanvasItem) -> void:
	# 분화구 (타겟 발 아래)
	if _crater_age >= 0.0:
		var grow: float = clampf(_crater_age / 0.4, 0.0, 1.0)
		var cc := _target + Vector2(0.0, 44.0)
		var crater := PackedVector2Array()
		for i in range(28):
			var ang := TAU * float(i) / 28.0
			crater.append(cc + Vector2(cos(ang) * 140.0 * grow * BLAST_SCALE, sin(ang) * 22.0 * grow * BLAST_SCALE))
		canvas.draw_colored_polygon(crater, Color(0.063, 0.039, 0.020, 0.85))

	# 폭연 + 흙먼지
	for p in _particles:
		var kind: String = p["kind"]
		if kind != "smoke" and kind != "dust":
			continue
		var k: float = p["life"] / p["max_life"]
		var base_a: float = 0.45 if kind == "smoke" else 0.4
		var a: float = (1.0 - k) * base_a
		var r: float = p["r"] * (1.0 + k * 1.5)
		var col := COL_SMOKE if kind == "smoke" else COL_DUST
		canvas.draw_circle(p["pos"], r, Color(col, a))

	# 파편 (회전 사각형)
	for p in _particles:
		if p["kind"] != "chunk":
			continue
		var a: float = (1.0 - p["life"] / p["max_life"]) * 0.95
		var r: float = p["r"]
		var fwd := Vector2(cos(p["rot"]), sin(p["rot"]))
		var side := Vector2(-fwd.y, fwd.x)
		canvas.draw_colored_polygon(PackedVector2Array([
			p["pos"] + fwd * -r + side * (-r * 0.7), p["pos"] + fwd * r + side * (-r * 0.7),
			p["pos"] + fwd * r + side * (r * 0.7), p["pos"] + fwd * -r + side * (r * 0.7),
		]), Color(COL_CHUNK, a))

	# 폭탄 (비행 중)
	if _bomb_t >= 0.0 and _bomb_t < 1.0:
		var bp := proj_pos(_caster, _target, _bomb_t, ARC_HEIGHT)
		canvas.draw_circle(bp, 11.0, Color(0.255, 0.255, 0.282))
		canvas.draw_circle(bp + Vector2(-3.0, -3.0), 4.0, Color(0.42, 0.42, 0.45))

	# 조준 경고 레티클 (착탄 전 ~ 폭발 전, 깜빡임)
	if _reticle_age >= 0.0:
		var blink := 1.0 if fmod(_reticle_age, 0.25) < 0.125 else 0.4
		var rc := _target + Vector2(0.0, 20.0)
		canvas.draw_arc(rc, 74.0, 0.0, TAU, 36, Color(COL_WARN, 0.85 * blink), 2.0, true)
		canvas.draw_arc(rc, 50.0, 0.0, TAU, 28, Color(COL_WARN, 0.6 * blink), 1.5, true)
		for q in range(4):
			var d := Vector2(cos(deg_to_rad(90.0 * float(q))), sin(deg_to_rad(90.0 * float(q))))
			canvas.draw_line(rc + d * 56.0, rc + d * 84.0, Color(COL_WARN, 0.85 * blink), 2.0)
		canvas.draw_circle(rc, 4.0, Color(COL_WARN, blink))

func _draw_fire_pass(canvas: CanvasItem) -> void:
	# 폭탄 도화선 불꽃 (비행 중)
	if _bomb_t >= 0.0 and _bomb_t < 1.0:
		var bp := proj_pos(_caster, _target, _bomb_t, ARC_HEIGHT)
		var fuse_pulse := 3.0 + 1.5 * sin(_bomb_rot * 4.0)
		canvas.draw_circle(bp + Vector2(0.0, -16.0), fuse_pulse, Color(COL_HOT, 0.9))

	# 흰 코어 / 화염구 / 불꽃
	for p in _particles:
		var kind: String = p["kind"]
		if kind != "core" and kind != "fireball" and kind != "flame":
			continue
		var k: float = p["life"] / p["max_life"]
		var c := _fire_color(kind, k)
		var r: float = p["r"] * (1.0 + k * 0.7)
		canvas.draw_circle(p["pos"], r, Color(c.r, c.g, c.b, c.a * (1.0 - k)))

	# 불씨 (밝은 점 + 가로 streak)
	for p in _particles:
		if p["kind"] != "ember":
			continue
		var k: float = p["life"] / p["max_life"]
		var a: float = 1.0 - k
		var col := Color(1.0, 0.824 - 0.431 * k, 0.392 - 0.314 * k, a)
		var pr: float = p["r"]
		canvas.draw_circle(p["pos"], pr, col)
		canvas.draw_rect(Rect2(p["pos"].x - pr * 2.5, p["pos"].y - 0.3, pr * 5.0, 0.6), col)

	# 충격파 링 2겹
	if _shock_life >= 0.0 and _shock_life <= 1.0:
		var rad: float = (30.0 + _shock_life * 520.0) * BLAST_SCALE
		var a: float = (1.0 - _shock_life) * 0.9
		canvas.draw_arc(_target, rad, 0.0, TAU, 56, Color(COL_MID, a), 1.0 + 4.0 * (1.0 - _shock_life), true)
	if _shock2_life >= 0.0 and _shock2_life <= 1.0:
		var rad2: float = (30.0 + _shock2_life * 300.0) * BLAST_SCALE
		var a2: float = (1.0 - _shock2_life) * 0.8
		canvas.draw_arc(_target, rad2, 0.0, TAU, 48, Color(COL_HOT, a2), 1.0 + 3.0 * (1.0 - _shock2_life), true)

# ── 블렌드 모드가 다른 두 그리기 레이어 ──
# 어두운 폭연·먼지는 가산이면 안 보이므로 일반 블렌드, 불꽃·불씨는 글로우용 가산 블렌드.
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
