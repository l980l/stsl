# scenes/vfx/blunt_smash_gpu.gd
# 둔기 슬램 GPU 하이브리드 — blunt_smash.gd 상속.
# dust 80 / chunk 24 / spark 30 / dust_rise 24 → GPU. 슬램 모션/크랙/충격링 → CPU.
extends "res://scenes/vfx/blunt_smash.gd"

const _Helpers = preload("res://scenes/vfx/gpu_particle_helpers.gd")

var _impact_made: bool = false

func _spawn_impact_dust() -> void:
	if _impact_made:
		return
	_impact_made = true
	var gy: Vector2 = _ground_pos if _has_ground else _target + Vector2(0.0, 80.0)
	# dust 80 — 바닥 먼지 옆으로
	var dust := _Helpers.make_emitter({
		"count": _pcount(80), "lifetime": 2.0, "color": COL_DUST_MID,
		"speed_min": 120.0 * DUST_SCALE, "speed_max": 420.0 * DUST_SCALE,
		"direction": Vector2.UP, "spread": 130.0,
		"gravity": -18.0 * DUST_SCALE, "damping": 3.0,
		"size_min": 20.0 * DUST_SCALE, "size_max": 42.0 * DUST_SCALE,
		"additive": false,
		"start_alpha": 0.5, "mid_alpha": 0.25, "end_alpha": 0.0,
	})
	dust.position = gy
	add_child(dust)
	# chunk 24 — 회전 파편
	var chunk := _Helpers.make_chunk_emitter(COL_CHUNK, _pcount(24), 1.5,
		180.0, 600.0, 1080.0, 3.0, 7.0)
	chunk.position = gy
	add_child(chunk)
	# spark 30 — 스파크
	var spark := _Helpers.make_emitter({
		"count": _pcount(30), "lifetime": 1.0, "color": COL_HOT,
		"speed_min": 120.0, "speed_max": 480.0,
		"direction": Vector2.UP, "spread": 180.0,
		"gravity": 540.0, "damping": 3.0,
		"size_min": 1.0, "size_max": 2.4,
		"size_base": 4.0,
		"texture": _Helpers.sparkle_tex(),
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	spark.position = gy + Vector2(0.0, -10.0)
	add_child(spark)
	# dust_rise 24 — 위로 솟는 먼지 기둥
	var dust_rise := _Helpers.make_emitter({
		"count": _pcount(24), "lifetime": 1.9, "color": COL_DUST_MID,
		"speed_min": 180.0 * DUST_SCALE, "speed_max": 360.0 * DUST_SCALE,
		"direction": Vector2.UP, "spread": 12.0,
		"gravity": -18.0 * DUST_SCALE, "damping": 3.0,
		"size_min": 16.0 * DUST_SCALE, "size_max": 32.0 * DUST_SCALE,
		"additive": false,
		"start_alpha": 0.5, "mid_alpha": 0.25, "end_alpha": 0.0,
		"emission_shape": "box", "emission_box": Vector2(20.0 * DUST_SCALE, 1.0),
	})
	dust_rise.position = gy
	add_child(dust_rise)
