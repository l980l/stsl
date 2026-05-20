# scenes/vfx/counter_gpu.gd
# 카운터 GPU 하이브리드 — counter.gd 상속.
# _spawn_parry_flash_burst(brass_spark) / _spawn_enemy_hit_burst(crimson_spark + steel_chip)
#   → GPUParticles2D 버스트. normal/major 두 모드 모두 대응 (_is_major 로 개수 분기).
# parry flash / shock ring / counter streak(Bezier) / slash / 흑백 overlay → CPU _draw() 상속 유지.
extends "res://scenes/vfx/counter.gd"

const _Helpers = preload("res://scenes/vfx/gpu_particle_helpers.gd")

# 영웅 측 parry 충돌 — brass spark
func _spawn_parry_flash_burst() -> void:
	var brass := _Helpers.make_emitter({
		"count": _pcount(36) if _is_major else _pcount(20),
		"lifetime": 0.8, "color": Color.WHITE,
		"speed_min": 80.0, "speed_max": 240.0, "spread": 180.0,
		"gravity": 50.0,
		"size_min": 1.4, "size_max": 2.8, "additive": false,
		"color_ramp": _Helpers.make_color_ramp(
			Color(1.0, 0.90, 0.62), Color(1.0, 0.82, 0.465), Color(1.0, 0.74, 0.31),
			1.0, 0.5, 0.0),
	})
	brass.position = _caster_pos
	add_child(brass)

# 적 측 반사 데미지 — crimson spark + (major) steel chip
func _spawn_enemy_hit_burst() -> void:
	var crimson := _Helpers.make_emitter({
		"count": _pcount(48) if _is_major else _pcount(28),
		"lifetime": 1.0, "color": Color.WHITE,
		"speed_min": 100.0, "speed_max": 300.0, "spread": 180.0,
		"gravity": 80.0,
		"size_min": 1.4, "size_max": 3.0, "additive": false,
		"color_ramp": _Helpers.make_color_ramp(
			Color(1.0, 0.43, 0.31), Color(1.0, 0.35, 0.26), Color(1.0, 0.27, 0.21),
			1.0, 0.5, 0.0),
	})
	crimson.position = _target_pos
	add_child(crimson)
	# steel chip — major 모드 전용 (무거운 충돌 표현)
	if _is_major:
		var chip := _Helpers.make_emitter({
			"count": _pcount(16), "lifetime": 1.2, "color": Color.WHITE,
			"speed_min": 60.0, "speed_max": 200.0, "spread": 180.0,
			"gravity": 120.0,
			"size_min": 1.6, "size_max": 3.0, "additive": false,
			"color_ramp": _Helpers.make_color_ramp(
				Color(0.85, 0.88, 0.92), Color(0.85, 0.83, 0.88), Color(0.85, 0.78, 0.84),
				1.0, 0.5, 0.0),
		})
		chip.position = _target_pos
		add_child(chip)
