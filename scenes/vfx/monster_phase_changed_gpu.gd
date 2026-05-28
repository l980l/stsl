# scenes/vfx/monster_phase_changed_gpu.gd
# 일반 몬스터 페이즈 전환 VFX — ui_sample/vfx/Monster Phase Changed VFX.html.
# 보스 phase 의 시네마틱과 달리 작은 충격파 + inward 흡수 + 짧은 flash + 작은 지면 ring.
# 단계: CHARGE 0.56s (inward motes 흡수) → BURST 0.12s (flash + core + shock×3 + 사방 burst)
#       → SHIFT 0.26s → HOLD 1.5s (embers) → RING FADE 0.7s. TOTAL ~3.14s.
# SFX 는 battle_scene 호출 시점에 직접 재생 (vfx_preview 에서는 무음 — acid_spray 사례 일관성).
extends Node2D

const _Helpers = preload("res://scenes/vfx/gpu_particle_helpers.gd")

# 색 — HTML CSS var 매핑
const COL_BRASS    := Color(0.910, 0.784, 0.471)  # #e8c878
const COL_HOT      := Color(1.0, 0.972, 0.871)    # #fff8de
const COL_ORANGE   := Color(1.0, 0.667, 0.431)    # #ffaa6e
const COL_P2_RIM   := Color(0.851, 0.290, 0.314)  # #d94a50
const COL_P2_HOT   := Color(1.0, 0.604, 0.416)    # #ff9a6a

const CHARGE_TIME := 0.56
const BURST_TIME  := 0.12
const SHIFT_TIME  := 0.26
const HOLD_TIME   := 1.5
const FADE_TIME   := 0.7

var _target := Vector2.ZERO
var _foot_anchor := Vector2.ZERO  # 지면 효과 (ring, dust, embers) 위치 — battle_scene 의 _foot_pos
var _age: float = 0.0
var _burst_start: float = -1.0  # < 0 = 미발동
var _ring_start: float = -1.0
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

# vfx_preview._apply_ground_anchor 가 자동 호출 — 정확한 발치 위치 전달 (play 전에 호출됨).
func set_ground_anchor(pos: Vector2) -> void:
	_foot_anchor = pos

# battle_scene 호출: play(target_pos, foot_pos). phase_num 무시 (시각 동일).
func play(target_pos: Vector2, foot_pos: Vector2 = Vector2.ZERO, _phase_num: int = 2) -> void:
	_target = target_pos
	# set_ground_anchor 가 먼저 호출됐으면 그 값 유지. 아니면 foot_pos 인자 또는 fallback.
	if _foot_anchor == Vector2.ZERO:
		_foot_anchor = foot_pos if foot_pos != Vector2.ZERO else target_pos + Vector2(0.0, 96.0)
	_run_sequence()

func _run_sequence() -> void:
	# CHARGE — inward motes (사방 → 중심 흡수)
	_spawn_inward_motes()
	await get_tree().create_timer(CHARGE_TIME).timeout
	# BURST — flash + core + shock 시작 (CPU draw 활성화) + 사방 burst particles
	_burst_start = _age
	_ring_start = _age + BURST_TIME  # ring 은 burst 끝 후 등장
	_spawn_burst_particles()
	await get_tree().create_timer(BURST_TIME).timeout
	# SHIFT — 색 변화 (시각상 ring 천천히 등장)
	await get_tree().create_timer(SHIFT_TIME).timeout
	# HOLD — embers 천천히 위로
	_spawn_embers()
	await get_tree().create_timer(HOLD_TIME).timeout
	await get_tree().create_timer(FADE_TIME).timeout
	queue_free()

func _process(delta: float) -> void:
	_age += delta
	queue_redraw()

func _draw() -> void:
	if _burst_start >= 0.0:
		var burst_age: float = _age - _burst_start
		_draw_flash(burst_age)
		_draw_core(burst_age)
		# 3 shock — delay 0 / 0.06 / 0.12, dur 0.9 / 1.0 / 1.05
		_draw_shock(burst_age, 0.0, 0.9, Color(1.0, 1.0, 1.0, 1.0))
		_draw_shock(burst_age, 0.06, 1.0, COL_P2_RIM)
		_draw_shock(burst_age, 0.12, 1.05, Color(COL_BRASS.r, COL_BRASS.g, COL_BRASS.b, 0.5))
	if _ring_start >= 0.0:
		_draw_ring(_age - _ring_start)

# 0~25% 페이드인 → 100% 페이드아웃 (0.45s 짧은 노란 flash)
func _draw_flash(age: float) -> void:
	var dur: float = 0.45
	if age < 0.0 or age > dur:
		return
	var t: float = age / dur
	var alpha: float = (t / 0.25) if t < 0.25 else (1.0 - t) / 0.75
	draw_circle(_target, 120.0, Color(COL_HOT.r, COL_HOT.g, COL_HOT.b, alpha * 0.35))
	draw_circle(_target, 70.0, Color(COL_HOT.r, COL_HOT.g, COL_HOT.b, alpha * 0.55))

# coreErupt: 0:0/.1 → 18%:1/1.6 → 55%:1/1.1 → 100%:0/2.2 (0.85s)
func _draw_core(age: float) -> void:
	var dur: float = 0.85
	if age < 0.0 or age > dur:
		return
	var t: float = age / dur
	var alpha: float
	var sc: float
	if t < 0.18:
		alpha = t / 0.18
		sc = lerpf(0.1, 1.6, t / 0.18)
	elif t < 0.55:
		alpha = 1.0
		sc = lerpf(1.6, 1.1, (t - 0.18) / 0.37)
	else:
		alpha = lerpf(1.0, 0.0, (t - 0.55) / 0.45)
		sc = lerpf(1.1, 2.2, (t - 0.55) / 0.45)
	var r: float = 26.0 * sc
	# 흰-주황-fade 3-layer 원
	draw_circle(_target, r * 1.5, Color(COL_P2_RIM.r, COL_P2_RIM.g, COL_P2_RIM.b, alpha * 0.3))
	draw_circle(_target, r, Color(COL_P2_HOT.r, COL_P2_HOT.g, COL_P2_HOT.b, alpha * 0.55))
	draw_circle(_target, r * 0.55, Color(1.0, 1.0, 1.0, alpha * 0.9))

# shockOut: 0:0/.2/5px → 8%:1/_ → 100%:0/7×/0.5px
func _draw_shock(age: float, delay: float, dur: float, ring_col: Color) -> void:
	var ra: float = age - delay
	if ra < 0.0 or ra > dur:
		return
	var t: float = ra / dur
	var alpha: float = (t / 0.08) if t < 0.08 else (1.0 - t) / 0.92
	var sc: float = lerpf(0.2, 7.0, t)
	var width: float = lerpf(5.0, 0.5, t)
	draw_arc(_target, 40.0 * sc, 0.0, TAU, 48, Color(ring_col.r, ring_col.g, ring_col.b, ring_col.a * alpha), width)

# 지면 ring — 타원 (rotateX 72deg ≈ y scale 0.31) + slow spin (18s/cycle).
func _draw_ring(age: float) -> void:
	var in_dur: float = 0.55
	var fade_dur: float = 1.0
	var total: float = SHIFT_TIME + HOLD_TIME + FADE_TIME + BURST_TIME  # ring 지속
	if age < 0.0 or age > total:
		return
	var alpha: float
	var sc: float
	if age < in_dur:
		var t: float = 1.0 - pow(1.0 - age / in_dur, 3.0)
		sc = lerpf(0.3, 1.0, t)
		alpha = t * 0.85
	elif age > total - fade_dur:
		sc = 1.0
		alpha = lerpf(0.85, 0.0, (age - (total - fade_dur)) / fade_dur)
	else:
		sc = 1.0
		alpha = 0.85
	if alpha <= 0.01:
		return
	var ring_r: float = 90.0 * sc
	var spin: float = age * (TAU / 18.0)
	var center: Vector2 = _foot_anchor
	# 지면 평면 (z=0) 에서 spin 회전 + 위에서 본 시각 (y scale 0.31).
	# draw_set_transform 은 scale → rotate → translate 순서라 회전 시 타원 모양이 흔들림.
	# 대신 각 점을 직접 계산: ring 평면에서 각도 + spin → vec2(cos, sin) * r → y 만 0.31 압축.
	_draw_ring_circle(center, ring_r, spin, 0.31, 64, Color(COL_P2_RIM.r, COL_P2_RIM.g, COL_P2_RIM.b, alpha * 0.85), 1.4)
	_draw_ring_circle(center, ring_r * 0.84, spin, 0.31, 48, Color(COL_BRASS.r, COL_BRASS.g, COL_BRASS.b, alpha * 0.55), 1.0)
	_draw_ring_circle(center, ring_r * 0.58, spin, 0.31, 32, Color(COL_P2_RIM.r, COL_P2_RIM.g, COL_P2_RIM.b, alpha * 0.7), 1.0)
	# 8개 outer tick (회전 평면 위 점, y 압축)
	for i in 8:
		var a: float = float(i) * TAU / 8.0 + spin
		var p0 := Vector2(cos(a) * (ring_r - 10.0), sin(a) * (ring_r - 10.0) * 0.31)
		var p1 := Vector2(cos(a) * ring_r, sin(a) * ring_r * 0.31)
		draw_line(center + p0, center + p1, Color(COL_BRASS.r, COL_BRASS.g, COL_BRASS.b, alpha * 0.7), 1.2)

# 지면 ring polyline — 각 점이 평면 위 각도 (spin 포함) 기준, y 만 squash 로 위에서 본 시각.
func _draw_ring_circle(center: Vector2, r: float, spin: float, y_squash: float, n: int, col: Color, width: float) -> void:
	var pts := PackedVector2Array()
	for i in n + 1:
		var a: float = float(i) / float(n) * TAU + spin
		pts.push_back(center + Vector2(cos(a) * r, sin(a) * r * y_squash))
	draw_polyline(pts, col, width)

# ── inward motes — 사방에서 몬스터로 빨려듦 (radial_accel 음수만, 초기 속도 0) ──
func _spawn_inward_motes() -> void:
	# 초기 velocity 0 — direction RIGHT/spread 0 는 모든 입자에 우측 속도를 주어 편향 발생.
	# sphere emission + radial_accel 음수만으로 사방→중심 흡수 매핑.
	var motes := _Helpers.make_emitter({
		"count": int(60 * _scale()), "lifetime": 0.7, "color": COL_BRASS,
		"speed_min": 0.0, "speed_max": 0.0,
		"direction": Vector2.UP, "spread": 0.0,
		"emission_shape": "sphere", "emission_radius": 220.0,
		"radial_accel_min": -380.0, "radial_accel_max": -240.0,
		"size_min": 1.0, "size_max": 2.2,
		"additive": true,
		"one_shot": false, "explosiveness": 0.0,
		"start_alpha": 0.95, "mid_alpha": 0.55, "end_alpha": 0.0,
	})
	motes.local_coords = true  # emission radius 가 emitter 좌표계 기준
	motes.position = _target
	add_child(motes)
	get_tree().create_timer(CHARGE_TIME).timeout.connect(func() -> void:
		if is_instance_valid(motes): motes.emitting = false)

# ── BURST particles — 사방 80 motes (가산) + ground dust 32 ──
func _spawn_burst_particles() -> void:
	var burst := _Helpers.make_emitter({
		"count": _pcount(80), "lifetime": 1.3, "color": COL_P2_HOT,
		"speed_min": 180.0, "speed_max": 540.0,
		"direction": Vector2.UP, "spread": 180.0,
		"gravity": 12.6,
		"size_min": 1.2, "size_max": 2.7,
		"additive": true,
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	burst.position = _target
	add_child(burst)
	var dust := _Helpers.make_emitter({
		"count": _pcount(32), "lifetime": 1.7, "color": COL_P2_HOT,
		"speed_min": 96.0, "speed_max": 210.0,
		"direction": Vector2.UP, "spread": 100.0,
		"gravity": -10.8,
		"size_min": 16.0, "size_max": 30.0,
		"additive": false,
		"start_alpha": 0.34, "mid_alpha": 0.17, "end_alpha": 0.0,
	})
	dust.position = _foot_anchor
	add_child(dust)

# ── embers — HOLD 동안 천천히 위로 작은 ember ──
func _spawn_embers() -> void:
	var embers := _Helpers.make_emitter({
		"count": int(15 * _scale()), "lifetime": 1.8, "color": COL_ORANGE,
		"speed_min": 30.0, "speed_max": 60.0,
		"direction": Vector2.UP, "spread": 18.0,
		"gravity": 0.0,
		"size_min": 1.0, "size_max": 2.0,
		"additive": true,
		"emission_shape": "box", "emission_box": Vector2(80.0, 4.0),
		"one_shot": false, "explosiveness": 0.0,
		"start_alpha": 0.7, "mid_alpha": 0.4, "end_alpha": 0.0,
	})
	embers.position = _foot_anchor
	add_child(embers)
	get_tree().create_timer(HOLD_TIME).timeout.connect(func() -> void:
		if is_instance_valid(embers): embers.emitting = false)
