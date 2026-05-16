# scenes/vfx/charm_kiss.gd
# 시전자→타겟 매혹 공격 VFX — ui_sample/vfx/Charm Attack VFX.html 재현 (CHARMED 콜아웃 제외).
# battle_scene이 charm/enthrall 디버프 적용 시 .new() → add_child → play(caster, target).
# 노드는 position (0,0)으로 add_child해야 한다 (좌표를 global로 받아 그대로 그림).
# 분홍 연기는 가산 블렌드로 안 보이므로 연기·하트솔리드(일반)·헤일로/꽃잎/반짝임(가산) 2레이어로 그린다.
extends Node2D

# 파티클 갯수 — GameSettings.particle_count_scale 적용 (하/중/상 = 0.25/0.5/1.0배)
var _particle_scale_override: float = -1.0  # vfx_preview 3-way 비교용 (음수=GameSettings)

func _pcount(n: int) -> int:
	if _particle_scale_override > 0.0:
		return maxi(1, int(round(n * _particle_scale_override)))
	var gs := get_node_or_null("/root/GameSettings")
	return n if gs == null else maxi(1, int(round(n * gs.particle_count_scale())))


# ambient/trail 의 확률 spawn 에 사용 — _pcount 와 동일 스케일
func _scale() -> float:
	if _particle_scale_override > 0.0:
		return _particle_scale_override
	var gs := get_node_or_null("/root/GameSettings")
	return 1.0 if gs == null else gs.particle_count_scale()
const COL_HOT    := Color(1.0, 0.949, 0.976)   # #fff2f9 — 흰분홍 코어
const COL_MID    := Color(1.0, 0.604, 0.831)   # #ff9ad4 — 분홍
const COL_DEEP   := Color(0.902, 0.310, 0.651) # #e64fa6 — 진분홍
const COL_VIOLET := Color(0.769, 0.486, 1.0)   # #c47cff — 보라
const COL_SMOKE  := Color(1.0, 0.706, 0.863)   # rgba(255,180,220) — 분홍 연기

# 크기/타이밍 — 이 상수만 만지면 된다.
const CHARGE_TIME  := 0.35   # 차지 시간(s)
const PROJ_FLIGHT  := 0.6    # 키스 투사체 비행 시간(s)
const IMPACT_DELAY := CHARGE_TIME + PROJ_FLIGHT  # battle_manager 동기화용
const ARC_HEIGHT   := 50.0   # 포물선 최고점 높이(px)
const WOBBLE_AMP   := 22.0   # 비행 중 흔들림 진폭(px)
const CHARM_TIME   := 2.5    # 명중 후 매혹 잔류(s) — HTML 5.0초의 절반
const ORB_SIZE     := 36.0   # 차지 하트 구체 크기(px)
const PSPEED       := 60.0   # HTML(dt*0.06) → Godot(delta*60) 환산 계수

## 키스 명중 순간 — 화면 흔들림·SFX 요청 (battle_scene이 수신)
signal screen_effect

var _caster := Vector2.ZERO
var _target := Vector2.ZERO
# 매혹 오라 anchor — set_ground_anchor() 로 타겟 발 위치 지정.
var _ground_pos := Vector2.ZERO
var _has_ground: bool = false

func set_ground_anchor(pos: Vector2) -> void:
	_ground_pos = pos
	_has_ground = true
	if _ground_layer != null:
		_ground_layer.z_as_relative = false
		_ground_layer.z_index = int(pos.y) - 1

var _smoke_layer: Node2D  # 일반 블렌드 — 분홍 연기·하트 솔리드
var _glow_layer: Node2D   # 가산 블렌드 — 차지오브·헤일로·꽃잎·반짝임·투사체·나선
var _ground_layer: Node2D # 매혹 오라 (캐릭터 뒤로 z set)
var _heart_pts: PackedVector2Array  # 단위 하트 윤곽 (32점)
var _particles: Array = []  # [{pos, vel, life, max_life, size, rot, kind, grav, spin, tint}]
var _proj_t := -1.0       # <0 = 비활성, 0~1 = 투사체 비행
var _charge_t := -1.0     # <0 = 비활성, 0~1 = 차지 진행
var _shock_life := -1.0   # <0 = 비활성, 0~1 = 하트 충격파
var _spiral_age := -1.0   # <0 = 비활성, 경과 초 (최면 나선)
var _ambient_timer := 0.0 # 매혹 잔류 남은 시간
var _elapsed := 0.0       # 하트 흔들림·박동용 누적 시간

# ── 단위 하트 윤곽 32점 (autoload 비의존 static — 단위 테스트 가능) ──
# HTML drawHeart 의 4개 큐빅 베지어를 8점씩 샘플. 중심 (0,0), 크기 32 기준.
static func heart_unit() -> PackedVector2Array:
	var ctrl := [
		Vector2(0, 12), Vector2(-14, 4), Vector2(-18, -6), Vector2(-12, -12),
		Vector2(-12, -12), Vector2(-6, -18), Vector2(0, -14), Vector2(0, -8),
		Vector2(0, -8), Vector2(0, -14), Vector2(6, -18), Vector2(12, -12),
		Vector2(12, -12), Vector2(18, -6), Vector2(14, 4), Vector2(0, 12),
	]
	var p := PackedVector2Array()
	for seg in range(4):
		var a: Vector2 = ctrl[seg * 4]
		var b: Vector2 = ctrl[seg * 4 + 1]
		var c: Vector2 = ctrl[seg * 4 + 2]
		var d: Vector2 = ctrl[seg * 4 + 3]
		for i in range(8):
			var t := float(i) / 8.0
			var u := 1.0 - t
			p.append(u * u * u * a + 3.0 * u * u * t * b + 3.0 * u * t * t * c + t * t * t * d)
	return p

# ── 키스 투사체 위치 (autoload 비의존 static) ──
# 직선 보간 + 포물선 arc + sin 흔들림. t=0 → a, t=1 → b.
static func charm_proj_pos(a: Vector2, b: Vector2, t: float, arc_h: float, wob_amp: float) -> Vector2:
	var arc := -sin(t * PI) * arc_h
	var wob := sin(t * PI * 3.0) * wob_amp * sin(t * PI)
	return a.lerp(b, t) + Vector2(0.0, arc + wob)

func _ready() -> void:
	set_process(false)
	_heart_pts = heart_unit()

	# 매혹 오라 — 캐릭터 뒤로 z set, 가산 블렌드. 가장 먼저 add
	_ground_layer = _GroundLayer.new()
	_ground_layer.setup(self)
	add_child(_ground_layer)
	# 연기·하트 솔리드 레이어 — 일반 블렌드, 아래
	_smoke_layer = _DrawLayer.new()
	_smoke_layer.setup(self, false)
	add_child(_smoke_layer)

	# 헤일로·꽃잎·반짝임·투사체·나선 레이어 — 가산 블렌드, 위
	_glow_layer = _DrawLayer.new()
	_glow_layer.setup(self, true)
	add_child(_glow_layer)

# caster_pos / target_pos 는 global 좌표 (노드가 (0,0)에 있다는 전제)
func play(caster_pos: Vector2, target_pos: Vector2) -> void:
	_caster = caster_pos
	_target = target_pos
	_run()

func _run() -> void:
	# 1) 차지 — 시전자 손의 하트 구체 (0.7s)
	_charge_t = 0.0
	set_process(true)
	await get_tree().create_timer(CHARGE_TIME).timeout
	if not is_inside_tree():
		return
	# 2) 발사 — 하트 키스 투사체
	_charge_t = -1.0
	_proj_t = 0.0
	# 3) 비행·명중·잔류는 _process에서. 정리.
	await get_tree().create_timer(PROJ_FLIGHT + CHARM_TIME + 1.5).timeout
	if is_inside_tree():
		queue_free()

func _mk(pos: Vector2, vel: Vector2, max_life: float, size: float, kind: String,
		grav: float, rot: float = 0.0, spin: float = 0.0, tint: String = "rose") -> Dictionary:
	return {"pos": pos, "vel": vel, "life": 0.0, "max_life": max_life, "size": size,
		"rot": rot, "kind": kind, "grav": grav, "spin": spin, "tint": tint}

# 투사체 꽁무니 — 하트 + 반짝임 + 분홍 연기
func _spawn_trail(pos: Vector2) -> void:
	_particles.append(_mk(pos + _roff(10.0),
		Vector2(randf_range(-0.4, 0.4), -0.3 - randf() * 0.5),
		0.7 + randf() * 0.5, 8.0 + randf() * 8.0, "heart", 0.0, randf_range(-0.3, 0.3)))
	if randf() < 0.5 * _scale():
		_particles.append(_mk(pos,
			Vector2(randf_range(-0.6, 0.6), randf_range(-0.6, 0.6) - 0.2),
			0.6 + randf() * 0.5, 1.5 + randf() * 1.5, "sparkle", 0.0))
	_particles.append(_mk(pos + _roff(8.0),
		Vector2(randf_range(-0.25, 0.25), -0.1 - randf() * 0.3),
		0.9 + randf() * 0.6, 14.0 + randf() * 16.0, "smoke", 0.0))

# 명중 폭발 — 하트 + 꽃잎 + 반짝임 + 분홍 연기
func _spawn_impact_burst(pos: Vector2) -> void:
	for _i in range(_pcount(26)):
		var a := randf() * TAU
		var sp := 1.5 + randf() * 4.5
		var tn := "violet" if randf() < 0.3 else "rose"
		_particles.append(_mk(pos, Vector2(cos(a) * sp, sin(a) * sp * 0.85 - 1.0),
			1.4 + randf() * 0.8, 14.0 + randf() * 16.0, "heart", -0.012, randf_range(-0.4, 0.4), 0.0, tn))
	for _i in range(_pcount(40)):
		var a := randf() * TAU
		var sp := 1.0 + randf() * 3.0
		_particles.append(_mk(pos, Vector2(cos(a) * sp, sin(a) * sp * 0.7 - 0.6),
			1.6 + randf() * 0.9, 6.0 + randf() * 7.0, "petal", 0.02,
			randf_range(-0.4, 0.4), randf_range(-3.0, 3.0)))
	for _i in range(_pcount(60)):
		var a := randf() * TAU
		var sp := 1.0 + randf() * 5.0
		_particles.append(_mk(pos, Vector2(cos(a) * sp, sin(a) * sp - 0.5),
			1.0 + randf() * 0.7, 1.0 + randf() * 1.4, "sparkle", 0.01))
	for _i in range(_pcount(22)):
		var a := randf() * TAU
		var sp := 0.6 + randf() * 1.6
		_particles.append(_mk(pos, Vector2(cos(a) * sp, sin(a) * sp * 0.6 - 0.4),
			1.4 + randf() * 0.9, 24.0 + randf() * 22.0, "smoke", -0.005))

# 잔류 — 명중 후 타겟 주위에 떠오르는 하트·반짝임
func _spawn_ambient() -> void:
	if randf() < 0.6 * _scale():
		var tn := "violet" if randf() < 0.25 else "rose"
		_particles.append(_mk(_target + Vector2(randf_range(-45.0, 45.0), randf_range(10.0, 30.0)),
			Vector2(randf_range(-0.3, 0.3), -0.5 - randf() * 0.7),
			1.6 + randf() * 0.9, 8.0 + randf() * 10.0, "heart", 0.0, randf_range(-0.25, 0.25), 0.0, tn))
	if randf() < 0.4 * _scale():
		_particles.append(_mk(_target + Vector2(randf_range(-50.0, 50.0), randf_range(-15.0, 15.0)),
			Vector2(randf_range(-0.4, 0.4), -0.4 - randf() * 0.5),
			1.4 + randf() * 0.9, 1.2 + randf() * 1.2, "sparkle", 0.0))

func _roff(m: float) -> Vector2:
	return Vector2(randf_range(-m, m), randf_range(-m, m))

func _process(delta: float) -> void:
	_elapsed += delta

	# 차지 진행
	if _charge_t >= 0.0:
		_charge_t = minf(_charge_t + delta / CHARGE_TIME, 1.0)

	# 투사체 비행 — 꽁무니 trail 방출
	if _proj_t >= 0.0:
		_proj_t += delta / PROJ_FLIGHT
		_spawn_trail(charm_proj_pos(_caster, _target, clampf(_proj_t, 0.0, 1.0), ARC_HEIGHT, WOBBLE_AMP))
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
		if p["kind"] == "heart":
			p["pos"].x += sin((p["life"] + p["max_life"] * 0.3) * 10.0) * 0.3 * delta * PSPEED
		p["vel"] *= damp
		if p["spin"] != 0.0:
			p["rot"] += p["spin"] * delta * PSPEED
		alive.append(p)
	_particles = alive

	# 매혹 잔류 — 명중 후 CHARM_TIME 동안 지속 생성
	if _ambient_timer > 0.0:
		_ambient_timer -= delta
		_spawn_ambient()

	# 하트 충격파 / 최면 나선 진행
	if _shock_life >= 0.0:
		_shock_life += delta / 0.85
	if _spiral_age >= 0.0:
		_spiral_age += delta

	_smoke_layer.queue_redraw()
	_glow_layer.queue_redraw()
	if _ground_layer:
		_ground_layer.queue_redraw()

func _on_impact() -> void:
	_proj_t = -1.0
	_spawn_impact_burst(_target)
	_shock_life = 0.0
	_spiral_age = 0.0
	_ambient_timer = CHARM_TIME
	screen_effect.emit()

# ── 하트 모양 그리기 헬퍼 ──
func _heart_polygon(pos: Vector2, size: float, rot: float) -> PackedVector2Array:
	var s := size / 32.0
	var out := PackedVector2Array()
	for pt in _heart_pts:
		out.append(pos + (pt * s).rotated(rot))
	return out

func _tint_color(tint: String) -> Color:
	return COL_VIOLET if tint == "violet" else COL_MID

# ── 그리기 패스 — _DrawLayer 가 블렌드 모드별로 호출 ──
func _draw_smoke_pass(canvas: CanvasItem) -> void:
	# 분홍 연기
	for p in _particles:
		if p["kind"] != "smoke":
			continue
		var k: float = p["life"] / p["max_life"]
		var a: float = (1.0 - k) * 0.35
		var r: float = p["size"] * (1.0 + k * 1.4)
		canvas.draw_circle(p["pos"], r, Color(COL_SMOKE, a))
	# 하트 솔리드 (헤일로 위에 또렷한 하트)
	for p in _particles:
		if p["kind"] != "heart":
			continue
		var a: float = 1.0 - p["life"] / p["max_life"]
		var poly := _heart_polygon(p["pos"], p["size"], p["rot"])
		canvas.draw_colored_polygon(poly, Color(COL_MID, a))
		canvas.draw_polyline(poly + PackedVector2Array([poly[0]]), Color(COL_HOT, 0.7 * a), 1.2, true)

func _draw_glow_pass(canvas: CanvasItem) -> void:
	# 차지 하트 구체
	if _charge_t >= 0.0:
		var sc := lerpf(0.25, 1.1, _charge_t)
		var beat := 1.0 + 0.12 * sin(_elapsed * 10.0) * _charge_t
		var oa := clampf(_charge_t * 2.0, 0.0, 1.0)
		canvas.draw_circle(_caster, ORB_SIZE * sc * 0.9, Color(COL_DEEP, 0.09 * oa))
		var op := _heart_polygon(_caster, ORB_SIZE * sc * beat, 0.0)
		canvas.draw_colored_polygon(op, Color(COL_MID, oa))
		canvas.draw_polyline(op + PackedVector2Array([op[0]]), Color(COL_HOT, 0.85 * oa), 1.4, true)

	# 하트 헤일로 (가산 글로우)
	for p in _particles:
		if p["kind"] != "heart":
			continue
		var a: float = 1.0 - p["life"] / p["max_life"]
		canvas.draw_circle(p["pos"], p["size"] * 1.4, Color(_tint_color(p["tint"]), 0.11 * a))

	# 꽃잎
	for p in _particles:
		if p["kind"] != "petal":
			continue
		_draw_petal(canvas, p)

	# 반짝임 (점 + 십자)
	for p in _particles:
		if p["kind"] != "sparkle":
			continue
		var a: float = 1.0 - p["life"] / p["max_life"]
		var pr: float = p["size"]
		var pos: Vector2 = p["pos"]
		canvas.draw_circle(pos, pr, Color(COL_HOT, a))
		canvas.draw_rect(Rect2(pos.x - pr * 2.5, pos.y - 0.3, pr * 5.0, 0.6), Color(COL_HOT, a))
		canvas.draw_rect(Rect2(pos.x - 0.3, pos.y - pr * 2.5, 0.6, pr * 5.0), Color(COL_HOT, a))

	# 매혹 오라는 _ground_layer 로 분리됨 (캐릭터 뒤)

	# 하트 충격파 링
	if _shock_life >= 0.0 and _shock_life <= 1.0:
		var hs := lerpf(0.3, 6.0, _shock_life) * 32.0
		var ha := (1.0 - _shock_life) * 0.85
		var ring := _heart_polygon(_target, hs, 0.0)
		canvas.draw_polyline(ring + PackedVector2Array([ring[0]]), Color(COL_MID, ha),
			1.0 + 3.0 * (1.0 - _shock_life), true)

	# 최면 나선
	if _spiral_age >= 0.0:
		_draw_spiral(canvas)

	# 키스 투사체 — 헤일로 + 밝은 하트
	if _proj_t >= 0.0:
		var pp := charm_proj_pos(_caster, _target, clampf(_proj_t, 0.0, 1.0), ARC_HEIGHT, WOBBLE_AMP)
		canvas.draw_circle(pp, 42.0, Color(COL_MID, 0.08))
		canvas.draw_circle(pp, 22.0, Color(COL_HOT, 0.14))
		var php := _heart_polygon(pp, 28.0, sin(_elapsed * 6.0) * 0.12)
		canvas.draw_colored_polygon(php, Color(COL_DEEP, 0.95))
		canvas.draw_polyline(php + PackedVector2Array([php[0]]), Color(1, 1, 1, 0.9), 1.4, true)

func _draw_petal(canvas: CanvasItem, p: Dictionary) -> void:
	var a: float = 1.0 - p["life"] / p["max_life"]
	var sz: float = p["size"]
	var rot: float = p["rot"]
	var body := PackedVector2Array()
	for i in range(10):
		var ang := TAU * float(i) / 10.0
		body.append(p["pos"] + Vector2(cos(ang) * sz * 0.55, sin(ang) * sz).rotated(rot))
	canvas.draw_colored_polygon(body, Color(COL_MID, 0.85 * a))
	var hl_center: Vector2 = p["pos"] + Vector2(0.0, -sz * 0.2).rotated(rot)
	var hl := PackedVector2Array()
	for i in range(8):
		var ang := TAU * float(i) / 8.0
		hl.append(hl_center + Vector2(cos(ang) * sz * 0.25, sin(ang) * sz * 0.45).rotated(rot))
	canvas.draw_colored_polygon(hl, Color(COL_HOT, 0.5 * a))

func _draw_spiral(canvas: CanvasItem) -> void:
	var appear := clampf(_spiral_age / 0.4, 0.0, 1.0)
	var sc := lerpf(0.4, 1.0, appear)
	var spin := _spiral_age * 1.5
	var fade := 1.0
	if _spiral_age > CHARM_TIME:
		fade = clampf(1.0 - (_spiral_age - CHARM_TIME) / 0.4, 0.0, 1.0)
	var a := appear * fade * 0.55
	if a <= 0.0:
		return
	var c := _target + Vector2(0.0, -30.0)
	var pts := PackedVector2Array()
	var steps := 64
	for i in range(steps + 1):
		var f := float(i) / float(steps)
		var ang := f * 3.0 * TAU + spin
		var r := lerpf(52.0, 4.0, f) * sc
		pts.append(c + Vector2(cos(ang), sin(ang)) * r)
	canvas.draw_polyline(pts, Color(COL_HOT, a), 2.0, true)

# ── 매혹 오라 (캐릭터 뒤) — _ground_layer 가 z 캐릭터 아래로 set ──
func _draw_ground_pass(canvas: CanvasItem) -> void:
	if _ambient_timer > 0.0:
		var pulse := 0.5 + 0.3 * sin(_elapsed * 4.0)
		var ac: Vector2 = _ground_pos if _has_ground else _target + Vector2(0.0, 70.0)
		var aura := PackedVector2Array()
		for i in range(20):
			var ang := TAU * float(i) / 20.0
			aura.append(ac + Vector2(cos(ang) * 76.0, sin(ang) * 15.0))
		canvas.draw_colored_polygon(aura, Color(COL_MID, 0.28 * pulse))

# ── 블렌드 모드가 다른 두 그리기 레이어 ──
# 어두운 분홍 연기는 가산이면 안 보이므로 일반 블렌드, 헤일로·반짝임은 글로우용 가산 블렌드.
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

# 매혹 오라 전용 레이어 — 가산 블렌드 (분홍 글로우). z_index 캐릭터 아래로.
class _GroundLayer:
	extends Node2D
	var _fx: Node2D

	func setup(owner_fx: Node2D) -> void:
		_fx = owner_fx
		var m := CanvasItemMaterial.new()
		m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		material = m

	func _draw() -> void:
		_fx._draw_ground_pass(self)
