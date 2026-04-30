@tool
extends "res://scenes/vfx/impact_particle_base.gd"

func setup(p_amount: int, p_flipped: bool) -> void:
	var mag: int = 0 if p_amount < 30 else (1 if p_amount < 100 else 2)
	var dx: float = -1.0 if p_flipped else 1.0
	var launch_offset := Vector2(-dx * 400.0, 0.0)
	var proj_angle := 0.0 if dx > 0.0 else 180.0
	_emit_particle_layer(launch_offset, {
		"count": [3, 5, 7][mag],
		"lifetime": 0.23,
		"direction": Vector2(dx, 0.0),
		"spread": 4.0,
		"speed_min": 1500.0, "speed_max": 1900.0,
		"scale_min": 0.62, "scale_max": 1.0,
		"texture": _slash_tex,
		"color_a": Color(2.0, 1.9, 1.4, 1.0),
		"color_b": Color(0.8, 0.6, 0.2, 0.0),
		"damping_min": 200.0, "damping_max": 400.0,
		"angle_min": proj_angle - 2.0, "angle_max": proj_angle + 2.0,
	})
	_emit_particle_layer(Vector2.ZERO, {
		"count": 1, "lifetime": 0.1,
		"spread": 0.0, "speed_min": 0.0, "speed_max": 0.0,
		"scale_min": 0.5, "scale_max": 0.7,
		"texture": _circle_tex,
		"color_a": Color(2.5, 2.5, 2.0, 1.0),
		"color_b": Color(1.0, 0.9, 0.5, 0.0),
		"delay": 0.18,
	})
	_emit_particle_layer(Vector2.ZERO, {
		"count": [5, 8, 12][mag],
		"lifetime": 0.35,
		"direction": Vector2(-dx, -0.3),
		"spread": 70.0,
		"speed_min": 100.0, "speed_max": 280.0,
		"gravity": Vector2(0, 220),
		"scale_min": 0.13, "scale_max": 0.25,
		"texture": _circle_tex,
		"color_a": Color(2.0, 1.8, 1.0, 1.0),
		"color_b": Color(0.85, 0.3, 0.08, 0.0),
		"damping_min": 50.0, "damping_max": 120.0,
		"delay": 0.18,
	})
	_spawn_point_light(Vector2.ZERO, Color(1.0, 1.0, 1.0), 60.0, 0.2)
	_schedule_free(1.2)
