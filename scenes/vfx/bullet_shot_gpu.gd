# scenes/vfx/bullet_shot_gpu.gd
# 총알 GPU 하이브리드 — bullet_shot.gd 상속.
# muzzle (spark/smoke/casing) + impact (spark/dust/chip) GPU.
# 탄도/조준 레이저/탄흔 CPU.
extends "res://scenes/vfx/bullet_shot.gd"

const _Helpers = preload("res://scenes/vfx/gpu_particle_helpers.gd")

var _muzzle_made: bool = false
var _impact_made: bool = false

func _spawn_muzzle() -> void:
	if _muzzle_made:
		return
	_muzzle_made = true
	var dir := (_target - _caster).normalized()
	# spark 14 — 총구 부채꼴
	var spark := _Helpers.make_emitter({
		"count": _pcount(14), "lifetime": 0.48,
		"color": COL_MUZZLE,
		"speed_min": 240.0, "speed_max": 660.0,
		"direction": dir, "spread": 14.3,
		"gravity": 144.0, "damping": 3.0,
		"size_min": 1.2, "size_max": 2.6,
		"size_base": 4.0,
		"texture": _Helpers.sparkle_tex(),
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	spark.position = _caster
	add_child(spark)
	# smoke 14 — 머즐 연기 (cone 더 넓게)
	var smoke := _Helpers.make_emitter({
		"count": _pcount(14), "lifetime": 2.0,
		"color": COL_SMOKE,
		"speed_min": 36.0, "speed_max": 132.0,
		"direction": dir, "spread": 45.8,  # ±0.8 rad
		"gravity": -18.0, "damping": 3.0,
		"size_min": 9.0, "size_max": 19.0,
		"additive": false,
		"start_alpha": 0.5, "mid_alpha": 0.25, "end_alpha": 0.0,
	})
	smoke.position = _caster
	add_child(smoke)
	# casing — 1 개, super 코드 그대로 처리하기 어려움 (단일 + 회전 + 그래픽). super 의 CPU 그대로 두는 게 OK.
	# 즉 super._spawn_muzzle 의 casing 부분만 호출하려면 super 코드 분기 필요.
	# 간단: casing 만 super._particles 에 직접 추가.
	var side := Vector2(-dir.y, dir.x)
	_particles.append(_mk(_caster + side * -8.0,
		side * randf_range(-0.6, -0.4) + Vector2(0.0, -3.0 - randf()),
		1.6, 5.0, "casing", 0.32, randf() * TAU, randf_range(-0.5, 0.5)))

func _spawn_impact(pos: Vector2, ang: float) -> void:
	if _impact_made:
		return
	_impact_made = true
	var bounce_dir := Vector2(cos(ang + PI), sin(ang + PI))
	# spark 28 — 튕기는 스파크
	var spark := _Helpers.make_emitter({
		"count": _pcount(28), "lifetime": 0.78,
		"color": COL_MUZZLE,
		"speed_min": 120.0, "speed_max": 540.0,
		"direction": bounce_dir, "spread": 40.0,
		"gravity": 648.0, "damping": 3.0,
		"size_min": 1.0, "size_max": 2.3,
		"size_base": 4.0,
		"texture": _Helpers.sparkle_tex(),
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	spark.position = pos
	add_child(spark)
	# dust 18
	var dust := _Helpers.make_emitter({
		"count": _pcount(18), "lifetime": 1.2,
		"color": COL_DUST,
		"speed_min": 24.0, "speed_max": 156.0,
		"direction": bounce_dir, "spread": 30.0,
		"gravity": -28.8, "damping": 3.0,
		"size_min": 9.0, "size_max": 19.0,
		"additive": false,
		"start_alpha": 0.5, "mid_alpha": 0.25, "end_alpha": 0.0,
	})
	dust.position = pos
	add_child(dust)
	# chip 8 (회전 파편) — 원본 COL_STEEL (밝은 회색 #cfd4dd)
	var chip := _Helpers.make_chunk_emitter(COL_STEEL, _pcount(8), 1.3, 180.0, 480.0, 1080.0, 2.0, 4.0)
	chip.position = pos
	add_child(chip)
