extends "res://scenes/vfx/impact_particle_base.gd"

func setup(p_amount: int, _p_flipped: bool) -> void:
	var mag: int = 0 if p_amount < 30 else (1 if p_amount < 100 else 2)
	_emit_particle_layer(Vector2.ZERO, {
		"count": [18, 28, 40][mag],
		"lifetime": 0.95,
		"spread": 180.0,
		"speed_min": 70.0, "speed_max": 200.0,
		"scale_min": 0.23, "scale_max": 0.44,
		"texture": _circle_tex,
		"color_a": Color(1.5, 0.35, 2.0, 1.0),
		"color_mid": Color(0.7, 0.08, 1.2, 0.7),
		"color_b": Color(0.05, 0.0, 0.15, 0.0),
		"radial_min": -180.0, "radial_max": -80.0,
		"angular_min": -200.0, "angular_max": 200.0,
		"turbulence": true, "turb_strength": 1.8, "turb_scale": 2.0,
		"turb_min": 0.15, "turb_max": 0.5,
	})
	_emit_particle_layer(Vector2.ZERO, {
		"count": [10, 16, 24][mag],
		"lifetime": 1.1,
		"direction": Vector2(0.0, -1.0),
		"spread": 130.0,
		"speed_min": 25.0, "speed_max": 90.0,
		"gravity": Vector2(0, -35),
		"scale_min": 0.44, "scale_max": 0.75,
		"texture": _smoke_tex,
		"color_a": Color(0.22, 0.05, 0.35, 0.75),
		"color_b": Color(0.02, 0.0, 0.05, 0.0),
		"turbulence": true, "turb_strength": 1.5, "turb_scale": 2.5,
		"turb_min": 0.1, "turb_max": 0.4,
		"additive": false,
		"delay": 0.05,
	})
	_emit_particle_layer(Vector2.ZERO, {
		"count": 1, "lifetime": 0.2,
		"spread": 0.0, "speed_min": 0.0, "speed_max": 0.0,
		"scale_min": 0.62, "scale_max": 0.81,
		"texture": _circle_tex,
		"color_a": Color(1.5, 0.3, 2.5, 0.9),
		"color_b": Color(0.2, 0.0, 0.4, 0.0),
	})
	_spawn_point_light(Vector2.ZERO, Color(1.0, 0.4, 1.5), 120.0, 0.5)
	_schedule_free(2.0)
