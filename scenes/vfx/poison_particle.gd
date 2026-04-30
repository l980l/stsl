@tool
extends "res://scenes/vfx/impact_particle_base.gd"

func setup(p_flipped: bool) -> void:
	super(p_flipped)
	_spawn_point_light(Vector2.ZERO, Color(0.6, 1.5, 0.4), 90.0, 0.6)
	_schedule_free(2.5)
