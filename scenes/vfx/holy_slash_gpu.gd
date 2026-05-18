# scenes/vfx/holy_slash_gpu.gd
# 신성 베기 GPU 하이브리드 — holy_slash.gd 상속.
# channel mote / feather burst GPU 화. slash particle (PackedScene) + 후광 폴리곤 CPU.
extends "res://scenes/vfx/holy_slash.gd"

const _Helpers = preload("res://scenes/vfx/gpu_particle_helpers.gd")
# Holy 시리즈 — 더 흰색에 가까운 mote/haze 색 (사용자 피드백)
const _COL_MOTE_WHITE := Color(1.0, 0.97, 0.88)
const _COL_HAZE_WHITE := Color(1.0, 0.98, 0.93)

var _gpu_channel: GPUParticles2D
var _channel_made: bool = false
var _impact_made: bool = false

# 채널 mote — 0.7 확률/frame × 60 = 42/s × lifetime 1.2 ≈ 50 동시
func _spawn_channel_mote() -> void:
	if _channel_made:
		return
	_channel_made = true
	_gpu_channel = _Helpers.make_emitter({
		"count": int(50 * _scale()),
		"lifetime": 1.2,
		"color": _COL_MOTE_WHITE,
		"speed_min": 24.0, "speed_max": 60.0,
		"direction": Vector2.UP, "spread": 25.0,
		"gravity": -18.0, "damping": 3.0,
		"size_min": 1.4, "size_max": 2.8,
		"size_base": 4.0,
		"emission_shape": "box", "emission_box": Vector2(11.0, 8.0),
		"texture": _Helpers.sparkle_tex(),
		"one_shot": false, "explosiveness": 0.0,
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	_gpu_channel.position = _caster + Vector2(0.0, -42.0)
	add_child(_gpu_channel)
	get_tree().create_timer(CHANNEL_TIME).timeout.connect(func() -> void:
		if is_instance_valid(_gpu_channel): _gpu_channel.emitting = false)

# 베기 명중 — slash particle (PackedScene 그대로 super) + feather GPU
func _spawn_basic_slash_and_feathers() -> void:
	if _impact_made:
		return
	_impact_made = true
	# super 의 slash PackedScene 부분만 호출 (feather _particles.append 부분은 GPU 로 대체)
	var slash_rot: float = randf_range(0.0, TAU)
	var fx: Node2D = _VFX_SLASH_PARTICLE.instantiate()
	if "autostart" in fx:
		fx.autostart = false
	if "repeat" in fx:
		fx.repeat = false
	add_child(fx)
	fx.global_position = _target
	fx.rotation = slash_rot
	fx.burst()
	# feather burst — 베기 방향 ±0.7 rad cone, speed 1.5~5.5*60
	var dir := Vector2(cos(slash_rot), sin(slash_rot))
	var feather := _Helpers.make_emitter({
		"count": _pcount(FEATHER_COUNT),
		"lifetime": 1.8,
		"color": Color.WHITE,  # 텍스처 색 (COL_FEATHER 매칭은 sparkle 와 비슷 — 일단 white)
		"speed_min": 90.0, "speed_max": 330.0,
		"direction": dir, "spread": 40.0,  # ±0.7 rad ≈ 40°
		"gravity": 43.2, "damping": 3.0,  # 0.012 * 60²
		"size_min": 8.0, "size_max": 16.0,
		"size_base": 30.0,
		"angle_min": -34.4, "angle_max": 34.4,
		"angular_velocity_min": -618.0, "angular_velocity_max": 618.0,
		"additive": false,
		"texture": _Helpers.feather_tex(),
		"start_alpha": 0.95, "mid_alpha": 0.475, "end_alpha": 0.0,
	})
	feather.position = _target
	add_child(feather)
