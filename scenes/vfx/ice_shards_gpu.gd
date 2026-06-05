# scenes/vfx/ice_shards_gpu.gd
# 얼음 파편 GPU 하이브리드 — ice_shards.gd 상속.
# frost_mist / impact (chunk/mist/sparkle) / snow GPU.
# shard 비행 (회전 폴리곤), 차지 오브, 명중 폭발 ring CPU.
extends "res://scenes/vfx/ice_shards.gd"

const _Helpers = preload("res://scenes/vfx/gpu_particle_helpers.gd")

var _frost_trail_mist: GPUParticles2D
var _frost_trail_spark: GPUParticles2D
var _frost_made: bool = false
var _impact_made: bool = false
var _snow_emitter: GPUParticles2D
var _snow_made: bool = false

# frost_mist — 비행 중 꽁무니. continuous emitter (첫 호출 시 만들고 매 프레임 위치 동기)
func _spawn_frost_mist(pos: Vector2, _intensity: float) -> void:
	if not _frost_made:
		_frost_made = true
		# mist 6/frame × intensity. continuous.
		_frost_trail_mist = _Helpers.make_emitter({
			"count": int(80 * _scale()), "lifetime": 0.75,
			"color": COL_MIST,
			"speed_min": 12.0, "speed_max": 30.0,
			"direction": Vector2.UP, "spread": 180.0,
			"gravity": -18.0, "damping": 3.0,
			"size_min": 6.0, "size_max": 18.0,
			"additive": false,
			"start_alpha": 0.4, "mid_alpha": 0.2, "end_alpha": 0.0,
			"emission_shape": "box", "emission_box": Vector2(5.0, 5.0),
			"one_shot": false, "explosiveness": 0.0,
		})
		add_child(_frost_trail_mist)
		# sparkle 3/frame × intensity
		_frost_trail_spark = _Helpers.make_emitter({
			"count": int(40 * _scale()), "lifetime": 0.85,
			"color": COL_HOT,
			"speed_min": 60.0, "speed_max": 84.0,
			"direction": Vector2.UP, "spread": 180.0,
			"gravity": 18.0, "damping": 3.0,
			"size_min": 1.2, "size_max": 2.4,
			"size_base": 4.0,
			"texture": _Helpers.sparkle_tex(),
			"one_shot": false, "explosiveness": 0.0,
			"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
		})
		add_child(_frost_trail_spark)
	if is_instance_valid(_frost_trail_mist):
		_frost_trail_mist.position = pos
		_frost_trail_spark.position = pos

func _spawn_impact_shatter(pos: Vector2) -> void:
	if _impact_made:
		return
	_impact_made = true
	# trail off
	if is_instance_valid(_frost_trail_mist): _frost_trail_mist.emitting = false
	if is_instance_valid(_frost_trail_spark): _frost_trail_spark.emitting = false
	# chunk 28 (회전 파편)
	var chunk := _Helpers.make_chunk_emitter(COL_BODY, _pcount(28), 1.2, 120.0, 420.0, 216.0, 3.0, 8.0)
	chunk.position = pos
	add_child(chunk)
	# mist 60 (큰 안개)
	var mist := _Helpers.make_emitter({
		"count": _pcount(60), "lifetime": 1.6, "color": COL_MIST,
		"speed_min": 48.0, "speed_max": 228.0,
		"direction": Vector2.UP, "spread": 180.0,
		"gravity": -36.0, "damping": 3.0,
		"size_min": 16.0, "size_max": 38.0,
		"additive": false,
		"start_alpha": 0.5, "mid_alpha": 0.25, "end_alpha": 0.0,
	})
	mist.position = pos
	add_child(mist)
	# sparkle 50 (반짝임)
	var sparkle := _Helpers.make_emitter({
		"count": _pcount(50), "lifetime": 1.5, "color": COL_HOT,
		"speed_min": 60.0, "speed_max": 300.0,
		"direction": Vector2.UP, "spread": 180.0,
		"gravity": 72.0, "damping": 3.0,
		"size_min": 1.0, "size_max": 2.4,
		"size_base": 4.0,
		"texture": _Helpers.sparkle_tex(),
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	sparkle.position = pos
	add_child(sparkle)

# snow — 명중 후 천천히 흩날림. continuous emitter.
func _spawn_snow() -> void:
	if _snow_made:
		return
	_snow_made = true
	_snow_emitter = _Helpers.make_emitter({
		"count": int(80 * _scale()), "lifetime": 2.4,
		"color": COL_HOT,
		"speed_min": 18.0, "speed_max": 48.0,
		"direction": Vector2.DOWN, "spread": 30.0,
		"gravity": 0.0, "damping": 3.0,
		"size_min": 1.2, "size_max": 2.4,
		"size_base": 4.0,
		"texture": _Helpers.sparkle_tex(),
		"emission_shape": "box", "emission_box": Vector2(120.0, 30.0),
		"one_shot": false, "explosiveness": 0.0,
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	_snow_emitter.position = _target + Vector2(0.0, -60.0)
	add_child(_snow_emitter)
	# super 의 snow timer 끝나면 off — 일정 시간 후 emit false
	get_tree().create_timer(2.0).timeout.connect(func() -> void:
		if is_instance_valid(_snow_emitter): _snow_emitter.emitting = false)
