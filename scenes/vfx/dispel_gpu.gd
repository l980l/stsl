# scenes/vfx/dispel_gpu.gd
# DISPEL GPU 하이브리드 — dispel.gd 상속.
# _spawn_shatter_particles: brass shard 16 + crimson backsplash 8 → GPUParticles2D.
# buff orb / hook tendril(Bezier) / shatter ring 폴리곤 → CPU _draw() 상속 유지.
extends "res://scenes/vfx/dispel.gd"

const _Helpers = preload("res://scenes/vfx/gpu_particle_helpers.gd")

# 원본 _spawn_shatter_particles 의 _particles 채우기를 GPU 이미터로 대체.
# _process / _draw_particles 는 상속 — _particles 가 빈 채로 남아 무동작.
func _spawn_shatter_particles(pos: Vector2) -> void:
	# brass shard 16 — 전방위 분산, sp 90~270, life 0.55~0.9, size 1.4~3.2 (일반 블렌드)
	var brass := _Helpers.make_emitter({
		"count": 16, "lifetime": 0.9, "color": Color.WHITE,
		"speed_min": 90.0, "speed_max": 270.0, "spread": 180.0,
		"size_min": 1.4, "size_max": 3.2, "additive": false,
		"color_ramp": _Helpers.make_color_ramp(
			Color(1.0, 0.9, 0.59), Color(1.0, 0.82, 0.435), Color(1.0, 0.74, 0.28),
			1.0, 0.5, 0.0),
	})
	brass.position = pos
	add_child(brass)
	# crimson backsplash 8 — sp 60~180, life 0.7~1.1, size 1.6~3.2 (일반 블렌드)
	var crimson := _Helpers.make_emitter({
		"count": 8, "lifetime": 1.1, "color": Color.WHITE,
		"speed_min": 60.0, "speed_max": 180.0, "spread": 180.0,
		"size_min": 1.6, "size_max": 3.2, "additive": false,
		"color_ramp": _Helpers.make_color_ramp(
			Color(1.0, 0.43, 0.39), Color(1.0, 0.35, 0.27), Color(1.0, 0.27, 0.15),
			1.0, 0.5, 0.0),
	})
	crimson.position = pos
	add_child(crimson)
