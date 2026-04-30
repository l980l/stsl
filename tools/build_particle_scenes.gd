@tool
extends EditorScript

# Editor > Run Script 으로 1회 실행 → scenes/vfx/*.tscn 에 GPUParticles2D 자식 생성
# 이후 Inspector에서 직접 편집. 재실행하면 Inspector 편집값이 덮어써짐에 주의.

const CIRCLE := preload("res://assets/art/particles/circle_128.png")
const SLASH  := preload("res://assets/art/particles/slash_128x16.png")
const SQUARE := preload("res://assets/art/particles/dust_64.png")
const STAR   := preload("res://assets/art/particles/star_128.png")
const SMOKE  := preload("res://assets/art/particles/smoke_128.png")

func _run() -> void:
	_build("slash",      _slash_layers())
	_build("blunt",      _blunt_layers())
	_build("projectile", _projectile_layers())
	_build("explosive",  _explosive_layers())
	_build("poison",     _poison_layers())
	_build("divine",     _divine_layers())
	_build("curse",      _curse_layers())
	_build("default",    _default_layers())
	print("=== 파티클 씬 빌드 완료 ===")

# ── 씬 빌드 ──────────────────────────────────────────────────────────────────

func _build(dtype: String, layers: Array) -> void:
	var root := Node2D.new()
	root.name = dtype.capitalize() + "Particle"
	root.set_script(load("res://scenes/vfx/%s_particle.gd" % dtype))

	for i in layers.size():
		var p := _make_particle(layers[i])
		p.name = "Layer%d" % (i + 1)
		root.add_child(p)
		p.owner = root

	var packed := PackedScene.new()
	packed.pack(root)
	ResourceSaver.save(packed, "res://scenes/vfx/%s_particle.tscn" % dtype)
	root.queue_free()
	print("빌드: %s_particle.tscn" % dtype)

func _make_particle(cfg: Dictionary) -> GPUParticles2D:
	var p := GPUParticles2D.new()
	p.amount       = int(cfg.get("count", 8))
	p.lifetime     = float(cfg.get("lifetime", 0.5))
	p.one_shot     = true
	p.explosiveness = 1.0
	p.z_index      = 15
	p.local_coords = true   # scale.x=-1 로 방향 반전 가능하게
	p.emitting     = false
	p.texture      = cfg.get("texture", CIRCLE)
	if cfg.get("delay", 0.0) > 0.0:
		p.set_meta("layer_delay", float(cfg["delay"]))

	var mat := ParticleProcessMaterial.new()
	var dir2: Vector2 = cfg.get("direction", Vector2.RIGHT)
	mat.direction            = Vector3(dir2.x, dir2.y, 0.0)
	mat.spread               = float(cfg.get("spread", 180.0))
	var grav2: Vector2       = cfg.get("gravity", Vector2.ZERO)
	mat.gravity              = Vector3(grav2.x, grav2.y, 0.0)
	mat.initial_velocity_min = float(cfg.get("speed_min", 0.0))
	mat.initial_velocity_max = float(cfg.get("speed_max", 0.0))
	mat.scale_min            = float(cfg.get("scale_min", 1.0))
	mat.scale_max            = float(cfg.get("scale_max", 1.0))
	mat.radial_accel_min     = float(cfg.get("radial_min", 0.0))
	mat.radial_accel_max     = float(cfg.get("radial_max", 0.0))
	mat.damping_min          = float(cfg.get("damping_min", 0.0))
	mat.damping_max          = float(cfg.get("damping_max", 0.0))
	mat.angular_velocity_min = float(cfg.get("angular_min", 0.0))
	mat.angular_velocity_max = float(cfg.get("angular_max", 0.0))
	mat.angle_min            = float(cfg.get("angle_min", 0.0))
	mat.angle_max            = float(cfg.get("angle_max", 0.0))

	if cfg.get("turbulence", false):
		mat.turbulence_enabled           = true
		mat.turbulence_noise_strength    = float(cfg.get("turb_strength", 1.5))
		mat.turbulence_noise_scale       = float(cfg.get("turb_scale", 3.0))
		mat.turbulence_influence_min     = float(cfg.get("turb_min", 0.1))
		mat.turbulence_influence_max     = float(cfg.get("turb_max", 0.4))

	var grad := Gradient.new()
	grad.set_color(0, cfg.get("color_a", Color.WHITE))
	grad.set_color(1, cfg.get("color_b", Color(1, 1, 1, 0)))
	if cfg.has("color_mid"):
		grad.add_point(0.5, cfg["color_mid"])
	var gt := GradientTexture1D.new()
	gt.gradient = grad
	mat.color_ramp = gt

	if cfg.get("pulse_scale", false):
		var sc := Curve.new()
		sc.add_point(Vector2(0.0, 0.0))
		sc.add_point(Vector2(0.35, 1.0))
		sc.add_point(Vector2(1.0, 0.0))
		var ct := CurveTexture.new()
		ct.curve = sc
		mat.set_param_texture(ParticleProcessMaterial.PARAM_SCALE, ct)
	else:
		var sc := Curve.new()
		sc.add_point(Vector2(0.0, 1.0))
		sc.add_point(Vector2(0.7, 0.85))
		sc.add_point(Vector2(1.0, 0.0))
		var ct := CurveTexture.new()
		ct.curve = sc
		mat.set_param_texture(ParticleProcessMaterial.PARAM_SCALE, ct)

	p.process_material = mat

	if cfg.get("additive", true):
		var cm := CanvasItemMaterial.new()
		cm.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		p.material = cm

	if cfg.has("local_pos"):
		p.position = cfg["local_pos"]

	return p

# ── dtype별 레이어 정의 ───────────────────────────────────────────────────────

func _slash_layers() -> Array:
	return [
		{ "count": 1, "lifetime": 0.45,
		  "spread": 0.0, "speed_min": 0.0, "speed_max": 0.0,
		  "scale_min": 2.1, "scale_max": 2.5, "texture": SLASH,
		  "color_a": Color(2.2, 2.2, 2.2, 1.0), "color_b": Color(0.6, 0.85, 1.0, 0.0),
		  "angle_min": -3.0, "angle_max": 3.0, "pulse_scale": true },
		{ "count": 2, "lifetime": 0.6,
		  "spread": 0.0, "speed_min": 0.0, "speed_max": 0.0,
		  "scale_min": 1.4, "scale_max": 1.9, "texture": SLASH,
		  "color_a": Color(1.2, 1.5, 2.0, 0.55), "color_b": Color(0.2, 0.4, 0.85, 0.0),
		  "angle_min": -18.0, "angle_max": 18.0, "pulse_scale": true, "delay": 0.06 },
		{ "count": 1, "lifetime": 0.28,
		  "spread": 0.0, "speed_min": 0.0, "speed_max": 0.0,
		  "scale_min": 0.55, "scale_max": 0.7, "texture": CIRCLE,
		  "color_a": Color(2.5, 2.5, 2.5, 0.85), "color_b": Color(0.7, 0.85, 1.0, 0.0),
		  "pulse_scale": true },
	]

func _blunt_layers() -> Array:
	return [
		{ "count": 1, "lifetime": 0.18,
		  "spread": 0.0, "speed_min": 0.0, "speed_max": 0.0,
		  "scale_min": 0.62, "scale_max": 0.88, "texture": CIRCLE,
		  "color_a": Color(2.0, 1.7, 0.8, 0.85), "color_b": Color(1.0, 0.45, 0.15, 0.0) },
		{ "count": 34, "lifetime": 0.65, "spread": 180.0,
		  "speed_min": 100.0, "speed_max": 280.0, "gravity": Vector2(0, 420),
		  "scale_min": 0.38, "scale_max": 0.75, "texture": CIRCLE,
		  "color_a": Color(0.82, 0.65, 0.42, 0.9), "color_mid": Color(0.55, 0.42, 0.28, 0.55),
		  "color_b": Color(0.22, 0.16, 0.10, 0.0),
		  "damping_min": 60.0, "damping_max": 130.0,
		  "turbulence": true, "turb_strength": 1.2, "turb_scale": 2.5,
		  "turb_min": 0.1, "turb_max": 0.3, "additive": false },
		{ "count": 10, "lifetime": 0.7,
		  "direction": Vector2(0.0, -1.0), "spread": 130.0,
		  "speed_min": 200.0, "speed_max": 380.0, "gravity": Vector2(0, 520),
		  "scale_min": 0.19, "scale_max": 0.35, "texture": SQUARE,
		  "color_a": Color(0.55, 0.45, 0.32, 1.0), "color_b": Color(0.18, 0.14, 0.10, 0.0),
		  "angular_min": -240.0, "angular_max": 240.0, "additive": false },
	]

func _projectile_layers() -> Array:
	# Layer1 local_pos: 발사 위치 (flipped=false 기준, scale.x=-1 시 자동 반전)
	return [
		{ "count": 5, "lifetime": 0.23,
		  "direction": Vector2(1.0, 0.0), "spread": 4.0,
		  "speed_min": 1500.0, "speed_max": 1900.0,
		  "scale_min": 0.62, "scale_max": 1.0, "texture": SLASH,
		  "color_a": Color(2.0, 1.9, 1.4, 1.0), "color_b": Color(0.8, 0.6, 0.2, 0.0),
		  "damping_min": 200.0, "damping_max": 400.0,
		  "angle_min": -2.0, "angle_max": 2.0,
		  "local_pos": Vector2(-400.0, 0.0) },
		{ "count": 1, "lifetime": 0.1,
		  "spread": 0.0, "speed_min": 0.0, "speed_max": 0.0,
		  "scale_min": 0.5, "scale_max": 0.7, "texture": CIRCLE,
		  "color_a": Color(2.5, 2.5, 2.0, 1.0), "color_b": Color(1.0, 0.9, 0.5, 0.0),
		  "delay": 0.18 },
		{ "count": 8, "lifetime": 0.35,
		  "direction": Vector2(-1.0, -0.3), "spread": 70.0,
		  "speed_min": 100.0, "speed_max": 280.0, "gravity": Vector2(0, 220),
		  "scale_min": 0.13, "scale_max": 0.25, "texture": CIRCLE,
		  "color_a": Color(2.0, 1.8, 1.0, 1.0), "color_b": Color(0.85, 0.3, 0.08, 0.0),
		  "damping_min": 50.0, "damping_max": 120.0, "delay": 0.18 },
	]

func _explosive_layers() -> Array:
	return [
		{ "count": 50, "lifetime": 0.55, "spread": 180.0,
		  "speed_min": 120.0, "speed_max": 360.0, "gravity": Vector2(0, -40),
		  "scale_min": 0.44, "scale_max": 0.88, "texture": CIRCLE,
		  "color_a": Color(2.5, 1.8, 0.5, 1.0), "color_mid": Color(2.0, 0.6, 0.08, 0.7),
		  "color_b": Color(0.3, 0.05, 0.0, 0.0),
		  "damping_min": 80.0, "damping_max": 200.0 },
		{ "count": 1, "lifetime": 0.3,
		  "spread": 0.0, "speed_min": 0.0, "speed_max": 0.0,
		  "scale_min": 1.25, "scale_max": 1.75, "texture": CIRCLE,
		  "color_a": Color(3.0, 1.8, 0.4, 1.0), "color_b": Color(1.5, 0.4, 0.08, 0.0),
		  "pulse_scale": true },
		{ "count": 22, "lifetime": 1.2,
		  "direction": Vector2(0.0, -1.0), "spread": 180.0,
		  "speed_min": 35.0, "speed_max": 140.0, "gravity": Vector2(0, -55),
		  "scale_min": 0.62, "scale_max": 1.12, "texture": SMOKE,
		  "color_a": Color(0.35, 0.28, 0.24, 0.85), "color_b": Color(0.05, 0.04, 0.03, 0.0),
		  "turbulence": true, "turb_strength": 2.0, "turb_scale": 1.5,
		  "turb_min": 0.15, "turb_max": 0.5, "additive": false, "delay": 0.07 },
	]

func _poison_layers() -> Array:
	return [
		{ "count": 24, "lifetime": 1.2,
		  "direction": Vector2(0.0, -1.0), "spread": 110.0,
		  "speed_min": 25.0, "speed_max": 120.0, "gravity": Vector2(0, -50),
		  "scale_min": 0.23, "scale_max": 0.44, "texture": CIRCLE,
		  "color_a": Color(0.6, 2.0, 0.4, 0.9), "color_mid": Color(0.18, 0.85, 0.1, 0.5),
		  "color_b": Color(0.05, 0.32, 0.0, 0.0),
		  "turbulence": true, "turb_strength": 1.0, "turb_scale": 3.5,
		  "turb_min": 0.1, "turb_max": 0.35 },
		{ "count": 18, "lifetime": 1.5,
		  "direction": Vector2(0.0, -1.0), "spread": 170.0,
		  "speed_min": 12.0, "speed_max": 65.0, "gravity": Vector2(0, -22),
		  "scale_min": 0.10, "scale_max": 0.19, "texture": CIRCLE,
		  "color_a": Color(0.18, 0.55, 0.08, 0.9), "color_b": Color(0.0, 0.18, 0.0, 0.0),
		  "turbulence": true, "turb_strength": 0.8, "turb_scale": 4.0,
		  "turb_min": 0.05, "turb_max": 0.25, "additive": false, "delay": 0.05 },
		{ "count": 1, "lifetime": 0.2,
		  "spread": 0.0, "speed_min": 0.0, "speed_max": 0.0,
		  "scale_min": 0.5, "scale_max": 0.69, "texture": CIRCLE,
		  "color_a": Color(0.6, 2.5, 0.4, 0.85), "color_b": Color(0.1, 0.5, 0.0, 0.0) },
	]

func _divine_layers() -> Array:
	return [
		{ "count": 32, "lifetime": 0.8,
		  "direction": Vector2(1.0, 0.0), "spread": 180.0,
		  "speed_min": 120.0, "speed_max": 320.0, "gravity": Vector2(0, -60),
		  "scale_min": 0.28, "scale_max": 0.56, "texture": CIRCLE,
		  "color_a": Color(2.0, 1.9, 1.2, 1.0), "color_mid": Color(2.0, 1.5, 0.4, 0.7),
		  "color_b": Color(1.0, 0.55, 0.1, 0.0),
		  "damping_min": 70.0, "damping_max": 150.0 },
		{ "count": 12, "lifetime": 1.0,
		  "direction": Vector2(1.0, 0.0), "spread": 180.0,
		  "speed_min": 75.0, "speed_max": 220.0, "gravity": Vector2(0, -40),
		  "scale_min": 0.31, "scale_max": 0.63, "texture": STAR,
		  "color_a": Color(2.2, 2.0, 0.8, 1.0), "color_b": Color(1.5, 1.5, 1.0, 0.0),
		  "angular_min": -180.0, "angular_max": 180.0, "delay": 0.04 },
		{ "count": 1, "lifetime": 0.22,
		  "spread": 0.0, "speed_min": 0.0, "speed_max": 0.0,
		  "scale_min": 1.12, "scale_max": 1.5, "texture": CIRCLE,
		  "color_a": Color(3.0, 2.8, 1.8, 1.0), "color_b": Color(1.5, 1.2, 0.4, 0.0),
		  "pulse_scale": true },
	]

func _curse_layers() -> Array:
	return [
		{ "count": 28, "lifetime": 0.95, "spread": 180.0,
		  "speed_min": 70.0, "speed_max": 200.0,
		  "scale_min": 0.23, "scale_max": 0.44, "texture": CIRCLE,
		  "color_a": Color(1.5, 0.35, 2.0, 1.0), "color_mid": Color(0.7, 0.08, 1.2, 0.7),
		  "color_b": Color(0.05, 0.0, 0.15, 0.0),
		  "radial_min": -180.0, "radial_max": -80.0,
		  "angular_min": -200.0, "angular_max": 200.0,
		  "turbulence": true, "turb_strength": 1.8, "turb_scale": 2.0,
		  "turb_min": 0.15, "turb_max": 0.5 },
		{ "count": 16, "lifetime": 1.1,
		  "direction": Vector2(0.0, -1.0), "spread": 130.0,
		  "speed_min": 25.0, "speed_max": 90.0, "gravity": Vector2(0, -35),
		  "scale_min": 0.44, "scale_max": 0.75, "texture": SMOKE,
		  "color_a": Color(0.22, 0.05, 0.35, 0.75), "color_b": Color(0.02, 0.0, 0.05, 0.0),
		  "turbulence": true, "turb_strength": 1.5, "turb_scale": 2.5,
		  "turb_min": 0.1, "turb_max": 0.4, "additive": false, "delay": 0.05 },
		{ "count": 1, "lifetime": 0.2,
		  "spread": 0.0, "speed_min": 0.0, "speed_max": 0.0,
		  "scale_min": 0.62, "scale_max": 0.81, "texture": CIRCLE,
		  "color_a": Color(1.5, 0.3, 2.5, 0.9), "color_b": Color(0.2, 0.0, 0.4, 0.0) },
	]

func _default_layers() -> Array:
	return [
		{ "count": 10, "lifetime": 0.32,
		  "direction": Vector2(1.0, 0.0), "spread": 80.0,
		  "speed_min": 150.0, "speed_max": 320.0, "gravity": Vector2(0, 200),
		  "scale_min": 0.19, "scale_max": 0.38, "texture": CIRCLE,
		  "color_a": Color(2.2, 2.2, 1.8, 1.0), "color_b": Color(1.5, 0.8, 0.1, 0.0),
		  "damping_min": 60.0, "damping_max": 140.0 },
		{ "count": 1, "lifetime": 0.12,
		  "spread": 0.0, "speed_min": 0.0, "speed_max": 0.0,
		  "scale_min": 0.62, "scale_max": 0.88, "texture": CIRCLE,
		  "color_a": Color(2.5, 2.2, 1.2, 0.9), "color_b": Color(1.5, 0.8, 0.15, 0.0) },
	]
