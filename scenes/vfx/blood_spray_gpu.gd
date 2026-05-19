# scenes/vfx/blood_spray_gpu.gd
# 피 분출 GPU 하이브리드 — blood_spray.gd 상속.
# 원본 _draw: non-additive, color_ramp COL_BLOOD→COL_BLOOD_DARK, alpha=0.95×(1-k).
# 작은 핏방울 55 + 큰 14, dir_angle 방향 spread.
# streak (vel>2 시) → GPU 단순 원으로 근사.
extends "res://scenes/vfx/blood_spray.gd"

const _Helpers = preload("res://scenes/vfx/gpu_particle_helpers.gd")

func play(_caster_pos: Vector2, target_pos: Vector2, dir_angle: float = INF) -> void:
	var base_ang: float = dir_angle if is_finite(dir_angle) else -PI / 2.0
	var dir_vec := Vector2(cos(base_ang), sin(base_ang))
	# 작은 핏방울 55 — sp 3~11 × PSPEED 60 = 180~660, spread ±1.0 rad ≈ 57°
	var ramp_small := _Helpers.make_color_ramp(COL_BLOOD, COL_BLOOD, COL_BLOOD_DARK, 0.95, 0.5, 0.0)
	var small := _Helpers.make_emitter({
		"count": _pcount(55), "lifetime": 1.5, "color": COL_BLOOD,
		"speed_min": 180.0, "speed_max": 660.0,
		"direction": dir_vec, "spread": 57.0,
		"gravity": 648.0, "damping": 0.0,  # 0.18 × PSPEED² = 648
		"size_min": 1.6, "size_max": 3.8,
		"additive": false,
		"color_ramp": ramp_small,
	})
	small.position = target_pos
	add_child(small)
	# 큰 핏방울 14 — sp 4~9, spread ±0.9 rad ≈ 51°, gravity 0.22 × 3600 = 792
	var ramp_big := _Helpers.make_color_ramp(COL_BLOOD, COL_BLOOD, COL_BLOOD_DARK, 0.95, 0.5, 0.0)
	var big := _Helpers.make_emitter({
		"count": _pcount(14), "lifetime": 1.8, "color": COL_BLOOD,
		"speed_min": 240.0, "speed_max": 540.0,
		"direction": dir_vec, "spread": 51.0,
		"gravity": 792.0, "damping": 0.0,
		"size_min": 3.0, "size_max": 6.0,
		"additive": false,
		"color_ramp": ramp_big,
	})
	big.position = target_pos
	add_child(big)
	# super 의 _run() 만 호출 — _particles 비어있으니 super._process 는 무해.
	set_process(true)
	_run()
