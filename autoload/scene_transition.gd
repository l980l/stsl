# autoload/scene_transition.gd
extends CanvasLayer

signal transition_failed(path: String, error: Error)

const BATTLE_PATH := "res://scenes/battle/battle_scene.tscn"
const ART_CACHE := preload("res://characters/character_art_cache.gd")

var _overlay: ColorRect
var _tween: Tween = null
var last_transition_error: Error = OK
var _battle_scene: PackedScene
var _loading_bar: ProgressBar
var last_art_preparation: Dictionary = {}

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_overlay = ColorRect.new()
	_overlay.color = SacredPalette.INK_1000
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.modulate.a = 1.0
	add_child(_overlay)
	_loading_bar = ProgressBar.new()
	_loading_bar.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_loading_bar.offset_left = -100
	_loading_bar.offset_right = 100
	_loading_bar.offset_top = -3
	_loading_bar.offset_bottom = 3
	_loading_bar.show_percentage = false
	_loading_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_loading_bar.hide()
	_overlay.add_child(_loading_bar)
	_fade_in(0.30)
	# Defer until all autoloads exist. Retain only this frequently used scene;
	# synchronous parsing happens at startup, not on the first battle click.
	call_deferred("_warm_battle_scene")

func _warm_battle_scene() -> void:
	var started_usec := Time.get_ticks_usec()
	_battle_scene = load(BATTLE_PATH) as PackedScene
	if OS.get_environment("STSL_PROFILE_CPU") == "1":
		print("[stsl_cpu] ", JSON.stringify({"stage": "startup.warm_battle_scene",
			"ms": (Time.get_ticks_usec() - started_usec) / 1000.0}))

func _exit_tree() -> void:
	_battle_scene = null
	ART_CACHE.clear()

func _prepare_battle_art() -> void:
	var paths := ART_CACHE.battle_paths(TeamManager.heroes, GameManager.pending_enemies)
	var missing: Array[String] = []
	for path in paths:
		if not ART_CACHE.has_texture(path):
			missing.append(path)
	var started_usec := Time.get_ticks_usec()
	if not missing.is_empty():
		_loading_bar.max_value = missing.size()
		_loading_bar.value = 0
		_loading_bar.show()
		# Present the opaque transition before synchronous texture work. One
		# texture per frame avoids a single combined hitch; this is not threading.
		await get_tree().process_frame
		await get_tree().process_frame
		for path in missing:
			ART_CACHE.get_texture(path)
			_loading_bar.value += 1
			await get_tree().process_frame
	_loading_bar.hide()
	last_art_preparation = {"paths": paths, "cold_count": missing.size(),
		"ms": (Time.get_ticks_usec() - started_usec) / 1000.0}
	if OS.get_environment("STSL_PROFILE_CPU") == "1":
		print("[stsl_cpu] ", JSON.stringify({"stage": "transition.prepare_art",
			"details": last_art_preparation}))

func go(path: String) -> void:
	last_transition_error = OK
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_overlay, "modulate:a", 1.0, 0.22) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await _tween.finished
	if path == BATTLE_PATH:
		await _prepare_battle_art()
	var started_usec := Time.get_ticks_usec()
	var scene_change_error: Error
	if path == BATTLE_PATH and _battle_scene != null:
		scene_change_error = get_tree().change_scene_to_packed(_battle_scene)
	else:
		scene_change_error = get_tree().change_scene_to_file(path)
	if OS.get_environment("STSL_PROFILE_CPU") == "1":
		print("[stsl_cpu] ", JSON.stringify({"stage": "transition.change_scene", "path": path,
			"ms": (Time.get_ticks_usec() - started_usec) / 1000.0}))
	if scene_change_error != OK:
		last_transition_error = scene_change_error
		push_error("Scene transition failed (%d): %s" % [scene_change_error, path])
		transition_failed.emit(path, scene_change_error)
	await get_tree().process_frame
	await get_tree().process_frame
	_fade_in(0.28)

func _fade_in(duration: float) -> void:
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_overlay, "modulate:a", 0.0, duration) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_callback(func(): _overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE)
