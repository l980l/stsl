# scenes/vfx/poison_tick.gd
# 독 지속피해(DoT) tick 시 사용 — poison_splash 의 잔류 가스만 추출.
# 차지/비행 없이 target 위치에서 가스가 스멀스멀 솟구침. SFX = impact_poison (poison_splash 와 동일).
# battle_manager 의 _tick_*_poison 시점에 .new() → add_child → play(target, target).
extends Node2D

const COL_GAS := Color(0.627, 0.863, 0.314)  # rgba(160,220,80) — 독가스

# 크기/타이밍
const TICK_TIME := 1.2   # 가스 솟구침 지속(s)
const PSPEED    := 60.0

# 즉발 — 차지 없음. battle_manager 의 _vfx_impact_delay 가 0 반환하도록 노출 (현재 미사용 — 데미지 시그널과 별도 흐름).
const IMPACT_DELAY := 0.0

## SFX/feedback 트리거 — battle_scene 이 수신
signal screen_effect

var _target := Vector2.ZERO
var _smoke_layer: Node2D
var _particles: Array = []
var _ambient_timer := 0.0

func _ready() -> void:
	set_process(false)
	_smoke_layer = _DrawLayer.new()
	_smoke_layer.setup(self)
	add_child(_smoke_layer)

# 첫 인자(caster) 무시 — tick 은 대상 위치에서만
func play(_caster_pos: Vector2, target_pos: Vector2) -> void:
	_target = target_pos
	_ambient_timer = TICK_TIME
	set_process(true)
	screen_effect.emit()  # 즉시 SFX 트리거 (impact_poison)
	await get_tree().create_timer(TICK_TIME + 1.0).timeout
	if is_inside_tree():
		queue_free()

func _spawn_ambient() -> void:
	if randf() < 0.7:
		_particles.append({
			"pos": _target + Vector2(randf_range(-35.0, 35.0), randf_range(25.0, 55.0)),
			"vel": Vector2(randf_range(-0.15, 0.15), -0.4 - randf() * 0.5),
			"life": 0.0, "max_life": 1.6 + randf() * 0.8,
			"r": 12.0 + randf() * 12.0,
		})

func _process(delta: float) -> void:
	if _ambient_timer > 0.0:
		_ambient_timer -= delta
		_spawn_ambient()

	var damp: float = pow(0.992, delta * 60.0)
	var alive: Array = []
	for p in _particles:
		p["life"] += delta
		if p["life"] >= p["max_life"]:
			continue
		p["pos"] += p["vel"] * delta * PSPEED
		p["vel"].y += -0.005 * delta * PSPEED
		p["vel"] *= damp
		alive.append(p)
	_particles = alive
	_smoke_layer.queue_redraw()

func _draw_smoke_pass(canvas: CanvasItem) -> void:
	for p in _particles:
		var k: float = p["life"] / p["max_life"]
		var a: float = (1.0 - k) * 0.4
		var r: float = p["r"] * (1.0 + k * 1.4)
		canvas.draw_circle(p["pos"], r, Color(COL_GAS, a))

# 일반 블렌드 단일 레이어 (가스만)
class _DrawLayer:
	extends Node2D
	var _fx: Node2D

	func setup(owner_fx: Node2D) -> void:
		_fx = owner_fx

	func _draw() -> void:
		_fx._draw_smoke_pass(self)
