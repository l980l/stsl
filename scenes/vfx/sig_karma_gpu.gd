# scenes/vfx/sig_karma_gpu.gd
# 카르마 GPU 하이브리드 — sig_karma.gd 상속.
# _spawn_petal (반복 spawn, petal 회전 + 위로 부유) → GPU continuous emitter.
# 연꽃, ring, beam 폴리곤 CPU.
extends "res://scenes/vfx/sig_karma.gd"

const _Helpers = preload("res://scenes/vfx/gpu_particle_helpers.gd")

var _gpu_petal: GPUParticles2D
var _made: bool = false

# 원본: 0.5 확률/frame × _scale × 60fps = 15/s × lifetime 2.2 = ~33 동시.
# vel (cos*sp, sin*sp*0.5 - 0.3), sp 0.6~1.6 → speed 36~96 + y bias -18.
# size 2.2~3.8, rot_v ±1.5 rad/s = ±86°/s (느린 회전).
func _spawn_petal() -> void:
	if _made:
		return
	_made = true
	_gpu_petal = _Helpers.make_emitter({
		"count": int(33 * _scale()),
		"lifetime": 2.2,
		"color": COL_LOTUS,
		"speed_min": 36.0, "speed_max": 96.0,
		"direction": Vector2.UP, "spread": 180.0,
		"gravity": 18.0, "damping": 3.0,
		"size_min": 2.2, "size_max": 3.8,
		"size_base": 30.0,  # feather_tex 긴축 매핑 (꽃잎 모양 근사)
		"angle_min": -180.0, "angle_max": 180.0,
		"angular_velocity_min": -86.0, "angular_velocity_max": 86.0,
		"additive": false,
		"texture": _Helpers.feather_tex(),  # 꽃잎 = 타원 모양
		"one_shot": false, "explosiveness": 0.0,
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	_gpu_petal.position = _caster
	add_child(_gpu_petal)
	get_tree().create_timer(HOLD_TIME).timeout.connect(func() -> void:
		if is_instance_valid(_gpu_petal): _gpu_petal.emitting = false)
