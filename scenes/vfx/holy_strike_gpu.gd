# scenes/vfx/holy_strike_gpu.gd
# 신성 강타 GPU 하이브리드 — holy_strike.gd 상속 + _spawn_* override.
# 채널 mote / impact (mote/feather/haze/bottom_haze) / linger mote 모두 GPUParticles2D.
# 빛기둥, 충격파, 빛의 칼, 차지 오브, 후광 폴리곤은 원본 그대로.
extends "res://scenes/vfx/holy_strike.gd"

const _Helpers = preload("res://scenes/vfx/gpu_particle_helpers.gd")
# Holy 시리즈 — 더 흰색에 가까운 mote/haze 색 (사용자 피드백)
const _COL_MOTE_WHITE := Color(1.0, 0.97, 0.88)
const _COL_HAZE_WHITE := Color(1.0, 0.98, 0.93)

var _gpu_channel: GPUParticles2D
var _gpu_linger: GPUParticles2D
var _channel_made: bool = false
var _impact_made: bool = false
var _linger_made: bool = false

# z order: GPU haze/feather(0) < _glow_layer(5, 빛의 칼/십자/충격파) < GPU mote/linger(10)
func _ready() -> void:
	super._ready()
	if _glow_layer != null:
		_glow_layer.z_index = 5

# 채널 mote — super: 0.45 확률/frame × 60fps = 27/s × lifetime 1.6 ≈ 43 동시
# 시전자 손 위 (±11, -50~-34) 에서 spawn, vel (±0.3*60, -0.6*60~-1.4*60).
func _spawn_channel_mote() -> void:
	if _channel_made:
		return
	_channel_made = true
	_gpu_channel = _Helpers.make_emitter({
		"count": int(43 * _scale()),
		"lifetime": 1.6,
		"color": _COL_MOTE_WHITE,
		"speed_min": 36.0, "speed_max": 84.0,
		"direction": Vector2.UP, "spread": 25.0,
		"gravity": -18.0, "damping": 3.0,
		"size_min": 1.5, "size_max": 2.9,
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

# 명중 burst — mote 40 + feather 35 + haze 26 + bottom_haze 24
func _spawn_impact() -> void:
	if _impact_made:
		return
	_impact_made = true
	# mote 40 — speed 2~8 * 60 = 120~480, gravity 0.018*60²=64.8
	var mote := _Helpers.make_emitter({
		"count": _pcount(40), "lifetime": 2.3,
		"color": _COL_MOTE_WHITE,
		"speed_min": 120.0, "speed_max": 480.0,
		"direction": Vector2.UP, "spread": 180.0,
		"gravity": 64.8, "damping": 3.0,
		"size_min": 1.6, "size_max": 3.2,
		"size_base": 4.0,
		"texture": _Helpers.sparkle_tex(),
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	mote.position = _target
	mote.z_index = 10  # 빛의 칼/십자 위
	add_child(mote)
	# feather 35 — speed 1.4~5.4*60=84~324, gravity 0.01*60²=36, spin ±0.18*60=±618°/s
	var feather := _Helpers.make_emitter({
		"count": _pcount(35), "lifetime": 2.9,
		"color": Color.WHITE,
		"speed_min": 84.0, "speed_max": 324.0,
		"direction": Vector2.UP, "spread": 180.0,
		"gravity": 36.0, "damping": 3.0,
		"size_min": 11.0, "size_max": 23.0,
		"size_base": 30.0,
		"angle_min": -34.4, "angle_max": 34.4,
		"angular_velocity_min": -618.0, "angular_velocity_max": 618.0,
		"additive": false,
		"texture": _Helpers.feather_tex(),
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	feather.position = _target
	add_child(feather)
	# haze 26 — 큰 안개, COL_HAZE alpha (1-k)*0.5
	var haze := _Helpers.make_emitter({
		"count": _pcount(26), "lifetime": 2.5,
		"color": _COL_HAZE_WHITE,
		"speed_min": 36.0, "speed_max": 144.0,
		"direction": Vector2.UP, "spread": 180.0,
		"gravity": -28.8, "damping": 3.0,
		"size_min": 28.0, "size_max": 50.0,
		"additive": false,
		"start_alpha": 0.5, "mid_alpha": 0.25, "end_alpha": 0.0,
	})
	haze.position = _target
	add_child(haze)
	# bottom_haze 24 — target 아래 (+70) 에서 위로
	var bottom_haze := _Helpers.make_emitter({
		"count": _pcount(24), "lifetime": 1.8,
		"color": _COL_HAZE_WHITE,
		"speed_min": 60.0, "speed_max": 180.0,
		"direction": Vector2.UP, "spread": 40.0,
		"gravity": -36.0, "damping": 3.0,
		"size_min": 14.0, "size_max": 28.0,
		"additive": false,
		"start_alpha": 0.5, "mid_alpha": 0.25, "end_alpha": 0.0,
	})
	bottom_haze.position = _target + Vector2(0.0, 70.0)
	add_child(bottom_haze)

# 잔류 mote — 0.35 확률/frame × 60fps = 21/s × lifetime 1.85 ≈ 39 동시
func _spawn_linger() -> void:
	if _linger_made:
		return
	_linger_made = true
	_gpu_linger = _Helpers.make_emitter({
		"count": int(39 * _scale()),
		"lifetime": 1.85,
		"color": _COL_MOTE_WHITE,
		"speed_min": 12.0, "speed_max": 48.0,
		"direction": Vector2.UP, "spread": 35.0,
		"gravity": 0.0, "damping": 3.0,
		"size_min": 1.3, "size_max": 2.7,
		"size_base": 4.0,
		"emission_shape": "box", "emission_box": Vector2(35.0, 30.0),
		"texture": _Helpers.sparkle_tex(),
		"one_shot": false, "explosiveness": 0.0,
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	_gpu_linger.position = _target + Vector2(0.0, 5.0)
	_gpu_linger.z_index = 10  # 빛의 칼/십자 위
	add_child(_gpu_linger)
	get_tree().create_timer(LINGER_TIME).timeout.connect(func() -> void:
		if is_instance_valid(_gpu_linger): _gpu_linger.emitting = false)
