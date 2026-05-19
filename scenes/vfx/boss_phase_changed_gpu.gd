# scenes/vfx/boss_phase_changed_gpu.gd
# 보스 페이즈 변경 GPU 하이브리드 — boss_phase_changed.gd 상속.
# inflow + spark + dust GPU. core/shockwave/aura/streaks 폴리곤 → CPU 유지.
extends "res://scenes/vfx/boss_phase_changed.gd"

const _Helpers = preload("res://scenes/vfx/gpu_particle_helpers.gd")

var _peak_made: bool = false
var _gpu_inflow_blood: GPUParticles2D
var _gpu_inflow_hot: GPUParticles2D
var _gpu_inflow_rim: GPUParticles2D
var _gpu_hold_ember: GPUParticles2D
var _inflow_made: bool = false
var _hold_made: bool = false

func _process(delta: float) -> void:
	super._process(delta)
	var ga: float = _global_alpha()
	for child in get_children():
		if child is GPUParticles2D:
			child.modulate.a = ga

static func _dust_scale_curve() -> Curve:
	var c := Curve.new()
	c.add_point(Vector2(0.0, 1.0))
	c.add_point(Vector2(1.0, 2.3))
	return c

func _make_inflow(col: Color, count: int) -> GPUParticles2D:
	return _Helpers.make_emitter({
		"count": count, "lifetime": 0.5, "color": col,
		"speed_min": 0.0, "speed_max": 0.0,
		"emission_shape": "sphere", "emission_radius": 280.0,
		"radial_accel_min": -1400.0, "radial_accel_max": -900.0,
		"size_min": 1.4, "size_max": 2.8,
		"size_base": 16.0,
		"texture": _Helpers.mote_halo_tex(),
		"one_shot": false, "explosiveness": 0.0,
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})

# inflow 3 tint emitter — blood 30%, hot 20%, rim 50%
func _spawn_inflow(_intensity: int) -> void:
	if _inflow_made:
		return
	_inflow_made = true
	var ctr: Vector2 = _target + Vector2(0.0, -40.0)
	# intensity 평균 3/frame × 60 = 180/s × lifetime 0.5 = 90 동시
	_gpu_inflow_blood = _make_inflow(COL_BLOOD, int(27 * _scale()))
	_gpu_inflow_hot = _make_inflow(COL_HOT, int(18 * _scale()))
	_gpu_inflow_rim = _make_inflow(COL_RIM_HOT, int(45 * _scale()))
	_gpu_inflow_blood.position = ctr
	_gpu_inflow_hot.position = ctr
	_gpu_inflow_rim.position = ctr
	add_child(_gpu_inflow_blood)
	add_child(_gpu_inflow_hot)
	add_child(_gpu_inflow_rim)
	get_tree().create_timer(PEAK_DELAY).timeout.connect(func() -> void:
		if is_instance_valid(_gpu_inflow_blood): _gpu_inflow_blood.emitting = false
		if is_instance_valid(_gpu_inflow_hot): _gpu_inflow_hot.emitting = false
		if is_instance_valid(_gpu_inflow_rim): _gpu_inflow_rim.emitting = false)

# peak: spark 90 (rim 36 + hot 22 + blood 32) + ember 40 rim + dust 32
func _spawn_peak_burst() -> void:
	if _peak_made:
		return
	_peak_made = true
	var ctr: Vector2 = _target + Vector2(0.0, -40.0)
	_make_spark_burst(ctr, COL_RIM_HOT, _pcount(36), 1.6, 3.6)
	_make_spark_burst(ctr, COL_HOT, _pcount(22), 1.6, 3.6)
	_make_spark_burst(ctr, COL_BLOOD, _pcount(32), 1.6, 3.6)
	# 작은 ember 40 (rim, 오래)
	_make_ember_burst(ctr, _pcount(40))
	# 발치 dust 32
	var foot: Vector2 = _foot_pos()
	var dust := _Helpers.make_emitter({
		"count": _pcount(32), "lifetime": 1.5, "color": COL_BLOOD_DEEP,
		"speed_min": 150.0, "speed_max": 420.0,  # sp 2.5~7 × PSPEED
		"direction": Vector2.UP, "spread": 130.0,
		"gravity": -18.0, "damping": 0.0,
		"size_min": 16.0, "size_max": 30.0,
		"scale_curve": _dust_scale_curve(),
		"start_alpha": 0.4, "mid_alpha": 0.2, "end_alpha": 0.0,
	})
	dust.position = foot
	add_child(dust)

func _make_spark_burst(ctr: Vector2, col: Color, count: int, size_min: float, size_max: float) -> void:
	var spark := _Helpers.make_emitter({
		"count": count, "lifetime": 1.7, "color": col,
		"speed_min": 240.0, "speed_max": 840.0,  # sp 4~14 × PSPEED
		"direction": Vector2.UP, "spread": 180.0,
		"gravity": 72.0, "damping": 0.0,
		"size_min": size_min, "size_max": size_max,
		"size_base": 16.0,
		"texture": _Helpers.mote_halo_tex(),
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	spark.position = ctr
	add_child(spark)

func _make_ember_burst(ctr: Vector2, count: int) -> void:
	var ember := _Helpers.make_emitter({
		"count": count, "lifetime": 2.0, "color": COL_RIM_HOT,
		"speed_min": 90.0, "speed_max": 270.0,
		"direction": Vector2.UP, "spread": 180.0,
		"gravity": 18.0, "damping": 0.0,
		"size_min": 1.0, "size_max": 2.0,
		"size_base": 16.0,
		"texture": _Helpers.mote_halo_tex(),
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	ember.position = ctr
	add_child(ember)

# hold ember continuous (rim)
func _spawn_hold_ember() -> void:
	if _hold_made:
		return
	_hold_made = true
	var foot: Vector2 = _foot_pos()
	# 0.55/frame × 60 × lifetime 1.5 ≈ 50 동시
	_gpu_hold_ember = _Helpers.make_emitter({
		"count": int(50 * _scale()), "lifetime": 1.5, "color": COL_RIM_HOT,
		"speed_min": 42.0, "speed_max": 78.0,
		"direction": Vector2.UP, "spread": 12.0,
		"gravity": 0.0, "damping": 0.0,
		"size_min": 1.2, "size_max": 2.5,
		"size_base": 16.0,
		"texture": _Helpers.mote_halo_tex(),
		"emission_shape": "box", "emission_box": Vector2(130.0, 20.0),
		"one_shot": false, "explosiveness": 0.0,
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	_gpu_hold_ember.position = foot + Vector2(0.0, -20.0)
	add_child(_gpu_hold_ember)
	get_tree().create_timer(HOLD_TIME).timeout.connect(func() -> void:
		if is_instance_valid(_gpu_hold_ember): _gpu_hold_ember.emitting = false)
