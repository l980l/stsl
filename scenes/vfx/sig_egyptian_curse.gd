# scenes/vfx/sig_egyptian_curse.gd
# 이집트 신화 시그너처 — 저주 (NETER).
# ui_sample/vfx/Curse VFX.html 재현. 적 ATTACK 적중 시 영웅에 자동 vulnerable +1.
# 작고 짧음 (~0.7s) — 모든 공격마다 발동이라 화면 부담 최소화.
# play(_caster_pos, target_pos) — caster 무시. target = 피해 입은 영웅 위치.
# ground: 영웅 발치 작은 황금 wash.
# glow: 영웅 머리 위 호루스의 눈 stamp + 상형문자 drift + vuln mark.
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


const COL_HOT       := Color(1.0, 1.0, 1.0)
const COL_GOLD      := Color(0.956, 0.862, 0.627)   # #f4dca0
const COL_GOLD_DEEP := Color(0.721, 0.564, 0.164)   # #b8902a
const COL_INK       := Color(0.039, 0.031, 0.019)   # #0a0805
const COL_BLUE      := Color(0.117, 0.305, 0.603)   # #1e4e9a 호루스 동공
const COL_VULN      := Color(0.850, 0.478, 0.627)   # #d97aa0 — vulnerable 핑크

const STAMP_DELAY    := 0.05    # 호루스 눈 stamp pop
const STAMP_INTERVAL := 0.1     # 3 연속 stamp 간격
const STAMP_COUNT    := 3       # 연속 stamp 횟수
const IMPACT_DELAY   := STAMP_DELAY    # 첫 stamp SFX 시점
const HOLD_TIME      := 0.4
const FADE_TIME      := 0.3
const HEAD_OFFSET    := -120.0
const HORUS_W        := 90.0
const HORUS_H        := 60.0
const PSPEED         := 60.0
const HIEROS_TEXT    := ["𓂀", "𓊽", "𓋹"]

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
var _stamps_emitted: int = 0    # 지금까지 emit 한 stamp 갯수 (각 stamp 마다 SFX)
var _ground_layer: Node2D
var _glow_layer: Node2D

# 마지막 stamp 의 시작 시점 + STAMP_DELAY + HOLD + FADE
func _total_life() -> float:
	return STAMP_INTERVAL * (STAMP_COUNT - 1) + STAMP_DELAY + HOLD_TIME + FADE_TIME

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
	await get_tree().create_timer(_total_life() + 0.1).timeout
	if is_inside_tree():
		queue_free()

func _process(delta: float) -> void:
	_age += delta
	# 각 stamp 의 IMPACT_DELAY 시점에 screen_effect emit (SFX 3번)
	while _stamps_emitted < STAMP_COUNT:
		var t_emit: float = float(_stamps_emitted) * STAMP_INTERVAL + IMPACT_DELAY
		if _age < t_emit:
			break
		_stamps_emitted += 1
		screen_effect.emit()
	_ground_layer.queue_redraw()
	_glow_layer.queue_redraw()

# 전체 envelope (마지막 stamp 의 hold + fade 기준)
func _global_alpha() -> float:
	var last_start: float = float(STAMP_COUNT - 1) * STAMP_INTERVAL
	var end_phase: float = last_start + STAMP_DELAY + HOLD_TIME
	if _age < end_phase:
		return clampf(_age / 0.08, 0.0, 1.0)
	var t: float = (_age - end_phase) / FADE_TIME
	return clampf(1.0 - t, 0.0, 1.0)

# 각 stamp 의 local_age — 시작 전이면 음수 (그리지 않음)
func _stamp_local_age(i: int) -> float:
	return _age - float(i) * STAMP_INTERVAL

# ── ground — 발치 작은 황금 wash ──
func _draw_ground_pass(canvas: CanvasItem) -> void:
	var ga: float = _global_alpha()
	if ga <= 0.0:
		return
	var foot: Vector2 = _foot_pos()
	var grow: float = clampf(_age / 0.2, 0.0, 1.0)
	var alpha: float = grow * ga * 0.35
	var seg := 24
	var pts := PackedVector2Array()
	for i in range(seg + 1):
		var a: float = TAU * float(i) / float(seg)
		pts.append(foot + Vector2(cos(a) * 50.0 * grow, sin(a) * 15.0 * grow))
	canvas.draw_colored_polygon(pts, Color(COL_GOLD_DEEP, alpha))

# ── glow — 0.1s 간격 3 stamp (호루스 눈 + 상형문자 + vulnerable mark) ──
func _draw_glow_pass(canvas: CanvasItem) -> void:
	var ga: float = _global_alpha()
	if ga <= 0.0:
		return
	# 각 stamp 별로 local_age 기반 호루스/상형/vuln 누적 그림
	for i in range(STAMP_COUNT):
		var la: float = _stamp_local_age(i)
		if la < 0.0:
			continue
		_draw_horus_eye(canvas, ga, la)
		_draw_hieroglyphs(canvas, ga, la)
		if la >= STAMP_DELAY + 0.2:
			_draw_vuln_mark(canvas, ga, la)

# 호루스의 눈 — 머리 위 stamp (위에서 내려와 박힘). la = stamp 의 local age
func _draw_horus_eye(canvas: CanvasItem, ga: float, la: float) -> void:
	var pop: float = clampf(la / 0.25, 0.0, 1.0)
	if pop <= 0.0:
		return
	var fade: float = 1.0
	if la > STAMP_DELAY + HOLD_TIME:
		fade = clampf(1.0 - (la - STAMP_DELAY - HOLD_TIME) / FADE_TIME, 0.0, 1.0)
	if fade <= 0.0:
		return
	# stamp drop — 위에서 20px 내려옴
	var drop_y: float = lerpf(-20.0, 0.0, pop)
	var sc: float = lerpf(1.4, 1.0, pop)
	var alpha: float = pop * fade * ga
	var ctr: Vector2 = _target + Vector2(0.0, HEAD_OFFSET + drop_y)
	var w: float = HORUS_W * sc * 0.5
	var h: float = HORUS_H * sc * 0.5
	# 윗 눈썹 (호 — 위에서 좌→우 곡선)
	var brow := PackedVector2Array()
	var seg := 12
	for i in range(seg + 1):
		var t: float = float(i) / float(seg)
		var bx: float = lerpf(-w * 0.9, w * 0.9, t)
		var by: float = -h * 0.5 + sin(PI * t) * -h * 0.3 - 8.0
		brow.append(ctr + Vector2(bx, by))
	canvas.draw_polyline(brow, Color(COL_GOLD, alpha), 2.5, true)
	# 눈 본체 — 가로 길쭉한 아몬드 (위 곡선 + 아래 곡선)
	var eye := PackedVector2Array()
	for i in range(seg + 1):
		var t: float = float(i) / float(seg)
		var ex: float = lerpf(-w * 0.9, w * 0.9, t)
		var ey: float = -sin(PI * t) * h * 0.4
		eye.append(ctr + Vector2(ex, ey))
	for i in range(seg + 1):
		var t: float = float(seg - i) / float(seg)
		var ex: float = lerpf(-w * 0.9, w * 0.9, t)
		var ey: float = sin(PI * t) * h * 0.4
		eye.append(ctr + Vector2(ex, ey))
	canvas.draw_colored_polygon(eye, Color(COL_INK.r, COL_INK.g, COL_INK.b, alpha * 0.85))
	canvas.draw_polyline(eye, Color(COL_GOLD, alpha * 0.95), 1.6, true)
	# 동공 — 파랑 + 검 + 흰 하이라이트
	canvas.draw_circle(ctr, h * 0.27, Color(COL_BLUE.r, COL_BLUE.g, COL_BLUE.b, alpha))
	canvas.draw_circle(ctr, h * 0.12, Color(COL_INK.r, COL_INK.g, COL_INK.b, alpha))
	canvas.draw_circle(ctr + Vector2(-h * 0.06, -h * 0.06), h * 0.04, Color(COL_HOT.r, COL_HOT.g, COL_HOT.b, alpha))
	# 아래 꼬리 — 왼쪽 짧은 선 + 오른쪽 곡선 (호루스 눈 특징)
	canvas.draw_line(ctr + Vector2(-w * 0.4, h * 0.3), ctr + Vector2(-w * 0.4, h * 0.8),
		Color(COL_GOLD, alpha), 2.0, true)
	var curl := PackedVector2Array()
	for i in range(8):
		var t: float = float(i) / 7.0
		curl.append(ctr + Vector2(w * 0.25 + t * w * 0.55, h * 0.3 + t * t * h * 0.55))
	canvas.draw_polyline(curl, Color(COL_GOLD, alpha), 2.0, true)

# 상형문자 row — 머리 약간 아래에서 위로 drift. la = stamp 의 local age
func _draw_hieroglyphs(canvas: CanvasItem, ga: float, la: float) -> void:
	var post: float = la - STAMP_DELAY - 0.05
	if post < 0.0:
		return
	var t: float = clampf(post / 0.9, 0.0, 1.0)
	var alpha: float
	if t < 0.2:
		alpha = t / 0.2
	else:
		alpha = 1.0 - (t - 0.2) / 0.8
	alpha *= ga
	if alpha <= 0.0:
		return
	var drift_y: float = -25.0 * t
	var base: Vector2 = _target + Vector2(0.0, HEAD_OFFSET + 35.0 + drift_y)
	var font := ThemeDB.fallback_font
	var spacing: float = 26.0
	var total_w: float = spacing * (HIEROS_TEXT.size() - 1)
	for i in range(HIEROS_TEXT.size()):
		var flick: float = 0.6 + 0.4 * sin(la * (TAU / 0.25) + float(i) * 1.3)
		var pos: Vector2 = base + Vector2(-total_w * 0.5 + spacing * float(i) - 10.0, 0.0)
		canvas.draw_string(font, pos, HIEROS_TEXT[i],
			HORIZONTAL_ALIGNMENT_CENTER, -1, 22,
			Color(COL_GOLD.r, COL_GOLD.g, COL_GOLD.b, alpha * flick))

# 영웅 가슴 위치 vulnerable 동그라미 mark — 잠시 박힘. la = stamp 의 local age
func _draw_vuln_mark(canvas: CanvasItem, ga: float, la: float) -> void:
	var post: float = la - STAMP_DELAY - 0.2
	if post < 0.0:
		return
	var pop: float = clampf(post / 0.18, 0.0, 1.0)
	var fade: float = 1.0
	if la > STAMP_DELAY + HOLD_TIME:
		fade = clampf(1.0 - (la - STAMP_DELAY - HOLD_TIME) / FADE_TIME, 0.0, 1.0)
	var alpha: float = pop * fade * ga
	if alpha <= 0.0:
		return
	var ctr: Vector2 = _target + Vector2(0.0, -40.0)
	var sc: float = lerpf(1.6, 1.0, pop)
	var r: float = 18.0 * sc
	# 내부 분홍 fill
	canvas.draw_circle(ctr, r * 0.85, Color(COL_VULN.r, COL_VULN.g, COL_VULN.b, alpha * 0.45))
	# 외곽 ring
	canvas.draw_arc(ctr, r, 0.0, TAU, 28, Color(COL_VULN, alpha * 0.95), 1.6, true)

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
