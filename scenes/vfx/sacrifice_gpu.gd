# scenes/vfx/sacrifice_gpu.gd
# 희생 GPU 하이브리드 — sacrifice.gd 상속.
# 원본 _draw 매칭:
#   - drip: glow(add) blood 85% (alpha 0.95) + hot 15% (alpha 1.0). 세로 ellipse → 원형 근사.
#   - dust: ground(add) COL_BLOOD_DEEP alpha (1-k)×0.45, 크기 1→2.3배 확장.
#   - ember: glow(add) COL_BLOOD 코어 + 헤일로 (pr*1.6 alpha 0.45).
# spiral/column/sigil/aura/slash 폴리곤 → CPU 유지.
extends "res://scenes/vfx/sacrifice.gd"

const _Helpers = preload("res://scenes/vfx/gpu_particle_helpers.gd")

var _peak_made: bool = false
var _gpu_hold_ember: GPUParticles2D
var _hold_made: bool = false

func _process(delta: float) -> void:
	super._process(delta)
	var ga: float = _global_alpha()
	for child in get_children():
		if child is GPUParticles2D:
			child.modulate.a = ga

static func _dust_scale_curve() -> Curve:
	var c := Curve.new()
	c.add_point(Vector2(0.0, 1.0))
	c.add_point(Vector2(1.0, 2.3))
	return c

func _spawn_peak_burst() -> void:
	if _peak_made:
		return
	_peak_made = true
	# drip 28 (blood 24 + hot 4) — sp 3~8 × PSPEED 60, gravity 0.06 × PSPEED² = 216
	var drip_blood := _Helpers.make_emitter({
		"count": _pcount(24), "lifetime": 1.3, "color": COL_BLOOD,
		"speed_min": 180.0, "speed_max": 480.0,
		"direction": Vector2.UP, "spread": 90.0,  # 위 절반 (PI - PI/2 매칭)
		"gravity": 216.0, "damping": 0.0,
		"size_min": 1.5, "size_max": 3.1,
		"start_alpha": 0.95, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	drip_blood.position = _target + Vector2(0.0, -30.0)
	add_child(drip_blood)
	var drip_hot := _Helpers.make_emitter({
		"count": _pcount(4), "lifetime": 1.3, "color": COL_HOT,
		"speed_min": 180.0, "speed_max": 480.0,
		"direction": Vector2.UP, "spread": 90.0,
		"gravity": 216.0, "damping": 0.0,
		"size_min": 1.5, "size_max": 3.1,
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	drip_hot.position = _target + Vector2(0.0, -30.0)
	add_child(drip_hot)
	# dust 12 (발치 검붉은, ground add)
	var foot: Vector2 = _foot_pos()
	var dust := _Helpers.make_emitter({
		"count": _pcount(12), "lifetime": 1.5, "color": COL_BLOOD_DEEP,
		"speed_min": 90.0, "speed_max": 240.0,
		"direction": Vector2.UP, "spread": 130.0,
		"gravity": -18.0, "damping": 0.0,
		"size_min": 14.0, "size_max": 26.0,
		"scale_curve": _dust_scale_curve(),
		"start_alpha": 0.45, "mid_alpha": 0.2, "end_alpha": 0.0,
	})
	dust.position = foot
	add_child(dust)

func _spawn_hold_ember() -> void:
	if _hold_made:
		return
	_hold_made = true
	var foot: Vector2 = _foot_pos()
	# 0.45/frame × 60 × lifetime 1.25 ≈ 34 동시. COL_BLOOD.
	_gpu_hold_ember = _Helpers.make_emitter({
		"count": int(34 * _scale()), "lifetime": 1.25, "color": COL_BLOOD,
		"speed_min": 36.0, "speed_max": 66.0,  # vel 0.6~1.1 × PSPEED
		"direction": Vector2.UP, "spread": 18.0,
		"gravity": 0.0, "damping": 0.0,
		"size_min": 1.0, "size_max": 2.0,
		"size_base": 16.0,
		"texture": _Helpers.mote_halo_tex(),
		"emission_shape": "box", "emission_box": Vector2(80.0, 15.0),
		"one_shot": false, "explosiveness": 0.0,
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	_gpu_hold_ember.position = foot + Vector2(0.0, -15.0)
	add_child(_gpu_hold_ember)
	get_tree().create_timer(HOLD_TIME).timeout.connect(func() -> void:
		if is_instance_valid(_gpu_hold_ember): _gpu_hold_ember.emitting = false)
