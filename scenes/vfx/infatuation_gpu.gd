# scenes/vfx/infatuation_gpu.gd
# 반함 GPU 하이브리드 — infatuation.gd 상속.
# trail / ambient / impact_burst (heart 26 + petal 40 + sparkle 60 + smoke 22) → GPU.
# 만다라/체인/오라/큰 키스/하트 투사체 폴리곤 CPU.
extends "res://scenes/vfx/infatuation.gd"

const _Helpers = preload("res://scenes/vfx/gpu_particle_helpers.gd")

var _gpu_trail: GPUParticles2D
var _trail_made: bool = false
var _gpu_ambient_heart: GPUParticles2D
var _ambient_made: bool = false
var _impact_made: bool = false

func _spawn_trail(pos: Vector2, _tint: String) -> void:
	if not _trail_made:
		_trail_made = true
		# heart_small + sparkle 합쳐 1 emitter
		_gpu_trail = _Helpers.make_emitter({
			"count": int(60 * _scale()), "lifetime": 1.0, "color": COL_RED,
			"speed_min": 12.0, "speed_max": 36.0,
			"direction": Vector2.UP, "spread": 90.0,
			"gravity": 0.0, "damping": 3.0,
			"size_min": 5.0, "size_max": 9.0,
			"emission_shape": "box", "emission_box": Vector2(4.0, 4.0),
			"additive": false,
			"one_shot": false, "explosiveness": 0.0,
			"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
		})
		add_child(_gpu_trail)
	if is_instance_valid(_gpu_trail):
		_gpu_trail.position = pos

func _spawn_ambient() -> void:
	if _ambient_made:
		return
	_ambient_made = true
	_gpu_ambient_heart = _Helpers.make_emitter({
		"count": int(100 * _scale()), "lifetime": 2.4, "color": COL_RED,
		"speed_min": 30.0, "speed_max": 72.0,
		"direction": Vector2.UP, "spread": 30.0,
		"gravity": 0.0, "damping": 3.0,
		"size_min": 6.0, "size_max": 11.0,
		"emission_shape": "box", "emission_box": Vector2(50.0, 20.0),
		"additive": false,
		"one_shot": false, "explosiveness": 0.0,
		"start_alpha": 0.7, "mid_alpha": 0.35, "end_alpha": 0.0,
	})
	_gpu_ambient_heart.position = _target + Vector2(0.0, -10.0)
	add_child(_gpu_ambient_heart)
	get_tree().create_timer(BUFF_TIME).timeout.connect(func() -> void:
		if is_instance_valid(_gpu_ambient_heart): _gpu_ambient_heart.emitting = false)

func _spawn_impact_burst() -> void:
	if _impact_made:
		return
	_impact_made = true
	if is_instance_valid(_gpu_trail): _gpu_trail.emitting = false
	var b := _target + Vector2(0.0, -40.0)
	# heart 26 (crimson + rose)
	var heart_crim := _Helpers.make_emitter({
		"count": _pcount(12), "lifetime": 2.2, "color": COL_CRIMSON,
		"speed_min": 150.0, "speed_max": 540.0,
		"direction": Vector2.UP, "spread": 180.0,
		"gravity": -43.2, "damping": 3.0,
		"size_min": 14.0, "size_max": 30.0,
		"additive": false,
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	heart_crim.position = b
	add_child(heart_crim)
	var heart_rose := _Helpers.make_emitter({
		"count": _pcount(14), "lifetime": 2.2, "color": COL_RED,
		"speed_min": 150.0, "speed_max": 540.0,
		"direction": Vector2.UP, "spread": 180.0,
		"gravity": -43.2, "damping": 3.0,
		"size_min": 14.0, "size_max": 30.0,
		"additive": false,
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	heart_rose.position = b
	add_child(heart_rose)
	# petal 40 — feather_tex 회전
	var petal := _Helpers.make_emitter({
		"count": _pcount(40), "lifetime": 2.6, "color": COL_PETAL,
		"speed_min": 90.0, "speed_max": 330.0,
		"direction": Vector2.UP, "spread": 180.0,
		"gravity": 72.0, "damping": 3.0,
		"size_min": 6.0, "size_max": 13.0,
		"size_base": 30.0,
		"angle_min": -180.0, "angle_max": 180.0,
		"angular_velocity_min": -275.0, "angular_velocity_max": 275.0,
		"additive": false,
		"texture": _Helpers.feather_tex(),
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	petal.position = b
	add_child(petal)
	# sparkle 60
	var sparkle := _Helpers.make_emitter({
		"count": _pcount(60), "lifetime": 1.7, "color": COL_HOT,
		"speed_min": 90.0, "speed_max": 450.0,
		"direction": Vector2.UP, "spread": 180.0,
		"gravity": 36.0, "damping": 3.0,
		"size_min": 1.0, "size_max": 2.4,
		"size_base": 4.0,
		"texture": _Helpers.sparkle_tex(),
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	sparkle.position = b
	add_child(sparkle)
	# smoke 22 — 빨강
	var smoke := _Helpers.make_emitter({
		"count": _pcount(22), "lifetime": 2.3, "color": COL_DARK,
		"speed_min": 48.0, "speed_max": 156.0,
		"direction": Vector2.UP, "spread": 180.0,
		"gravity": -18.0, "damping": 3.0,
		"size_min": 24.0, "size_max": 46.0,
		"additive": false,
		"start_alpha": 0.5, "mid_alpha": 0.25, "end_alpha": 0.0,
	})
	smoke.position = b
	smoke.z_index = -1
	add_child(smoke)
