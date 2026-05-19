# scenes/vfx/counter.gd
# 카운터 VFX — ui_sample/vfx/Counter VFX.html 재현.
# play(caster_pos, target_pos) — caster = 영웅, target = 적.
# set_is_major(true) 시 charge_up 무효 변형: 더 큰 효과 + 화면 frozen vignette + 두꺼운 streak.
# 시퀀스: parry flash (영웅 측) → streak (영웅→적) → enemy hit burst (적 측) → fade.
# screen_effect = parry flash 시점 (충돌 순간).
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


const COL_HOT          := Color(1.0, 1.0, 1.0)
const COL_COUNTER      := Color(0.85, 0.29, 0.31)         # #d94a50 — counter crimson
const COL_COUNTER_HOT  := Color(1.0, 0.42, 0.29)          # #ff6c4a
const COL_COUNTER_DEEP := Color(0.42, 0.078, 0.094)       # #6b1418
const COL_BRASS        := Color(0.909, 0.784, 0.470)      # #e8c878
const COL_BRASS_HOT    := Color(1.0, 0.953, 0.752)        # #fff3c0
const COL_STEEL        := Color(0.784, 0.831, 0.862)      # #c8d4dc

const PARRY_DELAY    := 0.08    # 영웅 측 charge → parry flash
const IMPACT_DELAY   := PARRY_DELAY  # screen_effect 시점 (parry flash)
const STRIKE_DELAY   := 0.18    # parry 후 영웅→적 베기
const HIT_DELAY      := 0.30    # 영웅→적 streak 도달 시점 (parry + travel)
const HOLD_TIME      := 0.4
const FADE_TIME      := 0.35
const PARRY_R        := 55.0
const SHOCK_R        := 30.0
# major (charge 보스 무효) 모드 — 시간 감속 + 흑백 postprocess
const MAJOR_TIME_SCALE   := 0.35  # 슬로모 배율
const MAJOR_FREEZE_TIME  := 0.6   # real time — 슬로모 지속
const DESATURATE_SHADER  := preload("res://assets/shaders/desaturate.gdshader")

signal screen_effect

var _caster_pos := Vector2.ZERO  # 영웅
var _target_pos := Vector2.ZERO  # 적
var _is_major: bool = false
var _age := -1.0
var _impact_emitted := false
var _hit_burst_spawned: bool = false
var _freeze_started: bool = false
var _freeze_ended: bool = false
var _particles: Array = []
var _desat_overlay: ColorRect       # 흑백 postprocess overlay (hint_screen_texture)

func set_is_major(v: bool) -> void:
	_is_major = v

func play(caster_pos: Vector2, target_pos: Vector2) -> void:
	_caster_pos = caster_pos
	_target_pos = target_pos
	_age = 0.0
	set_process(true)
	await get_tree().create_timer(HIT_DELAY + HOLD_TIME + FADE_TIME + 0.1).timeout
	if is_inside_tree():
		queue_free()

func _ready() -> void:
	set_process(false)
	process_mode = Node.PROCESS_MODE_ALWAYS  # time_scale 변경 중에도 진행

func _exit_tree() -> void:
	# 안전: VFX 가 어떻게 사라지든 time_scale 복원
	if _freeze_started and not _freeze_ended:
		Engine.time_scale = 1.0
		_freeze_ended = true

func _start_major_freeze() -> void:
	Engine.time_scale = MAJOR_TIME_SCALE
	# real time 0.6s 후 자동 복귀 (process_always=true, ignore_time_scale=true)
	var t: SceneTreeTimer = get_tree().create_timer(MAJOR_FREEZE_TIME, true, false, true)
	t.timeout.connect(_end_major_freeze)
	# 흑백 postprocess overlay — ColorRect + desaturate shader (hint_screen_texture 자체 캡처)
	var vp_size: Vector2 = get_viewport_rect().size
	_desat_overlay = ColorRect.new()
	_desat_overlay.size = vp_size
	_desat_overlay.position = Vector2.ZERO
	_desat_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = DESATURATE_SHADER
	mat.set_shader_parameter("strength", 1.0)
	mat.set_shader_parameter("tint", Color(0.85, 0.85, 0.88, 1.0))
	_desat_overlay.material = mat
	add_child(_desat_overlay)

func _end_major_freeze() -> void:
	if _freeze_ended:
		return
	_freeze_ended = true
	Engine.time_scale = 1.0

func _process(delta: float) -> void:
	_age += delta
	# IMPACT — parry flash 시점 screen_effect
	if not _impact_emitted and _age >= IMPACT_DELAY:
		_impact_emitted = true
		screen_effect.emit()
		_spawn_parry_flash_burst()
		# major 변형 — 시간 감속 + 어두운 overlay + 큰 텍스트 등장
		if _is_major and not _freeze_started:
			_freeze_started = true
			_start_major_freeze()
	# HIT — 적 측 폭발
	if not _hit_burst_spawned and _age >= HIT_DELAY:
		_hit_burst_spawned = true
		_spawn_enemy_hit_burst()
	# 파티클 갱신
	var alive: Array = []
	for p in _particles:
		p["life"] += delta
		if p["life"] >= p["max_life"]:
			continue
		p["pos"] += p["vel"] * delta
		p["vel"].y += p.get("grav", 0.0) * delta
		p["vel"] *= 0.985
		alive.append(p)
	_particles = alive
	queue_redraw()

func _global_alpha() -> float:
	var end_phase: float = HIT_DELAY + HOLD_TIME
	if _age < end_phase:
		return clampf(_age / 0.05, 0.0, 1.0)
	var t: float = (_age - end_phase) / FADE_TIME
	return clampf(1.0 - t, 0.0, 1.0)

func _spawn_parry_flash_burst() -> void:
	# 영웅 측에서 brass spark burst (parry 충돌 표현)
	var cnt: int = _pcount(20 if not _is_major else 36)
	for _i in range(cnt):
		var a: float = randf() * TAU
		var sp: float = 80.0 + randf() * 160.0
		_particles.append({
			"pos": _caster_pos, "vel": Vector2(cos(a), sin(a)) * sp,
			"life": 0.0, "max_life": 0.45 + randf() * 0.35,
			"size": 1.4 + randf() * 1.4, "kind": "brass_spark", "grav": 50.0,
		})

func _spawn_enemy_hit_burst() -> void:
	# 적 측 폭발 — counter crimson sparks (반사 데미지 시각화)
	var cnt: int = _pcount(28 if not _is_major else 48)
	for _i in range(cnt):
		var a: float = randf() * TAU
		var sp: float = 100.0 + randf() * 200.0
		_particles.append({
			"pos": _target_pos, "vel": Vector2(cos(a), sin(a)) * sp,
			"life": 0.0, "max_life": 0.55 + randf() * 0.45,
			"size": 1.4 + randf() * 1.6, "kind": "crimson_spark", "grav": 80.0,
		})
	# steel chip (major 만) — 무거운 충돌 표현
	if _is_major:
		var sc_cnt: int = _pcount(16)
		for _i in range(sc_cnt):
			var a2: float = randf() * TAU
			var sp2: float = 60.0 + randf() * 140.0
			_particles.append({
				"pos": _target_pos, "vel": Vector2(cos(a2), sin(a2)) * sp2,
				"life": 0.0, "max_life": 0.7 + randf() * 0.5,
				"size": 1.6 + randf() * 1.4, "kind": "steel_chip", "grav": 120.0,
			})

func _draw() -> void:
	var ga: float = _global_alpha()
	if ga <= 0.0:
		return
	# major: 흑백 postprocess overlay alpha 동기화 (강도 fade in/out)
	if _is_major and _impact_emitted and _desat_overlay != null and is_instance_valid(_desat_overlay):
		var fade_in_t: float = clampf((_age - IMPACT_DELAY) / 0.1, 0.0, 1.0)
		var fade_out_t: float = clampf((_age - (HIT_DELAY + 0.15)) / 0.3, 0.0, 1.0)
		var strength: float = fade_in_t * (1.0 - fade_out_t)
		var mat := _desat_overlay.material as ShaderMaterial
		if mat != null:
			mat.set_shader_parameter("strength", strength)
		# 0 되면 overlay 자체 숨김
		_desat_overlay.visible = strength > 0.01
	# 1) parry flash — 영웅 측 (IMPACT_DELAY ~ STRIKE_DELAY)
	if _age >= IMPACT_DELAY:
		var ft: float = clampf((_age - IMPACT_DELAY) / 0.2, 0.0, 1.0)
		var fa: float = (1.0 - ft) * ga
		var fr: float = PARRY_R * (1.0 + ft * 1.6) * (1.5 if _is_major else 1.0)
		# 외곽 (brass)
		draw_circle(_caster_pos, fr,
			Color(COL_BRASS.r, COL_BRASS.g, COL_BRASS.b, fa * 0.35))
		# 코어 (hot)
		draw_circle(_caster_pos, fr * 0.45,
			Color(COL_BRASS_HOT.r, COL_BRASS_HOT.g, COL_BRASS_HOT.b, fa * 0.85))
		# 중심 (흰)
		draw_circle(_caster_pos, fr * 0.20,
			Color(COL_HOT.r, COL_HOT.g, COL_HOT.b, fa))
	# 2) shock ring (수평) — 영웅 발치
	if _age >= IMPACT_DELAY and _age < IMPACT_DELAY + 0.45:
		var st: float = (_age - IMPACT_DELAY) / 0.45
		var sa: float = (1.0 - st) * ga * 0.75
		var sr: float = SHOCK_R + 180.0 * st * (1.4 if _is_major else 1.0)
		_draw_squashed_ring(_caster_pos + Vector2(0.0, 70.0), sr, 0.4,
			Color(COL_COUNTER_HOT.r, COL_COUNTER_HOT.g, COL_COUNTER_HOT.b, sa), 2.5)
	# 3) counter streak — 영웅 → 적 가로 베기 (STRIKE_DELAY ~ HIT_DELAY)
	if _age >= STRIKE_DELAY and _age < HIT_DELAY + 0.15:
		if _is_major:
			_draw_major_curved_streaks(ga)
		else:
			_draw_counter_streak(ga)
	# 4) hit flash + slash — 적 측 (HIT_DELAY ~ +0.25)
	if _age >= HIT_DELAY and _age < HIT_DELAY + 0.3:
		var ht: float = (_age - HIT_DELAY) / 0.3
		var ha: float = (1.0 - ht) * ga
		var hr: float = 40.0 + 80.0 * ht * (1.5 if _is_major else 1.0)
		# 외곽 crimson
		draw_circle(_target_pos, hr,
			Color(COL_COUNTER.r, COL_COUNTER.g, COL_COUNTER.b, ha * 0.45))
		draw_circle(_target_pos, hr * 0.5,
			Color(COL_COUNTER_HOT.r, COL_COUNTER_HOT.g, COL_COUNTER_HOT.b, ha * 0.85))
		# 베기 슬래시 라인 2~3개 (적 위치 가로지름)
		_draw_slash_lines(_target_pos, ha)
	# 5) 파티클
	_draw_particles(ga)

func _draw_major_curved_streaks(ga: float) -> void:
	# major 전용 — 곡선 3가닥이 영웅에서 적까지 다른 경로로 휘어 날아감.
	# 위로 크게 휨 / 아래로 휨 / 옆으로 비스듬히 휨 — ctrl 점 다양.
	var t: float = clampf((_age - STRIKE_DELAY) / (HIT_DELAY - STRIKE_DELAY), 0.0, 1.0)
	var sa: float = ga * (1.0 - clampf((_age - HIT_DELAY) / 0.2, 0.0, 1.0))
	var dir: Vector2 = _target_pos - _caster_pos
	var perp: Vector2 = Vector2(-dir.y, dir.x).normalized()
	var ctrl_offsets := [
		perp * -180.0,                                      # 위로 크게 휨
		perp * 110.0 + Vector2(0.0, 30.0),                  # 아래로 휨
		perp * -60.0 + (dir.normalized() * 80.0),           # 옆으로 비스듬
	]
	for i in range(ctrl_offsets.size()):
		var ctrl: Vector2 = (_caster_pos + _target_pos) * 0.5 + ctrl_offsets[i]
		_draw_bezier_streak(_caster_pos, ctrl, _target_pos, t, sa, 9.0)

func _draw_bezier_streak(p0: Vector2, p1: Vector2, p2: Vector2, t: float, alpha: float, width: float) -> void:
	# Bezier 2차 곡선 — t 진행도까지만 그림 (trail 도 길게).
	var segs: int = 18
	var end_seg: int = int(round(float(segs) * t))
	if end_seg < 1:
		return
	var trail_start: int = max(0, end_seg - 9)  # 끝에서 9 세그먼트 길이
	var pts := PackedVector2Array()
	for i in range(trail_start, end_seg + 1):
		var u: float = float(i) / float(segs)
		pts.append(p0.bezier_interpolate(p1, p1, p2, u))
	if pts.size() < 2:
		return
	# 외곽 deep crimson (두꺼움)
	for i in range(pts.size() - 1):
		draw_line(pts[i], pts[i + 1],
			Color(COL_COUNTER_DEEP.r, COL_COUNTER_DEEP.g, COL_COUNTER_DEEP.b, alpha * 0.85), width, true)
	# 중간 hot crimson
	for i in range(pts.size() - 1):
		draw_line(pts[i], pts[i + 1],
			Color(COL_COUNTER_HOT.r, COL_COUNTER_HOT.g, COL_COUNTER_HOT.b, alpha), width * 0.45, true)
	# 코어 흰색
	for i in range(pts.size() - 1):
		draw_line(pts[i], pts[i + 1],
			Color(COL_HOT.r, COL_HOT.g, COL_HOT.b, alpha * 0.85), width * 0.18, true)

func _draw_counter_streak(ga: float) -> void:
	# 영웅 → 적 streak — STRIKE_DELAY 시 영웅에서, HIT_DELAY 시 적에 도달
	var t: float = clampf((_age - STRIKE_DELAY) / (HIT_DELAY - STRIKE_DELAY), 0.0, 1.0)
	var w: float = 6.0 if not _is_major else 11.0
	var sa: float = ga * (1.0 - clampf((_age - HIT_DELAY) / 0.15, 0.0, 1.0))
	# 후미 (영웅 측에서 짧게 시작)
	var trail_start_t: float = maxf(0.0, t - 0.6)
	var p_start: Vector2 = _caster_pos.lerp(_target_pos, trail_start_t)
	var p_end: Vector2 = _caster_pos.lerp(_target_pos, t)
	# 외곽 deep crimson
	draw_line(p_start, p_end,
		Color(COL_COUNTER_DEEP.r, COL_COUNTER_DEEP.g, COL_COUNTER_DEEP.b, sa * 0.85), w, true)
	# 코어 hot
	draw_line(p_start, p_end,
		Color(COL_COUNTER_HOT.r, COL_COUNTER_HOT.g, COL_COUNTER_HOT.b, sa), w * 0.45, true)
	# 흰 코어 (얇음)
	draw_line(p_start, p_end,
		Color(COL_HOT.r, COL_HOT.g, COL_HOT.b, sa * 0.85), w * 0.18, true)

func _draw_slash_lines(c: Vector2, alpha: float) -> void:
	var lines := 2 if not _is_major else 3
	var span: float = 90.0 if not _is_major else 130.0
	for i in range(lines):
		var ang: float = -PI * 0.25 + float(i) * (PI * 0.5 / float(max(lines - 1, 1)))
		var d: Vector2 = Vector2(cos(ang), sin(ang)) * span
		var s: Vector2 = c - d * 0.5
		var e: Vector2 = c + d * 0.5
		draw_line(s, e,
			Color(COL_HOT.r, COL_HOT.g, COL_HOT.b, alpha * 0.95), 2.6, true)
		draw_line(s, e,
			Color(COL_COUNTER_HOT.r, COL_COUNTER_HOT.g, COL_COUNTER_HOT.b, alpha * 0.55), 5.0, true)

func _draw_squashed_ring(c: Vector2, radius: float, squash: float, col: Color, width: float) -> void:
	var seg: int = 28
	var pts := PackedVector2Array()
	for i in range(seg + 1):
		var ang: float = TAU * float(i) / float(seg)
		pts.append(c + Vector2(cos(ang) * radius, sin(ang) * radius * squash))
	for i in range(pts.size() - 1):
		draw_line(pts[i], pts[i + 1], col, width, true)

func _draw_particles(ga: float) -> void:
	for p in _particles:
		var k: float = p["life"] / p["max_life"]
		var a: float = (1.0 - k) * ga
		var pr: float = p["size"]
		match p["kind"]:
			"brass_spark":
				draw_circle(p["pos"], pr,
					Color(1.0, 0.90 - 0.16 * k, 0.62 - 0.31 * k, a))
				draw_rect(Rect2(p["pos"].x - pr * 2.0, p["pos"].y - 0.3, pr * 4.0, 0.6),
					Color(1.0, 0.90 - 0.16 * k, 0.62 - 0.31 * k, a))
			"crimson_spark":
				draw_circle(p["pos"], pr,
					Color(1.0, 0.43 - 0.16 * k, 0.31 - 0.10 * k, a))
				draw_rect(Rect2(p["pos"].x - pr * 2.0, p["pos"].y - 0.3, pr * 4.0, 0.6),
					Color(1.0, 0.43 - 0.16 * k, 0.31 - 0.10 * k, a))
			"steel_chip":
				draw_circle(p["pos"], pr,
					Color(0.85, 0.88 - 0.10 * k, 0.92 - 0.08 * k, a))
