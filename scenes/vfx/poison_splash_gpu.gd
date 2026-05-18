# scenes/vfx/poison_splash_gpu.gd
# 독 폭발 GPU 하이브리드 — poison_splash.gd 상속.
# trail / splash / ambient → GPU. 플라스크 비행/회전 CPU.
extends "res://scenes/vfx/poison_splash.gd"

const _Helpers = preload("res://scenes/vfx/gpu_particle_helpers.gd")

var _gpu_trail_drip: GPUParticles2D
var _gpu_trail_gas: GPUParticles2D
var _trail_made: bool = false
var _splash_made: bool = false
var _gpu_ambient_gas: GPUParticles2D
var _ambient_made: bool = false

func _spawn_trail(pos: Vector2) -> void:
	if not _trail_made:
		_trail_made = true
		# drip — 흘러내림
		_gpu_trail_drip = _Helpers.make_emitter({
			"count": int(72 * _scale()), "lifetime": 1.0, "color": COL_DRIP,
			"speed_min": 12.0, "speed_max": 36.0,
			"direction": Vector2.DOWN, "spread": 25.0,
			"gravity": 144.0, "damping": 3.0,
			"size_min": 4.0, "size_max": 9.0,
			"additive": false,
			"emission_shape": "box", "emission_box": Vector2(3.0, 3.0),
			"one_shot": false, "explosiveness": 0.0,
			"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
		})
		add_child(_gpu_trail_drip)
		# gas — 위로 피어오름
		_gpu_trail_gas = _Helpers.make_emitter({
			"count": int(60 * _scale()), "lifetime": 1.2, "color": COL_GAS,
			"speed_min": 12.0, "speed_max": 30.0,
			"direction": Vector2.UP, "spread": 30.0,
			"gravity": -18.0, "damping": 3.0,
			"size_min": 8.0, "size_max": 16.0,
			"additive": false,
			"emission_shape": "box", "emission_box": Vector2(2.0, 2.0),
			"one_shot": false, "explosiveness": 0.0,
			"start_alpha": 0.6, "mid_alpha": 0.3, "end_alpha": 0.0,
		})
		add_child(_gpu_trail_gas)
	if is_instance_valid(_gpu_trail_drip):
		_gpu_trail_drip.position = pos
		_gpu_trail_gas.position = pos

func _spawn_splash(pos: Vector2) -> void:
	if _splash_made:
		return
	_splash_made = true
	if is_instance_valid(_gpu_trail_drip): _gpu_trail_drip.emitting = false
	if is_instance_valid(_gpu_trail_gas): _gpu_trail_gas.emitting = false
	# drip 40
	var drip := _Helpers.make_emitter({
		"count": _pcount(40), "lifetime": 1.4, "color": COL_DRIP,
		"speed_min": 60.0, "speed_max": 300.0,
		"direction": Vector2.UP, "spread": 180.0,
		"gravity": 216.0, "damping": 3.0,
		"size_min": 3.0, "size_max": 8.0,
		"additive": false,
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	drip.position = pos
	add_child(drip)
	# gas 50 — 큰 안개
	var gas := _Helpers.make_emitter({
		"count": _pcount(50), "lifetime": 2.3, "color": COL_GAS,
		"speed_min": 36.0, "speed_max": 186.0,
		"direction": Vector2.UP, "spread": 180.0,
		"gravity": -28.8, "damping": 3.0,
		"size_min": 18.0, "size_max": 38.0,
		"additive": false,
		"start_alpha": 0.6, "mid_alpha": 0.3, "end_alpha": 0.0,
	})
	gas.position = pos
	add_child(gas)
	# spark 24
	var spark := _Helpers.make_emitter({
		"count": _pcount(24), "lifetime": 1.7, "color": COL_SPARK,
		"speed_min": 60.0, "speed_max": 240.0,
		"direction": Vector2.UP, "spread": 180.0,
		"gravity": 0.0, "damping": 3.0,
		"size_min": 1.4, "size_max": 2.6,
		"size_base": 4.0,
		"texture": _Helpers.sparkle_tex(),
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	spark.position = pos
	add_child(spark)

func _spawn_ambient() -> void:
	if _ambient_made:
		return
	_ambient_made = true
	# gas 0.7 확률 + bubble 0.3 + drip 0.2 ≈ 합 1.2/frame × 60 × lifetime 2.4 ≈ 172.
	# 단순화: gas 만 continuous (가장 두드러진 효과)
	_gpu_ambient_gas = _Helpers.make_emitter({
		"count": int(60 * _scale()), "lifetime": 2.4, "color": COL_GAS,
		"speed_min": 24.0, "speed_max": 60.0,
		"direction": Vector2.UP, "spread": 20.0,
		"gravity": -18.0, "damping": 3.0,
		"size_min": 12.0, "size_max": 24.0,
		"additive": false,
		"emission_shape": "box", "emission_box": Vector2(35.0, 15.0),
		"one_shot": false, "explosiveness": 0.0,
		"start_alpha": 0.6, "mid_alpha": 0.3, "end_alpha": 0.0,
	})
	_gpu_ambient_gas.position = _target + Vector2(0.0, 40.0)
	add_child(_gpu_ambient_gas)
	get_tree().create_timer(POISON_TIME).timeout.connect(func() -> void:
		if is_instance_valid(_gpu_ambient_gas): _gpu_ambient_gas.emitting = false)
