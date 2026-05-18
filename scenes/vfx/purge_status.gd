# scenes/vfx/purge_status.gd
# 디버프 정화 VFX — ui_sample/vfx/Purge Status VFX.html 재현 (PURGE_STATUS EffectType).
# play(_caster, target_pos) — caster 무시, target = 자기 위치.
# ground (캐릭터 뒤): 발치 회전 ring + 황금 빛기둥 pillar + brass wash
# glow  (캐릭터 앞): 가슴 정화 core → 3겹 확장 wave + 머리 위 halo
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
const COL_BONE      := Color(0.964, 0.945, 0.901)        # #f6f1e6
const COL_TEAL      := Color(0.380, 0.901, 0.823)        # #61e6d2 시원한 청록 (정화 코어)
const COL_TEAL_MID  := Color(0.117, 0.564, 0.501)        # #1e9080 진한 청록
const COL_PURE      := Color(0.682, 0.941, 1.0)          # #aef0ff 정화 시안 (wave 보조)

const CHARGE_TIME    := 0.3     # core 등장
const IMPACT_DELAY   := 0.4     # wave 발산 시점 (peak)
const HOLD_TIME      := 0.55    # halo + pillar 잔존
const FADE_TIME      := 0.4
const RING_RADIUS    := 130.0   # 발치 ring
const RING_SQUASH    := 0.32
const PILLAR_W       := 150.0
const PILLAR_H       := 220.0
const CORE_R         := 36.0    # 가슴 core 반경
const CORE_Y_OFFSET  := -50.0   # 캐릭터 가슴 위치
const HALO_W         := 110.0   # 머리 위 halo 가로
const HALO_H         := 28.0
const HALO_Y_OFFSET  := -100.0
const PSPEED         := 60.0

## 화면 플래시 + SFX (peak = wave 발산 시점)
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

# peak 시 — 가슴 위치 황금 sparks (외곽 확산)
func _spawn_peak_burst() -> void:
	var ctr: Vector2 = _target + Vector2(0.0, CORE_Y_OFFSET)
	for _i in range(_pcount(24)):
		var a := randf() * TAU
		var sp := 2.0 + randf() * 4.0
		_particles.append({
			"pos": ctr,
			"vel": Vector2(cos(a) * sp, sin(a) * sp - 0.3),
			"life": 0.0,
			"max_life": 0.8 + randf() * 0.4,
			"size": 1.4 + randf() * 1.4,
			"kind": "spark",
			"tint": "brass" if randf() < 0.7 else "pure",
			"grav": 0.01,
		})

# hold 동안 — 발치 위로 솟구치는 부드러운 ember (정화의 잔류)
func _spawn_hold_ember() -> void:
	var foot: Vector2 = _foot_pos()
	if randf() < 0.4 * _scale():
		_particles.append({
			"pos": Vector2(foot.x + randf_range(-70.0, 70.0), foot.y - randf() * 30.0),
			"vel": Vector2(randf_range(-0.2, 0.2), -0.5 - randf() * 0.4),
			"life": 0.0,
			"max_life": 1.1 + randf() * 0.5,
			"size": 1.0 + randf() * 1.0,
			"kind": "spark",
			"tint": "bone",
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

# ── ground (가산, 캐릭터 뒤) — 발치 회전 ring + 황금 pillar + brass wash ──
func _draw_ground_pass(canvas: CanvasItem) -> void:
	var ga: float = _global_alpha()
	if ga <= 0.0:
		return
	_draw_ring(canvas, ga)
	_draw_pillar(canvas, ga)
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
				pts.append(_target + Vector2(cos(a) * 160.0, sin(a) * 120.0))
			canvas.draw_colored_polygon(pts, Color(COL_TEAL_MID, wash_alpha))

# 발치 회전 ring — 외곽 원 + 점선 안쪽 원 + 4 방향 마커 (정화 sigil)
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
	canvas.draw_polyline(pts, Color(COL_BONE, alpha), 2.0, true)
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
		canvas.draw_polyline(arc, Color(COL_TEAL, alpha * 0.7), 1.0, true)
	# 4 방향 다이아 마커 (회전)
	var rot: float = _age * 0.4
	for i in range(4):
		var ang: float = rot + TAU * float(i) / 4.0
		var mp := foot + Vector2(cos(ang) * r * 1.02, sin(ang) * r * 1.02 * RING_SQUASH)
		var sz: float = 5.0
		canvas.draw_colored_polygon(PackedVector2Array([
			mp + Vector2(0, -sz), mp + Vector2(sz, 0),
			mp + Vector2(0, sz), mp + Vector2(-sz, 0),
		]), Color(COL_BONE, alpha * 0.95))

# 발치에서 솟는 황금 빛기둥 (pillar) — pulse
func _draw_pillar(canvas: CanvasItem, ga: float) -> void:
	var rise: float = clampf((_age - 0.15) / 0.45, 0.0, 1.0)
	if rise <= 0.0:
		return
	var fade: float = 1.0
	if _age > IMPACT_DELAY + HOLD_TIME:
		fade = clampf(1.0 - (_age - IMPACT_DELAY - HOLD_TIME) / FADE_TIME, 0.0, 1.0)
	var pulse: float = 0.75 + sin(_age * (TAU / 1.6)) * 0.15
	var alpha: float = rise * fade * ga * pulse
	if alpha <= 0.0:
		return
	var foot: Vector2 = _foot_pos()
	var h: float = PILLAR_H * rise
	var w: float = PILLAR_W
	var bottom_y: float = foot.y
	var top_y: float = foot.y - h
	# 외층 (옅은 황동)
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(foot.x - w * 0.45, bottom_y),
		Vector2(foot.x + w * 0.45, bottom_y),
		Vector2(foot.x + w * 0.18, top_y),
		Vector2(foot.x - w * 0.18, top_y),
	]), Color(COL_TEAL, alpha * 0.45))
	# 코어 (밝은 흰)
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(foot.x - w * 0.22, bottom_y),
		Vector2(foot.x + w * 0.22, bottom_y),
		Vector2(foot.x + w * 0.06, top_y),
		Vector2(foot.x - w * 0.06, top_y),
	]), Color(COL_BONE, alpha * 0.6))

# ── glow (가산, 캐릭터 앞) — core + wave + halo + sparks ──
func _draw_glow_pass(canvas: CanvasItem) -> void:
	var ga: float = _global_alpha()
	if ga <= 0.0:
		return
	# 가슴 정화 core (CHARGE 부터 등장, peak 후 fade)
	_draw_core(canvas, ga)
	# 3겹 wave (peak 시 발산, stagger)
	if _impact_emitted:
		_draw_wave(canvas, 0.0, ga, COL_BONE)
		_draw_wave(canvas, 0.08, ga, COL_TEAL)
		_draw_wave(canvas, 0.16, ga, COL_PURE)
	# 머리 위 halo
	if _impact_emitted:
		_draw_halo(canvas, ga)
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
		"brass": return Color(COL_TEAL.r, COL_TEAL.g, COL_TEAL.b, a)
		"pure":  return Color(COL_PURE.r, COL_PURE.g, COL_PURE.b, a)
		_:        return Color(COL_BONE.r, COL_BONE.g, COL_BONE.b, a)

# 가슴 정화 core — 흰/황금 동심원, CHARGE 동안 등장
func _draw_core(canvas: CanvasItem, ga: float) -> void:
	var t: float = _age / CHARGE_TIME
	if t < 0.0:
		return
	var grow: float = clampf(t * 1.5, 0.0, 1.0)  # 빠르게 등장
	var fade: float = 1.0
	if _impact_emitted:
		var post: float = (_age - IMPACT_DELAY) / 0.5
		fade = clampf(1.0 - post, 0.0, 1.0)
	if fade <= 0.0:
		return
	var alpha: float = grow * fade * ga
	var ctr: Vector2 = _target + Vector2(0.0, CORE_Y_OFFSET)
	var r: float = CORE_R * grow
	# 외층 (황금)
	canvas.draw_circle(ctr, r, Color(COL_TEAL, alpha * 0.55))
	# 코어 (흰)
	canvas.draw_circle(ctr, r * 0.55, Color(COL_HOT, alpha * 0.9))

# 확장 wave — delay 별 stagger, peak 부터 1.0s 동안 확장
func _draw_wave(canvas: CanvasItem, delay: float, ga: float, base_col: Color) -> void:
	var t: float = (_age - IMPACT_DELAY - delay) / 1.0
	if t < 0.0 or t > 1.0:
		return
	var sc: float = lerpf(0.2, 10.0, t)
	var alpha: float
	if t < 0.1:
		alpha = t / 0.1
	else:
		alpha = 1.0 - (t - 0.1) / 0.9
	alpha *= ga
	if alpha <= 0.0:
		return
	var ctr: Vector2 = _target + Vector2(0.0, CORE_Y_OFFSET)
	var rad: float = 40.0 * sc
	var thick: float = lerpf(2.5, 0.5, t)
	canvas.draw_arc(ctr, rad, 0.0, TAU, 48, Color(base_col, alpha), thick, true)

# 머리 위 halo — 황금 ellipse (정화의 축복), floating
func _draw_halo(canvas: CanvasItem, ga: float) -> void:
	var post: float = _age - IMPACT_DELAY
	var pop: float = clampf(post / 0.55, 0.0, 1.0)
	var fade: float = 1.0
	if _age > IMPACT_DELAY + HOLD_TIME:
		fade = clampf(1.0 - (_age - IMPACT_DELAY - HOLD_TIME) / 0.55, 0.0, 1.0)
	if fade <= 0.0:
		return
	var sc: float = lerpf(0.5, 1.0, pop)
	var float_y: float = sin(post * (TAU / 2.4)) * 3.0
	var alpha: float = pop * fade * ga
	var ctr: Vector2 = _target + Vector2(0.0, HALO_Y_OFFSET + float_y)
	# 외층 황동
	var seg := 32
	var pts := PackedVector2Array()
	var w: float = HALO_W * 0.5 * sc
	var h: float = HALO_H * 0.5 * sc
	for i in range(seg + 1):
		var a: float = TAU * float(i) / float(seg)
		pts.append(ctr + Vector2(cos(a) * w, sin(a) * h))
	canvas.draw_colored_polygon(pts, Color(COL_TEAL, alpha * 0.6))
	# 코어 흰
	var pts2 := PackedVector2Array()
	for i in range(seg + 1):
		var a: float = TAU * float(i) / float(seg)
		pts2.append(ctr + Vector2(cos(a) * w * 0.55, sin(a) * h * 0.55))
	canvas.draw_colored_polygon(pts2, Color(COL_HOT, alpha * 0.5))

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
