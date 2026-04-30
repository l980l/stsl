@tool
extends "res://scenes/vfx/impact_particle_base.gd"

func setup(p_flipped: bool) -> void:
	super(p_flipped)
	_spawn_point_light(Vector2.ZERO, Color(1.2, 1.1, 0.8), 80.0, 0.2)
	_schedule_free(1.0)
