# scenes/vfx/vulnerable_debuff_gpu.gd
# 취약 디버프 GPU 하이브리드 — vulnerable_debuff.gd 상속.
# impact 파편(chunk)·brass/red mote·dust burst + 노출 중 잔불 ambient 를 GPUParticles2D 로 대체.
# 벡터 글로우(쐐기·균열·약점표식·깨진 방패·funnel)는 CPU 유지 (부모 _draw).
extends "res://scenes/vfx/vulnerable_debuff.gd"

const _Helpers = preload("res://scenes/vfx/gpu_particle_helpers.gd")

var _gpu_embers: GPUParticles2D
var _amb_made: bool = false

# impact 파편 폭발 — chunk(갑옷 파편) + mote(brass/red) + dust
func _spawn_shatter(pos: Vector2) -> void:
	# 갑옷 파편 — 회전 사각형 chunk (brass)
	var shard := _Helpers.make_chunk_emitter(COL_WARN, _pcount(24), 0.9, 130.0, 380.0, 60.0, 3.0, 7.0)
	shard.position = pos
	add_child(shard)
	# brass mote (가산, halo)
	var mote_b := _Helpers.make_emitter({
		"count": _pcount(13), "lifetime": 0.8, "color": COL_WARN,
		"speed_min": 96.0, "speed_max": 300.0, "gravity": -36.0, "damping": 5.0,
		"size_min": 1.0, "size_max": 2.6, "additive": true,
		"texture": _Helpers.mote_halo_tex(), "size_base": 16.0,
	})
	mote_b.position = pos
	add_child(mote_b)
	# red mote (가산, halo)
	var mote_r := _Helpers.make_emitter({
		"count": _pcount(15), "lifetime": 0.8, "color": COL_RED_HOT,
		"speed_min": 96.0, "speed_max": 300.0, "gravity": -36.0, "damping": 5.0,
		"size_min": 1.0, "size_max": 2.6, "additive": true,
		"texture": _Helpers.mote_halo_tex(), "size_base": 16.0,
	})
	mote_r.position = pos
	add_child(mote_r)
	# dust (비가산, 어두운 붉은 먼지)
	var dust := _Helpers.make_emitter({
		"count": _pcount(12), "lifetime": 1.4, "color": Color(0.46, 0.18, 0.18),
		"speed_min": 36.0, "speed_max": 120.0, "gravity": -10.0, "damping": 3.0,
		"size_min": 14.0, "size_max": 30.0, "additive": false,
		"start_alpha": 0.32, "mid_alpha": 0.2, "end_alpha": 0.0,
	})
	dust.position = pos
	add_child(dust)

# 노출 중 잔불 — CPU 매프레임 대신 GPU continuous emitter 1회 생성
func _spawn_ambient_embers() -> void:
	if _amb_made:
		return
	_amb_made = true
	_gpu_embers = _Helpers.make_emitter({
		"count": int(40 * _scale()), "lifetime": 1.6, "color": COL_RED_HOT,
		"speed_min": 18.0, "speed_max": 48.0, "direction": Vector2.UP, "spread": 30.0,
		"gravity": -24.0, "damping": 2.0, "size_min": 1.0, "size_max": 2.2,
		"additive": true, "texture": _Helpers.mote_halo_tex(), "size_base": 16.0,
		"emission_shape": "sphere", "emission_radius": 30.0,
		"one_shot": false, "explosiveness": 0.0,
		"start_alpha": 0.9, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	_gpu_embers.position = _chest
	add_child(_gpu_embers)
	get_tree().create_timer(EXPOSED_TIME).timeout.connect(func() -> void:
		if is_instance_valid(_gpu_embers):
			_gpu_embers.emitting = false)
