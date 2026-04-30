extends "res://scenes/vfx/impact_particle_base.gd"

func setup(p_amount: int, _p_flipped: bool) -> void:
	var mag: int = 0 if p_amount < 30 else (1 if p_amount < 100 else 2)
	_emit_particle_layer(Vector2.ZERO, {
		"count": 1, "lifetime": 0.18,
		"spread": 0.0, "speed_min": 0.0, "speed_max": 0.0,
		"scale_min": 0.62, "scale_max": 0.88,
		"texture": _circle_tex,
		"color_a": Color(2.0, 1.7, 0.8, 0.85),
		"color_b": Color(1.0, 0.45, 0.15, 0.0),
	})
	_emit_particle_layer(Vector2.ZERO, {
		"count": [22, 34, 50][mag],
		"lifetime": 0.65,
		"spread": 180.0,
		"speed_min": 100.0, "speed_max": 280.0,
		"gravity": Vector2(0, 420),
		"scale_min": 0.38, "scale_max": 0.75,
		"texture": _circle_tex,
		"color_a": Color(0.82, 0.65, 0.42, 0.9),
		"color_mid": Color(0.55, 0.42, 0.28, 0.55),
		"color_b": Color(0.22, 0.16, 0.10, 0.0),
		"damping_min": 60.0, "damping_max": 130.0,
		"turbulence": true, "turb_strength": 1.2, "turb_scale": 2.5,
		"turb_min": 0.1, "turb_max": 0.3,
		"additive": false,
	})
	_emit_particle_layer(Vector2.ZERO, {
		"count": [6, 10, 14][mag],
		"lifetime": 0.7,
		"direction": Vector2(0.0, -1.0),
		"spread": 130.0,
		"speed_min": 200.0, "speed_max": 380.0,
		"gravity": Vector2(0, 520),
		"scale_min": 0.19, "scale_max": 0.35,
		"texture": _square_tex,
		"color_a": Color(0.55, 0.45, 0.32, 1.0),
		"color_b": Color(0.18, 0.14, 0.10, 0.0),
		"angular_min": -240.0, "angular_max": 240.0,
		"additive": false,
	})
	_spawn_point_light(Vector2.ZERO, Color(1.0, 0.85, 0.6), 100.0, 0.3)
	_schedule_free(1.5)
