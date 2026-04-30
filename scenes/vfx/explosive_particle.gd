@tool
extends "res://scenes/vfx/impact_particle_base.gd"

func setup(p_amount: int, _p_flipped: bool) -> void:
	var mag: int = 0 if p_amount < 30 else (1 if p_amount < 100 else 2)
	_emit_particle_layer(Vector2.ZERO, {
		"count": [30, 50, 72][mag],
		"lifetime": 0.55,
		"spread": 180.0,
		"speed_min": 120.0, "speed_max": 360.0,
		"gravity": Vector2(0, -40),
		"scale_min": 0.44, "scale_max": 0.88,
		"texture": _circle_tex,
		"color_a": Color(2.5, 1.8, 0.5, 1.0),
		"color_mid": Color(2.0, 0.6, 0.08, 0.7),
		"color_b": Color(0.3, 0.05, 0.0, 0.0),
		"damping_min": 80.0, "damping_max": 200.0,
	})
	_emit_particle_layer(Vector2.ZERO, {
		"count": 1, "lifetime": 0.3,
		"spread": 0.0, "speed_min": 0.0, "speed_max": 0.0,
		"scale_min": 1.25, "scale_max": 1.75,
		"texture": _circle_tex,
		"color_a": Color(3.0, 1.8, 0.4, 1.0),
		"color_b": Color(1.5, 0.4, 0.08, 0.0),
		"pulse_scale": true,
	})
	_emit_particle_layer(Vector2.ZERO, {
		"count": [14, 22, 32][mag],
		"lifetime": 1.2,
		"direction": Vector2(0.0, -1.0),
		"spread": 180.0,
		"speed_min": 35.0, "speed_max": 140.0,
		"gravity": Vector2(0, -55),
		"scale_min": 0.62, "scale_max": 1.12,
		"texture": _smoke_tex,
		"color_a": Color(0.35, 0.28, 0.24, 0.85),
		"color_b": Color(0.05, 0.04, 0.03, 0.0),
		"turbulence": true, "turb_strength": 2.0, "turb_scale": 1.5,
		"turb_min": 0.15, "turb_max": 0.5,
		"additive": false,
		"delay": 0.07,
	})
	_spawn_point_light(Vector2.ZERO, Color(1.5, 0.7, 0.2), 180.0, 0.5)
	_schedule_free(2.0)
