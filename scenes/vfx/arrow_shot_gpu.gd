# scenes/vfx/arrow_shot_gpu.gd
# 화살 발사 GPU 하이브리드 — arrow_shot.gd 상속.
# _spawn_impact: dust 14 + chip 6 + spark 22 → GPU.
# 화살 자체 / 조준 레이저 / 트레일 / 박힌 화살 폴리곤 → CPU 유지.
extends "res://scenes/vfx/arrow_shot.gd"

const _Helpers = preload("res://scenes/vfx/gpu_particle_helpers.gd")

var _impact_made: bool = false

static func _dust_scale_curve() -> Curve:
	var c := Curve.new()
	c.add_point(Vector2(0.0, 1.0))
	c.add_point(Vector2(1.0, 2.4))
	return c

func _spawn_impact(pos: Vector2, ang: float) -> void:
	if _impact_made:
		return
	_impact_made = true
	# 반사 방향 (ang + PI) — 화살이 박힌 방향에서 튕겨나옴
	var back_dir := Vector2(cos(ang + PI), sin(ang + PI))
	# spark 22 — glow(add) 색 변화 ramp (COL_SPARK → 어두), alpha (1-k)
	var spark_ramp := _Helpers.make_color_ramp(
		Color(1.0, 0.902, 0.706), Color(1.0, 0.745, 0.392), Color(1.0, 0.588, 0.078),
		1.0, 0.5, 0.0)
	var spark := _Helpers.make_emitter({
		"count": _pcount(22), "lifetime": 0.8, "color": Color.WHITE,
		"speed_min": 120.0, "speed_max": 480.0,  # sp 2~8 × PSPEED
		"direction": back_dir, "spread": 40.0,
		"gravity": 432.0, "damping": 0.0,  # grav 0.12 × 3600
		"size_min": 1.0, "size_max": 2.3,
		"size_base": 16.0,
		"texture": _Helpers.mote_halo_tex(),
		"color_ramp": spark_ramp,
	})
	spark.position = pos
	add_child(spark)
	# dust 14 — non-add, COL_DUST alpha 0.45, 크기 확장
	var dust := _Helpers.make_emitter({
		"count": _pcount(14), "lifetime": 1.1, "color": COL_DUST,
		"speed_min": 30.0, "speed_max": 138.0,  # sp 0.5~2.3 × PSPEED
		"direction": back_dir, "spread": 29.0,
		"gravity": -28.8, "damping": 0.0,
		"size_min": 8.0, "size_max": 16.0,
		"scale_curve": _dust_scale_curve(),
		"additive": false,
		"start_alpha": 0.45, "mid_alpha": 0.22, "end_alpha": 0.0,
	})
	dust.position = pos
	add_child(dust)
	# chip 6 — non-add, COL_STEEL alpha 0.9, 회전 사각형
	var chip := _Helpers.make_emitter({
		"count": _pcount(6), "lifetime": 1.2, "color": COL_STEEL,
		"speed_min": 180.0, "speed_max": 420.0,  # sp 3~7 × PSPEED
		"direction": back_dir, "spread": 23.0,
		"gravity": 900.0, "damping": 0.0,  # grav 0.25 × 3600
		"size_min": 2.0, "size_max": 4.0,
		"size_base": 32.0,
		"texture": _Helpers.square_tex(),
		"angle_min": 0.0, "angle_max": 360.0,
		"angular_velocity_min": -1031.0, "angular_velocity_max": 1031.0,  # ±0.3 × PSPEED × 180/π
		"additive": false,
		"start_alpha": 0.9, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	chip.position = pos
	add_child(chip)
