# scenes/vfx/weaken_debuff_gpu.gd
# 약화 디버프 GPU 하이브리드 — weaken_debuff.gd 상속.
# 힘 흡수 burst + SAP 가라앉는 sink mote·잿빛 smoke 를 GPUParticles2D 로 대체.
# 벡터 글로우(움켜쥐는 룬·siphon 실·beads·시든 검·▼·웅덩이)는 CPU 유지 (부모 _draw). beads 는 베지어 경로라 CPU.
extends "res://scenes/vfx/weaken_debuff.gd"

const _Helpers = preload("res://scenes/vfx/gpu_particle_helpers.gd")

var _gpu_sink: GPUParticles2D
var _gpu_smoke: GPUParticles2D
var _amb_made: bool = false

# 힘 흡수 burst — 아래로 빠지는 sage/ash mote + 가라앉는 smoke
func _spawn_drain_burst(pos: Vector2) -> void:
	var sage := _Helpers.make_emitter({
		"count": _pcount(20), "lifetime": 1.0, "color": COL_WEAK,
		"direction": Vector2.DOWN, "spread": 55.0,
		"speed_min": 60.0, "speed_max": 200.0, "gravity": 36.0, "damping": 3.0,
		"size_min": 1.2, "size_max": 2.6, "additive": true,
		"texture": _Helpers.mote_halo_tex(), "size_base": 16.0,
	})
	sage.position = pos
	add_child(sage)
	var ash := _Helpers.make_emitter({
		"count": _pcount(12), "lifetime": 1.0, "color": COL_ASH,
		"direction": Vector2.DOWN, "spread": 55.0,
		"speed_min": 50.0, "speed_max": 170.0, "gravity": 36.0, "damping": 3.0,
		"size_min": 1.0, "size_max": 2.2, "additive": true,
		"texture": _Helpers.mote_halo_tex(), "size_base": 16.0,
	})
	ash.position = pos
	add_child(ash)
	var smoke := _Helpers.make_emitter({
		"count": _pcount(12), "lifetime": 1.3, "color": Color(0.31, 0.42, 0.37),
		"direction": Vector2.DOWN, "spread": 60.0,
		"speed_min": 20.0, "speed_max": 70.0, "gravity": 12.0, "damping": 3.0,
		"size_min": 14.0, "size_max": 30.0, "additive": false,
		"start_alpha": 0.3, "mid_alpha": 0.18, "end_alpha": 0.0,
	})
	smoke.position = pos
	add_child(smoke)

# SAP 중 가라앉는 잿빛 활력 — CPU 매프레임 대신 GPU continuous emitter 1회 생성
func _spawn_sap_ambient() -> void:
	if _amb_made:
		return
	_amb_made = true
	_gpu_sink = _Helpers.make_emitter({
		"count": int(36 * _scale()), "lifetime": 1.4, "color": COL_WEAK,
		"direction": Vector2.DOWN, "spread": 40.0,
		"speed_min": 14.0, "speed_max": 38.0, "gravity": 16.0, "damping": 2.0,
		"size_min": 1.0, "size_max": 2.2, "additive": true,
		"texture": _Helpers.mote_halo_tex(), "size_base": 16.0,
		"emission_shape": "sphere", "emission_radius": 34.0,
		"one_shot": false, "explosiveness": 0.0,
		"start_alpha": 0.9, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	_gpu_sink.position = _chest
	add_child(_gpu_sink)
	_gpu_smoke = _Helpers.make_emitter({
		"count": int(14 * _scale()), "lifetime": 1.6, "color": Color(0.31, 0.42, 0.37),
		"direction": Vector2.DOWN, "spread": 40.0,
		"speed_min": 8.0, "speed_max": 24.0, "gravity": 8.0, "damping": 2.0,
		"size_min": 12.0, "size_max": 26.0, "additive": false,
		"emission_shape": "sphere", "emission_radius": 30.0,
		"one_shot": false, "explosiveness": 0.0,
		"start_alpha": 0.28, "mid_alpha": 0.16, "end_alpha": 0.0,
	})
	_gpu_smoke.position = _chest + Vector2(0.0, 8.0)
	add_child(_gpu_smoke)
	get_tree().create_timer(SAP_TIME).timeout.connect(func() -> void:
		if is_instance_valid(_gpu_sink):
			_gpu_sink.emitting = false
		if is_instance_valid(_gpu_smoke):
			_gpu_smoke.emitting = false)
