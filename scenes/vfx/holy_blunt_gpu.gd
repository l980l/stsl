# scenes/vfx/holy_blunt_gpu.gd
# 신성 둔기 GPU 하이브리드 — holy_blunt.gd 상속.
# feather (큰) / feather_small / spark GPU 화. 슬램 모션·크랙·후광 폴리곤 CPU.
extends "res://scenes/vfx/holy_blunt.gd"

const _Helpers = preload("res://scenes/vfx/gpu_particle_helpers.gd")

var _impact_made: bool = false

func _spawn_impact_feathers() -> void:
	if _impact_made:
		return
	_impact_made = true
	var gy: Vector2 = _ground_pos if _has_ground else _target + Vector2(0.0, 80.0)
	# 큰 깃털 20 — 옆으로 튀는 메인. speed 3~9*60=180~540, gravity 0.06*60²=216
	var feather := _Helpers.make_emitter({
		"count": _pcount(20), "lifetime": 2.1,
		"color": COL_FEATHER_HI,
		"speed_min": 180.0, "speed_max": 540.0,
		"direction": Vector2.UP, "spread": 90.0,
		"gravity": 216.0, "damping": 60.0,
		"size_min": 9.0, "size_max": 14.0,
		"size_base": 30.0,
		"angle_min": -180.0, "angle_max": 180.0,
		"angular_velocity_min": -2062.0, "angular_velocity_max": 2062.0,  # ±0.6 rad×60
		"additive": false,
		"texture": _Helpers.feather_tex(),
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	feather.position = gy
	add_child(feather)
	# 작은 깃털 28 — 흩어지는 잔깃털. speed * DUST_SCALE 0.5
	var feather_small := _Helpers.make_emitter({
		"count": _pcount(28), "lifetime": 2.3,
		"color": COL_FEATHER_HI,
		"speed_min": 60.0, "speed_max": 210.0,
		"direction": Vector2.UP, "spread": 90.0,
		"gravity": 108.0, "damping": 60.0,
		"size_min": 5.0, "size_max": 8.0,
		"size_base": 30.0,
		"angle_min": -180.0, "angle_max": 180.0,
		"angular_velocity_min": -1375.0, "angular_velocity_max": 1375.0,
		"additive": false,
		"texture": _Helpers.feather_tex(),
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	feather_small.position = gy
	add_child(feather_small)
	# 위로 솟는 작은 깃털 14
	var feather_rise := _Helpers.make_emitter({
		"count": _pcount(14), "lifetime": 2.1,
		"color": COL_FEATHER_HI,
		"speed_min": 210.0, "speed_max": 390.0,
		"direction": Vector2.UP, "spread": 12.0,
		"gravity": 72.0, "damping": 60.0,
		"size_min": 5.0, "size_max": 8.0,
		"size_base": 30.0,
		"angle_min": -180.0, "angle_max": 180.0,
		"angular_velocity_min": -1719.0, "angular_velocity_max": 1719.0,
		"additive": false,
		"texture": _Helpers.feather_tex(),
		"emission_shape": "box", "emission_box": Vector2(10.0, 1.0),
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	feather_rise.position = gy
	add_child(feather_rise)
	# 스파크 30
	var spark := _Helpers.make_emitter({
		"count": _pcount(30), "lifetime": 1.0,
		"color": COL_HOT,
		"speed_min": 120.0, "speed_max": 480.0,
		"direction": Vector2.UP, "spread": 180.0,
		"gravity": 540.0, "damping": 60.0,
		"size_min": 1.0, "size_max": 2.4,
		"size_base": 4.0,
		"texture": _Helpers.sparkle_tex(),
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	spark.position = gy + Vector2(0.0, -10.0)
	add_child(spark)
