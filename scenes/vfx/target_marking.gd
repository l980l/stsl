# scenes/vfx/target_marking.gd
# 타겟 마킹 VFX — ui_sample/vfx/Target Marking VFX.html 재현 (MARK_TARGET 적 intent).
# 시전자(적) → 타겟(영웅) 으로 tracer + reticle travel → corner brackets snap → mark glyph hold.
# play(caster_pos, target_pos) — 둘 다 사용.
# ground (영웅 뒤): red wash + 발치 ember
# glow  (영웅 앞): tracer + reticle + brackets + mark glyph + lock sparks + rune
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


const COL_HOT       := Color(1.0, 1.0, 1.0)
const COL_MARK      := Color(0.850, 0.290, 0.313)        # #d94a50 blood
const COL_MARK_HOT  := Color(1.0, 0.313, 0.376)          # #ff5060 brighter
const COL_MARK_DEEP := Color(0.419, 0.078, 0.094)        # #6b1418
const COL_WARN      := Color(0.909, 0.784, 0.470)        # #e8c878 brass
const COL_SCAN      := Color(0.360, 0.862, 1.0)          # #5cdcff cyan (charge)

const CHARGE_TIME  := 0.2     # caster aim glow
const TRAVEL_TIME  := 0.3     # tracer + reticle travel
const PEAK_DELAY   := CHARGE_TIME + TRAVEL_TIME  # = 0.5s — IMPACT_DELAY
const IMPACT_DELAY := PEAK_DELAY
const HOLD_TIME    := 0.6     # brackets pulse + mark glyph hold
const FADE_TIME    := 0.35
const RETICLE_R    := 56.0    # reticle outer radius
const BRACKET_W    := 70.0    # corner bracket bbox half-width
const BRACKET_H    := 65.0
const MARK_Y_OFFSET := -100.0  # 머리 위
const PSPEED       := 60.0

## 화면 플래시 + SFX 트리거 (peak = lock 시점)
signal screen_effect

var _caster := Vector2.ZERO
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
var _particles: Array = []
var _ground_layer: Node2D   # red wash + 발치 ember
var _glow_layer: Node2D     # tracer / reticle / brackets / mark / sparks / rune

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

func play(caster_pos: Vector2, target_pos: Vector2) -> void:
	_caster = caster_pos
	_target = target_pos
	_age = 0.0
	set_process(true)
	await get_tree().create_timer(PEAK_DELAY + HOLD_TIME + FADE_TIME + 0.1).timeout
	if is_inside_tree():
		queue_free()

# lock 시점 폭발 — 외곽 → target 으로 수렴하는 빨간/황동 motes + rune 글리프
func _spawn_lock_sparks() -> void:
	for _i in range(_pcount(20)):
		var a := randf() * TAU
		var sp := 1.5 + randf() * 3.0
		var tint: String = "red" if randf() < 0.5 else "amber"
		_particles.append({
			"pos": _target + Vector2(cos(a) * 60.0, sin(a) * 70.0),
			"vel": Vector2(-cos(a) * sp, -sin(a) * sp),  # 외곽 → target 수렴
			"life": 0.0,
			"max_life": 0.5 + randf() * 0.4,
			"size": 1.2 + randf() * 1.2,
			"kind": "mote",
			"tint": tint,
		})
	for _i in range(_pcount(4)):
		var a2 := randf() * TAU
		_particles.append({
			"pos": _target + Vector2(randf_range(-20.0, 20.0), randf_range(-30.0, 30.0)),
			"vel": Vector2(cos(a2) * 0.6, sin(a2) * 0.6),
			"life": 0.0,
			"max_life": 0.8 + randf() * 0.4,
			"size": 8.0 + randf() * 5.0,
			"kind": "rune",
			"rot": randf() * TAU,
			"spin": randf_range(-0.04, 0.04),
			"glyph_idx": randi() % 5,
		})

# hold 동안 빨간 ember 모트 — target 주변 위로 솟구침
func _spawn_hold_ember() -> void:
	if randf() < 0.4 * _scale():
		_particles.append({
			"pos": _target + Vector2(randf_range(-100.0, 100.0), randf_range(30.0, 80.0)),
			"vel": Vector2(randf_range(-0.1, 0.1), -0.4 - randf() * 0.4),
			"life": 0.0,
			"max_life": 1.0 + randf() * 0.5,
			"size": 1.0 + randf() * 1.1,
			"kind": "mote",
			"tint": "red",
		})

func _process(delta: float) -> void:
	_age += delta
	# lock peak — 1회 burst + screen_effect
	if not _impact_emitted and _age >= PEAK_DELAY:
		_impact_emitted = true
		_spawn_lock_sparks()
		screen_effect.emit()
	if _impact_emitted and _age < PEAK_DELAY + HOLD_TIME:
		_spawn_hold_ember()

	# 파티클 업데이트
	var alive: Array = []
	for p in _particles:
		p["life"] += delta
		if p["life"] >= p["max_life"]:
			continue
		p["pos"] += p["vel"] * delta * PSPEED
		p["vel"] *= pow(0.993, delta * 60.0)
		if p.has("spin"):
			p["rot"] = p.get("rot", 0.0) + p["spin"] * delta * PSPEED
		alive.append(p)
	_particles = alive

	_ground_layer.queue_redraw()
	_glow_layer.queue_redraw()

func _global_alpha() -> float:
	if _age < PEAK_DELAY + HOLD_TIME:
		return clampf(_age / 0.15, 0.0, 1.0)
	var t: float = (_age - (PEAK_DELAY + HOLD_TIME)) / FADE_TIME
	return clampf(1.0 - t, 0.0, 1.0)

# ── ground (가산, 영웅 뒤) — red wash overlay (radial) ──
func _draw_ground_pass(canvas: CanvasItem) -> void:
	var ga: float = _global_alpha()
	if ga <= 0.0:
		return
	# red wash — lock 부터 hold 끝까지
	if _impact_emitted:
		var wash_t: float = (_age - PEAK_DELAY) / 0.4
		var wash_alpha: float = clampf(wash_t, 0.0, 1.0) * 0.35 * ga
		if _age > PEAK_DELAY + HOLD_TIME:
			wash_alpha *= clampf(1.0 - (_age - PEAK_DELAY - HOLD_TIME) / FADE_TIME, 0.0, 1.0)
		if wash_alpha > 0.0:
			var seg := 32
			var pts := PackedVector2Array()
			for i in range(seg + 1):
				var a: float = TAU * float(i) / float(seg)
				pts.append(_target + Vector2(cos(a) * 180.0, sin(a) * 140.0))
			canvas.draw_colored_polygon(pts, Color(COL_MARK_DEEP, wash_alpha))

# ── glow (가산, 영웅 앞) — tracer / reticle / brackets / mark / sparks / rune ──
func _draw_glow_pass(canvas: CanvasItem) -> void:
	var ga: float = _global_alpha()
	if ga <= 0.0:
		return
	# tracer — charge 후 ~ travel 동안
	_draw_tracer(canvas, ga)
	# reticle — travel + 잠시 hold
	_draw_reticle(canvas, ga)
	# brackets — lock 부터
	if _impact_emitted:
		_draw_brackets(canvas, ga)
	# mark glyph (머리 위) — lock 부터 hold + 페이드
	if _impact_emitted:
		_draw_mark_glyph(canvas, ga)
	# motes (lock sparks + hold ember)
	for p in _particles:
		if p["kind"] != "mote":
			continue
		var k: float = p["life"] / p["max_life"]
		var a: float = (1.0 - k) * ga
		var col := _mote_color(p["tint"], a)
		var pr: float = p["size"]
		canvas.draw_circle(p["pos"], pr * 1.8, Color(col.r, col.g, col.b, col.a * 0.45))
		canvas.draw_circle(p["pos"], pr, col)
		canvas.draw_rect(Rect2(p["pos"].x - pr * 2.2, p["pos"].y - 0.3, pr * 4.4, 0.6), col)
		canvas.draw_rect(Rect2(p["pos"].x - 0.3, p["pos"].y - pr * 2.2, 0.6, pr * 4.4), col)
	# rune (lock 시점 회전 글리프 — 단순 + 모양)
	for p in _particles:
		if p["kind"] != "rune":
			continue
		var k: float = p["life"] / p["max_life"]
		var a: float = (1.0 - k) * ga
		var col := Color(COL_MARK_HOT.r, COL_MARK_HOT.g, COL_MARK_HOT.b, a * 0.9)
		_draw_rune_glyph(canvas, p["pos"], p["size"], p.get("rot", 0.0), p.get("glyph_idx", 0), col)
	# lock shockwave
	if _impact_emitted:
		_draw_lock_shock(canvas, ga)

func _mote_color(tint: String, a: float) -> Color:
	match tint:
		"cyan":  return Color(0.627, 0.901, 1.0, a)
		"amber": return Color(0.909, 0.784, 0.470, a)
		_:        return Color(1.0, 0.470, 0.501, a)  # red

# 시전자 → 타겟 tracer (charge 후 등장, peak 후 빠르게 페이드)
func _draw_tracer(canvas: CanvasItem, ga: float) -> void:
	var t: float = (_age - CHARGE_TIME) / TRAVEL_TIME
	if t <= 0.0:
		return
	var grow: float = clampf(t, 0.0, 1.0)
	var fade: float = 1.0
	if _impact_emitted:
		var post: float = (_age - PEAK_DELAY) / 0.25
		fade = clampf(1.0 - post, 0.0, 1.0)
	var alpha: float = ga * fade
	if alpha <= 0.0:
		return
	# tracer 끝점 = caster + (target - caster) * grow
	var endp := _caster.lerp(_target, grow)
	# warning gradient — caster→tracer 끝까지, alpha 점진 증가
	canvas.draw_line(_caster, endp, Color(COL_WARN, 0.4 * alpha), 1.2, true)
	canvas.draw_line(_caster, endp, Color(COL_MARK_HOT, 0.85 * alpha), 0.5, true)

# reticle — travel 중 caster→target 으로 이동, lock 후 잠시 hold, fade
func _draw_reticle(canvas: CanvasItem, ga: float) -> void:
	var t: float = (_age - CHARGE_TIME) / TRAVEL_TIME
	if t <= 0.0:
		return
	var travel: float = clampf(t, 0.0, 1.0)
	var pos := _caster.lerp(_target, travel)
	# scale: travel 동안 0.4→1.0
	var sc: float = lerpf(0.4, 1.0, travel)
	# 페이드: lock 후 0.6s 뒤부터
	var alpha: float = ga
	if _impact_emitted:
		var post: float = (_age - PEAK_DELAY) / 0.6
		alpha *= clampf(1.0 - post, 0.0, 1.0)
	if alpha <= 0.0:
		return
	var r: float = RETICLE_R * sc
	# outer ring
	canvas.draw_arc(pos, r, 0.0, TAU, 32, Color(COL_MARK_HOT, 0.85 * alpha), 1.5, true)
	# ticked ring (점선 — 12 호)
	for i in range(12):
		var a0: float = TAU * float(i) / 12.0
		var a1: float = a0 + TAU / 24.0
		canvas.draw_arc(pos, r * 0.8, a0, a1, 4, Color(COL_WARN, 0.7 * alpha), 1.0, true)
	# inner small ring
	canvas.draw_arc(pos, r * 0.26, 0.0, TAU, 16, Color(COL_HOT, 0.9 * alpha), 1.0, true)
	# crosshair cross (4 stub)
	var _stub: float = r * 0.36
	canvas.draw_line(pos + Vector2(0, -r * 1.1), pos + Vector2(0, -r * 0.55), Color(COL_HOT, 0.95 * alpha), 1.4, true)
	canvas.draw_line(pos + Vector2(0, r * 1.1), pos + Vector2(0, r * 0.55), Color(COL_HOT, 0.95 * alpha), 1.4, true)
	canvas.draw_line(pos + Vector2(-r * 1.1, 0), pos + Vector2(-r * 0.55, 0), Color(COL_HOT, 0.95 * alpha), 1.4, true)
	canvas.draw_line(pos + Vector2(r * 1.1, 0), pos + Vector2(r * 0.55, 0), Color(COL_HOT, 0.95 * alpha), 1.4, true)
	# center dot
	canvas.draw_circle(pos, 2.0, Color(COL_HOT, alpha))
	# 대각 tick (4 모서리)
	for i in range(4):
		var dx: float = -1.0 if i % 2 == 0 else 1.0
		var dy: float = -1.0 if i < 2 else 1.0
		var p0: Vector2 = pos + Vector2(dx * r * 0.55, dy * r * 0.55)
		var p1: Vector2 = pos + Vector2(dx * r * 0.72, dy * r * 0.72)
		canvas.draw_line(p0, p1, Color(COL_MARK_HOT, 0.7 * alpha), 1.0, true)

# 4 corner brackets (lock 시점 snap, hold pulse, fade)
@warning_ignore("shadowed_variable_base_class")
func _draw_brackets(canvas: CanvasItem, ga: float) -> void:
	var post: float = _age - PEAK_DELAY
	var snap: float = clampf(post / 0.2, 0.0, 1.0)
	# 페이드: hold 끝나면 0.45s
	var fade: float = 1.0
	if _age > PEAK_DELAY + HOLD_TIME:
		fade = clampf(1.0 - (_age - PEAK_DELAY - HOLD_TIME) / 0.45, 0.0, 1.0)
	if fade <= 0.0:
		return
	# pulse — hold 중 alpha 가 미세하게 진동
	var pulse: float = 0.85 + sin(post * (TAU / 1.4)) * 0.1
	var alpha: float = snap * fade * ga * pulse
	# bracket 크기 — snap 중 1.8→1.0 으로 줄어듦
	var sc: float = lerpf(1.4, 1.0, snap)
	var bw: float = BRACKET_W * sc
	var bh: float = BRACKET_H * sc
	var thick: float = 2.0
	# 4 모서리 (top-left, top-right, bottom-right, bottom-left)
	var tl: Vector2 = _target + Vector2(-bw, -bh)
	var tr: Vector2 = _target + Vector2(bw, -bh)
	var br: Vector2 = _target + Vector2(bw, bh)
	var bl: Vector2 = _target + Vector2(-bw, bh)
	var arm: float = bw * 0.4
	# TL
	canvas.draw_line(tl, tl + Vector2(arm, 0), Color(COL_MARK_HOT, alpha), thick, true)
	canvas.draw_line(tl, tl + Vector2(0, arm), Color(COL_MARK_HOT, alpha), thick, true)
	# TR
	canvas.draw_line(tr, tr + Vector2(-arm, 0), Color(COL_MARK_HOT, alpha), thick, true)
	canvas.draw_line(tr, tr + Vector2(0, arm), Color(COL_MARK_HOT, alpha), thick, true)
	# BR
	canvas.draw_line(br, br + Vector2(-arm, 0), Color(COL_MARK_HOT, alpha), thick, true)
	canvas.draw_line(br, br + Vector2(0, -arm), Color(COL_MARK_HOT, alpha), thick, true)
	# BL
	canvas.draw_line(bl, bl + Vector2(arm, 0), Color(COL_MARK_HOT, alpha), thick, true)
	canvas.draw_line(bl, bl + Vector2(0, -arm), Color(COL_MARK_HOT, alpha), thick, true)
	# side ticks (작은 양옆 tick)
	canvas.draw_line(_target + Vector2(-bw - 8, 0), _target + Vector2(-bw, 0), Color(COL_MARK_HOT, alpha * 0.85), 1.5, true)
	canvas.draw_line(_target + Vector2(bw, 0), _target + Vector2(bw + 8, 0), Color(COL_MARK_HOT, alpha * 0.85), 1.5, true)

# mark glyph (머리 위 chevron + diamond)
func _draw_mark_glyph(canvas: CanvasItem, ga: float) -> void:
	var post: float = _age - PEAK_DELAY
	# popIn (0~0.35) + float (지속)
	var pop: float = clampf(post / 0.35, 0.0, 1.0)
	var fade: float = 1.0
	if _age > PEAK_DELAY + HOLD_TIME:
		fade = clampf(1.0 - (_age - PEAK_DELAY - HOLD_TIME) / 0.6, 0.0, 1.0)
	if fade <= 0.0:
		return
	var float_y: float = sin(post * (TAU / 2.4)) * 3.0
	var sc: float = lerpf(0.5, 1.0, pop)
	var alpha: float = pop * fade * ga
	var ctr: Vector2 = _target + Vector2(0.0, MARK_Y_OFFSET + float_y)
	# 위쪽 chevron (큰, 빨강)
	var cw: float = 22.0 * sc
	var ch: float = 14.0 * sc
	var p1: Vector2 = ctr + Vector2(-cw, -ch)
	var p2: Vector2 = ctr + Vector2(0, ch * 0.6)
	var p3: Vector2 = ctr + Vector2(cw, -ch)
	canvas.draw_line(p1, p2, Color(COL_MARK_HOT, alpha), 2.5, true)
	canvas.draw_line(p2, p3, Color(COL_MARK_HOT, alpha), 2.5, true)
	# 아래쪽 chevron (작은, 흰)
	var cw2: float = 18.0 * sc
	var ch2: float = 10.0 * sc
	var dy: float = 10.0 * sc
	canvas.draw_line(ctr + Vector2(-cw2, -ch2 + dy), ctr + Vector2(0, ch2 * 0.6 + dy), Color(COL_HOT, 0.9 * alpha), 2.0, true)
	canvas.draw_line(ctr + Vector2(0, ch2 * 0.6 + dy), ctr + Vector2(cw2, -ch2 + dy), Color(COL_HOT, 0.9 * alpha), 2.0, true)
	# 다이아몬드 (마크 코어)
	var dsz: float = 6.0 * sc
	var dctr: Vector2 = ctr + Vector2(0, 22.0 * sc)
	canvas.draw_colored_polygon(PackedVector2Array([
		dctr + Vector2(0, -dsz), dctr + Vector2(dsz, 0),
		dctr + Vector2(0, dsz), dctr + Vector2(-dsz, 0),
	]), Color(COL_MARK_HOT, alpha))

# lock 시점 짧은 shockwave (target 중심)
func _draw_lock_shock(canvas: CanvasItem, ga: float) -> void:
	var t: float = (_age - PEAK_DELAY) / 0.45
	if t < 0.0 or t > 1.0:
		return
	var sc: float = lerpf(0.3, 10.0, t)
	var alpha: float
	if t < 0.2:
		alpha = t / 0.2
	else:
		alpha = 1.0 - (t - 0.2) / 0.8
	alpha *= ga
	if alpha <= 0.0:
		return
	var rad: float = 20.0 * sc
	var thick: float = lerpf(4.0, 1.0, t)
	canvas.draw_arc(_target, rad, 0.0, TAU, 48, Color(COL_MARK_HOT, alpha), thick, true)

# rune 글리프 — + × ◇ □ ◯ 단순 도형 (text 대신)
@warning_ignore("shadowed_variable_base_class")
func _draw_rune_glyph(canvas: CanvasItem, pos: Vector2, size: float, rot: float, idx: int, col: Color) -> void:
	var r: float = size
	var c: Vector2 = pos
	var cs := cos(rot)
	var sn := sin(rot)
	# 회전 행렬 헬퍼
	var rotate := func(p: Vector2) -> Vector2:
		return Vector2(p.x * cs - p.y * sn, p.x * sn + p.y * cs)
	match idx:
		0:  # +
			canvas.draw_line(c + rotate.call(Vector2(-r, 0)), c + rotate.call(Vector2(r, 0)), col, 1.5, true)
			canvas.draw_line(c + rotate.call(Vector2(0, -r)), c + rotate.call(Vector2(0, r)), col, 1.5, true)
		1:  # ×
			canvas.draw_line(c + rotate.call(Vector2(-r, -r)), c + rotate.call(Vector2(r, r)), col, 1.5, true)
			canvas.draw_line(c + rotate.call(Vector2(-r, r)), c + rotate.call(Vector2(r, -r)), col, 1.5, true)
		2:  # ◇
			var pts := PackedVector2Array([
				c + rotate.call(Vector2(0, -r)),
				c + rotate.call(Vector2(r, 0)),
				c + rotate.call(Vector2(0, r)),
				c + rotate.call(Vector2(-r, 0)),
				c + rotate.call(Vector2(0, -r)),
			])
			canvas.draw_polyline(pts, col, 1.5, true)
		3:  # □
			var pts2 := PackedVector2Array([
				c + rotate.call(Vector2(-r, -r)),
				c + rotate.call(Vector2(r, -r)),
				c + rotate.call(Vector2(r, r)),
				c + rotate.call(Vector2(-r, r)),
				c + rotate.call(Vector2(-r, -r)),
			])
			canvas.draw_polyline(pts2, col, 1.5, true)
		_:  # ◯
			canvas.draw_arc(c, r, 0.0, TAU, 16, col, 1.5, true)

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
