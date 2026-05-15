# scenes/vfx/revive_blessing.gd
# 부활 VFX — ui_sample/vfx/Revive VFX.html 재현 (REVIVED 콜아웃·캐릭터 기립 애니메이션 제외).
# battle_scene이 영웅 부활 시 .new() → add_child → play(target, target).
# 노드는 position (0,0)으로 add_child해야 한다 (좌표를 global로 받아 그대로 그림).
# 부활은 시전자가 무의미하므로 play 의 첫 인자는 무시한다 (빔 VFX와 인터페이스 통일용).
# 어두운 황금 안개는 가산 블렌드로 흐려지므로 기둥·고리·안개·깃털(일반)·빛입자(가산) 2레이어로 그린다.
extends Node2D

# 파티클 갯수 — GameSettings.particle_count_scale 적용 (하/중/상 = 0.25/0.5/1.0배)
func _pcount(n: int) -> int:
	var gs := get_node_or_null("/root/GameSettings")
	return n if gs == null else maxi(1, int(round(n * gs.particle_count_scale())))

const COL_HOT     := Color(1, 1, 1)             # 흰 코어
const COL_MID     := Color(1.0, 0.914, 0.659)   # #ffe9a8 — 황금
const COL_DEEP    := Color(0.8, 0.588, 0.282)   # #cc9648 — 진황금
const COL_HAZE    := Color(1.0, 0.941, 0.784)   # rgba(255,240,200) — 안개
const COL_FEATHER := Color(1.0, 0.980, 0.863)   # rgba(255,250,220) — 깃털

# 크기/타이밍 — 이 상수만 만지면 된다.
const PILLAR_TIME   := 0.7    # 빛기둥 강하 시간(s)
const PILLAR_WIDTH  := 200.0  # 빛기둥 너비(px)
const PILLAR_HEIGHT := 420.0  # 빛기둥 높이 — 타겟 위로(px)
const RING_RADIUS   := 130.0  # 바닥 고리 기준 반경(px)
const RING_SQUASH   := 0.34   # 누운 원근 — y축 압축 (rotateX 70°)
const REVIVE_TIME   := 2.5    # 명중 후 기둥·고리 유지(s)
const PSPEED        := 60.0   # HTML(dt*0.06) → Godot(delta*60) 환산 계수

## 빔 VFX와 인터페이스 통일용 — 부활 VFX는 emit하지 않는다.
signal screen_effect

var _target := Vector2.ZERO
var _smoke_layer: Node2D  # 일반 블렌드 — 기둥·고리·안개·깃털
var _glow_layer: Node2D   # 가산 블렌드 — 빛 입자
var _particles: Array = []  # [{pos, vel, life, max_life, r, kind, grav, rot, spin}]
var _pillar_age := -1.0   # <0 = 비활성, 경과 초 (빛기둥)
var _ring_age := -1.0     # <0 = 비활성, 경과 초 (바닥 고리)
var _bursted := false

# ── 빛기둥 사다리꼴 4점 (autoload 비의존 static — 단위 테스트 가능) ──
# grow 0 → 위 모서리만 (높이 0), grow 1 → 전체 높이. target 바로 위로 자란다.
static func pillar_quad(target: Vector2, width: float, height: float, grow: float) -> PackedVector2Array:
	var hw := width * 0.5
	var top := target.y - height
	var bot := lerpf(top, target.y, clampf(grow, 0.0, 1.0))
	return PackedVector2Array([
		Vector2(target.x - hw, top), Vector2(target.x + hw, top),
		Vector2(target.x + hw, bot), Vector2(target.x - hw, bot),
	])

func _ready() -> void:
	set_process(false)
	# 기둥·고리·안개·깃털 레이어 — 일반 블렌드, 아래
	_smoke_layer = _DrawLayer.new()
	_smoke_layer.setup(self, false)
	add_child(_smoke_layer)
	# 빛 입자 레이어 — 가산 블렌드, 위
	_glow_layer = _DrawLayer.new()
	_glow_layer.setup(self, true)
	add_child(_glow_layer)

# 첫 인자(caster)는 무시 — 부활 VFX는 부활 대상 위치에서만 발동
func play(_caster_pos: Vector2, target_pos: Vector2) -> void:
	_target = target_pos
	_run()

func _run() -> void:
	# 1) 빛기둥 강하 (0.7s)
	_pillar_age = 0.0
	set_process(true)
	await get_tree().create_timer(PILLAR_TIME).timeout
	if not is_inside_tree():
		return
	# 2) 폭발 + 바닥 고리 등장
	_bursted = true
	_ring_age = 0.0
	_spawn_burst()
	# 3) 잔류·페이드는 _process에서. 정리.
	await get_tree().create_timer(REVIVE_TIME + 1.5).timeout
	if is_inside_tree():
		queue_free()

func _mk(pos: Vector2, vel: Vector2, max_life: float, r: float, kind: String,
		grav: float, rot: float = 0.0, spin: float = 0.0) -> Dictionary:
	return {"pos": pos, "vel": vel, "life": 0.0, "max_life": max_life, "r": r,
		"kind": kind, "grav": grav, "rot": rot, "spin": spin}

# 빛기둥 안에서 천천히 내려오는 빛 입자
func _spawn_pillar_mote() -> void:
	_particles.append(_mk(
		_target + Vector2(randf_range(-90.0, 90.0), -randf() * PILLAR_HEIGHT),
		Vector2(randf_range(-0.2, 0.2), 0.6 + randf() * 0.8),
		1.4 + randf() * 0.9, 1.4 + randf() * 1.4, "mote", 0.0))

# 폭발 — 빛 입자 + 깃털 + 황금 안개
func _spawn_burst() -> void:
	var origin := _target + Vector2(0.0, -60.0)
	for _i in range(_pcount(80)):
		var a := randf() * TAU
		var sp := 2.0 + randf() * 6.0
		_particles.append(_mk(origin, Vector2(cos(a) * sp, sin(a) * sp - 1.5),
			1.5 + randf() * 0.9, 1.6 + randf() * 1.6, "mote", 0.018))
	for _i in range(_pcount(40)):
		var a := randf() * TAU
		var sp := 1.5 + randf() * 4.0
		_particles.append(_mk(origin, Vector2(cos(a) * sp, sin(a) * sp - 1.2),
			1.8 + randf() * 0.9, 12.0 + randf() * 12.0, "feather", 0.012,
			randf_range(-0.8, 0.8), randf_range(-0.18, 0.18)))
	for _i in range(_pcount(24)):
		var a := randf() * TAU
		var sp := 0.6 + randf() * 1.8
		_particles.append(_mk(origin, Vector2(cos(a) * sp, sin(a) * sp * 0.6 - 0.5),
			1.8 + randf() * 0.9, 28.0 + randf() * 22.0, "haze", -0.01))

func _process(delta: float) -> void:
	# 기둥·고리 진행
	if _pillar_age >= 0.0:
		_pillar_age += delta
	if _ring_age >= 0.0:
		_ring_age += delta

	# 빛기둥 활성 동안 빛 입자 강하
	if _pillar_age >= 0.0 and _pillar_age < REVIVE_TIME:
		if randf() < 0.6:
			_spawn_pillar_mote()

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
		if p["kind"] == "feather":
			p["rot"] += p["spin"] * delta * PSPEED
		alive.append(p)
	_particles = alive

	_smoke_layer.queue_redraw()
	_glow_layer.queue_redraw()

# ── 그리기 패스 — _DrawLayer 가 블렌드 모드별로 호출 ──
func _draw_smoke_pass(canvas: CanvasItem) -> void:
	# 빛기둥 — 위에서 아래로 자라는 세로 그라데이션 띠
	if _pillar_age >= 0.0:
		var grow: float = 1.0 - pow(1.0 - clampf(_pillar_age / PILLAR_TIME, 0.0, 1.0), 2.0)
		var pa := 0.5
		if _pillar_age > REVIVE_TIME:
			pa *= clampf(1.0 - (_pillar_age - REVIVE_TIME) / 1.2, 0.0, 1.0)
		if pa > 0.0:
			var quad := pillar_quad(_target, PILLAR_WIDTH, PILLAR_HEIGHT, grow)
			var cols := PackedColorArray([
				Color(COL_MID, pa), Color(COL_MID, pa),
				Color(COL_DEEP, 0.0), Color(COL_DEEP, 0.0)])
			canvas.draw_polygon(quad, cols)

	# 바닥 고리 (누운 원근)
	if _ring_age >= 0.0:
		_draw_ring(canvas)

	# 황금 안개
	for p in _particles:
		if p["kind"] != "haze":
			continue
		var k: float = p["life"] / p["max_life"]
		var a: float = (1.0 - k) * 0.4
		var r: float = p["r"] * (1.0 + k * 1.2)
		canvas.draw_circle(p["pos"], r, Color(COL_HAZE, a))

	# 깃털 (몸 타원 + 중앙 + 깃대)
	for p in _particles:
		if p["kind"] != "feather":
			continue
		_draw_feather(canvas, p)

func _draw_glow_pass(canvas: CanvasItem) -> void:
	# 빛 입자 (밝은 점 + 십자 반짝임)
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

func _draw_feather(canvas: CanvasItem, p: Dictionary) -> void:
	var a: float = 1.0 - p["life"] / p["max_life"]
	var r: float = p["r"]
	var rot: float = p["rot"]
	var pos: Vector2 = p["pos"]
	# 깃털 몸 (세로 타원)
	var body := PackedVector2Array()
	for i in range(10):
		var ang := TAU * float(i) / 10.0
		body.append(pos + Vector2(cos(ang) * r * 0.4, sin(ang) * r).rotated(rot))
	canvas.draw_colored_polygon(body, Color(COL_FEATHER, 0.95 * a))
	# 중앙 밝은 줄
	var mid_center: Vector2 = pos + Vector2(0.0, -r * 0.3).rotated(rot)
	var mid := PackedVector2Array()
	for i in range(8):
		var ang := TAU * float(i) / 8.0
		mid.append(mid_center + Vector2(cos(ang) * r * 0.15, sin(ang) * r * 0.5).rotated(rot))
	canvas.draw_colored_polygon(mid, Color(COL_MID, 0.7 * a))
	# 깃대
	canvas.draw_line(pos + Vector2(0.0, -r).rotated(rot), pos + Vector2(0.0, r).rotated(rot),
		Color(COL_DEEP, 0.5 * a), 0.8)

func _draw_ring(canvas: CanvasItem) -> void:
	var appear: float = clampf(_ring_age / 0.6, 0.0, 1.0)
	var sc: float = lerpf(0.4, 1.0, appear)
	var spin: float = _ring_age * 0.6
	var fade := 1.0
	if _ring_age > REVIVE_TIME:
		fade = clampf(1.0 - (_ring_age - REVIVE_TIME) / 1.2, 0.0, 1.0)
	var a: float = appear * fade * 0.9
	if a <= 0.0:
		return
	var rc := _target + Vector2(0.0, 36.0)
	# 동심원 3개 (누운 타원)
	var radii := [125.0, 108.0, 86.0]
	var ring_cols := [Color(COL_MID, 0.9 * a), Color(COL_HOT, 0.65 * a), Color(COL_DEEP, 0.5 * a)]
	for ri in range(3):
		var rad: float = float(radii[ri]) * sc
		var rc_col: Color = ring_cols[ri]
		var pts := PackedVector2Array()
		for i in range(48):
			var ang := TAU * float(i) / 48.0 + spin
			pts.append(rc + Vector2(cos(ang) * rad, sin(ang) * rad * RING_SQUASH))
		canvas.draw_polyline(pts + PackedVector2Array([pts[0]]), rc_col, 1.5, true)
	# 삼각형 4개 (상하좌우 향함)
	for q in range(4):
		var base_ang := deg_to_rad(90.0 * float(q)) + spin
		var tip := rc + Vector2(cos(base_ang), sin(base_ang) * RING_SQUASH) * 118.0 * sc
		var l := base_ang + deg_to_rad(20.0)
		var rr := base_ang - deg_to_rad(20.0)
		var pl := rc + Vector2(cos(l), sin(l) * RING_SQUASH) * 86.0 * sc
		var pr := rc + Vector2(cos(rr), sin(rr) * RING_SQUASH) * 86.0 * sc
		canvas.draw_polyline(PackedVector2Array([pl, tip, pr]), Color(COL_MID, 0.8 * a), 1.2, true)

# ── 블렌드 모드가 다른 두 그리기 레이어 ──
# 어두운 황금 안개는 가산이면 흐려지므로 일반 블렌드, 빛 입자는 글로우용 가산 블렌드.
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
