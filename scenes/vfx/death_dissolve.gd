# scenes/vfx/death_dissolve.gd
# 사망 VFX — ui_sample/vfx/Death VFX.html 재현 (DEFEATED 콜아웃·캐릭터 낙하 애니메이션 제외).
# battle_scene이 적/영웅 사망 시 .new() → add_child → play(target, target).
# 노드는 position (0,0)으로 add_child해야 한다 (좌표를 global로 받아 그대로 그림).
# 사망은 시전자가 무의미하므로 play 의 첫 인자는 무시한다 (빔 VFX와 인터페이스 통일용).
# 회색 재는 가산 블렌드로 안 보이므로 핏물·재(일반)·영혼(가산) 2레이어로 그린다.
extends Node2D

# 파티클 갯수 / ambient 확률 — GameSettings.particle_count_scale 적용 (override 우선)
var _particle_scale_override: float = -1.0  # vfx_preview 3-way 비교용 (음수=GameSettings)

func _scale() -> float:
	if _particle_scale_override > 0.0:
		return _particle_scale_override
	var gs := get_node_or_null("/root/GameSettings")
	return 1.0 if gs == null else gs.particle_count_scale()

const COL_SOUL      := Color(0.549, 0.561, 0.596) # 잿빛 영혼 — 외곽 글로우
const COL_SOUL_HOT  := Color(0.784, 0.792, 0.820) # 잿빛 영혼 — 중심 글로우
const COL_BLOOD     := Color(0.431, 0.078, 0.078) # rgba(110,20,20) — 핏물

# 타이밍/크기 — 이 상수만 만지면 된다.
const DISSOLVE_TIME := 1.8   # 재·영혼 분출 지속(s)
const POOL_GROW     := 1.6   # 핏물 웅덩이 확장 시간(s)
const POOL_RADIUS   := 84.0  # 핏물 웅덩이 최대 가로 반경(px)
const PSPEED        := 60.0  # HTML(dt*0.06) → Godot(delta*60) 환산 계수

## 빔 VFX와 인터페이스 통일용 — 사망 VFX는 emit하지 않는다.
@warning_ignore("unused_signal")
signal screen_effect

var _target := Vector2.ZERO
# 핏물 웅덩이 anchor — set_ground_anchor() 로 캐릭터 발 위치 지정.
var _ground_pos := Vector2.ZERO
var _has_ground: bool = false

func set_ground_anchor(pos: Vector2) -> void:
	_ground_pos = pos
	_has_ground = true
	if _ground_layer != null:
		_ground_layer.z_as_relative = false
		_ground_layer.z_index = int(pos.y) - 1

var _smoke_layer: Node2D  # 일반 블렌드 — 회색 재
var _glow_layer: Node2D   # 가산 블렌드 — 푸른 영혼
var _ground_layer: Node2D # 핏물 웅덩이 (캐릭터 뒤로 z set)
var _particles: Array = []  # [{pos, vel, life, max_life, r, kind, grav, rot, spin, sway}]
var _pool_age := -1.0     # <0 = 비활성, 경과 초 (핏물 웅덩이)
var _emit_timer := 0.0    # 재·영혼 분출 남은 시간

# ── 회전 사각형 4점 (autoload 비의존 static — 단위 테스트 가능) ──
static func ash_quad(center: Vector2, half_w: float, half_h: float, rot: float) -> PackedVector2Array:
	var local := [
		Vector2(-half_w, -half_h), Vector2(half_w, -half_h),
		Vector2(half_w, half_h), Vector2(-half_w, half_h),
	]
	var out := PackedVector2Array()
	for v in local:
		out.append(center + (v as Vector2).rotated(rot))
	return out

func _ready() -> void:
	set_process(false)
	# 핏물 — 캐릭터 뒤로 z set, 일반 블렌드. 가장 먼저 add
	_ground_layer = _GroundLayer.new()
	_ground_layer.setup(self)
	add_child(_ground_layer)
	# 회색 재 레이어 — 일반 블렌드
	_smoke_layer = _DrawLayer.new()
	_smoke_layer.setup(self, false)
	add_child(_smoke_layer)
	# 영혼 레이어 — 가산 블렌드, 위
	_glow_layer = _DrawLayer.new()
	_glow_layer.setup(self, true)
	add_child(_glow_layer)

# 첫 인자(caster)는 무시 — 사망 VFX는 죽는 대상 위치에서만 발동
func play(_caster_pos: Vector2, target_pos: Vector2) -> void:
	_target = target_pos
	_run()

func _run() -> void:
	_pool_age = 0.0
	_emit_timer = DISSOLVE_TIME
	set_process(true)
	await get_tree().create_timer(DISSOLVE_TIME + 2.5).timeout
	if is_inside_tree():
		queue_free()

func _spawn_ash() -> void:
	_particles.append({
		"pos": _target + Vector2(randf_range(-40.0, 40.0), randf_range(-70.0, 50.0)),
		"vel": Vector2(randf_range(-0.5, 0.5), -0.3 - randf() * 0.7),
		"life": 0.0, "max_life": 1.6 + randf() * 1.2,
		"r": 1.4 + randf() * 1.8, "kind": "ash", "grav": -0.005,
		"rot": randf() * TAU, "spin": randf_range(-0.04, 0.04), "sway": 0.0,
	})

func _spawn_soul() -> void:
	_particles.append({
		"pos": _target + Vector2(randf_range(-15.0, 15.0), randf_range(-20.0, 20.0)),
		"vel": Vector2(randf_range(-0.3, 0.3), -0.8 - randf() * 0.8),
		"life": 0.0, "max_life": 2.0 + randf() * 1.0,
		"r": 3.0 + randf() * 4.0, "kind": "soul", "grav": -0.012,
		"rot": 0.0, "spin": 0.0, "sway": randf() * TAU,
	})

func _process(delta: float) -> void:
	# 재·영혼 분출 — DISSOLVE_TIME 동안
	if _emit_timer > 0.0:
		_emit_timer -= delta
		if randf() < 0.7 * _scale():
			_spawn_ash()
		if randf() < 0.5 * _scale():
			_spawn_soul()

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
		if p["kind"] == "soul":
			p["pos"].x += sin((p["life"] + p["sway"]) * 5.0) * 0.6 * delta * PSPEED
		elif p["kind"] == "ash":
			p["rot"] += p["spin"] * delta * PSPEED
		alive.append(p)
	_particles = alive

	# 핏물 웅덩이 진행
	if _pool_age >= 0.0:
		_pool_age += delta

	_smoke_layer.queue_redraw()
	_glow_layer.queue_redraw()
	if _ground_layer:
		_ground_layer.queue_redraw()

# ── 핏물 웅덩이 (캐릭터 뒤) — _ground_layer 가 z 캐릭터 아래로 set ──
func _draw_ground_pass(canvas: CanvasItem) -> void:
	if _pool_age >= 0.0:
		var grow: float = 1.0 - pow(1.0 - clampf(_pool_age / POOL_GROW, 0.0, 1.0), 2.0)
		var pc: Vector2 = _ground_pos if _has_ground else _target + Vector2(0.0, 80.0)
		var pool := PackedVector2Array()
		for i in range(24):
			var ang := TAU * float(i) / 24.0
			pool.append(pc + Vector2(cos(ang) * POOL_RADIUS * grow, sin(ang) * 16.0))
		canvas.draw_colored_polygon(pool, Color(COL_BLOOD, 0.82))

# ── 그리기 패스 — _DrawLayer 가 블렌드 모드별로 호출 (웅덩이는 ground_layer 분리) ──
func _draw_smoke_pass(canvas: CanvasItem) -> void:
	# 회색 재 조각 (회전 사각형, 수명에 따라 어두워짐)
	for p in _particles:
		if p["kind"] != "ash":
			continue
		var k: float = p["life"] / p["max_life"]
		var a: float = (1.0 - k) * 0.85
		var g: float = 0.51 - 0.16 * k  # 130→90 (/255)
		var quad := ash_quad(p["pos"], p["r"], p["r"] * 0.4, p["rot"])
		canvas.draw_colored_polygon(quad, Color(g, g, g + 0.04, a))

func _draw_glow_pass(canvas: CanvasItem) -> void:
	# 푸른 영혼 (글로우 헤일로 + 순백 코어) — HTML: 가장자리 진파랑 → 중심 흰하늘, 코어 순백
	for p in _particles:
		if p["kind"] != "soul":
			continue
		var k: float = p["life"] / p["max_life"]
		var a: float = (1.0 - k) * 0.85
		canvas.draw_circle(p["pos"], p["r"] * 4.0, Color(COL_SOUL, 0.2 * a))
		canvas.draw_circle(p["pos"], p["r"] * 2.0, Color(COL_SOUL_HOT, 0.32 * a))
		canvas.draw_circle(p["pos"], p["r"] * 0.8, Color(1, 1, 1, a))

# ── 블렌드 모드가 다른 두 그리기 레이어 ──
# 회색 재는 가산이면 안 보이므로 일반 블렌드, 영혼은 글로우용 가산 블렌드.
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

# 핏물 웅덩이 전용 레이어 — 일반 블렌드. z_index 캐릭터 아래로.
class _GroundLayer:
	extends Node2D
	var _fx: Node2D

	func setup(owner_fx: Node2D) -> void:
		_fx = owner_fx

	func _draw() -> void:
		_fx._draw_ground_pass(self)
