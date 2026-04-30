@tool
extends "res://scenes/vfx/impact_particle_base.gd"

func setup(p_flipped: bool) -> void:
	super(p_flipped)
	_spawn_point_light(Vector2.ZERO, Color(1.0, 0.85, 0.6), 100.0, 0.3)
	_schedule_free(1.5)
