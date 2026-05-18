# scenes/vfx/power_up.gd
# 힘 모으기 VFX — ui_sample/vfx/Power Up VFX.html 재현 (적 CHARGE_UP intent 발동 시).
# 외곽에서 적으로 수렴하는 inflow 파티클 + 적 위치 청록 aura + 솟구치는 vertical streaks.
# CHARGE_TIME 후 짧은 peak shockwave + screen_effect emit, HOLD/FADE 후 자유.
extends Node2D

# 파티클 갯수 — GameSettings.particle_count_scale 적용 (하/중/상 = 0.25/0.5/1.0배)
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


const COL_HOT   := Color(1.0, 1.0, 1.0)            # 흰 코어
const COL_CYAN  := Color(0.486, 0.875, 1.0)        # #7cdfff 청록 에너지
const COL_DEEP  := Color(0.117, 0.435, 0.722)      # #1e6fb8 진청
const COL_WARM  := Color(1.0, 0.706, 0.329)        # #ffb454 따뜻한 강조
const COL_DUST  := Color(0.549, 0.706, 0.863)      # 청색 dust

const CHARGE_TIME  := 0.5    # inflow + aura ramp
const IMPACT_DELAY := CHARGE_TIME  # battle_manager 동기화
const HOLD_TIME    := 0.3    # peak hold
const FADE_TIME    := 0.35   # 페이드아웃
const AURA_W       := 110.0
const AURA_H       := 160.0
const STREAK_W     := 220.0  # 솟구치는 streak 가로 폭
const STREAK_H     := 200.0  # streak 솟구치는 높이
const STREAK_COUNT := 8
const PSPEED       := 60.0

## 화면 플래시 + power-up SFX 트리거 (peak 시점)
signal screen_effect

var _caster := Vector2.ZERO
# 바닥 anchor — set_ground_anchor() 로 캐릭터 발 위치 지정 (aura·dust 등 바닥 효과 기준).
# 미지정 시 _caster 기준으로 폴백.
var _ground_pos := Vector2.ZERO
var _has_ground: bool = false

func set_ground_anchor(pos: Vector2) -> void:
	_ground_pos = pos
	_has_ground = true
	if _ground_layer != null:
		_ground_layer.z_as_relative = false
		_ground_layer.z_index = int(pos.y) - 1  # 캐릭터(y_sort) 뒤로

var _age := -1.0          # 0..CHARGE_TIME+HOLD+FADE
var _impact_emitted := false
var _particles: Array = []
var _ground_layer: Node2D  # 가산 블렌드, 캐릭터 뒤 — aura + 바닥 dust
var _glow_layer: Node2D    # 가산 블렌드, 캐릭터 앞 — streak, inflow mote, peak shock

func _foot_pos() -> Vector2:
	return _ground_pos if _has_ground else _caster

func _ready() -> void:
	set_process(false)
	# 바닥 효과 — 캐릭터 뒤로 z set (set_ground_anchor 가 외부에서 호출 시 적용)
	_ground_layer = _DrawLayer.new()
	_ground_layer.setup(self, true)  # 가산 블렌드 (청록 글로우)
	add_child(_ground_layer)
	_ground_layer.set_meta("pass", "ground")
	# 위 레이어 — 캐릭터 앞 가산 블렌드
	_glow_layer = _DrawLayer.new()
	_glow_layer.setup(self, true)
	add_child(_glow_layer)
	_glow_layer.set_meta("pass", "glow")

# caster_pos = 적 위치 (몸체 중심), target_pos 무시. 바닥 좌표는 set_ground_anchor 로 별도 지정.
func play(caster_pos: Vector2, _target_pos: Vector2) -> void:
	_caster = caster_pos
	_age = 0.0
	set_process(true)
	await get_tree().create_timer(CHARGE_TIME + HOLD_TIME + FADE_TIME + 0.1).timeout
	if is_inside_tree():
		queue_free()

# 외곽에서 적 위치로 inflow 파티클 spawn (homing)
func _spawn_inflow(n: int) -> void:
	for _i in range(n):
		var ang := randf() * TAU
		var dist := 220.0 + randf() * 160.0
		var sx := _caster.x + cos(ang) * dist
		var sy := _caster.y + sin(ang) * dist * 0.65
		var sp := 2.5 + randf() * 2.0
		var dx := _caster.x - sx
		var dy := _caster.y - sy
		var d_len: float = max(1.0, sqrt(dx * dx + dy * dy))
		var tint_r := randf()
		var tint: String = "warm" if tint_r < 0.15 else ("cyan" if tint_r < 0.65 else "white")
		_particles.append({
			"pos": Vector2(sx, sy),
			"vel": Vector2(dx / d_len * sp, dy / d_len * sp),
			"life": 0.0,
			"max_life": 0.9 + randf() * 0.5,
			"size": 1.2 + randf() * 1.4,
			"kind": "mote",
			"tint": tint,
			"homing": true,
		})

# 바닥 부유 dust (캐릭터 발치에서 위로 솟구침) — _foot_pos 기준
func _spawn_dust(n: int) -> void:
	var foot: Vector2 = _foot_pos()
	for _i in range(n):
		_particles.append({
			"pos": Vector2(foot.x + randf_range(-90.0, 90.0), foot.y - 4.0),
			"vel": Vector2(randf_range(-0.3, 0.3), -0.5 - randf() * 0.6),
			"life": 0.0,
			"max_life": 1.2 + randf() * 0.6,
			"size": 12.0 + randf() * 14.0,
			"kind": "dust",
			"tint": "cyan",
			"homing": false,
			"grav": -0.005,
		})

# peak 시 폭발 — 외곽으로 튀는 mote + dust ring
func _spawn_peak_burst() -> void:
	for _i in range(_pcount(40)):
		var a := randf() * TAU
		var sp := 3.0 + randf() * 5.0
		_particles.append({
			"pos": _caster,
			"vel": Vector2(cos(a) * sp, sin(a) * sp - 1.5),
			"life": 0.0,
			"max_life": 0.9 + randf() * 0.6,
			"size": 1.4 + randf() * 1.4,
			"kind": "mote",
			"tint": "warm" if randf() < 0.3 else "cyan",
			"homing": false,
			"grav": 0.02,
		})
	var foot: Vector2 = _foot_pos()
	for _i in range(_pcount(16)):
		var a2 := randf() * TAU
		var sp2 := 2.0 + randf() * 3.0
		_particles.append({
			"pos": foot,
			"vel": Vector2(cos(a2) * sp2, sin(a2) * sp2 * 0.25 - 0.6 - randf() * 0.8),
			"life": 0.0,
			"max_life": 1.0 + randf() * 0.5,
			"size": 18.0 + randf() * 14.0,
			"kind": "dust",
			"tint": "cyan",
			"homing": false,
			"grav": -0.005,
		})

func _process(delta: float) -> void:
	_age += delta
	# Phase 1: 차지 중 — 매 프레임 inflow + 가끔 dust
	if _age < CHARGE_TIME:
		var intensity: int = _pcount(int(2 + (_age / CHARGE_TIME) * 4))
		_spawn_inflow(intensity)
		if randf() < 0.7 * _scale() and _age > CHARGE_TIME * 0.3:
			_spawn_dust(1)
	# Phase 2: peak 도달 — 한 번의 burst + screen_effect
	if not _impact_emitted and _age >= CHARGE_TIME:
		_impact_emitted = true
		_spawn_peak_burst()
		screen_effect.emit()

	# 파티클 업데이트
	var alive: Array = []
	for p in _particles:
		p["life"] += delta
		if p["life"] >= p["max_life"]:
			continue
		# homing — 적 위치로 가속
		if p.get("homing", false):
			var dx: float = _caster.x - p["pos"].x
			var dy: float = _caster.y - p["pos"].y
			var d: float = max(1.0, sqrt(dx * dx + dy * dy))
			if d < 10.0:
				continue  # 도착
			var accel: float = 0.08 + (1.0 - min(1.0, d / 300.0)) * 0.18
			p["vel"].x += dx / d * accel * delta * PSPEED
			p["vel"].y += dy / d * accel * delta * PSPEED
		p["pos"] += p["vel"] * delta * PSPEED
		p["vel"].y += p.get("grav", 0.0) * delta * PSPEED
		p["vel"] *= pow(0.99, delta * 60.0)
		alive.append(p)
	_particles = alive

	_ground_layer.queue_redraw()
	_glow_layer.queue_redraw()

# 페이드 알파 계산 — Phase 끝나면 0 으로
func _global_alpha() -> float:
	if _age < CHARGE_TIME + HOLD_TIME:
		return clampf(_age / 0.2, 0.0, 1.0)  # 빠른 페이드인
	var t: float = (_age - (CHARGE_TIME + HOLD_TIME)) / FADE_TIME
	return clampf(1.0 - t, 0.0, 1.0)

# ── ground (가산 블렌드, 캐릭터 뒤) — aura + dust (발치 효과) ──
func _draw_ground_pass(canvas: CanvasItem) -> void:
	var ga: float = _global_alpha()
	if ga <= 0.0:
		return
	_draw_aura(canvas, ga)
	for p in _particles:
		if p["kind"] != "dust":
			continue
		var k: float = p["life"] / p["max_life"]
		var a: float = (1.0 - k) * 0.4 * ga
		var r: float = p["size"] * (1.0 + k * 1.3)
		canvas.draw_circle(p["pos"], r, Color(COL_DUST, a))

# ── glow (가산 블렌드, 캐릭터 앞) — vertical streaks, inflow mote, peak shock ──
func _draw_glow_pass(canvas: CanvasItem) -> void:
	var ga: float = _global_alpha()
	if ga <= 0.0:
		return
	_draw_streaks(canvas, ga)
	for p in _particles:
		if p["kind"] != "mote":
			continue
		var k: float = p["life"] / p["max_life"]
		var a: float = (1.0 - k) * ga
		var col := _mote_color(p["tint"], a)
		var pr: float = p["size"]
		canvas.draw_circle(p["pos"], pr * 1.8, Color(col.r, col.g, col.b, col.a * 0.45))
		canvas.draw_circle(p["pos"], pr, col)
		# 모션 streak (homing 방향)
		if p.get("homing", false):
			var sp: float = p["vel"].length()
			if sp > 1.5:
				var ang: float = p["vel"].angle()
				var stl: float = min(sp * 1.6, 18.0)
				var sp_v: Vector2 = Vector2(cos(ang), sin(ang)) * stl
				canvas.draw_line(p["pos"] - sp_v, p["pos"], col, 0.8, true)
	if _impact_emitted:
		_draw_peak_shock(canvas, ga)

func _mote_color(tint: String, a: float) -> Color:
	match tint:
		"warm":  return Color(1.0, 0.823, 0.549, a)
		"cyan":  return Color(0.588, 0.921, 1.0, a)
		_:        return Color(0.941, 0.980, 1.0, a)

# 발치 청록 aura — 발 밑에서 위로 솟는 빛기둥 (캐릭터 뒤로 렌더링)
func _draw_aura(canvas: CanvasItem, ga: float) -> void:
	var grow: float = clampf(_age / 0.3, 0.0, 1.0)
	var alpha: float = grow * ga * 0.7
	var foot: Vector2 = _foot_pos()
	# 바닥 ellipse — 발 밑 청록 풀
	var pool := PackedVector2Array()
	var seg := 32
	var pw: float = AURA_W * grow
	var ph: float = AURA_W * 0.35 * grow  # 납작한 바닥 ellipse
	for i in range(seg + 1):
		var a: float = TAU * float(i) / float(seg)
		pool.append(foot + Vector2(cos(a) * pw * 0.55, sin(a) * ph * 0.5))
	canvas.draw_colored_polygon(pool, Color(COL_CYAN, alpha * 0.55))
	canvas.draw_colored_polygon(pool, Color(COL_DEEP, alpha * 0.35))
	# 발치에서 위로 솟는 빛기둥 — 사다리꼴
	var h: float = AURA_H * grow
	var bottom_y: float = foot.y
	var top_y: float = foot.y - h
	var w_bot: float = AURA_W * 0.45 * grow
	var w_top: float = AURA_W * 0.18 * grow
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(foot.x - w_bot, bottom_y),
		Vector2(foot.x + w_bot, bottom_y),
		Vector2(foot.x + w_top, top_y),
		Vector2(foot.x - w_top, top_y),
	]), Color(COL_CYAN, alpha * 0.45))

# 적 머리 위로 솟구치는 vertical light streaks (HTML spires)
func _draw_streaks(canvas: CanvasItem, ga: float) -> void:
	var grow: float = clampf(_age / 0.35, 0.0, 1.0)
	var alpha: float = grow * ga * 0.85
	if alpha <= 0.0:
		return
	# 8개 streak — caster x 주변 ±STREAK_W/2 범위, 위로 STREAK_H 만큼
	for i in range(STREAK_COUNT):
		var t: float = float(i) / float(STREAK_COUNT - 1)
		var x: float = _caster.x + (t - 0.5) * STREAK_W
		var phase: float = fmod(_age * 2.0 + t * 0.7, 1.0)  # 반복 솟구침
		var y_top: float = _caster.y - STREAK_H * phase
		var y_bot: float = _caster.y - STREAK_H * (phase - 0.4)
		y_bot = min(y_bot, _caster.y)  # 시작은 아래쪽 cap
		var line_a: float = alpha * (1.0 - phase)
		canvas.draw_line(Vector2(x, y_bot), Vector2(x, y_top), Color(COL_CYAN, line_a), 2.0, true)
		canvas.draw_line(Vector2(x, y_bot), Vector2(x, y_top), Color(COL_HOT, line_a * 0.5), 1.0, true)

# peak 시 한 번의 shockwave ring
func _draw_peak_shock(canvas: CanvasItem, ga: float) -> void:
	var t: float = (_age - CHARGE_TIME) / 0.5
	if t < 0.0 or t > 1.0:
		return
	var sc: float = lerpf(0.2, 12.0, t)
	var alpha: float
	if t < 0.25:
		alpha = t / 0.25
	else:
		alpha = 1.0 - (t - 0.25) / 0.75
	alpha *= ga
	if alpha <= 0.0:
		return
	var rad: float = 20.0 * sc
	var thick: float = lerpf(5.0, 1.0, t)
	canvas.draw_arc(_caster, rad, 0.0, TAU, 48, Color(COL_CYAN, alpha), thick, true)
	canvas.draw_arc(_caster, rad * 0.85, 0.0, TAU, 36, Color(COL_HOT, alpha * 0.7), thick * 0.5, true)

# ── 블렌드 분리 레이어 — meta("pass") 로 ground/glow 분기 ──
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
