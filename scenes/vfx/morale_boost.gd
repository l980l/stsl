# scenes/vfx/morale_boost.gd
# 사기 진작 VFX — ui_sample/vfx/Morale Boost VFX.html 재현 (GAIN_MORALE EffectType).
# play(_caster, target_pos) — caster 무시, target = 자기 위치.
# ground (캐릭터 뒤): 발치 회전 ring + sunburst 회전 ray + brass wash
# glow  (캐릭터 앞): 깃발 pole + flag + 3겹 trumpet ring + 머리 위 sigil(laurel)
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


const COL_HOT          := Color(1.0, 1.0, 1.0)
const COL_BRASS_300    := Color(0.956, 0.862, 0.627)         # #f4dca0
const COL_BRASS        := Color(0.909, 0.784, 0.470)         # #e8c878
const COL_BRASS_MID    := Color(0.721, 0.564, 0.164)         # #b8902a
const COL_BRASS_DEEP   := Color(0.419, 0.329, 0.094)         # #6b5418
const COL_BANNER       := Color(0.752, 0.219, 0.121)         # #c0381f 빨강 깃발
const COL_BANNER_SHADE := Color(0.478, 0.109, 0.062)         # #7a1c10 깃발 그림자
const COL_POLE         := Color(0.227, 0.156, 0.078)         # #3a2814 깃대

const CHARGE_TIME      := 0.3     # 깃대 솟구침
const IMPACT_DELAY     := 0.5     # trumpet 발산 (peak)
const HOLD_TIME        := 0.75    # banner + sigil + sunburst 잔존
const FADE_TIME        := 0.5
const RING_RADIUS      := 140.0
const RING_SQUASH      := 0.32
const SUNBURST_RAYS    := 12
const SUNBURST_R       := 220.0
const POLE_H           := 180.0   # 깃대 길이
const POLE_X_OFFSET    := 30.0    # 캐릭터 옆 (오른손 든 듯)
const FLAG_W           := 100.0   # 깃발 가로
const FLAG_H           := 70.0
const SIGIL_Y_OFFSET   := -150.0
const SIGIL_R          := 32.0
const PSPEED           := 60.0

## 화면 플래시 + 사기 진작 SFX (peak = trumpet 발산 시점)
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

# peak (trumpet 발산) — 외곽으로 튀는 황금 sparks + 발치 dust
func _spawn_peak_burst() -> void:
	var ctr: Vector2 = _target + Vector2(0.0, -40.0)
	for _i in range(_pcount(28)):
		var a := randf() * TAU
		var sp := 2.5 + randf() * 5.0
		_particles.append({
			"pos": ctr,
			"vel": Vector2(cos(a) * sp, sin(a) * sp - 0.5),
			"life": 0.0,
			"max_life": 0.9 + randf() * 0.5,
			"size": 1.4 + randf() * 1.4,
			"kind": "spark",
			"tint": "brass" if randf() < 0.7 else "hot",
			"grav": 0.015,
		})
	var foot: Vector2 = _foot_pos()
	for _i in range(_pcount(12)):
		var a2 := randf() * TAU
		var sp2 := 1.5 + randf() * 2.5
		_particles.append({
			"pos": foot,
			"vel": Vector2(cos(a2) * sp2, sin(a2) * sp2 * 0.2 - 0.4 - randf() * 0.5),
			"life": 0.0,
			"max_life": 1.0 + randf() * 0.5,
			"size": 12.0 + randf() * 12.0,
			"kind": "dust",
			"grav": -0.005,
		})

# hold 동안 — 발치 위로 부드럽게 솟는 황금 ember
func _spawn_hold_ember() -> void:
	var foot: Vector2 = _foot_pos()
	if randf() < 0.4 * _scale():
		_particles.append({
			"pos": Vector2(foot.x + randf_range(-90.0, 90.0), foot.y - randf() * 30.0),
			"vel": Vector2(randf_range(-0.2, 0.2), -0.5 - randf() * 0.4),
			"life": 0.0,
			"max_life": 1.0 + randf() * 0.5,
			"size": 1.0 + randf() * 1.1,
			"kind": "spark",
			"tint": "brass",
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

# ── ground (가산, 캐릭터 뒤) — 발치 황금 ring + sunburst 회전 ray + brass wash + 바닥 dust ──
func _draw_ground_pass(canvas: CanvasItem) -> void:
	var ga: float = _global_alpha()
	if ga <= 0.0:
		return
	_draw_sunburst(canvas, ga)
	_draw_ring(canvas, ga)
	# brass wash — peak 후
	if _impact_emitted:
		var wash_t: float = (_age - IMPACT_DELAY) / 0.4
		var wash_alpha: float = clampf(wash_t, 0.0, 1.0) * 0.35 * ga
		if _age > IMPACT_DELAY + HOLD_TIME:
			wash_alpha *= clampf(1.0 - (_age - IMPACT_DELAY - HOLD_TIME) / FADE_TIME, 0.0, 1.0)
		if wash_alpha > 0.0:
			var seg := 32
			var pts := PackedVector2Array()
			for i in range(seg + 1):
				var a: float = TAU * float(i) / float(seg)
				pts.append(_target + Vector2(cos(a) * 180.0, sin(a) * 130.0))
			canvas.draw_colored_polygon(pts, Color(COL_BRASS_DEEP, wash_alpha))
	# 바닥 dust
	for p in _particles:
		if p["kind"] != "dust":
			continue
		var k: float = p["life"] / p["max_life"]
		var a: float = (1.0 - k) * 0.4 * ga
		var r: float = p["size"] * (1.0 + k * 1.3)
		canvas.draw_circle(p["pos"], r, Color(COL_BRASS_DEEP, a))

# 발치 회전 황금 ring — 외원 + 점선 안쪽 + 별 4 마커
func _draw_ring(canvas: CanvasItem, ga: float) -> void:
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
	for i in range(16):
		var a0: float = TAU * float(i) / 16.0
		var a1: float = a0 + TAU / 32.0
		var dr: float = r * 0.78
		var arc := PackedVector2Array()
		for k in range(4):
			var t: float = float(k) / 3.0
			var ang: float = lerpf(a0, a1, t)
			arc.append(foot + Vector2(cos(ang) * dr, sin(ang) * dr * RING_SQUASH))
		canvas.draw_polyline(arc, Color(COL_BRASS_MID, alpha * 0.7), 1.0, true)
	# 4 방향 별 마커 (회전)
	var rot: float = _age * 0.35
	for i in range(4):
		var ang: float = rot + TAU * float(i) / 4.0
		var mp := foot + Vector2(cos(ang) * r * 1.02, sin(ang) * r * 1.02 * RING_SQUASH)
		_draw_star(canvas, mp, 5.0, Color(COL_BRASS_300, alpha * 0.95))

func _draw_star(canvas: CanvasItem, ctr: Vector2, r: float, col: Color) -> void:
	# 4점 다이아 (단순화)
	canvas.draw_colored_polygon(PackedVector2Array([
		ctr + Vector2(0, -r), ctr + Vector2(r, 0),
		ctr + Vector2(0, r), ctr + Vector2(-r, 0),
	]), col)

# sunburst — 캐릭터 뒤 큰 황금 ray 부채 (회전)
func _draw_sunburst(canvas: CanvasItem, ga: float) -> void:
	var grow: float = clampf(_age / 0.5, 0.0, 1.0)
	if grow <= 0.0:
		return
	var fade: float = 1.0
	if _age > IMPACT_DELAY + HOLD_TIME:
		fade = clampf(1.0 - (_age - IMPACT_DELAY - HOLD_TIME) / FADE_TIME, 0.0, 1.0)
	if fade <= 0.0:
		return
	var alpha: float = grow * fade * ga * 0.55
	var ctr: Vector2 = _target + Vector2(0.0, -20.0)
	var sb_r: float = SUNBURST_R * grow
	var rot: float = _age * 0.18  # 천천히 회전
	for i in range(SUNBURST_RAYS):
		var ang: float = rot + TAU * float(i) / float(SUNBURST_RAYS)
		var perp_ang: float = ang + PI * 0.5
		var perp: Vector2 = Vector2(cos(perp_ang), sin(perp_ang)) * sb_r * 0.04
		var tip: Vector2 = ctr + Vector2(cos(ang), sin(ang)) * sb_r
		var base_l: Vector2 = ctr + perp
		var base_r: Vector2 = ctr - perp
		canvas.draw_colored_polygon(PackedVector2Array([base_l, tip, base_r]), Color(COL_BRASS, alpha))
		# 내층 (옅은)
		var tip2: Vector2 = ctr + Vector2(cos(ang), sin(ang)) * sb_r * 0.6
		canvas.draw_colored_polygon(PackedVector2Array([base_l, tip2, base_r]), Color(COL_BRASS_300, alpha * 0.8))

# ── glow (가산, 캐릭터 앞) — 깃대 + flag + 3겹 trumpet ring + 머리 위 sigil + sparks ──
func _draw_glow_pass(canvas: CanvasItem) -> void:
	var ga: float = _global_alpha()
	if ga <= 0.0:
		return
	_draw_pole_and_flag(canvas, ga)
	# 3겹 trumpet ring (peak)
	if _impact_emitted:
		_draw_trumpet_ring(canvas, 0.0, ga, COL_BRASS)
		_draw_trumpet_ring(canvas, 0.12, ga, COL_BRASS_300)
		_draw_trumpet_ring(canvas, 0.24, ga, COL_HOT)
	# 머리 위 sigil (laurel)
	if _impact_emitted:
		_draw_sigil(canvas, ga)
	# sparks
	for p in _particles:
		if p["kind"] != "spark":
			continue
		var k: float = p["life"] / p["max_life"]
		var a: float = (1.0 - k) * ga
		var col := _spark_color(p["tint"], a)
		var pr: float = p["size"]
		canvas.draw_circle(p["pos"], pr * 1.8, Color(col.r, col.g, col.b, col.a * 0.45))
		canvas.draw_circle(p["pos"], pr, col)
		canvas.draw_rect(Rect2(p["pos"].x - pr * 2.2, p["pos"].y - 0.3, pr * 4.4, 0.6), col)

func _spark_color(tint: String, a: float) -> Color:
	match tint:
		"hot":   return Color(COL_HOT.r, COL_HOT.g, COL_HOT.b, a)
		_:        return Color(COL_BRASS.r, COL_BRASS.g, COL_BRASS.b, a)

# 깃대 + 깃발 — caster 오른편에서 위로 솟구침, 그 후 깃발 unfurl + sway
func _draw_pole_and_flag(canvas: CanvasItem, ga: float) -> void:
	var rise: float = clampf(_age / CHARGE_TIME, 0.0, 1.0)
	if rise <= 0.0:
		return
	var fade: float = 1.0
	if _age > IMPACT_DELAY + HOLD_TIME:
		fade = clampf(1.0 - (_age - IMPACT_DELAY - HOLD_TIME) / FADE_TIME, 0.0, 1.0)
	if fade <= 0.0:
		return
	var alpha: float = rise * fade * ga
	var pole_base: Vector2 = _target + Vector2(POLE_X_OFFSET, -10.0)  # caster 손 부근
	var pole_top: Vector2 = pole_base + Vector2(0.0, -POLE_H * rise)
	# 깃대 (어두운 갈색)
	canvas.draw_line(pole_base, pole_top, Color(COL_POLE, alpha * 0.95), 3.0, true)
	# 깃대 끝 황금 finial (작은 다이아)
	canvas.draw_colored_polygon(PackedVector2Array([
		pole_top + Vector2(0, -7), pole_top + Vector2(5, 0),
		pole_top + Vector2(0, 5), pole_top + Vector2(-5, 0),
	]), Color(COL_BRASS, alpha))
	# 깃발 — 깃대 위쪽에서 오른쪽으로 펼침 (unfurl 진행)
	var unfurl: float = clampf((_age - 0.15) / 0.55, 0.0, 1.0)
	if unfurl <= 0.0:
		return
	var fw: float = FLAG_W * unfurl
	var flag_top: Vector2 = pole_top + Vector2(0.0, 12.0)
	# sway (좌우 휘날림)
	var sway: float = sin(_age * (TAU / 2.0)) * 6.0 * unfurl
	# 깃발 4점 (사다리꼴 + 꼬리 분기 모양 — 간단 사각형 + 우측 V 컷)
	var f_tl: Vector2 = flag_top
	var f_tr: Vector2 = flag_top + Vector2(fw, sway * 0.5)
	var f_br: Vector2 = flag_top + Vector2(fw, FLAG_H + sway * 0.5)
	var f_mid_r: Vector2 = flag_top + Vector2(fw * 0.78, (FLAG_H * 0.5) + sway * 0.4)
	var f_bl: Vector2 = flag_top + Vector2(0.0, FLAG_H)
	# 본체 (빨강)
	canvas.draw_colored_polygon(PackedVector2Array([f_tl, f_tr, f_mid_r, f_br, f_bl]),
		Color(COL_BANNER, alpha * 0.9))
	# 윗면 하이라이트
	canvas.draw_colored_polygon(PackedVector2Array([f_tl, f_tr, flag_top + Vector2(fw * 0.5, sway * 0.3 + FLAG_H * 0.35), f_tl]),
		Color(COL_BANNER_SHADE, alpha * 0.45))
	# 황금 윤곽
	canvas.draw_polyline(PackedVector2Array([f_tl, f_tr, f_mid_r, f_br, f_bl, f_tl]),
		Color(COL_BRASS, alpha), 1.2, true)
	# 중심 황금 star (heraldic)
	var star_ctr: Vector2 = flag_top + Vector2(fw * 0.4, FLAG_H * 0.5 + sway * 0.3)
	_draw_star(canvas, star_ctr, 6.0 * unfurl, Color(COL_BRASS_300, alpha))

# 3겹 trumpet ring — 가슴 위치 발산
func _draw_trumpet_ring(canvas: CanvasItem, delay: float, ga: float, base_col: Color) -> void:
	var t: float = (_age - IMPACT_DELAY - delay) / 1.1
	if t < 0.0 or t > 1.0:
		return
	var sc: float = lerpf(0.25, 8.0, t)
	var alpha: float
	if t < 0.12:
		alpha = t / 0.12
	else:
		alpha = 1.0 - (t - 0.12) / 0.88
	alpha *= ga
	if alpha <= 0.0:
		return
	var ctr: Vector2 = _target + Vector2(0.0, -40.0)
	var rad: float = 35.0 * sc
	var thick: float = lerpf(3.0, 0.5, t)
	canvas.draw_arc(ctr, rad, 0.0, TAU, 48, Color(base_col, alpha), thick, true)

# 머리 위 sigil — laurel wreath (두 호 + 황금 ring + 중심 별)
func _draw_sigil(canvas: CanvasItem, ga: float) -> void:
	var post: float = _age - IMPACT_DELAY
	var pop: float = clampf(post / 0.45, 0.0, 1.0)
	var fade: float = 1.0
	if _age > IMPACT_DELAY + HOLD_TIME:
		fade = clampf(1.0 - (_age - IMPACT_DELAY - HOLD_TIME) / 0.55, 0.0, 1.0)
	if fade <= 0.0:
		return
	var sc: float = lerpf(0.4, 1.0, pop)
	var float_y: float = sin(post * (TAU / 3.0)) * 3.0
	var alpha: float = pop * fade * ga
	var ctr: Vector2 = _target + Vector2(0.0, SIGIL_Y_OFFSET + float_y)
	var r: float = SIGIL_R * sc
	# 외곽 황동 ring
	canvas.draw_arc(ctr, r, 0.0, TAU, 32, Color(COL_BRASS, alpha * 0.9), 1.5, true)
	# 두 laurel 호 (좌우 곡선 — 위에서 시작해서 아래로 휘는 잎)
	var laurel_pts_l := PackedVector2Array()
	var laurel_pts_r := PackedVector2Array()
	var seg := 16
	for i in range(seg + 1):
		var t: float = float(i) / float(seg)
		# 왼쪽 잎: 위에서 시작 → 좌측 아래로 호
		var ang_l: float = -PI * 0.5 + t * PI * 0.95
		laurel_pts_l.append(ctr + Vector2(-cos(ang_l) * r * 0.78, sin(ang_l) * r * 0.78))
		# 오른쪽 잎
		var ang_r: float = -PI * 0.5 - t * PI * 0.95
		laurel_pts_r.append(ctr + Vector2(-cos(ang_r) * r * 0.78, sin(ang_r) * r * 0.78))
	canvas.draw_polyline(laurel_pts_l, Color(COL_BRASS_300, alpha), 2.0, true)
	canvas.draw_polyline(laurel_pts_r, Color(COL_BRASS_300, alpha), 2.0, true)
	# 잎 detail — 작은 짧은 선들
	for i in range(1, seg, 2):
		var t: float = float(i) / float(seg)
		var ang_l: float = -PI * 0.5 + t * PI * 0.95
		var pl: Vector2 = ctr + Vector2(-cos(ang_l) * r * 0.78, sin(ang_l) * r * 0.78)
		var perp_l := Vector2(sin(ang_l), -cos(ang_l)) * 4.0
		canvas.draw_line(pl, pl + perp_l, Color(COL_BRASS, alpha * 0.85), 1.0, true)
		var ang_r: float = -PI * 0.5 - t * PI * 0.95
		var pr: Vector2 = ctr + Vector2(-cos(ang_r) * r * 0.78, sin(ang_r) * r * 0.78)
		var perp_r := Vector2(-sin(ang_r), cos(ang_r)) * 4.0
		canvas.draw_line(pr, pr + perp_r, Color(COL_BRASS, alpha * 0.85), 1.0, true)
	# 중심 황금 별
	_draw_star(canvas, ctr, 5.0 * sc, Color(COL_HOT, alpha))

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
