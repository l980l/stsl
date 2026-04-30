@tool
extends Node2D

const _circle_tex: Texture2D = preload("res://assets/art/particles/circle_128.png")

func setup(p_flipped: bool) -> void:
	scale.x = -1.0 if p_flipped else 1.0
	_emit_all()

func _emit_all() -> void:
	for child in get_children():
		if not child is GPUParticles2D:
			continue
		var delay: float = child.get_meta("layer_delay", 0.0)
		if delay > 0.0:
			child.emitting = false
			get_tree().create_timer(delay).timeout.connect(func():
				if is_instance_valid(child): child.emitting = true
			)
		else:
			child.emitting = true

func _schedule_free(delay: float) -> void:
	if Engine.is_editor_hint(): return
	get_tree().create_timer(delay).timeout.connect(queue_free)

func _spawn_point_light(local_pos: Vector2, color: Color, radius: float, duration: float = 0.4) -> void:
	var light := PointLight2D.new()
	light.color = color
	light.energy = 1.5
	light.texture = _circle_tex
	light.texture_scale = radius / 128.0
	light.position = local_pos
	light.z_index = 14
	add_child(light)
	var tw := create_tween()
	tw.tween_property(light, "energy", 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_callback(light.queue_free)
