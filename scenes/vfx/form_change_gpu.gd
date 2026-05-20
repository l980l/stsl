# scenes/vfx/form_change_gpu.gd
# 폼 변환 GPU 하이브리드 — form_change.gd 상속.
# _spawn_shatter_burst(cyan_shard 50) / _spawn_reveal_burst(brass_spark 70 + ground_dust 20 + brass_ember 18)
#   → GPUParticles2D 버스트로 대체.
# cyan_mote(차지 중 매 프레임 랜덤 누출 — 단일 이미터로 표현 곤란) / pillar·crack·ring·flash 폴리곤
#   → CPU _draw() 상속 유지.
extends "res://scenes/vfx/form_change.gd"

const _Helpers = preload("res://scenes/vfx/gpu_particle_helpers.gd")

# ground dust — 시간에 따라 1.0 → 2.2 배 확장 (원본 r * (1 + k*1.2))
static func _dust_grow_curve() -> Curve:
	var c := Curve.new()
	c.add_point(Vector2(0.0, 1.0))
	c.add_point(Vector2(1.0, 2.2))
	return c

# SHATTER — 이전 폼 cyan shard 폭발
func _spawn_shatter_burst() -> void:
	var shard := _Helpers.make_emitter({
		"count": _pcount(50), "lifetime": 1.2, "color": Color.WHITE,
		"speed_min": 180.0, "speed_max": 600.0, "spread": 180.0,
		"gravity": 144.0,
		"size_min": 1.4, "size_max": 2.8,
		"emission_shape": "box", "emission_box": Vector2(4.0, 35.0),
		"color_ramp": _Helpers.make_color_ramp(
			Color(0.8, 0.86, 1.0), Color(0.675, 0.74, 1.0), Color(0.55, 0.62, 1.0),
			1.0, 0.5, 0.0),
	})
	shard.position = _target
	_glow_layer.add_child(shard)

# REVEAL — 새 폼 brass spark + 발치 ground dust + 떠다니는 brass ember
func _spawn_reveal_burst() -> void:
	# brass spark 70 — glow(가산)
	var spark := _Helpers.make_emitter({
		"count": _pcount(70), "lifetime": 1.4, "color": Color.WHITE,
		"speed_min": 180.0, "speed_max": 720.0, "spread": 180.0,
		"gravity": 90.0,
		"size_min": 1.4, "size_max": 3.0,
		"color_ramp": _Helpers.make_color_ramp(
			Color(1.0, 0.90, 0.62), Color(1.0, 0.82, 0.465), Color(1.0, 0.74, 0.31),
			1.0, 0.5, 0.0),
	})
	spark.position = _target
	_glow_layer.add_child(spark)
	# ground dust 20 — 발치 위쪽 반원, 크기 확장, ground layer(캐릭터 뒤)
	var dust := _Helpers.make_emitter({
		"count": _pcount(20), "lifetime": 1.6, "color": Color(0.78, 0.67, 0.47),
		"speed_min": 120.0, "speed_max": 360.0,
		"direction": Vector2.UP, "spread": 72.0,
		"gravity": 43.0,
		"size_min": 8.0, "size_max": 16.0,
		"scale_curve": _dust_grow_curve(),
		"emission_shape": "box", "emission_box": Vector2(50.0, 4.0),
		"start_alpha": 0.55, "mid_alpha": 0.3, "end_alpha": 0.0,
	})
	dust.position = _foot_pos()
	_ground_layer.add_child(dust)
	# brass ember 18 — 떠다니는 잔불(살짝 상승), glow(가산)
	var ember := _Helpers.make_emitter({
		"count": _pcount(18), "lifetime": 2.2, "color": Color.WHITE,
		"speed_min": 30.0, "speed_max": 105.0,
		"direction": Vector2.UP, "spread": 50.0,
		"gravity": -14.0,
		"size_min": 1.6, "size_max": 3.0,
		"emission_shape": "box", "emission_box": Vector2(25.0, 40.0),
		"color_ramp": _Helpers.make_color_ramp(
			Color(1.0, 0.78, 0.43), Color(1.0, 0.66, 0.35), Color(1.0, 0.54, 0.27),
			0.9, 0.45, 0.0),
	})
	ember.position = _target
	_glow_layer.add_child(ember)
