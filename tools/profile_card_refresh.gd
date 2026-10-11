## Rendered card-refresh diagnostic. Launch with --audio-driver Dummy in an isolated user directory.
extends SceneTree

const CARD_SCENE := preload("res://scenes/card/card_scene_v2.tscn")
const CARD_SCRIPT := preload("res://scenes/card/card_scene_v2.gd")
const CLEOPATRA := preload("res://resources/cards/cards_cleopatra.gd")
const GPU_HELPERS := preload("res://scenes/vfx/gpu_particle_helpers.gd")

const SAMPLES := 20
var _report_path := ""
var _cards: Array[Node] = []

func _init() -> void:
	_parse_args()
	call_deferred("_run")

func _parse_args() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--report="):
			_report_path = arg.trim_prefix("--report=")

func _run() -> void:
	# The guard deliberately precedes report-directory creation and every other script write.
	if not _isolated_user_directory():
		print("[profile_card_refresh] refusing non-isolated user directory")
		quit(1)
		return
	if DisplayServer.get_name() == "headless":
		print("[profile_card_refresh] refusing headless renderer")
		quit(1)
		return
	if AudioServer.get_driver_name() != "Dummy":
		print("[profile_card_refresh] launch with --audio-driver Dummy")
		quit(1)
		return
	if _report_path == "":
		_report_path = "user://card_refresh_profile.json"
	elif not _report_path.begins_with("user://") and not _report_path.is_absolute_path():
		print("[profile_card_refresh] --report must be absolute or user://")
		quit(1)
		return
	_report_path = ProjectSettings.globalize_path(_report_path) if _report_path.begins_with("user://") else _report_path
	_mute_audio()
	root.show()
	root.grab_focus()
	var starter: Array = CLEOPATRA.starter_deck()
	for index in mini(5, starter.size()):
		var card := CARD_SCENE.instantiate()
		card.position = Vector2(16 + index * 204, 16)
		root.add_child(card)
		_cards.append(card)
	await process_frame
	for index in _cards.size():
		_cards[index].setup(starter[index], CARD_SCRIPT.Mode.REWARD)
	await process_frame
	# The initial setup above warms real node styles, labels, and generated textures.
	for card in _cards:
		card.refresh()
	await process_frame
	var cost_samples := await _circle_samples(_cards[0], false)
	var gem_samples := await _circle_samples(_cards[0], true)
	var refresh_samples := await _refresh_samples()
	var report := {
		"kind": "stsl_card_refresh_profile_v1",
		"environment": _environment(),
		"samples": {"count": SAMPLES, "cost_circle": _stats(cost_samples), "gem_circle": _stats(gem_samples),
			"five_card_refresh_batch": _stats(refresh_samples)},
		"measurement": "Time.get_ticks_usec CPU method wall time including submission",
		"limitations": "Not GPU completion time and not evidence of full-battle causality; frame pacing, drivers, and unrelated process work can affect wall time."
	}
	if not _write_report(report):
		await _cleanup_and_quit(1)
		return
	print("[profile_card_refresh] n=%d cost p50/p95/max=%.3f/%.3f/%.3fms gem=%.3f/%.3f/%.3fms refresh5=%.3f/%.3f/%.3fms -> %s" % [SAMPLES, _stats(cost_samples).p50_ms, _stats(cost_samples).p95_ms, _stats(cost_samples).max_ms, _stats(gem_samples).p50_ms, _stats(gem_samples).p95_ms, _stats(gem_samples).max_ms, _stats(refresh_samples).p50_ms, _stats(refresh_samples).p95_ms, _stats(refresh_samples).max_ms, _report_path])
	await _cleanup_and_quit(0)

func _isolated_user_directory() -> bool:
	return ProjectSettings.globalize_path("user://").get_base_dir().get_file().begins_with("STSL-campaign-bot-")

func _mute_audio() -> void:
	var audio := root.get_node_or_null("AudioManager")
	if audio != null:
		audio.set_bus_volume("master", 0.0)
	var master := AudioServer.get_bus_index("Master")
	if master >= 0:
		AudioServer.set_bus_mute(master, true)

func _circle_samples(card: Node, gem: bool) -> Array[float]:
	var values: Array[float] = []
	for _sample in SAMPLES:
		var started := Time.get_ticks_usec()
		if gem:
			card._make_circle_texture(Color("#ffffff"), Color("#e5e0d2"), Color("#8b8676"), Color("#c9a447"), 0.08, 64, 0.65)
		else:
			card._make_circle_texture(Color(0.96, 0.94, 0.90, 1.0), Color("#070710"), Color("#070710"), Color("#c9a447"), 0.04, 64, 0.25)
		values.append((Time.get_ticks_usec() - started) / 1000.0)
		await process_frame
	return values

func _refresh_samples() -> Array[float]:
	var values: Array[float] = []
	for _sample in SAMPLES:
		var started := Time.get_ticks_usec()
		for card in _cards:
			card.refresh()
		values.append((Time.get_ticks_usec() - started) / 1000.0)
		await process_frame
	return values

func _stats(values: Array[float]) -> Dictionary:
	var sorted := values.duplicate()
	sorted.sort()
	return {"count": sorted.size(), "p50_ms": _percentile(sorted, 0.50), "p95_ms": _percentile(sorted, 0.95), "max_ms": sorted.back() if not sorted.is_empty() else 0.0}

func _percentile(values: Array, quantile: float) -> float:
	return values[clampi(int(ceil(values.size() * quantile)) - 1, 0, values.size() - 1)] if not values.is_empty() else 0.0

func _environment() -> Dictionary:
	return {"godot": Engine.get_version_info().get("string", ""), "os": OS.get_name(), "display_server": DisplayServer.get_name(), "renderer": RenderingServer.get_current_rendering_method(), "audio_driver": AudioServer.get_driver_name(), "window_visible": root.visible, "window_focused": root.has_focus(), "window_size": [root.size.x, root.size.y], "viewport_size": [root.get_visible_rect().size.x, root.get_visible_rect().size.y]}

func _write_report(report: Dictionary) -> bool:
	DirAccess.make_dir_recursive_absolute(_report_path.get_base_dir())
	var file := FileAccess.open(_report_path, FileAccess.WRITE)
	if file == null:
		push_error("[profile_card_refresh] cannot write report: " + _report_path)
		return false
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	return true

func _cleanup_and_quit(exit_code: int) -> void:
	for card in _cards:
		card.queue_free()
	_cards.clear()
	var audio := root.get_node_or_null("AudioManager")
	if audio != null:
		for node in audio.get_children():
			if node is AudioStreamPlayer or node is AudioStreamPlayer2D:
				node.stop()
				node.stream = null
			elif node is Timer:
				node.stop()
	await process_frame
	GPU_HELPERS.release_cached_textures()
	CARD_SCRIPT.release_cached_textures()
	for shape in range(Input.CURSOR_ARROW, Input.CURSOR_HELP + 1):
		Input.set_custom_mouse_cursor(null, shape)
	var sacred_theme := root.get_node_or_null("SacredTheme")
	if sacred_theme != null:
		sacred_theme._cursor_textures_cache.clear()
		sacred_theme._cursor_hotspots_cache.clear()
	await process_frame
	quit(exit_code)
