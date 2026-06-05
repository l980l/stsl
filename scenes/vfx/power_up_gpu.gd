# scenes/vfx/power_up_gpu.gd
# 파워업 GPU 하이브리드 — power_up.gd 상속.
# 원본 _draw 매칭:
#   - mote: glow(add) 코어+헤일로 (pr*1.8 alpha 0.45), alpha=(1-k)×ga
#   - dust: ground(add) COL_DUST alpha (1-k)×0.4, 크기 1→2.3배 확장
# inflow: 외곽→caster homing. GPU sphere emission + radial_accel 음수 강력.
# aura / streaks / peak_shock 폴리곤 → CPU 유지.
extends "res://scenes/vfx/power_up.gd"

const _Helpers = preload("res://scenes/vfx/gpu_particle_helpers.gd")

const _COL_WARM_HOT  := Color(1.0, 0.823, 0.549)   # _mote_color warm
const _COL_CYAN_HOT  := Color(0.588, 0.921, 1.0)   # _mote_color cyan
const _COL_WHITE_HOT := Color(1.0, 1.0, 1.0)

var _peak_made: bool = false
var _gpu_inflow_warm: GPUParticles2D
var _gpu_inflow_cyan: GPUParticles2D
var _gpu_inflow_white: GPUParticles2D
var _gpu_charge_dust: GPUParticles2D
var _inflow_made: bool = false

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

func _make_inflow(col: Color, count: int) -> GPUParticles2D:
	return _Helpers.make_emitter({
		"count": count, "lifetime": 0.7, "color": col,
		"speed_min": 0.0, "speed_max": 0.0,
		"emission_shape": "sphere", "emission_radius": 300.0,
		"radial_accel_min": -1500.0, "radial_accel_max": -900.0,  # caster 로 빠른 끌림
		"size_min": 1.2, "size_max": 2.6,
		"size_base": 16.0,
		"texture": _Helpers.mote_halo_tex(),
		"one_shot": false, "explosiveness": 0.0,
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})

func _spawn_inflow(_n: int) -> void:
	if not _inflow_made:
		_inflow_made = true
		# intensity 평균 4/frame × 60 = 240/s × lifetime 1.15 = 276 동시.
		# warm 15% / cyan 50% / white 35%
		_gpu_inflow_warm = _make_inflow(_COL_WARM_HOT, int(41 * _scale()))
		_gpu_inflow_cyan = _make_inflow(_COL_CYAN_HOT, int(138 * _scale()))
		_gpu_inflow_white = _make_inflow(_COL_WHITE_HOT, int(97 * _scale()))
		_gpu_inflow_warm.position = _caster
		_gpu_inflow_cyan.position = _caster
		_gpu_inflow_white.position = _caster
		add_child(_gpu_inflow_warm)
		add_child(_gpu_inflow_cyan)
		add_child(_gpu_inflow_white)
		# charge 끝나면 inflow 정지
		get_tree().create_timer(CHARGE_TIME).timeout.connect(func() -> void:
			if is_instance_valid(_gpu_inflow_warm): _gpu_inflow_warm.emitting = false
			if is_instance_valid(_gpu_inflow_cyan): _gpu_inflow_cyan.emitting = false
			if is_instance_valid(_gpu_inflow_white): _gpu_inflow_white.emitting = false)

func _spawn_dust(_n: int) -> void:
	# charge phase 의 dust — continuous lazy.
	# super 의 _spawn_dust 는 _spawn_inflow 호출 후 0.7 확률로. 평균 0.7×60×1.5 = 63 동시.
	if not is_instance_valid(_gpu_charge_dust):
		var foot: Vector2 = _foot_pos()
		_gpu_charge_dust = _Helpers.make_emitter({
			"count": int(63 * _scale()), "lifetime": 1.5, "color": COL_DUST,
			"speed_min": 30.0, "speed_max": 66.0,  # vel 0.5~1.1 × PSPEED
			"direction": Vector2.UP, "spread": 20.0,
			"gravity": -18.0, "damping": 0.0,
			"size_min": 12.0, "size_max": 26.0,
			"scale_curve": _dust_scale_curve(),
			"emission_shape": "box", "emission_box": Vector2(90.0, 4.0),
			"one_shot": false, "explosiveness": 0.0,
			"start_alpha": 0.4, "mid_alpha": 0.2, "end_alpha": 0.0,
		})
		_gpu_charge_dust.position = foot + Vector2(0.0, -4.0)
		add_child(_gpu_charge_dust)
		get_tree().create_timer(CHARGE_TIME).timeout.connect(func() -> void:
			if is_instance_valid(_gpu_charge_dust): _gpu_charge_dust.emitting = false)

# peak burst: mote 40 (warm 12 + cyan 28) caster 외곽 + dust 16 (foot ring)
func _spawn_peak_burst() -> void:
	if _peak_made:
		return
	_peak_made = true
	var mote_warm := _Helpers.make_emitter({
		"count": _pcount(12), "lifetime": 1.5, "color": _COL_WARM_HOT,
		"speed_min": 180.0, "speed_max": 480.0,  # sp 3~8 × PSPEED 60
		"direction": Vector2.UP, "spread": 180.0,
		"gravity": 72.0, "damping": 0.0,
		"size_min": 1.4, "size_max": 2.8,
		"size_base": 16.0,
		"texture": _Helpers.mote_halo_tex(),
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	mote_warm.position = _caster
	add_child(mote_warm)
	var mote_cyan := _Helpers.make_emitter({
		"count": _pcount(28), "lifetime": 1.5, "color": _COL_CYAN_HOT,
		"speed_min": 180.0, "speed_max": 480.0,
		"direction": Vector2.UP, "spread": 180.0,
		"gravity": 72.0, "damping": 0.0,
		"size_min": 1.4, "size_max": 2.8,
		"size_base": 16.0,
		"texture": _Helpers.mote_halo_tex(),
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	mote_cyan.position = _caster
	add_child(mote_cyan)
	# dust 16 (foot ring)
	var foot: Vector2 = _foot_pos()
	var dust := _Helpers.make_emitter({
		"count": _pcount(16), "lifetime": 1.5, "color": COL_DUST,
		"speed_min": 120.0, "speed_max": 300.0,  # sp 2~5 × PSPEED
		"direction": Vector2.UP, "spread": 130.0,
		"gravity": -18.0, "damping": 0.0,
		"size_min": 18.0, "size_max": 32.0,
		"scale_curve": _dust_scale_curve(),
		"start_alpha": 0.4, "mid_alpha": 0.2, "end_alpha": 0.0,
	})
	dust.position = foot
	add_child(dust)
