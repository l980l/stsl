# scenes/vfx/holy_fire_gpu.gd
# 성스러운 화염 GPU 하이브리드 — holy_fire.gd 상속 + GPU emitter.
# trail/explosion/burn 의 ember/flame/fireball/smoke → GPUParticles2D.
# 차지 오브, 투사체 머리, 충격파, 열기 펄스 → CPU 폴리곤 그대로.
extends "res://scenes/vfx/holy_fire.gd"

const _Helpers = preload("res://scenes/vfx/gpu_particle_helpers.gd")

var _gpu_trail_smoke: GPUParticles2D
var _gpu_trail_flame: GPUParticles2D
var _gpu_trail_ember: GPUParticles2D
var _gpu_burn_flame: GPUParticles2D
var _gpu_burn_ember: GPUParticles2D
var _trail_made: bool = false
var _burn_made: bool = false
var _exploded: bool = false

func _spawn_trail(_pos: Vector2) -> void:
	if not _trail_made:
		_trail_made = true
		_gpu_trail_smoke = _Helpers.make_emitter({
			"count": int(280 * _scale()), "lifetime": 0.6, "color": COL_SMOKE,
			"speed_min": 18.0, "speed_max": 54.0,
			"direction": Vector2.UP, "spread": 180.0,
			"gravity": -18.0, "size_min": 8.0, "size_max": 24.0,
			"additive": false,
			"start_alpha": 0.35, "mid_alpha": 0.18, "end_alpha": 0.0,
			"one_shot": false, "explosiveness": 0.0,
		})
		_gpu_trail_smoke.z_index = -1
		add_child(_gpu_trail_smoke)
		_gpu_trail_flame = _Helpers.make_emitter({
			"count": int(900 * _scale()), "lifetime": 0.4, "color": COL_HOT,
			"speed_min": 36.0, "speed_max": 90.0,
			"direction": Vector2.UP, "spread": 180.0,
			"gravity": -72.0, "size_min": 3.0, "size_max": 8.0,
			"one_shot": false, "explosiveness": 0.0,
		})
		add_child(_gpu_trail_flame)
		_gpu_trail_ember = _Helpers.make_emitter({
			"count": int(120 * _scale()), "lifetime": 0.9, "color": COL_DEEP,
			"speed_min": 60.0, "speed_max": 210.0,
			"direction": Vector2.UP, "spread": 180.0,
			"gravity": 72.0, "size_min": 1.4, "size_max": 2.6,
			"one_shot": false, "explosiveness": 0.0,
		})
		add_child(_gpu_trail_ember)
	# 매 프레임 위치 갱신 — super 의 _proj_t 사용
	if is_instance_valid(_gpu_trail_smoke):
		var pp: Vector2 = _pos
		_gpu_trail_smoke.position = pp
		_gpu_trail_flame.position = pp
		_gpu_trail_ember.position = pp

func _spawn_explosion(pos: Vector2) -> void:
	if _exploded:
		return
	_exploded = true
	# trail emitter 끄기
	if is_instance_valid(_gpu_trail_smoke): _gpu_trail_smoke.emitting = false
	if is_instance_valid(_gpu_trail_flame): _gpu_trail_flame.emitting = false
	if is_instance_valid(_gpu_trail_ember): _gpu_trail_ember.emitting = false
	# smoke 먼저 (z 가장 뒤)
	var smoke := _Helpers.make_emitter({
		"count": _pcount(40), "lifetime": 1.85, "color": COL_SMOKE,
		"speed_min": 36.0, "speed_max": 132.0,
		"direction": Vector2.UP, "spread": 50.0,
		"gravity": -36.0, "damping": 60.0,
		"size_min": 26.0, "size_max": 56.0,
		"additive": false,
		"start_alpha": 0.35, "mid_alpha": 0.17, "end_alpha": 0.0,
		"emission_shape": "box", "emission_box": Vector2(30.0, 20.0),
	})
	smoke.position = pos
	smoke.z_index = -1
	add_child(smoke)
	# fireball — holy 색 3단계 (흰코어 → 황금 → 진금)
	var fireball := _Helpers.make_emitter({
		"count": _pcount(70), "lifetime": 0.75, "color": COL_MID,
		"speed_min": 60.0, "speed_max": 360.0,
		"direction": Vector2.UP, "spread": 180.0,
		"gravity": -54.0, "damping": 60.0,
		"size_min": 14.0, "size_max": 36.0,
		"color_ramp": _Helpers.make_color_ramp(COL_HOT, COL_MID, COL_DEEP, 0.9, 0.75, 0.0),
	})
	fireball.position = pos
	add_child(fireball)
	var ember := _Helpers.make_emitter({
		"count": _pcount(80), "lifetime": 1.05, "color": COL_HOT,
		"speed_min": 120.0, "speed_max": 540.0,
		"direction": Vector2.UP, "spread": 180.0,
		"gravity": 162.0, "damping": 60.0,
		"size_min": 1.6, "size_max": 3.2,
		"color_ramp": _Helpers.make_color_ramp(COL_HOT, COL_MID, COL_DEEP, 1.0, 0.6, 0.0),
	})
	ember.position = pos
	add_child(ember)

func _spawn_burn() -> void:
	if _burn_made:
		return
	_burn_made = true
	_gpu_burn_flame = _Helpers.make_emitter({
		"count": int(25 * _scale()), "lifetime": 0.6, "color": COL_HOT,
		"speed_min": 24.0, "speed_max": 66.0,
		"direction": Vector2.UP, "spread": 18.0,
		"gravity": -72.0, "damping": 60.0,
		"size_min": 4.0, "size_max": 11.0,
		"emission_shape": "box", "emission_box": Vector2(20.0, 5.0),
		"one_shot": false, "explosiveness": 0.0,
		"color_ramp": _Helpers.make_color_ramp(COL_HOT, COL_MID, COL_DEEP, 0.9, 0.7, 0.0),
	})
	_gpu_burn_flame.position = _target
	add_child(_gpu_burn_flame)
	_gpu_burn_ember = _Helpers.make_emitter({
		"count": int(20 * _scale()), "lifetime": 0.85, "color": COL_MID,
		"speed_min": 48.0, "speed_max": 102.0,
		"direction": Vector2.UP, "spread": 25.0,
		"gravity": 36.0, "damping": 60.0,
		"size_min": 1.2, "size_max": 2.2,
		"emission_shape": "box", "emission_box": Vector2(18.0, 4.0),
		"one_shot": false, "explosiveness": 0.0,
		"color_ramp": _Helpers.make_color_ramp(COL_HOT, COL_MID, COL_DEEP, 1.0, 0.6, 0.0),
	})
	_gpu_burn_ember.position = _target
	add_child(_gpu_burn_ember)
	get_tree().create_timer(BURN_TIME).timeout.connect(func() -> void:
		if is_instance_valid(_gpu_burn_flame): _gpu_burn_flame.emitting = false
		if is_instance_valid(_gpu_burn_ember): _gpu_burn_ember.emitting = false)
