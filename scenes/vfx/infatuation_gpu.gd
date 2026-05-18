# scenes/vfx/infatuation_gpu.gd
# 반함 GPU 하이브리드 — infatuation.gd 정확 매핑.
# _spawn_impact_burst (heart_small 26 + petal 40 + sparkle 60 + smoke 22) → GPU
# _spawn_ambient (heart_small 0.5 + sparkle 0.3 확률) → GPU continuous
# trail (5 hearts 매 프레임 spawn) 은 super CPU 그대로 (각 hearts 위치 동기 복잡).
# 만다라/체인/오라/충격파/비행 hearts 폴리곤 → CPU.
extends "res://scenes/vfx/infatuation.gd"

const _Helpers = preload("res://scenes/vfx/gpu_particle_helpers.gd")

var _impact_made: bool = false

# ambient continuous emitters
var _gpu_amb_heart_rose: GPUParticles2D
var _gpu_amb_heart_crim: GPUParticles2D
var _gpu_amb_sparkle: GPUParticles2D
var _amb_made: bool = false

# trail emitters — 5 hearts 각각 heart + sparkle + halo emitter (총 15).
var _gpu_trail_emitters: Array[GPUParticles2D] = []      # heart_small × 5
var _gpu_trail_sparkles: Array[GPUParticles2D] = []      # sparkle × 5
var _gpu_trail_halos: Array[GPUParticles2D] = []         # halo × 5 (비행 hearts halo)
var _trail_setup: bool = false

func _setup_trail_emitters() -> void:
	if _trail_setup:
		return
	_trail_setup = true
	# heart tint: fan i%2==1 crimson, big rose. → 0,2,4 rose / 1,3 crimson.
	var colors := [COL_RED, COL_CRIMSON, COL_RED, COL_CRIMSON, COL_RED]
	# sparkle 색 (tint 별 — _draw_glow_pass 의 sparkle 색 매핑)
	var sparkle_colors := [
		Color(1.0, 0.835, 0.835),  # rose
		Color(1.0, 0.620, 0.620),  # crimson
		Color(1.0, 0.835, 0.835),
		Color(1.0, 0.620, 0.620),
		Color(1.0, 0.835, 0.835),
	]
	for i in 5:
		# heart_small: 2/frame × 60 × lifetime 0.95 ≈ 114 동시 per heart (사용자 요청 2배).
		var em := _Helpers.make_emitter({
			"count": int(114 * _scale()), "lifetime": 0.95,
			"color": colors[i],
			"speed_min": 24.0, "speed_max": 48.0,
			"direction": Vector2.UP, "spread": 25.0,
			"gravity": 0.0, "damping": 3.0,
			"size_min": 5.0, "size_max": 9.0,
			"size_base": 32.0,
			"emission_shape": "box", "emission_box": Vector2(4.0, 4.0),
			"texture": _Helpers.heart_tex(),
			"additive": false,
			"one_shot": false, "explosiveness": 0.0,
			"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
		})
		em.emitting = false
		add_child(em)
		_gpu_trail_emitters.append(em)
		# sparkle: 0.4 확률 × 60 = 24/s × lifetime 0.85 ≈ 20 동시 per heart.
		# vel (±1, ±1-0.2)*60 → speed magnitude 0~84 + y bias -12. spread 180.
		var sp := _Helpers.make_emitter({
			"count": int(20 * _scale()), "lifetime": 0.85,
			"color": sparkle_colors[i],
			"speed_min": 24.0, "speed_max": 84.0,
			"direction": Vector2.UP, "spread": 180.0,
			"gravity": -12.0, "damping": 3.0,
			"size_min": 1.2, "size_max": 2.2,
			"size_base": 4.0,
			"texture": _Helpers.sparkle_tex(),
			"one_shot": false, "explosiveness": 0.0,
			"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
		})
		sp.emitting = false
		add_child(sp)
		_gpu_trail_sparkles.append(sp)
		# halo — 비행 heart 의 큰+작은 halo (가산). size = heart size (fan 18~22, big 30).
		var heart_size: float = 30.0 if i == 4 else (18.0 + 2.0)  # big 30, fan 평균 20
		if i < _hearts.size():
			heart_size = _hearts[i]["size"]
		var halo := _Helpers.make_emitter({
			"count": 1, "lifetime": 0.2, "color": colors[i],  # 1 입자 항상 spawn
			"speed_min": 0.0, "speed_max": 0.0,
			"direction": Vector2.UP, "spread": 0.0,
			"gravity": 0.0, "damping": 0.0,
			"size_min": heart_size, "size_max": heart_size,
			"size_base": 22.86,  # 32 / 1.4 (halo_tex 안쪽 반경 매핑)
			"texture": _Helpers.halo_tex(),
			"one_shot": false, "explosiveness": 0.0,
			"start_alpha": 1.0, "mid_alpha": 1.0, "end_alpha": 1.0,  # halo 는 alpha 고정 (페이드 X — 텍스처 자체 alpha 사용)
		})
		halo.emitting = false
		add_child(halo)
		_gpu_trail_halos.append(halo)

# super 의 _spawn_trail override — heart_small + sparkle 모두 GPU. super CPU _particles 안 채움.
func _spawn_trail(_pos: Vector2, _tint: String) -> void:
	pass

func _process(delta: float) -> void:
	super._process(delta)
	_setup_trail_emitters()
	# _hearts (super) 순회 — 각 heart 의 emitter_idx 추적 후 position 동기.
	var active_indices: Array = []
	for h in _hearts:
		var idx: int = h.get("emitter_idx", -1)
		if idx < 0:
			# 처음 보는 heart — 남는 인덱스 부여
			for ei in 5:
				if not active_indices.has(ei):
					h["emitter_idx"] = ei
					idx = ei
					break
		if idx >= 0:
			active_indices.append(idx)
			var em: GPUParticles2D = _gpu_trail_emitters[idx]
			var sp: GPUParticles2D = _gpu_trail_sparkles[idx]
			var ha: GPUParticles2D = _gpu_trail_halos[idx]
			if h["delay"] > 0.0:
				em.emitting = false
				sp.emitting = false
				ha.emitting = false
			else:
				em.emitting = true
				em.position = h["pos"]
				sp.emitting = true
				sp.position = h["pos"]
				ha.emitting = true
				ha.position = h["pos"]
	# 비활성 emitter (현재 _hearts 에 없는) 끄기
	for i in 5:
		if not active_indices.has(i):
			_gpu_trail_emitters[i].emitting = false
			_gpu_trail_sparkles[i].emitting = false
			_gpu_trail_halos[i].emitting = false

# ── impact burst ──
# 원본:
#  - heart_small 26: vel (cos*sp, sin*sp*0.85 - 1.5), sp 2.5~9 → speed 150~540 + y bias -90
#    lifetime 1.4~2.2, r 14~30, grav -0.012 → -43.2 px/s² (up gentle), tint crimson 45% / rose 55%
#  - petal 40: vel (cos*sp, sin*sp*0.7 - 0.8), sp 1.5~5.5 → speed 90~330 + y bias -48
#    lifetime 1.6~2.6, r 6~13, grav 0.02 → 72, spin ±0.08 → ±4.8 rad/s = ±275°/s
#  - sparkle 60: vel (cos*sp, sin*sp - 0.5), sp 1.5~7.5 → speed 90~450 + y bias -30
#    lifetime 1.0~1.7, r 1.0~2.4, grav 0.01 → 36
#  - smoke 22: vel (cos*sp, sin*sp*0.6 - 0.4), sp 0.8~2.6 → speed 48~156 + y bias -24
#    lifetime 1.4~2.3, r 24~46, grav -0.005 → -18
func _spawn_impact_burst() -> void:
	if _impact_made:
		return
	_impact_made = true
	var b := _target + Vector2(0.0, -40.0)
	# heart rose (55% = 14)
	var heart_rose := _Helpers.make_emitter({
		"count": _pcount(14), "lifetime": 1.8, "color": COL_RED,
		"speed_min": 150.0, "speed_max": 540.0,
		"direction": Vector2.UP, "spread": 180.0,
		"gravity": -43.2, "damping": 3.0,
		"size_min": 14.0, "size_max": 30.0,
		"size_base": 32.0,
		"angle_min": -180.0, "angle_max": 180.0,
		"angular_velocity_min": -34.0, "angular_velocity_max": 34.0,
		"texture": _Helpers.heart_tex(),
		"additive": false,
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	heart_rose.position = b
	add_child(heart_rose)
	# heart crimson (45% = 12)
	var heart_crim := _Helpers.make_emitter({
		"count": _pcount(12), "lifetime": 1.8, "color": COL_CRIMSON,
		"speed_min": 150.0, "speed_max": 540.0,
		"direction": Vector2.UP, "spread": 180.0,
		"gravity": -43.2, "damping": 3.0,
		"size_min": 14.0, "size_max": 30.0,
		"size_base": 32.0,
		"angle_min": -180.0, "angle_max": 180.0,
		"angular_velocity_min": -34.0, "angular_velocity_max": 34.0,
		"texture": _Helpers.heart_tex(),
		"additive": false,
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	heart_crim.position = b
	add_child(heart_crim)
	# petal 40 — 핑크빨강 타원, 회전
	var petal := _Helpers.make_emitter({
		"count": _pcount(40), "lifetime": 2.1, "color": COL_PETAL,
		"speed_min": 90.0, "speed_max": 330.0,
		"direction": Vector2.UP, "spread": 180.0,
		"gravity": 72.0, "damping": 3.0,
		"size_min": 6.0, "size_max": 13.0,
		"size_base": 30.0,
		"angle_min": -180.0, "angle_max": 180.0,
		"angular_velocity_min": -275.0, "angular_velocity_max": 275.0,
		"texture": _Helpers.petal_tex(),
		"additive": false,
		"start_alpha": 0.92, "mid_alpha": 0.46, "end_alpha": 0.0,
	})
	petal.position = b
	add_child(petal)
	# sparkle 60 — 분홍빛 (rose 50% / crimson 50%)
	var sparkle_rose := _Helpers.make_emitter({
		"count": _pcount(30), "lifetime": 1.35, "color": Color(1.0, 0.835, 0.835),
		"speed_min": 90.0, "speed_max": 450.0,
		"direction": Vector2.UP, "spread": 180.0,
		"gravity": 36.0, "damping": 3.0,
		"size_min": 1.0, "size_max": 2.4,
		"size_base": 4.0,
		"texture": _Helpers.sparkle_tex(),
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	sparkle_rose.position = b
	add_child(sparkle_rose)
	var sparkle_crim := _Helpers.make_emitter({
		"count": _pcount(30), "lifetime": 1.35, "color": Color(1.0, 0.620, 0.620),
		"speed_min": 90.0, "speed_max": 450.0,
		"direction": Vector2.UP, "spread": 180.0,
		"gravity": 36.0, "damping": 3.0,
		"size_min": 1.0, "size_max": 2.4,
		"size_base": 4.0,
		"texture": _Helpers.sparkle_tex(),
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	sparkle_crim.position = b
	add_child(sparkle_crim)
	# smoke 22 — 핏빛 연기 (원본 Color(1.0, 0.420, 0.500))
	var smoke := _Helpers.make_emitter({
		"count": _pcount(22), "lifetime": 1.85, "color": Color(1.0, 0.420, 0.500),
		"speed_min": 48.0, "speed_max": 156.0,
		"direction": Vector2.UP, "spread": 180.0,
		"gravity": -18.0, "damping": 3.0,
		"size_min": 24.0, "size_max": 46.0,
		"additive": false,
		"start_alpha": 0.35, "mid_alpha": 0.17, "end_alpha": 0.0,
	})
	smoke.position = b
	smoke.z_index = -1
	add_child(smoke)

# ── ambient (BUFF_TIME 동안 매 프레임) ──
# 원본:
#  - heart_small 0.5 확률 × 60 = 30/s × lifetime 1.9 ≈ 57 동시.
#    pos = target + (0, -30) + (±50, -10~30), vel (±0.3, -0.5~-1.2)*60, lifetime 1.4~2.4, r 6~11.
#    tint crimson 40% / rose 60%.
#  - sparkle 0.3 확률 × 60 = 18/s × lifetime 1.7 ≈ 31 동시.
#    pos = target + (0, -30) + (±55, ±20), vel (±0.4, -0.3~-0.8)*60, lifetime 1.2~2.2, r 1~2.
func _spawn_ambient() -> void:
	if _amb_made:
		return
	_amb_made = true
	var ctr := _target + Vector2(0.0, -30.0)
	# heart_small rose (60% = 34)
	_gpu_amb_heart_rose = _Helpers.make_emitter({
		"count": int(34 * _scale()), "lifetime": 1.9, "color": COL_RED,
		"speed_min": 30.0, "speed_max": 78.0,
		"direction": Vector2.UP, "spread": 18.0,
		"gravity": 0.0, "damping": 3.0,
		"size_min": 6.0, "size_max": 11.0,
		"size_base": 32.0,
		"angle_min": -180.0, "angle_max": 180.0,
		"angular_velocity_min": -20.0, "angular_velocity_max": 20.0,
		"texture": _Helpers.heart_tex(),
		"additive": false,
		"emission_shape": "box", "emission_box": Vector2(50.0, 20.0),
		"one_shot": false, "explosiveness": 0.0,
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	_gpu_amb_heart_rose.position = ctr + Vector2(0.0, 10.0)
	add_child(_gpu_amb_heart_rose)
	# heart_small crimson (40% = 23)
	_gpu_amb_heart_crim = _Helpers.make_emitter({
		"count": int(23 * _scale()), "lifetime": 1.9, "color": COL_CRIMSON,
		"speed_min": 30.0, "speed_max": 78.0,
		"direction": Vector2.UP, "spread": 18.0,
		"gravity": 0.0, "damping": 3.0,
		"size_min": 6.0, "size_max": 11.0,
		"size_base": 32.0,
		"angle_min": -180.0, "angle_max": 180.0,
		"angular_velocity_min": -20.0, "angular_velocity_max": 20.0,
		"texture": _Helpers.heart_tex(),
		"additive": false,
		"emission_shape": "box", "emission_box": Vector2(50.0, 20.0),
		"one_shot": false, "explosiveness": 0.0,
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	_gpu_amb_heart_crim.position = ctr + Vector2(0.0, 10.0)
	add_child(_gpu_amb_heart_crim)
	# sparkle 31 동시 (분홍빛)
	_gpu_amb_sparkle = _Helpers.make_emitter({
		"count": int(31 * _scale()), "lifetime": 1.7, "color": Color(1.0, 0.835, 0.835),
		"speed_min": 24.0, "speed_max": 54.0,
		"direction": Vector2.UP, "spread": 25.0,
		"gravity": 0.0, "damping": 3.0,
		"size_min": 1.0, "size_max": 2.0,
		"size_base": 4.0,
		"texture": _Helpers.sparkle_tex(),
		"emission_shape": "box", "emission_box": Vector2(55.0, 20.0),
		"one_shot": false, "explosiveness": 0.0,
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	_gpu_amb_sparkle.position = ctr
	add_child(_gpu_amb_sparkle)
	get_tree().create_timer(BUFF_TIME).timeout.connect(func() -> void:
		if is_instance_valid(_gpu_amb_heart_rose): _gpu_amb_heart_rose.emitting = false
		if is_instance_valid(_gpu_amb_heart_crim): _gpu_amb_heart_crim.emitting = false
		if is_instance_valid(_gpu_amb_sparkle): _gpu_amb_sparkle.emitting = false)
