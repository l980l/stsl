# scenes/vfx/sacrifice.gd
# 자해 강화 VFX — ui_sample/vfx/Sacrifice VFX.html 재현.
# 적 SACRIFICE intent + 영웅(잔다르크) SACRIFICE_HP 카드 effect 양쪽 사용.
# play(_caster_pos, target_pos) — caster 무시, target = 자기 위치.
# ground (캐릭터 뒤): 회전 spiral ring (바닥) + 피 column rising
# glow  (캐릭터 앞): aura outline + slash mark + drip + sigil glyph + flash + 피 sparks
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
const COL_BLOOD      := Color(0.850, 0.290, 0.313)         # #d94a50
const COL_BLOOD_MID  := Color(0.545, 0.101, 0.121)         # #8b1a1f
const COL_BLOOD_DEEP := Color(0.290, 0.050, 0.062)         # #4a0d10
const COL_BRASS      := Color(0.909, 0.784, 0.470)         # #e8c878 (sigil 강조)

const CHARGE_TIME    := 0.2     # brace
const IMPACT_DELAY   := 0.35    # slash 시점 (peak)
const HOLD_TIME      := 0.7     # empowered hold (spiral·column·sigil 잔존)
const FADE_TIME      := 0.4
const SPIRAL_R       := 130.0   # 바닥 spiral 반경
const RING_SQUASH    := 0.32    # 바닥 perspective
const COLUMN_W       := 130.0
const COLUMN_H       := 200.0
const AURA_W         := 110.0
const AURA_H         := 180.0
const SIGIL_Y_OFFSET := -130.0  # 머리 위 sigil
const SIGIL_R        := 32.0
const SLASH_W        := 120.0
const SLASH_THICK    := 8.0
const PSPEED         := 60.0

## 화면 플래시 + screen shake + SFX (peak = slash 시점)
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
var _particles: Array = []
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

# peak (slash 시점) — 외곽 핏방울 spray + 발치 dust
func _spawn_peak_burst() -> void:
	# 핏방울 (위·아래로 튀는)
	for _i in range(_pcount(28)):
		var a := randf() * PI - PI * 0.5  # 위 절반
		var sp := 3.0 + randf() * 5.0
		_particles.append({
			"pos": _target + Vector2(0.0, -30.0),
			"vel": Vector2(cos(a) * sp, sin(a) * sp - 0.5),
			"life": 0.0,
			"max_life": 0.8 + randf() * 0.5,
			"size": 1.5 + randf() * 1.6,
			"kind": "drip",
			"tint": "blood" if randf() < 0.85 else "hot",
			"grav": 0.06,  # 중력 — 핏방울 떨어짐
		})
	# 발치 검붉은 dust
	var foot: Vector2 = _foot_pos()
	for _i in range(_pcount(12)):
		var a2 := randf() * TAU
		var sp2 := 1.5 + randf() * 2.5
		_particles.append({
			"pos": foot,
			"vel": Vector2(cos(a2) * sp2, sin(a2) * sp2 * 0.25 - 0.4 - randf() * 0.5),
			"life": 0.0,
			"max_life": 1.0 + randf() * 0.5,
			"size": 14.0 + randf() * 12.0,
			"kind": "dust",
			"grav": -0.005,
		})

# hold 동안 — aura 잔존 ember + spiral 따라 도는 모트
func _spawn_hold_ember() -> void:
	var foot: Vector2 = _foot_pos()
	if randf() < 0.45 * _scale():
		_particles.append({
			"pos": Vector2(foot.x + randf_range(-80.0, 80.0), foot.y - randf() * 30.0),
			"vel": Vector2(randf_range(-0.3, 0.3), -0.6 - randf() * 0.5),
			"life": 0.0,
			"max_life": 1.0 + randf() * 0.5,
			"size": 1.0 + randf() * 1.0,
			"kind": "ember",
		})

func _process(delta: float) -> void:
	_age += delta
	if not _impact_emitted and _age >= IMPACT_DELAY:
		_impact_emitted = true
		_spawn_peak_burst()
		screen_effect.emit()
	if _impact_emitted and _age < IMPACT_DELAY + HOLD_TIME:
		_spawn_hold_ember()

	var alive: Array = []
	for p in _particles:
		p["life"] += delta
		if p["life"] >= p["max_life"]:
			continue
		p["pos"] += p["vel"] * delta * PSPEED
		p["vel"].y += p.get("grav", 0.0) * delta * PSPEED
		p["vel"] *= pow(0.992, delta * 60.0)
		alive.append(p)
	_particles = alive

	_ground_layer.queue_redraw()
	_glow_layer.queue_redraw()

func _global_alpha() -> float:
	if _age < IMPACT_DELAY + HOLD_TIME:
		return clampf(_age / 0.15, 0.0, 1.0)
	var t: float = (_age - (IMPACT_DELAY + HOLD_TIME)) / FADE_TIME
	return clampf(1.0 - t, 0.0, 1.0)

# ── ground (가산, 캐릭터 뒤) — 회전 spiral ring + 피 column rising + 바닥 dust ──
func _draw_ground_pass(canvas: CanvasItem) -> void:
	var ga: float = _global_alpha()
	if ga <= 0.0:
		return
	_draw_blood_spiral(canvas, ga)
	_draw_blood_column(canvas, ga)
	for p in _particles:
		if p["kind"] != "dust":
			continue
		var k: float = p["life"] / p["max_life"]
		var a: float = (1.0 - k) * 0.45 * ga
		var r: float = p["size"] * (1.0 + k * 1.3)
		canvas.draw_circle(p["pos"], r, Color(COL_BLOOD_DEEP, a))

# ── glow (가산, 캐릭터 앞) — aura outline + slash + drip + sigil + ember + 핏방울 ──
func _draw_glow_pass(canvas: CanvasItem) -> void:
	var ga: float = _global_alpha()
	if ga <= 0.0:
		return
	_draw_aura(canvas, ga)
	_draw_slash(canvas, ga)
	if _impact_emitted:
		_draw_sigil(canvas, ga)
	# drip + ember + hot
	for p in _particles:
		if p["kind"] == "drip":
			var k: float = p["life"] / p["max_life"]
			var a: float = (1.0 - k) * ga
			var col: Color
			if p["tint"] == "hot":
				col = Color(COL_HOT.r, COL_HOT.g, COL_HOT.b, a)
			else:
				col = Color(COL_BLOOD.r, COL_BLOOD.g, COL_BLOOD.b, 0.95 * a)
			# 핏방울 — 세로로 늘어난 ellipse
			var pts := PackedVector2Array()
			var seg := 12
			for i in range(seg + 1):
				var ag: float = TAU * float(i) / float(seg)
				pts.append(p["pos"] + Vector2(cos(ag) * p["size"] * 0.6, sin(ag) * p["size"] * 1.3))
			canvas.draw_colored_polygon(pts, col)
		elif p["kind"] == "ember":
			var k2: float = p["life"] / p["max_life"]
			var a2: float = (1.0 - k2) * ga
			var col2 := Color(COL_BLOOD.r, COL_BLOOD.g, COL_BLOOD.b, a2)
			var pr: float = p["size"]
			canvas.draw_circle(p["pos"], pr * 1.6, Color(col2.r, col2.g, col2.b, col2.a * 0.45))
			canvas.draw_circle(p["pos"], pr, col2)

# 발치 회전 spiral — 빨간 동심원 + 5개 방사 선 (피 spiral 효과)
func _draw_blood_spiral(canvas: CanvasItem, ga: float) -> void:
	var grow: float = clampf(_age / 0.4, 0.0, 1.0)
	if grow <= 0.0:
		return
	var fade: float = 1.0
	if _age > IMPACT_DELAY + HOLD_TIME:
		fade = clampf(1.0 - (_age - IMPACT_DELAY - HOLD_TIME) / FADE_TIME, 0.0, 1.0)
	if fade <= 0.0:
		return
	var alpha: float = grow * fade * ga * 0.85
	var foot: Vector2 = _foot_pos()
	var r: float = SPIRAL_R * grow
	# 외곽 동심원
	var seg := 48
	for radius in [r, r * 0.78, r * 0.55]:
		var pts := PackedVector2Array()
		for i in range(seg + 1):
			var a: float = TAU * float(i) / float(seg)
			pts.append(foot + Vector2(cos(a) * radius, sin(a) * radius * RING_SQUASH))
		canvas.draw_polyline(pts, Color(COL_BLOOD, alpha * 0.7), 1.5, true)
	# 회전 방사선 (5)
	var rot: float = _age * 1.0  # rad/s
	for i in range(5):
		var ang: float = rot + TAU * float(i) / 5.0
		var p0: Vector2 = foot + Vector2(cos(ang) * r * 0.2, sin(ang) * r * 0.2 * RING_SQUASH)
		var p1: Vector2 = foot + Vector2(cos(ang) * r, sin(ang) * r * RING_SQUASH)
		canvas.draw_line(p0, p1, Color(COL_BLOOD_MID, alpha * 0.85), 1.5, true)

# 발치에서 위로 솟는 피 column (사다리꼴 + 옅은 글로우)
func _draw_blood_column(canvas: CanvasItem, ga: float) -> void:
	var rise: float = clampf((_age - 0.1) / 0.5, 0.0, 1.0)
	if rise <= 0.0:
		return
	var fade: float = 1.0
	if _age > IMPACT_DELAY + HOLD_TIME:
		fade = clampf(1.0 - (_age - IMPACT_DELAY - HOLD_TIME) / FADE_TIME, 0.0, 1.0)
	# pulse — 0.7~1.0 진동
	var pulse: float = 0.7 + sin(_age * (TAU / 1.6)) * 0.15
	var alpha: float = rise * fade * ga * pulse
	if alpha <= 0.0:
		return
	var foot: Vector2 = _foot_pos()
	var h: float = COLUMN_H * rise
	var w: float = COLUMN_W
	var bottom_y: float = foot.y
	var top_y: float = foot.y - h
	# 외층 (어두운 핏빛)
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(foot.x - w * 0.45, bottom_y),
		Vector2(foot.x + w * 0.45, bottom_y),
		Vector2(foot.x + w * 0.18, top_y),
		Vector2(foot.x - w * 0.18, top_y),
	]), Color(COL_BLOOD_MID, alpha * 0.6))
	# 코어 (밝은 핏빛)
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(foot.x - w * 0.25, bottom_y),
		Vector2(foot.x + w * 0.25, bottom_y),
		Vector2(foot.x + w * 0.08, top_y),
		Vector2(foot.x - w * 0.08, top_y),
	]), Color(COL_BLOOD, alpha * 0.7))

# 캐릭터 둘러싼 빨간 aura 외곽 사각 ring (pulse)
func _draw_aura(canvas: CanvasItem, ga: float) -> void:
	var grow: float = clampf(_age / 0.45, 0.0, 1.0)
	if grow <= 0.0:
		return
	var fade: float = 1.0
	if _age > IMPACT_DELAY + HOLD_TIME:
		fade = clampf(1.0 - (_age - IMPACT_DELAY - HOLD_TIME) / FADE_TIME, 0.0, 1.0)
	if fade <= 0.0:
		return
	var pulse: float = 0.8 + sin(_age * (TAU / 1.8)) * 0.18
	var alpha: float = grow * fade * ga * pulse * 0.7
	# 캐릭터 BBox = 약 110×180. _target 가 캐릭터 중심으로 가정
	var ctr := _target + Vector2(0.0, -30.0)  # 캐릭터 가운데 보정
	var w: float = AURA_W * 0.5 * grow
	var h: float = AURA_H * 0.5 * grow
	# round rect 윤곽
	var pts := PackedVector2Array()
	var seg := 48
	for i in range(seg + 1):
		var a: float = TAU * float(i) / float(seg)
		# 약간 round 한 사각 — superellipse 근사
		var cx: float = cos(a)
		var sy: float = sin(a)
		var ex: float = w * sign(cx) * pow(abs(cx), 0.7)
		var ey: float = h * sign(sy) * pow(abs(sy), 0.7)
		pts.append(ctr + Vector2(ex, ey))
	canvas.draw_polyline(pts, Color(COL_BLOOD, alpha), 2.0, true)
	# 내부 옅은 글로우
	canvas.draw_polyline(pts, Color(COL_BLOOD, alpha * 0.4), 4.0, true)

# slash mark — 가슴 부근 횡단선 (peak 시 1회)
func _draw_slash(canvas: CanvasItem, ga: float) -> void:
	var slash_age: float = _age - IMPACT_DELAY * 0.55
	if slash_age < 0.0 or slash_age > 0.42:
		return
	var t: float = slash_age / 0.42
	var sc: float
	var alpha: float
	if t < 0.25:
		sc = lerpf(0.0, 1.0, t / 0.25)
		alpha = t / 0.25
	else:
		sc = lerpf(1.0, 1.1, (t - 0.25) / 0.75)
		alpha = 1.0 - (t - 0.25) / 0.75
	alpha *= ga
	if alpha <= 0.0:
		return
	# 가슴 위치
	var ctr := _target + Vector2(0.0, -50.0)
	# -8도 회전 — 약간 비스듬
	var ang: float = -0.14
	var dx: float = cos(ang) * SLASH_W * 0.5 * sc
	var dy: float = sin(ang) * SLASH_W * 0.5 * sc
	var p0: Vector2 = ctr + Vector2(-dx, -dy)
	var p1: Vector2 = ctr + Vector2(dx, dy)
	# 두꺼운 흰 코어 + 빨간 외층
	canvas.draw_line(p0, p1, Color(COL_BLOOD, alpha * 0.85), SLASH_THICK * 1.5, true)
	canvas.draw_line(p0, p1, Color(COL_HOT, alpha), SLASH_THICK * 0.5, true)

# sigil — 머리 위 빨간 십자 + 황동 원 (sacrifice 표식)
func _draw_sigil(canvas: CanvasItem, ga: float) -> void:
	var post: float = _age - IMPACT_DELAY
	var pop: float = clampf(post / 0.5, 0.0, 1.0)
	var fade: float = 1.0
	if _age > IMPACT_DELAY + HOLD_TIME:
		fade = clampf(1.0 - (_age - IMPACT_DELAY - HOLD_TIME) / 0.5, 0.0, 1.0)
	if fade <= 0.0:
		return
	# floating offset
	var float_y: float = sin(post * (TAU / 3.0)) * 4.0
	var sc: float = lerpf(0.4, 1.0, pop)
	var alpha: float = pop * fade * ga
	var ctr: Vector2 = _target + Vector2(0.0, SIGIL_Y_OFFSET + float_y)
	var r: float = SIGIL_R * sc
	# 외곽 황동 ring
	canvas.draw_arc(ctr, r, 0.0, TAU, 32, Color(COL_BRASS, alpha * 0.85), 1.8, true)
	canvas.draw_arc(ctr, r * 0.7, 0.0, TAU, 24, Color(COL_BLOOD, alpha * 0.6), 1.2, true)
	# 가시 (cross) — 4 방향 piercing arms
	var arm_long: float = r * 1.1
	var arm_short: float = r * 0.65
	# 세로 가시 (위·아래 — 더 김, 순교 십자)
	canvas.draw_line(ctr + Vector2(0, -arm_long), ctr + Vector2(0, -arm_short * 0.8), Color(COL_BLOOD, alpha), 2.0, true)
	canvas.draw_line(ctr + Vector2(0, arm_long), ctr + Vector2(0, arm_short * 0.8), Color(COL_BLOOD, alpha), 2.0, true)
	canvas.draw_line(ctr + Vector2(-arm_long, 0), ctr + Vector2(-arm_short * 0.8, 0), Color(COL_BLOOD, alpha), 2.0, true)
	canvas.draw_line(ctr + Vector2(arm_long, 0), ctr + Vector2(arm_short * 0.8, 0), Color(COL_BLOOD, alpha), 2.0, true)
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
