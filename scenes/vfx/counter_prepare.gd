# scenes/vfx/counter_prepare.gd
# 반사 준비 VFX — ui_sample/vfx/Counter Prepare VFX.html 재현 (COUNTER_PREPARE intent).
# play(_caster, target_pos) — caster 무시, target = 자기 위치.
# ground (캐릭터 뒤): 발치 황동 ring (양방향 chevron 반사 표시) + brass wash
# glow  (캐릭터 앞): facet shards 조립 → hex mirror shield + sheen wipe + 머리 위 sigil
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
const COL_BRASS      := Color(0.909, 0.784, 0.470)         # #e8c878
const COL_BRASS_MID  := Color(0.721, 0.564, 0.164)         # #b8902a
const COL_BRASS_DEEP := Color(0.419, 0.329, 0.094)         # #6b5418
const COL_STEEL      := Color(0.360, 0.862, 1.0)           # #5cdcff (약간의 cyan)

const CHARGE_TIME    := 0.2     # facet 조립 시작
const IMPACT_DELAY   := 0.55    # shield 완성 + screen_effect
const HOLD_TIME      := 0.6     # shield idle + sigil 회전
const FADE_TIME      := 0.4
const RING_RADIUS    := 100.0   # 발치 황동 ring
const RING_SQUASH    := 0.32
const SHIELD_W       := 110.0
const SHIELD_H       := 134.0   # hex 세로 비율
const SHIELD_Y_OFFSET := -30.0  # 캐릭터 중심에서 위로
const SIGIL_Y_OFFSET := -130.0
const SIGIL_R        := 32.0
const FACET_COUNT    := 6       # 조립용 hex 모서리
const PSPEED         := 60.0

## 화면 플래시 + SFX (peak = shield 조립 완성 시점)
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
var _impact_emitted := false
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
	await get_tree().create_timer(IMPACT_DELAY + HOLD_TIME + FADE_TIME + 0.1).timeout
	if is_inside_tree():
		queue_free()

func _process(delta: float) -> void:
	_age += delta
	if not _impact_emitted and _age >= IMPACT_DELAY:
		_impact_emitted = true
		screen_effect.emit()
	_ground_layer.queue_redraw()
	_glow_layer.queue_redraw()

func _global_alpha() -> float:
	if _age < IMPACT_DELAY + HOLD_TIME:
		return clampf(_age / 0.15, 0.0, 1.0)
	var t: float = (_age - (IMPACT_DELAY + HOLD_TIME)) / FADE_TIME
	return clampf(1.0 - t, 0.0, 1.0)

# 캐릭터 중심 위치 (shield 가운데) — _target 기준 약간 위로 보정
func _shield_center() -> Vector2:
	return _target + Vector2(0.0, SHIELD_Y_OFFSET)

# hex 꼭짓점 6개 — 중심·크기·회전
func _hex_points(ctr: Vector2, w_half: float, h_half: float) -> PackedVector2Array:
	# pointy-top hex: 위·아래 꼭짓점 + 좌상/좌하/우상/우하
	return PackedVector2Array([
		ctr + Vector2(0.0, -h_half),
		ctr + Vector2(w_half, -h_half * 0.5),
		ctr + Vector2(w_half, h_half * 0.5),
		ctr + Vector2(0.0, h_half),
		ctr + Vector2(-w_half, h_half * 0.5),
		ctr + Vector2(-w_half, -h_half * 0.5),
	])

# ── ground (가산, 캐릭터 뒤) — 발치 황동 ring + 양방향 chevron + brass wash ──
func _draw_ground_pass(canvas: CanvasItem) -> void:
	var ga: float = _global_alpha()
	if ga <= 0.0:
		return
	_draw_ground_ring(canvas, ga)
	# brass wash — peak 후
	if _impact_emitted:
		var wash_t: float = (_age - IMPACT_DELAY) / 0.4
		var wash_alpha: float = clampf(wash_t, 0.0, 1.0) * 0.4 * ga
		if _age > IMPACT_DELAY + HOLD_TIME:
			wash_alpha *= clampf(1.0 - (_age - IMPACT_DELAY - HOLD_TIME) / FADE_TIME, 0.0, 1.0)
		if wash_alpha > 0.0:
			var seg := 32
			var pts := PackedVector2Array()
			for i in range(seg + 1):
				var a: float = TAU * float(i) / float(seg)
				pts.append(_target + Vector2(cos(a) * 160.0, sin(a) * 120.0))
			canvas.draw_colored_polygon(pts, Color(COL_BRASS_DEEP, wash_alpha))

# 발치 황동 ring — 외곽 원 + 점선 안쪽 원 + 양방향 chevron
func _draw_ground_ring(canvas: CanvasItem, ga: float) -> void:
	var grow: float = clampf(_age / 0.4, 0.0, 1.0)
	if grow <= 0.0:
		return
	var fade: float = 1.0
	if _age > IMPACT_DELAY + HOLD_TIME:
		fade = clampf(1.0 - (_age - IMPACT_DELAY - HOLD_TIME) / FADE_TIME, 0.0, 1.0)
	if fade <= 0.0:
		return
	var alpha: float = grow * fade * ga * 0.9
	var foot: Vector2 = _foot_pos()
	var r: float = RING_RADIUS * grow
	# 외곽 원
	var seg := 48
	var pts := PackedVector2Array()
	for i in range(seg + 1):
		var a: float = TAU * float(i) / float(seg)
		pts.append(foot + Vector2(cos(a) * r, sin(a) * r * RING_SQUASH))
	canvas.draw_polyline(pts, Color(COL_BRASS, alpha), 2.0, true)
	# 점선 안쪽 원
	for i in range(12):
		var a0: float = TAU * float(i) / 12.0
		var a1: float = a0 + TAU / 24.0
		var dr: float = r * 0.85
		var arc := PackedVector2Array()
		for k in range(4):
			var t: float = float(k) / 3.0
			var ang: float = lerpf(a0, a1, t)
			arc.append(foot + Vector2(cos(ang) * dr, sin(ang) * dr * RING_SQUASH))
		canvas.draw_polyline(arc, Color(COL_BRASS_MID, alpha * 0.7), 1.0, true)
	# 양방향 chevron — 좌측에서 → 가운데, 우측에서 → 가운데 (반사 컨셉)
	for dir in [-1.0, 1.0]:
		var tip_x: float = dir * r * 0.4
		var tip: Vector2 = foot + Vector2(tip_x, 0.0)
		var back_x: float = dir * r * 0.85
		var back: Vector2 = foot + Vector2(back_x, 0.0)
		var perp_y: float = r * 0.22 * RING_SQUASH
		canvas.draw_line(back + Vector2(0.0, -perp_y), tip, Color(COL_BRASS, alpha), 2.5, true)
		canvas.draw_line(back + Vector2(0.0, perp_y), tip, Color(COL_BRASS, alpha), 2.5, true)
	# 8 tick (외곽 — 각도 표시)
	for i in range(8):
		var ang_t: float = TAU * float(i) / 8.0
		var p_in: Vector2 = foot + Vector2(cos(ang_t) * r * 1.02, sin(ang_t) * r * 1.02 * RING_SQUASH)
		var p_out: Vector2 = foot + Vector2(cos(ang_t) * r * 1.12, sin(ang_t) * r * 1.12 * RING_SQUASH)
		canvas.draw_line(p_in, p_out, Color(COL_BRASS, alpha * 0.85), 1.5, true)

# ── glow (가산, 캐릭터 앞) — facet shards → hex mirror shield + sheen + sigil ──
func _draw_glow_pass(canvas: CanvasItem) -> void:
	var ga: float = _global_alpha()
	if ga <= 0.0:
		return
	# Phase 1: facet shards 조립 (CHARGE_TIME~IMPACT_DELAY)
	if _age < IMPACT_DELAY:
		_draw_facets(canvas, ga)
	# Phase 2~3: hex shield (peak~)
	if _impact_emitted:
		_draw_shield(canvas, ga)
		_draw_sigil(canvas, ga)

# 조립 페이즈 — 6개 facet shards 가 외곽에서 shield 중심으로 수렴
func _draw_facets(canvas: CanvasItem, ga: float) -> void:
	var t: float = clampf((_age - CHARGE_TIME) / (IMPACT_DELAY - CHARGE_TIME), 0.0, 1.0)
	if t <= 0.0:
		return
	var ctr: Vector2 = _shield_center()
	var hex_pts := _hex_points(ctr, SHIELD_W * 0.5, SHIELD_H * 0.5)
	# 각 facet 은 외곽에서 hex 꼭짓점으로 이동
	for i in range(FACET_COUNT):
		var end_pt: Vector2 = hex_pts[i]
		var ang: float = TAU * float(i) / float(FACET_COUNT)
		var start_pt: Vector2 = ctr + Vector2(cos(ang), sin(ang)) * SHIELD_W * 1.4
		var pos := start_pt.lerp(end_pt, t)
		var alpha: float = clampf(t * 2.0, 0.0, 1.0) * ga
		# 다이아 모양 (작은 사각, 45도 회전)
		var sz: float = 8.0 * (0.5 + t * 0.5)
		canvas.draw_colored_polygon(PackedVector2Array([
			pos + Vector2(0, -sz), pos + Vector2(sz, 0),
			pos + Vector2(0, sz), pos + Vector2(-sz, 0),
		]), Color(COL_BRASS, alpha * 0.85))
		canvas.draw_polyline(PackedVector2Array([
			pos + Vector2(0, -sz), pos + Vector2(sz, 0),
			pos + Vector2(0, sz), pos + Vector2(-sz, 0),
			pos + Vector2(0, -sz),
		]), Color(COL_HOT, alpha), 1.0, true)

# hex mirror shield — peak 시 조립 완성 + sheen wipe + idle pulse
func _draw_shield(canvas: CanvasItem, ga: float) -> void:
	var post: float = _age - IMPACT_DELAY
	# pop 0~0.15s: scale 1.06→1.0
	var pop: float = clampf(post / 0.15, 0.0, 1.0)
	# idle breath: scale 1.0±0.02
	var breath: float = sin(post * (TAU / 3.2)) * 0.02 + 1.0
	# fade out: hold 끝나면 0.5s
	var fade: float = 1.0
	if _age > IMPACT_DELAY + HOLD_TIME:
		fade = clampf(1.0 - (_age - IMPACT_DELAY - HOLD_TIME) / 0.5, 0.0, 1.0)
	if fade <= 0.0:
		return
	var sc: float = lerpf(1.06, breath, pop)
	var alpha: float = pop * fade * ga
	var ctr: Vector2 = _shield_center()
	var w_half: float = SHIELD_W * 0.5 * sc
	var h_half: float = SHIELD_H * 0.5 * sc
	var hex := _hex_points(ctr, w_half, h_half)
	# 내부 채움 (옅은 황동 + cyan 그라데이션 흉내)
	canvas.draw_colored_polygon(hex, Color(COL_BRASS_DEEP, alpha * 0.4))
	# 외곽 황동 윤곽
	var poly := PackedVector2Array(hex)
	poly.append(hex[0])
	canvas.draw_polyline(poly, Color(COL_BRASS, alpha), 2.5, true)
	# 내부 작은 hex (코어)
	var hex2 := _hex_points(ctr, w_half * 0.5, h_half * 0.5)
	var poly2 := PackedVector2Array(hex2)
	poly2.append(hex2[0])
	canvas.draw_polyline(poly2, Color(COL_STEEL, alpha * 0.7), 1.5, true)
	# sheen wipe — peak 직후 0.65s 동안 가로지름
	var sheen_t: float = post / 0.55
	if sheen_t > 0.0 and sheen_t < 1.0:
		var sheen_alpha: float = sin(sheen_t * PI) * alpha
		# 가로지르는 흰 직사각형 — hex 영역 안에 (clip 없으니 hex bbox 내 직선 2개로 흉내)
		var sheen_x: float = lerpf(-w_half * 1.2, w_half * 1.2, sheen_t)
		var p1: Vector2 = ctr + Vector2(sheen_x, -h_half)
		var p2: Vector2 = ctr + Vector2(sheen_x + w_half * 0.25, h_half)
		canvas.draw_line(p1, p2, Color(COL_HOT, sheen_alpha * 0.95), 3.0, true)
		canvas.draw_line(p1 + Vector2(-6.0, 0.0), p2 + Vector2(-6.0, 0.0), Color(COL_BRASS, sheen_alpha * 0.55), 2.0, true)
	# 중심 작은 점 (mirror reflection center)
	canvas.draw_circle(ctr, 3.0, Color(COL_HOT, alpha))

# 머리 위 sigil — 황동 ring + 양방향 chevron + 중심 다이아 (반사 표식, 회전)
func _draw_sigil(canvas: CanvasItem, ga: float) -> void:
	var post: float = _age - IMPACT_DELAY
	var pop: float = clampf(post / 0.45, 0.0, 1.0)
	var fade: float = 1.0
	if _age > IMPACT_DELAY + HOLD_TIME:
		fade = clampf(1.0 - (_age - IMPACT_DELAY - HOLD_TIME) / 0.5, 0.0, 1.0)
	if fade <= 0.0:
		return
	var sc: float = lerpf(0.4, 1.0, pop)
	var alpha: float = pop * fade * ga
	# 천천히 회전
	var rot: float = post * (TAU / 12.0)
	var ctr: Vector2 = _target + Vector2(0.0, SIGIL_Y_OFFSET)
	var r: float = SIGIL_R * sc
	# 외곽 ring
	canvas.draw_arc(ctr, r, 0.0, TAU, 32, Color(COL_BRASS, alpha * 0.9), 1.5, true)
	# 점선 안쪽 원
	for i in range(8):
		var a0: float = TAU * float(i) / 8.0 + rot
		var a1: float = a0 + TAU / 16.0
		canvas.draw_arc(ctr, r * 0.7, a0, a1, 3, Color(COL_BRASS_MID, alpha * 0.7), 1.0, true)
	# 양방향 chevron (반사 → ←)
	for dir in [-1.0, 1.0]:
		var dx: float = cos(rot) * dir
		var dy: float = sin(rot) * dir
		var fwd := Vector2(dx, dy)
		var perp := Vector2(-dy, dx) * r * 0.22
		var tip: Vector2 = ctr + fwd * r * 0.35
		var back: Vector2 = ctr + fwd * r * 0.8
		canvas.draw_line(back + perp, tip, Color(COL_BRASS, alpha), 1.8, true)
		canvas.draw_line(back - perp, tip, Color(COL_BRASS, alpha), 1.8, true)
	# 중심 다이아 (흰)
	var dsz: float = 4.0 * sc
	canvas.draw_colored_polygon(PackedVector2Array([
		ctr + Vector2(0, -dsz), ctr + Vector2(dsz, 0),
		ctr + Vector2(0, dsz), ctr + Vector2(-dsz, 0),
	]), Color(COL_HOT, alpha))

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
