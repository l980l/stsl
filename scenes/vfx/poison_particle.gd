@tool
extends "res://scenes/vfx/impact_particle_base.gd"

func setup(p_amount: int, _p_flipped: bool) -> void:
	var mag: int = 0 if p_amount < 30 else (1 if p_amount < 100 else 2)
	_emit_particle_layer(Vector2.ZERO, {
		"count": [16, 24, 34][mag],
		"lifetime": 1.2,
		"direction": Vector2(0.0, -1.0),
		"spread": 110.0,
		"speed_min": 25.0, "speed_max": 120.0,
		"gravity": Vector2(0, -50),
		"scale_min": 0.23, "scale_max": 0.44,
		"texture": _circle_tex,
		"color_a": Color(0.6, 2.0, 0.4, 0.9),
		"color_mid": Color(0.18, 0.85, 0.1, 0.5),
		"color_b": Color(0.05, 0.32, 0.0, 0.0),
		"turbulence": true, "turb_strength": 1.0, "turb_scale": 3.5,
		"turb_min": 0.1, "turb_max": 0.35,
	})
	_emit_particle_layer(Vector2.ZERO, {
		"count": [12, 18, 26][mag],
		"lifetime": 1.5,
		"direction": Vector2(0.0, -1.0),
		"spread": 170.0,
		"speed_min": 12.0, "speed_max": 65.0,
		"gravity": Vector2(0, -22),
		"scale_min": 0.10, "scale_max": 0.19,
		"texture": _circle_tex,
		"color_a": Color(0.18, 0.55, 0.08, 0.9),
		"color_b": Color(0.0, 0.18, 0.0, 0.0),
		"turbulence": true, "turb_strength": 0.8, "turb_scale": 4.0,
		"turb_min": 0.05, "turb_max": 0.25,
		"additive": false,
		"delay": 0.05,
	})
	_emit_particle_layer(Vector2.ZERO, {
		"count": 1, "lifetime": 0.2,
		"spread": 0.0, "speed_min": 0.0, "speed_max": 0.0,
		"scale_min": 0.5, "scale_max": 0.69,
		"texture": _circle_tex,
		"color_a": Color(0.6, 2.5, 0.4, 0.85),
		"color_b": Color(0.1, 0.5, 0.0, 0.0),
	})
	_spawn_point_light(Vector2.ZERO, Color(0.6, 1.5, 0.4), 90.0, 0.6)
	_schedule_free(2.5)
