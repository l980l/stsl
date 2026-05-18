# scenes/vfx/mimic.gd
# 메아리 반사 VFX — ui_sample/vfx/Mimic VFX.html 재현 (MIMIC intent, yamabiko).
# play(caster_pos, target_pos) — caster=적(시전자), target=영웅(반사 원본).
# 영웅 위치에서 source pulse → 두 위치 잇는 시안 dashed arc → 적 위치 ripple 3개 + brass burst → peak.
# ground (둘 다 뒤): mirror arc 점선 path + 발치 dust
# glow  (둘 다 앞): ripple, source pulse, brass burst, sparks
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
const COL_ECHO       := Color(0.360, 0.862, 1.0)          # #5cdcff 시안 메아리
const COL_ECHO_HOT   := Color(0.682, 0.941, 1.0)          # #aef0ff 밝은 시안
const COL_ECHO_DEEP  := Color(0.101, 0.290, 0.419)        # #1a4a6b
const COL_BRASS      := Color(0.909, 0.784, 0.470)        # #e8c878 황동
const COL_BRASS_DEEP := Color(0.721, 0.564, 0.164)        # #b8902a

const CHANNEL_TIME := 0.3     # source pulse + ripple 1
const ARC_RAMP     := 0.4     # mirror arc 등장
const PEAK_DELAY   := 0.7     # brass burst + IMPACT_DELAY
const IMPACT_DELAY := PEAK_DELAY
const HOLD_TIME    := 0.5     # arc 잔존
const FADE_TIME    := 0.4
const RIPPLE_TIME  := 0.85    # 1 ripple 의 확장 시간
const SOURCE_R     := 60.0    # 영웅 측 pulse 반경
const PSPEED       := 60.0

## 화면 플래시 + SFX 트리거 (peak = brass burst 시점)
signal screen_effect

var _caster := Vector2.ZERO    # 적
var _target := Vector2.ZERO    # 영웅 (반사 원본)
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
	await get_tree().create_timer(PEAK_DELAY + HOLD_TIME + FADE_TIME + 0.1).timeout
	if is_inside_tree():
		queue_free()

# peak 시 — 적 위치 brass burst sparks + 영웅 측 echo motes
func _spawn_peak_burst() -> void:
	# 적 위치 황동 burst
	for _i in range(_pcount(28)):
		var a := randf() * TAU
		var sp := 2.0 + randf() * 4.0
		_particles.append({
			"pos": _caster,
			"vel": Vector2(cos(a) * sp, sin(a) * sp - 0.5),
			"life": 0.0,
			"max_life": 0.8 + randf() * 0.5,
			"size": 1.4 + randf() * 1.4,
			"kind": "spark",
			"tint": "brass" if randf() < 0.6 else "echo",
			"grav": 0.015,
		})
	# 영웅 측 echo motes (mirror echo)
	for _i in range(_pcount(14)):
		var a2 := randf() * TAU
		var sp2 := 1.5 + randf() * 2.5
		_particles.append({
			"pos": _target,
			"vel": Vector2(cos(a2) * sp2, sin(a2) * sp2 * 0.7 - 0.3),
			"life": 0.0,
			"max_life": 0.7 + randf() * 0.4,
			"size": 1.2 + randf() * 1.2,
			"kind": "spark",
			"tint": "echo",
		})

# hold 동안 — arc 점선 따라 흐르는 작은 시안 motes
func _spawn_arc_motes() -> void:
	if randf() < 0.5 * _scale():
		var t: float = randf()
		var arc_pt := _arc_point(t, sin(_age * TAU) * 0.5 + 0.5)
		_particles.append({
			"pos": arc_pt,
			"vel": Vector2(randf_range(-0.4, 0.4), randf_range(-0.3, 0.3)),
			"life": 0.0,
			"max_life": 0.5 + randf() * 0.4,
			"size": 1.0 + randf() * 0.8,
			"kind": "spark",
			"tint": "echo",
		})

# arc 곡선 위 점 — t = 0 (caster) ~ 1 (target). curve_dir: -1=위로, +1=아래로 (이중 곡선)
func _arc_point(t: float, curve_dir: float) -> Vector2:
	var base := _caster.lerp(_target, t)
	var dist: float = _caster.distance_to(_target)
	# 포물선 — t=0.5 에서 최대 변위
	var sag: float = 4.0 * t * (1.0 - t) * dist * 0.18 * curve_dir
	return base + Vector2(0.0, -sag)

func _process(delta: float) -> void:
	_age += delta
	# peak (1회 burst + screen_effect)
	if not _impact_emitted and _age >= PEAK_DELAY:
		_impact_emitted = true
		_spawn_peak_burst()
		screen_effect.emit()
	# arc motes (hold 동안)
	if _impact_emitted and _age < PEAK_DELAY + HOLD_TIME:
		_spawn_arc_motes()

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
	if _age < PEAK_DELAY + HOLD_TIME:
		return clampf(_age / 0.15, 0.0, 1.0)
	var t: float = (_age - (PEAK_DELAY + HOLD_TIME)) / FADE_TIME
	return clampf(1.0 - t, 0.0, 1.0)

# ── ground (가산, 캐릭터 뒤) — mirror arc 점선 path (이중 곡선) ──
func _draw_ground_pass(canvas: CanvasItem) -> void:
	var ga: float = _global_alpha()
	if ga <= 0.0:
		return
	_draw_mirror_arc(canvas, ga)

# 두 캐릭터를 잇는 시안 dashed arc — 위·아래 이중 곡선
func _draw_mirror_arc(canvas: CanvasItem, ga: float) -> void:
	var grow: float = clampf((_age - CHANNEL_TIME) / ARC_RAMP, 0.0, 1.0)
	if grow <= 0.0:
		return
	var fade: float = 1.0
	if _age > PEAK_DELAY + HOLD_TIME:
		fade = clampf(1.0 - (_age - PEAK_DELAY - HOLD_TIME) / FADE_TIME, 0.0, 1.0)
	if fade <= 0.0:
		return
	var alpha: float = grow * fade * ga * 0.9
	# 두 곡선 (위·아래) — dashed (12 세그먼트로 분할)
	for dir in [-1.0, 1.0]:
		var dir_alpha: float = alpha if dir < 0.0 else alpha * 0.55
		var seg := 24
		var dash_offset: float = fmod(_age * 3.0, 1.0)
		for i in range(0, seg):
			# 짝수 i 만 그림 (dashed)
			if int(float(i) + dash_offset * 2.0) % 2 != 0:
				continue
			var t0: float = float(i) / float(seg)
			var t1: float = float(i + 1) / float(seg)
			# arc grow 에 맞춰 끝점 제한
			if t0 > grow:
				continue
			t1 = min(t1, grow)
			var p0 := _arc_point(t0, dir)
			var p1 := _arc_point(t1, dir)
			canvas.draw_line(p0, p1, Color(COL_ECHO_HOT, dir_alpha), 1.5, true)

# ── glow (가산, 캐릭터 앞) — source pulse + ripple + brass burst + sparks ──
func _draw_glow_pass(canvas: CanvasItem) -> void:
	var ga: float = _global_alpha()
	if ga <= 0.0:
		return
	# source pulse — 영웅 위치 (CHANNEL_TIME 동안 짧게 빛남)
	_draw_source_pulse(canvas, ga)
	# 적 위치 ripple — 3 스태거
	_draw_ripple(canvas, 0.0, ga)
	_draw_ripple(canvas, 0.15, ga)
	_draw_ripple(canvas, 0.30, ga)
	# brass burst (peak)
	if _impact_emitted:
		_draw_brass_burst(canvas, ga)
	# sparks (peak + arc motes)
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
		"brass": return Color(COL_BRASS.r, COL_BRASS.g, COL_BRASS.b, a)
		_:        return Color(COL_ECHO_HOT.r, COL_ECHO_HOT.g, COL_ECHO_HOT.b, a)

# 영웅 위치 source pulse — 시안 글로우 동심원
func _draw_source_pulse(canvas: CanvasItem, ga: float) -> void:
	var t: float = _age / 0.55
	if t < 0.0 or t > 1.0:
		return
	# 0~1 의 펄스 — alpha 0→1→0
	var alpha: float
	if t < 0.4:
		alpha = t / 0.4
	else:
		alpha = 1.0 - (t - 0.4) / 0.6
	alpha *= ga
	if alpha <= 0.0:
		return
	# 외층 (옅은 시안)
	canvas.draw_circle(_target, SOURCE_R, Color(COL_ECHO_DEEP, alpha * 0.4))
	# 코어 (밝은 시안)
	canvas.draw_circle(_target, SOURCE_R * 0.6, Color(COL_ECHO, alpha * 0.55))
	# 외곽 ring (확장)
	var ring_r: float = SOURCE_R * (0.6 + t * 0.8)
	canvas.draw_arc(_target, ring_r, 0.0, TAU, 32, Color(COL_ECHO_HOT, alpha), 1.5, true)

# 적 위치 ripple — 동심원 확장 (delay = 시작 시점)
func _draw_ripple(canvas: CanvasItem, delay: float, ga: float) -> void:
	var t: float = (_age - CHANNEL_TIME - delay) / RIPPLE_TIME
	if t < 0.0 or t > 1.0:
		return
	var alpha: float
	if t < 0.1:
		alpha = t / 0.1
	else:
		alpha = 1.0 - (t - 0.1) / 0.9
	alpha *= ga
	if alpha <= 0.0:
		return
	var sc: float = lerpf(0.2, 14.0, t)
	var rad: float = 20.0 * sc
	var thick: float = lerpf(2.5, 0.5, t)
	canvas.draw_arc(_caster, rad, 0.0, TAU, 48, Color(COL_ECHO_HOT, alpha), thick, true)

# peak 시 황동 burst — 적 위치
func _draw_brass_burst(canvas: CanvasItem, ga: float) -> void:
	var t: float = (_age - PEAK_DELAY) / 0.6
	if t < 0.0 or t > 1.0:
		return
	var sc: float = lerpf(0.3, 10.0, t)
	var alpha: float
	if t < 0.15:
		alpha = t / 0.15
	else:
		alpha = 1.0 - (t - 0.15) / 0.85
	alpha *= ga
	if alpha <= 0.0:
		return
	var rad: float = 30.0 * sc
	var thick: float = lerpf(3.5, 0.5, t)
	canvas.draw_arc(_caster, rad, 0.0, TAU, 48, Color(COL_BRASS, alpha), thick, true)
	canvas.draw_arc(_caster, rad * 0.85, 0.0, TAU, 36, Color(COL_HOT, alpha * 0.7), thick * 0.5, true)

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
