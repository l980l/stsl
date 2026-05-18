# scenes/vfx/card_exhaust.gd
# 카드 소진 (EXHAUST) VFX — ui_sample/vfx/Card Exhaust VFX.html 재현.
# 카드 위에 적용되는 효과: ember line 위→아래 + 황금 잿불 + 회색 재 + EXHAUST stamp.
# play(_caster_pos, target_pos) — target_pos = 카드 중심.
# set_card_size(size) — 카드 가로/세로 크기 (기본 180x250).
# 카드 본체의 fade out 은 외부에서 처리 (이 VFX 는 카드 영역 위의 효과만 그림).
extends Node2D

var _particle_scale_override: float = -1.0

func _pcount(n: int) -> int:
	if _particle_scale_override > 0.0:
		return maxi(1, int(round(n * _particle_scale_override)))
	var gs := get_node_or_null("/root/GameSettings")
	return n if gs == null else maxi(1, int(round(n * gs.particle_count_scale())))

func _scale() -> float:
	if _particle_scale_override > 0.0:
		return _particle_scale_override
	var gs := get_node_or_null("/root/GameSettings")
	return 1.0 if gs == null else gs.particle_count_scale()


const COL_HOT   := Color(1.0, 1.0, 1.0)
const COL_EMBER := Color(0.956, 0.862, 0.627)   # #f4dca0
const COL_FIRE  := Color(1.0, 0.541, 0.227)     # #ff8a3a
const COL_CHAR  := Color(0.227, 0.121, 0.047)   # #3a1f0c
const COL_ASH   := Color(0.478, 0.454, 0.4)     # #7a7466

const CARD_W       := 180.0
const CARD_H       := 250.0
const IMPACT_DELAY := 0.1
const SWEEP_TIME   := 0.9              # ember line 위→아래 이동 시간
const HOLD_TIME    := 1.0              # IMPACT 이후 효과 진행 (sweep 포함)
const FADE_TIME    := 0.3
const PSPEED       := 60.0

signal screen_effect

var _card_pos := Vector2.ZERO
var _card_size := Vector2(CARD_W, CARD_H)
var _age := -1.0
var _impact_emitted := false
var _particles: Array = []
var _ash_layer: Node2D     # normal blend — 회색 재 (가산이면 안 보임)
var _glow_layer: Node2D    # 가산 blend — ember line, embers, flash, stamp

# 카드 크기 override — vfx_preview 에서는 더미 카드 크기, 게임에선 실제 카드 노드 크기.
func set_card_size(size: Vector2) -> void:
	_card_size = size

func _ready() -> void:
	set_process(false)
	_ash_layer = _DrawLayer.new()
	_ash_layer.setup(self, false)
	add_child(_ash_layer)
	_ash_layer.set_meta("pass", "ash")
	_glow_layer = _DrawLayer.new()
	_glow_layer.setup(self, true)
	add_child(_glow_layer)
	_glow_layer.set_meta("pass", "glow")

func play(_caster_pos: Vector2, target_pos: Vector2) -> void:
	_card_pos = target_pos
	_age = 0.0
	set_process(true)
	await get_tree().create_timer(IMPACT_DELAY + HOLD_TIME + FADE_TIME + 0.1).timeout
	if is_inside_tree():
		queue_free()

func _card_rect() -> Rect2:
	return Rect2(_card_pos - _card_size * 0.5, _card_size)

# 현재 sweep y 위치 (ember line 의 y)
func _sweep_y() -> float:
	var sweep_t: float = clampf((_age - IMPACT_DELAY) / SWEEP_TIME, 0.0, 1.0)
	var rect := _card_rect()
	return rect.position.y + sweep_t * rect.size.y

func _spawn_ember() -> void:
	var rect := _card_rect()
	var px: float = rect.position.x + randf() * rect.size.x
	var py: float = _sweep_y() + randf_range(-10.0, 10.0)
	_particles.append({
		"pos": Vector2(px, py),
		"vel": Vector2(randf_range(-0.3, 0.3), -1.0 - randf() * 1.4),
		"life": 0.0,
		"max_life": 0.8 + randf() * 0.6,
		"size": 1.4 + randf() * 1.4,
		"kind": "ember",
	})

func _spawn_ash() -> void:
	var rect := _card_rect()
	var px: float = rect.position.x + randf() * rect.size.x
	var py: float = _sweep_y() + randf_range(-5.0, 15.0)
	_particles.append({
		"pos": Vector2(px, py),
		"vel": Vector2(randf_range(-0.3, 0.3), 0.5 + randf() * 1.0),
		"life": 0.0,
		"max_life": 1.4 + randf() * 0.8,
		"size": 1.8 + randf() * 1.4,
		"kind": "ash",
		"rot": randf() * TAU,
		"rot_v": randf_range(-2.0, 2.0),
	})

func _process(delta: float) -> void:
	_age += delta
	if not _impact_emitted and _age >= IMPACT_DELAY:
		_impact_emitted = true
		screen_effect.emit()
	if _age >= IMPACT_DELAY and _age < IMPACT_DELAY + SWEEP_TIME:
		for _i in range(_pcount(2)):
			_spawn_ember()
		if randf() < 0.6 * _scale():
			_spawn_ash()

	var alive: Array = []
	for p in _particles:
		p["life"] += delta
		if p["life"] >= p["max_life"]:
			continue
		p["pos"] += p["vel"] * delta * PSPEED
		if p.has("rot"):
			p["rot"] += p["rot_v"] * delta
		alive.append(p)
	_particles = alive

	_ash_layer.queue_redraw()
	_glow_layer.queue_redraw()

func _global_alpha() -> float:
	var end_phase: float = IMPACT_DELAY + HOLD_TIME
	if _age < end_phase:
		return clampf(_age / 0.1, 0.0, 1.0)
	var t: float = (_age - end_phase) / FADE_TIME
	return clampf(1.0 - t, 0.0, 1.0)

# ── ash (normal blend) — 회색 재 입자 ──
func _draw_ash_pass(canvas: CanvasItem) -> void:
	var ga: float = _global_alpha()
	if ga <= 0.0:
		return
	for p in _particles:
		if p["kind"] != "ash":
			continue
		var k: float = p["life"] / p["max_life"]
		var a: float = (1.0 - k) * ga * 0.85
		var pr: float = p["size"]
		var rot: float = p.get("rot", 0.0)
		# 작은 회전 ellipse (재 모양)
		var pts := PackedVector2Array()
		var seg := 8
		for i in range(seg + 1):
			var ang: float = TAU * float(i) / float(seg)
			var lx: float = cos(ang) * pr * 1.3
			var ly: float = sin(ang) * pr * 0.7
			var rx: float = lx * cos(rot) - ly * sin(rot)
			var ry: float = lx * sin(rot) + ly * cos(rot)
			pts.append(p["pos"] + Vector2(rx, ry))
		canvas.draw_colored_polygon(pts, Color(COL_ASH.r, COL_ASH.g, COL_ASH.b, a))

# ── glow (가산 blend) — ember line, embers, flash ──
func _draw_glow_pass(canvas: CanvasItem) -> void:
	var ga: float = _global_alpha()
	if ga <= 0.0:
		return
	_draw_ember_line(canvas, ga)
	for p in _particles:
		if p["kind"] != "ember":
			continue
		var k: float = p["life"] / p["max_life"]
		var a: float = (1.0 - k) * ga
		var pr: float = p["size"]
		canvas.draw_circle(p["pos"], pr * 1.8, Color(COL_EMBER.r, COL_EMBER.g, COL_EMBER.b, a * 0.45))
		canvas.draw_circle(p["pos"], pr, Color(COL_EMBER.r, COL_EMBER.g, COL_EMBER.b, a))
	_draw_flash(canvas, ga)

# ember line — 카드 가로 폭, 위→아래 sweep
func _draw_ember_line(canvas: CanvasItem, ga: float) -> void:
	if _age < IMPACT_DELAY:
		return
	var sweep_t: float = clampf((_age - IMPACT_DELAY) / SWEEP_TIME, 0.0, 1.0)
	if sweep_t >= 1.0:
		return
	var rect := _card_rect()
	var line_y: float = rect.position.y + sweep_t * rect.size.y
	var alpha: float = ga
	# 글로우 (넓고 옅게)
	var glow_h := 24.0
	canvas.draw_rect(Rect2(rect.position.x - 8.0, line_y - glow_h * 0.5, rect.size.x + 16.0, glow_h),
		Color(COL_EMBER.r, COL_EMBER.g, COL_EMBER.b, alpha * 0.25))
	# 화염 (중간 두께, 주황)
	var fire_h := 8.0
	canvas.draw_rect(Rect2(rect.position.x, line_y - fire_h * 0.5, rect.size.x, fire_h),
		Color(COL_FIRE.r, COL_FIRE.g, COL_FIRE.b, alpha * 0.95))
	# 코어 (얇은 흰 선)
	var core_h := 2.5
	canvas.draw_rect(Rect2(rect.position.x, line_y - core_h * 0.5, rect.size.x, core_h),
		Color(COL_HOT.r, COL_HOT.g, COL_HOT.b, alpha))

# 카드 영역 중심에 짧은 황금 flash
func _draw_flash(canvas: CanvasItem, ga: float) -> void:
	var post: float = _age - IMPACT_DELAY
	if post < 0.0 or post > 0.5:
		return
	var t: float = post / 0.5
	var alpha: float
	if t < 0.15:
		alpha = t / 0.15
	else:
		alpha = 1.0 - (t - 0.15) / 0.85
	alpha *= ga * 0.85
	if alpha <= 0.0:
		return
	canvas.draw_circle(_card_pos, _card_size.x * 0.7, Color(COL_EMBER.r, COL_EMBER.g, COL_EMBER.b, alpha * 0.4))
	canvas.draw_circle(_card_pos, _card_size.x * 0.4, Color(COL_HOT.r, COL_HOT.g, COL_HOT.b, alpha * 0.55))

# ── 블렌드 분리 레이어 ──
class _DrawLayer:
	extends Node2D
	var _fx: Node2D

	func setup(owner_fx: Node2D, additive: bool) -> void:
		_fx = owner_fx
		if additive:
			var m := CanvasItemMaterial.new()
			m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
			material = m

	func _draw() -> void:
		match get_meta("pass", "glow"):
			"ash": _fx._draw_ash_pass(self)
			_:    _fx._draw_glow_pass(self)
