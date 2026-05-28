# scenes/vfx/bite_attack_gpu.gd
# 물기 공격 GPU 하이브리드 — bite_attack.gd 상속.
# 본체 (snarl/jaws/punctures) + drip line 은 CPU 유지 (동적 형태).
# blood burst 86 + bone 10 + drip 파티클을 GPUParticles2D 로 대체.
extends "res://scenes/vfx/bite_attack.gd"

const _Helpers = preload("res://scenes/vfx/gpu_particle_helpers.gd")

var _drip_emitter: GPUParticles2D

# 초기 blood burst — 70 작은 + 16 큰 + 10 bone
func _spawn_blood_burst() -> void:
	var pos: Vector2 = _target + JAWS_OFFSET
	# 작은 spray 70 — ±162° (위 헤미스피어 + α), 어두운 빨강 일반 블렌드
	var small := _Helpers.make_emitter({
		"count": _pcount(70), "lifetime": 1.6, "color": COL_BLOOD,
		"speed_min": 180.0, "speed_max": 720.0,
		"direction": Vector2.UP, "spread": 162.0,
		"gravity": 10.8,
		"size_min": 1.4, "size_max": 3.8,
		"additive": false,
		"start_alpha": 0.95, "mid_alpha": 0.55, "end_alpha": 0.0,
	})
	small.position = pos
	add_child(small)
	# 큰 fat 16 — ±108°, 더 멀리/오래
	var fat := _Helpers.make_emitter({
		"count": _pcount(16), "lifetime": 2.0, "color": COL_BLOOD,
		"speed_min": 240.0, "speed_max": 540.0,
		"direction": Vector2.UP, "spread": 108.0,
		"gravity": 14.4,
		"size_min": 3.0, "size_max": 6.4,
		"additive": false,
		"start_alpha": 0.95, "mid_alpha": 0.55, "end_alpha": 0.0,
	})
	fat.position = pos
	add_child(fat)
	# 뼈 10 — ±126°, 회전
	var bone := _Helpers.make_emitter({
		"count": _pcount(10), "lifetime": 1.2, "color": COL_BONE_MID,
		"speed_min": 240.0, "speed_max": 540.0,
		"direction": Vector2.UP, "spread": 126.0,
		"gravity": 10.8,
		"size_min": 2.8, "size_max": 6.0,
		"size_base": 48.0,  # square_tex 가로 48 → 화면 가로 = size
		"texture": _Helpers.square_tex(),
		"additive": false,
		"angle_min": -180.0, "angle_max": 180.0,
		"angular_velocity_min": -360.0, "angular_velocity_max": 360.0,
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	bone.position = pos
	add_child(bone)

# drip burst — 부모 _process 가 0.12s 마다 호출. GPU continuous emitter 1개로 통합 — 1회만 만들고
# emitting on/off 로 제어. CPU 부모는 _particles 안 채움.
func _spawn_drip() -> void:
	var pos: Vector2 = _target + JAWS_OFFSET
	if _drip_emitter == null:
		# continuous emitter — DRIP_TIME 동안 25/s ≈ 1.6초 동안 ~40 동시
		_drip_emitter = _Helpers.make_emitter({
			"count": int(40 * _scale()), "lifetime": 1.6, "color": COL_BLOOD,
			"speed_min": 24.0, "speed_max": 60.0,
			"direction": Vector2.DOWN, "spread": 8.0,
			"gravity": 7.2,
			"size_min": 2.0, "size_max": 3.5,
			"emission_shape": "box", "emission_box": Vector2(20.0, 15.0),
			"one_shot": false, "explosiveness": 0.0,
			"additive": false,
			"start_alpha": 0.9, "mid_alpha": 0.5, "end_alpha": 0.0,
		})
		_drip_emitter.position = pos + Vector2(0.0, 10.0)
		add_child(_drip_emitter)
		# DRIP_TIME 후 emitting off
		get_tree().create_timer(DRIP_TIME).timeout.connect(func() -> void:
			if is_instance_valid(_drip_emitter):
				_drip_emitter.emitting = false)
