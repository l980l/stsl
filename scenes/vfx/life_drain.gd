# scenes/vfx/life_drain.gd
# 생명력 흡수 VFX — ui_sample/vfx/Life Drain VFX.html 재현 (HUD/숫자/플래시 제외).
# 흐름: open(0.30s) → siphon(1.50s) → seal(0.70s)
#   open    : target 위치에서 피 분출(splat) + wither 고리 등장
#   siphon  : caster↔target 사이 wavy tether + 흐름 입자(target→caster) + spiral 고리(caster) + 성배 sigil(caster 머리 위) + 바닥 motes
#   seal    : tether/spiral 페이드, sigil 위로 사라짐
# play(caster_pos, target_pos) — caster 가 흡수자, target 이 피해 대상.
# screen_effect 시그널은 siphon 시작 시점에 발동 (battle_scene 이 SFX·임팩트 동기화에 사용).
# 잎/포일 가산 블렌드(반짝임·흐름·고리)는 _glow_layer, 불투명 피·꼬리는 _smoke_layer.
extends Node2D

# 파티클 갯수 — GameSettings.particle_count_scale 적용 (하/중/상 = 0.25/0.5/1.0)
var _particle_scale_override: float = -1.0  # vfx_preview 3-way 비교용

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

# 색상 — HTML --blood/--brass/--hot 기준
const COL_HOT     := Color(1.0,   0.541, 0.565)   # #ff8a90  tether core
const COL_BLOOD   := Color(0.851, 0.290, 0.314)   # #d94a50  메인 블러드
const COL_BLOOD_M := Color(0.545, 0.102, 0.122)   # #8b1a1f
const COL_BLOOD_D := Color(0.290, 0.051, 0.063)   # #4a0d10
const COL_BRASS   := Color(0.910, 0.784, 0.471)   # #e8c878  성배·dashed flow
const COL_BRASS_H := Color(1.0,   0.953, 0.753)   # #fff3c0

# 타이밍 (s) — 이 상수만 만지면 된다.
const OPEN_TIME    := 0.30
const SIPHON_TIME  := 1.50
const SEAL_TIME    := 0.70
const FADE_TAIL    := 0.80         # seal 후 잔여 입자 페이드 여유
const IMPACT_DELAY := OPEN_TIME    # battle_manager 동기화용 (siphon 시작 = 흡수 발동)

const RING_SQUASH  := 0.34         # 누운 원근 (rotateX 70° 근사)
const PSPEED       := 60.0         # HTML(dt*0.06) → Godot(delta*60) 환산 계수

## 흡수 발동(siphon 시작) 시점 — battle_scene 이 받아 SFX·효과 적용을 동기화.
signal screen_effect

var _caster := Vector2.ZERO
var _target := Vector2.ZERO

# 바닥 anchor — set_ground_anchors() 로 caster/target 발 위치 지정.
var _caster_ground := Vector2.ZERO
var _target_ground := Vector2.ZERO
var _has_grounds: bool = false

# 페이즈 — 0=idle, 1=open, 2=siphon, 3=seal
var _phase: int = 0
var _phase_age: float = 0.0

# 데코 age (음수 = 비활성)
var _wither_age: float = -1.0
var _spiral_age: float = -1.0
var _tether_age: float = -1.0
var _sigil_age:  float = -1.0
var _tether_fade_age: float = -1.0
var _spiral_fade_age: float = -1.0
var _wither_fade_age: float = -1.0
var _sigil_fade_age:  float = -1.0

var _wave_t: float = 0.0           # tether wavy 위상 + dash 흐름

var _particles: Array = []         # {kind, ...}
# kind:
#   splat   — 초기 피 분출 (target). pos, vel, life, max_life, r, grav
#   flow    — tether 따라 target→caster. t, t_speed, life, max_life, r, phase, jitter, tint(blood/brass)
#   rise    — 바닥 motes. pos, vel, life, max_life, r, tint(cold/warm)

var _smoke_layer: Node2D  # 불투명 — splat
var _glow_layer:  Node2D  # 가산 — tether/flow/rise/sigil
var _ground_layer: Node2D # 캐릭터 뒤 z — wither/spiral

# 흡수자(caster)와 대상(target) 의 발 위치를 지정. 없으면 _target/_caster 아래 42px 가정.
func set_ground_anchors(caster_ground: Vector2, target_ground: Vector2) -> void:
	_caster_ground = caster_ground
	_target_ground = target_ground
	_has_grounds = true
	if _ground_layer != null:
		_ground_layer.z_as_relative = false
		# 더 위쪽(작은 y) 발 위치 - 1 → 캐릭터 두 명 모두 뒤로
		_ground_layer.z_index = int(min(caster_ground.y, target_ground.y)) - 1

func _ready() -> void:
	set_process(false)

	_ground_layer = _GroundLayer.new()
	_ground_layer.setup(self)
	add_child(_ground_layer)

	_smoke_layer = _DrawLayer.new()
	_smoke_layer.setup(self, false)
	add_child(_smoke_layer)

	_glow_layer = _DrawLayer.new()
	_glow_layer.setup(self, true)
	add_child(_glow_layer)

func play(caster_pos: Vector2, target_pos: Vector2) -> void:
	_caster = caster_pos
	_target = target_pos
	_run()

func _run() -> void:
	# Phase 1: open — wound burst + wither 등장
	_phase = 1
	_phase_age = 0.0
	_wither_age = 0.0
	_spawn_wound_burst()
	set_process(true)
	await get_tree().create_timer(OPEN_TIME).timeout
	if not is_inside_tree():
		return

	# Phase 2: siphon — tether/spiral/sigil 등장, 흐름 입자 분출
	_phase = 2
	_phase_age = 0.0
	_tether_age = 0.0
	_spiral_age = 0.0
	_sigil_age = 0.0
	screen_effect.emit()
	await get_tree().create_timer(SIPHON_TIME).timeout
	if not is_inside_tree():
		return

	# Phase 3: seal — tether/wither/spiral 페이드, sigil 위로 사라짐
	_phase = 3
	_phase_age = 0.0
	_tether_fade_age = 0.0
	_spiral_fade_age = 0.0
	_wither_fade_age = 0.0
	_sigil_fade_age = 0.0
	await get_tree().create_timer(SEAL_TIME + FADE_TAIL).timeout
	if is_inside_tree():
		queue_free()

# ── 입자 spawn ──

func _spawn_wound_burst() -> void:
	# 28 빨간 splat — 왼쪽(caster 방향) 위주
	var dir_to_caster: float = (_caster - _target).angle()
	for _i in range(_pcount(28)):
		var ang := dir_to_caster + randf_range(-0.7, 0.7)
		var sp := 2.0 + randf() * 4.0
		_particles.append({
			"kind": "splat",
			"pos": _target + Vector2(0.0, -8.0),
			"vel": Vector2(cos(ang), sin(ang) - 0.4) * sp * PSPEED * 0.06,
			"life": 0.0, "max_life": 0.85 + randf() * 0.55,
			"r": 1.4 + randf() * 1.6,
			"grav": 0.08,
		})

func _spawn_flow() -> void:
	# tether 따라 target→caster 로 흐르는 작은 코어
	for _i in range(int(maxf(1, 2.0 * _scale()))):
		var t0 := 0.92 + randf() * 0.06
		_particles.append({
			"kind": "flow", "tint": "blood",
			"t": t0, "t_speed": 1.05 + randf() * 0.75,
			"life": 0.0, "max_life": 1.1 + randf() * 0.4,
			"r": 1.5 + randf() * 1.3,
			"phase": randf() * TAU,
			"jitter": randf_range(-6.0, 6.0),
		})
	# 가끔 brass 코어 (회복받는 신호)
	if randf() < 0.28:
		_particles.append({
			"kind": "flow", "tint": "brass",
			"t": 0.95, "t_speed": 0.85 + randf() * 0.55,
			"life": 0.0, "max_life": 1.35 + randf() * 0.4,
			"r": 1.9 + randf() * 1.3,
			"phase": randf() * TAU,
			"jitter": randf_range(-6.0, 6.0),
		})

func _spawn_rising() -> void:
	var t_floor: Vector2 = _target_ground if _has_grounds else _target + Vector2(0.0, 80.0)
	var c_floor: Vector2 = _caster_ground if _has_grounds else _caster + Vector2(0.0, 80.0)
	# target — cold(어둡고 푸르스름) 망령 모트
	if randf() < 0.7 * _scale():
		_particles.append({
			"kind": "rise", "tint": "cold",
			"pos": t_floor + Vector2(randf_range(-40.0, 40.0), randf() * 4.0),
			"vel": Vector2(randf_range(-0.2, 0.2), -0.55 - randf() * 0.7) * PSPEED,
			"life": 0.0, "max_life": 1.4 + randf() * 0.6,
			"r": 1.0 + randf() * 1.2,
		})
	# caster — warm(brass) 생명 모트
	if randf() < 0.5 * _scale():
		_particles.append({
			"kind": "rise", "tint": "warm",
			"pos": c_floor + Vector2(randf_range(-40.0, 40.0), randf() * 4.0),
			"vel": Vector2(randf_range(-0.18, 0.18), -0.6 - randf() * 0.6) * PSPEED,
			"life": 0.0, "max_life": 1.4 + randf() * 0.6,
			"r": 1.0 + randf() * 1.2,
		})

# ── _process ──

func _process(delta: float) -> void:
	_phase_age += delta
	_wave_t += delta
	if _wither_age >= 0.0: _wither_age += delta
	if _spiral_age >= 0.0: _spiral_age += delta
	if _tether_age >= 0.0: _tether_age += delta
	if _sigil_age  >= 0.0: _sigil_age  += delta
	if _tether_fade_age >= 0.0: _tether_fade_age += delta
	if _spiral_fade_age >= 0.0: _spiral_fade_age += delta
	if _wither_fade_age >= 0.0: _wither_fade_age += delta
	if _sigil_fade_age  >= 0.0: _sigil_fade_age  += delta

	# 분출
	if _phase == 2:
		_spawn_flow()
		_spawn_rising()
	elif _phase == 3:
		_spawn_rising()

	# 입자 step
	var damp: float = pow(0.992, delta * 60.0)
	var alive: Array = []
	for p in _particles:
		p["life"] += delta
		if p["life"] >= p["max_life"]:
			continue
		match p["kind"]:
			"splat":
				p["pos"] += p["vel"] * delta * PSPEED
				p["vel"].y += p["grav"] * delta * PSPEED
				p["vel"] *= damp
			"flow":
				p["t"] -= p["t_speed"] * delta
				if p["t"] <= 0.02:
					continue
				var dx: float = _target.x - _caster.x
				var dy: float = _target.y - _caster.y
				var t: float = p["t"]
				var base_x: float = _caster.x + dx * t
				var base_y: float = _caster.y + dy * t
				var nx: float = -dy
				var ny: float = dx
				var nl: float = sqrt(nx * nx + ny * ny)
				if nl > 0.0:
					var fall: float = sin(t * PI)
					var wig: float = sin(_wave_t * 8.0 + p["phase"]) * p["jitter"] * fall
					p["pos"] = Vector2(base_x + nx / nl * wig, base_y + ny / nl * wig)
				else:
					p["pos"] = Vector2(base_x, base_y)
			"rise":
				p["pos"] += p["vel"] * delta
				p["vel"].y *= pow(0.996, delta * 60.0)
		alive.append(p)
	_particles = alive

	_smoke_layer.queue_redraw()
	_glow_layer.queue_redraw()
	if _ground_layer:
		_ground_layer.queue_redraw()

# ── 그리기 패스 ──

# 불투명 — splat (피 방울 + 꼬리)
func _draw_smoke_pass(canvas: CanvasItem) -> void:
	for p in _particles:
		if p["kind"] != "splat":
			continue
		var k: float = p["life"] / p["max_life"]
		var a: float = 1.0 - k * 0.6
		canvas.draw_circle(p["pos"], p["r"], Color(COL_BLOOD, a))
		var v: Vector2 = p["vel"]
		var sp: float = v.length()
		if sp > 0.1:
			var tail: float = min(14.0, sp * 0.04)
			var tip: Vector2 = p["pos"] - v.normalized() * tail
			canvas.draw_line(p["pos"], tip, Color(COL_BLOOD_M, a * 0.55), p["r"] * 0.8)

# 가산 — tether + flow + rise + sigil
func _draw_glow_pass(canvas: CanvasItem) -> void:
	if _tether_age >= 0.0:
		_draw_tether(canvas)
	for p in _particles:
		match p["kind"]:
			"flow":
				var k: float = p["life"] / p["max_life"]
				var a: float = 1.0 - k * 0.5
				var col: Color = COL_BRASS if p["tint"] == "brass" else COL_HOT
				var pr: float = p["r"]
				canvas.draw_circle(p["pos"], pr * 1.8, Color(col, a * 0.32))
				canvas.draw_circle(p["pos"], pr, Color(col, a))
				if pr > 1.8:
					canvas.draw_rect(Rect2(p["pos"].x - pr * 1.6, p["pos"].y - 0.3, pr * 3.2, 0.6), Color(col, a))
					canvas.draw_rect(Rect2(p["pos"].x - 0.3, p["pos"].y - pr * 1.6, 0.6, pr * 3.2), Color(col, a))
			"rise":
				var k2: float = p["life"] / p["max_life"]
				var a2: float = 1.0 - k2
				var col2: Color = COL_BLOOD_D if p["tint"] == "cold" else COL_BRASS
				canvas.draw_circle(p["pos"], p["r"] * 1.6, Color(col2, a2 * 0.5))
				canvas.draw_circle(p["pos"], p["r"] * 0.7, Color(col2, a2))
	if _sigil_age >= 0.0:
		_draw_sigil(canvas)

# 캐릭터 뒤 z — wither(target) + spiral(caster)
func _draw_ground_pass(canvas: CanvasItem) -> void:
	if _spiral_age >= 0.0:
		_draw_spiral(canvas)
	if _wither_age >= 0.0:
		_draw_wither(canvas)

# ── 데코 그리기 ──

# tether — caster↔target wavy 3중 라인 (core hot / inner white / brass dashed)
func _draw_tether(canvas: CanvasItem) -> void:
	var appear: float = clampf(_tether_age / 0.25, 0.0, 1.0)
	var fade: float = 1.0
	if _tether_fade_age >= 0.0:
		fade = clampf(1.0 - _tether_fade_age / 0.5, 0.0, 1.0)
	var a: float = appear * fade
	if a <= 0.0:
		return
	var segs := 22
	var dx: float = _target.x - _caster.x
	var dy: float = _target.y - _caster.y
	var dist: float = sqrt(dx * dx + dy * dy)
	var wave: float = min(28.0, dist * 0.06)
	var nx: float = -dy
	var ny: float = dx
	var nl: float = sqrt(nx * nx + ny * ny)
	var pts := PackedVector2Array()
	for i in range(segs + 1):
		var t: float = float(i) / float(segs)
		var base_x: float = _caster.x + dx * t
		var base_y: float = _caster.y + dy * t
		var fall: float = sin(t * PI)
		var phase: float = _wave_t * 5.0 + t * PI * 3.4
		var w: float = sin(phase) * wave * fall
		if nl > 0.0:
			pts.append(Vector2(base_x + nx / nl * w, base_y + ny / nl * w))
		else:
			pts.append(Vector2(base_x, base_y))
	# core (두꺼운 hot pink)
	canvas.draw_polyline(pts, Color(COL_HOT, a * 0.95), 5.0, true)
	# inner (얇은 흰색)
	canvas.draw_polyline(pts, Color(1.0, 1.0, 1.0, a * 0.85), 1.5, true)
	# brass dashed (간단화 — 짝수 세그먼트만 그려 흐름감)
	var dash_period: int = 3
	var dash_offset: int = int(_wave_t * 14.0) % (dash_period + 2)
	for i in range(pts.size() - 1):
		if (i + dash_offset) % (dash_period + 2) < dash_period:
			canvas.draw_line(pts[i], pts[i + 1], Color(COL_BRASS, a * 0.85), 2.0, true)

# wither — target 발 아래 누운 빨간 고리 두 줄 (정적)
func _draw_wither(canvas: CanvasItem) -> void:
	var appear: float = clampf(_wither_age / 0.5, 0.0, 1.0)
	var sc: float = lerpf(0.6, 1.0, appear)
	var fade: float = 1.0
	if _wither_fade_age >= 0.0:
		fade = clampf(1.0 - _wither_fade_age / 0.9, 0.0, 1.0)
	var a: float = appear * fade * 0.7
	if a <= 0.0:
		return
	var rc: Vector2 = _target_ground if _has_grounds else _target + Vector2(0.0, 42.0)
	for rad in [94.0, 82.0]:
		var r: float = float(rad) * sc
		var pts := PackedVector2Array()
		for i in range(40):
			var ang: float = TAU * float(i) / 40.0
			pts.append(rc + Vector2(cos(ang) * r, sin(ang) * r * RING_SQUASH))
		canvas.draw_polyline(pts + PackedVector2Array([pts[0]]), Color(COL_BLOOD_D, a), 1.6, true)

# spiral — caster 발 아래 누운 빨간 고리 + brass dashed 내부 + chalice glyph + 천천히 회전
func _draw_spiral(canvas: CanvasItem) -> void:
	var appear: float = clampf(_spiral_age / 0.55, 0.0, 1.0)
	var sc: float = lerpf(0.4, 1.0, appear)
	var fade: float = 1.0
	if _spiral_fade_age >= 0.0:
		fade = clampf(1.0 - _spiral_fade_age / 1.0, 0.0, 1.0)
	var a: float = appear * fade * 0.9
	if a <= 0.0:
		return
	var rc: Vector2 = _caster_ground if _has_grounds else _caster + Vector2(0.0, 42.0)
	var spin: float = _spiral_age * (-TAU / 5.0)  # 5초 1회전
	# 외곽 고리 두 줄 (blood / blood_mid)
	for ring in [[112.0, COL_BLOOD, 1.6], [100.0, COL_BLOOD_M, 1.2]]:
		var r: float = float(ring[0]) * sc
		var col: Color = ring[1]
		var lw: float = float(ring[2])
		var pts := PackedVector2Array()
		for i in range(48):
			var ang: float = TAU * float(i) / 48.0 + spin
			pts.append(rc + Vector2(cos(ang) * r, sin(ang) * r * RING_SQUASH))
		canvas.draw_polyline(pts + PackedVector2Array([pts[0]]), Color(col, a), lw, true)
	# 내부 brass 점선 (간격 dashed 간단 시뮬레이션)
	var inner_r: float = 64.0 * sc
	var dash_segs: int = 60
	for i in range(dash_segs):
		if i % 2 != 0:
			continue
		var a1: float = TAU * float(i) / float(dash_segs) + spin
		var a2: float = TAU * float(i + 1) / float(dash_segs) + spin
		var p1: Vector2 = rc + Vector2(cos(a1) * inner_r, sin(a1) * inner_r * RING_SQUASH)
		var p2: Vector2 = rc + Vector2(cos(a2) * inner_r, sin(a2) * inner_r * RING_SQUASH)
		canvas.draw_line(p1, p2, Color(COL_BRASS, a * 0.55), 1.0, true)

# sigil — caster 머리 위 성배 + 점 (popup → float 부드럽게 위로 떠오름)
func _draw_sigil(canvas: CanvasItem) -> void:
	var pop: float = clampf(_sigil_age / 0.5, 0.0, 1.0)
	var sc: float
	if pop < 0.6:
		sc = lerpf(0.3, 1.08, pop / 0.6)
	else:
		sc = lerpf(1.08, 1.0, (pop - 0.6) / 0.4)
	var a: float = 1.0
	var rise_y: float = 0.0
	if _sigil_fade_age >= 0.0:
		a = clampf(1.0 - _sigil_fade_age / 0.8, 0.0, 1.0)
		rise_y = -16.0 * (1.0 - a)
	if a <= 0.0:
		return
	var float_y: float = 0.0
	if _sigil_age > 0.5:
		float_y = sin((_sigil_age - 0.5) * 2.2) * 6.0
	var c: Vector2 = _caster + Vector2(0.0, -150.0 + float_y + rise_y)
	var size: float = 32.0 * sc
	# 외곽 원
	var pts := PackedVector2Array()
	for i in range(40):
		var ang: float = TAU * float(i) / 40.0
		pts.append(c + Vector2(cos(ang), sin(ang)) * size)
	canvas.draw_polyline(pts + PackedVector2Array([pts[0]]), Color(COL_BLOOD, a * 0.9), 1.5, true)
	# 내부 점선 원 (brass)
	for i in range(40):
		if i % 2 != 0:
			continue
		var a1: float = TAU * float(i) / 40.0
		var a2: float = TAU * float(i + 1) / 40.0
		var p1: Vector2 = c + Vector2(cos(a1), sin(a1)) * size * 0.82
		var p2: Vector2 = c + Vector2(cos(a2), sin(a2)) * size * 0.82
		canvas.draw_line(p1, p2, Color(COL_BRASS, a * 0.7), 1.0, true)
	# 성배 윤곽 — 잔(좌·우 사선) + 줄기 + 받침
	var cw: float = size * 0.55
	var ch: float = size * 0.55
	canvas.draw_line(c + Vector2(-cw, -ch * 0.2), c + Vector2(0.0, ch * 0.2), Color(COL_HOT, a), 1.5, true)
	canvas.draw_line(c + Vector2(0.0, ch * 0.2), c + Vector2(cw, -ch * 0.2), Color(COL_HOT, a), 1.5, true)
	canvas.draw_line(c + Vector2(0.0, ch * 0.2), c + Vector2(0.0, ch * 0.7), Color(COL_BRASS, a), 2.0, true)
	canvas.draw_line(c + Vector2(-cw * 0.55, ch * 0.7), c + Vector2(cw * 0.55, ch * 0.7), Color(COL_BRASS, a), 2.0, true)
	# 잔 안 핏방울
	var drop := PackedVector2Array([
		c + Vector2(0.0, -ch * 0.05),
		c + Vector2(cw * 0.18, ch * 0.12),
		c + Vector2(0.0, ch * 0.22),
		c + Vector2(-cw * 0.18, ch * 0.12),
	])
	canvas.draw_colored_polygon(drop, Color(COL_BLOOD, a))

# ── 블렌드 모드별 두 그리기 레이어 (heal_blessing 패턴과 동일) ──

class _DrawLayer:
	extends Node2D
	var _fx: Node2D
	var _additive: bool = false

	func setup(owner_fx: Node2D, additive: bool) -> void:
		_fx = owner_fx
		_additive = additive
		if additive:
			var m := CanvasItemMaterial.new()
			m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
			material = m

	func _draw() -> void:
		if _additive:
			_fx._draw_glow_pass(self)
		else:
			_fx._draw_smoke_pass(self)

class _GroundLayer:
	extends Node2D
	var _fx: Node2D

	func setup(owner_fx: Node2D) -> void:
		_fx = owner_fx

	func _draw() -> void:
		_fx._draw_ground_pass(self)
