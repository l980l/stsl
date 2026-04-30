@tool
extends "res://scenes/vfx/impact_particle_base.gd"

func setup(p_flipped: bool) -> void:
	super(p_flipped)
	_spawn_point_light(Vector2.ZERO, Color(1.8, 1.5, 0.7), 200.0, 0.6)
	_schedule_free(2.0)
