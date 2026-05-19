# scenes/vfx/speed_buff_gpu.gd
# 속도 버프 GPU 하이브리드 — speed_buff.gd 상속.
# spark + dust GPU. streak (방향성 라인) 은 CPU 유지.
extends "res://scenes/vfx/speed_buff.gd"

const _Helpers = preload("res://scenes/vfx/gpu_particle_helpers.gd")

var _peak_made: bool = false
var _gpu_amb_spark: GPUParticles2D
var _amb_made: bool = false

func _process(delta: float) -> void:
	super._process(delta)
	var ga: float = _global_alpha()
	for child in get_children():
		if child is GPUParticles2D:
			child.modulate.a = ga

# spark/dust GPU + streak CPU inline (super 호출 X)
func _spawn_peak_burst() -> void:
	if _peak_made:
		return
	_peak_made = true
	var foot: Vector2 = _foot_pos()
	# spark 40 (외곽 mote)
	var spark := _Helpers.make_emitter({
		"count": _pcount(40), "lifetime": 1.3, "color": COL_ELEC,
		"speed_min": 120.0, "speed_max": 420.0,
		"direction": Vector2.UP, "spread": 180.0,
		"gravity": 72.0, "damping": 3.0,
		"size_min": 1.4, "size_max": 2.8,
		"size_base": 16.0,
		"texture": _Helpers.mote_halo_tex(),
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	spark.position = _target
	add_child(spark)
	# dust 14 (바닥 ring)
	var dust := _Helpers.make_emitter({
		"count": _pcount(14), "lifetime": 1.6, "color": COL_DUST,
		"speed_min": 90.0, "speed_max": 240.0,
		"direction": Vector2.UP, "spread": 130.0,
		"gravity": -18.0, "damping": 3.0,
		"size_min": 12.0, "size_max": 24.0,
		"additive": false,
		"start_alpha": 0.4, "mid_alpha": 0.2, "end_alpha": 0.0,
	})
	dust.position = foot
	add_child(dust)
	# streak 10 CPU (방향성 라인 — GPU 표준 파티클로 표현 불가)
	for _i in range(_pcount(10)):
		var dir: float = -1.0 if randf() < 0.5 else 1.0
		var sp2 := 5.0 + randf() * 4.0
		var ang_jitter := randf_range(-0.25, 0.25)
		_particles.append({
			"pos": _target + Vector2(0.0, randf_range(-50.0, 30.0)),
			"vel": Vector2(cos(ang_jitter) * sp2 * dir, sin(ang_jitter) * sp2),
			"life": 0.0,
			"max_life": 0.5 + randf() * 0.3,
			"size": 2.0 + randf() * 1.4,
			"kind": "streak",
		})

# ambient — spark GPU continuous + streak CPU inline
func _spawn_ambient() -> void:
	if not _amb_made:
		_amb_made = true
		var foot: Vector2 = _foot_pos()
		# 0.6 확률/frame × 60 = 36/s × lifetime 1.0 ≈ 36 동시
		_gpu_amb_spark = _Helpers.make_emitter({
			"count": int(36 * _scale()), "lifetime": 1.0, "color": COL_ELEC,
			"speed_min": 18.0, "speed_max": 84.0,
			"direction": Vector2.UP, "spread": 60.0,
			"gravity": 144.0, "damping": 3.0,
			"size_min": 1.2, "size_max": 2.4,
			"size_base": 16.0,
			"texture": _Helpers.mote_halo_tex(),
			"emission_shape": "box", "emission_box": Vector2(60.0, 15.0),
			"one_shot": false, "explosiveness": 0.0,
			"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
		})
		_gpu_amb_spark.position = foot + Vector2(0.0, -15.0)
		add_child(_gpu_amb_spark)
		get_tree().create_timer(BUFF_TIME).timeout.connect(func() -> void:
			if is_instance_valid(_gpu_amb_spark): _gpu_amb_spark.emitting = false)
	# streak CPU
	if randf() < 0.3 * _scale():
		var dir: float = -1.0 if randf() < 0.5 else 1.0
		_particles.append({
			"pos": _target + Vector2(dir * 40.0 + randf_range(-15.0, 15.0), randf_range(-50.0, 30.0)),
			"vel": Vector2(dir * (2.0 + randf() * 2.0), 0.0),
			"life": 0.0,
			"max_life": 0.3 + randf() * 0.2,
			"size": 1.6 + randf() * 1.0,
			"kind": "streak",
		})
