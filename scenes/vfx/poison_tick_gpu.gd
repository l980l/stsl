# scenes/vfx/poison_tick_gpu.gd
# 독 틱 GPU 하이브리드 — poison_tick.gd 상속.
# 원본 _draw_smoke_pass (non-additive):
#   - gas: COL_GAS alpha (1-k)×0.4, 크기 1→2.4배 확장
#   - bubble: COL_DRIP 채움 0.25×a + DRIP_HL ring 0.7×a + 흰 하이라이트
# puddle (ground) 폴리곤 → CPU 유지.
extends "res://scenes/vfx/poison_tick.gd"

const _Helpers = preload("res://scenes/vfx/gpu_particle_helpers.gd")

var _gpu_gas: GPUParticles2D
var _gpu_bubble: GPUParticles2D
var _amb_made: bool = false

static func _gas_scale_curve() -> Curve:
	var c := Curve.new()
	c.add_point(Vector2(0.0, 1.0))
	c.add_point(Vector2(1.0, 2.4))
	return c

func _spawn_ambient() -> void:
	if _amb_made:
		return
	_amb_made = true
	# gas: 0.7/frame × 60 × lifetime 2.0 ≈ 84 동시. 위로 천천히.
	_gpu_gas = _Helpers.make_emitter({
		"count": int(84 * _scale()), "lifetime": 2.0, "color": COL_GAS,
		"speed_min": 24.0, "speed_max": 54.0,
		"direction": Vector2.UP, "spread": 12.0,
		"gravity": -18.0, "damping": 0.0,
		"size_min": 12.0, "size_max": 24.0,
		"scale_curve": _gas_scale_curve(),
		"additive": false,
		"emission_shape": "box", "emission_box": Vector2(35.0, 15.0),
		"one_shot": false, "explosiveness": 0.0,
		"start_alpha": 0.4, "mid_alpha": 0.2, "end_alpha": 0.0,
	})
	_gpu_gas.position = _target + Vector2(0.0, 40.0)
	add_child(_gpu_gas)
	# bubble: 0.4/frame × 60 × lifetime 1.15 ≈ 28 동시. 위로.
	_gpu_bubble = _Helpers.make_emitter({
		"count": int(28 * _scale()), "lifetime": 1.15, "color": COL_DRIP_HL,  # 밝은 녹 (ring 색 매칭)
		"speed_min": 36.0, "speed_max": 78.0,
		"direction": Vector2.UP, "spread": 8.0,
		"gravity": 0.0, "damping": 0.0,
		"size_min": 3.0, "size_max": 7.0,
		"additive": false,
		"emission_shape": "box", "emission_box": Vector2(30.0, 15.0),
		"one_shot": false, "explosiveness": 0.0,
		"start_alpha": 0.8, "mid_alpha": 0.4, "end_alpha": 0.0,
	})
	_gpu_bubble.position = _target + Vector2(0.0, 55.0)
	add_child(_gpu_bubble)
	get_tree().create_timer(TICK_TIME).timeout.connect(func() -> void:
		if is_instance_valid(_gpu_gas): _gpu_gas.emitting = false
		if is_instance_valid(_gpu_bubble): _gpu_bubble.emitting = false)
