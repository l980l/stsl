# scenes/vfx/slow_debuff_gpu.gd
# 둔화 디버프 GPU 하이브리드 — slow_debuff.gd 상속.
# 원본 _draw_*_pass 한 줄씩 매칭:
#   - mist: ground_layer (additive=true), Color(COL_MID, a) where a=(1-k)×0.4×ga, r=size×(1+k×1.3)
#   - drip: glow_layer (additive=true), Color(COL_MID, 0.92×a), 세로 ellipse (cos×0.65, sin×1.4)
#   - bubble: glow_layer (additive=true), 내부 Color(COL_MID, 0.3×a) + 외곽 ring Color(COL_HOT, 0.65×a)
#   - spiral: glow_layer (additive=true), 외곽→target 수렴 — GPU 표준 파티클 불가 → CPU 유지
extends "res://scenes/vfx/slow_debuff.gd"

const _Helpers = preload("res://scenes/vfx/gpu_particle_helpers.gd")

var _peak_made: bool = false
var _gpu_amb_drip: GPUParticles2D
var _gpu_amb_mist: GPUParticles2D
var _gpu_amb_bubble: GPUParticles2D
var _amb_made: bool = false

func _process(delta: float) -> void:
	super._process(delta)
	var ga: float = _global_alpha()
	for child in get_children():
		if child is GPUParticles2D:
			child.modulate.a = ga

# 시간 따라 크기 확장 Curve (mist 의 r = size × (1 + k × 1.3))
static func _mist_scale_curve() -> Curve:
	var c := Curve.new()
	c.add_point(Vector2(0.0, 1.0))
	c.add_point(Vector2(1.0, 2.3))
	return c

# _spawn_peak_burst: spiral 20 CPU (외곽→수렴) + mist 14 GPU
func _spawn_peak_burst() -> void:
	if _peak_made:
		return
	_peak_made = true
	var foot: Vector2 = _foot_pos()
	# mist 14 (ground additive, COL_MID, alpha (1-k)×0.4, 크기 1→2.3배 확장)
	# 원본 vx = cos(a)×sp, vy = sin(a)×sp×0.2 — x:y = 2.3:1 가로 위주.
	# damping 60 (CPU exponential 0.992^60 ≈ 1초 후 0.62× 매칭, linear 근사).
	var mist := _Helpers.make_emitter({
		"count": _pcount(14), "lifetime": 1.5, "color": COL_HOT,
		"speed_min": 40.0, "speed_max": 120.0,
		"direction": Vector2(1.0, -0.3).normalized(), "spread": 60.0,  # 가로 위주 + 위쪽, 아래로 안 감
		"gravity": -18.0, "damping": 0.0,
		"size_min": 12.0, "size_max": 24.0,
		"scale_curve": _mist_scale_curve(),
		"lifetime_randomness": 0.2,
		"start_alpha": 0.4, "mid_alpha": 0.2, "end_alpha": 0.0,
	})
	mist.position = foot
	add_child(mist)
	# 좌측 7 입자 별도 emitter (direction RIGHT 만으론 좌측 안 감, 양방향 합성)
	var mist_l := _Helpers.make_emitter({
		"count": _pcount(7), "lifetime": 1.5, "color": COL_HOT,
		"speed_min": 40.0, "speed_max": 120.0,
		"direction": Vector2(-1.0, -0.3).normalized(), "spread": 60.0,
		"gravity": -18.0, "damping": 0.0,
		"size_min": 12.0, "size_max": 24.0,
		"scale_curve": _mist_scale_curve(),
		"lifetime_randomness": 0.2,
		"start_alpha": 0.4, "mid_alpha": 0.2, "end_alpha": 0.0,
	})
	mist_l.position = foot
	add_child(mist_l)
	# spiral 20 — CPU 위임 (GPU sphere/orbit 으로는 가로 긴 타원 궤도 표현 한계 — local scale 트릭이
	# mote_halo_tex 도 함께 압축해 시각 어색). super 와 동일 spawn 으로 _particles 에 직접 append.
	for _i in range(_pcount(20)):
		var ang := randf() * TAU
		var dist := 110.0 + randf() * 50.0
		_particles.append({
			"pos": Vector2(_target.x + cos(ang) * dist, _target.y + sin(ang) * dist * 0.4 - 30.0),
			"vel": Vector2.ZERO,
			"life": 0.0,
			"max_life": 0.8 + randf() * 0.4,
			"size": 1.4 + randf() * 1.2,
			"kind": "spiral",
			"start_ang": ang,
			"start_dist": dist,
		})

# _spawn_ambient: drip + mist + bubble GPU continuous
func _spawn_ambient() -> void:
	if _amb_made:
		return
	_amb_made = true
	var foot: Vector2 = _foot_pos()
	# drip: 0.35/frame × 60 × lifetime 1.0 ≈ 21 동시. glow additive, COL_MID, alpha 0.92.
	# 원본 세로 ellipse (cos×0.65, sin×1.4) — GPU 단순 원으로 근사.
	_gpu_amb_drip = _Helpers.make_emitter({
		"count": int(21 * _scale()), "lifetime": 1.0, "color": COL_MID,
		"speed_min": 12.0, "speed_max": 36.0,  # 원본 vel 0.4~0.8 × PSPEED 60
		"direction": Vector2.DOWN, "spread": 12.0,
		"gravity": 108.0, "damping": 3.0,  # 원본 grav 0.03 × 3600 (PSPEED²)
		"size_min": 2.4, "size_max": 3.8,
		"emission_shape": "box", "emission_box": Vector2(70.0, 8.0),
		"one_shot": false, "explosiveness": 0.0,
		"start_alpha": 0.92, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	_gpu_amb_drip.position = foot + Vector2(0.0, -18.0)
	add_child(_gpu_amb_drip)
	# mist ambient: 0.5/frame × 60 × lifetime 1.7 ≈ 51 동시. ground additive, COL_MID, alpha 0.4.
	# damping 60 + lifetime_randomness 0.2 — peak 와 동일 패턴.
	_gpu_amb_mist = _Helpers.make_emitter({
		"count": int(51 * _scale()), "lifetime": 1.7, "color": COL_HOT,
		"speed_min": 15.0, "speed_max": 35.0,
		"direction": Vector2.UP, "spread": 60.0,  # 위쪽 ±30° — 아래로 안 감
		"gravity": -10.8, "damping": 0.0,
		"size_min": 12.0, "size_max": 22.0,
		"scale_curve": _mist_scale_curve(),
		"lifetime_randomness": 0.2,
		"emission_shape": "box", "emission_box": Vector2(80.0, 4.0),
		"one_shot": false, "explosiveness": 0.0,
		"start_alpha": 0.4, "mid_alpha": 0.2, "end_alpha": 0.0,
	})
	_gpu_amb_mist.position = foot + Vector2(0.0, -2.0)
	add_child(_gpu_amb_mist)
	# bubble: 0.2/frame × 60 × lifetime 0.65 ≈ 8 동시. glow additive.
	# 원본 = 내부 COL_MID alpha 0.3 + 외곽 ring COL_HOT alpha 0.65. 2 색 합성 → 1 입자 매칭 불가.
	# 가장 눈에 띄는 외곽 ring (COL_HOT, 0.65) 만 살림.
	_gpu_amb_bubble = _Helpers.make_emitter({
		"count": int(8 * _scale()), "lifetime": 0.65, "color": COL_HOT,
		"speed_min": 12.0, "speed_max": 30.0,
		"direction": Vector2.UP, "spread": 12.0,
		"gravity": 0.0, "damping": 3.0,
		"size_min": 3.0, "size_max": 5.0,
		"emission_shape": "box", "emission_box": Vector2(60.0, 2.0),
		"one_shot": false, "explosiveness": 0.0,
		"start_alpha": 0.65, "mid_alpha": 0.4, "end_alpha": 0.0,
	})
	_gpu_amb_bubble.position = foot + Vector2(0.0, -2.0)
	add_child(_gpu_amb_bubble)
	get_tree().create_timer(DEBUFF_TIME).timeout.connect(func() -> void:
		if is_instance_valid(_gpu_amb_drip): _gpu_amb_drip.emitting = false
		if is_instance_valid(_gpu_amb_mist): _gpu_amb_mist.emitting = false
		if is_instance_valid(_gpu_amb_bubble): _gpu_amb_bubble.emitting = false)
