# scenes/vfx/debuff_hex_gpu.gd
# 디버프 헥스 GPU 하이브리드 — debuff_hex.gd 상속.
# impact 시 miasma + drip GPU burst, ambient miasma GPU continuous. rune (회전 심볼) CPU 유지.
# tendrils (포물선 경로) 도 CPU 유지 (경로 종속).
extends "res://scenes/vfx/debuff_hex.gd"

const _Helpers = preload("res://scenes/vfx/gpu_particle_helpers.gd")

const _COL_LILAC := Color(0.85, 0.65, 0.95)   # 연보라 라벤더 (보라 위주, 회색X)
const _COL_GRASS := Color(0.49, 0.99, 0.0)    # #7CFC00 lawn green (밝은 잔디)

var _impact_made: bool = false
var _gpu_amb_miasma: GPUParticles2D
var _amb_made: bool = false

# impact: miasma 55 + drip 18 GPU + rune 32 CPU inline
func _spawn_impact_cloud(pos: Vector2) -> void:
	if _impact_made:
		return
	_impact_made = true
	# miasma 55 (보라 안개 — COL_MIASMA, non-add)
	var miasma := _Helpers.make_emitter({
		"count": _pcount(55), "lifetime": 2.1, "color": _COL_LILAC,
		"speed_min": 48.0, "speed_max": 228.0,
		"direction": Vector2.UP, "spread": 160.0,
		"gravity": -28.8, "damping": 3.0,
		"size_min": 18.0, "size_max": 40.0,
		"additive": false,
		"start_alpha": 0.4, "mid_alpha": 0.25, "end_alpha": 0.0,
	})
	miasma.position = pos
	miasma.z_index = -1  # _smoke_layer 영역 — _hex_layer (sigil/rune) 보다 뒤
	add_child(miasma)
	# drip 18 (작은 원형 녹색 방울 — circle_tex, non-add, COL_DRIP × 0.9)
	# size_base default 32 → size r*0.9 매핑. drip_tex 의 poison 색 곱셈 회피.
	var drip := _Helpers.make_emitter({
		"count": _pcount(18), "lifetime": 2.0, "color": _COL_GRASS,
		"speed_min": 60.0, "speed_max": 240.0,
		"direction": Vector2.UP, "spread": 160.0,
		"gravity": 180.0, "damping": 3.0,
		"size_min": 2.7, "size_max": 6.3,  # 원본 r=3.0~7.0 × 0.9 매칭
		"additive": false,
		"start_alpha": 0.7, "mid_alpha": 0.4, "end_alpha": 0.0,
	})
	drip.position = pos
	drip.z_index = -1
	add_child(drip)
	# rune CPU 32 (회전 심볼 — GPU 표준 파티클로 표현 불가)
	for _i in range(_pcount(32)):
		var a := randf() * TAU
		var sp := 1.0 + randf() * 4.0
		_particles.append(_mk(pos, Vector2(cos(a) * sp, sin(a) * sp - 0.5),
			1.0 + randf() * 0.7, 1.5 + randf() * 1.4, "rune", 0.0))

# ambient: miasma GPU continuous + rune CPU inline
func _spawn_ambient() -> void:
	if not _amb_made:
		_amb_made = true
		# 0.7/frame × 60 × lifetime 2.5 ≈ 105 동시
		_gpu_amb_miasma = _Helpers.make_emitter({
			"count": int(105 * _scale()), "lifetime": 2.5, "color": _COL_LILAC,
			"speed_min": 18.0, "speed_max": 60.0,
			"direction": Vector2.UP, "spread": 18.0,
			"gravity": -14.4, "damping": 3.0,
			"size_min": 10.0, "size_max": 24.0,
			"additive": false,
			"emission_shape": "box", "emission_box": Vector2(50.0, 10.0),
			"one_shot": false, "explosiveness": 0.0,
			"start_alpha": 0.4, "mid_alpha": 0.25, "end_alpha": 0.0,
		})
		_gpu_amb_miasma.position = _target + Vector2(0.0, 30.0)
		_gpu_amb_miasma.z_index = -1
		add_child(_gpu_amb_miasma)
		get_tree().create_timer(DEBUFF_TIME).timeout.connect(func() -> void:
			if is_instance_valid(_gpu_amb_miasma): _gpu_amb_miasma.emitting = false)
	# rune CPU
	if randf() < 0.3 * _scale():
		_particles.append(_mk(_target + Vector2(randf_range(-45.0, 45.0), randf_range(-5.0, 25.0)),
			Vector2(randf_range(-0.15, 0.15), -0.4 - randf() * 0.4),
			1.4 + randf() * 0.8, 1.2 + randf() * 1.2, "rune", 0.0))
