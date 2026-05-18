# scenes/vfx/holy_arrow_gpu.gd
# 신성 화살 GPU 하이브리드 — holy_arrow.gd 상속.
# channel mote / muzzle spark / impact (spark + haze) GPU 화. 후광/화살/십자가 CPU.
extends "res://scenes/vfx/holy_arrow.gd"

const _Helpers = preload("res://scenes/vfx/gpu_particle_helpers.gd")

var _gpu_channel: GPUParticles2D
var _channel_made: bool = false
var _muzzle_made: bool = false
var _impact_made: bool = false

# 채널 mote — 0.7 확률/frame × 60 = 42/s × lifetime 1.2 ≈ 50 동시
func _spawn_channel_mote() -> void:
	if _channel_made:
		return
	_channel_made = true
	_gpu_channel = _Helpers.make_emitter({
		"count": int(50 * _scale()),
		"lifetime": 1.2,
		"color": COL_MID,
		"speed_min": 24.0, "speed_max": 60.0,
		"direction": Vector2.UP, "spread": 25.0,
		"gravity": -18.0, "damping": 60.0,
		"size_min": 1.4, "size_max": 2.8,
		"size_base": 4.0,
		"emission_shape": "box", "emission_box": Vector2(11.0, 8.0),
		"texture": _Helpers.sparkle_tex(),
		"one_shot": false, "explosiveness": 0.0,
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	_gpu_channel.position = _caster + Vector2(0.0, -22.0)
	add_child(_gpu_channel)
	get_tree().create_timer(DRAW_TIME).timeout.connect(func() -> void:
		if is_instance_valid(_gpu_channel): _gpu_channel.emitting = false)

# 머즐 14 — dir 방향 cone 으로 spark
func _spawn_muzzle() -> void:
	if _muzzle_made:
		return
	_muzzle_made = true
	var dir := (_target - _caster).normalized()
	var emitter := _Helpers.make_emitter({
		"count": _pcount(14), "lifetime": 0.48,
		"color": COL_MID,
		"speed_min": 240.0, "speed_max": 660.0,  # 4~11 * 60
		"direction": dir, "spread": 14.3,  # ±0.25 rad
		"gravity": 144.0, "damping": 60.0,
		"size_min": 1.2, "size_max": 2.6,
		"size_base": 4.0,
		"texture": _Helpers.sparkle_tex(),
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	emitter.position = _caster
	add_child(emitter)

# 명중 — spark 20 (반사 방향) + haze 14
func _spawn_impact(pos: Vector2, ang: float) -> void:
	if _impact_made:
		return
	_impact_made = true
	# spark 20 — 반사 방향 (ang+PI) ±0.7 rad cone, speed 2~8*60
	var bounce_dir := Vector2(cos(ang + PI), sin(ang + PI))
	var spark := _Helpers.make_emitter({
		"count": _pcount(20), "lifetime": 0.8,
		"color": COL_MID,
		"speed_min": 120.0, "speed_max": 480.0,
		"direction": bounce_dir, "spread": 40.0,
		"gravity": 648.0, "damping": 60.0,  # 0.18*60²
		"size_min": 1.0, "size_max": 2.3,
		"size_base": 4.0,
		"texture": _Helpers.sparkle_tex(),
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	spark.position = pos
	add_child(spark)
	# haze 14 — 사방 안개
	var haze := _Helpers.make_emitter({
		"count": _pcount(14), "lifetime": 1.9,
		"color": COL_HAZE,
		"speed_min": 30.0, "speed_max": 96.0,
		"direction": Vector2.UP, "spread": 180.0,
		"gravity": -28.8, "damping": 60.0,
		"size_min": 11.0, "size_max": 20.0,
		"additive": false,
		"start_alpha": 0.5, "mid_alpha": 0.25, "end_alpha": 0.0,
	})
	haze.position = pos
	add_child(haze)
