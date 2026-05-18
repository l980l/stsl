# scenes/vfx/sig_hubris_gpu.gd
# 휴브리스 GPU 하이브리드 — sig_hubris.gd 상속.
# _spawn_strike_sparks (spark 14, gold/cyan 혼합) → GPU.
# 황금 halo, zigzag 번개, 빛기둥 등 폴리곤 CPU.
extends "res://scenes/vfx/sig_hubris.gd"

const _Helpers = preload("res://scenes/vfx/gpu_particle_helpers.gd")

var _impact_made: bool = false

func _spawn_strike_sparks() -> void:
	if _impact_made:
		return
	_impact_made = true
	var head: Vector2 = _target + Vector2(0.0, HEAD_OFFSET)
	# gold spark ~70% / cyan ~30%. count 14 → gold 10 + cyan 4.
	# vel (cos*sp, sin*sp*0.7 - 0.5), sp 2~6 → speed 120~360 * y bias -30.
	var gold := _Helpers.make_emitter({
		"count": _pcount(10), "lifetime": 0.65, "color": COL_GOLD,
		"speed_min": 120.0, "speed_max": 360.0,
		"direction": Vector2.UP, "spread": 180.0,
		"gravity": 72.0, "damping": 3.0,
		"size_min": 1.2, "size_max": 2.6,
		"size_base": 4.0,
		"texture": _Helpers.sparkle_tex(),
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	gold.position = head
	add_child(gold)
	var cyan := _Helpers.make_emitter({
		"count": _pcount(4), "lifetime": 0.65, "color": COL_CYAN,
		"speed_min": 120.0, "speed_max": 360.0,
		"direction": Vector2.UP, "spread": 180.0,
		"gravity": 72.0, "damping": 3.0,
		"size_min": 1.2, "size_max": 2.6,
		"size_base": 4.0,
		"texture": _Helpers.sparkle_tex(),
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	cyan.position = head
	add_child(cyan)
