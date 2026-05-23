# scenes/vfx/life_drain_gpu.gd
# 생명력 흡수 GPU 하이브리드 — life_drain.gd 상속.
# 변환 대상: _spawn_wound_burst (open 1-shot 28) + _spawn_flow (siphon 지속 target→caster) + _spawn_rising (바닥 motes)
# 유지(CPU): tether wavy 3-라인 / wither·spiral 고리 / 성배 sigil — 폴리곤·동적 곡선이라 GPU 표준 파티클로 표현 불가.
# flow 입자는 GPU 직선 방향 (target→caster) — CPU 의 wavy path 추종 효과는 손실(직선). 시각적 흐름감은 CPU 가 그리는 tether 가 유지.
extends "res://scenes/vfx/life_drain.gd"

const _Helpers = preload("res://scenes/vfx/gpu_particle_helpers.gd")

var _splat_made: bool = false
var _amb_made: bool = false
var _gpu_flow_blood: GPUParticles2D
var _gpu_flow_brass: GPUParticles2D
var _gpu_rise_cold: GPUParticles2D
var _gpu_rise_warm: GPUParticles2D

# Override: open 1-shot 28 splat → GPU one-shot.
# 원본 CPU vel = sp * PSPEED * 0.06 (sp=2..6), pos += vel * delta * PSPEED →
# 효과 px/sec = sp * 3.6 * 60 = 432..1296. gravity = 0.08 * 60 * 60 = 288 px/sec².
func _spawn_wound_burst() -> void:
	if _splat_made:
		return
	_splat_made = true
	var dir_to_caster: Vector2 = (_caster - _target).normalized() if _caster.distance_to(_target) > 1.0 else Vector2.LEFT
	var splat := _Helpers.make_emitter({
		"count": _pcount(28), "lifetime": 1.4, "color": COL_BLOOD,
		"direction": dir_to_caster, "spread": 40.0,
		"speed_min": 432.0, "speed_max": 1296.0,
		"gravity": 288.0, "damping": 80.0,
		"size_min": 1.4, "size_max": 3.0,
		"size_base": 32.0,
		"additive": false,
		"start_alpha": 1.0, "mid_alpha": 0.6, "end_alpha": 0.0,
	})
	splat.position = _target + Vector2(0.0, -8.0)
	add_child(splat)

# Override: 지속 spawn → 첫 호출 시 GPU emitter 설정 후 noop.
func _spawn_flow() -> void:
	_setup_ambient_once()

func _spawn_rising() -> void:
	_setup_ambient_once()

func _setup_ambient_once() -> void:
	if _amb_made:
		return
	_amb_made = true
	# ── flow blood (target → caster, 직선) ──
	var diff: Vector2 = _caster - _target
	var dist: float = diff.length()
	var dir: Vector2 = diff.normalized() if dist > 1.0 else Vector2.UP
	# 입자가 정확히 caster 위치에서 사라지도록 — speed 편차 0 + lifetime = dist/speed 정확 매칭.
	# 모든 입자가 동일 속도/수명 → 정확히 같은 시점에 caster 도달 + 즉시 fade.
	# play() 호출 시점에 거리 계산하므로 distance 변화에 자동 적응.
	# 시각 다양성은 emission_box (시작점 작은 분산) + size 편차로 확보.
	var flow_speed: float = dist / 0.75 if dist > 1.0 else 800.0
	var flow_lifetime: float = 0.75
	_gpu_flow_blood = _Helpers.make_emitter({
		"count": int(120.0 * flow_lifetime * _scale()), "lifetime": flow_lifetime, "color": COL_HOT,
		"direction": dir, "spread": 0.0,
		"speed_min": flow_speed, "speed_max": flow_speed,
		"size_min": 1.5, "size_max": 2.8,
		"size_base": 16.0,
		"texture": _Helpers.mote_halo_tex(),
		"emission_shape": "box", "emission_box": Vector2(8.0, 8.0),
		"one_shot": false, "explosiveness": 0.0,
		"lifetime_randomness": 0.0,
		"start_alpha": 1.0, "mid_alpha": 0.85, "end_alpha": 0.0,
	})
	_gpu_flow_blood.position = _target
	add_child(_gpu_flow_blood)
	# ── flow brass (sparse, 조금 느림) ──
	# 원본 28% 확률/frame × 60 = 16.8/s × lifetime ≈ 동시 입자수
	var brass_lifetime: float = 0.95  # 25% 더 느림
	var brass_speed: float = dist / brass_lifetime if dist > 1.0 else 630.0
	_gpu_flow_brass = _Helpers.make_emitter({
		"count": int(16.8 * brass_lifetime * _scale()), "lifetime": brass_lifetime, "color": COL_BRASS,
		"direction": dir, "spread": 0.0,
		"speed_min": brass_speed, "speed_max": brass_speed,
		"size_min": 1.9, "size_max": 3.3,
		"size_base": 16.0,
		"texture": _Helpers.mote_halo_tex(),
		"emission_shape": "box", "emission_box": Vector2(8.0, 8.0),
		"one_shot": false, "explosiveness": 0.0,
		"lifetime_randomness": 0.0,
		"start_alpha": 1.0, "mid_alpha": 0.85, "end_alpha": 0.0,
	})
	_gpu_flow_brass.position = _target
	add_child(_gpu_flow_brass)
	# ── rise cold (target 발 — 어두운 망령) ──
	var t_floor: Vector2 = _target_ground if _has_grounds else _target + Vector2(0.0, 80.0)
	var c_floor: Vector2 = _caster_ground if _has_grounds else _caster + Vector2(0.0, 80.0)
	# 원본 70% 확률/frame × 60 = 42/s × lifetime 1.7 ≈ 71 동시 → GPU 는 밀도 4배로 강조 (코어 작아 시각 손실 보상).
	# COL_BLOOD_D 가 어두운 색이라 가산 블렌드에서 흐릿 → size·mid_alpha 보강 (CPU 의 2-layer draw 누적 효과 보상)
	_gpu_rise_cold = _Helpers.make_emitter({
		"count": int(284.0 * _scale()), "lifetime": 1.7, "color": COL_BLOOD_D,
		"direction": Vector2.UP, "spread": 22.0,
		"speed_min": 33.0, "speed_max": 75.0,
		"size_min": 1.6, "size_max": 3.2,
		"size_base": 16.0,
		"texture": _Helpers.mote_halo_tex(),
		"emission_shape": "box", "emission_box": Vector2(40.0, 4.0),
		"one_shot": false, "explosiveness": 0.0,
		"start_alpha": 1.0, "mid_alpha": 0.85, "end_alpha": 0.0,
	})
	_gpu_rise_cold.position = t_floor
	add_child(_gpu_rise_cold)
	# ── rise warm (caster 발 — brass 생명) ──
	# 원본 50% × 60 = 30/s × lifetime 1.7 ≈ 51 동시 → GPU 는 밀도 4배로 강조
	_gpu_rise_warm = _Helpers.make_emitter({
		"count": int(204.0 * _scale()), "lifetime": 1.7, "color": COL_BRASS,
		"direction": Vector2.UP, "spread": 20.0,
		"speed_min": 36.0, "speed_max": 72.0,
		"size_min": 1.0, "size_max": 2.2,
		"size_base": 16.0,
		"texture": _Helpers.mote_halo_tex(),
		"emission_shape": "box", "emission_box": Vector2(40.0, 4.0),
		"one_shot": false, "explosiveness": 0.0,
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	_gpu_rise_warm.position = c_floor
	add_child(_gpu_rise_warm)
	# SIPHON_TIME + SEAL_TIME 동안만 분출 — 이후 emit 정지 (잔여 입자는 lifetime 만큼 페이드)
	get_tree().create_timer(SIPHON_TIME + SEAL_TIME).timeout.connect(func() -> void:
		if is_instance_valid(_gpu_flow_blood): _gpu_flow_blood.emitting = false
		if is_instance_valid(_gpu_flow_brass): _gpu_flow_brass.emitting = false
		if is_instance_valid(_gpu_rise_cold): _gpu_rise_cold.emitting = false
		if is_instance_valid(_gpu_rise_warm): _gpu_rise_warm.emitting = false)
