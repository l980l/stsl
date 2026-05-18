# scenes/vfx/taunt.gd
# 도발 (TAUNT) VFX — 적이 영웅에게 도발 부여 시 시전 적 위치에 재현.
# ui_sample/vfx/Taunt VFX.html 변환.
# play(caster_pos, target_pos) — caster_pos = 시전 적, target_pos 미사용 (자기 중심).
# 단계:
#   windup 0.32s — 시전자 가슴 빌드업 (시각적으론 fade-in 만 — 적 sprite 자체에 위빙 X)
#   thump 0.32s — chest flash + 3 concentric shockwave + flash + ground crack + glyph + 한글 "도발" + particles
#   hold 0.9s — 글리프 회전 + word shake
#   fade 0.7s
extends Node2D

signal screen_effect

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

# 색상 (HTML --taunt 계열)
const COL_HOT     := Color(1.0, 1.0, 1.0)
const COL_TAUNT   := Color(0.851, 0.290, 0.314)   # #d94a50 붉음
const COL_BURN    := Color(1.0, 0.423, 0.290)     # #ff6c4a 오렌지빨강
const COL_DEEP    := Color(0.419, 0.078, 0.094)   # #6b1418
const COL_BRASS   := Color(0.910, 0.784, 0.470)   # #e8c878 황금
const COL_INK     := Color(0.027, 0.024, 0.039)

# 타이밍 (HTML 의 cast() 시퀀스)
const WINDUP_TIME  := 0.32
const IMPACT_DELAY := WINDUP_TIME               # 0.32s — chest thump
const ARROW_DELAY  := WINDUP_TIME + 0.14        # 0.46s — aggro arrows snap
const STAMP_DELAY  := WINDUP_TIME + 0.32        # 0.64s — TAUNTED stamp
const HOLD_TIME    := 0.9
const FADE_TIME    := 0.7

# 기하
const SHOCK_BASE_R := 30.0
const SHOCK_MAX_R  := 540.0
const CHEST_R      := 16.0
const GLYPH_R      := 36.0
const WORD_OFFSET_Y := -120.0     # caster 위
const GLYPH_OFFSET_Y := -86.0
const CRACK_OFFSET_Y := 56.0      # 발치 아래

var _caster := Vector2.ZERO
var _ground_pos := Vector2.ZERO
var _has_ground: bool = false

func set_ground_anchor(pos: Vector2) -> void:
	_ground_pos = pos
	_has_ground = true

func _foot_pos() -> Vector2:
	return _ground_pos if _has_ground else _caster + Vector2(0.0, CRACK_OFFSET_Y)

var _age := -1.0
var _impact_emitted := false
var _particles: Array = []

var _bg_layer: Node2D    # ground crack + heat tint (lower)
var _shock_layer: Node2D # 3 shockwave (additive)
var _glow_layer: Node2D  # chest flash + glyph + word (additive)
var _smoke_layer: Node2D # smoke/dust particles (normal blend)

func _ready() -> void:
	set_process(false)
	_bg_layer = _DrawLayer.new()
	_bg_layer.setup(self, false)  # ground crack — normal blend
	add_child(_bg_layer)
	_bg_layer.set_meta("pass", "bg")
	_shock_layer = _DrawLayer.new()
	_shock_layer.setup(self, true)  # additive shockwaves
	add_child(_shock_layer)
	_shock_layer.set_meta("pass", "shock")
	_smoke_layer = _DrawLayer.new()
	_smoke_layer.setup(self, false)  # smoke normal
	add_child(_smoke_layer)
	_smoke_layer.set_meta("pass", "smoke")
	_glow_layer = _DrawLayer.new()
	_glow_layer.setup(self, true)  # glow + glyph + word
	add_child(_glow_layer)
	_glow_layer.set_meta("pass", "glow")

func play(caster_pos: Vector2, _target_pos: Vector2) -> void:
	_caster = caster_pos
	_age = 0.0
	set_process(true)
	var total: float = IMPACT_DELAY + 0.32 + HOLD_TIME + FADE_TIME + 0.1
	await get_tree().create_timer(total).timeout
	if is_inside_tree():
		queue_free()

func _process(delta: float) -> void:
	_age += delta
	if not _impact_emitted and _age >= IMPACT_DELAY:
		_impact_emitted = true
		_spawn_impact_particles()
		screen_effect.emit()
	_update_particles(delta)
	_bg_layer.queue_redraw()
	_shock_layer.queue_redraw()
	_smoke_layer.queue_redraw()
	_glow_layer.queue_redraw()

func _global_alpha() -> float:
	var end_phase: float = IMPACT_DELAY + 0.32 + HOLD_TIME
	if _age < end_phase:
		return clampf(_age / 0.15, 0.0, 1.0)
	var t: float = (_age - end_phase) / FADE_TIME
	return clampf(1.0 - t, 0.0, 1.0)

# ── 파티클 ──
func _spawn_impact_particles() -> void:
	var s: float = _scale()
	# 외향 sparks (HTML: 70개, 스케일 적용)
	for _i in range(_pcount(50)):
		var a: float = randf() * TAU
		var sp: float = (60.0 + randf() * 180.0) * s
		_particles.append({
			"x": _caster.x, "y": _caster.y - 50.0,
			"vx": cos(a) * sp, "vy": sin(a) * sp,
			"life": 0.0, "max_life": 0.7 + randf() * 0.5,
			"size": (1.2 + randf() * 1.8) * s, "kind": "spark", "grav": 25.0,
		})
	# 위로 ember (HTML: 18개)
	for _i in range(_pcount(14)):
		var a2: float = randf() * TAU
		_particles.append({
			"x": _caster.x + (randf() - 0.5) * 30.0,
			"y": _caster.y - 50.0 + (randf() - 0.5) * 30.0,
			"vx": (randf() - 0.5) * 30.0, "vy": -10.0 - randf() * 30.0,
			"life": 0.0, "max_life": 1.4 + randf() * 0.8,
			"size": (1.6 + randf() * 1.4) * s, "kind": "ember", "grav": -4.0,
		})
	# 발치 dust (HTML: 30개) — 정확한 발 위치 사용
	var foot := _foot_pos()
	for _i in range(_pcount(20)):
		var a3: float = (randf() - 0.5) * 1.8
		var sp3: float = 50.0 + randf() * 120.0
		_particles.append({
			"x": foot.x + (randf() - 0.5) * 80.0, "y": foot.y,
			"vx": cos(a3) * sp3, "vy": -(15.0 + randf() * 35.0),
			"life": 0.0, "max_life": 1.0 + randf() * 0.7,
			"size": (16.0 + randf() * 14.0) * s, "kind": "dust", "grav": 12.0,
		})
	# smoke (HTML: 24개)
	for _i in range(_pcount(16)):
		var a4: float = randf() * TAU
		var sp4: float = 25.0 + randf() * 70.0
		_particles.append({
			"x": _caster.x, "y": _caster.y - 50.0,
			"vx": cos(a4) * sp4, "vy": sin(a4) * sp4 * 0.6 - 12.0,
			"life": 0.0, "max_life": 0.9 + randf() * 0.7,
			"size": (18.0 + randf() * 16.0) * s, "kind": "smoke", "grav": -6.0,
		})

func _update_particles(delta: float) -> void:
	for i in range(_particles.size() - 1, -1, -1):
		var p: Dictionary = _particles[i]
		p["life"] += delta
		if p["life"] >= p["max_life"]:
			_particles.remove_at(i)
			continue
		p["x"] += p["vx"] * delta
		p["y"] += p["vy"] * delta
		p["vy"] += p["grav"]
		p["vx"] *= pow(0.98, delta * 60.0)
		p["vy"] *= pow(0.98, delta * 60.0)

# ── 레이어별 draw ──
func _draw_bg_pass(canvas: CanvasItem) -> void:
	var ga: float = _global_alpha()
	if ga <= 0.0 or _age < IMPACT_DELAY:
		return
	# ground crack — 정확한 발 위치 (foot anchor) 사용
	var crack_age: float = _age - IMPACT_DELAY
	var crack_in: float = clampf(crack_age / 0.3, 0.0, 1.0)
	var crack_alpha: float = crack_in * ga * 0.8
	var foot := _foot_pos()
	var s: float = _scale()
	var col := Color(COL_BURN.r, COL_BURN.g, COL_BURN.b, crack_alpha)
	# 메인 zigzag
	var paths := [
		PackedVector2Array([
			foot + Vector2(-70.0, 0.0) * s, foot + Vector2(-26.0, -8.0) * s,
			foot + Vector2(-12.0, 6.0) * s, foot + Vector2(20.0, -12.0) * s,
			foot + Vector2(46.0, 0.0) * s, foot + Vector2(76.0, -6.0) * s,
		]),
		PackedVector2Array([
			foot + Vector2(-50.0, 8.0) * s, foot + Vector2(-28.0, 16.0) * s,
			foot + Vector2(-6.0, 8.0) * s, foot + Vector2(18.0, 20.0) * s,
			foot + Vector2(52.0, 12.0) * s,
		]),
		PackedVector2Array([foot + Vector2(-40.0, -10.0) * s, foot + Vector2(-24.0, -20.0) * s]),
		PackedVector2Array([foot + Vector2(10.0, 10.0) * s, foot + Vector2(22.0, 24.0) * s]),
	]
	for pts in paths:
		canvas.draw_polyline(pts, col, 1.6 * s, true)

func _draw_shock_pass(canvas: CanvasItem) -> void:
	var ga: float = _global_alpha()
	if ga <= 0.0 or not _impact_emitted:
		return
	var shock_age: float = _age - IMPACT_DELAY
	var s: float = _scale()
	# 3 concentric shockwave (s1: red strong / s2: burn / s3: brass)
	_draw_one_shock(canvas, shock_age, 0.0, 0.9, COL_TAUNT, 3.0, ga, s)
	_draw_one_shock(canvas, shock_age, 0.12, 1.05, COL_BURN, 2.2, ga * 0.85, s)
	_draw_one_shock(canvas, shock_age, 0.22, 1.2, COL_BRASS, 1.6, ga * 0.7, s)
	# chest flash (interior burst)
	if shock_age < 0.35:
		var k: float = shock_age / 0.35
		var alpha: float = (1.0 - k) * ga
		var r: float = CHEST_R * (0.3 + k * 2.0) * s
		canvas.draw_circle(_caster + Vector2(0.0, -50.0), r, Color(COL_HOT.r, COL_HOT.g, COL_HOT.b, alpha * 0.9))
		canvas.draw_circle(_caster + Vector2(0.0, -50.0), r * 0.55, Color(COL_BURN.r, COL_BURN.g, COL_BURN.b, alpha))

func _draw_one_shock(canvas: CanvasItem, shock_age: float, delay: float, duration: float, col: Color, width: float, ga: float, s: float) -> void:
	var t: float = shock_age - delay
	if t < 0.0 or t > duration:
		return
	var k: float = t / duration
	var r: float = SHOCK_BASE_R + (SHOCK_MAX_R - SHOCK_BASE_R) * k
	r *= s
	var alpha: float = 0.0
	if k < 0.15:
		alpha = (k / 0.15) * ga
	else:
		alpha = (1.0 - (k - 0.15) / 0.85) * ga
	var w: float = max(1.0, width * (1.0 - k * 0.7)) * s
	# 원 path
	var seg := 64
	var pts := PackedVector2Array()
	for i in range(seg + 1):
		var a: float = TAU * float(i) / float(seg)
		pts.append(_caster + Vector2(cos(a), sin(a)) * r + Vector2(0.0, -50.0))
	canvas.draw_polyline(pts, Color(col.r, col.g, col.b, alpha), w, true)

func _draw_smoke_pass(canvas: CanvasItem) -> void:
	var ga: float = _global_alpha()
	if ga <= 0.0:
		return
	# smoke + dust (lower layer, normal blend)
	for p in _particles:
		var kind: String = p["kind"]
		if kind != "smoke" and kind != "dust":
			continue
		var k: float = float(p["life"]) / float(p["max_life"])
		var a: float = (1.0 - k) * 0.4 * ga
		var r: float = float(p["size"]) * (1.0 + k * 1.5)
		var col: Color
		if kind == "smoke":
			col = Color(1.0, 0.55, 0.35, a * 0.7)
		else:
			col = Color(0.70, 0.55, 0.35, a)
		canvas.draw_circle(Vector2(p["x"], p["y"]), r, col)

func _draw_glow_pass(canvas: CanvasItem) -> void:
	var ga: float = _global_alpha()
	if ga <= 0.0:
		return
	# sparks + embers (additive)
	for p in _particles:
		var kind: String = p["kind"]
		if kind != "spark" and kind != "ember":
			continue
		var k: float = float(p["life"]) / float(p["max_life"])
		var a: float = (1.0 - k) * ga
		var col: Color
		if kind == "spark":
			col = Color(1.0, (180.0 - 80.0 * k) / 255.0, (110.0 - 60.0 * k) / 255.0, a)
			canvas.draw_circle(Vector2(p["x"], p["y"]), float(p["size"]), col)
		else:
			col = Color(1.0, (140.0 - 60.0 * k) / 255.0, (80.0 - 40.0 * k) / 255.0, a * 0.9)
			canvas.draw_circle(Vector2(p["x"], p["y"]), float(p["size"]), col)
	# glyph (자물쇠 — 원형 + 4방향 tick + 다이아몬드 blade)
	if _impact_emitted:
		_draw_glyph(canvas, ga)
	# word "도발" — 큰 텍스트 (Cinzel/SacredTheme 폰트 사용 — 한글은 NotoSans fallback)
	if _impact_emitted:
		_draw_word(canvas, ga)

func _draw_glyph(canvas: CanvasItem, ga: float) -> void:
	var glyph_age: float = _age - IMPACT_DELAY
	if glyph_age < 0.0:
		return
	var pop_t: float = clampf(glyph_age / 0.45, 0.0, 1.0)
	var scale_g: float = 0.2
	if pop_t <= 0.6:
		scale_g = 0.2 + (pop_t / 0.6) * 1.0
	else:
		scale_g = 1.2 - ((pop_t - 0.6) / 0.4) * 0.2
	var rot: float = (glyph_age - 0.45) * (TAU / 4.0)  # 4초당 1회전
	if rot < 0.0:
		rot = 0.0
	var s: float = _scale() * scale_g
	var ctr := _caster + Vector2(0.0, GLYPH_OFFSET_Y)
	# 외곽 ring
	var alpha: float = ga * pop_t
	_draw_ring(canvas, ctr, GLYPH_R * s, 2.5, Color(COL_BURN.r, COL_BURN.g, COL_BURN.b, alpha))
	# 내부 ring (황금)
	_draw_ring(canvas, ctr, GLYPH_R * 0.76 * s, 1.5, Color(COL_BRASS.r, COL_BRASS.g, COL_BRASS.b, alpha * 0.7))
	# 4방향 tick (N/E/S/W) — 회전 적용
	for i in range(4):
		var a: float = rot + (TAU / 4.0) * float(i)
		var p1: Vector2 = ctr + Vector2(cos(a), sin(a)) * (GLYPH_R - 8.0) * s
		var p2: Vector2 = ctr + Vector2(cos(a), sin(a)) * GLYPH_R * s
		canvas.draw_line(p1, p2, Color(COL_HOT.r, COL_HOT.g, COL_HOT.b, alpha), 2.5 * s, true)
	# 중심 다이아몬드 (blade)
	var d: float = 12.0 * s
	var diamond := PackedVector2Array([
		ctr + Vector2(0.0, -d).rotated(rot),
		ctr + Vector2(d * 0.6, 0.0).rotated(rot),
		ctr + Vector2(0.0, d).rotated(rot),
		ctr + Vector2(-d * 0.6, 0.0).rotated(rot),
	])
	canvas.draw_colored_polygon(diamond, Color(COL_TAUNT.r, COL_TAUNT.g, COL_TAUNT.b, alpha))

func _draw_ring(canvas: CanvasItem, ctr: Vector2, r: float, width: float, col: Color) -> void:
	var seg := 32
	var pts := PackedVector2Array()
	for i in range(seg + 1):
		var a: float = TAU * float(i) / float(seg)
		pts.append(ctr + Vector2(cos(a), sin(a)) * r)
	canvas.draw_polyline(pts, col, width, true)

func _draw_word(canvas: CanvasItem, ga: float) -> void:
	var word_age: float = _age - IMPACT_DELAY
	if word_age < 0.0:
		return
	var pop_t: float = clampf(word_age / 0.25, 0.0, 1.0)
	var alpha: float = ga * pop_t
	# 마지막 페이드
	var word_end: float = HOLD_TIME
	if word_age > word_end:
		alpha *= clampf(1.0 - (word_age - word_end) / 0.4, 0.0, 1.0)
	if alpha <= 0.01:
		return
	# 한글 폰트 가져오기 — SacredTheme display 폰트
	var theme_font: Font = null
	var sacred = get_node_or_null("/root/SacredTheme")
	if sacred and sacred.theme != null:
		theme_font = sacred.theme.default_font
	if theme_font == null:
		theme_font = ThemeDB.fallback_font
	var text := "도발"
	var fsize: int = int(56 * _scale())
	# 흔들림
	var shake_x: float = sin(word_age * 90.0) * 2.0 * _scale()
	var shake_y: float = cos(word_age * 110.0) * 1.5 * _scale()
	var pos := _caster + Vector2(shake_x, WORD_OFFSET_Y + shake_y)
	var size_v: Vector2 = theme_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize)
	var draw_pos: Vector2 = pos - Vector2(size_v.x * 0.5, 0.0)
	# 그림자 (붉음)
	canvas.draw_string(theme_font, draw_pos + Vector2(0.0, 4.0), text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, Color(COL_DEEP.r, COL_DEEP.g, COL_DEEP.b, alpha * 0.9))
	# 본체 (흰)
	canvas.draw_string(theme_font, draw_pos, text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, Color(COL_HOT.r, COL_HOT.g, COL_HOT.b, alpha))

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
			"bg":    _fx._draw_bg_pass(self)
			"shock": _fx._draw_shock_pass(self)
			"smoke": _fx._draw_smoke_pass(self)
			_:       _fx._draw_glow_pass(self)
