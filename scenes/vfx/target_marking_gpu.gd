# scenes/vfx/target_marking_gpu.gd
# 타겟 마킹 GPU 하이브리드 — target_marking.gd 상속.
# lock spark (red+amber) + hold ember (red) mote GPU. rune (회전 글리프) 은 CPU 유지.
# reticle / brackets / wash 폴리곤 → CPU.
extends "res://scenes/vfx/target_marking.gd"

const _Helpers = preload("res://scenes/vfx/gpu_particle_helpers.gd")

const _COL_RED   := Color(1.0, 0.470, 0.501)        # _mote_color red
const _COL_AMBER := Color(0.909, 0.784, 0.470)      # _mote_color amber

var _lock_made: bool = false
var _gpu_hold_ember: GPUParticles2D
var _hold_made: bool = false

func _process(delta: float) -> void:
	super._process(delta)
	var ga: float = _global_alpha()
	for child in get_children():
		if child is GPUParticles2D:
			child.modulate.a = ga

# lock 폭발: mote red 10 + amber 10 GPU (외곽→target 수렴은 어려움, 대신 외곽 spread 로 근사).
# rune 4 CPU.
func _spawn_lock_sparks() -> void:
	if _lock_made:
		return
	_lock_made = true
	# 원본은 외곽에서 target 쪽으로 수렴 — GPU 표준은 origin → 외곽 spread 만.
	# 시각 근사: target 중심에서 외곽으로 burst (반대 방향) + 짧은 lifetime.
	var spark_red := _Helpers.make_emitter({
		"count": _pcount(10), "lifetime": 0.9, "color": _COL_RED,
		"speed_min": 90.0, "speed_max": 180.0,
		"direction": Vector2.UP, "spread": 180.0,
		"gravity": 0.0, "damping": 3.0,
		"size_min": 1.2, "size_max": 2.4,
		"size_base": 16.0,
		"texture": _Helpers.mote_halo_tex(),
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	spark_red.position = _target
	add_child(spark_red)
	var spark_amber := _Helpers.make_emitter({
		"count": _pcount(10), "lifetime": 0.9, "color": _COL_AMBER,
		"speed_min": 90.0, "speed_max": 180.0,
		"direction": Vector2.UP, "spread": 180.0,
		"gravity": 0.0, "damping": 3.0,
		"size_min": 1.2, "size_max": 2.4,
		"size_base": 16.0,
		"texture": _Helpers.mote_halo_tex(),
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	spark_amber.position = _target
	add_child(spark_amber)
	# rune 4 CPU (회전 글리프)
	for _i in range(_pcount(4)):
		var a2 := randf() * TAU
		_particles.append({
			"pos": _target + Vector2(randf_range(-20.0, 20.0), randf_range(-30.0, 30.0)),
			"vel": Vector2(cos(a2) * 0.6, sin(a2) * 0.6),
			"life": 0.0,
			"max_life": 0.8 + randf() * 0.4,
			"size": 8.0 + randf() * 5.0,
			"kind": "rune",
			"rot": randf() * TAU,
			"spin": randf_range(-0.04, 0.04),
			"glyph_idx": randi() % 5,
		})

# hold red ember GPU continuous
func _spawn_hold_ember() -> void:
	if _hold_made:
		return
	_hold_made = true
	# 0.4/frame × 60 × lifetime 1.25 ≈ 30 동시
	_gpu_hold_ember = _Helpers.make_emitter({
		"count": int(30 * _scale()), "lifetime": 1.25, "color": _COL_RED,
		"speed_min": 24.0, "speed_max": 48.0,
		"direction": Vector2.UP, "spread": 12.0,
		"gravity": 0.0, "damping": 3.0,
		"size_min": 1.0, "size_max": 2.1,
		"size_base": 16.0,
		"texture": _Helpers.mote_halo_tex(),
		"emission_shape": "box", "emission_box": Vector2(100.0, 25.0),
		"one_shot": false, "explosiveness": 0.0,
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	_gpu_hold_ember.position = _target + Vector2(0.0, 55.0)
	add_child(_gpu_hold_ember)
	get_tree().create_timer(HOLD_TIME).timeout.connect(func() -> void:
		if is_instance_valid(_gpu_hold_ember): _gpu_hold_ember.emitting = false)
