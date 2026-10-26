extends SceneTree

# Rendered captures of the main text-heavy screens for before/after readability
# review. Run through tools/run_live_balance_checks.sh --rendered so user:// is
# isolated. Not a pass/fail layout test: it only records what is on screen.
const SCENES := [
	["main_menu", "res://scenes/main_menu/main_menu_scene.tscn"],
	["tutorial_select", "res://scenes/tutorial/tutorial_select_scene.tscn"],
	["hero_select", "res://scenes/hero_select/hero_select_scene.tscn"],
	["chapter_select", "res://scenes/chapter_select/chapter_select_scene.tscn"],
	["map", "res://scenes/map/map_scene.tscn"],
	["shop", "res://scenes/shop/shop_scene.tscn"],
	["rest", "res://scenes/rest/rest_scene.tscn"],
	["event", "res://scenes/event/event_scene.tscn"],
	["card_pick", "res://scenes/card_pick/card_pick_scene.tscn"],
	["card_upgrade", "res://scenes/card_upgrade/card_upgrade_scene.tscn"],
	["chapter_clear", "res://scenes/chapter_clear/chapter_clear_scene.tscn"],
	["game_over", "res://scenes/game_over/game_over_scene.tscn"],
	["codex", "res://scenes/ui/codex_scene.tscn"],
]

var gm: Node

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	AudioServer.set_bus_mute(0, true)
	var out := _output()
	gm = root.get_node("GameManager")
	TranslationServer.set_locale(OS.get_environment("STSL_CAPTURE_LOCALE") if OS.get_environment("STSL_CAPTURE_LOCALE") != "" else "ko")
	gm.start_run("napoleon", 1)
	# Skip the one-shot story overlays so the map itself is captured.
	gm._awakening_shown_run = true
	gm._realm_intro_act = gm.current_act
	for entry in SCENES:
		_prepare(entry[0])
		change_scene_to_file(entry[1])
		await _settle(90)
		await _shot(out, entry[0])
		await _overlays(out, entry[0])
	gm.start_tutorial("basics")
	await _settle(240)
	await _shot(out, "battle")
	await _battle_extras(out)
	print("UI text captures written to %s" % ProjectSettings.globalize_path(out))
	quit(0)

# Scenes that bounce back to the map without pending run state.
func _prepare(id: String) -> void:
	match id:
		"event":
			gm.pending_event = gm._get_random_event()
		"card_pick":
			gm.card_rewards = gm._generate_card_rewards()
		"game_over":
			gm.run_won = false

func _overlays(out: String, id: String) -> void:
	match id:
		"main_menu":
			current_scene._on_credits()
			await _settle(30)
			await _shot(out, "credits")
		"map":
			var settings: Node = load("res://scenes/ui/settings_overlay.tscn").instantiate()
			current_scene.add_child(settings)
			settings.open()
			await _settle(30)
			await _shot(out, "settings")
			settings.queue_free()

func _battle_extras(out: String) -> void:
	var bm := root.get_node("BattleManager")
	var scene: Node = current_scene
	var hid: String = bm.get_current_hero_id()
	# Status badges, block and enemy debuffs as they would appear mid-fight.
	for s in [["strength", 2], ["weak", 1]]:
		bm._apply_status_to_hero(hid, s[0], s[1])
	bm._gain_block(hid, 12)
	for s in [["poison", 4], ["vulnerable", 2], ["weak", 1]]:
		bm._apply_status_to_enemy(0, s[0], s[1])
	await _settle(60)
	await _shot(out, "battle_status")
	scene._show_deck_viewer_in_battle()
	await _settle(30)
	await _shot(out, "battle_deck")

func _settle(frames: int) -> void:
	for i in frames:
		await process_frame

func _shot(out: String, id: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.save_png(out.path_join(id + ".png"))
	if id == "battle":
		# Turn-queue chips (top-left) at 2× for close inspection.
		var queue := image.get_region(Rect2i(0, 0, 340, 80))
		queue.resize(680, 160, Image.INTERPOLATE_NEAREST)
		queue.save_png(out.path_join("battle_queue.png"))

func _output() -> String:
	var directory := OS.get_environment("STSL_UI_CAPTURE_OUTPUT")
	if directory == "":
		directory = "user://ui-text-captures"
	DirAccess.make_dir_recursive_absolute(directory)
	return directory
