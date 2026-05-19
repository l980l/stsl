# scenes/vfx/card_exhaust_gpu.gd
# 카드 소각 GPU 하이브리드 — card_exhaust.gd 상속.
# 원본 _draw 매칭:
#   - ember: glow(add) COL_EMBER 코어+헤일로 (pr*1.8 alpha 0.45). spawn at sweep_y.
#   - ash: ash_layer(non-add) COL_ASH alpha (1-k)×0.85. 회전 ellipse.
# spawn 위치가 sweep_y 따라 동적 → emitter.position 매 frame 업데이트.
# ember line / flash 폴리곤 → CPU 유지.
extends "res://scenes/vfx/card_exhaust.gd"

const _Helpers = preload("res://scenes/vfx/gpu_particle_helpers.gd")

var _gpu_ember: GPUParticles2D
var _gpu_ash: GPUParticles2D
var _spawn_made: bool = false

func _process(delta: float) -> void:
	super._process(delta)
	var ga: float = _global_alpha()
	# emitter position 매 frame 업데이트 (sweep_y 추적)
	if _impact_emitted and _age < IMPACT_DELAY + SWEEP_TIME:
		var rect := _card_rect()
		var sy: float = _sweep_y()
		var cx: float = rect.position.x + rect.size.x * 0.5
		if is_instance_valid(_gpu_ember): _gpu_ember.position = Vector2(cx, sy)
		if is_instance_valid(_gpu_ash): _gpu_ash.position = Vector2(cx, sy + 5.0)
	for child in get_children():
		if child is GPUParticles2D:
			child.modulate.a = ga

func _spawn_ember() -> void:
	if not _spawn_made:
		_make_emitters()

func _spawn_ash() -> void:
	if not _spawn_made:
		_make_emitters()

func _make_emitters() -> void:
	_spawn_made = true
	var rect := _card_rect()
	# ember: 2/frame × 60 × lifetime 1.1 ≈ 132 동시. 위로 (-1~-2.4 × PSPEED).
	_gpu_ember = _Helpers.make_emitter({
		"count": int(132 * _scale()), "lifetime": 1.1, "color": COL_EMBER,
		"speed_min": 60.0, "speed_max": 144.0,
		"direction": Vector2.UP, "spread": 15.0,
		"gravity": 0.0, "damping": 0.0,
		"size_min": 1.4, "size_max": 2.8,
		"size_base": 16.0,
		"texture": _Helpers.mote_halo_tex(),
		"emission_shape": "box", "emission_box": Vector2(rect.size.x * 0.5, 10.0),
		"one_shot": false, "explosiveness": 0.0,
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	add_child(_gpu_ember)
	# ash: 0.6/frame × 60 × lifetime 1.8 ≈ 65 동시. 아래로 (0.5~1.5 × PSPEED).
	_gpu_ash = _Helpers.make_emitter({
		"count": int(65 * _scale()), "lifetime": 1.8, "color": COL_ASH,
		"speed_min": 30.0, "speed_max": 90.0,
		"direction": Vector2.DOWN, "spread": 15.0,
		"gravity": 0.0, "damping": 0.0,
		"size_min": 1.8, "size_max": 3.2,
		"size_base": 32.0,
		"texture": _Helpers.square_tex(),  # 회전 시각화 위해
		"angle_min": 0.0, "angle_max": 360.0,
		"angular_velocity_min": -115.0, "angular_velocity_max": 115.0,  # rad → deg 변환 ±2
		"additive": false,
		"emission_shape": "box", "emission_box": Vector2(rect.size.x * 0.5, 10.0),
		"one_shot": false, "explosiveness": 0.0,
		"start_alpha": 0.85, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	add_child(_gpu_ash)
	get_tree().create_timer(SWEEP_TIME).timeout.connect(func() -> void:
		if is_instance_valid(_gpu_ember): _gpu_ember.emitting = false
		if is_instance_valid(_gpu_ash): _gpu_ash.emitting = false)
