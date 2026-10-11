extends SceneTree

const TARGET_SCENE := "res://scenes/chapter_select/chapter_select_scene.tscn"

var failed := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failed += 1
		printerr("FAIL: " + message)

func _wait_for_scene(path: String, seconds: float = 5.0) -> bool:
	var deadline := Time.get_ticks_msec() + int(seconds * 1000.0)
	while (current_scene == null or current_scene.scene_file_path != path) and Time.get_ticks_msec() < deadline:
		await process_frame
	return current_scene != null and current_scene.scene_file_path == path

func _wait_for_overlay_clear(transition, seconds: float = 5.0) -> bool:
	var deadline := Time.get_ticks_msec() + int(seconds * 1000.0)
	while transition._overlay.mouse_filter != Control.MOUSE_FILTER_IGNORE and Time.get_ticks_msec() < deadline:
		await process_frame
	return transition._overlay.mouse_filter == Control.MOUSE_FILTER_IGNORE

func _run() -> void:
	var user_dir := ProjectSettings.globalize_path("user://scene-transition-test.guard").get_base_dir()
	if not user_dir.get_file().begins_with("STSL-transition-test-"):
		printerr("Use an isolated STSL-transition-test-* user directory.")
		quit(2)
		return
	var transition = root.get_node_or_null("SceneTransition")
	_check(transition != null, "SceneTransition autoload exists")
	if transition == null:
		quit(1)
		return

	await transition.go(TARGET_SCENE)
	_check(transition._overlay.mouse_filter == Control.MOUSE_FILTER_STOP, "input stays blocked while fading")
	_check(await _wait_for_scene(TARGET_SCENE), "scene transition completes")
	_check(await _wait_for_overlay_clear(transition), "overlay input gate is released after transition")
	_check(transition._overlay.modulate.a < 0.001, "overlay fades back in after transition")
	var missing_path := "res://tests/does_not_exist.tscn"
	var outgoing_scene = current_scene
	await transition.go(missing_path)
	_check(transition.last_transition_error != OK, "invalid path reports a transition failure")
	_check(current_scene == outgoing_scene, "invalid path restores the outgoing scene")
	_check(await _wait_for_overlay_clear(transition), "invalid path releases the input gate after restoration")
	print("Scene transition recovery: ", "PASS" if failed == 0 else "FAIL")
	await process_frame
	await process_frame
	quit(1 if failed else 0)
