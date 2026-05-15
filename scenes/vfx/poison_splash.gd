# scenes/vfx/poison_splash.gd
# 시전자→타겟 독 공격 VFX — ui_sample/vfx/Poison Attack VFX.html 재현 (DoT 숫자 제외).
# battle_scene이 poison damage_type 공격 시 .new() → add_child → play(caster, target).
# 노드는 position (0,0)으로 add_child해야 한다 (좌표를 global로 받아 그대로 그림).
# 어두운 독가스는 가산 블렌드로 안 보이므로 가스·물방울·거품(일반)·불씨·헤일로(가산) 2레이어로 그린다.
extends Node2D

# 파티클 갯수 — GameSettings.particle_count_scale 적용 (하/중/상 = 0.25/0.5/1.0배)
func _pcount(n: int) -> int:
	var gs := get_node_or_null("/root/GameSettings")
	return n if gs == null else maxi(1, int(round(n * gs.particle_count_scale())))

const COL_HOT     := Color(0.910, 1.0, 0.690)   # #e8ffb0 — 연두 코어
const COL_MID     := Color(0.722, 1.0, 0.361)   # #b8ff5c — 독성 녹색
const COL_DEEP    := Color(0.227, 0.541, 0.110) # #3a8a1c — 진녹색
const COL_GAS     := Color(0.627, 0.863, 0.314) # rgba(160,220,80) — 독가스
const COL_DRIP    := Color(0.549, 0.824, 0.196) # rgba(140,210,50) — 독액
const COL_DRIP_HL := Color(0.863, 1.0, 0.627)   # rgba(220,255,160) — 독액 하이라이트
const COL_FLASK   := Color(0.608, 0.847, 0.290) # #9bd84a — 플라스크 본체
const COL_CORK    := Color(0.353, 0.227, 0.094) # #5a3a18 — 코르크
const COL_SPARK   := Color(0.863, 1.0, 0.549)   # rgba(220,255,140) — 불씨
const COL_EYE     := Color(0.04, 0.10, 0.02)    # #0a1a04 — 해골 눈

# 크기/타이밍 — 이 상수만 만지면 된다.
const ORB_CHARGE_START := 0.12  # 차지 구체 시작
const ORB_CHARGE_FULL  := 0.36  # 차지 완료
const CHARGE_TIME      := 0.3   # 차지 시간(s)
const FLASK_FLIGHT     := 0.5   # 플라스크 비행 시간(s)
const IMPACT_DELAY     := CHARGE_TIME + FLASK_FLIGHT  # battle_manager 동기화용
const ARC_HEIGHT       := 100.0 # 포물선 최고점 높이(px)
const POISON_TIME      := 1.5   # 명중 후 잔류 독 지속(s)
const PSPEED           := 60.0  # HTML(dt*0.06) → Godot(delta*60) 환산 계수

## 플라스크 명중 순간 — 화면 흔들림·SFX 요청 (battle_scene이 수신)
signal screen_effect

var _caster := Vector2.ZERO
var _target := Vector2.ZERO
var _charge_orb: Sprite2D
var _smoke_layer: Node2D  # 일반 블렌드 — 가스·물방울·거품·웅덩이·플라스크
var _glow_layer: Node2D   # 가산 블렌드 — 불씨·헤일로·해골
var _flask_pts: PackedVector2Array  # 단위 플라스크 윤곽
var _particles: Array = []  # [{pos, vel, life, max_life, r, kind, grav}]
var _proj_t := -1.0       # <0 = 비활성, 0~1 = 플라스크 비행
var _proj_rot := 0.0      # 플라스크 회전 각도
var _puddle_age := -1.0   # <0 = 비활성, 경과 초 (독 웅덩이)
var _skull_age := -1.0    # <0 = 비활성, 경과 초 (해골 아이콘)
var _ambient_timer := 0.0 # 잔류 독 남은 시간
var _elapsed := 0.0       # 해골 부유용 누적 시간

# ── 포물선 투사체 위치 (autoload 비의존 static — 단위 테스트 가능) ──
static func proj_pos(a: Vector2, b: Vector2, t: float, arc_h: float) -> Vector2:
	return a.lerp(b, t) + Vector2(0.0, -sin(t * PI) * arc_h)

# ── 단위 플라스크 윤곽 (autoload 비의존 static) ──
# HTML drawFlask 의 직선 3 + 큐빅 베지어 2개를 샘플. 중심 (0,0) 기준.
static func flask_shape() -> PackedVector2Array:
	var p := PackedVector2Array([Vector2(-5, -10), Vector2(5, -10), Vector2(5, -4)])
	var beziers := [
		[Vector2(5, -4), Vector2(12, 2), Vector2(12, 12), Vector2(0, 14)],
		[Vector2(0, 14), Vector2(-12, 12), Vector2(-12, 2), Vector2(-5, -4)],
	]
	for bz in beziers:
		var a: Vector2 = bz[0]
		var c1: Vector2 = bz[1]
		var c2: Vector2 = bz[2]
		var d: Vector2 = bz[3]
		for i in range(1, 7):
			var t := float(i) / 6.0
			var u := 1.0 - t
			p.append(u * u * u * a + 3.0 * u * u * t * c1 + 3.0 * u * t * t * c2 + t * t * t * d)
	return p

# 라디얼 그라데이션 구체 텍스처 — orb.png는 배경이 불투명해 검은 박스로 보이므로 코드 생성.
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
	_flask_pts = flask_shape()
	var orb_tex := _make_orb_tex(COL_HOT, COL_MID, COL_DEEP)

	# 가스·물방울 레이어 — 일반 블렌드, 아래
	_smoke_layer = _DrawLayer.new()
	_smoke_layer.setup(self, false)
	add_child(_smoke_layer)

	_charge_orb = Sprite2D.new()
	_charge_orb.texture = orb_tex
	_charge_orb.modulate = Color(1, 1, 1, 0.0)  # 알파만 제어 — 색은 텍스처가 가짐
	_charge_orb.scale = Vector2(ORB_CHARGE_START, ORB_CHARGE_START)
	add_child(_charge_orb)

	# 불씨·헤일로·해골 레이어 — 가산 블렌드, 위
	_glow_layer = _DrawLayer.new()
	_glow_layer.setup(self, true)
	add_child(_glow_layer)

# caster_pos / target_pos 는 global 좌표 (노드가 (0,0)에 있다는 전제)
func play(caster_pos: Vector2, target_pos: Vector2) -> void:
	_caster = caster_pos
	_target = target_pos
	_charge_orb.position = caster_pos
	_run()

func _run() -> void:
	# 1) 차지 — 시전자 손의 부글거리는 독 구체 (0.6s)
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_charge_orb, "modulate:a", 1.0, 0.18)
	tw.parallel().tween_property(_charge_orb, "scale", Vector2(ORB_CHARGE_FULL, ORB_CHARGE_FULL), CHARGE_TIME)
	set_process(true)
	await get_tree().create_timer(CHARGE_TIME).timeout
	if not is_inside_tree():
		return
	# 2) 발사 — 회전하는 독 플라스크
	var tw2 := create_tween()
	tw2.tween_property(_charge_orb, "modulate:a", 0.0, 0.12)
	_proj_t = 0.0
	# 3) 비행·명중·잔류는 _process에서. 정리.
	await get_tree().create_timer(FLASK_FLIGHT + POISON_TIME + 1.5).timeout
	if is_inside_tree():
		queue_free()

func _mk(pos: Vector2, vel: Vector2, max_life: float, r: float, kind: String, grav: float) -> Dictionary:
	return {"pos": pos, "vel": vel, "life": 0.0, "max_life": max_life, "r": r, "kind": kind, "grav": grav}

# 플라스크 꽁무니 — 흘러내리는 독액 + 피어오르는 가스
func _spawn_trail(pos: Vector2) -> void:
	_particles.append(_mk(pos + Vector2(randf_range(-3.0, 3.0), randf_range(-3.0, 3.0)),
		Vector2(randf_range(-0.2, 0.2), 0.2 + randf() * 0.4),
		0.7 + randf() * 0.5, 4.0 + randf() * 5.0, "drip", 0.04))
	if randf() < 0.7:
		_particles.append(_mk(pos + Vector2(randf_range(-2.0, 2.0), randf_range(-2.0, 2.0)),
			Vector2(randf_range(-0.15, 0.15), -0.2 - randf() * 0.3),
			0.9 + randf() * 0.5, 8.0 + randf() * 8.0, "gas", -0.005))

# 명중 폭발 — 독액 + 독가스 + 불씨
func _spawn_splash(pos: Vector2) -> void:
	for _i in range(_pcount(40)):
		var a := randf() * TAU
		var sp := 1.0 + randf() * 4.0
		_particles.append(_mk(pos, Vector2(cos(a) * sp, sin(a) * sp * 0.6 - 1.2),
			0.8 + randf() * 0.6, 3.0 + randf() * 5.0, "drip", 0.06))
	for _i in range(_pcount(50)):
		var a := randf() * TAU
		var sp := 0.6 + randf() * 2.5
		_particles.append(_mk(pos, Vector2(cos(a) * sp, sin(a) * sp * 0.6 - 0.4),
			1.4 + randf() * 0.9, 18.0 + randf() * 20.0, "gas", -0.008))
	for _i in range(_pcount(24)):
		var a := randf() * TAU
		var sp := 1.0 + randf() * 3.0
		_particles.append(_mk(pos, Vector2(cos(a) * sp, sin(a) * sp - 0.6),
			1.0 + randf() * 0.7, 1.4 + randf() * 1.2, "spark", 0.0))

# 잔류 — 명중 후 타겟 주위의 독가스·거품·떨어지는 독액
func _spawn_ambient() -> void:
	if randf() < 0.7:
		_particles.append(_mk(_target + Vector2(randf_range(-35.0, 35.0), randf_range(25.0, 55.0)),
			Vector2(randf_range(-0.15, 0.15), -0.4 - randf() * 0.5),
			1.6 + randf() * 0.8, 12.0 + randf() * 12.0, "gas", -0.005))
	if randf() < 0.3:
		_particles.append(_mk(_target + Vector2(randf_range(-30.0, 30.0), randf_range(40.0, 70.0)),
			Vector2(randf_range(-0.1, 0.1), -0.6 - randf() * 0.7),
			0.9 + randf() * 0.5, 3.0 + randf() * 4.0, "bubble", 0.0))
	if randf() < 0.2:
		_particles.append(_mk(_target + Vector2(randf_range(-30.0, 30.0), randf_range(-15.0, 15.0)),
			Vector2(randf_range(-0.1, 0.1), 0.5 + randf() * 0.4),
			0.9 + randf() * 0.4, 2.4 + randf() * 1.8, "drip", 0.05))

func _process(delta: float) -> void:
	_elapsed += delta

	# 플라스크 비행 — 회전 + 꽁무니 trail
	if _proj_t >= 0.0:
		_proj_t += delta / FLASK_FLIGHT
		_proj_rot += delta * 10.8
		_spawn_trail(proj_pos(_caster, _target, clampf(_proj_t, 0.0, 1.0), ARC_HEIGHT))
		if _proj_t >= 1.0:
			_on_impact()

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
		alive.append(p)
	_particles = alive

	# 잔류 독 — 명중 후 POISON_TIME 동안 지속 생성
	if _ambient_timer > 0.0:
		_ambient_timer -= delta
		_spawn_ambient()

	# 독 웅덩이 / 해골 진행
	if _puddle_age >= 0.0:
		_puddle_age += delta
	if _skull_age >= 0.0:
		_skull_age += delta

	_smoke_layer.queue_redraw()
	_glow_layer.queue_redraw()

func _on_impact() -> void:
	_proj_t = -1.0
	_spawn_splash(_target)
	_puddle_age = 0.0
	_skull_age = 0.0
	_ambient_timer = POISON_TIME
	screen_effect.emit()

# ── 그리기 패스 — _DrawLayer 가 블렌드 모드별로 호출 ──
func _draw_smoke_pass(canvas: CanvasItem) -> void:
	# 독 웅덩이 (타겟 발 아래, 가로로 퍼짐)
	if _puddle_age >= 0.0:
		var grow: float = clampf(_puddle_age / 1.1, 0.0, 1.0)
		var fade := 1.0
		if _puddle_age > POISON_TIME:
			fade = clampf(1.0 - (_puddle_age - POISON_TIME) / 0.5, 0.0, 1.0)
		if fade > 0.0:
			var pc := _target + Vector2(0.0, 72.0)
			var pud := PackedVector2Array()
			for i in range(22):
				var ang := TAU * float(i) / 22.0
				pud.append(pc + Vector2(cos(ang) * 76.0 * grow, sin(ang) * 17.0))
			canvas.draw_colored_polygon(pud, Color(COL_DEEP, 0.6 * fade))

	# 독가스
	for p in _particles:
		if p["kind"] != "gas":
			continue
		var k: float = p["life"] / p["max_life"]
		var a: float = (1.0 - k) * 0.4
		var r: float = p["r"] * (1.0 + k * 1.4)
		canvas.draw_circle(p["pos"], r, Color(COL_GAS, a))

	# 독액 방울 (몸 + 하이라이트)
	for p in _particles:
		if p["kind"] != "drip":
			continue
		var a: float = 1.0 - p["life"] / p["max_life"]
		canvas.draw_circle(p["pos"], p["r"] * 0.85, Color(COL_DRIP, 0.9 * a))
		canvas.draw_circle(p["pos"] + Vector2(-p["r"] * 0.2, -p["r"] * 0.4),
			p["r"] * 0.3, Color(COL_DRIP_HL, 0.7 * a))

	# 거품 (채움 + 외곽 + 하이라이트)
	for p in _particles:
		if p["kind"] != "bubble":
			continue
		var a: float = 1.0 - p["life"] / p["max_life"]
		canvas.draw_circle(p["pos"], p["r"], Color(COL_DRIP, 0.25 * a))
		canvas.draw_arc(p["pos"], p["r"], 0.0, TAU, 16, Color(COL_DRIP_HL, 0.7 * a), 1.0, true)
		canvas.draw_circle(p["pos"] + Vector2(-p["r"] * 0.35, -p["r"] * 0.35),
			p["r"] * 0.3, Color(1, 1, 1, 0.7 * a))

	# 플라스크 투사체 본체 (회전)
	if _proj_t >= 0.0:
		var pp := proj_pos(_caster, _target, clampf(_proj_t, 0.0, 1.0), ARC_HEIGHT)
		var body := PackedVector2Array()
		for pt in _flask_pts:
			body.append(pp + pt.rotated(_proj_rot))
		canvas.draw_colored_polygon(body, COL_FLASK)
		# 코르크 (회전 사각)
		var cork_local := [Vector2(-3.5, -13), Vector2(3.5, -13), Vector2(3.5, -10), Vector2(-3.5, -10)]
		var cork := PackedVector2Array()
		for cl in cork_local:
			cork.append(pp + (cl as Vector2).rotated(_proj_rot))
		canvas.draw_colored_polygon(cork, COL_CORK)

	# 해골 아이콘 (타겟 위에 떠올라 부유) — 검은 눈·코가 가산에선 안 보이므로 일반 블렌드 레이어에 그림
	if _skull_age >= 0.0:
		_draw_skull(canvas)

func _draw_glow_pass(canvas: CanvasItem) -> void:
	# 불씨
	for p in _particles:
		if p["kind"] != "spark":
			continue
		var a: float = 1.0 - p["life"] / p["max_life"]
		canvas.draw_circle(p["pos"], p["r"], Color(COL_SPARK, a))

	# 플라스크 헤일로
	if _proj_t >= 0.0:
		var pp := proj_pos(_caster, _target, clampf(_proj_t, 0.0, 1.0), ARC_HEIGHT)
		canvas.draw_circle(pp, 28.0, Color(COL_MID, 0.28))

func _draw_skull(canvas: CanvasItem) -> void:
	var pop: float = clampf(_skull_age / 0.5, 0.0, 1.0)
	var fade := 1.0
	if _skull_age > POISON_TIME:
		fade = clampf(1.0 - (_skull_age - POISON_TIME) / 0.4, 0.0, 1.0)
	var a: float = pop * fade
	if a <= 0.0:
		return
	var sc: float = lerpf(0.4, 1.0, pop)
	var bob: float = sin(_skull_age * 2.85) * 6.0
	var c := _target + Vector2(0.0, -120.0 + bob)
	# 두개골 (원) + 턱 (사각)
	canvas.draw_circle(c, 13.0 * sc, Color(COL_HOT, 0.9 * a))
	canvas.draw_rect(Rect2(c.x - 7.0 * sc, c.y + 7.0 * sc, 14.0 * sc, 7.0 * sc), Color(COL_HOT, 0.9 * a))
	# 눈구멍 2개
	canvas.draw_circle(c + Vector2(-5.0, 0.0) * sc, 3.0 * sc, Color(COL_EYE, a))
	canvas.draw_circle(c + Vector2(5.0, 0.0) * sc, 3.0 * sc, Color(COL_EYE, a))
	# 코 (마름모)
	var nose := PackedVector2Array([
		c + Vector2(0.0, 3.0) * sc, c + Vector2(2.5, 6.5) * sc,
		c + Vector2(0.0, 10.0) * sc, c + Vector2(-2.5, 6.5) * sc])
	canvas.draw_colored_polygon(nose, Color(COL_EYE, a))

# ── 블렌드 모드가 다른 두 그리기 레이어 ──
# 어두운 독가스는 가산이면 안 보이므로 일반 블렌드, 불씨·헤일로는 글로우용 가산 블렌드.
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
