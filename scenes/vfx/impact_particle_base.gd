@tool
extends Node2D

@export var amount: int = 50:
	set(v): amount = v; if Engine.is_editor_hint(): _refresh_editor()
@export var flipped: bool = false:
	set(v): flipped = v; if Engine.is_editor_hint(): _refresh_editor()

static var _additive_mat: CanvasItemMaterial

const _circle_tex: Texture2D = preload("res://assets/art/particles/circle_128.png")
const _slash_tex:  Texture2D = preload("res://assets/art/particles/slash_128x16.png")
const _square_tex: Texture2D = preload("res://assets/art/particles/dust_64.png")
const _star_tex:   Texture2D = preload("res://assets/art/particles/star_128.png")
const _smoke_tex:  Texture2D = preload("res://assets/art/particles/smoke_128.png")

func _ready() -> void:
	_refresh_editor() if Engine.is_editor_hint() else setup(amount, flipped)

func _refresh_editor() -> void:
	for child in get_children():
		child.queue_free()
	setup(amount, flipped)

func setup(_p_amount: int, _p_flipped: bool) -> void:
	pass

func _schedule_free(delay: float) -> void:
	if Engine.is_editor_hint():
		return
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

func _emit_particle_layer(local_pos: Vector2, cfg: Dictionary) -> void:
	var p := GPUParticles2D.new()
	p.amount = int(cfg.get("count", 8))
	p.lifetime = float(cfg.get("lifetime", 0.5))
	p.one_shot = true
	p.explosiveness = 1.0
	p.z_index = int(cfg.get("z", 15))
	p.texture = cfg.get("texture", _circle_tex)

	var mat := ParticleProcessMaterial.new()
	var dir2: Vector2 = cfg.get("direction", Vector2.RIGHT)
	mat.direction = Vector3(dir2.x, dir2.y, 0.0)
	mat.spread = float(cfg.get("spread", 180.0))
	var grav2: Vector2 = cfg.get("gravity", Vector2.ZERO)
	mat.gravity = Vector3(grav2.x, grav2.y, 0.0)
	mat.initial_velocity_min = float(cfg.get("speed_min", 100.0))
	mat.initial_velocity_max = float(cfg.get("speed_max", 200.0))
	mat.scale_min = float(cfg.get("scale_min", 1.0))
	mat.scale_max = float(cfg.get("scale_max", 2.0))
	mat.radial_accel_min = float(cfg.get("radial_min", 0.0))
	mat.radial_accel_max = float(cfg.get("radial_max", 0.0))
	mat.damping_min = float(cfg.get("damping_min", 0.0))
	mat.damping_max = float(cfg.get("damping_max", 0.0))
	mat.angular_velocity_min = float(cfg.get("angular_min", 0.0))
	mat.angular_velocity_max = float(cfg.get("angular_max", 0.0))
	mat.angle_min = float(cfg.get("angle_min", 0.0))
	mat.angle_max = float(cfg.get("angle_max", 0.0))

	var grad := Gradient.new()
	grad.set_color(0, cfg.get("color_a", Color.WHITE))
	grad.set_color(1, cfg.get("color_b", Color(1, 1, 1, 0)))
	if cfg.has("color_mid"):
		grad.add_point(0.5, cfg["color_mid"])
	var grad_tex := GradientTexture1D.new()
	grad_tex.gradient = grad
	mat.color_ramp = grad_tex

	if cfg.get("pulse_scale", false):
		var sc := Curve.new()
		sc.add_point(Vector2(0.0, 0.0))
		sc.add_point(Vector2(0.35, 1.0))
		sc.add_point(Vector2(1.0, 0.0))
		var ct := CurveTexture.new()
		ct.curve = sc
		mat.set_param_texture(ParticleProcessMaterial.PARAM_SCALE, ct)
	elif cfg.get("fade_scale", true):
		var sc := Curve.new()
		sc.add_point(Vector2(0.0, 1.0))
		sc.add_point(Vector2(0.7, 0.85))
		sc.add_point(Vector2(1.0, 0.0))
		var ct := CurveTexture.new()
		ct.curve = sc
		mat.set_param_texture(ParticleProcessMaterial.PARAM_SCALE, ct)

	if cfg.get("turbulence", false):
		mat.turbulence_enabled = true
		mat.turbulence_noise_strength = float(cfg.get("turb_strength", 1.5))
		mat.turbulence_noise_scale = float(cfg.get("turb_scale", 3.0))
		mat.turbulence_influence_min = float(cfg.get("turb_min", 0.1))
		mat.turbulence_influence_max = float(cfg.get("turb_max", 0.4))

	p.process_material = mat

	if cfg.get("additive", true):
		if _additive_mat == null:
			_additive_mat = CanvasItemMaterial.new()
			_additive_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		p.material = _additive_mat

	add_child(p)
	p.position = local_pos

	var delay: float = float(cfg.get("delay", 0.0))
	if delay > 0.0:
		p.emitting = false
		get_tree().create_timer(delay).timeout.connect(func() -> void:
			if is_instance_valid(p): p.emitting = true
		)
	else:
		p.emitting = true

	get_tree().create_timer(p.lifetime + delay + 0.5).timeout.connect(p.queue_free)
