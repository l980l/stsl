# scenes/vfx/charm_kiss_gpu.gd
# 매혹 키스 GPU 하이브리드 — charm_kiss.gd 상속.
# _spawn_trail (반복) / _spawn_impact_burst (one-time) / _spawn_ambient (반복) → GPU.
# 하트 모양 폴리곤, 차지 오브 CPU.
extends "res://scenes/vfx/charm_kiss.gd"

const _Helpers = preload("res://scenes/vfx/gpu_particle_helpers.gd")

var _gpu_trail_heart: GPUParticles2D
var _gpu_trail_smoke: GPUParticles2D
var _trail_made: bool = false
var _impact_made: bool = false
var _gpu_ambient: GPUParticles2D
var _ambient_made: bool = false

func _spawn_trail(pos: Vector2) -> void:
	if not _trail_made:
		_trail_made = true
		# heart trail — circle 근사
		_gpu_trail_heart = _Helpers.make_emitter({
			"count": int(60 * _scale()), "lifetime": 1.0, "color": COL_MID,
			"speed_min": 12.0, "speed_max": 36.0,
			"direction": Vector2.UP, "spread": 90.0,
			"gravity": 0.0, "damping": 3.0,
			"size_min": 8.0, "size_max": 16.0,
			"emission_shape": "box", "emission_box": Vector2(10.0, 10.0),
			"additive": false,
			"one_shot": false, "explosiveness": 0.0,
			"start_alpha": 0.7, "mid_alpha": 0.35, "end_alpha": 0.0,
		})
		add_child(_gpu_trail_heart)
		_gpu_trail_smoke = _Helpers.make_emitter({
			"count": int(60 * _scale()), "lifetime": 1.4, "color": COL_SMOKE,
			"speed_min": 6.0, "speed_max": 24.0,
			"direction": Vector2.UP, "spread": 60.0,
			"gravity": 0.0, "damping": 3.0,
			"size_min": 14.0, "size_max": 30.0,
			"emission_shape": "box", "emission_box": Vector2(8.0, 8.0),
			"additive": false,
			"one_shot": false, "explosiveness": 0.0,
			"start_alpha": 0.5, "mid_alpha": 0.25, "end_alpha": 0.0,
		})
		add_child(_gpu_trail_smoke)
	if is_instance_valid(_gpu_trail_heart):
		_gpu_trail_heart.position = pos
		_gpu_trail_smoke.position = pos

func _spawn_impact_burst(pos: Vector2) -> void:
	if _impact_made:
		return
	_impact_made = true
	# trail off
	if is_instance_valid(_gpu_trail_heart): _gpu_trail_heart.emitting = false
	if is_instance_valid(_gpu_trail_smoke): _gpu_trail_smoke.emitting = false
	# heart 26 (분홍/보라 혼합)
	var heart_rose := _Helpers.make_emitter({
		"count": _pcount(18), "lifetime": 2.2, "color": COL_MID,
		"speed_min": 90.0, "speed_max": 360.0,
		"direction": Vector2.UP, "spread": 180.0,
		"gravity": -43.2, "damping": 3.0,
		"size_min": 14.0, "size_max": 30.0,
		"additive": false,
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	heart_rose.position = pos
	add_child(heart_rose)
	var heart_violet := _Helpers.make_emitter({
		"count": _pcount(8), "lifetime": 2.2, "color": COL_VIOLET,
		"speed_min": 90.0, "speed_max": 360.0,
		"direction": Vector2.UP, "spread": 180.0,
		"gravity": -43.2, "damping": 3.0,
		"size_min": 14.0, "size_max": 30.0,
		"additive": false,
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	heart_violet.position = pos
	add_child(heart_violet)
	# petal 40 — feather_tex 사용 (꽃잎 모양)
	var petal := _Helpers.make_emitter({
		"count": _pcount(40), "lifetime": 2.5, "color": COL_DEEP,
		"speed_min": 60.0, "speed_max": 240.0,
		"direction": Vector2.UP, "spread": 180.0,
		"gravity": 72.0, "damping": 3.0,
		"size_min": 6.0, "size_max": 13.0,
		"size_base": 30.0,
		"angle_min": -180.0, "angle_max": 180.0,
		"angular_velocity_min": -172.0, "angular_velocity_max": 172.0,
		"additive": false,
		"texture": _Helpers.feather_tex(),
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	petal.position = pos
	add_child(petal)
	# sparkle 60 — 반짝임
	var sparkle := _Helpers.make_emitter({
		"count": _pcount(60), "lifetime": 1.7, "color": COL_HOT,
		"speed_min": 60.0, "speed_max": 360.0,
		"direction": Vector2.UP, "spread": 180.0,
		"gravity": 36.0, "damping": 3.0,
		"size_min": 1.0, "size_max": 2.4,
		"size_base": 4.0,
		"texture": _Helpers.sparkle_tex(),
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	sparkle.position = pos
	add_child(sparkle)
	# smoke 22 — 분홍 연기
	var smoke := _Helpers.make_emitter({
		"count": _pcount(22), "lifetime": 2.3, "color": COL_SMOKE,
		"speed_min": 36.0, "speed_max": 132.0,
		"direction": Vector2.UP, "spread": 180.0,
		"gravity": -18.0, "damping": 3.0,
		"size_min": 24.0, "size_max": 46.0,
		"additive": false,
		"start_alpha": 0.5, "mid_alpha": 0.25, "end_alpha": 0.0,
	})
	smoke.position = pos
	smoke.z_index = -1
	add_child(smoke)

func _spawn_ambient() -> void:
	if _ambient_made:
		return
	_ambient_made = true
	# 0.6 + 0.4 확률/frame × 60 × lifetime 2.5 ≈ 150 동시
	_gpu_ambient = _Helpers.make_emitter({
		"count": int(120 * _scale()), "lifetime": 2.5, "color": COL_MID,
		"speed_min": 30.0, "speed_max": 72.0,
		"direction": Vector2.UP, "spread": 30.0,
		"gravity": 0.0, "damping": 3.0,
		"size_min": 8.0, "size_max": 18.0,
		"emission_shape": "box", "emission_box": Vector2(45.0, 10.0),
		"additive": false,
		"one_shot": false, "explosiveness": 0.0,
		"start_alpha": 0.7, "mid_alpha": 0.35, "end_alpha": 0.0,
	})
	_gpu_ambient.position = _target + Vector2(0.0, 20.0)
	add_child(_gpu_ambient)
	get_tree().create_timer(CHARM_TIME).timeout.connect(func() -> void:
		if is_instance_valid(_gpu_ambient): _gpu_ambient.emitting = false)
