# scenes/vfx/boss_phase_changed.gd
# 보스 페이즈 전환 VFX — ui_sample/vfx/Boss Phase Changed VFX.html 재현.
# play(_caster, target_pos) — caster 무시, target = 보스 위치.
# ground (보스 뒤): 큰 발치 ring (회전) + 보스 둘레 aura + holdTint wash
# glow  (보스 앞): build-up rumble + peak core erupt + 4겹 shockwave + 전체 flash
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
const COL_RIM       := Color(1.0, 0.541, 0.164)         # #ff8a2a 주황
const COL_RIM_HOT   := Color(1.0, 0.843, 0.415)         # #ffd76a 황금
const COL_BLOOD     := Color(0.850, 0.290, 0.313)       # #d94a50
const COL_BLOOD_DEEP := Color(0.290, 0.050, 0.062)      # #4a0d10
const COL_BRASS     := Color(0.909, 0.784, 0.470)       # #e8c878

const BUILD_TIME    := 0.5     # rumble + aura 강화 (긴장감 빌드업)
const PEAK_DELAY    := 0.65    # core erupt + screen_effect
const IMPACT_DELAY  := PEAK_DELAY
const HOLD_TIME     := 1.4     # shockwave 확장 + holdTint 잔존 + title 표시
const FADE_TIME     := 0.7
const RING_RADIUS   := 240.0   # 보스 발치 큰 ring (더 큰)
const RING_SQUASH   := 0.32
const AURA_R        := 280.0   # 보스 둘레 aura (더 큰)
const CORE_R        := 42.0    # white-hot core 시작 반경
const PSPEED        := 60.0

## 화면 플래시 + screen shake + SFX (peak = core erupt 시점)
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

# build 단계 — 외곽에서 보스 위치로 빠르게 수렴하는 motes (에너지 흡수)
func _spawn_inflow(intensity: int) -> void:
	var ctr: Vector2 = _target + Vector2(0.0, -40.0)
	for _i in range(intensity):
		var ang := randf() * TAU
		var dist := 300.0 + randf() * 220.0
		var sx := ctr.x + cos(ang) * dist
		var sy := ctr.y + sin(ang) * dist * 0.7
		# 초기 속도 — 5~10 (이전 2.5~5.5 대비 2배)
		var sp := 6.0 + randf() * 5.0
		var dx := ctr.x - sx
		var dy := ctr.y - sy
		var d_len: float = max(1.0, sqrt(dx * dx + dy * dy))
		var tint_r := randf()
		var tint: String = "blood" if tint_r < 0.3 else ("hot" if tint_r < 0.5 else "rim")
		_particles.append({
			"pos": Vector2(sx, sy),
			"vel": Vector2(dx / d_len * sp, dy / d_len * sp),
			"life": 0.0,
			# max_life 짧게 — 0.35~0.6s (이전 0.7~1.1 대비 절반)
			"max_life": 0.35 + randf() * 0.25,
			"size": 1.4 + randf() * 1.4,
			"kind": "inflow",
			"tint": tint,
			"target_x": ctr.x,
			"target_y": ctr.y,
		})

# peak (core erupt) — 외곽 큰 sparks + 발치 dust 폭발
func _spawn_peak_burst() -> void:
	var ctr: Vector2 = _target + Vector2(0.0, -40.0)
	# 외곽 sparks (큰 폭발) — 90개로 증량
	for _i in range(_pcount(90)):
		var a := randf() * TAU
		var sp := 4.0 + randf() * 10.0
		_particles.append({
			"pos": ctr,
			"vel": Vector2(cos(a) * sp, sin(a) * sp - 1.2),
			"life": 0.0,
			"max_life": 1.2 + randf() * 0.8,
			"size": 1.6 + randf() * 2.0,
			"kind": "spark",
			"tint": "rim" if randf() < 0.4 else ("hot" if randf() < 0.4 else "blood"),
			"grav": 0.02,
		})
	# 작은 ember 추가 (오래 떠다님)
	for _i in range(_pcount(40)):
		var a3 := randf() * TAU
		var sp3 := 1.5 + randf() * 4.0
		_particles.append({
			"pos": ctr,
			"vel": Vector2(cos(a3) * sp3, sin(a3) * sp3 - 0.8),
			"life": 0.0,
			"max_life": 1.6 + randf() * 0.8,
			"size": 1.0 + randf() * 1.0,
			"kind": "spark",
			"tint": "rim",
			"grav": 0.005,
		})
	# 발치 dust (큰 흙먼지)
	var foot: Vector2 = _foot_pos()
	for _i in range(_pcount(32)):
		var a2 := randf() * TAU
		var sp2 := 2.5 + randf() * 4.5
		_particles.append({
			"pos": foot,
			"vel": Vector2(cos(a2) * sp2, sin(a2) * sp2 * 0.2 - 0.5 - randf() * 0.6),
			"life": 0.0,
			"max_life": 1.2 + randf() * 0.6,
			"size": 16.0 + randf() * 14.0,
			"kind": "dust",
			"grav": -0.005,
		})

# hold 동안 — ember 잔존 (분노 잔불)
func _spawn_hold_ember() -> void:
	var foot: Vector2 = _foot_pos()
	if randf() < 0.55 * _scale():
		_particles.append({
			"pos": Vector2(foot.x + randf_range(-130.0, 130.0), foot.y - randf() * 40.0),
			"vel": Vector2(randf_range(-0.3, 0.3), -0.7 - randf() * 0.6),
			"life": 0.0,
			"max_life": 1.2 + randf() * 0.6,
			"size": 1.2 + randf() * 1.3,
			"kind": "spark",
			"tint": "rim",
		})

func _process(delta: float) -> void:
	_age += delta
	# build 단계 — 매 프레임 inflow (외곽 → 보스 수렴) — intensity 점진 증가
	if _age < PEAK_DELAY:
		var t: float = _age / PEAK_DELAY
		var intensity: int = _pcount(int(3 + t * 5))
		_spawn_inflow(intensity)
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
		# inflow homing — 보스 위치로 강한 가속 (가까워질수록 더 빠름)
		if p["kind"] == "inflow":
			var dx: float = p["target_x"] - p["pos"].x
			var dy: float = p["target_y"] - p["pos"].y
			var d: float = max(1.0, sqrt(dx * dx + dy * dy))
			if d < 18.0:
				continue  # 도착 — 소멸 (임계 거리 증가)
			# 강화된 가속: 베이스 0.4 + 거리 비례 0.7 (이전 0.1 + 0.22 대비 3배 이상)
			var accel: float = 0.4 + (1.0 - min(1.0, d / 300.0)) * 0.7
			p["vel"].x += dx / d * accel * delta * PSPEED
			p["vel"].y += dy / d * accel * delta * PSPEED
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

# ── ground (가산, 보스 뒤) — 큰 발치 ring + 보스 둘레 aura + holdTint + dust ──
func _draw_ground_pass(canvas: CanvasItem) -> void:
	var ga: float = _global_alpha()
	if ga <= 0.0:
		return
	_draw_aura(canvas, ga)
	_draw_ring(canvas, ga)
	# holdTint — peak 후 어두운 wash (불타는 분위기)
	if _impact_emitted:
		var t: float = (_age - IMPACT_DELAY) / 0.4
		var alpha: float = clampf(t, 0.0, 1.0) * 0.5 * ga
		if _age > IMPACT_DELAY + HOLD_TIME:
			alpha *= clampf(1.0 - (_age - IMPACT_DELAY - HOLD_TIME) / FADE_TIME, 0.0, 1.0)
		if alpha > 0.0:
			var seg := 36
			var pts := PackedVector2Array()
			for i in range(seg + 1):
				var a: float = TAU * float(i) / float(seg)
				pts.append(_target + Vector2(cos(a) * 280.0, sin(a) * 200.0))
			canvas.draw_colored_polygon(pts, Color(COL_BLOOD_DEEP, alpha))
	# 바닥 dust
	for p in _particles:
		if p["kind"] != "dust":
			continue
		var k: float = p["life"] / p["max_life"]
		var a: float = (1.0 - k) * 0.4 * ga
		var r: float = p["size"] * (1.0 + k * 1.3)
		canvas.draw_circle(p["pos"], r, Color(COL_BLOOD_DEEP, a))

# 보스 둘레 큰 aura — 주황·빨강 그라데이션, peak 후 확장
func _draw_aura(canvas: CanvasItem, ga: float) -> void:
	var grow: float = clampf(_age / 0.5, 0.0, 1.0)
	if grow <= 0.0:
		return
	var fade: float = 1.0
	if _age > IMPACT_DELAY + HOLD_TIME:
		fade = clampf(1.0 - (_age - IMPACT_DELAY - HOLD_TIME) / FADE_TIME, 0.0, 1.0)
	if fade <= 0.0:
		return
	# peak 후 1.18 배로 확장
	var expand: float = 1.0
	if _impact_emitted:
		expand = lerpf(1.0, 1.18, clampf((_age - IMPACT_DELAY) / 0.4, 0.0, 1.0))
	# pulse
	var pulse: float = 0.85 + sin(_age * (TAU / 1.5)) * 0.12
	var alpha: float = grow * fade * ga * pulse * 0.45
	var ctr: Vector2 = _target + Vector2(0.0, -30.0)
	var r: float = AURA_R * grow * expand
	# 외층 (어두운 주황)
	canvas.draw_circle(ctr, r, Color(COL_RIM, alpha * 0.3))
	# 중층 (밝은 주황)
	canvas.draw_circle(ctr, r * 0.65, Color(COL_RIM, alpha * 0.55))
	# 코어 (옅은 빨강)
	canvas.draw_circle(ctr, r * 0.35, Color(COL_BLOOD, alpha * 0.4))

# 발치 큰 회전 ring — 외원 + 점선 + 6 방향 마커
func _draw_ring(canvas: CanvasItem, ga: float) -> void:
	var grow: float = clampf((_age - 0.2) / 0.6, 0.0, 1.0)
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
	# 외곽 원 (주황)
	var seg := 56
	var pts := PackedVector2Array()
	for i in range(seg + 1):
		var a: float = TAU * float(i) / float(seg)
		pts.append(foot + Vector2(cos(a) * r, sin(a) * r * RING_SQUASH))
	canvas.draw_polyline(pts, Color(COL_RIM, alpha), 2.5, true)
	# 안쪽 점선 (빨강)
	for i in range(20):
		var a0: float = TAU * float(i) / 20.0
		var a1: float = a0 + TAU / 40.0
		var dr: float = r * 0.82
		var arc := PackedVector2Array()
		for k in range(4):
			var t: float = float(k) / 3.0
			var ang: float = lerpf(a0, a1, t)
			arc.append(foot + Vector2(cos(ang) * dr, sin(ang) * dr * RING_SQUASH))
		canvas.draw_polyline(arc, Color(COL_BLOOD, alpha * 0.65), 1.2, true)
	# 6 방향 마커 (회전, 황금 다이아)
	var rot: float = _age * 0.35
	for i in range(6):
		var ang: float = rot + TAU * float(i) / 6.0
		var mp := foot + Vector2(cos(ang) * r * 1.02, sin(ang) * r * 1.02 * RING_SQUASH)
		var sz: float = 6.0
		canvas.draw_colored_polygon(PackedVector2Array([
			mp + Vector2(0, -sz), mp + Vector2(sz, 0),
			mp + Vector2(0, sz), mp + Vector2(-sz, 0),
		]), Color(COL_RIM_HOT, alpha * 0.95))

# ── glow (가산, 보스 앞) — core erupt + 4겹 shockwave + 외곽 sparks ──
func _draw_glow_pass(canvas: CanvasItem) -> void:
	var ga: float = _global_alpha()
	if ga <= 0.0:
		return
	# build-up — 보스 가슴 위치 작은 charging glow (BUILD_TIME 동안 강해짐)
	_draw_build_glow(canvas, ga)
	if _impact_emitted:
		# core erupt — white-hot 중심 폭발
		_draw_core(canvas, ga)
		# 6겹 shockwave (stagger) — 흰·황금·주황·빨강 강화
		_draw_shockwave(canvas, 0.0, ga, COL_HOT)
		_draw_shockwave(canvas, 0.06, ga, COL_RIM_HOT)
		_draw_shockwave(canvas, 0.12, ga, COL_RIM)
		_draw_shockwave(canvas, 0.18, ga, COL_BLOOD)
		_draw_shockwave(canvas, 0.24, ga, COL_RIM)
		_draw_shockwave(canvas, 0.32, ga, COL_BRASS)
		# 머리 위 사망의 후광 — 빛이 위로 솟구치는 vertical streak
		_draw_vertical_streaks(canvas, ga)
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
		canvas.draw_rect(Rect2(p["pos"].x - pr * 2.5, p["pos"].y - 0.3, pr * 5.0, 0.6), col)
	# inflow (보스로 수렴하는 motes) — 방향 motion streak
	for p in _particles:
		if p["kind"] != "inflow":
			continue
		var k: float = p["life"] / p["max_life"]
		var a: float = (1.0 - k) * ga
		var col := _spark_color(p["tint"], a)
		var pr: float = p["size"]
		canvas.draw_circle(p["pos"], pr * 1.6, Color(col.r, col.g, col.b, col.a * 0.45))
		canvas.draw_circle(p["pos"], pr, col)
		# 모션 streak (이동 방향 후미 꼬리)
		var sp: float = p["vel"].length()
		if sp > 1.5:
			var ang: float = p["vel"].angle()
			var stl: float = min(sp * 1.8, 22.0)
			var dir := Vector2(cos(ang), sin(ang)) * stl
			canvas.draw_line(p["pos"] - dir, p["pos"], col, 1.0, true)

func _spark_color(tint: String, a: float) -> Color:
	match tint:
		"hot":   return Color(COL_HOT.r, COL_HOT.g, COL_HOT.b, a)
		"blood": return Color(COL_BLOOD.r, COL_BLOOD.g, COL_BLOOD.b, a)
		_:        return Color(COL_RIM_HOT.r, COL_RIM_HOT.g, COL_RIM_HOT.b, a)

# build-up — 보스 가슴 위치 작은 charging glow (BUILD_TIME 동안 강해짐, peak 직후 소멸)
func _draw_build_glow(canvas: CanvasItem, ga: float) -> void:
	if _impact_emitted:
		return
	var t: float = _age / BUILD_TIME
	var grow: float = clampf(t, 0.0, 1.0)
	# 빠르게 강해짐 (exponential ramp)
	var alpha: float = pow(grow, 1.5) * ga
	if alpha <= 0.0:
		return
	var ctr: Vector2 = _target + Vector2(0.0, -50.0)
	# pulse (build 후반에 빨라짐)
	var pulse_speed: float = lerpf(1.5, 4.0, grow)
	var pulse: float = 1.0 + sin(_age * (TAU * pulse_speed)) * 0.18
	var r: float = 20.0 * grow * pulse
	canvas.draw_circle(ctr, r * 2.5, Color(COL_BLOOD, alpha * 0.35))
	canvas.draw_circle(ctr, r * 1.5, Color(COL_RIM, alpha * 0.65))
	canvas.draw_circle(ctr, r * 0.6, Color(COL_HOT, alpha * 0.95))

# core erupt — peak 시점 중심 white-hot 폭발 (scale 0.1→2.2→3.5)
func _draw_core(canvas: CanvasItem, ga: float) -> void:
	var t: float = (_age - IMPACT_DELAY) / 1.4
	if t < 0.0 or t > 1.0:
		return
	# scale: 0~0.1 (.1→3.0), 0.1~0.3 (3.0→1.8), 0.3~1.0 (1.8→4.5)
	var sc: float
	if t < 0.1:
		sc = lerpf(0.1, 3.0, t / 0.1)
	elif t < 0.3:
		sc = lerpf(3.0, 1.8, (t - 0.1) / 0.2)
	else:
		sc = lerpf(1.8, 4.5, (t - 0.3) / 0.7)
	# alpha: 0~0.1 (0→1), 0.1~0.4 (1.0 유지), 0.4~1.0 (1→0)
	var alpha: float
	if t < 0.1:
		alpha = t / 0.1
	elif t < 0.4:
		alpha = 1.0
	else:
		alpha = 1.0 - (t - 0.4) / 0.6
	alpha *= ga
	if alpha <= 0.0:
		return
	var ctr: Vector2 = _target + Vector2(0.0, -40.0)
	var r: float = CORE_R * sc
	# 외층 (옅은 빨강)
	canvas.draw_circle(ctr, r * 2.5, Color(COL_BLOOD, alpha * 0.3))
	# 중층 (주황)
	canvas.draw_circle(ctr, r * 1.6, Color(COL_RIM, alpha * 0.6))
	# 황금 중간층
	canvas.draw_circle(ctr, r, Color(COL_RIM_HOT, alpha * 0.85))
	# 흰 코어
	canvas.draw_circle(ctr, r * 0.45, Color(COL_HOT, alpha * 0.98))

# 보스 머리 위 vertical streaks — peak 부터 위로 솟구치는 빛기둥 (6개)
func _draw_vertical_streaks(canvas: CanvasItem, ga: float) -> void:
	var t: float = (_age - IMPACT_DELAY) / 0.9
	if t < 0.0 or t > 1.0:
		return
	var fade: float
	if t < 0.1:
		fade = t / 0.1
	else:
		fade = 1.0 - (t - 0.1) / 0.9
	var alpha: float = fade * ga
	if alpha <= 0.0:
		return
	var ctr: Vector2 = _target + Vector2(0.0, -30.0)
	var streak_count := 6
	for i in range(streak_count):
		var x_off: float = (float(i) - float(streak_count - 1) * 0.5) * 22.0
		var rise: float = clampf(t * 1.5 + sin(float(i) * 0.7) * 0.2, 0.0, 1.0)
		var top_y: float = ctr.y - 200.0 * rise
		var line_a: float = alpha * (0.7 + sin(_age * (TAU * 6.0) + float(i)) * 0.2)
		canvas.draw_line(ctr + Vector2(x_off, 0.0), Vector2(ctr.x + x_off, top_y),
			Color(COL_RIM_HOT, line_a), 1.5, true)
		canvas.draw_line(ctr + Vector2(x_off, 0.0), Vector2(ctr.x + x_off, top_y),
			Color(COL_HOT, line_a * 0.5), 0.8, true)

# 6겹 shockwave — peak 부터 1.8s 동안 확장
func _draw_shockwave(canvas: CanvasItem, delay: float, ga: float, base_col: Color) -> void:
	var t: float = (_age - IMPACT_DELAY - delay) / 1.8
	if t < 0.0 or t > 1.0:
		return
	var sc: float = lerpf(0.2, 22.0, t)
	var alpha: float
	if t < 0.05:
		alpha = t / 0.05
	else:
		alpha = 1.0 - (t - 0.05) / 0.95
	alpha *= ga
	if alpha <= 0.0:
		return
	var ctr: Vector2 = _target + Vector2(0.0, -40.0)
	var rad: float = 60.0 * sc
	var thick: float = lerpf(5.0, 0.5, t)
	canvas.draw_arc(ctr, rad, 0.0, TAU, 64, Color(base_col, alpha), thick, true)

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
