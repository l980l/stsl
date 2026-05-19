# scenes/vfx/slow_debuff_gpu.gd
# 둔화 디버프 GPU 하이브리드 — slow_debuff.gd 상속.
# mist + drip + bubble GPU. spiral (나선 수렴) 은 CPU 유지.
extends "res://scenes/vfx/slow_debuff.gd"

const _Helpers = preload("res://scenes/vfx/gpu_particle_helpers.gd")

var _peak_made: bool = false
var _gpu_amb_drip: GPUParticles2D
var _gpu_amb_mist: GPUParticles2D
var _gpu_amb_bubble: GPUParticles2D
var _amb_made: bool = false

func _process(delta: float) -> void:
	super._process(delta)
	var ga: float = _global_alpha()
	for child in get_children():
		if child is GPUParticles2D:
			child.modulate.a = ga

# mist GPU + spiral CPU (super 호출 X)
func _spawn_peak_burst() -> void:
	if _peak_made:
		return
	_peak_made = true
	var foot: Vector2 = _foot_pos()
	# 바닥 mist 14 (보라 안개 — 원본 ground_layer 가산 + COL_MID)
	var mist := _Helpers.make_emitter({
		"count": _pcount(14), "lifetime": 1.5, "color": COL_MID,
		"speed_min": 60.0, "speed_max": 120.0,
		"direction": Vector2.UP, "spread": 130.0,
		"gravity": -18.0, "damping": 3.0,
		"size_min": 12.0, "size_max": 24.0,
		"start_alpha": 0.4, "mid_alpha": 0.2, "end_alpha": 0.0,
	})
	mist.position = foot
	add_child(mist)
	# spiral CPU 20 — _process 의 spiral 위치 계산 필요
	for _i in range(_pcount(20)):
		var ang := randf() * TAU
		var dist := 110.0 + randf() * 50.0
		var sx := _target.x + cos(ang) * dist
		var sy := _target.y + sin(ang) * dist * 0.4 - 30.0
		_particles.append({
			"pos": Vector2(sx, sy),
			"vel": Vector2.ZERO,
			"life": 0.0,
			"max_life": 0.8 + randf() * 0.4,
			"size": 1.4 + randf() * 1.2,
			"kind": "spiral",
			"start_ang": ang,
			"start_dist": dist,
		})

# ambient — drip + mist + bubble GPU continuous
func _spawn_ambient() -> void:
	if _amb_made:
		return
	_amb_made = true
	var foot: Vector2 = _foot_pos()
	# drip 0.35/frame × 60 × lifetime 1.0 ≈ 21 동시 (보라 방울 — 작은 원형, 가산)
	_gpu_amb_drip = _Helpers.make_emitter({
		"count": int(21 * _scale()), "lifetime": 1.0, "color": COL_MID,
		"speed_min": 24.0, "speed_max": 48.0,
		"direction": Vector2.DOWN, "spread": 12.0,
		"gravity": 108.0, "damping": 3.0,
		"size_min": 2.4, "size_max": 3.8,
		"emission_shape": "box", "emission_box": Vector2(70.0, 8.0),
		"one_shot": false, "explosiveness": 0.0,
		"start_alpha": 0.9, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	_gpu_amb_drip.position = foot + Vector2(0.0, -18.0)
	add_child(_gpu_amb_drip)
	# mist 0.5/frame × 60 × lifetime 1.7 ≈ 51 동시 (가산 + COL_MID 밝은 보라)
	_gpu_amb_mist = _Helpers.make_emitter({
		"count": int(51 * _scale()), "lifetime": 1.7, "color": COL_MID,
		"speed_min": 12.0, "speed_max": 30.0,
		"direction": Vector2.UP, "spread": 60.0,
		"gravity": -10.8, "damping": 3.0,
		"size_min": 12.0, "size_max": 22.0,
		"emission_shape": "box", "emission_box": Vector2(80.0, 4.0),
		"one_shot": false, "explosiveness": 0.0,
		"start_alpha": 0.4, "mid_alpha": 0.2, "end_alpha": 0.0,
	})
	_gpu_amb_mist.position = foot + Vector2(0.0, -2.0)
	add_child(_gpu_amb_mist)
	# bubble 0.2/frame × 60 × lifetime 0.65 ≈ 8 동시 (가산, COL_MID 내부 흐릿 + COL_HOT 외곽)
	_gpu_amb_bubble = _Helpers.make_emitter({
		"count": int(8 * _scale()), "lifetime": 0.65, "color": COL_MID,
		"speed_min": 18.0, "speed_max": 30.0,
		"direction": Vector2.UP, "spread": 12.0,
		"gravity": 0.0, "damping": 3.0,
		"size_min": 3.0, "size_max": 5.0,
		"emission_shape": "box", "emission_box": Vector2(60.0, 2.0),
		"one_shot": false, "explosiveness": 0.0,
		"start_alpha": 0.5, "mid_alpha": 0.3, "end_alpha": 0.0,
	})
	_gpu_amb_bubble.position = foot + Vector2(0.0, -2.0)
	add_child(_gpu_amb_bubble)
	get_tree().create_timer(DEBUFF_TIME).timeout.connect(func() -> void:
		if is_instance_valid(_gpu_amb_drip): _gpu_amb_drip.emitting = false
		if is_instance_valid(_gpu_amb_mist): _gpu_amb_mist.emitting = false
		if is_instance_valid(_gpu_amb_bubble): _gpu_amb_bubble.emitting = false)
