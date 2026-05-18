# scenes/vfx/lightning_beam_gpu.gd
# 번개 GPU 하이브리드 — lightning_beam.gd 상속.
# _sparks (CPUParticles2D) 무력화 + GPUParticles2D 로 대체.
# bolt polyline / 차지 오브 / impact orb CPU 그대로.
extends "res://scenes/vfx/lightning_beam.gd"

const _Helpers = preload("res://scenes/vfx/gpu_particle_helpers.gd")

var _gpu_sparks: GPUParticles2D

func _ready() -> void:
	super._ready()
	# super 의 CPU sparks 무력화
	if _sparks != null:
		_sparks.emitting = false
		_sparks.visible = false
	# GPU sparks — 동일 spec (amount 14, lifetime 0.8, spread 180, speed 80~240, scale 1.5~3.0)
	_gpu_sparks = _Helpers.make_emitter({
		"count": 14, "lifetime": 0.8,
		"color": COL_MID,
		"speed_min": 80.0, "speed_max": 240.0,
		"direction": Vector2.UP, "spread": 180.0,
		"gravity": 0.0, "damping": 3.0,
		"size_min": 1.5, "size_max": 3.0,
		"size_base": 4.0,
		"texture": _Helpers.sparkle_tex(),
		"explosiveness": 1.0, "one_shot": true,
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	_gpu_sparks.emitting = false
	add_child(_gpu_sparks)

func play(caster_pos: Vector2, target_pos: Vector2) -> void:
	super.play(caster_pos, target_pos)
	if is_instance_valid(_gpu_sparks):
		_gpu_sparks.position = target_pos
		# super 의 _run 이 비동기 — 차지 0.55s + 발사 직후 sparks. timer 로 동기.
		get_tree().create_timer(0.55).timeout.connect(func() -> void:
			if is_instance_valid(_gpu_sparks): _gpu_sparks.restart())
