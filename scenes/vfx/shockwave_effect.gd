@tool
extends Node2D

const _SHADER := preload("res://assets/shaders/shockwave.gdshader")
const _DURATION := 0.2

func burst() -> void:
	if Engine.is_editor_hint():
		return
	var viewport := get_viewport()
	var viewport_size := viewport.get_visible_rect().size

	# 월드 좌표 → 스크린 UV 변환
	var screen_pos := viewport.get_canvas_transform() * global_position
	var center_uv := screen_pos / viewport_size

	var mat := ShaderMaterial.new()
	mat.shader = _SHADER
	var aspect := viewport_size.x / viewport_size.y
	mat.set_shader_parameter("progress", 0.0)
	mat.set_shader_parameter("strength", 0.05)
	mat.set_shader_parameter("thickness", 0.025)
	mat.set_shader_parameter("center", center_uv)
	mat.set_shader_parameter("aspect_ratio", aspect)
	mat.set_shader_parameter("max_progress", 0.15)

	var layer := CanvasLayer.new()
	layer.layer = 10
	get_tree().root.add_child(layer)

	var rect := ColorRect.new()
	rect.size = viewport_size
	rect.position = Vector2.ZERO
	rect.material = mat
	layer.add_child(rect)

	var tw := get_tree().create_tween()
	tw.tween_method(func(v: float): mat.set_shader_parameter("progress", v), 0.0, 0.15, _DURATION)
	tw.tween_callback(layer.queue_free)
