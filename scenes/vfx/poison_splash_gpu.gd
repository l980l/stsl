# scenes/vfx/poison_splash_gpu.gd
# 독 폭발 GPU 하이브리드 — poison_splash.gd 정확 매핑.
# trail (drip+gas) / splash (drip+gas+spark) / ambient (gas+bubble+drip) → GPU.
# 차지 오브, 플라스크 회전, 코르크, 헤일로, 해골, 웅덩이 CPU.
extends "res://scenes/vfx/poison_splash.gd"

const _Helpers = preload("res://scenes/vfx/gpu_particle_helpers.gd")
# COL_GAS / COL_SPARK / COL_DRIP 등 super 상수 그대로 사용 (원본 색).

# trail emitters
var _gpu_trail_drip: GPUParticles2D
var _gpu_trail_gas: GPUParticles2D
var _trail_made: bool = false

# splash one-time
var _splash_made: bool = false

# ambient emitters (POISON_TIME 동안)
var _gpu_amb_gas: GPUParticles2D
var _gpu_amb_bubble: GPUParticles2D
var _gpu_amb_drip: GPUParticles2D
var _amb_made: bool = false

# ── trail (비행 중 매 프레임) ──
# 원본:
#  - drip: 1/frame. pos = trail + ±3, vel (±0.2, 0.2~0.6)*60, lifetime 0.7~1.2, r 4~9, grav 0.04 (down)
#  - gas: 0.7 확률 × 60 = 42/s, pos = trail + ±2, vel (±0.15, -0.2~-0.5)*60, lifetime 0.9~1.4, r 8~16, grav -0.005 (up gentle)
func _spawn_trail(pos: Vector2) -> void:
	if not _trail_made:
		_trail_made = true
		# drip 60/s × lifetime 0.95 ≈ 57 동시. 떨어짐 (vel.y +).
		_gpu_trail_drip = _Helpers.make_emitter({
			"count": int(57 * _scale()), "lifetime": 0.95,
			"color": Color.WHITE,
			"speed_min": 12.0, "speed_max": 36.0,
			"direction": Vector2.DOWN, "spread": 25.0,
			"gravity": 144.0, "damping": 3.0,  # 0.04 * 60²
			"size_min": 4.0, "size_max": 9.0,
			"size_base": 23.0,
		"texture": _Helpers.drip_tex(),
		"additive": false,
			"emission_shape": "box", "emission_box": Vector2(3.0, 3.0),
			"one_shot": false, "explosiveness": 0.0,
			"start_alpha": 0.9, "mid_alpha": 0.45, "end_alpha": 0.0,
		})
		add_child(_gpu_trail_drip)
		# gas 42/s × lifetime 1.15 ≈ 48 동시. 위로 살짝.
		_gpu_trail_gas = _Helpers.make_emitter({
			"count": int(48 * _scale()), "lifetime": 1.15,
			"color": COL_GAS,
			"speed_min": 12.0, "speed_max": 30.0,
			"direction": Vector2.UP, "spread": 25.0,
			"gravity": -18.0, "damping": 3.0,  # -0.005 * 60²
			"size_min": 8.0, "size_max": 16.0,
			"additive": false,
			"emission_shape": "box", "emission_box": Vector2(2.0, 2.0),
			"one_shot": false, "explosiveness": 0.0,
			"start_alpha": 0.4, "mid_alpha": 0.2, "end_alpha": 0.0,
		})
		add_child(_gpu_trail_gas)
	if is_instance_valid(_gpu_trail_drip):
		_gpu_trail_drip.position = pos
		_gpu_trail_gas.position = pos

# ── splash (one-time burst) ──
# 원본:
#  - drip 40: vel (cos*sp, sin*sp*0.6 - 1.2), sp 1~5 → speed 60~300 + y bias -72
#    lifetime 0.8~1.4, r 3~8, grav 0.06 (down strong)
#  - gas 50: vel (cos*sp, sin*sp*0.6 - 0.4), sp 0.6~3.1 → speed 36~186 + y bias -24
#    lifetime 1.4~2.3, r 18~38, grav -0.008
#  - spark 24: vel (cos*sp, sin*sp - 0.6), sp 1~4 → speed 60~240 + y bias -36
#    lifetime 1.0~1.7, r 1.4~2.6, grav 0.0
func _spawn_splash(pos: Vector2) -> void:
	if _splash_made:
		return
	_splash_made = true
	# trail off
	if is_instance_valid(_gpu_trail_drip): _gpu_trail_drip.emitting = false
	if is_instance_valid(_gpu_trail_gas): _gpu_trail_gas.emitting = false
	# drip 40 burst
	var drip := _Helpers.make_emitter({
		"count": _pcount(40), "lifetime": 1.1, "color": Color.WHITE,
		"speed_min": 60.0, "speed_max": 300.0,
		"direction": Vector2.UP, "spread": 180.0,
		"gravity": 216.0, "damping": 3.0,  # 0.06 * 60²
		"size_min": 3.0, "size_max": 8.0,
		"size_base": 23.0,
		"texture": _Helpers.drip_tex(),
		"additive": false,
		"start_alpha": 0.9, "mid_alpha": 0.45, "end_alpha": 0.0,
	})
	drip.position = pos
	add_child(drip)
	# gas 50 burst — 사방 퍼지는 큰 안개. size 2배 + 더 밝게 (사용자 피드백).
	var gas := _Helpers.make_emitter({
		"count": _pcount(50), "lifetime": 1.85, "color": COL_GAS,
		"speed_min": 36.0, "speed_max": 186.0,
		"direction": Vector2.UP, "spread": 180.0,
		"gravity": -28.8, "damping": 3.0,
		"size_min": 36.0, "size_max": 76.0,
		"additive": false,
		"start_alpha": 0.7, "mid_alpha": 0.4, "end_alpha": 0.0,
	})
	gas.position = pos
	add_child(gas)
	# spark 24 — 불씨 (가산)
	var spark := _Helpers.make_emitter({
		"count": _pcount(24), "lifetime": 1.35, "color": COL_SPARK,
		"speed_min": 60.0, "speed_max": 240.0,
		"direction": Vector2.UP, "spread": 180.0,
		"gravity": 0.0, "damping": 3.0,
		"size_min": 1.4, "size_max": 2.6,
		"texture": _Helpers.circle_tex(),
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	spark.position = pos
	add_child(spark)

# ── ambient (POISON_TIME 동안 매 프레임) ──
# 원본:
#  - gas 0.7 확률 × 60 = 42/s, pos = target + (±35, 25~55), vel (±0.15, -0.4~-0.9)*60, lifetime 1.6~2.4, r 12~24, grav -0.005
#  - bubble 0.3 확률 × 60 = 18/s, pos = target + (±30, 40~70), vel (±0.1, -0.6~-1.3)*60, lifetime 0.9~1.4, r 3~7, grav 0.0
#  - drip 0.2 확률 × 60 = 12/s, pos = target + (±30, ±15), vel (±0.1, 0.5~0.9)*60, lifetime 0.9~1.3, r 2.4~4.2, grav 0.05
func _spawn_ambient() -> void:
	if _amb_made:
		return
	_amb_made = true
	# gas 42/s × lifetime 2.0 ≈ 84 동시. 위쪽으로.
	_gpu_amb_gas = _Helpers.make_emitter({
		"count": int(84 * _scale()), "lifetime": 2.0, "color": COL_GAS,
		"speed_min": 24.0, "speed_max": 54.0,
		"direction": Vector2.UP, "spread": 18.0,
		"gravity": -18.0, "damping": 3.0,
		"size_min": 12.0, "size_max": 24.0,
		"additive": false,
		"emission_shape": "box", "emission_box": Vector2(35.0, 15.0),
		"one_shot": false, "explosiveness": 0.0,
		"start_alpha": 0.4, "mid_alpha": 0.2, "end_alpha": 0.0,
	})
	_gpu_amb_gas.position = _target + Vector2(0.0, 40.0)
	add_child(_gpu_amb_gas)
	# bubble 18/s × lifetime 1.15 ≈ 21 동시. 위로 빠르게.
	_gpu_amb_bubble = _Helpers.make_emitter({
		"count": int(21 * _scale()), "lifetime": 1.15, "color": Color.WHITE,  # bubble_tex 자체 색
		"speed_min": 36.0, "speed_max": 78.0,
		"direction": Vector2.UP, "spread": 12.0,
		"gravity": 0.0, "damping": 3.0,
		"size_min": 3.0, "size_max": 7.0,
		"size_base": 28.0,  # bubble_tex 외곽 반경
		"texture": _Helpers.bubble_tex(),
		"additive": false,
		"emission_shape": "box", "emission_box": Vector2(30.0, 15.0),
		"one_shot": false, "explosiveness": 0.0,
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	_gpu_amb_bubble.position = _target + Vector2(0.0, 55.0)
	add_child(_gpu_amb_bubble)
	# drip 12/s × lifetime 1.1 ≈ 13 동시. 떨어짐.
	_gpu_amb_drip = _Helpers.make_emitter({
		"count": int(13 * _scale()), "lifetime": 1.1, "color": Color.WHITE,
		"speed_min": 30.0, "speed_max": 54.0,
		"direction": Vector2.DOWN, "spread": 12.0,
		"gravity": 180.0, "damping": 3.0,  # 0.05 * 60²
		"size_min": 2.4, "size_max": 4.2,
		"size_base": 23.0,
		"texture": _Helpers.drip_tex(),
		"additive": false,
		"emission_shape": "box", "emission_box": Vector2(30.0, 15.0),
		"one_shot": false, "explosiveness": 0.0,
		"start_alpha": 0.9, "mid_alpha": 0.45, "end_alpha": 0.0,
	})
	_gpu_amb_drip.position = _target
	add_child(_gpu_amb_drip)
	get_tree().create_timer(POISON_TIME).timeout.connect(func() -> void:
		if is_instance_valid(_gpu_amb_gas): _gpu_amb_gas.emitting = false
		if is_instance_valid(_gpu_amb_bubble): _gpu_amb_bubble.emitting = false
		if is_instance_valid(_gpu_amb_drip): _gpu_amb_drip.emitting = false)
