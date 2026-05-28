# scenes/vfx/needle_sting_gpu.gd
# 전갈 침 GPU 하이브리드 — needle_sting.gd 상속.
# 본체 베지어 ribbon/마디/barb/puncture/motion blur 는 CPU 유지 (동적 형태 — GPU 표현 불가).
# 피 22+5 + 뼈 6 의 표준 파티클만 GPUParticles2D 로 대체 → _particles 빈 채 유지.
extends "res://scenes/vfx/needle_sting.gd"

const _Helpers = preload("res://scenes/vfx/gpu_particle_helpers.gd")

# CPU 부모의 _spawn_blood override — _particles array 비워두고 GPU emitter 만 spawn
func _spawn_blood(impact_pos: Vector2) -> void:
	# 작은 피 22 — 위 헤미스피어 사방 (HTML -PI/2 ± 0.7PI = ±126°), 어두운 빨강 일반 블렌드
	# HTML sp 2~5 px/frame → Godot 120~300 px/s. grav 0.22 → 13.2 px/s².
	var small := _Helpers.make_emitter({
		"count": _pcount(22), "lifetime": 1.0, "color": COL_BLOOD,
		"speed_min": 120.0, "speed_max": 300.0,
		"direction": Vector2.UP, "spread": 126.0,
		"gravity": 13.2,
		"size_min": 1.4, "size_max": 3.2,
		"additive": false,
		"start_alpha": 0.95, "mid_alpha": 0.55, "end_alpha": 0.0,
	})
	small.position = impact_pos
	add_child(small)
	# 큰 피 5 — 위로 좁게 (±28°), 더 멀리/오래
	var large := _Helpers.make_emitter({
		"count": _pcount(5), "lifetime": 1.5, "color": COL_BLOOD,
		"speed_min": 180.0, "speed_max": 420.0,
		"direction": Vector2.UP, "spread": 28.0,
		"gravity": 14.4,
		"size_min": 2.6, "size_max": 4.6,
		"additive": false,
		"start_alpha": 0.95, "mid_alpha": 0.55, "end_alpha": 0.0,
	})
	large.position = impact_pos
	add_child(large)
	# 뼈 조각 6 — 전방위 + 위 bias + 회전 (square_tex 직사각형)
	var bone := _Helpers.make_emitter({
		"count": _pcount(6), "lifetime": 0.7, "color": COL_BONE_MID,
		"speed_min": 90.0, "speed_max": 270.0,
		"direction": Vector2(0.0, -0.3), "spread": 180.0,
		"gravity": 10.8,
		"size_min": 3.2, "size_max": 7.0,
		"size_base": 48.0,  # square_tex 48×64 → 화면 가로 = size
		"texture": _Helpers.square_tex(),
		"additive": false,
		"angle_min": -180.0, "angle_max": 180.0,
		"angular_velocity_min": -360.0, "angular_velocity_max": 360.0,
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	bone.position = impact_pos
	add_child(bone)
