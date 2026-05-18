# scenes/vfx/sig_kekkai.gd
# 일본 신화 시그너처 — 결계 (KEKKAI).
# ui_sample/vfx/Kekkai VFX.html 재현. 매 5턴마다 자기 BLOCK +20.
# play(_caster_pos, target_pos) — caster 무시. target = 적 위치 (시전자 본인).
# ground: 발치 푸른 wash + 6각 hex 베이스.
# glow: 4 ofuda (NWSE) fly in + 6각 hex barrier 형성 + 중심 結 kanji + flash.
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


const COL_HOT      := Color(1.0, 1.0, 1.0)
const COL_PAPER    := Color(0.964, 0.945, 0.901)   # #f6f1e6 한지
const COL_SHRINE   := Color(0.752, 0.156, 0.184)   # #c0282f 신사 빨강
const COL_SHRINE_D := Color(0.419, 0.078, 0.094)   # #6b1418
const COL_BARRIER  := Color(0.682, 0.749, 1.0)     # #aebfff 결계 푸른
const COL_BARRIER_D:= Color(0.101, 0.156, 0.250)   # #1a2840
const COL_INK      := Color(0.039, 0.031, 0.019)

const OFUDA_DELAY  := 0.0      # 4 ofuda fly in 시작
const BARRIER_DELAY:= 0.55     # hex barrier 형성
const IMPACT_DELAY := BARRIER_DELAY    # SFX + screen flash
const KANJI_DELAY  := 0.7
const HOLD_TIME    := 1.0
const FADE_TIME    := 0.55
const HEX_R        := 120.0
const OFUDA_W      := 22.0
const OFUDA_H      := 42.0
const OFUDA_DIST   := 150.0
const HEAD_OFFSET  := -110.0
const PSPEED       := 60.0
# 4 ofuda: N, E, S, W (각 방향 + 회전 각도)
const OFUDA_DIRS := [
	{"ang": -PI / 2.0, "rot": 0.0,        "kanji": "護"},
	{"ang":  0.0,       "rot": PI / 2.0,   "kanji": "界"},
	{"ang":  PI / 2.0,  "rot": PI,         "kanji": "封"},
	{"ang":  PI,        "rot": -PI / 2.0,  "kanji": "結"},
]

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

func _barrier_ctr() -> Vector2:
	return _target + Vector2(0.0, -10.0)

var _age := -1.0
var _impact_emitted := false
var _ground_layer: Node2D
var _paper_layer: Node2D
var _glow_layer: Node2D

func _ready() -> void:
	set_process(false)
	_ground_layer = _DrawLayer.new()
	_ground_layer.setup(self, true)
	add_child(_ground_layer)
	_ground_layer.set_meta("pass", "ground")
	# 부적 본체는 normal blend — 가산이면 흰 한지가 한자를 덮어버림
	_paper_layer = _DrawLayer.new()
	_paper_layer.setup(self, false)
	add_child(_paper_layer)
	_paper_layer.set_meta("pass", "paper")
	_glow_layer = _DrawLayer.new()
	_glow_layer.setup(self, true)
	add_child(_glow_layer)
	_glow_layer.set_meta("pass", "glow")

func play(_caster_pos: Vector2, target_pos: Vector2) -> void:
	_target = target_pos
	_age = 0.0
	set_process(true)
	await get_tree().create_timer(BARRIER_DELAY + HOLD_TIME + FADE_TIME + 0.1).timeout
	if is_inside_tree():
		queue_free()

func _process(delta: float) -> void:
	_age += delta
	if not _impact_emitted and _age >= IMPACT_DELAY:
		_impact_emitted = true
		screen_effect.emit()
	_ground_layer.queue_redraw()
	_paper_layer.queue_redraw()
	_glow_layer.queue_redraw()

func _global_alpha() -> float:
	var end_phase: float = BARRIER_DELAY + HOLD_TIME
	if _age < end_phase:
		return clampf(_age / 0.15, 0.0, 1.0)
	var t: float = (_age - end_phase) / FADE_TIME
	return clampf(1.0 - t, 0.0, 1.0)

# ── ground — 발치 푸른 wash + 6각 hex 베이스 ──
func _draw_ground_pass(canvas: CanvasItem) -> void:
	var ga: float = _global_alpha()
	if ga <= 0.0:
		return
	var foot: Vector2 = _foot_pos()
	var grow: float = clampf(_age / 0.5, 0.0, 1.0)
	var alpha: float = grow * ga * 0.45
	var seg := 28
	var pts := PackedVector2Array()
	for i in range(seg + 1):
		var a: float = TAU * float(i) / float(seg)
		pts.append(foot + Vector2(cos(a) * 100.0 * grow, sin(a) * 30.0 * grow))
	canvas.draw_colored_polygon(pts, Color(COL_BARRIER, alpha * 0.5))
	canvas.draw_colored_polygon(pts, Color(COL_BARRIER_D, alpha * 0.35))

# ── paper (normal blend) — ofuda paper + 빨간 띠 + 한자 ──
# 가산 블렌드에 두면 흰 한지가 한자를 가려버려 별도 레이어로 분리.
func _draw_paper_pass(canvas: CanvasItem) -> void:
	var ga: float = _global_alpha()
	if ga <= 0.0:
		return
	_draw_ofudas(canvas, ga)

# ── glow — hex barrier + center kanji + flash ──
func _draw_glow_pass(canvas: CanvasItem) -> void:
	var ga: float = _global_alpha()
	if ga <= 0.0:
		return
	if _age >= BARRIER_DELAY:
		_draw_barrier(canvas, ga)
	if _age >= KANJI_DELAY:
		_draw_center_kanji(canvas, ga)
	if _impact_emitted:
		_draw_flash(canvas, ga)

# 4 ofuda — 각 방향에서 staggered fly in
func _draw_ofudas(canvas: CanvasItem, ga: float) -> void:
	var fade: float = 1.0
	if _age > BARRIER_DELAY + HOLD_TIME:
		fade = clampf(1.0 - (_age - BARRIER_DELAY - HOLD_TIME) / FADE_TIME, 0.0, 1.0)
	if fade <= 0.0:
		return
	var ctr: Vector2 = _barrier_ctr()
	var font := ThemeDB.fallback_font
	for i in range(OFUDA_DIRS.size()):
		var d: Dictionary = OFUDA_DIRS[i]
		var ang: float = d["ang"]
		var rot: float = d["rot"]
		var delay: float = float(i) * 0.08
		var post: float = _age - OFUDA_DELAY - delay
		if post < 0.0:
			continue
		var t: float = clampf(post / 0.5, 0.0, 1.0)
		var alpha: float = clampf(post / 0.15, 0.0, 1.0) * fade * ga
		# 방향으로 OFUDA_DIST 만큼 외곽에서 안쪽으로 진입
		var dist: float = lerpf(OFUDA_DIST + 60.0, OFUDA_DIST, t)
		var pos: Vector2 = ctr + Vector2(cos(ang), sin(ang)) * dist
		# ofuda 본체 — 회전된 흰 종이
		_draw_ofuda_paper(canvas, pos, rot, alpha)
		# 부적 위 한자 (작게)
		var kanji_pos: Vector2 = pos
		canvas.draw_string(font, kanji_pos - Vector2(6.0, -3.0), d["kanji"],
			HORIZONTAL_ALIGNMENT_CENTER, -1, 14,
			Color(COL_SHRINE.r, COL_SHRINE.g, COL_SHRINE.b, alpha))

func _draw_ofuda_paper(canvas: CanvasItem, pos: Vector2, rot: float, alpha: float) -> void:
	var hw: float = OFUDA_W * 0.5
	var hh: float = OFUDA_H * 0.5
	# 사각형 4점 (회전 후)
	var corners := [
		Vector2(-hw, -hh), Vector2(hw, -hh),
		Vector2(hw, hh), Vector2(-hw, hh),
	]
	var pts := PackedVector2Array()
	for c in corners:
		var rx: float = c.x * cos(rot) - c.y * sin(rot)
		var ry: float = c.x * sin(rot) + c.y * cos(rot)
		pts.append(pos + Vector2(rx, ry))
	canvas.draw_colored_polygon(pts, Color(COL_PAPER.r, COL_PAPER.g, COL_PAPER.b, alpha * 0.95))
	# 위·아래 빨간 띠
	for sign in [-1.0, 1.0]:
		var band := PackedVector2Array()
		for c in [Vector2(-hw, sign * hh - 3.0), Vector2(hw, sign * hh - 3.0),
				Vector2(hw, sign * hh), Vector2(-hw, sign * hh)]:
			var rx: float = c.x * cos(rot) - c.y * sin(rot)
			var ry: float = c.x * sin(rot) + c.y * cos(rot)
			band.append(pos + Vector2(rx, ry))
		canvas.draw_colored_polygon(band, Color(COL_SHRINE, alpha))

# 6각 hex barrier (3겹) + bind lines
func _draw_barrier(canvas: CanvasItem, ga: float) -> void:
	var post: float = _age - BARRIER_DELAY
	var form: float = clampf(post / 0.35, 0.0, 1.0)
	var fade: float = 1.0
	if _age > BARRIER_DELAY + HOLD_TIME:
		fade = clampf(1.0 - (_age - BARRIER_DELAY - HOLD_TIME) / FADE_TIME, 0.0, 1.0)
	var alpha: float = form * fade * ga
	if alpha <= 0.0:
		return
	var ctr: Vector2 = _barrier_ctr()
	# 외 hex (큰)
	_draw_hex(canvas, ctr, HEX_R * form, 0.0, Color(COL_BARRIER, alpha * 0.95), 2.4)
	# 중 hex (점선 흉내 — 작은 선분 6개)
	_draw_hex_dashed(canvas, ctr, HEX_R * 0.78 * form, 0.0, Color(COL_BARRIER, alpha * 0.7), 1.4)
	# 내 hex (작은, paper 색)
	_draw_hex(canvas, ctr, HEX_R * 0.55 * form, 0.0, Color(COL_PAPER.r, COL_PAPER.g, COL_PAPER.b, alpha * 0.6), 1.2)
	# bind lines — 각 외 hex 꼭짓점 → 내 hex 꼭짓점
	for i in range(6):
		var ang: float = -PI / 2.0 + TAU * float(i) / 6.0
		var po: Vector2 = ctr + Vector2(cos(ang), sin(ang)) * HEX_R * form
		var pi_pt: Vector2 = ctr + Vector2(cos(ang), sin(ang)) * HEX_R * 0.55 * form
		canvas.draw_line(po, pi_pt, Color(COL_BARRIER, alpha * 0.55), 1.0, true)

func _draw_hex(canvas: CanvasItem, ctr: Vector2, r: float, rot: float, col: Color, w: float) -> void:
	var pts := PackedVector2Array()
	for i in range(7):
		var a: float = rot - PI / 2.0 + TAU * float(i) / 6.0
		pts.append(ctr + Vector2(cos(a), sin(a)) * r)
	canvas.draw_polyline(pts, col, w, true)

func _draw_hex_dashed(canvas: CanvasItem, ctr: Vector2, r: float, rot: float, col: Color, w: float) -> void:
	# 6 변, 각 변에 짧은 dash 4개씩
	for i in range(6):
		var a0: float = rot - PI / 2.0 + TAU * float(i) / 6.0
		var a1: float = rot - PI / 2.0 + TAU * float(i + 1) / 6.0
		var p0: Vector2 = ctr + Vector2(cos(a0), sin(a0)) * r
		var p1: Vector2 = ctr + Vector2(cos(a1), sin(a1)) * r
		for k in range(4):
			var t0: float = float(k) / 4.0 + 0.05
			var t1: float = float(k) / 4.0 + 0.20
			canvas.draw_line(p0.lerp(p1, t0), p0.lerp(p1, t1), col, w, true)

# 중심 結 kanji — 푸른 원 안에
func _draw_center_kanji(canvas: CanvasItem, ga: float) -> void:
	var post: float = _age - KANJI_DELAY
	var pop: float = clampf(post / 0.3, 0.0, 1.0)
	var fade: float = 1.0
	if _age > BARRIER_DELAY + HOLD_TIME:
		fade = clampf(1.0 - (_age - BARRIER_DELAY - HOLD_TIME) / FADE_TIME, 0.0, 1.0)
	var alpha: float = pop * fade * ga
	if alpha <= 0.0:
		return
	var ctr: Vector2 = _barrier_ctr()
	var sc: float = lerpf(0.5, 1.0, pop)
	var r: float = 32.0 * sc
	# 푸른 원 베이스
	canvas.draw_circle(ctr, r, Color(COL_BARRIER_D.r, COL_BARRIER_D.g, COL_BARRIER_D.b, alpha * 0.85))
	canvas.draw_arc(ctr, r, 0.0, TAU, 28, Color(COL_BARRIER, alpha * 0.95), 1.4, true)
	# 結 kanji (한자)
	var font := ThemeDB.fallback_font
	canvas.draw_string(font, ctr - Vector2(18.0, -12.0), "結",
		HORIZONTAL_ALIGNMENT_CENTER, -1, 36,
		Color(COL_PAPER.r, COL_PAPER.g, COL_PAPER.b, alpha))

# barrier 형성 순간 — 푸른 wash flash (짧음)
func _draw_flash(canvas: CanvasItem, ga: float) -> void:
	var post: float = _age - IMPACT_DELAY
	var t: float = post / 0.4
	if t < 0.0 or t > 1.0:
		return
	var alpha: float
	if t < 0.15:
		alpha = t / 0.15
	else:
		alpha = 1.0 - (t - 0.15) / 0.85
	alpha *= ga * 0.7
	if alpha <= 0.0:
		return
	var ctr: Vector2 = _barrier_ctr()
	canvas.draw_circle(ctr, HEX_R * 1.4, Color(COL_BARRIER.r, COL_BARRIER.g, COL_BARRIER.b, alpha * 0.4))
	canvas.draw_circle(ctr, HEX_R * 0.8, Color(COL_HOT.r, COL_HOT.g, COL_HOT.b, alpha * 0.5))

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
			"ground": _fx._draw_ground_pass(self)
			"paper":  _fx._draw_paper_pass(self)
			_:        _fx._draw_glow_pass(self)
