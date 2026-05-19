# scenes/vfx/purge_status_gpu.gd
# 정화 GPU 하이브리드 — purge_status.gd 상속.
# peak spark (teal+pure) + hold ember (bone) GPU. ring/pillar/wash 폴리곤 → CPU.
extends "res://scenes/vfx/purge_status.gd"

const _Helpers = preload("res://scenes/vfx/gpu_particle_helpers.gd")

var _peak_made: bool = false
var _gpu_hold_ember: GPUParticles2D
var _hold_made: bool = false

func _process(delta: float) -> void:
	super._process(delta)
	var ga: float = _global_alpha()
	for child in get_children():
		if child is GPUParticles2D:
			child.modulate.a = ga

# peak: spark 24 GPU (teal 70% + pure 30%)
func _spawn_peak_burst() -> void:
	if _peak_made:
		return
	_peak_made = true
	var ctr: Vector2 = _target + Vector2(0.0, CORE_Y_OFFSET)
	var spark_teal := _Helpers.make_emitter({
		"count": _pcount(17), "lifetime": 1.2, "color": COL_TEAL,
		"speed_min": 120.0, "speed_max": 360.0,
		"direction": Vector2.UP, "spread": 180.0,
		"gravity": 36.0, "damping": 3.0,
		"size_min": 1.4, "size_max": 2.8,
		"size_base": 16.0,
		"texture": _Helpers.mote_halo_tex(),
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	spark_teal.position = ctr
	add_child(spark_teal)
	var spark_pure := _Helpers.make_emitter({
		"count": _pcount(7), "lifetime": 1.2, "color": COL_PURE,
		"speed_min": 120.0, "speed_max": 360.0,
		"direction": Vector2.UP, "spread": 180.0,
		"gravity": 36.0, "damping": 3.0,
		"size_min": 1.4, "size_max": 2.8,
		"size_base": 16.0,
		"texture": _Helpers.mote_halo_tex(),
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	spark_pure.position = ctr
	add_child(spark_pure)

# hold ember GPU continuous (bone)
func _spawn_hold_ember() -> void:
	if _hold_made:
		return
	_hold_made = true
	var foot: Vector2 = _foot_pos()
	# 0.4/frame × 60 × lifetime 1.35 ≈ 32 동시
	_gpu_hold_ember = _Helpers.make_emitter({
		"count": int(32 * _scale()), "lifetime": 1.35, "color": COL_BONE,
		"speed_min": 30.0, "speed_max": 54.0,
		"direction": Vector2.UP, "spread": 18.0,
		"gravity": 0.0, "damping": 3.0,
		"size_min": 1.0, "size_max": 2.0,
		"size_base": 16.0,
		"texture": _Helpers.mote_halo_tex(),
		"emission_shape": "box", "emission_box": Vector2(70.0, 15.0),
		"one_shot": false, "explosiveness": 0.0,
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	_gpu_hold_ember.position = foot + Vector2(0.0, -15.0)
	add_child(_gpu_hold_ember)
	get_tree().create_timer(HOLD_TIME).timeout.connect(func() -> void:
		if is_instance_valid(_gpu_hold_ember): _gpu_hold_ember.emitting = false)
