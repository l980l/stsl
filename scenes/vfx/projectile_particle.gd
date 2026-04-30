@tool
extends "res://scenes/vfx/impact_particle_base.gd"

func setup(p_flipped: bool) -> void:
	super(p_flipped)
	_spawn_point_light(Vector2.ZERO, Color(1.0, 1.0, 1.0), 60.0, 0.2)
	_schedule_free(1.2)
