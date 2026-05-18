# scenes/vfx/steal_card.gd
# 카드 빼앗기 VFX — ui_sample/vfx/Steal Card VFX.html 재현.
# 적 SPECIAL "remove_card" 발동 시 (harpy / sphinx_cub / sphinx_adult / cursed_scroll).
# play(caster_pos, target_pos) — caster=적(도둑), target=영웅(피해자).
# 영웅 위치 빨간 mark pulse → 카드 글리프 영웅→적 비행 → 적 catch burst + hook sigil + screen_effect.
# ground (뒤): shadow tether (두 위치 잇는 보라 dashed bezier) + 양측 wash
# glow  (앞): 영웅 mark + 비행 카드 + 적 catch burst + hook sigil
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
const COL_SHADOW       := Color(0.486, 0.290, 0.850)         # #7c4ad9
const COL_SHADOW_HOT   := Color(0.784, 0.627, 1.0)           # #c8a0ff
const COL_SHADOW_MID   := Color(0.290, 0.125, 0.564)         # #4a2090
const COL_SHADOW_DEEP  := Color(0.133, 0.062, 0.290)         # #22104a
const COL_BLOOD        := Color(0.850, 0.290, 0.313)         # #d94a50
const COL_BRASS        := Color(0.909, 0.784, 0.470)         # #e8c878

const CHARGE_TIME      := 0.4    # 영웅 mark pulse
const FLIGHT_TIME      := 0.5    # 카드 비행 (영웅→적)
const IMPACT_DELAY     := CHARGE_TIME + FLIGHT_TIME  # = 0.9s
const HOLD_TIME        := 0.4    # hook sigil + catch burst 잔존
const FADE_TIME        := 0.4
const CARD_W           := 38.0
const CARD_H           := 56.0
const MARK_R           := 32.0   # 영웅 위 mark ring 반경
const HOOK_R           := 24.0   # 적 측 hook sigil 반경
const HEAD_Y_OFFSET    := -40.0  # 손 부근 (캐릭터 위쪽 살짝)
const PSPEED           := 60.0

## 화면 플래시 + SFX (peak = catch burst 시점)
signal screen_effect

var _caster := Vector2.ZERO    # 적
var _target := Vector2.ZERO    # 영웅
var _ground_pos := Vector2.ZERO
var _has_ground: bool = false

func set_ground_anchor(pos: Vector2) -> void:
	_ground_pos = pos
	_has_ground = true
	if _ground_layer != null:
		_ground_layer.z_as_relative = false
		_ground_layer.z_index = int(pos.y) - 1

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

func play(caster_pos: Vector2, target_pos: Vector2) -> void:
	_caster = caster_pos
	_target = target_pos
	_age = 0.0
	set_process(true)
	await get_tree().create_timer(IMPACT_DELAY + HOLD_TIME + FADE_TIME + 0.1).timeout
	if is_inside_tree():
		queue_free()

# peak (catch) 시점 — 적 위치 황동 sparks burst
func _spawn_catch_burst() -> void:
	for _i in range(_pcount(20)):
		var a := randf() * TAU
		var sp := 2.0 + randf() * 4.0
		_particles.append({
			"pos": _caster + Vector2(0.0, HEAD_Y_OFFSET),
			"vel": Vector2(cos(a) * sp, sin(a) * sp - 0.5),
			"life": 0.0,
			"max_life": 0.7 + randf() * 0.4,
			"size": 1.2 + randf() * 1.2,
			"kind": "spark",
			"tint": "brass" if randf() < 0.7 else "shadow",
			"grav": 0.015,
		})

func _process(delta: float) -> void:
	_age += delta
	if not _impact_emitted and _age >= IMPACT_DELAY:
		_impact_emitted = true
		_spawn_catch_burst()
		screen_effect.emit()

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

# 영웅 손(머리 위 살짝) 위치
func _target_hand() -> Vector2:
	return _target + Vector2(0.0, HEAD_Y_OFFSET)

# 적 손(머리 위 살짝) 위치
func _caster_hand() -> Vector2:
	return _caster + Vector2(0.0, HEAD_Y_OFFSET)

# 곡선 위 점 — t=0 (target/영웅) ~ 1 (caster/적), 위로 sag
func _flight_point(t: float) -> Vector2:
	var base := _target_hand().lerp(_caster_hand(), t)
	var dist: float = _target_hand().distance_to(_caster_hand())
	var sag: float = -4.0 * t * (1.0 - t) * dist * 0.15  # 위로 호
	return base + Vector2(0.0, sag)

# ── ground (가산, 캐릭터 뒤) — shadow tether (보라 dashed bezier) + 양측 wash ──
func _draw_ground_pass(canvas: CanvasItem) -> void:
	var ga: float = _global_alpha()
	if ga <= 0.0:
		return
	_draw_tether(canvas, ga)
	# 영웅 측 보라 wash (피해 표시)
	_draw_wash(canvas, _target, COL_SHADOW_DEEP, 0.5 * ga)
	# 적 측 보라 wash (peak 후 추가)
	if _impact_emitted:
		var post: float = (_age - IMPACT_DELAY) / 0.4
		var alpha: float = clampf(post, 0.0, 1.0) * ga * 0.4
		if _age > IMPACT_DELAY + HOLD_TIME:
			alpha *= clampf(1.0 - (_age - IMPACT_DELAY - HOLD_TIME) / FADE_TIME, 0.0, 1.0)
		_draw_wash(canvas, _caster, COL_SHADOW_MID, alpha)

func _draw_wash(canvas: CanvasItem, ctr: Vector2, col: Color, alpha: float) -> void:
	if alpha <= 0.0:
		return
	var seg := 28
	var pts := PackedVector2Array()
	for i in range(seg + 1):
		var a: float = TAU * float(i) / float(seg)
		pts.append(ctr + Vector2(cos(a) * 140.0, sin(a) * 100.0))
	canvas.draw_colored_polygon(pts, Color(col, alpha))

# shadow tether — 두 위치 잇는 보라 dashed bezier (위/아래 이중 곡선)
func _draw_tether(canvas: CanvasItem, ga: float) -> void:
	var grow: float = clampf((_age - 0.1) / 0.4, 0.0, 1.0)
	if grow <= 0.0:
		return
	var fade: float = 1.0
	if _age > IMPACT_DELAY + HOLD_TIME:
		fade = clampf(1.0 - (_age - IMPACT_DELAY - HOLD_TIME) / FADE_TIME, 0.0, 1.0)
	if fade <= 0.0:
		return
	var alpha: float = grow * fade * ga * 0.85
	# bezier — caster_hand ~ target_hand
	var ch: Vector2 = _caster_hand()
	var th: Vector2 = _target_hand()
	var mid_x: float = (ch.x + th.x) * 0.5
	var dash_offset: float = fmod(_age * 4.0, 1.0)
	for dir in [-1.0, 1.0]:
		var dir_alpha: float = alpha if dir < 0.0 else alpha * 0.55
		var ctrl: Vector2 = Vector2(mid_x, min(ch.y, th.y) + dir * 60.0)
		var seg := 24
		for i in range(0, seg):
			if int(float(i) + dash_offset * 2.0) % 2 != 0:
				continue
			var t0: float = float(i) / float(seg)
			var t1: float = float(i + 1) / float(seg)
			if t0 > grow:
				continue
			t1 = min(t1, grow)
			var p0 := _bezier(ch, ctrl, th, t0)
			var p1 := _bezier(ch, ctrl, th, t1)
			# 보라 strand
			canvas.draw_line(p0, p1, Color(COL_SHADOW_HOT, dir_alpha), 1.8, true)
	# 빨강 strand (가운데 직선)
	var seg2 := 24
	for i in range(0, seg2):
		if int(float(i) + dash_offset * 3.0) % 3 != 0:
			continue
		var t0: float = float(i) / float(seg2)
		var t1: float = float(i + 1) / float(seg2)
		if t0 > grow:
			continue
		t1 = min(t1, grow)
		var p0 := ch.lerp(th, t0)
		var p1 := ch.lerp(th, t1)
		canvas.draw_line(p0, p1, Color(COL_BLOOD, alpha * 0.7), 1.0, true)

# 2차 베지어
func _bezier(p0: Vector2, p1: Vector2, p2: Vector2, t: float) -> Vector2:
	var u: float = 1.0 - t
	return u * u * p0 + 2.0 * u * t * p1 + t * t * p2

# ── glow (가산, 캐릭터 앞) — 영웅 mark + 비행 카드 + 적 catch + hook + sparks ──
func _draw_glow_pass(canvas: CanvasItem) -> void:
	var ga: float = _global_alpha()
	if ga <= 0.0:
		return
	# Phase 1: 영웅 손 위 mark (빨간 카드 윤곽 + ring pulse)
	_draw_target_mark(canvas, ga)
	# Phase 2: 비행 카드 (CHARGE_TIME ~ IMPACT_DELAY)
	_draw_flying_card(canvas, ga)
	# Phase 3+: 적 catch burst + hook sigil
	if _impact_emitted:
		_draw_catch_burst(canvas, ga)
		_draw_hook_sigil(canvas, ga)
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
		"shadow": return Color(COL_SHADOW_HOT.r, COL_SHADOW_HOT.g, COL_SHADOW_HOT.b, a)
		_:        return Color(COL_BRASS.r, COL_BRASS.g, COL_BRASS.b, a)

# 영웅 손 위 mark — 빨간 카드 윤곽 + pulse ring (CHARGE_TIME 동안)
func _draw_target_mark(canvas: CanvasItem, ga: float) -> void:
	var t: float = _age / CHARGE_TIME
	if t < 0.0:
		return
	# CHARGE 후 빠르게 페이드 (카드가 떠난 듯)
	var alpha: float
	if t < 1.0:
		var pulse: float = 0.7 + sin(_age * (TAU / 0.45)) * 0.25
		alpha = clampf(t / 0.2, 0.0, 1.0) * pulse * ga
	else:
		alpha = clampf(1.0 - (t - 1.0) / 0.5, 0.0, 1.0) * ga * 0.4
	if alpha <= 0.0:
		return
	var ctr: Vector2 = _target_hand()
	# 빨간 ring (pulse)
	canvas.draw_arc(ctr, MARK_R, 0.0, TAU, 32, Color(COL_BLOOD, alpha), 1.8, true)
	canvas.draw_arc(ctr, MARK_R * 0.7, 0.0, TAU, 24, Color(COL_BLOOD, alpha * 0.6), 1.0, true)
	# 빨간 카드 윤곽 (중심)
	var pts := PackedVector2Array([
		ctr + Vector2(-CARD_W * 0.5, -CARD_H * 0.5),
		ctr + Vector2(CARD_W * 0.5, -CARD_H * 0.5),
		ctr + Vector2(CARD_W * 0.5, CARD_H * 0.5),
		ctr + Vector2(-CARD_W * 0.5, CARD_H * 0.5),
		ctr + Vector2(-CARD_W * 0.5, -CARD_H * 0.5),
	])
	canvas.draw_polyline(pts, Color(COL_BLOOD, alpha * 0.95), 1.5, true)

# 비행 카드 — CHARGE_TIME~IMPACT_DELAY 동안 영웅→적 호 그리며 이동
func _draw_flying_card(canvas: CanvasItem, ga: float) -> void:
	var t: float = (_age - CHARGE_TIME) / FLIGHT_TIME
	if t < 0.0 or t > 1.1:
		return
	t = clampf(t, 0.0, 1.0)
	var pos := _flight_point(t)
	# 비행 중 회전·flutter
	var rot: float = sin(_age * (TAU / 0.3)) * 0.18
	var sc: float = lerpf(1.0, 0.85, t)  # 적 쪽으로 갈수록 약간 작아짐 (원근감)
	var alpha: float = ga
	# 페이드아웃 — t=1 직전 빠르게
	if t > 0.85:
		alpha *= clampf(1.0 - (t - 0.85) / 0.15, 0.0, 1.0)
	if alpha <= 0.0:
		return
	# 회전 변환
	var cs := cos(rot)
	var sn := sin(rot)
	var rotate := func(p: Vector2) -> Vector2:
		return Vector2(p.x * cs - p.y * sn, p.x * sn + p.y * cs) * sc
	var w_half: float = CARD_W * 0.5
	var h_half: float = CARD_H * 0.5
	var c0: Vector2 = pos + rotate.call(Vector2(-w_half, -h_half))
	var c1: Vector2 = pos + rotate.call(Vector2(w_half, -h_half))
	var c2: Vector2 = pos + rotate.call(Vector2(w_half, h_half))
	var c3: Vector2 = pos + rotate.call(Vector2(-w_half, h_half))
	# 카드 body (어두운 보라)
	canvas.draw_colored_polygon(PackedVector2Array([c0, c1, c2, c3]), Color(COL_SHADOW_DEEP, alpha * 0.85))
	# 빨간 윤곽 (도난된 카드)
	canvas.draw_polyline(PackedVector2Array([c0, c1, c2, c3, c0]), Color(COL_BLOOD, alpha), 1.5, true)
	# 중심 글리프 — 작은 다이아 (✦ 대용)
	var dsz: float = 6.0 * sc
	canvas.draw_colored_polygon(PackedVector2Array([
		pos + rotate.call(Vector2(0, -dsz)),
		pos + rotate.call(Vector2(dsz, 0)),
		pos + rotate.call(Vector2(0, dsz)),
		pos + rotate.call(Vector2(-dsz, 0)),
	]), Color(COL_HOT, alpha * 0.95))

# 적 catch burst — 황동 ring + 흰 코어
func _draw_catch_burst(canvas: CanvasItem, ga: float) -> void:
	var t: float = (_age - IMPACT_DELAY) / 0.7
	if t < 0.0 or t > 1.0:
		return
	var sc: float = lerpf(0.3, 9.0, t)
	var alpha: float
	if t < 0.15:
		alpha = t / 0.15
	else:
		alpha = 1.0 - (t - 0.15) / 0.85
	alpha *= ga
	if alpha <= 0.0:
		return
	var ctr: Vector2 = _caster_hand()
	var rad: float = 30.0 * sc
	var thick: float = lerpf(3.5, 0.5, t)
	canvas.draw_arc(ctr, rad, 0.0, TAU, 48, Color(COL_BRASS, alpha), thick, true)
	canvas.draw_arc(ctr, rad * 0.85, 0.0, TAU, 36, Color(COL_HOT, alpha * 0.7), thick * 0.5, true)

# 적 손 hook sigil — 보라 ring + 갈고리 곡선 + 빨간 중심점
func _draw_hook_sigil(canvas: CanvasItem, ga: float) -> void:
	var post: float = _age - IMPACT_DELAY
	var pop: float = clampf(post / 0.35, 0.0, 1.0)
	var fade: float = 1.0
	if _age > IMPACT_DELAY + HOLD_TIME:
		fade = clampf(1.0 - (_age - IMPACT_DELAY - HOLD_TIME) / 0.5, 0.0, 1.0)
	if fade <= 0.0:
		return
	var sc: float = lerpf(0.4, 1.0, pop)
	var alpha: float = pop * fade * ga
	var ctr: Vector2 = _caster_hand()
	var r: float = HOOK_R * sc
	# 외곽 ring
	canvas.draw_arc(ctr, r, 0.0, TAU, 32, Color(COL_SHADOW_HOT, alpha * 0.9), 1.5, true)
	# 점선 안쪽 원
	for i in range(8):
		var a0: float = TAU * float(i) / 8.0
		var a1: float = a0 + TAU / 16.0
		canvas.draw_arc(ctr, r * 0.75, a0, a1, 3, Color(COL_SHADOW, alpha * 0.7), 1.0, true)
	# 갈고리 곡선 — 호 그리는 path (작은 원호 + 짧은 직선)
	var hook_pts := PackedVector2Array()
	var hook_seg := 12
	for i in range(hook_seg + 1):
		var t: float = float(i) / float(hook_seg)
		var a: float = -PI * 0.5 + t * PI * 1.4  # 위에서 시작해서 우하단으로
		hook_pts.append(ctr + Vector2(cos(a) * r * 0.55, sin(a) * r * 0.55))
	canvas.draw_polyline(hook_pts, Color(COL_HOT, alpha), 1.8, true)
	# 갈고리 꼬리
	var tail_start: Vector2 = ctr + Vector2(cos(0.9 * PI) * r * 0.55, sin(0.9 * PI) * r * 0.55)
	var tail_end: Vector2 = ctr + Vector2(r * 0.35, r * 0.6)
	canvas.draw_line(tail_start, tail_end, Color(COL_HOT, alpha), 1.8, true)
	# 빨간 중심점
	canvas.draw_circle(ctr, 2.5, Color(COL_BLOOD, alpha))

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
