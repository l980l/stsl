extends Node
# Wall-clock frame intervals, not GPU execution times. Attach only in the test bot.
var _file: FileAccess
var _last_usec: int = 0
var _frames: Array[float] = []
var _slow_33: int = 0
var _slow_50: int = 0
var _action: String = "startup"
var _action_context: Dictionary = {}
var _write_error: String = ""
var _groups: Dictionary = {}
var _last_window_state := ""
var _last_scene := ""

func configure(path: String) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	_file = FileAccess.open(path, FileAccess.WRITE)
	if _file == null:
		_write_error = "Cannot open frame journal: " + path
	process_mode = Node.PROCESS_MODE_ALWAYS
	_last_usec = Time.get_ticks_usec()

func mark_action(label: String, context: Dictionary = {}) -> void:
	_action = label
	_action_context = context.duplicate(true)
	_write({"event": "action", "action": label, "context": _action_context, "at_usec": Time.get_ticks_usec()})

func _process(_delta: float) -> void:
	var now := Time.get_ticks_usec()
	if _last_usec == 0:
		_last_usec = now
		return
	var elapsed_ms: float = (now - _last_usec) / 1000.0
	_last_usec = now
	var window := get_tree().root
	var state := _classify_window(DisplayServer.get_name() == "headless", window.visible, window.mode == Window.MODE_MINIMIZED, window.has_focus())
	var scene := get_tree().current_scene
	var scene_path: String = scene.scene_file_path if scene else ""
	# An interval crossing a focus/scene boundary is not a steady-play sample.
	var interval_state := state if _last_window_state == "" or _last_window_state == state else "mixed"
	var interval_scene := scene_path if _last_scene == scene_path else "transition"
	_record_sample(elapsed_ms, interval_scene, interval_state)
	if state != _last_window_state:
		_write({"event": "window_state", "state": state, "at_usec": now, "frame": _frames.size(),
			"visible": window.visible, "can_draw": window.can_draw(), "focused": window.has_focus(),
			"window_size": [window.size.x, window.size.y]})
	_last_window_state = state
	_last_scene = scene_path
	if elapsed_ms > 33.333:
		var gm := get_tree().root.get_node("GameManager")
		_write({"event": "slow_frame", "frame": _frames.size(), "at_usec": now,
			"wall_ms": elapsed_ms, "last_action": _action, "action_context": _action_context,
			"scene": scene_path, "interval_scene": interval_scene, "window_state": interval_state,
			"chapter": gm.current_chapter, "act": gm.current_act, "floor": gm.current_floor,
			"process_ms": Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
			"nodes": Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
			"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)})

static func _classify_window(headless: bool, visible: bool, minimized: bool, focused: bool) -> String:
	if headless:
		return "headless"
	if not visible:
		return "hidden"
	if minimized:
		return "minimized"
	return "focused" if focused else "unfocused"

func _record_sample(elapsed_ms: float, scene: String, state: String) -> void:
	_frames.append(elapsed_ms)
	if elapsed_ms > 33.333:
		_slow_33 += 1
	if elapsed_ms > 50.0:
		_slow_50 += 1
	var key := scene + "|" + state
	if not _groups.has(key):
		_groups[key] = {"scene": scene, "window_state": state, "values": [], "over_33": 0, "over_50": 0}
	var group: Dictionary = _groups[key]
	group.values.append(elapsed_ms)
	group.over_33 += int(elapsed_ms > 33.333)
	group.over_50 += int(elapsed_ms > 50.0)

func _write(record: Dictionary) -> void:
	if _file:
		_file.store_line(JSON.stringify(record))

func summary() -> Dictionary:
	if _file:
		_file.flush()
	var ordered := _frames.duplicate()
	ordered.sort()
	var groups: Array[Dictionary] = []
	for key in _groups:
		var group: Dictionary = _groups[key]
		var values: Array = group.values.duplicate()
		values.sort()
		groups.append({"scene": group.scene, "window_state": group.window_state, "frames": values.size(),
			"p50_ms": _percentile(values, 0.50), "p95_ms": _percentile(values, 0.95),
			"p99_ms": _percentile(values, 0.99), "max_ms": values.back(),
			"over_33ms_frames": group.over_33, "over_50ms_frames": group.over_50})
	return {"metric": "wall_clock_frame_interval_ms", "frames": ordered.size(),
		"p50_ms": _percentile(ordered, 0.50), "p95_ms": _percentile(ordered, 0.95),
		"p99_ms": _percentile(ordered, 0.99), "max_ms": ordered.back() if not ordered.is_empty() else 0,
		"over_33ms_frames": _slow_33, "over_50ms_frames": _slow_50,
		"display_server": DisplayServer.get_name(), "write_error": _write_error, "scene_window_groups": groups,
		"interpretation": "Includes startup, transitions, VSync and OS scheduling; not GPU time. Headless/accelerated runs are not player FPS evidence."}

func _percentile(values: Array, quantile: float) -> float:
	if values.is_empty():
		return 0.0
	return values[clampi(int(ceil(values.size() * quantile)) - 1, 0, values.size() - 1)]
