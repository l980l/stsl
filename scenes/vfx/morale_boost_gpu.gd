# scenes/vfx/morale_boost_gpu.gd
# 사기 진작 GPU 하이브리드 — morale_boost.gd 상속.
# _spawn_peak_burst (spark 28 + dust 12) + _spawn_hold_ember (continuous spark) GPU.
# 깃발 / sunburst ray / sigil 폴리곤 → CPU.
extends "res://scenes/vfx/morale_boost.gd"

const _Helpers = preload("res://scenes/vfx/gpu_particle_helpers.gd")

var _peak_made: bool = false
var _gpu_hold_ember: GPUParticles2D
var _hold_made: bool = false

func _spawn_peak_burst() -> void:
	if _peak_made:
		return
	_peak_made = true
	var ctr: Vector2 = _target + Vector2(0.0, -40.0)
	# spark 28 (brass 70% + hot 30%)
	var spark_brass := _Helpers.make_emitter({
		"count": _pcount(20), "lifetime": 1.15, "color": COL_BRASS,
		"speed_min": 150.0, "speed_max": 450.0,
		"direction": Vector2.UP, "spread": 180.0,
		"gravity": 54.0, "damping": 3.0,
		"size_min": 1.4, "size_max": 2.8,
		"size_base": 4.0,
		"texture": _Helpers.sparkle_tex(),
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	spark_brass.position = ctr
	add_child(spark_brass)
	var spark_hot := _Helpers.make_emitter({
		"count": _pcount(8), "lifetime": 1.15, "color": COL_HOT,
		"speed_min": 150.0, "speed_max": 450.0,
		"direction": Vector2.UP, "spread": 180.0,
		"gravity": 54.0, "damping": 3.0,
		"size_min": 1.4, "size_max": 2.8,
		"size_base": 4.0,
		"texture": _Helpers.sparkle_tex(),
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	spark_hot.position = ctr
	add_child(spark_hot)
	# dust 12 (발치 ring)
	var foot: Vector2 = _foot_pos()
	var dust := _Helpers.make_emitter({
		"count": _pcount(12), "lifetime": 1.25, "color": COL_BRASS_300,
		"speed_min": 90.0, "speed_max": 240.0,
		"direction": Vector2.UP, "spread": 130.0,
		"gravity": -18.0, "damping": 3.0,
		"size_min": 12.0, "size_max": 24.0,
		"additive": false,
		"start_alpha": 0.5, "mid_alpha": 0.25, "end_alpha": 0.0,
	})
	dust.position = foot
	add_child(dust)

func _spawn_hold_ember() -> void:
	if _hold_made:
		return
	_hold_made = true
	var foot: Vector2 = _foot_pos()
	# 0.4 확률/frame × 60 = 24/s × lifetime 1.25 ≈ 30 동시
	_gpu_hold_ember = _Helpers.make_emitter({
		"count": int(30 * _scale()), "lifetime": 1.25, "color": COL_BRASS,
		"speed_min": 30.0, "speed_max": 54.0,
		"direction": Vector2.UP, "spread": 18.0,
		"gravity": 0.0, "damping": 3.0,
		"size_min": 1.0, "size_max": 2.1,
		"size_base": 4.0,
		"texture": _Helpers.sparkle_tex(),
		"emission_shape": "box", "emission_box": Vector2(90.0, 15.0),
		"one_shot": false, "explosiveness": 0.0,
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	_gpu_hold_ember.position = foot + Vector2(0.0, -15.0)
	add_child(_gpu_hold_ember)
	get_tree().create_timer(HOLD_TIME).timeout.connect(func() -> void:
		if is_instance_valid(_gpu_hold_ember): _gpu_hold_ember.emitting = false)
