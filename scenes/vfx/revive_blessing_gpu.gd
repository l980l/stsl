# scenes/vfx/revive_blessing_gpu.gd
# 부활 GPU 하이브리드 — revive_blessing.gd 상속.
# _spawn_burst (mote 80 + feather 40 + haze 24) + _spawn_pillar_mote (continuous) GPU.
# 빛기둥, 고리 폴리곤 → CPU.
extends "res://scenes/vfx/revive_blessing.gd"

const _Helpers = preload("res://scenes/vfx/gpu_particle_helpers.gd")

var _burst_made: bool = false
var _gpu_pillar: GPUParticles2D
var _pillar_made: bool = false

func _spawn_burst() -> void:
	if _burst_made:
		return
	_burst_made = true
	var origin := _target + Vector2(0.0, -60.0)
	# mote 80 (sparkle_tex)
	var mote := _Helpers.make_emitter({
		"count": _pcount(80), "lifetime": 2.4, "color": COL_MID,
		"speed_min": 120.0, "speed_max": 480.0,
		"direction": Vector2.UP, "spread": 180.0,
		"gravity": 64.8, "damping": 3.0,
		"size_min": 1.6, "size_max": 3.2,
		"size_base": 4.0,
		"texture": _Helpers.sparkle_tex(),
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	mote.position = origin
	add_child(mote)
	# feather 40
	var feather := _Helpers.make_emitter({
		"count": _pcount(40), "lifetime": 2.25, "color": Color.WHITE,
		"speed_min": 90.0, "speed_max": 330.0,
		"direction": Vector2.UP, "spread": 180.0,
		"gravity": 43.2, "damping": 3.0,
		"size_min": 12.0, "size_max": 24.0,
		"size_base": 30.0,
		"angle_min": -180.0, "angle_max": 180.0,
		"angular_velocity_min": -618.0, "angular_velocity_max": 618.0,
		"additive": false,
		"texture": _Helpers.feather_tex(),
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	feather.position = origin
	add_child(feather)
	# haze 24 (큰 안개)
	var haze := _Helpers.make_emitter({
		"count": _pcount(24), "lifetime": 2.25, "color": COL_HAZE,
		"speed_min": 36.0, "speed_max": 144.0,
		"direction": Vector2.UP, "spread": 180.0,
		"gravity": -36.0, "damping": 3.0,
		"size_min": 28.0, "size_max": 50.0,
		"additive": false,
		"start_alpha": 0.5, "mid_alpha": 0.25, "end_alpha": 0.0,
	})
	haze.position = origin
	add_child(haze)

func _spawn_pillar_mote() -> void:
	if _pillar_made:
		return
	_pillar_made = true
	# 0.6 확률/frame × 60 = 36/s × lifetime 1.85 ≈ 67 동시
	_gpu_pillar = _Helpers.make_emitter({
		"count": int(67 * _scale()), "lifetime": 1.85, "color": COL_MID,
		"speed_min": 36.0, "speed_max": 96.0,
		"direction": Vector2.DOWN, "spread": 18.0,  # 빛기둥 내려옴
		"gravity": 0.0, "damping": 3.0,
		"size_min": 1.4, "size_max": 2.8,
		"size_base": 4.0,
		"texture": _Helpers.sparkle_tex(),
		"emission_shape": "box", "emission_box": Vector2(90.0, PILLAR_HEIGHT * 0.5),
		"one_shot": false, "explosiveness": 0.0,
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	_gpu_pillar.position = _target + Vector2(0.0, -PILLAR_HEIGHT * 0.5)
	add_child(_gpu_pillar)
	get_tree().create_timer(REVIVE_TIME).timeout.connect(func() -> void:
		if is_instance_valid(_gpu_pillar): _gpu_pillar.emitting = false)
