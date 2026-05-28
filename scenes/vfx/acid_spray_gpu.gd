# scenes/vfx/acid_spray_gpu.gd
# 산성 분무 VFX — 3-mouth 콘 분사 (1.0s sustained) + 지면 산성 풀 + 타겟 화상.
# HTML 매핑 (ui_sample/vfx/Acid Spray VFX.html):
#   WINDUP 0.4s  — 머리 부근 drool 응축 (작은 acid drop emission, down)
#   SPRAY  1.0s  — 3 mouth → target 방향 cone sustained, 매 0.1s splatter+foam at target
#   AFTERMATH 2.4s — 발치 산성 풀 (sizzle bubbles) + 타겟 몸 위 산성 화상 drip
# screen_effect: SPRAY 시작 시점 (피해 적용 = impact).
extends Node2D

const _Helpers = preload("res://scenes/vfx/gpu_particle_helpers.gd")

signal screen_effect

# 색 — HTML CSS var 매핑
const COL_HOT  := Color(0.957, 1.000, 0.478)   # #f4ff7a — acid 하이라이트
const COL_MID  := Color(0.784, 0.902, 0.290)   # #c8e64a — acid 본체
const COL_DEEP := Color(0.353, 0.510, 0.078)   # #5a8214 — acid 잔재
const COL_FOAM := Color(1.000, 0.988, 0.878)   # #fffce0 — foam 흰

const CHARGE_TIME  := 0.4   # WINDUP
const SPRAY_TIME   := 1.0   # SUSTAINED SPRAY
const POOL_TIME    := 2.4   # AFTERMATH
const IMPACT_DELAY := CHARGE_TIME   # spray 시작 = 피해 적용 시점

# SFX — battle_scene._spawn_attack_beam_simple 이 자동 호출 (LAUNCH=play() 직후, IMPACT=screen_effect)
const SFX_LAUNCH := "acid_spray_cry"
const SFX_IMPACT := "acid_spray_splat"

# 3개 mouth — caster sprite center 기준 (위쪽)
const MOUTH_OFFSETS := [
	Vector2(-26.0, -60.0),
	Vector2(  0.0, -78.0),
	Vector2( 26.0, -60.0),
]

var _caster := Vector2.ZERO
var _target := Vector2.ZERO
var _particle_scale_override: float = -1.0
var _spray_emitters: Array[GPUParticles2D] = []
var _splatter_timer: Timer
var _splat_tick: int = 0

func _pcount(n: int) -> int:
	if _particle_scale_override > 0.0:
		return maxi(1, int(round(n * _particle_scale_override)))
	var gs := get_node_or_null("/root/GameSettings")
	return n if gs == null else maxi(1, int(round(n * gs.particle_count_scale())))

func _scale() -> float:
	if _particle_scale_override > 0.0:
		return _particle_scale_override
	var gs := get_node_or_null("/root/GameSettings")
	return 1.0 if gs == null else gs.particle_count_scale()

func play(caster: Vector2, target: Vector2) -> void:
	_caster = caster
	_target = target
	_spawn_drool()
	get_tree().create_timer(CHARGE_TIME).timeout.connect(_start_spray)

# ── WINDUP — drool 응축 ──
# 각 mouth 에서 작은 acid drop 이 아래로 흐르며 응축. 0.4s 지속.
func _spawn_drool() -> void:
	for off in MOUTH_OFFSETS:
		var d := _Helpers.make_emitter({
			"count": _pcount(6), "lifetime": 0.4, "color": COL_MID,
			"speed_min": 8.0, "speed_max": 28.0,
			"direction": Vector2.DOWN, "spread": 12.0,
			"gravity": 280.0, "damping": 1.5,
			"size_min": 2.0, "size_max": 4.5,
			"additive": true,
			"one_shot": false, "explosiveness": 0.0,
			"start_alpha": 0.9, "mid_alpha": 0.6, "end_alpha": 0.0,
		})
		d.position = _caster + off
		add_child(d)
		var drool := d
		get_tree().create_timer(CHARGE_TIME).timeout.connect(func() -> void:
			if is_instance_valid(drool):
				drool.emitting = false)

# ── SPRAY — 3 mouth 콘 분사 + 매 0.1s splatter ──
func _start_spray() -> void:
	emit_signal("screen_effect")
	for off in MOUTH_OFFSETS:
		var mouth: Vector2 = _caster + off
		var dir: Vector2 = (_target - mouth).normalized()
		# 메인 acid streak — 가산 (빛나는 잔류)
		var spray := _Helpers.make_emitter({
			"count": _pcount(120), "lifetime": 0.55, "color": COL_HOT,
			"speed_min": 320.0, "speed_max": 620.0,
			"direction": dir, "spread": 25.0,
			"gravity": 480.0, "damping": 0.8,
			"size_min": 2.2, "size_max": 5.5,
			"additive": true,
			"one_shot": false, "explosiveness": 0.0,
			"lifetime_randomness": 0.5,
			"start_alpha": 0.95, "mid_alpha": 0.55, "end_alpha": 0.0,
		})
		spray.position = mouth
		add_child(spray)
		_spray_emitters.append(spray)
		# 콘 두께감 — 일반 블렌드 mid 색 흐름
		var body := _Helpers.make_emitter({
			"count": _pcount(60), "lifetime": 0.7, "color": COL_MID,
			"speed_min": 220.0, "speed_max": 460.0,
			"direction": dir, "spread": 28.0,
			"gravity": 360.0, "damping": 1.0,
			"size_min": 4.0, "size_max": 9.0,
			"additive": false,
			"one_shot": false, "explosiveness": 0.0,
			"lifetime_randomness": 0.55,
			"start_alpha": 0.55, "mid_alpha": 0.3, "end_alpha": 0.0,
		})
		body.position = mouth
		add_child(body)
		_spray_emitters.append(body)
	# splatter — target 부근에서 매 0.1s 작은 burst (튐 + foam)
	_splatter_timer = Timer.new()
	_splatter_timer.wait_time = 0.1
	_splatter_timer.one_shot = false
	_splatter_timer.autostart = true
	add_child(_splatter_timer)
	_splatter_timer.timeout.connect(_spawn_splatter_tick)
	get_tree().create_timer(SPRAY_TIME).timeout.connect(_end_spray)

func _spawn_splatter_tick() -> void:
	# 매 3 tick (0.3s) 마다 추가 splat sfx. tick 1 은 battle_scene 의 SFX_IMPACT 와 겹치니 skip — rate_limit 50ms.
	_splat_tick += 1
	if _splat_tick > 1 and _splat_tick % 3 == 1:
		var am := get_node_or_null("/root/AudioManager")
		if am != null:
			am.play_sfx("acid_spray_splat")
	# secondary 튐 (작은 입자 사방으로) — 일반 블렌드
	var splatter := _Helpers.make_emitter({
		"count": _pcount(8), "lifetime": 0.55, "color": COL_MID,
		"speed_min": 80.0, "speed_max": 220.0,
		"direction": Vector2.UP, "spread": 180.0,
		"gravity": 360.0, "damping": 1.0,
		"size_min": 1.5, "size_max": 3.5,
		"additive": false,
		"emission_shape": "box", "emission_box": Vector2(30.0, 40.0),
		"start_alpha": 0.95, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	splatter.position = _target
	add_child(splatter)
	# foam puff — 위로 천천히 (가산)
	var foam := _Helpers.make_emitter({
		"count": _pcount(5), "lifetime": 0.9, "color": COL_FOAM,
		"speed_min": 20.0, "speed_max": 60.0,
		"direction": Vector2.UP, "spread": 40.0,
		"gravity": -40.0, "damping": 1.0,
		"size_min": 8.0, "size_max": 16.0,
		"additive": true,
		"emission_shape": "box", "emission_box": Vector2(40.0, 50.0),
		"start_alpha": 0.5, "mid_alpha": 0.25, "end_alpha": 0.0,
	})
	foam.position = _target
	add_child(foam)

# ── AFTERMATH — 발치 풀 + 타겟 화상 ──
func _end_spray() -> void:
	for e in _spray_emitters:
		if is_instance_valid(e):
			e.emitting = false
	if is_instance_valid(_splatter_timer):
		_splatter_timer.stop()
		_splatter_timer.queue_free()
	_spawn_pool()
	_spawn_burns()
	get_tree().create_timer(POOL_TIME + 0.5).timeout.connect(queue_free)

func _spawn_pool() -> void:
	# 발치 산성 풀 — Sprite2D (큰 옅은 가산 타원) + sizzle bubbles emitter
	var ground: Vector2 = _target + Vector2(0.0, 90.0)
	var pool := Sprite2D.new()
	pool.texture = _Helpers.circle_tex()
	pool.position = ground
	pool.scale = Vector2(2.5, 0.65)
	pool.modulate = Color(COL_MID.r, COL_MID.g, COL_MID.b, 0.0)
	var pool_mat := CanvasItemMaterial.new()
	pool_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	pool.material = pool_mat
	add_child(pool)
	var tw := create_tween()
	tw.tween_property(pool, "modulate:a", 0.7, 0.2)
	tw.tween_interval(POOL_TIME * 0.55)
	tw.tween_property(pool, "modulate:a", 0.0, POOL_TIME * 0.4)
	tw.tween_callback(pool.queue_free)
	# 부글거리는 거품 — 위로 천천히 사라지는 작은 가산 bubble
	var sizzle := _Helpers.make_emitter({
		"count": _pcount(32), "lifetime": 1.2, "color": COL_HOT,
		"speed_min": 30.0, "speed_max": 80.0,
		"direction": Vector2.UP, "spread": 18.0,
		"gravity": 60.0, "damping": 1.5,
		"size_min": 1.5, "size_max": 3.5,
		"additive": true,
		"emission_shape": "box", "emission_box": Vector2(80.0, 10.0),
		"one_shot": false, "explosiveness": 0.0,
		"start_alpha": 0.9, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	sizzle.position = ground
	add_child(sizzle)
	get_tree().create_timer(POOL_TIME * 0.85).timeout.connect(func() -> void:
		if is_instance_valid(sizzle): sizzle.emitting = false)

func _spawn_burns() -> void:
	# 타겟 몸 위 산성 드립 — drip 텍스처, 아래로 천천히
	var burns := _Helpers.make_emitter({
		"count": _pcount(18), "lifetime": 1.6, "color": COL_HOT,
		"speed_min": 8.0, "speed_max": 30.0,
		"direction": Vector2.DOWN, "spread": 10.0,
		"gravity": 90.0, "damping": 1.8,
		"size_min": 3.0, "size_max": 6.5,
		"size_base": 23.0,
		"texture": _Helpers.drip_tex(),
		"additive": false,
		"emission_shape": "box", "emission_box": Vector2(36.0, 50.0),
		"one_shot": false, "explosiveness": 0.0,
		"start_alpha": 1.0, "mid_alpha": 0.6, "end_alpha": 0.0,
	})
	burns.position = _target + Vector2(0.0, -10.0)
	add_child(burns)
	get_tree().create_timer(POOL_TIME * 0.85).timeout.connect(func() -> void:
		if is_instance_valid(burns): burns.emitting = false)
