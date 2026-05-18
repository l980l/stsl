# scenes/vfx/explosion_blast_gpu.gd
# 대폭발 GPU 하이브리드 — explosion_blast.gd 상속.
# _spawn_fireball (core/fireball/flame/ember/dust/smoke/chunk) + _spawn_ambient_smoke → GPU.
# 폭탄 비행/회전, 레티클, 분화구, 충격파 → CPU.
extends "res://scenes/vfx/explosion_blast.gd"

const _Helpers = preload("res://scenes/vfx/gpu_particle_helpers.gd")

var _fireball_made: bool = false
var _ambient_smoke: GPUParticles2D
var _ambient_made: bool = false

func _spawn_fireball(pos: Vector2) -> void:
	if _fireball_made:
		return
	_fireball_made = true
	var bs := BLAST_SCALE
	# core 10 — 흰 코어, lifetime 0.4
	var core := _Helpers.make_emitter({
		"count": _pcount(10), "lifetime": 0.4, "color": COL_HOT,
		"speed_min": 60.0 * bs, "speed_max": 240.0 * bs,
		"direction": Vector2.UP, "spread": 180.0,
		"gravity": -36.0 * bs, "damping": 3.0,
		"size_min": 18.0 * bs, "size_max": 34.0 * bs,
		"color_ramp": _Helpers.make_color_ramp(COL_HOT, COL_MID, COL_DEEP, 0.95, 0.7, 0.0),
	})
	core.position = pos
	add_child(core)
	# fireball 50 — 주황, lifetime 1.4
	var fireball := _Helpers.make_emitter({
		"count": _pcount(50), "lifetime": 1.4, "color": COL_MID,
		"speed_min": 120.0 * bs, "speed_max": 540.0 * bs,
		"direction": Vector2.UP, "spread": 180.0,
		"gravity": -90.0 * bs, "damping": 3.0,
		"size_min": 18.0 * bs, "size_max": 48.0 * bs,
		"color_ramp": _Helpers.make_color_ramp(COL_HOT, COL_MID, COL_DEEP, 0.9, 0.7, 0.0),
	})
	fireball.position = pos
	add_child(fireball)
	# flame 30 — 작은 불꽃, lifetime 0.9
	var flame := _Helpers.make_emitter({
		"count": _pcount(30), "lifetime": 0.9, "color": COL_HOT,
		"speed_min": 240.0 * bs, "speed_max": 720.0 * bs,
		"direction": Vector2.UP, "spread": 180.0,
		"gravity": -54.0 * bs, "damping": 3.0,
		"size_min": 8.0 * bs, "size_max": 22.0 * bs,
		"color_ramp": _Helpers.make_color_ramp(COL_HOT, COL_MID, COL_DEEP, 0.9, 0.7, 0.0),
	})
	flame.position = pos
	add_child(flame)
	# ember 70 — 흩어지는 불씨, lifetime 2.1, gravity ↓
	var ember := _Helpers.make_emitter({
		"count": _pcount(70), "lifetime": 2.1, "color": COL_MID,
		"speed_min": 180.0 * bs, "speed_max": 840.0 * bs,
		"direction": Vector2.UP, "spread": 180.0,
		"gravity": 216.0 * bs, "damping": 3.0,
		"size_min": 1.4 * bs, "size_max": 3.2 * bs,
		"color_ramp": _Helpers.make_color_ramp(
			Color(1.0, 0.784, 0.392), Color(1.0, 0.549, 0.235), Color(1.0, 0.313, 0.078),
			1.0, 0.6, 0.0),
	})
	ember.position = pos
	add_child(ember)
	# dust 35 — 흙먼지, lifetime 2.8, 옆으로 넓게
	var dust := _Helpers.make_emitter({
		"count": _pcount(35), "lifetime": 2.8, "color": COL_DUST,
		"speed_min": 120.0 * bs, "speed_max": 420.0 * bs,
		"direction": Vector2.UP, "spread": 130.0,
		"gravity": -18.0 * bs, "damping": 3.0,
		"size_min": 24.0 * bs, "size_max": 46.0 * bs,
		"additive": false,
		"start_alpha": 0.5, "mid_alpha": 0.25, "end_alpha": 0.0,
		"emission_shape": "box", "emission_box": Vector2(15.0 * bs, 4.0 * bs),
	})
	dust.position = pos + Vector2(0.0, 20.0 * bs)
	dust.z_index = -1
	add_child(dust)
	# smoke 25 — 위로 솟는 연기, lifetime 3.7
	var smoke := _Helpers.make_emitter({
		"count": _pcount(25), "lifetime": 3.7, "color": COL_SMOKE,
		"speed_min": 72.0 * bs, "speed_max": 252.0 * bs,
		"direction": Vector2.UP, "spread": 50.0,
		"gravity": -64.8 * bs, "damping": 3.0,
		"size_min": 34.0 * bs, "size_max": 64.0 * bs,
		"additive": false,
		"start_alpha": 0.35, "mid_alpha": 0.18, "end_alpha": 0.0,
		"emission_shape": "box", "emission_box": Vector2(20.0 * bs, 4.0 * bs),
	})
	smoke.position = pos + Vector2(0.0, -10.0 * bs)
	smoke.z_index = -2
	add_child(smoke)
	# chunk 15 — 회전 파편, lifetime 2.0, gravity 강하게 ↓
	var chunk := _Helpers.make_chunk_emitter(COL_CHUNK, _pcount(15), 2.0,
		240.0 * bs, 720.0 * bs, 1260.0 * bs, 3.0 * bs, 8.0 * bs)
	chunk.position = pos
	add_child(chunk)

func _spawn_ambient_smoke() -> void:
	if _ambient_made:
		return
	_ambient_made = true
	# 0.6 확률/frame × 60 × lifetime 3.2 ≈ 115 동시
	_ambient_smoke = _Helpers.make_emitter({
		"count": int(115 * _scale()), "lifetime": 3.2, "color": COL_SMOKE,
		"speed_min": 36.0 * BLAST_SCALE, "speed_max": 78.0 * BLAST_SCALE,
		"direction": Vector2.UP, "spread": 25.0,
		"gravity": -36.0 * BLAST_SCALE, "damping": 3.0,
		"size_min": 20.0 * BLAST_SCALE, "size_max": 38.0 * BLAST_SCALE,
		"additive": false,
		"start_alpha": 0.35, "mid_alpha": 0.18, "end_alpha": 0.0,
		"emission_shape": "box", "emission_box": Vector2(30.0 * BLAST_SCALE, 5.0 * BLAST_SCALE),
		"one_shot": false, "explosiveness": 0.0,
	})
	_ambient_smoke.position = _target + Vector2(0.0, -20.0 * BLAST_SCALE)
	_ambient_smoke.z_index = -2
	add_child(_ambient_smoke)
	get_tree().create_timer(SMOKE_TIME).timeout.connect(func() -> void:
		if is_instance_valid(_ambient_smoke): _ambient_smoke.emitting = false)
