# scenes/vfx/heal_blessing_gpu.gd
# 회복 GPU 하이브리드 — heal_blessing.gd 상속.
# _pop (sparkle 24 + leaf 5 burst) + _spawn_leaf/_spawn_sparkle (continuous) GPU.
# 차지 오브, 고리, 십자, 잎 폴리곤 → CPU. (잎 모양 폴리곤 복잡 → circle 근사)
extends "res://scenes/vfx/heal_blessing.gd"

const _Helpers = preload("res://scenes/vfx/gpu_particle_helpers.gd")

var _pop_made: bool = false
var _gpu_amb_leaf: GPUParticles2D
var _gpu_amb_sparkle: GPUParticles2D
var _amb_made: bool = false

# pop_burst override — sparkle 24 + leaf 5 burst (one-time)
func _pop() -> void:
	if _pop_made:
		return
	_pop_made = true
	# sparkle 24
	var sparkle := _Helpers.make_emitter({
		"count": _pcount(24), "lifetime": 1.55, "color": COL_HOT,
		"speed_min": 60.0, "speed_max": 240.0,
		"direction": Vector2.UP, "spread": 180.0,
		"gravity": 72.0, "damping": 3.0,
		"size_min": 1.4, "size_max": 2.8,
		"size_base": 4.0,
		"texture": _Helpers.sparkle_tex(),
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	sparkle.position = _target + Vector2(0.0, -40.0)
	add_child(sparkle)
	# leaf 5 — feather_tex 근사 (타원 + 회전). 색 COL_LEAF_TOP 연두.
	var leaf := _Helpers.make_emitter({
		"count": _pcount(5), "lifetime": 2.05, "color": COL_LEAF_TOP,
		"speed_min": 60.0, "speed_max": 180.0,
		"direction": Vector2.UP, "spread": 180.0,
		"gravity": 72.0, "damping": 3.0,
		"size_min": 8.0, "size_max": 15.0,
		"size_base": 30.0,
		"angle_min": -180.0, "angle_max": 180.0,
		"angular_velocity_min": -172.0, "angular_velocity_max": 172.0,
		"additive": false,
		"texture": _Helpers.feather_tex(),
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	leaf.position = _target + Vector2(0.0, -40.0)
	add_child(leaf)
	# ambient continuous (HEAL_TIME 동안)
	_setup_ambient()

func _setup_ambient() -> void:
	if _amb_made:
		return
	_amb_made = true
	# leaf 0.4 확률/frame × 60 = 24/s × lifetime 2.05 ≈ 49 동시
	_gpu_amb_leaf = _Helpers.make_emitter({
		"count": int(49 * _scale()), "lifetime": 2.05, "color": COL_LEAF_TOP,
		"speed_min": 30.0, "speed_max": 78.0,
		"direction": Vector2.UP, "spread": 20.0,
		"gravity": 0.0, "damping": 3.0,
		"size_min": 7.0, "size_max": 14.0,
		"size_base": 30.0,
		"angle_min": -180.0, "angle_max": 180.0,
		"angular_velocity_min": -138.0, "angular_velocity_max": 138.0,
		"additive": false,
		"texture": _Helpers.feather_tex(),
		"emission_shape": "box", "emission_box": Vector2(60.0, 5.0),
		"one_shot": false, "explosiveness": 0.0,
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	_gpu_amb_leaf.position = _target + Vector2(0.0, 10.0)
	add_child(_gpu_amb_leaf)
	# sparkle 0.9 확률/frame × 60 = 54/s × lifetime 1.55 ≈ 84 동시
	_gpu_amb_sparkle = _Helpers.make_emitter({
		"count": int(84 * _scale()), "lifetime": 1.55, "color": COL_HOT,
		"speed_min": 60.0, "speed_max": 120.0,
		"direction": Vector2.UP, "spread": 18.0,
		"gravity": 0.0, "damping": 3.0,
		"size_min": 1.4, "size_max": 2.6,
		"size_base": 4.0,
		"texture": _Helpers.sparkle_tex(),
		"emission_shape": "box", "emission_box": Vector2(60.0, 5.0),
		"one_shot": false, "explosiveness": 0.0,
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	_gpu_amb_sparkle.position = _target + Vector2(0.0, 10.0)
	add_child(_gpu_amb_sparkle)
	get_tree().create_timer(HEAL_TIME).timeout.connect(func() -> void:
		if is_instance_valid(_gpu_amb_leaf): _gpu_amb_leaf.emitting = false
		if is_instance_valid(_gpu_amb_sparkle): _gpu_amb_sparkle.emitting = false)

# super 의 _spawn_leaf / _spawn_sparkle override — noop (모두 GPU emitter 처리)
func _spawn_leaf(_from_pop: bool) -> void:
	pass
func _spawn_sparkle(_from_pop: bool) -> void:
	pass
