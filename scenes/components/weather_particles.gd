# scenes/components/weather_particles.gd
# 비/눈 GPU 파티클 (CPUParticles2D 금지). 신화/날씨 호환 시에만 active.
# Node2D (CanvasLayer X) — z_index 950 으로 캐릭터/fg(0~1080) 위, 화면 UI(1000) 아래.
class_name WeatherParticles
extends Node2D

const W := 1920.0
const H := 1080.0
const Z_INDEX := 1100  # 캐릭터/fg(0~1080) 위, VFX(1200) 아래

func setup(weather: String) -> void:
	for c in get_children():
		c.queue_free()
	z_index = Z_INDEX
	if weather == "rain":
		_spawn_rain()
	elif weather == "snow":
		_spawn_snow()

func _spawn_rain() -> void:
	var ps := GPUParticles2D.new()
	ps.amount = 60  # 200 → 60 (0.3배)
	ps.lifetime = 1.4
	ps.preprocess = 1.0
	ps.position = Vector2(W * 0.5, -50.0)
	ps.texture = load("res://assets/art/backgrounds/particles/raindrop.svg")
	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(W * 0.75, 1.0, 0.0)
	mat.gravity = Vector3.ZERO
	mat.direction = Vector3(0.05, 1, 0)
	mat.initial_velocity_min = 700.0
	mat.initial_velocity_max = 850.0
	mat.spread = 2.0
	mat.scale_min = 1.0
	mat.scale_max = 1.4
	mat.color = Color(0.85, 0.92, 1.0, 0.55)
	ps.process_material = mat
	ps.emitting = true
	add_child(ps)

func _spawn_snow() -> void:
	var ps := GPUParticles2D.new()
	ps.amount = 36  # 120 → 36 (0.3배)
	ps.lifetime = 8.0
	ps.preprocess = 4.0
	ps.position = Vector2(W * 0.5, -30.0)
	ps.texture = load("res://assets/art/backgrounds/particles/snowflake.svg")
	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(W * 0.75, 1.0, 0.0)
	mat.gravity = Vector3.ZERO
	mat.direction = Vector3(0.1, 1, 0)
	mat.initial_velocity_min = 80.0
	mat.initial_velocity_max = 140.0
	mat.spread = 8.0
	mat.orbit_velocity_min = -0.05
	mat.orbit_velocity_max = 0.05
	mat.scale_min = 0.8
	mat.scale_max = 1.6
	mat.color = Color(1.0, 1.0, 1.0, 0.85)
	ps.process_material = mat
	ps.emitting = true
	add_child(ps)
