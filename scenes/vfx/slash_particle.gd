@tool
extends "res://scenes/vfx/impact_particle_base.gd"

func setup(p_amount: int, _p_flipped: bool) -> void:
	var mag: int = 0 if p_amount < 30 else (1 if p_amount < 100 else 2)
	_emit_particle_layer(Vector2.ZERO, {
		"count": 1,
		"lifetime": 0.45,
		"spread": 0.0, "speed_min": 0.0, "speed_max": 0.0,
		"scale_min": [1.5, 2.1, 3.0][mag], "scale_max": [1.9, 2.5, 3.5][mag],
		"texture": _slash_tex,
		"color_a": Color(2.2, 2.2, 2.2, 1.0),
		"color_b": Color(0.6, 0.85, 1.0, 0.0),
		"angle_min": -3.0, "angle_max": 3.0,
		"pulse_scale": true,
	})
	_emit_particle_layer(Vector2.ZERO, {
		"count": [1, 2, 2][mag],
		"lifetime": 0.6,
		"spread": 0.0, "speed_min": 0.0, "speed_max": 0.0,
		"scale_min": [1.0, 1.4, 2.0][mag], "scale_max": [1.4, 1.9, 2.5][mag],
		"texture": _slash_tex,
		"color_a": Color(1.2, 1.5, 2.0, 0.55),
		"color_b": Color(0.2, 0.4, 0.85, 0.0),
		"angle_min": -18.0, "angle_max": 18.0,
		"pulse_scale": true,
		"delay": 0.06,
	})
	_emit_particle_layer(Vector2.ZERO, {
		"count": 1, "lifetime": 0.28,
		"spread": 0.0, "speed_min": 0.0, "speed_max": 0.0,
		"scale_min": 0.55, "scale_max": 0.7,
		"texture": _circle_tex,
		"color_a": Color(2.5, 2.5, 2.5, 0.85),
		"color_b": Color(0.7, 0.85, 1.0, 0.0),
		"pulse_scale": true,
	})
	_spawn_point_light(Vector2.ZERO, Color(1.0, 1.0, 1.0), 80.0, 0.15)
	_schedule_free(1.5)
