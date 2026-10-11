extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if not ProjectSettings.globalize_path("user://").get_base_dir().get_file().begins_with("STSL-campaign-bot-"):
		printerr("Use a fresh isolated campaign-bot project")
		quit(2)
		return
	var probe = load("res://tools/campaign_frame_probe.gd").new()
	root.add_child(probe)
	probe.configure("user://frame-probe-test.jsonl")
	probe.set_process(false)
	probe.mark_action("test_card", {"action_index": 7, "card": "fixture"})
	probe._record_sample(10.0, "battle", "focused")
	probe._record_sample(20.0, "battle", "focused")
	probe._record_sample(40.0, "battle", "unfocused")
	probe._record_sample(60.0, "transition", "mixed")
	var result: Dictionary = probe.summary()
	var ok: bool = result.frames == 4 and result.p50_ms == 20.0 \
		and result.p95_ms == 60.0 and result.max_ms == 60.0 \
		and result.over_33ms_frames == 2 and result.over_50ms_frames == 1 \
		and result.write_error == ""
	ok = ok and result.scene_window_groups.size() == 3
	ok = ok and result.scene_window_groups[0].frames == 2 and result.scene_window_groups[0].p95_ms == 20.0
	ok = ok and result.scene_window_groups[1].over_33ms_frames == 1
	ok = ok and result.scene_window_groups[2].over_50ms_frames == 1
	ok = ok and probe._classify_window(true, true, false, true) == "headless"
	ok = ok and probe._classify_window(false, false, false, false) == "hidden"
	ok = ok and probe._classify_window(false, true, true, false) == "minimized"
	ok = ok and probe._classify_window(false, true, false, true) == "focused"
	ok = ok and probe._classify_window(false, true, false, false) == "unfocused"
	var line := FileAccess.get_file_as_string("user://frame-probe-test.jsonl")
	ok = ok and JSON.parse_string(line).action == "test_card"
	ok = ok and JSON.parse_string(line).context.action_index == 7 and probe._action_context.card == "fixture"
	print("Campaign frame probe: ", "PASS" if ok else "FAIL")
	probe.queue_free()
	await process_frame
	quit(0 if ok else 1)
