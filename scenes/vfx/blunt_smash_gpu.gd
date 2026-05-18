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
	# dust 80 — 옆으로 퍼지는 흙먼지. 30% 크게 + 더 흰색.
	var dust := _Helpers.make_emitter({
		"count": _pcount(80), "lifetime": 2.0, "color": Color(0.88, 0.84, 0.74),
		"speed_min": 120.0 * DUST_SCALE, "speed_max": 420.0 * DUST_SCALE,
		"direction": Vector2.UP, "spread": 60.0,
		"gravity": -18.0 * DUST_SCALE, "damping": 40.0,
		"size_min": 26.0 * DUST_SCALE, "size_max": 55.0 * DUST_SCALE,
		"additive": false,
		"start_alpha": 0.5, "mid_alpha": 0.25, "end_alpha": 0.0,
	})
	dust.position = gy
	add_child(dust)
	# chunk 24 — 회전 파편. 원본 COL_CHUNK 어두워서 흙색에 가깝게 밝게 보정.
	var chunk := _Helpers.make_chunk_emitter(Color(0.62, 0.50, 0.32), _pcount(24), 1.5,
		180.0, 600.0, 1080.0, 3.0, 7.0)
	chunk.position = gy
	add_child(chunk)
	# spark 30 — 단순 원 점 (sparkle 별가루 X), 흙색
	var spark := _Helpers.make_emitter({
		"count": _pcount(30), "lifetime": 1.0, "color": COL_DUST_DEEP,
		"speed_min": 120.0, "speed_max": 480.0,
		"direction": Vector2.UP, "spread": 180.0,
		"gravity": 540.0, "damping": 3.0,
		"size_min": 1.0, "size_max": 2.4,
		"texture": _Helpers.circle_tex(),
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	spark.position = gy + Vector2(0.0, -10.0)
	add_child(spark)
	# dust_rise 24 — 위로 솟는 먼지 기둥. 30% 크게 + 더 흰색.
	var dust_rise := _Helpers.make_emitter({
		"count": _pcount(24), "lifetime": 1.9, "color": Color(0.88, 0.84, 0.74),
		"speed_min": 180.0 * DUST_SCALE, "speed_max": 360.0 * DUST_SCALE,
		"direction": Vector2.UP, "spread": 12.0,
		"gravity": -18.0 * DUST_SCALE, "damping": 3.0,
		"size_min": 21.0 * DUST_SCALE, "size_max": 42.0 * DUST_SCALE,
		"additive": false,
		"start_alpha": 0.5, "mid_alpha": 0.25, "end_alpha": 0.0,
		"emission_shape": "box", "emission_box": Vector2(20.0 * DUST_SCALE, 1.0),
	})
	dust_rise.position = gy
	add_child(dust_rise)
