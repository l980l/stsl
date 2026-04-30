extends "res://scenes/vfx/impact_particle_base.gd"

func setup(p_amount: int, _p_flipped: bool) -> void:
	var mag: int = 0 if p_amount < 30 else (1 if p_amount < 100 else 2)
	_emit_particle_layer(Vector2.ZERO, {
		"count": [20, 32, 48][mag],
		"lifetime": 0.8,
		"direction": Vector2(1.0, 0.0),
		"spread": 180.0,
		"speed_min": 120.0, "speed_max": 320.0,
		"gravity": Vector2(0, -60),
		"scale_min": 0.28, "scale_max": 0.56,
		"texture": _circle_tex,
		"color_a": Color(2.0, 1.9, 1.2, 1.0),
		"color_mid": Color(2.0, 1.5, 0.4, 0.7),
		"color_b": Color(1.0, 0.55, 0.1, 0.0),
		"damping_min": 70.0, "damping_max": 150.0,
	})
	_emit_particle_layer(Vector2.ZERO, {
		"count": [7, 12, 18][mag],
		"lifetime": 1.0,
		"direction": Vector2(1.0, 0.0),
		"spread": 180.0,
		"speed_min": 75.0, "speed_max": 220.0,
		"gravity": Vector2(0, -40),
		"scale_min": 0.31, "scale_max": 0.63,
		"texture": _star_tex,
		"color_a": Color(2.2, 2.0, 0.8, 1.0),
		"color_b": Color(1.5, 1.5, 1.0, 0.0),
		"angular_min": -180.0, "angular_max": 180.0,
		"delay": 0.04,
	})
	_emit_particle_layer(Vector2.ZERO, {
		"count": 1, "lifetime": 0.22,
		"spread": 0.0, "speed_min": 0.0, "speed_max": 0.0,
		"scale_min": 1.12, "scale_max": 1.5,
		"texture": _circle_tex,
		"color_a": Color(3.0, 2.8, 1.8, 1.0),
		"color_b": Color(1.5, 1.2, 0.4, 0.0),
		"pulse_scale": true,
	})
	_spawn_point_light(Vector2.ZERO, Color(1.8, 1.5, 0.7), 200.0, 0.6)
	_schedule_free(2.0)
