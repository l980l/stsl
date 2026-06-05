# scenes/vfx/prepare.gd
# 준비 VFX — ui_sample/vfx/Prepare VFX.html 재현 (적 PREPARE intent, 효과 없는 1턴 빈 행동).
# play(_caster, target_pos) — caster 무시, target = 자기 위치. CHARGE_UP 의 power_up 보다 절제·차분.
# ground (캐릭터 뒤): 발치 작은 회전 ring + dim brew wash
# glow  (캐릭터 앞): 가슴 작은 orb (throb) + 머리 위 작은 glyph (anticipation)
extends Node2D

# 파티클 갯수 — GameSettings.particle_count_scale 적용
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


const COL_HOT        := Color(1.0, 1.0, 1.0)
const COL_WARN       := Color(1.0, 0.541, 0.290)         # #ff8a4a 주황
const COL_WARN_DEEP  := Color(0.478, 0.200, 0.094)       # #7a3318
const COL_BLOOD      := Color(0.850, 0.290, 0.313)       # #d94a50
const COL_BLOOD_MID  := Color(0.545, 0.101, 0.121)       # #8b1a1f
const COL_BRASS      := Color(0.909, 0.784, 0.470)       # #e8c878
const COL_BONE       := Color(0.964, 0.945, 0.901)       # #f6f1e6

const CHARGE_TIME    := 0.3      # orb ignite + ring 등장
const IMPACT_DELAY   := 0.0      # PREPARE 는 효과 없음 — 차지 대기 X (battle_manager 그대로 진행)
const BREW_TIME      := 0.8      # throb + glyph float (시각만 유지)
const FADE_TIME      := 0.4
const RING_RADIUS    := 70.0     # 작은 발치 ring
const RING_SQUASH    := 0.32
const ORB_R          := 10.0     # 가슴 orb 반경
const ORB_Y_OFFSET   := -50.0    # 캐릭터 가슴 위치
const GLYPH_Y_OFFSET := -110.0
const GLYPH_R        := 14.0
const WASH_R         := 110.0    # 캐릭터 뒤 dim wash 반경
const PSPEED         := 60.0

## 시그널 — 호출처가 connect 가능하지만 PREPARE 는 emit 안 함 (효과 없는 턴)
@warning_ignore("unused_signal")
signal screen_effect

var _target := Vector2.ZERO
var _ground_pos := Vector2.ZERO
var _has_ground: bool = false

func set_ground_anchor(pos: Vector2) -> void:
	_ground_pos = pos
	_has_ground = true
	if _ground_layer != null:
		_ground_layer.z_as_relative = false
		_ground_layer.z_index = int(pos.y) - 1

func _foot_pos() -> Vector2:
	return _ground_pos if _has_ground else _target + Vector2(0.0, 60.0)

var _age := -1.0
var _ground_layer: Node2D
var _glow_layer: Node2D

func _ready() -> void:
	set_process(false)
	_ground_layer = _DrawLayer.new()
	_ground_layer.setup(self, true)
	add_child(_ground_layer)
	_ground_layer.set_meta("pass", "ground")
	_glow_layer = _DrawLayer.new()
	_glow_layer.setup(self, true)
	add_child(_glow_layer)
	_glow_layer.set_meta("pass", "glow")

func play(_caster_pos: Vector2, target_pos: Vector2) -> void:
	_target = target_pos
	_age = 0.0
	set_process(true)
	await get_tree().create_timer(CHARGE_TIME + BREW_TIME + FADE_TIME + 0.1).timeout
	if is_inside_tree():
		queue_free()

func _process(delta: float) -> void:
	_age += delta
	_ground_layer.queue_redraw()
	_glow_layer.queue_redraw()

func _global_alpha() -> float:
	if _age < CHARGE_TIME + BREW_TIME:
		return clampf(_age / 0.15, 0.0, 1.0)
	var t: float = (_age - (CHARGE_TIME + BREW_TIME)) / FADE_TIME
	return clampf(1.0 - t, 0.0, 1.0)

# ── ground (가산, 캐릭터 뒤) — 발치 작은 ring + dim brew wash ──
func _draw_ground_pass(canvas: CanvasItem) -> void:
	var ga: float = _global_alpha()
	if ga <= 0.0:
		return
	_draw_brew_wash(canvas, ga)
	_draw_ring(canvas, ga)

# 캐릭터 뒤 dim 주황 wash — 차분히 밝아짐
func _draw_brew_wash(canvas: CanvasItem, ga: float) -> void:
	var grow: float = clampf(_age / 0.6, 0.0, 1.0)
	# intense pulse (전체 시간)
	var pulse: float = 0.7 + sin(_age * (TAU / 1.4)) * 0.18
	var fade: float = 1.0
	if _age > CHARGE_TIME + BREW_TIME:
		fade = clampf(1.0 - (_age - CHARGE_TIME - BREW_TIME) / FADE_TIME, 0.0, 1.0)
	var alpha: float = grow * fade * ga * pulse * 0.4
	if alpha <= 0.0:
		return
	var ctr: Vector2 = _target + Vector2(0.0, -30.0)
	var seg := 28
	var pts := PackedVector2Array()
	for i in range(seg + 1):
		var a: float = TAU * float(i) / float(seg)
		pts.append(ctr + Vector2(cos(a) * WASH_R, sin(a) * WASH_R * 0.85))
	canvas.draw_colored_polygon(pts, Color(COL_WARN_DEEP, alpha))
	# 내층 (약간 더 짙은 빨강)
	var pts2 := PackedVector2Array()
	for i in range(seg + 1):
		var a: float = TAU * float(i) / float(seg)
		pts2.append(ctr + Vector2(cos(a) * WASH_R * 0.55, sin(a) * WASH_R * 0.55 * 0.85))
	canvas.draw_colored_polygon(pts2, Color(COL_BLOOD_MID, alpha * 0.5))

# 발치 작은 회전 ring — 외원 + 단일 chevron 4개 (느린 회전)
func _draw_ring(canvas: CanvasItem, ga: float) -> void:
	var grow: float = clampf(_age / 0.45, 0.0, 1.0)
	if grow <= 0.0:
		return
	var fade: float = 1.0
	if _age > CHARGE_TIME + BREW_TIME:
		fade = clampf(1.0 - (_age - CHARGE_TIME - BREW_TIME) / FADE_TIME, 0.0, 1.0)
	if fade <= 0.0:
		return
	var alpha: float = grow * fade * ga * 0.7
	var foot: Vector2 = _foot_pos()
	var r: float = RING_RADIUS * grow
	# 외곽 원 (옅은 주황)
	var seg := 32
	var pts := PackedVector2Array()
	for i in range(seg + 1):
		var a: float = TAU * float(i) / float(seg)
		pts.append(foot + Vector2(cos(a) * r, sin(a) * r * RING_SQUASH))
	canvas.draw_polyline(pts, Color(COL_WARN, alpha), 1.5, true)
	# 4 chevron 마커 — 회전, 매우 천천히
	var rot: float = _age * 0.3
	for i in range(4):
		var ang: float = rot + TAU * float(i) / 4.0
		var tip: Vector2 = foot + Vector2(cos(ang) * r * 0.55, sin(ang) * r * 0.55 * RING_SQUASH)
		var perp_ang: float = ang + PI * 0.5
		var perp: Vector2 = Vector2(cos(perp_ang), sin(perp_ang) * RING_SQUASH) * r * 0.14
		var back: Vector2 = tip + Vector2(cos(ang + PI), sin(ang + PI) * RING_SQUASH) * r * 0.18
		canvas.draw_line(back + perp, tip, Color(COL_WARN, alpha * 0.9), 1.5, true)
		canvas.draw_line(back - perp, tip, Color(COL_WARN, alpha * 0.9), 1.5, true)

# ── glow (가산, 캐릭터 앞) — 가슴 orb + 머리 위 작은 glyph ──
func _draw_glow_pass(canvas: CanvasItem) -> void:
	var ga: float = _global_alpha()
	if ga <= 0.0:
		return
	_draw_orb(canvas, ga)
	_draw_glyph(canvas, ga)

# 가슴 작은 orb — ignite (~CHARGE_TIME) 후 throb
func _draw_orb(canvas: CanvasItem, ga: float) -> void:
	var ignite: float = clampf(_age / CHARGE_TIME, 0.0, 1.0)
	if ignite <= 0.0:
		return
	var fade: float = 1.0
	if _age > CHARGE_TIME + BREW_TIME:
		fade = clampf(1.0 - (_age - CHARGE_TIME - BREW_TIME) / FADE_TIME, 0.0, 1.0)
	if fade <= 0.0:
		return
	# throb — 1.0 ± 0.18
	var post: float = max(0.0, _age - CHARGE_TIME)
	var throb: float = 1.0 + sin(post * (TAU / 1.6)) * 0.18
	var sc: float = lerpf(0.2, throb, ignite)
	var alpha: float = ignite * fade * ga
	var ctr: Vector2 = _target + Vector2(0.0, ORB_Y_OFFSET)
	var r: float = ORB_R * sc
	# 외층 (옅은 빨강)
	canvas.draw_circle(ctr, r * 2.5, Color(COL_BLOOD, alpha * 0.35))
	# 중층 (주황)
	canvas.draw_circle(ctr, r * 1.5, Color(COL_WARN, alpha * 0.7))
	# 코어 (밝은)
	canvas.draw_circle(ctr, r * 0.6, Color(COL_HOT, alpha * 0.95))

# 머리 위 작은 anticipation glyph — 황동 마름모 + 작은 chevron (절제된 표식)
func _draw_glyph(canvas: CanvasItem, ga: float) -> void:
	var pop: float = clampf((_age - 0.15) / 0.45, 0.0, 1.0)
	if pop <= 0.0:
		return
	var fade: float = 1.0
	if _age > CHARGE_TIME + BREW_TIME:
		fade = clampf(1.0 - (_age - CHARGE_TIME - BREW_TIME) / FADE_TIME, 0.0, 1.0)
	if fade <= 0.0:
		return
	# float
	var float_y: float = sin(_age * (TAU / 2.6)) * 2.5
	var sc: float = lerpf(0.3, 1.0, pop)
	var alpha: float = pop * fade * ga * 0.85
	var ctr: Vector2 = _target + Vector2(0.0, GLYPH_Y_OFFSET + float_y)
	var r: float = GLYPH_R * sc
	# 마름모 (황동)
	canvas.draw_polyline(PackedVector2Array([
		ctr + Vector2(0, -r), ctr + Vector2(r * 0.7, 0),
		ctr + Vector2(0, r), ctr + Vector2(-r * 0.7, 0),
		ctr + Vector2(0, -r),
	]), Color(COL_BRASS, alpha), 1.4, true)
	# 위쪽 작은 chevron (∧)
	var ch_y: float = -r * 0.35
	var ch_w: float = r * 0.45
	canvas.draw_line(ctr + Vector2(-ch_w, ch_y + 4), ctr + Vector2(0, ch_y - 2), Color(COL_HOT, alpha * 0.9), 1.5, true)
	canvas.draw_line(ctr + Vector2(0, ch_y - 2), ctr + Vector2(ch_w, ch_y + 4), Color(COL_HOT, alpha * 0.9), 1.5, true)
	# 중심 작은 점 (빨강)
	canvas.draw_circle(ctr, 2.0, Color(COL_BLOOD, alpha))

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
		if get_meta("pass", "glow") == "ground":
			_fx._draw_ground_pass(self)
		else:
			_fx._draw_glow_pass(self)
