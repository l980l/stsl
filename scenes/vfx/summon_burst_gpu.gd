# scenes/vfx/summon_burst_gpu.gd
# 병사 소환 GPU 하이브리드 — summon_burst.gd 상속.
# _spawn_burst (spark 20 + spark column 12 + dust 14) per spawn position GPU.
# callRing / pillar 폴리곤 → CPU.
extends "res://scenes/vfx/summon_burst.gd"

const _Helpers = preload("res://scenes/vfx/gpu_particle_helpers.gd")

var _bursts_made: Dictionary = {}  # ctr 별 spawn 중복 방지

func _spawn_burst(ctr: Vector2) -> void:
	var key := str(ctr)
	if _bursts_made.has(key):
		return
	_bursts_made[key] = true
	# spark 20 사방
	var spark := _Helpers.make_emitter({
		"count": _pcount(20), "lifetime": 1.35, "color": COL_HOT,
		"speed_min": 90.0, "speed_max": 330.0,
		"direction": Vector2.UP, "spread": 180.0,
		"gravity": 144.0, "damping": 3.0,
		"size_min": 1.4, "size_max": 2.8,
		"size_base": 4.0,
		"texture": _Helpers.sparkle_tex(),
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	spark.position = ctr
	add_child(spark)
	# spark column 12 (위로)
	var spark_col := _Helpers.make_emitter({
		"count": _pcount(12), "lifetime": 1.15, "color": COL_HOT,
		"speed_min": 72.0, "speed_max": 144.0,
		"direction": Vector2.UP, "spread": 12.0,
		"gravity": 0.0, "damping": 3.0,
		"size_min": 1.2, "size_max": 2.4,
		"size_base": 4.0,
		"texture": _Helpers.sparkle_tex(),
		"emission_shape": "box", "emission_box": Vector2(22.0, 1.0),
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	spark_col.position = ctr
	add_child(spark_col)
	# dust ring 14
	var dust := _Helpers.make_emitter({
		"count": _pcount(14), "lifetime": 1.45, "color": COL_DUST,
		"speed_min": 60.0, "speed_max": 240.0,
		"direction": Vector2.UP, "spread": 130.0,
		"gravity": -18.0, "damping": 3.0,
		"size_min": 14.0, "size_max": 26.0,
		"additive": false,
		"start_alpha": 0.5, "mid_alpha": 0.25, "end_alpha": 0.0,
	})
	dust.position = ctr
	add_child(dust)
