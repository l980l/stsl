@tool
extends Node2D

@export_enum("slash", "blunt", "projectile", "explosive", "poison", "divine", "curse") var dtype: String = "slash":
	set(v):
		dtype = v
		if Engine.is_editor_hint() and auto_preview:
			_trigger_preview()

@export_range(1, 300) var amount: int = 80:
	set(v):
		amount = v
		if Engine.is_editor_hint() and auto_preview:
			_trigger_preview()

@export var auto_preview: bool = true

@export var trigger: bool = false:
	set(v):
		if v:
			trigger = false
			_trigger_preview()

@export var loop_preview: bool = false

var _loop_timer: float = 0.0
const _LOOP_INTERVAL := 1.8

var _circle_tex: Texture2D = preload("res://assets/art/particles/circle_128.png")
var _slash_tex: Texture2D  = preload("res://assets/art/particles/slash_128x16.png")
var _square_tex: Texture2D = preload("res://assets/art/particles/dust_64.png")
var _star_tex: Texture2D   = preload("res://assets/art/particles/star_128.png")
var _smoke_tex: Texture2D  = preload("res://assets/art/particles/smoke_128.png")
var _additive_mat: CanvasItemMaterial = null

func _process(delta: float) -> void:
	if not loop_preview:
		_loop_timer = 0.0
		return
	_loop_timer += delta
	if _loop_timer >= _LOOP_INTERVAL:
		_loop_timer = 0.0
		_trigger_preview()

func _trigger_preview() -> void:
	_spawn_impact_particles(Vector2.ZERO, amount, false, dtype)

# ── 텍스처 ──────────────────────────────────────────────────

func _make_circle_texture() -> ImageTexture:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	var center := Vector2(7.5, 7.5)
	for x in range(16):
		for y in range(16):
			var d: float = Vector2(x, y).distance_to(center) / 7.5
			var a: float = clampf(1.0 - d * d, 0.0, 1.0)
			a = pow(a, 1.4)
			img.set_pixel(x, y, Color(1, 1, 1, a))
	return ImageTexture.create_from_image(img)

func _make_slash_texture() -> ImageTexture:
	var img := Image.create(32, 4, false, Image.FORMAT_RGBA8)
	for x in range(32):
		var t: float = float(x) / 31.0
		var a: float = pow(sin(t * PI), 1.6)
		for y in range(4):
			var ya: float = 1.0 - abs(float(y) - 1.5) / 2.0
			img.set_pixel(x, y, Color(1, 1, 1, a * ya))
	return ImageTexture.create_from_image(img)

func _make_square_texture() -> ImageTexture:
	var img := Image.create(6, 6, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 1, 0))
	for x in range(6):
		for y in range(6):
			if x == 0 or x == 5 or y == 0 or y == 5:
				img.set_pixel(x, y, Color(1, 1, 1, 1))
			else:
				img.set_pixel(x, y, Color(1, 1, 1, 0.25))
	return ImageTexture.create_from_image(img)

func _make_star_texture() -> ImageTexture:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var c := Vector2(7.5, 7.5)
	for x in range(16):
		for y in range(16):
			var pt := Vector2(x, y)
			var d := pt.distance_to(c)
			var angle := (pt - c).angle()
			var spikes: float = abs(cos(angle * 4.0))
			var r: float = 3.0 + spikes * 4.0
			var a: float = clampf(1.0 - d / r, 0.0, 1.0)
			a = pow(a, 0.7)
			img.set_pixel(x, y, Color(1, 1, 1, a))
	return ImageTexture.create_from_image(img)

func _make_smoke_texture() -> ImageTexture:
	var img := Image.create(24, 24, false, Image.FORMAT_RGBA8)
	var center := Vector2(11.5, 11.5)
	for x in range(24):
		for y in range(24):
			var d: float = Vector2(x, y).distance_to(center) / 11.5
			var a: float = clampf(1.0 - d * d * d, 0.0, 1.0) * 0.55
			img.set_pixel(x, y, Color(1, 1, 1, a))
	return ImageTexture.create_from_image(img)

# ── 레이어 헬퍼 ─────────────────────────────────────────────

func _emit_particle_layer(pos: Vector2, cfg: Dictionary) -> void:
	var p := GPUParticles2D.new()
	p.amount = int(cfg.get("count", 8))
	p.lifetime = float(cfg.get("lifetime", 0.3))
	p.one_shot = true
	p.explosiveness = 1.0
	p.z_index = int(cfg.get("z", 15))
	p.texture = cfg.get("texture", _circle_tex)

	var mat := ParticleProcessMaterial.new()
	var dir2: Vector2 = cfg.get("direction", Vector2(0, -1))
	mat.direction = Vector3(dir2.x, dir2.y, 0.0)
	mat.spread = float(cfg.get("spread", 45.0))
	var grav2: Vector2 = cfg.get("gravity", Vector2.ZERO)
	mat.gravity = Vector3(grav2.x, grav2.y, 0.0)
	mat.initial_velocity_min = float(cfg.get("speed_min", 100.0))
	mat.initial_velocity_max = float(cfg.get("speed_max", 250.0))
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
	p.position = pos

	var delay: float = float(cfg.get("delay", 0.0))
	if delay > 0.0:
		get_tree().create_timer(delay).timeout.connect(func() -> void:
			if is_instance_valid(p): p.emitting = true
		)
	else:
		p.emitting = true

	get_tree().create_timer(p.lifetime + delay + 0.5).timeout.connect(func() -> void:
		if is_instance_valid(p): p.queue_free()
	)

# ── 스폰 (battle_scene.gd와 동기화 유지) ────────────────────

func _spawn_impact_particles(pos: Vector2, amount: int, flipped: bool = false, dtype_val: String = "") -> void:
	if amount <= 0:
		return
	var mag: int = 0 if amount < 30 else (1 if amount < 100 else 2)
	var dx: float = -1.0 if flipped else 1.0
	var eff := dtype_val if dtype_val != "" else "slash"

	match eff:
		"slash":
			_emit_particle_layer(pos, {
				"count": 1,
				"lifetime": 0.45,
				"spread": 0.0, "speed_min": 0.0, "speed_max": 0.0,
				"scale_min": [1.5, 2.1, 3.0][mag], "scale_max": [1.9, 2.5, 3.5][mag],
				"texture": _slash_tex,
				"color_a": Color(2.2, 2.2, 2.2, 1.0),
				"color_b": Color(0.6, 0.85, 1.0, 0.0),
				"angle_min": -3.0, "angle_max": 3.0,
				"pulse_scale": true,
			})
			_emit_particle_layer(pos, {
				"count": [1, 2, 2][mag],
				"lifetime": 0.6,
				"spread": 0.0, "speed_min": 0.0, "speed_max": 0.0,
				"scale_min": [1.0, 1.4, 2.0][mag], "scale_max": [1.4, 1.9, 2.5][mag],
				"texture": _slash_tex,
				"color_a": Color(1.2, 1.5, 2.0, 0.55),
				"color_b": Color(0.2, 0.4, 0.85, 0.0),
				"angle_min": -18.0, "angle_max": 18.0,
				"pulse_scale": true,
				"delay": 0.06,
			})
			_emit_particle_layer(pos, {
				"count": 1, "lifetime": 0.28,
				"spread": 0.0, "speed_min": 0.0, "speed_max": 0.0,
				"scale_min": 0.55, "scale_max": 0.7,
				"texture": _circle_tex,
				"color_a": Color(2.5, 2.5, 2.5, 0.85),
				"color_b": Color(0.7, 0.85, 1.0, 0.0),
				"pulse_scale": true,
			})
		"blunt":
			_emit_particle_layer(pos, {
				"count": 1, "lifetime": 0.18,
				"spread": 0.0, "speed_min": 0.0, "speed_max": 0.0,
				"scale_min": 0.62, "scale_max": 0.88,
				"texture": _circle_tex,
				"color_a": Color(2.0, 1.7, 0.8, 0.85),
				"color_b": Color(1.0, 0.45, 0.15, 0.0),
			})
			_emit_particle_layer(pos, {
				"count": [22, 34, 50][mag],
				"lifetime": 0.65,
				"spread": 180.0,
				"speed_min": 100.0, "speed_max": 280.0,
				"gravity": Vector2(0, 420),
				"scale_min": 0.38, "scale_max": 0.75,
				"texture": _circle_tex,
				"color_a": Color(0.82, 0.65, 0.42, 0.9),
				"color_mid": Color(0.55, 0.42, 0.28, 0.55),
				"color_b": Color(0.22, 0.16, 0.10, 0.0),
				"damping_min": 60.0, "damping_max": 130.0,
				"turbulence": true, "turb_strength": 1.2, "turb_scale": 2.5,
				"turb_min": 0.1, "turb_max": 0.3,
				"additive": false,
			})
			_emit_particle_layer(pos, {
				"count": [6, 10, 14][mag],
				"lifetime": 0.7,
				"direction": Vector2(0.0, -1.0),
				"spread": 130.0,
				"speed_min": 200.0, "speed_max": 380.0,
				"gravity": Vector2(0, 520),
				"scale_min": 0.19, "scale_max": 0.35,
				"texture": _square_tex,
				"color_a": Color(0.55, 0.45, 0.32, 1.0),
				"color_b": Color(0.18, 0.14, 0.10, 0.0),
				"angular_min": -240.0, "angular_max": 240.0,
				"additive": false,
			})
		"projectile":
			var launch_pos := pos - Vector2(dx, 0.0) * 400.0
			var proj_angle := 0.0 if dx > 0.0 else 180.0
			_emit_particle_layer(launch_pos, {
				"count": [3, 5, 7][mag],
				"lifetime": 0.23,
				"direction": Vector2(dx, 0.0),
				"spread": 4.0,
				"speed_min": 1500.0, "speed_max": 1900.0,
				"scale_min": 0.62, "scale_max": 1.0,
				"texture": _slash_tex,
				"color_a": Color(2.0, 1.9, 1.4, 1.0),
				"color_b": Color(0.8, 0.6, 0.2, 0.0),
				"damping_min": 200.0, "damping_max": 400.0,
				"angle_min": proj_angle - 2.0, "angle_max": proj_angle + 2.0,
			})
			_emit_particle_layer(pos, {
				"count": 1, "lifetime": 0.1,
				"spread": 0.0, "speed_min": 0.0, "speed_max": 0.0,
				"scale_min": 0.5, "scale_max": 0.7,
				"texture": _circle_tex,
				"color_a": Color(2.5, 2.5, 2.0, 1.0),
				"color_b": Color(1.0, 0.9, 0.5, 0.0),
				"delay": 0.18,
			})
			_emit_particle_layer(pos, {
				"count": [5, 8, 12][mag],
				"lifetime": 0.35,
				"direction": Vector2(-dx, -0.3),
				"spread": 70.0,
				"speed_min": 100.0, "speed_max": 280.0,
				"gravity": Vector2(0, 220),
				"scale_min": 0.13, "scale_max": 0.25,
				"texture": _circle_tex,
				"color_a": Color(2.0, 1.8, 1.0, 1.0),
				"color_b": Color(0.85, 0.3, 0.08, 0.0),
				"damping_min": 50.0, "damping_max": 120.0,
				"delay": 0.18,
			})
		"explosive":
			_emit_particle_layer(pos, {
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
			_emit_particle_layer(pos, {
				"count": 1, "lifetime": 0.3,
				"spread": 0.0, "speed_min": 0.0, "speed_max": 0.0,
				"scale_min": 1.25, "scale_max": 1.75,
				"texture": _circle_tex,
				"color_a": Color(3.0, 1.8, 0.4, 1.0),
				"color_b": Color(1.5, 0.4, 0.08, 0.0),
				"pulse_scale": true,
			})
			_emit_particle_layer(pos, {
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
		"poison":
			_emit_particle_layer(pos, {
				"count": [16, 24, 34][mag],
				"lifetime": 1.2,
				"direction": Vector2(0.0, -1.0),
				"spread": 110.0,
				"speed_min": 25.0, "speed_max": 120.0,
				"gravity": Vector2(0, -50),
				"scale_min": 0.23, "scale_max": 0.44,
				"texture": _circle_tex,
				"color_a": Color(0.6, 2.0, 0.4, 0.9),
				"color_mid": Color(0.18, 0.85, 0.1, 0.5),
				"color_b": Color(0.05, 0.32, 0.0, 0.0),
				"turbulence": true, "turb_strength": 1.0, "turb_scale": 3.5,
				"turb_min": 0.1, "turb_max": 0.35,
			})
			_emit_particle_layer(pos, {
				"count": [12, 18, 26][mag],
				"lifetime": 1.5,
				"direction": Vector2(0.0, -1.0),
				"spread": 170.0,
				"speed_min": 12.0, "speed_max": 65.0,
				"gravity": Vector2(0, -22),
				"scale_min": 0.10, "scale_max": 0.19,
				"texture": _circle_tex,
				"color_a": Color(0.18, 0.55, 0.08, 0.9),
				"color_b": Color(0.0, 0.18, 0.0, 0.0),
				"turbulence": true, "turb_strength": 0.8, "turb_scale": 4.0,
				"turb_min": 0.05, "turb_max": 0.25,
				"additive": false,
				"delay": 0.05,
			})
			_emit_particle_layer(pos, {
				"count": 1, "lifetime": 0.2,
				"spread": 0.0, "speed_min": 0.0, "speed_max": 0.0,
				"scale_min": 0.5, "scale_max": 0.69,
				"texture": _circle_tex,
				"color_a": Color(0.6, 2.5, 0.4, 0.85),
				"color_b": Color(0.1, 0.5, 0.0, 0.0),
			})
		"divine":
			_emit_particle_layer(pos, {
				"count": [20, 32, 48][mag],
				"lifetime": 0.8,
				"direction": Vector2(1.0, 0.0),
				"spread": 180.0,
				"speed_min": 120.0, "speed_max": 320.0,
				"gravity": Vector2(0, -60),
				"scale_min": 0.28, "scale_max": 0.56,
				"texture": _circle_tex,
				"color_a": Color(2.0, 1.9, 1.2, 1.0),
				"color_mid": Color(2.0, 1.5, 0.4, 0.7),
				"color_b": Color(1.0, 0.55, 0.1, 0.0),
				"damping_min": 70.0, "damping_max": 150.0,
			})
			_emit_particle_layer(pos, {
				"count": [7, 12, 18][mag],
				"lifetime": 1.0,
				"direction": Vector2(1.0, 0.0),
				"spread": 180.0,
				"speed_min": 75.0, "speed_max": 220.0,
				"gravity": Vector2(0, -40),
				"scale_min": 0.31, "scale_max": 0.63,
				"texture": _star_tex,
				"color_a": Color(2.2, 2.0, 0.8, 1.0),
				"color_b": Color(1.5, 1.5, 1.0, 0.0),
				"angular_min": -180.0, "angular_max": 180.0,
				"delay": 0.04,
			})
			_emit_particle_layer(pos, {
				"count": 1, "lifetime": 0.22,
				"spread": 0.0, "speed_min": 0.0, "speed_max": 0.0,
				"scale_min": 1.12, "scale_max": 1.5,
				"texture": _circle_tex,
				"color_a": Color(3.0, 2.8, 1.8, 1.0),
				"color_b": Color(1.5, 1.2, 0.4, 0.0),
				"pulse_scale": true,
			})
		"curse":
			_emit_particle_layer(pos, {
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
			_emit_particle_layer(pos, {
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
			_emit_particle_layer(pos, {
				"count": 1, "lifetime": 0.2,
				"spread": 0.0, "speed_min": 0.0, "speed_max": 0.0,
				"scale_min": 0.62, "scale_max": 0.81,
				"texture": _circle_tex,
				"color_a": Color(1.5, 0.3, 2.5, 0.9),
				"color_b": Color(0.2, 0.0, 0.4, 0.0),
			})
