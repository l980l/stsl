# scenes/components/scene_critters.gd
# 인터랙티브 요소 — 새 (가끔 화면 가로지름) + 별똥별 (밤 한정).
# 1차 PR: 새 + 별똥별. 후속: 폭포/사람/동물.
class_name SceneCritters
extends Node2D

const W := 1920.0
const HORIZON_Y := 270.0
const BIRD_TEX := preload("res://assets/art/backgrounds/critters/bird.svg")

var _env: Dictionary = {}
var _timer: Timer = null
var _active: int = 0

func setup(env: Dictionary) -> void:
	_env = env
	if _timer == null:
		_timer = Timer.new()
		_timer.one_shot = true
		_timer.timeout.connect(_on_tick)
		add_child(_timer)
	_schedule_next()

func _schedule_next() -> void:
	if _timer == null:
		return
	_timer.wait_time = randf_range(5.0, 15.0)
	_timer.start()

func _on_tick() -> void:
	if _active >= 3:
		_schedule_next()
		return
	# 환경에 따라 새/별똥별 비율
	var time_of_day: String = _env.get("time_of_day", "day")
	var weather: String = _env.get("weather", "clear")
	if time_of_day == "night" and weather != "overcast" and randf() < 0.4:
		_spawn_shooting_star()
	else:
		_spawn_bird()
	_schedule_next()

func _spawn_bird() -> void:
	var spr := Sprite2D.new()
	spr.texture = BIRD_TEX
	var dir: int = 1 if randf() < 0.5 else -1  # 좌→우 or 우→좌
	var start_x: float = -80.0 if dir == 1 else W + 80.0
	var end_x: float = W + 80.0 if dir == 1 else -80.0
	var y_start: float = randf_range(80.0, HORIZON_Y - 20.0)
	var y_mid: float = y_start + randf_range(-40.0, 30.0)
	var y_end: float = y_start + randf_range(-30.0, 40.0)
	spr.scale = Vector2(0.7 * dir, 0.7)
	spr.position = Vector2(start_x, y_start)
	spr.modulate.a = 0.0
	add_child(spr)
	_active += 1
	var dur: float = randf_range(8.0, 14.0)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(spr, "modulate:a", 0.85, 1.0)
	# 곡선 비행 — 3 단계 보간
	var step_dur: float = dur / 2.0
	tw.tween_property(spr, "position:x", (start_x + end_x) * 0.5, step_dur)
	tw.tween_property(spr, "position:y", y_mid, step_dur)
	tw.chain().set_parallel(true)
	tw.tween_property(spr, "position:x", end_x, step_dur)
	tw.tween_property(spr, "position:y", y_end, step_dur)
	tw.tween_property(spr, "modulate:a", 0.0, 1.0).set_delay(step_dur - 1.0)
	tw.chain().tween_callback(func() -> void:
		spr.queue_free()
		_active = max(0, _active - 1))

func _spawn_shooting_star() -> void:
	var line := Line2D.new()
	line.width = 2.5
	line.default_color = Color(1.0, 0.95, 0.85, 0.9)
	var x0: float = randf_range(W * 0.2, W * 0.8)
	var y0: float = randf_range(40.0, 140.0)
	var len: float = randf_range(180.0, 280.0)
	var ang: float = randf_range(PI * 0.20, PI * 0.40)  # 우하향
	var dx: float = cos(ang) * len
	var dy: float = sin(ang) * len
	line.points = PackedVector2Array([Vector2(x0, y0), Vector2(x0 + dx * 0.05, y0 + dy * 0.05)])
	add_child(line)
	_active += 1
	var tw := create_tween()
	tw.tween_method(func(t: float) -> void:
		var p1 := Vector2(x0, y0) + Vector2(dx, dy) * (t - 0.15)
		var p2 := Vector2(x0, y0) + Vector2(dx, dy) * t
		line.points = PackedVector2Array([p1, p2]),
		0.05, 1.0, 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(line, "modulate:a", 0.0, 0.3)
	tw.tween_callback(func() -> void:
		line.queue_free()
		_active = max(0, _active - 1))
