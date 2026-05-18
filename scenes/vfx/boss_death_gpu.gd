# scenes/vfx/boss_death_gpu.gd
# 보스 사망 GPU 하이브리드 — boss_death.gd 와 동일 시각.
# 상속 + _spawn_debris_burst/_spawn_ember override 해서 GPU emitter 만 spawn.
# 원본의 _particles Array 는 빈 상태로 유지 → super._draw_solid_pass / _draw_glow_pass 가 자동으로 skip.
# 모든 CPU 폴리곤 (cracks/inhale/pillar/shock/crown/slate/text/wash) 은 원본 그대로 작동.
extends "res://scenes/vfx/boss_death.gd"

const _Helpers = preload("res://scenes/vfx/gpu_particle_helpers.gd")

var _gpu_debris: GPUParticles2D
var _gpu_ember: GPUParticles2D
var _gpu_ember_made: bool = false

# 원본: _particles.append × 22 (debris 회전 chunk). GPU: chunk emitter 1회 burst.
func _spawn_debris_burst() -> void:
	var ctr: Vector2 = _blast_pos()
	# 원본 vel: speed 3~8 * 60 = 180~480, y -60 bias. lifetime 1.2~2.2 평균 1.7. size 3~10. grav 0.06*60=3.6 (down).
	_gpu_debris = _Helpers.make_chunk_emitter(
		COL_DEBRIS, _pcount(22), 1.7, 180.0, 480.0, 216.0, 3.0, 10.0)
	_gpu_debris.position = ctr
	add_child(_gpu_debris)

# 원본: _particles.append × 0.2 확률/frame ≈ 12/sec * lifetime 2 ≈ 24 동시.
# GPU: 첫 호출 시 continuous emitter 만들고 이후 noop. HOLD_TIME 후 자동 off.
func _spawn_ember() -> void:
	if _gpu_ember_made:
		return
	_gpu_ember_made = true
	var ctr: Vector2 = _blast_pos()
	_gpu_ember = _Helpers.make_emitter({
		"count": int(28 * _scale()),
		"lifetime": 2.0,
		"color": COL_FIRE,
		"speed_min": 90.0, "speed_max": 240.0,
		"direction": Vector2.UP, "spread": 90.0,
		"gravity": 36.0, "damping": 4.0,
		"size_min": 1.8, "size_max": 3.8,
		"emission_shape": "box", "emission_box": Vector2(100.0, 40.0),
		"one_shot": false, "explosiveness": 0.0,
	})
	_gpu_ember.position = ctr
	add_child(_gpu_ember)
	# HOLD_TIME 종료 시 emitter 끄기 (원본 _spawn_ember 는 그 시점부터 호출 안 됨)
	get_tree().create_timer(HOLD_TIME).timeout.connect(func() -> void:
		if is_instance_valid(_gpu_ember):
			_gpu_ember.emitting = false)
