# scenes/vfx/poison_tick_gpu.gd
# 독 틱 GPU 하이브리드 — poison_tick.gd 상속.
# poison_splash_gpu 의 ambient 매칭 (gas + bubble. drip 은 tick 에 없음).
# 원본 spawn:
#   - gas: 0.7/frame × 60 = 42/s × lifetime 2.0 ≈ 84 동시. COL_HOT (흰연두). non-add.
#   - bubble: 0.4/frame × 60 = 24/s × lifetime 1.15 ≈ 28 동시. bubble_tex. non-add.
# puddle (ground) 폴리곤 → CPU 유지.
extends "res://scenes/vfx/poison_tick.gd"

const _Helpers = preload("res://scenes/vfx/gpu_particle_helpers.gd")

var _gpu_gas: GPUParticles2D
var _gpu_bubble: GPUParticles2D
var _amb_made: bool = false

func _spawn_ambient() -> void:
	if _amb_made:
		return
	_amb_made = true
	# gas: COL_HOT 흰연두 (splash 매칭). 위로 천천히.
	_gpu_gas = _Helpers.make_emitter({
		"count": int(84 * _scale()), "lifetime": 2.0, "color": COL_HOT,
		"speed_min": 24.0, "speed_max": 54.0,
		"direction": Vector2.UP, "spread": 18.0,
		"gravity": -18.0, "damping": 3.0,
		"size_min": 12.0, "size_max": 24.0,
		"additive": false,
		"emission_shape": "box", "emission_box": Vector2(35.0, 15.0),
		"one_shot": false, "explosiveness": 0.0,
		"start_alpha": 0.4, "mid_alpha": 0.2, "end_alpha": 0.0,
	})
	_gpu_gas.position = _target + Vector2(0.0, 40.0)
	add_child(_gpu_gas)
	# bubble: bubble_tex (splash 매칭). 위로 빠르게.
	_gpu_bubble = _Helpers.make_emitter({
		"count": int(28 * _scale()), "lifetime": 1.15, "color": Color.WHITE,
		"speed_min": 36.0, "speed_max": 78.0,
		"direction": Vector2.UP, "spread": 12.0,
		"gravity": 0.0, "damping": 3.0,
		"size_min": 3.0, "size_max": 7.0,
		"size_base": 28.0,
		"texture": _Helpers.bubble_tex(),
		"additive": false,
		"emission_shape": "box", "emission_box": Vector2(30.0, 15.0),
		"one_shot": false, "explosiveness": 0.0,
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	_gpu_bubble.position = _target + Vector2(0.0, 55.0)
	add_child(_gpu_bubble)
	get_tree().create_timer(TICK_TIME).timeout.connect(func() -> void:
		if is_instance_valid(_gpu_gas): _gpu_gas.emitting = false
		if is_instance_valid(_gpu_bubble): _gpu_bubble.emitting = false)
