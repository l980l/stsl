# scenes/vfx/boss_death.gd
# 보스 전용 사망 VFX — ui_sample/vfx/Boss Death VFX.html 재현.
# 5단계: tremor + cracks (보스 빛 누출) → inhale (흰 빛 모임) → BIG explosion
# → debris/embers/pillar/shock → 왕관 추락 + slate.
# play(_caster_pos, target_pos) — target_pos = 보스 중심.
# 보스 본체 dissolve 는 외부에서 처리 (battle_scene 의 캐릭터 노드 fade out).
# screen_effect 는 explosion 시점 (IMPACT_DELAY = 1.2s) 1회 emit.
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
const COL_BRASS     := Color(0.956, 0.862, 0.627)   # #f4dca0
const COL_BRASS_D   := Color(0.721, 0.564, 0.164)   # #b8902a
const COL_FIRE      := Color(1.0, 0.478, 0.227)     # #ff7a3a
const COL_FIRE_D    := Color(0.752, 0.156, 0.184)   # #c0282f
const COL_BLOOD     := Color(0.419, 0.078, 0.094)   # #6b1418
const COL_BURGUNDY  := Color(0.560, 0.094, 0.125)   # #8f1820 슬레이트 텍스트 (살짝 밝은 버건디)
const COL_DEBRIS    := Color(0.290, 0.164, 0.078)   # 어두운 돌
const COL_CHAR      := Color(0.101, 0.054, 0.031)   # 검탄

# 필기체 이탤릭 — slate 텍스트용
const _SLATE_FONT := preload("res://assets/fonts/IMFellEnglish-Italic.ttf")

const CRACK_DELAY   := 0.0          # 균열 그리기 시작
const INHALE_DELAY  := 0.55         # 흰 빛 모임
const IMPACT_DELAY  := 1.1          # BIG EXPLOSION (screen_effect emit)
const SHOCK_TIME    := 1.4          # shock ring 확장 시간
const PILLAR_TIME   := 1.2          # 화염 기둥
const CROWN_DELAY   := 2.0          # 왕관 등장
const CROWN_FALL    := 1.0          # 왕관 추락
const SLATE_DELAY   := 2.4          # slate 텍스트
const HOLD_TIME     := 2.0          # IMPACT 이후 hold (warning: 전체 = IMPACT + HOLD + FADE)
const FADE_TIME     := 1.0
const BOSS_W        := 200.0
const BOSS_H        := 280.0
const PSPEED        := 60.0

signal screen_effect

var _target := Vector2.ZERO
var _ground_pos := Vector2.ZERO
var _has_ground: bool = false

func set_ground_anchor(pos: Vector2) -> void:
	_ground_pos = pos
	_has_ground = true

func _foot_pos() -> Vector2:
	return _ground_pos if _has_ground else _target + Vector2(0.0, BOSS_H * 0.5)

# explosion 중심 (보스 몸 중앙)
func _blast_pos() -> Vector2:
	return _target

var _age := -1.0
var _impact_emitted := false
var _particles: Array = []
var _ground_layer: Node2D  # 가산 — wash, shock, pillar
var _glow_layer: Node2D    # 가산 — cracks, core blast, embers, flash
var _solid_layer: Node2D   # normal — debris (돌 조각), 왕관
var _text_layer: Node2D    # normal — Fallen 텍스트 (모든 파티클 위)

func _ready() -> void:
	set_process(false)
	_ground_layer = _DrawLayer.new()
	_ground_layer.setup(self, true)
	add_child(_ground_layer)
	_ground_layer.set_meta("pass", "ground")
	_solid_layer = _DrawLayer.new()
	_solid_layer.setup(self, false)
	add_child(_solid_layer)
	_solid_layer.set_meta("pass", "solid")
	_glow_layer = _DrawLayer.new()
	_glow_layer.setup(self, true)
	add_child(_glow_layer)
	_glow_layer.set_meta("pass", "glow")
	_text_layer = _DrawLayer.new()
	_text_layer.setup(self, false)
	add_child(_text_layer)
	_text_layer.set_meta("pass", "text")

func play(_caster_pos: Vector2, target_pos: Vector2) -> void:
	_target = target_pos
	_age = 0.0
	set_process(true)
	await get_tree().create_timer(IMPACT_DELAY + HOLD_TIME + FADE_TIME + 0.5).timeout
	if is_inside_tree():
		queue_free()

# 폭발 시점 — debris 사방 분출
func _spawn_debris_burst() -> void:
	var ctr: Vector2 = _blast_pos()
	for _i in range(_pcount(22)):
		var ang := randf() * TAU
		var sp := 3.0 + randf() * 5.0
		_particles.append({
			"pos": ctr,
			"vel": Vector2(cos(ang) * sp, sin(ang) * sp * 0.7 - 1.0),
			"life": 0.0,
			"max_life": 1.2 + randf() * 1.0,
			"size": 3.0 + randf() * 7.0,
			"kind": "debris",
			"rot": randf() * TAU,
			"rot_v": randf_range(-8.0, 8.0),
			"grav": 0.06,
		})

# 폭발 시점부터 — embers 지속 spawn
func _spawn_ember() -> void:
	var ctr: Vector2 = _blast_pos()
	if randf() > 0.8 * _scale():
		return
	var ox := randf_range(-100.0, 100.0)
	var oy := randf_range(-40.0, 40.0)
	_particles.append({
		"pos": Vector2(ctr.x + ox, ctr.y + oy),
		"vel": Vector2(randf_range(-0.5, 0.5), -1.5 - randf() * 2.0),
		"life": 0.0,
		"max_life": 1.4 + randf() * 1.2,
		"size": 1.8 + randf() * 2.0,
		"kind": "ember",
	})

func _process(delta: float) -> void:
	_age += delta
	if not _impact_emitted and _age >= IMPACT_DELAY:
		_impact_emitted = true
		screen_effect.emit()
		_spawn_debris_burst()
	if _impact_emitted and _age < IMPACT_DELAY + HOLD_TIME:
		for _i in range(_pcount(2)):
			_spawn_ember()

	var alive: Array = []
	for p in _particles:
		p["life"] += delta
		if p["life"] >= p["max_life"]:
			continue
		p["pos"] += p["vel"] * delta * PSPEED
		p["vel"].y += p.get("grav", 0.0) * delta * PSPEED
		p["vel"] *= pow(0.99, delta * 60.0)
		if p.has("rot"):
			p["rot"] += p["rot_v"] * delta
		alive.append(p)
	_particles = alive

	_ground_layer.queue_redraw()
	_solid_layer.queue_redraw()
	_glow_layer.queue_redraw()
	_text_layer.queue_redraw()

func _global_alpha() -> float:
	var end_phase: float = IMPACT_DELAY + HOLD_TIME
	if _age < end_phase:
		return clampf(_age / 0.2, 0.0, 1.0)
	var t: float = (_age - end_phase) / FADE_TIME
	return clampf(1.0 - t, 0.0, 1.0)

# ── ground (가산) — shock rings + pillar + inhale wash ──
func _draw_ground_pass(canvas: CanvasItem) -> void:
	var ga: float = _global_alpha()
	if ga <= 0.0:
		return
	_draw_inhale(canvas, ga)
	if _impact_emitted:
		_draw_shock_rings(canvas, ga)
		_draw_pillar(canvas, ga)

# 폭발 직전 흰 빛 모임 — 보스 위치 중심 큰 옅은 동심원
func _draw_inhale(canvas: CanvasItem, ga: float) -> void:
	if _age < INHALE_DELAY or _age >= IMPACT_DELAY + 0.1:
		return
	var post: float = _age - INHALE_DELAY
	var dur: float = IMPACT_DELAY - INHALE_DELAY
	var t: float = clampf(post / dur, 0.0, 1.0)
	# 안쪽으로 모이는 빛 — 큰 → 작은 동심원, alpha 점점 증가
	var alpha: float = t * ga * 0.6
	var ctr: Vector2 = _blast_pos()
	var layers := 6
	for i in range(layers):
		var li: float = float(i) / float(layers - 1)
		var rad: float = lerpf(360.0, 80.0, t) * (1.0 - li * 0.5)
		canvas.draw_circle(ctr, rad, Color(COL_BRASS.r, COL_BRASS.g, COL_BRASS.b, alpha * 0.15))

# 3 shock ring — staggered 0.15s 간격
func _draw_shock_rings(canvas: CanvasItem, ga: float) -> void:
	var ring_cols := [COL_BRASS, COL_FIRE, COL_FIRE_D]
	var ctr: Vector2 = _blast_pos()
	for ri in range(3):
		var delay: float = IMPACT_DELAY + float(ri) * 0.15
		var t: float = (_age - delay) / SHOCK_TIME
		if t < 0.0 or t > 1.0:
			continue
		var sc: float = lerpf(0.1, 8.0, t)
		var alpha: float
		if t < 0.15:
			alpha = t / 0.15
		else:
			alpha = 1.0 - (t - 0.15) / 0.85
		alpha *= ga * 0.9
		var rad: float = 60.0 * sc
		var thick: float = lerpf(4.0, 0.8, t)
		canvas.draw_arc(ctr, rad, 0.0, TAU, 48, Color(ring_cols[ri], alpha), thick, true)

# 위로 솟구치는 화염 기둥
func _draw_pillar(canvas: CanvasItem, ga: float) -> void:
	var post: float = _age - IMPACT_DELAY
	var t: float = clampf(post / PILLAR_TIME, 0.0, 1.0)
	if t >= 1.0:
		return
	var rise: float = clampf(post / 0.4, 0.0, 1.0)
	var alpha: float
	if t < 0.2:
		alpha = t / 0.2
	else:
		alpha = 1.0 - (t - 0.2) / 0.8
	alpha *= ga
	# pillar 만 발바닥에서 시작 (다른 effect 들은 보스 몸 중앙 기준 유지)
	var foot: Vector2 = _foot_pos()
	var ctr: Vector2 = Vector2(_blast_pos().x, foot.y)
	var bot_y: float = foot.y
	var h: float = 340.0 * rise
	var top_y: float = bot_y - h
	var w_bot: float = lerpf(80.0, 180.0, t)
	var w_top: float = lerpf(20.0, 80.0, t)
	# 외곽 (붉음)
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(ctr.x - w_bot, bot_y), Vector2(ctr.x + w_bot, bot_y),
		Vector2(ctr.x + w_top, top_y), Vector2(ctr.x - w_top, top_y),
	]), Color(COL_FIRE_D.r, COL_FIRE_D.g, COL_FIRE_D.b, alpha * 0.55))
	# 중간 (오렌지)
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(ctr.x - w_bot * 0.6, bot_y), Vector2(ctr.x + w_bot * 0.6, bot_y),
		Vector2(ctr.x + w_top * 0.4, top_y), Vector2(ctr.x - w_top * 0.4, top_y),
	]), Color(COL_FIRE.r, COL_FIRE.g, COL_FIRE.b, alpha * 0.7))
	# 코어 (흰)
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(ctr.x - w_bot * 0.2, bot_y), Vector2(ctr.x + w_bot * 0.2, bot_y),
		Vector2(ctr.x + w_top * 0.15, top_y), Vector2(ctr.x - w_top * 0.15, top_y),
	]), Color(COL_HOT.r, COL_HOT.g, COL_HOT.b, alpha * 0.85))

# ── solid (normal) — debris (돌 조각) + 왕관 ──
func _draw_solid_pass(canvas: CanvasItem) -> void:
	var ga: float = _global_alpha()
	if ga <= 0.0:
		return
	# debris
	for p in _particles:
		if p["kind"] != "debris":
			continue
		var k: float = p["life"] / p["max_life"]
		var a: float = (1.0 - k) * ga
		var pr: float = p["size"]
		var rot: float = p.get("rot", 0.0)
		# 회전된 작은 사각형
		var hw := pr * 0.5
		var corners := [Vector2(-hw, -hw), Vector2(hw, -hw), Vector2(hw, hw), Vector2(-hw, hw)]
		var pts := PackedVector2Array()
		for c in corners:
			var rx: float = c.x * cos(rot) - c.y * sin(rot)
			var ry: float = c.x * sin(rot) + c.y * cos(rot)
			pts.append(p["pos"] + Vector2(rx, ry))
		canvas.draw_colored_polygon(pts, Color(COL_DEBRIS.r, COL_DEBRIS.g, COL_DEBRIS.b, a))
	_draw_crown(canvas, ga)

# 왕관 SVG → polygon (5 첨탑 — HTML 의 crown svg 단순화)
func _draw_crown(canvas: CanvasItem, ga: float) -> void:
	if _age < CROWN_DELAY:
		return
	var post: float = _age - CROWN_DELAY
	var t: float = clampf(post / CROWN_FALL, 0.0, 1.0)
	# 떨어짐 — 위에서 시작 → 바닥 (foot.y)
	var ease_t: float = t * t   # easeIn (가속 떨어짐)
	var ctr: Vector2 = _blast_pos()
	var start_y: float = ctr.y - 200.0
	var end_y: float = _foot_pos().y - 10.0
	var y: float = lerpf(start_y, end_y, ease_t)
	var x: float = ctr.x
	# 회전 — 1바퀴 반 추락
	var rot: float = ease_t * PI * 1.5
	# alpha — 진입 페이드인 + hold + 페이드아웃
	var alpha: float = ga
	if t < 0.15:
		alpha *= t / 0.15
	elif _age > IMPACT_DELAY + HOLD_TIME:
		alpha *= clampf(1.0 - (_age - IMPACT_DELAY - HOLD_TIME) / FADE_TIME, 0.0, 1.0)
	if alpha <= 0.0:
		return
	# 왕관 본체 — 5 첨탑 polygon (대략 80x32, 회전 적용)
	var w := 80.0
	var h := 32.0
	var local_pts := [
		Vector2(-w * 0.5,         h * 0.5),   # 좌하
		Vector2(-w * 0.5 + 5.0,  -h * 0.25),  # 좌측 첨탑 베이스
		Vector2(-w * 0.3,         h * 0.0),   # 좌측 첨탑 사이 골
		Vector2(-w * 0.15,       -h * 0.5),   # 중앙 좌측 첨탑
		Vector2( 0.0,             h * 0.0),   # 중심 골
		Vector2( w * 0.15,       -h * 0.5),   # 중앙 우측 첨탑
		Vector2( w * 0.3,         h * 0.0),   # 우측 골
		Vector2( w * 0.5 - 5.0,  -h * 0.25),  # 우측 첨탑 베이스
		Vector2( w * 0.5,         h * 0.5),   # 우하
	]
	var pts := PackedVector2Array()
	for lp in local_pts:
		var rx: float = lp.x * cos(rot) - lp.y * sin(rot)
		var ry: float = lp.x * sin(rot) + lp.y * cos(rot)
		pts.append(Vector2(x + rx, y + ry))
	# 황금 fill + 외곽 line
	canvas.draw_colored_polygon(pts, Color(COL_BRASS.r, COL_BRASS.g, COL_BRASS.b, alpha * 0.85))
	canvas.draw_polyline(pts, Color(COL_BRASS_D.r, COL_BRASS_D.g, COL_BRASS_D.b, alpha), 2.0, true)

# ── text (normal, 가장 앞) — Fallen 슬레이트 ──
func _draw_text_pass(canvas: CanvasItem) -> void:
	var ga: float = _global_alpha()
	if ga <= 0.0:
		return
	_draw_slate(canvas, ga)

# ── glow (가산) — cracks + core blast + embers + slate ──
func _draw_glow_pass(canvas: CanvasItem) -> void:
	var ga: float = _global_alpha()
	if ga <= 0.0:
		return
	_draw_cracks(canvas, ga)
	if _impact_emitted:
		_draw_core_blast(canvas, ga)
	for p in _particles:
		if p["kind"] != "ember":
			continue
		var k: float = p["life"] / p["max_life"]
		var a: float = (1.0 - k) * ga
		var pr: float = p["size"]
		canvas.draw_circle(p["pos"], pr * 1.8, Color(COL_BRASS.r, COL_BRASS.g, COL_BRASS.b, a * 0.45))
		canvas.draw_circle(p["pos"], pr, Color(COL_BRASS.r, COL_BRASS.g, COL_BRASS.b, a))

# 균열 — 보스 영역에 5 zigzag 빛나는 선 (위에서 아래로 그려짐)
func _draw_cracks(canvas: CanvasItem, ga: float) -> void:
	if _age >= IMPACT_DELAY:
		return
	var t: float = clampf(_age / 0.7, 0.0, 1.0)
	if t <= 0.0:
		return
	var fade: float = 1.0
	if _age > INHALE_DELAY:
		fade = clampf(1.0 - (_age - INHALE_DELAY) / (IMPACT_DELAY - INHALE_DELAY), 0.0, 1.0)
		fade = lerpf(1.0, 0.0, 1.0 - fade)  # inhale 동안 점점 강해짐
		fade = clampf(fade, 0.6, 1.0)
	var alpha: float = t * ga
	var ctr: Vector2 = _target
	# 5 zigzag — 중심에서 4 방향
	var cracks := [
		{"col": COL_BRASS, "pts": [Vector2(0, -60), Vector2(-10, -10), Vector2(10, 10), Vector2(-20, 50), Vector2(0, 100)]},
		{"col": COL_FIRE,  "pts": [Vector2(0, -60), Vector2(30, -30), Vector2(20, 20), Vector2(50, 60)]},
		{"col": COL_BRASS, "pts": [Vector2(0, -60), Vector2(-30, -20), Vector2(-50, 30)]},
		{"col": COL_HOT,   "pts": [Vector2(0, 20), Vector2(40, 100)]},
		{"col": COL_HOT,   "pts": [Vector2(0, 20), Vector2(-40, 110)]},
	]
	for i in range(cracks.size()):
		var crack_t: float = clampf((_age - float(i) * 0.1) / 0.4, 0.0, 1.0)
		if crack_t <= 0.0:
			continue
		var c: Dictionary = cracks[i]
		var lp: Array = c["pts"]
		# 부분 그리기 — crack_t 비율만큼
		var n: int = lp.size()
		var visible: int = max(2, int(round(float(n) * crack_t)))
		var pts := PackedVector2Array()
		for k in range(visible):
			pts.append(ctr + lp[k])
		var col: Color = c["col"]
		canvas.draw_polyline(pts, Color(col.r, col.g, col.b, alpha), 2.5, true)
		# 흰 코어 (얇음)
		canvas.draw_polyline(pts, Color(COL_HOT.r, COL_HOT.g, COL_HOT.b, alpha * 0.6), 1.0, true)

# 폭발 코어 — 큰 흰 → 황금 동심원 (시간에 따라 확장)
func _draw_core_blast(canvas: CanvasItem, ga: float) -> void:
	var post: float = _age - IMPACT_DELAY
	var t: float = clampf(post / 1.0, 0.0, 1.0)
	if t >= 1.0:
		return
	var sc: float = lerpf(0.1, 2.4, t)
	var alpha: float
	if t < 0.1:
		alpha = t / 0.1
	else:
		alpha = 1.0 - (t - 0.1) / 0.9
	alpha *= ga
	var ctr: Vector2 = _blast_pos()
	var rad: float = 100.0 * sc
	# 가산 동심원 4겹 (radial gradient 흉내)
	var layers := 12
	for i in range(layers):
		var li: float = float(i) / float(layers - 1)
		var r: float = lerpf(rad, rad * 0.3, li)
		var a: float = alpha * 0.08
		var col_t: float = li
		var c := Color(COL_HOT.r, COL_HOT.g, COL_HOT.b, a)
		if col_t > 0.5:
			c = Color(COL_BRASS.r, COL_BRASS.g, COL_BRASS.b, a)
		if col_t > 0.8:
			c = Color(COL_FIRE.r, COL_FIRE.g, COL_FIRE.b, a)
		canvas.draw_circle(ctr, r, c)

# slate 텍스트 — 화면 중앙 "BOSS DEFEATED"
func _draw_slate(canvas: CanvasItem, ga: float) -> void:
	if _age < SLATE_DELAY:
		return
	var post: float = _age - SLATE_DELAY
	var pop: float = clampf(post / 0.35, 0.0, 1.0)
	var fade: float = 1.0
	if _age > IMPACT_DELAY + HOLD_TIME:
		fade = clampf(1.0 - (_age - IMPACT_DELAY - HOLD_TIME) / FADE_TIME, 0.0, 1.0)
	var alpha: float = pop * fade * ga
	if alpha <= 0.0:
		return
	var sc: float = lerpf(1.2, 1.0, pop)
	var main_size: int = int(96.0 * sc)
	var ctr: Vector2 = Vector2(_target.x, _target.y - 60.0)
	canvas.draw_string(_SLATE_FONT, Vector2(ctr.x - 240.0, ctr.y + 40.0), "Fallen",
		HORIZONTAL_ALIGNMENT_CENTER, 480.0, main_size,
		Color(COL_BURGUNDY.r, COL_BURGUNDY.g, COL_BURGUNDY.b, alpha))

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
			"solid":  _fx._draw_solid_pass(self)
			"text":   _fx._draw_text_pass(self)
			_:        _fx._draw_glow_pass(self)
