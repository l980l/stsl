# scenes/vfx/mimic_gpu.gd
# 미믹 GPU 하이브리드 — mimic.gd 상속.
# 원본 _draw_glow_pass spark: glow_layer(additive=true) 코어+헤일로+가로막대, alpha=(1-k)×ga
# peak burst spark 28(caster) + 14(target) GPU. arc motes (위치 동적) CPU 유지.
extends "res://scenes/vfx/mimic.gd"

const _Helpers = preload("res://scenes/vfx/gpu_particle_helpers.gd")

var _peak_made: bool = false

func _process(delta: float) -> void:
	super._process(delta)
	var ga: float = _global_alpha()
	for child in get_children():
		if child is GPUParticles2D:
			child.modulate.a = ga

func _spawn_peak_burst() -> void:
	if _peak_made:
		return
	_peak_made = true
	# caster burst: brass 17 + echo 11 (28×60%/40%)
	var brass := _Helpers.make_emitter({
		"count": _pcount(17), "lifetime": 1.3, "color": COL_BRASS,
		"speed_min": 120.0, "speed_max": 360.0,  # sp 2~6 × PSPEED 60
		"direction": Vector2.UP, "spread": 180.0,
		"gravity": 54.0, "damping": 0.0,
		"size_min": 1.4, "size_max": 2.8,
		"size_base": 16.0,
		"texture": _Helpers.mote_halo_tex(),
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	brass.position = _caster
	add_child(brass)
	var echo_c := _Helpers.make_emitter({
		"count": _pcount(11), "lifetime": 1.3, "color": COL_ECHO_HOT,
		"speed_min": 120.0, "speed_max": 360.0,
		"direction": Vector2.UP, "spread": 180.0,
		"gravity": 54.0, "damping": 0.0,
		"size_min": 1.4, "size_max": 2.8,
		"size_base": 16.0,
		"texture": _Helpers.mote_halo_tex(),
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	echo_c.position = _caster
	add_child(echo_c)
	# target: echo 14 (전부 echo)
	var echo_t := _Helpers.make_emitter({
		"count": _pcount(14), "lifetime": 1.1, "color": COL_ECHO_HOT,
		"speed_min": 90.0, "speed_max": 240.0,  # sp 1.5~4 × PSPEED
		"direction": Vector2.UP, "spread": 180.0,
		"gravity": 18.0, "damping": 0.0,
		"size_min": 1.2, "size_max": 2.4,
		"size_base": 16.0,
		"texture": _Helpers.mote_halo_tex(),
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	echo_t.position = _target
	add_child(echo_t)
