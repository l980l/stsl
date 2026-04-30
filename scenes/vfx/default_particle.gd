extends "res://scenes/vfx/impact_particle_base.gd"

func setup(p_amount: int, p_flipped: bool) -> void:
	var mag: int = 0 if p_amount < 30 else (1 if p_amount < 100 else 2)
	var dx: float = -1.0 if p_flipped else 1.0
	_emit_particle_layer(Vector2.ZERO, {
		"count": [6, 10, 14][mag],
		"lifetime": 0.32,
		"direction": Vector2(dx, 0.0),
		"spread": 80.0,
		"speed_min": 150.0, "speed_max": 320.0,
		"gravity": Vector2(0, 200),
		"scale_min": 0.19, "scale_max": 0.38,
		"texture": _circle_tex,
		"color_a": Color(2.2, 2.2, 1.8, 1.0),
		"color_b": Color(1.5, 0.8, 0.1, 0.0),
		"damping_min": 60.0, "damping_max": 140.0,
	})
	_emit_particle_layer(Vector2.ZERO, {
		"count": 1, "lifetime": 0.12,
		"spread": 0.0, "speed_min": 0.0, "speed_max": 0.0,
		"scale_min": 0.62, "scale_max": 0.88,
		"texture": _circle_tex,
		"color_a": Color(2.5, 2.2, 1.2, 0.9),
		"color_b": Color(1.5, 0.8, 0.15, 0.0),
	})
	_spawn_point_light(Vector2.ZERO, Color(1.2, 1.1, 0.8), 80.0, 0.2)
	_schedule_free(1.0)
