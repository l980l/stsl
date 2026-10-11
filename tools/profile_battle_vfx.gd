## Rendered A-B-B-A diagnostic for a repeated production FireBlastGPU workload.
## Launch with --audio-driver Dummy in an isolated campaign-bot user directory.
extends SceneTree

const FIRE_BLAST := preload("res://scenes/vfx/fire_blast_gpu.gd")
const GPU_HELPERS := preload("res://scenes/vfx/gpu_particle_helpers.gd")

const PHASE_SECONDS := 3.0
const PHASES: PackedStringArray = ["control_a", "particles_b1", "particles_b2", "control_a2"]
const ATTACK_STARTS: PackedFloat32Array = [0.0, 0.5, 1.0, 1.5]
const SEED := 424242

var _report_path := ""
var _stage: CanvasLayer
var _wait_focus_seconds := 20.0
var _effect_seed_counter := 0

func _init() -> void:
	_parse_args()
	call_deferred("_run")

func _parse_args() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--report="):
			_report_path = arg.trim_prefix("--report=")
		elif arg.begins_with("--wait-focus-seconds="):
			_wait_focus_seconds = maxf(0.0, arg.trim_prefix("--wait-focus-seconds=").to_float())

func _run() -> void:
	# This guard deliberately precedes report creation and every other script write.
	if not _isolated_user_directory():
		print("[profile_battle_vfx] refusing non-isolated user directory")
		quit(1)
		return
	if DisplayServer.get_name() == "headless":
		print("[profile_battle_vfx] refusing headless renderer")
		quit(1)
		return
	if AudioServer.get_driver_name() != "Dummy":
		print("[profile_battle_vfx] launch with --audio-driver Dummy")
		quit(1)
		return
	if _report_path == "":
		_report_path = "user://battle_vfx_profile.json"
	elif not _report_path.begins_with("user://") and not _report_path.is_absolute_path():
		print("[profile_battle_vfx] --report must be absolute or user://")
		quit(1)
		return
	_report_path = ProjectSettings.globalize_path(_report_path) if _report_path.begins_with("user://") else _report_path
	_mute_audio()
	root.show()
	root.grab_focus()
	var focused := await _wait_for_focus()
	if not focused:
		print("[profile_battle_vfx] refusing to measure without a visible focused window")
		quit(1)
		return
	_make_stage()
	var viewport_rid := root.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(viewport_rid, true)
	# Prime the root viewport and generated helper textures before the ABBA samples.
	await process_frame
	await process_frame
	_warm_particle_textures()
	var first_effect := await _warm_effect(viewport_rid)

	var phase_results: Array[Dictionary] = []
	for phase_name in PHASES:
		phase_results.append(await _run_phase(phase_name, phase_name.begins_with("particles"), viewport_rid))
	var all_phases_valid: bool = bool(first_effect.get("valid_focused_measurement", false)) and _all_phases_valid(phase_results)
	var report := {
		"kind": "stsl_battle_vfx_profile_v1",
		"environment": _environment(),
		"workload": {
			"effect": "res://scenes/vfx/fire_blast_gpu.gd",
			"pattern": "ABBA; each B phase plays four fixed-position FireBlastGPU effects at 0.0, 0.5, 1.0, and 1.5 seconds",
			"warmup": "generated particle textures plus a separately recorded first FireBlastGPU run",
			"seed": SEED,
		},
		"first_effect_after_texture_warm": first_effect,
		"phases": phase_results,
		"overall_valid_focused_measurement": all_phases_valid,
		"measurement": "Focused and drawable frames only. Frame interval is wall time; TIME_PROCESS is engine process time; render CPU is root viewport render time plus global frame setup time.",
		"limitations": "This is a production VFX workload, not a full battle scene. OS compositor on-screen visibility is not independently proven by root.visible/focus. The diagnostic temporarily brings its own window to the foreground before and during each phase. GPU timing is reported only when the enabled viewport returns non-zero values; zero values are retained as unavailable/zero rather than interpreted as GPU time.",
	}
	if not _write_report(report):
		await _cleanup_and_quit(1, viewport_rid)
		return
	print("[profile_battle_vfx] %s -> %s" % [_summary(phase_results), _report_path])
	await _cleanup_and_quit(0 if all_phases_valid else 1, viewport_rid)

func _isolated_user_directory() -> bool:
	return ProjectSettings.globalize_path("user://").get_base_dir().get_file().begins_with("STSL-campaign-bot-")

func _mute_audio() -> void:
	var audio := root.get_node_or_null("AudioManager")
	if audio != null:
		audio.set_bus_volume("master", 0.0)
	var master := AudioServer.get_bus_index("Master")
	if master >= 0:
		AudioServer.set_bus_mute(master, true)

func _make_stage() -> void:
	_stage = CanvasLayer.new()
	_stage.layer = 200
	var backdrop := ColorRect.new()
	backdrop.color = Color("171424")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_stage.add_child(backdrop)
	root.add_child(_stage)

func _wait_for_focus() -> bool:
	var started_usec := Time.get_ticks_usec()
	while (Time.get_ticks_usec() - started_usec) / 1000000.0 < _wait_focus_seconds:
		if _is_usable_window_frame():
			return true
		await process_frame
	return _is_usable_window_frame()

func _warm_particle_textures() -> void:
	GPU_HELPERS.circle_tex()
	GPU_HELPERS.sparkle_tex()
	GPU_HELPERS.feather_tex()
	GPU_HELPERS.square_tex()

func _warm_effect(viewport_rid: RID) -> Dictionary:
	_maintain_focus()
	var focused := await _wait_for_focus()
	if not focused:
		return {"valid_focused_measurement": false, "invalid_reason": "could not acquire focus for warm effect"}
	seed(SEED)
	_effect_seed_counter = 0
	var pipeline_before := _pipeline_total()
	var spawn_started_usec := Time.get_ticks_usec()
	_spawn_fire_blast(Vector2(480, 430), Vector2(880, 430))
	var spawn_cpu_ms := (Time.get_ticks_usec() - spawn_started_usec) / 1000.0
	var frames: Array[Dictionary] = []
	var excluded_frames := 0
	var started_usec := Time.get_ticks_usec()
	var previous_usec := started_usec
	while (Time.get_ticks_usec() - started_usec) / 1000000.0 < 2.25:
		_maintain_focus()
		await process_frame
		var now_usec := Time.get_ticks_usec()
		if _is_usable_window_frame():
			frames.append(_frame_sample((now_usec - previous_usec) / 1000.0, viewport_rid))
		else:
			excluded_frames += 1
		previous_usec = now_usec
	var result := _series_stats(frames)
	result["focused_sample_coverage"] = _coverage(frames.size(), excluded_frames)
	result["valid_focused_measurement"] = not frames.is_empty() and result.focused_sample_coverage >= 0.95
	result["effect_node_and_play_cpu_ms"] = spawn_cpu_ms
	result["excluded_unfocused_or_undrawable_frames"] = excluded_frames
	result["pipeline_compilations_delta"] = _pipeline_total() - pipeline_before
	result["gpu_timing_available"] = _has_nonzero(frames, "render_gpu_ms")
	result["frame_samples"] = frames
	result["generated_helper_textures_prewarmed"] = true
	result["limitation"] = "This first-effect sample intentionally excludes generated helper texture creation. effect_node_and_play_cpu_ms is only Node creation plus play scheduling; production emitters are created after the effect's charge delay and are reflected only in frame timing and pipeline delta."
	_clear_effects()
	await process_frame
	return result

func _run_phase(phase_name: String, particles_enabled: bool, viewport_rid: RID) -> Dictionary:
	_maintain_focus()
	var focused := await _wait_for_focus()
	if not focused:
		return _invalid_phase(phase_name, particles_enabled, "could not reacquire focused drawable window")
	seed(SEED)
	_effect_seed_counter = 0
	var frames: Array[Dictionary] = []
	var excluded_frames := 0
	var spawned := 0
	var started_usec := Time.get_ticks_usec()
	var previous_usec := started_usec
	var pipeline_before := _pipeline_total()
	while (Time.get_ticks_usec() - started_usec) / 1000000.0 < PHASE_SECONDS:
		# This is an opt-in diagnostic: retain focus while sampling rather than
		# silently recording compositor-throttled background frames.
		_maintain_focus()
		var elapsed := (Time.get_ticks_usec() - started_usec) / 1000000.0
		while particles_enabled and spawned < ATTACK_STARTS.size() and elapsed >= ATTACK_STARTS[spawned]:
			_spawn_fire_blast(Vector2(260 + spawned * 95, 470), Vector2(1040 + spawned * 65, 430))
			spawned += 1
		await process_frame
		var now_usec := Time.get_ticks_usec()
		if _is_usable_window_frame():
			frames.append(_frame_sample((now_usec - previous_usec) / 1000.0, viewport_rid))
		else:
			excluded_frames += 1
		previous_usec = now_usec
	var pipeline_after := _pipeline_total()
	_clear_effects()
	await process_frame
	var series := _series_stats(frames)
	series["name"] = phase_name
	series["particles_enabled"] = particles_enabled
	series["attack_instances"] = spawned
	series["focused_sample_coverage"] = _coverage(frames.size(), excluded_frames)
	series["valid_focused_measurement"] = not frames.is_empty() and series.focused_sample_coverage >= 0.95
	series["excluded_unfocused_or_undrawable_frames"] = excluded_frames
	series["pipeline_compilations_delta"] = pipeline_after - pipeline_before
	series["gpu_timing_available"] = _has_nonzero(frames, "render_gpu_ms")
	series["frame_samples"] = frames
	return series

func _spawn_fire_blast(caster: Vector2, target: Vector2) -> void:
	var effect := FIRE_BLAST.new()
	var effect_seed := SEED + _effect_seed_counter
	_effect_seed_counter += 1
	effect.child_entered_tree.connect(_seed_particle_child.bind(effect_seed))
	effect._particle_scale_override = 1.0
	_stage.add_child(effect)
	effect.play(caster, target)

func _seed_particle_child(node: Node, effect_seed: int) -> void:
	_configure_particle_seed(node, effect_seed)

func _configure_particle_seed(node: Node, effect_seed: int) -> void:
	if node is GPUParticles2D:
		node.use_fixed_seed = true
		node.seed = effect_seed
	for child in node.get_children():
		_configure_particle_seed(child, effect_seed)

func _clear_effects() -> void:
	if _stage == null:
		return
	for child in _stage.get_children():
		if child is Node2D:
			child.queue_free()

func _is_usable_window_frame() -> bool:
	return root.visible and root.can_draw() and root.has_focus() and DisplayServer.window_is_focused(root.get_window_id()) and root.mode != Window.MODE_MINIMIZED

func _maintain_focus() -> void:
	DisplayServer.window_move_to_foreground(root.get_window_id())
	root.grab_focus()

func _frame_sample(interval_ms: float, viewport_rid: RID) -> Dictionary:
	return {
		"interval_ms": interval_ms,
		"process_ms": Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
		"render_viewport_cpu_ms": RenderingServer.viewport_get_measured_render_time_cpu(viewport_rid),
		"render_frame_setup_cpu_ms": RenderingServer.get_frame_setup_time_cpu(),
		"render_gpu_ms": RenderingServer.viewport_get_measured_render_time_gpu(viewport_rid),
		"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		"objects": Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
		"pipeline_compilations_total": _pipeline_total(),
	}

func _pipeline_total() -> float:
	return Performance.get_monitor(Performance.PIPELINE_COMPILATIONS_CANVAS) \
		+ Performance.get_monitor(Performance.PIPELINE_COMPILATIONS_SURFACE) \
		+ Performance.get_monitor(Performance.PIPELINE_COMPILATIONS_DRAW) \
		+ Performance.get_monitor(Performance.PIPELINE_COMPILATIONS_SPECIALIZATION)

func _series_stats(frames: Array[Dictionary]) -> Dictionary:
	var fields := ["interval_ms", "process_ms", "render_viewport_cpu_ms", "render_frame_setup_cpu_ms", "render_gpu_ms", "draw_calls", "objects"]
	var result := {"included_frames": frames.size()}
	for field in fields:
		var values: Array[float] = []
		for frame in frames:
			values.append(float(frame[field]))
		result[field] = _stats(values)
	return result

func _stats(values: Array[float]) -> Dictionary:
	var sorted := values.duplicate()
	sorted.sort()
	return {
		"count": sorted.size(),
		"p50": _percentile(sorted, 0.50),
		"p95": _percentile(sorted, 0.95),
		"max": sorted.back() if not sorted.is_empty() else 0.0,
	}

func _percentile(values: Array, quantile: float) -> float:
	return values[clampi(int(ceil(values.size() * quantile)) - 1, 0, values.size() - 1)] if not values.is_empty() else 0.0

func _has_nonzero(frames: Array[Dictionary], field: String) -> bool:
	for frame in frames:
		if float(frame[field]) > 0.0:
			return true
	return false

func _coverage(included: int, excluded: int) -> float:
	var total := included + excluded
	return float(included) / float(total) if total > 0 else 0.0

func _invalid_phase(phase_name: String, particles_enabled: bool, reason: String) -> Dictionary:
	var empty := _series_stats([])
	empty["name"] = phase_name
	empty["particles_enabled"] = particles_enabled
	empty["attack_instances"] = 0
	empty["excluded_unfocused_or_undrawable_frames"] = 0
	empty["focused_sample_coverage"] = 0.0
	empty["pipeline_compilations_delta"] = 0
	empty["gpu_timing_available"] = false
	empty["frame_samples"] = []
	empty["valid_focused_measurement"] = false
	empty["invalid_reason"] = reason
	return empty

func _all_phases_valid(phases: Array[Dictionary]) -> bool:
	for phase in phases:
		if not phase.valid_focused_measurement:
			return false
	return true

func _environment() -> Dictionary:
	return {
		"godot": Engine.get_version_info().get("string", ""),
		"os": OS.get_name(),
		"display_server": DisplayServer.get_name(),
		"renderer": RenderingServer.get_current_rendering_method(),
		"rendering_driver": RenderingServer.get_current_rendering_driver_name(),
		"audio_driver": AudioServer.get_driver_name(),
		"window_visible": root.visible,
		"window_focused": root.has_focus(),
		"window_drawable": root.can_draw(),
		"window_size": [root.size.x, root.size.y],
		"viewport_size": [root.get_visible_rect().size.x, root.get_visible_rect().size.y],
	}

func _summary(phases: Array[Dictionary]) -> String:
	var parts: Array[String] = []
	for phase in phases:
		if phase.valid_focused_measurement:
			var gpu_text := "gpu unavailable/zero"
			if phase.gpu_timing_available:
				gpu_text = "gpu p50=%.3fms" % phase.render_gpu_ms.p50
			parts.append("%s frame p50=%.3fms %s" % [phase.name, phase.interval_ms.p50, gpu_text])
		else:
			parts.append("%s invalid-focus" % phase.name)
	return "; ".join(parts)

func _write_report(report: Dictionary) -> bool:
	DirAccess.make_dir_recursive_absolute(_report_path.get_base_dir())
	var file := FileAccess.open(_report_path, FileAccess.WRITE)
	if file == null:
		push_error("[profile_battle_vfx] cannot write report: " + _report_path)
		return false
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	return true

func _cleanup_and_quit(exit_code: int, viewport_rid: RID) -> void:
	_clear_effects()
	if _stage != null:
		_stage.queue_free()
	RenderingServer.viewport_set_measure_render_time(viewport_rid, false)
	GPU_HELPERS.release_cached_textures()
	for shape in range(Input.CURSOR_ARROW, Input.CURSOR_HELP + 1):
		Input.set_custom_mouse_cursor(null, shape)
	var sacred_theme := root.get_node_or_null("SacredTheme")
	if sacred_theme != null:
		sacred_theme._cursor_textures_cache.clear()
		sacred_theme._cursor_hotspots_cache.clear()
	var audio := root.get_node_or_null("AudioManager")
	if audio != null:
		for node in audio.get_children():
			if node is AudioStreamPlayer or node is AudioStreamPlayer2D:
				node.stop()
				node.stream = null
			elif node is Timer:
				node.stop()
	await process_frame
	quit(exit_code)
