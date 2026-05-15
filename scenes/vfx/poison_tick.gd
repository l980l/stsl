# scenes/vfx/poison_tick.gd
# 독 지속피해(DoT) tick 시 사용 — poison_splash 의 잔류 부분만 추출.
# 차지/비행 없이 target 위치에서 가스 + 보글보글 거품 + 발 아래 초록 웅덩이.
# SFX = impact_poison (poison_splash 와 동일).
# battle_manager 의 _tick_*_poison 시점에 .new() → add_child → play(target, target).
extends Node2D

# 파티클 갯수 / ambient 확률 — GameSettings.particle_count_scale 적용 (override 우선)
var _particle_scale_override: float = -1.0  # vfx_preview 3-way 비교용 (음수=GameSettings)

func _scale() -> float:
	if _particle_scale_override > 0.0:
		return _particle_scale_override
	var gs := get_node_or_null("/root/GameSettings")
	return 1.0 if gs == null else gs.particle_count_scale()

const COL_GAS     := Color(0.627, 0.863, 0.314)  # rgba(160,220,80) — 독가스
const COL_DRIP    := Color(0.549, 0.824, 0.196)  # rgba(140,210,50) — 독액 거품 본체
const COL_DRIP_HL := Color(0.863, 1.0, 0.627)    # rgba(220,255,160) — 거품 외곽
const COL_DEEP    := Color(0.227, 0.541, 0.110)  # #3a8a1c — 독 웅덩이

# 크기/타이밍
const TICK_TIME    := 1.2   # 가스/거품 솟구침 지속(s)
const PUDDLE_GROW  := 0.5   # 웅덩이 등장 시간(s)
const PUDDLE_FADE  := 0.3   # 웅덩이 페이드아웃 시간(s)
const PSPEED       := 60.0

# 즉발 — 차지 없음 (battle_manager 동기화용)
const IMPACT_DELAY := 0.0

## SFX/feedback 트리거 — battle_scene 이 수신
signal screen_effect

var _target := Vector2.ZERO
var _smoke_layer: Node2D
var _particles: Array = []
var _ambient_timer := 0.0
var _puddle_age := -1.0  # <0=비활성, 경과 초

func _ready() -> void:
	set_process(false)
	_smoke_layer = _DrawLayer.new()
	_smoke_layer.setup(self)
	add_child(_smoke_layer)

# 첫 인자(caster) 무시 — tick 은 대상 위치에서만
func play(_caster_pos: Vector2, target_pos: Vector2) -> void:
	_target = target_pos
	_ambient_timer = TICK_TIME
	_puddle_age = 0.0
	set_process(true)
	screen_effect.emit()  # 즉시 SFX 트리거
	await get_tree().create_timer(TICK_TIME + PUDDLE_FADE + 0.5).timeout
	if is_inside_tree():
		queue_free()

func _spawn_ambient() -> void:
	# 가스 — 위로 스멀스멀 솟구침
	if randf() < 0.7 * _scale():
		_particles.append({
			"pos": _target + Vector2(randf_range(-35.0, 35.0), randf_range(25.0, 55.0)),
			"vel": Vector2(randf_range(-0.15, 0.15), -0.4 - randf() * 0.5),
			"life": 0.0, "max_life": 1.6 + randf() * 0.8,
			"r": 12.0 + randf() * 12.0, "kind": "gas", "grav": -0.005,
		})
	# 거품 — 웅덩이에서 보글보글 솟아오름
	if randf() < 0.4 * _scale():
		_particles.append({
			"pos": _target + Vector2(randf_range(-30.0, 30.0), randf_range(40.0, 70.0)),
			"vel": Vector2(randf_range(-0.1, 0.1), -0.6 - randf() * 0.7),
			"life": 0.0, "max_life": 0.9 + randf() * 0.5,
			"r": 3.0 + randf() * 4.0, "kind": "bubble", "grav": 0.0,
		})

func _process(delta: float) -> void:
	if _ambient_timer > 0.0:
		_ambient_timer -= delta
		_spawn_ambient()
	if _puddle_age >= 0.0:
		_puddle_age += delta

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

func _draw_smoke_pass(canvas: CanvasItem) -> void:
	# 발 아래 독 웅덩이 (가로로 퍼짐, fade-in/out)
	if _puddle_age >= 0.0:
		var grow: float = clampf(_puddle_age / PUDDLE_GROW, 0.0, 1.0)
		var fade := 1.0
		if _puddle_age > TICK_TIME:
			fade = clampf(1.0 - (_puddle_age - TICK_TIME) / PUDDLE_FADE, 0.0, 1.0)
		if fade > 0.0:
			var pc := _target + Vector2(0.0, 72.0)
			var pud := PackedVector2Array()
			for i in range(22):
				var ang := TAU * float(i) / 22.0
				pud.append(pc + Vector2(cos(ang) * 76.0 * grow, sin(ang) * 17.0))
			canvas.draw_colored_polygon(pud, Color(COL_DEEP, 0.6 * fade))

	# 가스
	for p in _particles:
		if p["kind"] != "gas":
			continue
		var k: float = p["life"] / p["max_life"]
		var a: float = (1.0 - k) * 0.4
		var r: float = p["r"] * (1.0 + k * 1.4)
		canvas.draw_circle(p["pos"], r, Color(COL_GAS, a))

	# 거품 (채움 + 외곽 + 하이라이트)
	for p in _particles:
		if p["kind"] != "bubble":
			continue
		var a: float = 1.0 - p["life"] / p["max_life"]
		canvas.draw_circle(p["pos"], p["r"], Color(COL_DRIP, 0.25 * a))
		canvas.draw_arc(p["pos"], p["r"], 0.0, TAU, 16, Color(COL_DRIP_HL, 0.7 * a), 1.0, true)
		canvas.draw_circle(p["pos"] + Vector2(-p["r"] * 0.35, -p["r"] * 0.35),
			p["r"] * 0.3, Color(1, 1, 1, 0.7 * a))

# 일반 블렌드 단일 레이어
class _DrawLayer:
	extends Node2D
	var _fx: Node2D

	func setup(owner_fx: Node2D) -> void:
		_fx = owner_fx

	func _draw() -> void:
		_fx._draw_smoke_pass(self)
