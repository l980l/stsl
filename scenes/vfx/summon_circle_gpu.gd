# scenes/vfx/summon_circle_gpu.gd
# 소환 마법진 GPU 하이브리드 — summon_circle.gd 상속.
# _spawn_rising (mote continuous) + _spawn_peak_burst (one-time) GPU.
# rune (glyph 문자) 은 super CPU 그대로 (텍스트 렌더링).
# 마법진 원·심볼·기둥 폴리곤 → CPU.
extends "res://scenes/vfx/summon_circle.gd"

const _Helpers = preload("res://scenes/vfx/gpu_particle_helpers.gd")

var _gpu_rising_violet: GPUParticles2D
var _gpu_rising_cyan: GPUParticles2D
var _gpu_rising_magenta: GPUParticles2D
var _rising_made: bool = false
var _peak_made: bool = false

# 원본 tint 분포: violet 40% / cyan 30% / magenta 30% (super _spawn_rising 코드 참고).
# rising 은 super 의 _process 마지막 phase 끝나면 호출 안 됨 — emitter off 별도 트리거 없이
# 자연스럽게 spawn 중단 → 기존 입자 lifetime 동안 페이드 아웃.
func _make_rising_emitter(col: Color, count_total: int, foot: Vector2) -> GPUParticles2D:
	var em := _Helpers.make_emitter({
		"count": count_total,
		"lifetime": 1.7,  # 원본 max_life 1.0 + randf*0.7 = 평균 1.35, max 1.7
		"color": col,
		"speed_min": 60.0, "speed_max": 132.0,
		"direction": Vector2.UP, "spread": 12.0,
		"gravity": 0.0, "damping": 3.0,
		"size_min": 1.4, "size_max": 2.8,
		"size_base": 4.0,
		"texture": _Helpers.sparkle_tex(),
		"emission_shape": "box", "emission_box": Vector2(CIRCLE_R * 0.7, CIRCLE_R * 0.3 * RING_SQUASH),
		"one_shot": false, "explosiveness": 0.0,
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	em.position = foot
	return em

# _spawn_rising override — mote 3 색 GPU 분리 + rune CPU
func _spawn_rising(n: int) -> void:
	if not _rising_made:
		_rising_made = true
		var foot: Vector2 = _foot_pos()
		# n/frame × 60 × lifetime 1.7 = 102*n 동시. 평균 n=3 → 306.
		# violet 40%, cyan 30%, magenta 30%.
		_gpu_rising_violet  = _make_rising_emitter(COL_VIOLET,  int(122 * _scale()), foot)
		_gpu_rising_cyan    = _make_rising_emitter(COL_CYAN,    int(92 * _scale()), foot)
		_gpu_rising_magenta = _make_rising_emitter(COL_MAGENTA, int(92 * _scale()), foot)
		add_child(_gpu_rising_violet)
		add_child(_gpu_rising_cyan)
		add_child(_gpu_rising_magenta)
		# spawn 중단 트리거 — super 의 rising phase 끝 (PEAK_DELAY+0.2 = 0.8s) 후 emit 정지.
		# 기존 입자는 lifetime 1.7 동안 자연 페이드 아웃.
		get_tree().create_timer(PEAK_DELAY + 0.2).timeout.connect(func() -> void:
			if is_instance_valid(_gpu_rising_violet): _gpu_rising_violet.emitting = false
			if is_instance_valid(_gpu_rising_cyan): _gpu_rising_cyan.emitting = false
			if is_instance_valid(_gpu_rising_magenta): _gpu_rising_magenta.emitting = false)
	# rune 은 super 호출 (CPU 텍스트 렌더링 필요)
	if randf() < 0.4 * _scale():
		var foot: Vector2 = _foot_pos()
		_particles.append({
			"pos": Vector2(foot.x + randf_range(-CIRCLE_R * 0.6, CIRCLE_R * 0.6), foot.y - 2.0),
			"vel": Vector2(randf_range(-0.2, 0.2), -0.5 - randf() * 0.5),
			"life": 0.0,
			"max_life": 1.2 + randf() * 0.6,
			"size": 8.0 + randf() * 8.0,
			"kind": "rune",
			"rot": randf() * TAU,
			"spin": randf_range(-0.04, 0.04),
			"glyph": ["◇", "◯", "✦", "✧", "△", "▽"][randi() % 6],
		})

func _spawn_peak_burst() -> void:
	if _peak_made:
		return
	_peak_made = true
	var foot: Vector2 = _foot_pos()
	# mote 40 burst (violet 50% / cyan 25% / magenta 25%)
	var mote_v := _Helpers.make_emitter({
		"count": _pcount(20), "lifetime": 1.3, "color": COL_VIOLET,
		"speed_min": 120.0, "speed_max": 420.0,
		"direction": Vector2.UP, "spread": 180.0,
		"gravity": 64.8, "damping": 3.0,
		"size_min": 1.4, "size_max": 2.8,
		"size_base": 4.0,
		"texture": _Helpers.sparkle_tex(),
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	mote_v.position = Vector2(foot.x, foot.y - 30.0)
	add_child(mote_v)
	var mote_c := _Helpers.make_emitter({
		"count": _pcount(10), "lifetime": 1.3, "color": COL_CYAN,
		"speed_min": 120.0, "speed_max": 420.0,
		"direction": Vector2.UP, "spread": 180.0,
		"gravity": 64.8, "damping": 3.0,
		"size_min": 1.4, "size_max": 2.8,
		"size_base": 4.0,
		"texture": _Helpers.sparkle_tex(),
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	mote_c.position = Vector2(foot.x, foot.y - 30.0)
	add_child(mote_c)
	var mote_m := _Helpers.make_emitter({
		"count": _pcount(10), "lifetime": 1.3, "color": COL_MAGENTA,
		"speed_min": 120.0, "speed_max": 420.0,
		"direction": Vector2.UP, "spread": 180.0,
		"gravity": 64.8, "damping": 3.0,
		"size_min": 1.4, "size_max": 2.8,
		"size_base": 4.0,
		"texture": _Helpers.sparkle_tex(),
		"start_alpha": 1.0, "mid_alpha": 0.5, "end_alpha": 0.0,
	})
	mote_m.position = Vector2(foot.x, foot.y - 30.0)
	add_child(mote_m)
	# haze 16 (큰 안개)
	var haze := _Helpers.make_emitter({
		"count": _pcount(16), "lifetime": 1.3, "color": COL_HAZE,
		"speed_min": 90.0, "speed_max": 240.0,
		"direction": Vector2.UP, "spread": 130.0,
		"gravity": -18.0, "damping": 3.0,
		"size_min": 16.0, "size_max": 30.0,
		"additive": false,
		"start_alpha": 0.5, "mid_alpha": 0.25, "end_alpha": 0.0,
	})
	haze.position = foot
	add_child(haze)
	# rune 10 — super CPU 그대로
	for _i in range(_pcount(10)):
		var a := randf() * TAU
		var sp := 1.0 + randf() * 2.5
		_particles.append({
			"pos": Vector2(foot.x, foot.y - 20.0),
			"vel": Vector2(cos(a) * sp, sin(a) * sp - 1.0),
			"life": 0.0,
			"max_life": 1.2 + randf() * 0.6,
			"size": 10.0 + randf() * 8.0,
			"kind": "rune",
			"rot": randf() * TAU,
			"spin": randf_range(-0.06, 0.06),
			"glyph": ["◇", "◯", "✦", "✧", "△", "▽", "✺"][randi() % 7],
		})
