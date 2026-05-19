# scenes/vfx/death_dissolve_gpu.gd
# 죽음 분해 GPU 하이브리드 — death_dissolve.gd 상속.
# 원본 _draw:
#   - ash: smoke(non-add) 회색 사각형 회전. 색 (0.51,0.51,0.55) → (0.35,0.35,0.39) 시간따라 어두워짐.
#   - soul: glow(add) 헤일로 r*4 alpha 0.2 + 중층 r*2 alpha 0.32 + 코어.
# pool (ground) 폴리곤 → CPU 유지.
extends "res://scenes/vfx/death_dissolve.gd"

const _Helpers = preload("res://scenes/vfx/gpu_particle_helpers.gd")

var _gpu_ash: GPUParticles2D
var _gpu_soul: GPUParticles2D
var _emit_made: bool = false

func _process(delta: float) -> void:
	super._process(delta)
	# death_dissolve 는 _global_alpha 없음 — modulate 1.0 유지 (입자 자체 fade)

func _spawn_ash() -> void:
	if not _emit_made:
		_make_emitters()

func _spawn_soul() -> void:
	if not _emit_made:
		_make_emitters()

func _make_emitters() -> void:
	_emit_made = true
	# ash: 0.7/frame × 60 × lifetime 2.2 ≈ 92 동시. 위로 천천히 + 회전.
	var ash_ramp := _Helpers.make_color_ramp(
		Color(0.51, 0.51, 0.55), Color(0.43, 0.43, 0.47), Color(0.35, 0.35, 0.39),
		0.85, 0.5, 0.0)
	_gpu_ash = _Helpers.make_emitter({
		"count": int(92 * _scale()), "lifetime": 2.2, "color": Color.WHITE,
		"speed_min": 18.0, "speed_max": 60.0,
		"direction": Vector2.UP, "spread": 30.0,
		"gravity": -18.0, "damping": 0.0,
		"size_min": 1.4, "size_max": 3.2,
		"size_base": 32.0,
		"texture": _Helpers.square_tex(),
		"angle_min": 0.0, "angle_max": 360.0,
		"angular_velocity_min": -137.0, "angular_velocity_max": 137.0,  # ±0.04 × PSPEED × 360/(2π)
		"additive": false,
		"color_ramp": ash_ramp,
		"emission_shape": "box", "emission_box": Vector2(40.0, 60.0),
		"one_shot": false, "explosiveness": 0.0,
	})
	_gpu_ash.position = _target + Vector2(0.0, -10.0)
	add_child(_gpu_ash)
	# soul: 0.5/frame × 60 × lifetime 2.5 ≈ 75 동시. 위로 + sway (GPU 단순화).
	_gpu_soul = _Helpers.make_emitter({
		"count": int(75 * _scale()), "lifetime": 2.5, "color": COL_SOUL_HOT,
		"speed_min": 48.0, "speed_max": 96.0,
		"direction": Vector2.UP, "spread": 12.0,
		"gravity": -43.2, "damping": 0.0,  # grav -0.012 × PSPEED²
		"size_min": 3.0, "size_max": 7.0,
		"size_base": 16.0,
		"texture": _Helpers.mote_halo_tex(),
		"emission_shape": "box", "emission_box": Vector2(15.0, 20.0),
		"one_shot": false, "explosiveness": 0.0,
		"start_alpha": 0.85, "mid_alpha": 0.45, "end_alpha": 0.0,
	})
	_gpu_soul.position = _target
	add_child(_gpu_soul)
	get_tree().create_timer(DISSOLVE_TIME).timeout.connect(func() -> void:
		if is_instance_valid(_gpu_ash): _gpu_ash.emitting = false
		if is_instance_valid(_gpu_soul): _gpu_soul.emitting = false)
