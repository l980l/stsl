# scenes/vfx/steal_card_gpu.gd
# 카드 훔치기 GPU 하이브리드 — steal_card.gd 상속.
# 원본 _draw_glow_pass spark: glow(add) 코어+헤일로+가로막대, alpha=(1-k)×ga, brass 70% + shadow 30%.
# mark / card flight / hook sigil 폴리곤 → CPU 유지.
extends "res://scenes/vfx/steal_card.gd"

const _Helpers = preload("res://scenes/vfx/gpu_particle_helpers.gd")

var _peak_made: bool = false

func _process(delta: float) -> void:
	super._process(delta)
	var ga: float = _global_alpha()
	for child in get_children():
		if child is GPUParticles2D:
			child.modulate.a = ga

func _spawn_catch_burst() -> void:
	if _peak_made:
		return
	_peak_made = true
	var ctr: Vector2 = _caster + Vector2(0.0, HEAD_Y_OFFSET)
	# brass 14 + shadow 6 (20×70%/30%). sp 2~6 × PSPEED 60 = 120~360.
	var brass := _Helpers.make_emitter({
		"count": _pcount(14), "lifetime": 1.1, "color": COL_BRASS,
		"speed_min": 120.0, "speed_max": 360.0,
		"direction": Vector2.UP, "spread": 180.0,
		"gravity": 54.0, "damping": 0.0,
		"size_min": 1.2, "size_max": 2.4,
		"size_base": 16.0,
		"texture": _Helpers.mote_halo_tex(),
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	brass.position = ctr
	add_child(brass)
	var shadow := _Helpers.make_emitter({
		"count": _pcount(6), "lifetime": 1.1, "color": COL_SHADOW_HOT,
		"speed_min": 120.0, "speed_max": 360.0,
		"direction": Vector2.UP, "spread": 180.0,
		"gravity": 54.0, "damping": 0.0,
		"size_min": 1.2, "size_max": 2.4,
		"size_base": 16.0,
		"texture": _Helpers.mote_halo_tex(),
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	shadow.position = ctr
	add_child(shadow)
