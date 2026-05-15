# scenes/vfx/heal_blessing.gd
# 회복 VFX — ui_sample/vfx/Heal VFX.html 재현 (+HP 숫자 제외).
# battle_scene이 영웅 회복 시 .new() → add_child → play(target, target).
# 노드는 position (0,0)으로 add_child해야 한다 (좌표를 global로 받아 그대로 그림).
# 회복은 시전자가 무의미하므로 play 의 첫 인자는 무시한다 (빔 VFX와 인터페이스 통일용).
# 나뭇잎은 가산 블렌드로 흐려지므로 잎·고리·십자(일반)·반짝임(가산) 2레이어로 그린다.
extends Node2D

# 파티클 갯수 — GameSettings.particle_count_scale 적용 (하/중/상 = 0.25/0.5/1.0배)
func _pcount(n: int) -> int:
	var gs := get_node_or_null("/root/GameSettings")
	return n if gs == null else maxi(1, int(round(n * gs.particle_count_scale())))

const COL_HOT      := Color(0.902, 1.0, 0.878)  # #e6ffe0 — 흰연두 코어
const COL_MID      := Color(0.525, 1.0, 0.682)  # #86ffae — 회복 녹색
const COL_DEEP     := Color(0.180, 0.604, 0.353) # #2e9a5a — 진녹색
const COL_VEIN     := Color(0.047, 0.353, 0.212) # #0c5a36 — 잎맥
const COL_LEAF_TOP := Color(0.706, 1.0, 0.784)  # rgba(180,255,200) — 잎 윗면

# 크기/타이밍 — 이 상수만 만지면 된다.
const ORB_CHARGE_START := 0.12  # 차지 구체 시작
const ORB_CHARGE_FULL  := 0.36  # 차지 완료
const ORB_OFFSET_Y     := -90.0 # 차지 구체 — 타겟 위로(px)
const CHARGE_TIME      := 0.6   # 차지 시간(s)
const IMPACT_DELAY     := CHARGE_TIME  # battle_manager 동기화용 (차지 끝 = 회복 발동)
const HEAL_TIME        := 1.4   # 발동 후 잎·반짝임 분출 지속(s)
const RING_SQUASH      := 0.34  # 누운 원근 — y축 압축 (rotateX 70°)
const PSPEED           := 60.0  # HTML(dt*0.06) → Godot(delta*60) 환산 계수

## 빔 VFX와 인터페이스 통일용 — 회복 VFX는 emit하지 않는다.
signal screen_effect

var _target := Vector2.ZERO
var _charge_orb: Sprite2D
var _smoke_layer: Node2D  # 일반 블렌드 — 잎·고리·십자
var _glow_layer: Node2D   # 가산 블렌드 — 반짝임
var _leaf_pts: PackedVector2Array  # 단위 나뭇잎 윤곽
var _particles: Array = []  # [{pos, vel, life, max_life, r, kind, grav, rot, spin, sway}]
var _ring_age := -1.0     # <0 = 비활성, 경과 초 (바닥 고리)
var _cross_age := -1.0    # <0 = 비활성, 경과 초 (회복 십자)
var _heal_timer := 0.0    # 잎·반짝임 분출 남은 시간

# ── 단위 나뭇잎 윤곽 (autoload 비의존 static — 단위 테스트 가능) ──
# HTML drawLeaf 의 큐빅 베지어 2개를 6점씩 샘플. 중심 (0,0), 크기 1 기준.
static func leaf_shape() -> PackedVector2Array:
	var beziers := [
		[Vector2(0, -1), Vector2(0.6, -0.5), Vector2(0.6, 0.5), Vector2(0, 1)],
		[Vector2(0, 1), Vector2(-0.6, 0.5), Vector2(-0.6, -0.5), Vector2(0, -1)],
	]
	var p := PackedVector2Array()
	for bz in beziers:
		var a: Vector2 = bz[0]
		var c1: Vector2 = bz[1]
		var c2: Vector2 = bz[2]
		var d: Vector2 = bz[3]
		for i in range(6):
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
	_leaf_pts = leaf_shape()

	# 잎·고리·십자 레이어 — 일반 블렌드, 아래
	_smoke_layer = _DrawLayer.new()
	_smoke_layer.setup(self, false)
	add_child(_smoke_layer)

	_charge_orb = Sprite2D.new()
	_charge_orb.texture = _make_orb_tex(COL_HOT, COL_MID, COL_DEEP)
	_charge_orb.modulate = Color(1, 1, 1, 0.0)  # 알파만 제어 — 색은 텍스처가 가짐
	_charge_orb.scale = Vector2(ORB_CHARGE_START, ORB_CHARGE_START)
	add_child(_charge_orb)

	# 반짝임 레이어 — 가산 블렌드, 위
	_glow_layer = _DrawLayer.new()
	_glow_layer.setup(self, true)
	add_child(_glow_layer)

# 첫 인자(caster)는 무시 — 회복 VFX는 회복 대상 위치에서만 발동
func play(_caster_pos: Vector2, target_pos: Vector2) -> void:
	_target = target_pos
	_charge_orb.position = target_pos + Vector2(0.0, ORB_OFFSET_Y)
	_run()

func _run() -> void:
	# 1) 차지 — 대상 위의 회복 구체 (0.6s)
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_charge_orb, "modulate:a", 1.0, 0.18)
	tw.parallel().tween_property(_charge_orb, "scale", Vector2(ORB_CHARGE_FULL, ORB_CHARGE_FULL), CHARGE_TIME)
	set_process(true)
	await get_tree().create_timer(CHARGE_TIME).timeout
	if not is_inside_tree():
		return
	# 2) 발동 — 구체 사라짐 + 고리·십자 등장 + 초기 분출
	var tw2 := create_tween()
	tw2.tween_property(_charge_orb, "modulate:a", 0.0, 0.12)
	_ring_age = 0.0
	_cross_age = 0.0
	_heal_timer = HEAL_TIME
	_pop()
	# 3) 분출·페이드는 _process에서. 정리.
	await get_tree().create_timer(HEAL_TIME + 1.5).timeout
	if is_inside_tree():
		queue_free()

func _mk(pos: Vector2, vel: Vector2, max_life: float, r: float, kind: String,
		grav: float, rot: float = 0.0, spin: float = 0.0, sway: float = 0.0) -> Dictionary:
	return {"pos": pos, "vel": vel, "life": 0.0, "max_life": max_life, "r": r,
		"kind": kind, "grav": grav, "rot": rot, "spin": spin, "sway": sway}

func _spawn_leaf(from_pop: bool) -> void:
	var pos := _target + Vector2(randf_range(-60.0, 60.0), 10.0)
	var grav := 0.0
	if from_pop:
		var a := randf() * TAU
		var sp := 1.0 + randf() * 2.0
		_particles.append(_mk(_target + Vector2(0.0, -40.0),
			Vector2(cos(a) * sp, sin(a) * sp - 0.8),
			1.6 + randf() * 0.9, 8.0 + randf() * 7.0, "leaf", 0.02,
			randf_range(-0.6, 0.6), randf_range(-0.05, 0.05), randf() * TAU))
	else:
		_particles.append(_mk(pos,
			Vector2(randf_range(-0.5, 0.5), -0.6 - randf() * 0.7),
			1.6 + randf() * 0.9, 7.0 + randf() * 7.0, "leaf", grav,
			randf_range(-0.6, 0.6), randf_range(-0.04, 0.04), randf() * TAU))

func _spawn_sparkle(from_pop: bool) -> void:
	if from_pop:
		var a := randf() * TAU
		var sp := 1.0 + randf() * 3.0
		_particles.append(_mk(_target + Vector2(0.0, -40.0),
			Vector2(cos(a) * sp, sin(a) * sp - 1.0),
			1.2 + randf() * 0.7, 1.4 + randf() * 1.4, "sparkle", 0.02))
	else:
		_particles.append(_mk(_target + Vector2(randf_range(-60.0, 60.0), 10.0),
			Vector2(randf_range(-0.3, 0.3), -1.2 - randf() * 0.8),
			1.2 + randf() * 0.7, 1.4 + randf() * 1.2, "sparkle", 0.0))

# 발동 순간 폭발 — 반짝임 + 나뭇잎
func _pop() -> void:
	for _i in range(_pcount(24)):
		_spawn_sparkle(true)
	for _i in range(_pcount(5)):
		_spawn_leaf(true)

func _process(delta: float) -> void:
	# 고리·십자 진행
	if _ring_age >= 0.0:
		_ring_age += delta
	if _cross_age >= 0.0:
		_cross_age += delta

	# 잎·반짝임 지속 분출 — HEAL_TIME 동안
	if _heal_timer > 0.0:
		_heal_timer -= delta
		if randf() < 0.4:
			_spawn_leaf(false)
		if randf() < 0.9:
			_spawn_sparkle(false)

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
		if p["kind"] == "leaf":
			p["pos"].x += sin((p["life"] + p["sway"]) * 5.0) * 0.6 * delta * PSPEED
			p["rot"] += p["spin"] * delta * PSPEED
		alive.append(p)
	_particles = alive

	_smoke_layer.queue_redraw()
	_glow_layer.queue_redraw()

# ── 그리기 패스 — _DrawLayer 가 블렌드 모드별로 호출 ──
func _draw_smoke_pass(canvas: CanvasItem) -> void:
	# 바닥 고리 (누운 원근)
	if _ring_age >= 0.0:
		_draw_ring(canvas)
	# 회복 십자
	if _cross_age >= 0.0:
		_draw_cross(canvas)
	# 나뭇잎
	for p in _particles:
		if p["kind"] != "leaf":
			continue
		var a: float = 1.0 - p["life"] / p["max_life"]
		var poly := PackedVector2Array()
		for pt in _leaf_pts:
			poly.append(p["pos"] + (pt * p["r"]).rotated(p["rot"]))
		canvas.draw_colored_polygon(poly, Color(COL_LEAF_TOP, 0.9 * a))
		# 잎맥 (중앙선)
		var v0: Vector2 = p["pos"] + (Vector2(0.0, -1.0) * p["r"]).rotated(p["rot"])
		var v1: Vector2 = p["pos"] + (Vector2(0.0, 1.0) * p["r"]).rotated(p["rot"])
		canvas.draw_line(v0, v1, Color(COL_VEIN, 0.6 * a), 0.8)

func _draw_glow_pass(canvas: CanvasItem) -> void:
	# 반짝임 (밝은 점 + 십자)
	for p in _particles:
		if p["kind"] != "sparkle":
			continue
		var k: float = p["life"] / p["max_life"]
		var a: float = 1.0 - k
		var pr: float = p["r"]
		var pos: Vector2 = p["pos"]
		var col := Color(0.784, 1.0, 0.784 + 0.157 * k, a)
		canvas.draw_circle(pos, pr, col)
		canvas.draw_rect(Rect2(pos.x - pr * 2.5, pos.y - 0.3, pr * 5.0, 0.6), col)
		canvas.draw_rect(Rect2(pos.x - 0.3, pos.y - pr * 2.5, 0.6, pr * 5.0), col)

func _draw_ring(canvas: CanvasItem) -> void:
	var appear: float = clampf(_ring_age / 0.5, 0.0, 1.0)
	var sc: float = lerpf(0.4, 1.0, appear)
	var fade := 1.0
	if _ring_age > HEAL_TIME:
		fade = clampf(1.0 - (_ring_age - HEAL_TIME) / 0.5, 0.0, 1.0)
	var a: float = appear * fade * 0.9
	if a <= 0.0:
		return
	var rc := _target + Vector2(0.0, 42.0)
	for radius in [95.0, 80.0]:
		var rad := float(radius) * sc
		var pts := PackedVector2Array()
		for i in range(40):
			var ang := TAU * float(i) / 40.0
			pts.append(rc + Vector2(cos(ang) * rad, sin(ang) * rad * RING_SQUASH))
		canvas.draw_polyline(pts + PackedVector2Array([pts[0]]), Color(COL_MID, 0.8 * a), 1.4, true)
	canvas.draw_circle(rc, 5.0 * sc, Color(COL_MID, a))

func _draw_cross(canvas: CanvasItem) -> void:
	var pop: float = clampf(_cross_age / 0.55, 0.0, 1.0)
	var sc: float
	if pop < 0.6:
		sc = lerpf(0.3, 1.15, pop / 0.6)
	else:
		sc = lerpf(1.15, 1.0, (pop - 0.6) / 0.4)
	# 항상 불투명 — 등장 페이드인 없음, 마지막에만 짧게 페이드아웃
	var a := 1.0
	if _cross_age > HEAL_TIME:
		a = clampf(1.0 - (_cross_age - HEAL_TIME) / 0.4, 0.0, 1.0)
	if a <= 0.0:
		return
	# 부유 — pop 완료(0.55s) 시점부터 sin(0)에서 시작해 위치 점프 없이 부드럽게
	var float_y := 0.0
	if _cross_age > 0.55:
		float_y = sin((_cross_age - 0.55) * 2.6) * 8.0
	var c := _target + Vector2(0.0, -90.0 + float_y)
	var arm := 21.0 * sc   # 십자 팔 길이(반)
	var thick := 5.0 * sc  # 십자 두께(반)
	canvas.draw_rect(Rect2(c.x - thick, c.y - arm, thick * 2.0, arm * 2.0), Color(COL_MID, a))
	canvas.draw_rect(Rect2(c.x - arm, c.y - thick, arm * 2.0, thick * 2.0), Color(COL_MID, a))

# ── 블렌드 모드가 다른 두 그리기 레이어 ──
# 나뭇잎은 가산이면 흐려지므로 일반 블렌드, 반짝임은 글로우용 가산 블렌드.
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
