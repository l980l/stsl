# scenes/vfx/charm_kiss_gpu.gd
# 매혹 키스 GPU 하이브리드 — charm_kiss.gd 상속, 원본 spec 정확 매핑.
# heart (32점 베지어 폴리곤) → heart_tex 사용. petal/sparkle/smoke → 적절 텍스처.
# 차지오브, 투사체, 충격파, 나선, 매혹 오라 등 폴리곤 CPU.
extends "res://scenes/vfx/charm_kiss.gd"

const _Helpers = preload("res://scenes/vfx/gpu_particle_helpers.gd")

# trail emitters (continuous, 비행 중 매 프레임 위치 동기)
var _gpu_trail_heart: GPUParticles2D
var _gpu_trail_sparkle: GPUParticles2D
var _gpu_trail_smoke: GPUParticles2D
var _trail_made: bool = false

# impact emitters
var _impact_made: bool = false

# ambient emitters (잔류)
var _gpu_amb_heart_rose: GPUParticles2D
var _gpu_amb_heart_violet: GPUParticles2D
var _gpu_amb_sparkle: GPUParticles2D
var _amb_made: bool = false

# ── 비행 trail ──
# 원본 _spawn_trail (매 프레임 호출):
#  - heart: pos = trail_pos + ±10 offset, vel (±0.4, -0.3 ~ -0.8) * 60, lifetime 0.7~1.2, size 8~16, spin ±0.3*60 = ±18°/s
#  - sparkle: 0.5 확률, pos = trail_pos, vel (±0.6, ±0.6 - 0.2) * 60, lifetime 0.6~1.1, size 1.5~3.0
#  - smoke: pos = trail_pos + ±8, vel (±0.25, -0.1~-0.4)*60, lifetime 0.9~1.5, size 14~30
func _spawn_trail(pos: Vector2) -> void:
	if not _trail_made:
		_trail_made = true
		# heart trail — 매 프레임 1개 spawn. 60/s * lifetime 0.95 ≈ 57 동시.
		_gpu_trail_heart = _Helpers.make_emitter({
			"count": int(57 * _scale()), "lifetime": 0.95, "color": COL_MID,
			"speed_min": 24.0, "speed_max": 78.0,  # ±0.4~0.8 * 60 magnitude
			"direction": Vector2.UP, "spread": 25.0,
			"gravity": 0.0, "damping": 3.0,
			"size_min": 8.0, "size_max": 16.0,
			"size_base": 32.0,  # heart_unit size 32 매핑 (원본 _heart_polygon(s = size/32))  # heart_tex 단위 반경
			"angle_min": -180.0, "angle_max": 180.0,
			"angular_velocity_min": -18.0, "angular_velocity_max": 18.0,
			"texture": _Helpers.heart_tex(),
			"additive": false,
			"emission_shape": "box", "emission_box": Vector2(10.0, 10.0),
			"one_shot": false, "explosiveness": 0.0,
			"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
		})
		add_child(_gpu_trail_heart)
		# sparkle trail — 0.5 확률 × 60 = 30/s × lifetime 0.85 ≈ 26 동시
		_gpu_trail_sparkle = _Helpers.make_emitter({
			"count": int(26 * _scale()), "lifetime": 0.85, "color": COL_HOT,
			"speed_min": 36.0, "speed_max": 72.0,
			"direction": Vector2.UP, "spread": 180.0,
			"gravity": 12.0, "damping": 3.0,
			"size_min": 1.5, "size_max": 3.0,
			"size_base": 4.0,
			"texture": _Helpers.sparkle_tex(),
			"one_shot": false, "explosiveness": 0.0,
			"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
		})
		add_child(_gpu_trail_sparkle)
		# smoke trail — 60/s × lifetime 1.2 ≈ 72 동시
		_gpu_trail_smoke = _Helpers.make_emitter({
			"count": int(72 * _scale()), "lifetime": 1.2, "color": COL_SMOKE,
			"speed_min": 6.0, "speed_max": 24.0,
			"direction": Vector2.UP, "spread": 25.0,
			"gravity": 0.0, "damping": 3.0,
			"size_min": 14.0, "size_max": 30.0,
			"additive": false,
			"emission_shape": "box", "emission_box": Vector2(8.0, 8.0),
			"one_shot": false, "explosiveness": 0.0,
			"start_alpha": 0.35, "mid_alpha": 0.17, "end_alpha": 0.0,
		})
		_gpu_trail_smoke.z_index = -1
		add_child(_gpu_trail_smoke)
	if is_instance_valid(_gpu_trail_heart):
		_gpu_trail_heart.position = pos
		_gpu_trail_sparkle.position = pos
		_gpu_trail_smoke.position = pos

# ── 명중 폭발 ──
# 원본 _spawn_impact_burst:
#  - heart 26: vel (cos*sp, sin*sp*0.85 - 1.0), sp 1.5~6.0 → speed 90~360 + y bias -60
#    lifetime 1.4~2.2, size 14~30, grav -0.012 (up gentle), tint violet 30% / rose 70%
#  - petal 40: vel (cos*sp, sin*sp*0.7 - 0.6), sp 1.0~4.0 → speed 60~240 + y bias -36
#    lifetime 1.6~2.5, size 6~13, grav 0.02 (down), spin ±3 rad/s = ±172°/s
#  - sparkle 60: vel (cos*sp, sin*sp - 0.5), sp 1.0~6.0 → speed 60~360 + y bias -30
#    lifetime 1.0~1.7, size 1.0~2.4, grav 0.01 (down small)
#  - smoke 22: vel (cos*sp, sin*sp*0.6 - 0.4), sp 0.6~2.2 → speed 36~132 + y bias -24
#    lifetime 1.4~2.3, size 24~46, grav -0.005 (up gentle)
func _spawn_impact_burst(pos: Vector2) -> void:
	if _impact_made:
		return
	_impact_made = true
	# trail off
	if is_instance_valid(_gpu_trail_heart): _gpu_trail_heart.emitting = false
	if is_instance_valid(_gpu_trail_sparkle): _gpu_trail_sparkle.emitting = false
	if is_instance_valid(_gpu_trail_smoke): _gpu_trail_smoke.emitting = false
	# heart 26 — rose 70% + violet 30%
	var heart_rose := _Helpers.make_emitter({
		"count": _pcount(18), "lifetime": 1.8, "color": COL_MID,
		"speed_min": 90.0, "speed_max": 360.0,
		"direction": Vector2.UP, "spread": 180.0,
		"gravity": -43.2, "damping": 3.0,  # 0.012 * 60²
		"size_min": 14.0, "size_max": 30.0,
		"size_base": 32.0,  # heart_unit size 32 매핑 (원본 _heart_polygon(s = size/32))
		"angle_min": -180.0, "angle_max": 180.0,
		"angular_velocity_min": -24.0, "angular_velocity_max": 24.0,
		"texture": _Helpers.heart_tex(),
		"additive": false,
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	heart_rose.position = pos
	add_child(heart_rose)
	# 원본: heart 솔리드는 tint 무관 항상 COL_MID. violet 은 가산 헤일로만 영향.
	# 두번째 heart emitter — 같은 COL_MID 솔리드 (violet 분량 8개를 다른 spawn 으로).
	var heart_violet := _Helpers.make_emitter({
		"count": _pcount(8), "lifetime": 1.8, "color": COL_MID,
		"speed_min": 90.0, "speed_max": 360.0,
		"direction": Vector2.UP, "spread": 180.0,
		"gravity": -43.2, "damping": 3.0,
		"size_min": 14.0, "size_max": 30.0,
		"size_base": 32.0,
		"angle_min": -180.0, "angle_max": 180.0,
		"angular_velocity_min": -24.0, "angular_velocity_max": 24.0,
		"texture": _Helpers.heart_tex(),
		"additive": false,
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	heart_violet.position = pos
	add_child(heart_violet)
	# violet 헤일로 가산 (원본 _draw_glow_pass 의 _tint_color(tint) alpha 0.11)
	# size*1.4 (원본), 8개 (violet tint 분량)
	var halo_violet := _Helpers.make_emitter({
		"count": _pcount(8), "lifetime": 1.8, "color": COL_VIOLET,
		"speed_min": 90.0, "speed_max": 360.0,
		"direction": Vector2.UP, "spread": 180.0,
		"gravity": -43.2, "damping": 3.0,
		"size_min": 14.0 * 1.4, "size_max": 30.0 * 1.4,
		"angle_min": -180.0, "angle_max": 180.0,
		"angular_velocity_min": -24.0, "angular_velocity_max": 24.0,
		"texture": _Helpers.circle_tex(),
		"start_alpha": 0.11, "mid_alpha": 0.055, "end_alpha": 0.0,
	})
	halo_violet.position = pos
	add_child(halo_violet)
	# petal 40 — circle_tex (작은 원형 폴리곤), 회전. COL_MID 핑크.
	var petal := _Helpers.make_emitter({
		"count": _pcount(40), "lifetime": 2.05, "color": COL_MID,
		"speed_min": 60.0, "speed_max": 240.0,
		"direction": Vector2.UP, "spread": 180.0,
		"gravity": 72.0, "damping": 3.0,
		"size_min": 6.0, "size_max": 13.0,
		"angle_min": -180.0, "angle_max": 180.0,
		"angular_velocity_min": -172.0, "angular_velocity_max": 172.0,
		"additive": false,
		"start_alpha": 0.85, "mid_alpha": 0.42, "end_alpha": 0.0,
	})
	petal.position = pos
	add_child(petal)
	# sparkle 60 — 흰 코어
	var sparkle := _Helpers.make_emitter({
		"count": _pcount(60), "lifetime": 1.35, "color": COL_HOT,
		"speed_min": 60.0, "speed_max": 360.0,
		"direction": Vector2.UP, "spread": 180.0,
		"gravity": 36.0, "damping": 3.0,
		"size_min": 1.0, "size_max": 2.4,
		"size_base": 4.0,
		"texture": _Helpers.sparkle_tex(),
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	sparkle.position = pos
	add_child(sparkle)
	# smoke 22 — 분홍 연기
	var smoke := _Helpers.make_emitter({
		"count": _pcount(22), "lifetime": 1.85, "color": COL_SMOKE,
		"speed_min": 36.0, "speed_max": 132.0,
		"direction": Vector2.UP, "spread": 180.0,
		"gravity": -18.0, "damping": 3.0,
		"size_min": 24.0, "size_max": 46.0,
		"additive": false,
		"start_alpha": 0.35, "mid_alpha": 0.17, "end_alpha": 0.0,
	})
	smoke.position = pos
	smoke.z_index = -1
	add_child(smoke)

# ── 잔류 ──
# 원본 _spawn_ambient (CHARM_TIME 동안 매 프레임):
#  - heart: 0.6 확률 × 60 = 36/s × lifetime 2.05 ≈ 74 동시.
#    pos = target + (±45, 10~30), vel (±0.3, -0.5~-1.2)*60, size 8~18, tint violet 25% rose 75%
#  - sparkle: 0.4 확률 × 60 = 24/s × lifetime 1.85 ≈ 44 동시.
#    pos = target + (±50, ±15), vel (±0.4, -0.4~-0.9)*60, size 1.2~2.4
func _spawn_ambient() -> void:
	if _amb_made:
		return
	_amb_made = true
	# heart rose 55 + violet 19
	_gpu_amb_heart_rose = _Helpers.make_emitter({
		"count": int(55 * _scale()), "lifetime": 2.05, "color": COL_MID,
		"speed_min": 30.0, "speed_max": 72.0,
		"direction": Vector2.UP, "spread": 25.0,
		"gravity": 0.0, "damping": 3.0,
		"size_min": 8.0, "size_max": 18.0,
		"size_base": 32.0,  # heart_unit size 32 매핑 (원본 _heart_polygon(s = size/32))
		"angle_min": -180.0, "angle_max": 180.0,
		"angular_velocity_min": -15.0, "angular_velocity_max": 15.0,
		"texture": _Helpers.heart_tex(),
		"additive": false,
		"emission_shape": "box", "emission_box": Vector2(45.0, 10.0),
		"one_shot": false, "explosiveness": 0.0,
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	_gpu_amb_heart_rose.position = _target + Vector2(0.0, 20.0)
	add_child(_gpu_amb_heart_rose)
	# violet ambient heart 도 솔리드는 COL_MID (원본).
	_gpu_amb_heart_violet = _Helpers.make_emitter({
		"count": int(19 * _scale()), "lifetime": 2.05, "color": COL_MID,
		"speed_min": 30.0, "speed_max": 72.0,
		"direction": Vector2.UP, "spread": 25.0,
		"gravity": 0.0, "damping": 3.0,
		"size_min": 8.0, "size_max": 18.0,
		"size_base": 32.0,
		"angle_min": -180.0, "angle_max": 180.0,
		"angular_velocity_min": -15.0, "angular_velocity_max": 15.0,
		"texture": _Helpers.heart_tex(),
		"additive": false,
		"emission_shape": "box", "emission_box": Vector2(45.0, 10.0),
		"one_shot": false, "explosiveness": 0.0,
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	_gpu_amb_heart_violet.position = _target + Vector2(0.0, 20.0)
	add_child(_gpu_amb_heart_violet)
	# sparkle 44
	_gpu_amb_sparkle = _Helpers.make_emitter({
		"count": int(44 * _scale()), "lifetime": 1.85, "color": COL_HOT,
		"speed_min": 24.0, "speed_max": 54.0,
		"direction": Vector2.UP, "spread": 35.0,
		"gravity": 0.0, "damping": 3.0,
		"size_min": 1.2, "size_max": 2.4,
		"size_base": 4.0,
		"texture": _Helpers.sparkle_tex(),
		"emission_shape": "box", "emission_box": Vector2(50.0, 15.0),
		"one_shot": false, "explosiveness": 0.0,
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	_gpu_amb_sparkle.position = _target
	add_child(_gpu_amb_sparkle)
	get_tree().create_timer(CHARM_TIME).timeout.connect(func() -> void:
		if is_instance_valid(_gpu_amb_heart_rose): _gpu_amb_heart_rose.emitting = false
		if is_instance_valid(_gpu_amb_heart_violet): _gpu_amb_heart_violet.emitting = false
		if is_instance_valid(_gpu_amb_sparkle): _gpu_amb_sparkle.emitting = false)
