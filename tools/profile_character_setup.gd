## Rendered character setup diagnostic. Launch with --audio-driver Dummy in an isolated user directory.
## Measures synchronous CPU wall time only; each sample is shown for one frame to exercise rendering.
extends SceneTree

const ENEMY_SCENE := preload("res://characters/enemies/enemy_placeholder.tscn")
const HERO_SCENE := preload("res://characters/heroes/cleopatra/cleopatra.tscn")
const CHARACTER_ART_CACHE := preload("res://characters/character_art_cache.gd")
const ENEMY_ID := "enemy.egyptian.scarab"
const DISTINCT_ENEMY_IDS := [
	"enemy.egyptian.scarab",
	"enemy.egyptian.desert_scorpion",
	"enemy.egyptian.sand_scout",
	"enemy.egyptian.sand_wraith",
	"enemy.egyptian.pyramid_golem",
]
const SAMPLES := 5

var _report_path := ""

func _init() -> void:
	_parse_args()
	call_deferred("_run")

func _parse_args() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--report="):
			_report_path = arg.trim_prefix("--report=")

func _run() -> void:
	# This guard deliberately precedes report-directory creation and every other script write.
	if not _isolated_user_directory():
		print("[profile_character_setup] refusing non-isolated user directory")
		quit(1)
		return
	if DisplayServer.get_name() == "headless":
		print("[profile_character_setup] refusing headless renderer")
		quit(1)
		return
	if AudioServer.get_driver_name() != "Dummy":
		print("[profile_character_setup] launch with --audio-driver Dummy")
		quit(1)
		return
	if _report_path == "":
		_report_path = "user://character_setup_profile.json"
	elif not _report_path.begins_with("user://") and not _report_path.is_absolute_path():
		print("[profile_character_setup] --report must be absolute or user://")
		quit(1)
		return
	_report_path = ProjectSettings.globalize_path(_report_path) if _report_path.begins_with("user://") else _report_path
	_mute_audio()
	root.show()
	root.grab_focus()
	await process_frame

	var hero_add_ready := await _add_ready_samples(HERO_SCENE, "Cleopatra")
	var enemy_add_ready := await _add_ready_samples(ENEMY_SCENE, "EnemyPlaceholder")
	var scarab_load := await _enemy_id_samples([ENEMY_ID, ENEMY_ID, ENEMY_ID, ENEMY_ID, ENEMY_ID])
	var distinct_load := await _enemy_id_samples(DISTINCT_ENEMY_IDS)
	var report := {
		"kind": "stsl_character_setup_profile_v1",
		"environment": _environment(),
		"enemy_id": ENEMY_ID,
		"enemy_art_path": "res://assets/art/enemies/egyptian_scarab.png",
		"samples": {
			"count": SAMPLES,
			"hero_cleopatra_instantiate_add_ready": _stats(hero_add_ready),
			"enemy_instantiate_add_ready": _stats(enemy_add_ready),
			"enemy_set_id_scarab_repeated": _stats(scarab_load),
			"enemy_set_id_distinct_art": _stats(distinct_load),
			"scarab_first_ms": scarab_load[0] if not scarab_load.is_empty() else 0.0,
			"scarab_repeat_warm": _stats(scarab_load.slice(1)),
		},
		"distinct_enemy_ids": DISTINCT_ENEMY_IDS,
		"measurement": "Time.get_ticks_usec synchronous CPU wall time including node construction, _ready work, and render submission",
		"limitations": "Each node remains rendered for one frame after measurement, but this is not GPU completion time or proof of whole-battle causality. Resource caching, shader compilation, drivers, and unrelated process work can affect wall time."
	}
	if not _write_report(report):
		await _cleanup_and_quit(1)
		return
	print("[profile_character_setup] n=%d hero add/ready p50=%.3fms enemy add/ready p50=%.3fms scarab first=%.3fms warm p50=%.3fms distinct p50=%.3fms -> %s" % [SAMPLES, report.samples.hero_cleopatra_instantiate_add_ready.p50_ms, report.samples.enemy_instantiate_add_ready.p50_ms, report.samples.scarab_first_ms, report.samples.scarab_repeat_warm.p50_ms, report.samples.enemy_set_id_distinct_art.p50_ms, _report_path])
	await _cleanup_and_quit(0)

func _add_ready_samples(scene: PackedScene, label: String) -> Array[float]:
	var values: Array[float] = []
	for sample in SAMPLES:
		var started := Time.get_ticks_usec()
		var character := scene.instantiate()
		character.name = label
		character.position = Vector2(200 + sample * 140, 240)
		root.add_child(character)
		values.append((Time.get_ticks_usec() - started) / 1000.0)
		await process_frame
		character.queue_free()
		await process_frame
	return values

func _enemy_id_samples(enemy_ids: Array) -> Array[float]:
	var values: Array[float] = []
	for sample in enemy_ids.size():
		var enemy := ENEMY_SCENE.instantiate()
		enemy.position = Vector2(200 + sample * 140, 420)
		root.add_child(enemy)
		var started := Time.get_ticks_usec()
		enemy.set_enemy_id(enemy_ids[sample])
		values.append((Time.get_ticks_usec() - started) / 1000.0)
		await process_frame
		enemy.queue_free()
		await process_frame
	return values

func _isolated_user_directory() -> bool:
	return ProjectSettings.globalize_path("user://").get_base_dir().get_file().begins_with("STSL-campaign-bot-")

func _mute_audio() -> void:
	var audio := root.get_node_or_null("AudioManager")
	if audio != null:
		audio.set_bus_volume("master", 0.0)
	var master := AudioServer.get_bus_index("Master")
	if master >= 0:
		AudioServer.set_bus_mute(master, true)

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
		push_error("[profile_character_setup] cannot write report: " + _report_path)
		return false
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	return true

func _cleanup_and_quit(exit_code: int) -> void:
	CHARACTER_ART_CACHE.clear()
	var audio := root.get_node_or_null("AudioManager")
	if audio != null:
		for node in audio.get_children():
			if node is AudioStreamPlayer or node is AudioStreamPlayer2D:
				node.stop()
				node.stream = null
			elif node is Timer:
				node.stop()
	for shape in range(Input.CURSOR_ARROW, Input.CURSOR_HELP + 1):
		Input.set_custom_mouse_cursor(null, shape)
	var sacred_theme := root.get_node_or_null("SacredTheme")
	if sacred_theme != null:
		sacred_theme._cursor_textures_cache.clear()
		sacred_theme._cursor_hotspots_cache.clear()
	await process_frame
	quit(exit_code)
