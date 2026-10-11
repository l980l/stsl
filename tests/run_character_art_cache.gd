extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	if not ProjectSettings.globalize_path("user://").get_base_dir().get_file().begins_with("STSL-campaign-bot-"):
		printerr("Use an isolated STSL-campaign-bot-* user directory.")
		quit(2)
		return
	var suite = preload("res://tests/test_character_art_cache.gd").new()
	var result: Dictionary = suite.run_all()
	var cache = preload("res://characters/character_art_cache.gd")
	var hero := preload("res://resources/hero_resource.gd").new()
	hero.character_scene = preload("res://characters/heroes/cleopatra/cleopatra.tscn")
	var enemy := preload("res://resources/enemy_resource.gd").new()
	enemy.enemy_name = "enemy.egyptian.scarab"
	enemy.character_scene = preload("res://characters/enemies/enemy_placeholder.tscn")
	var team = root.get_node("TeamManager")
	var game = root.get_node("GameManager")
	var transition = root.get_node("SceneTransition")
	var saved_heroes: Array = team.heroes
	var saved_enemies: Array = game.pending_enemies
	team.heroes = [hero]
	game.pending_enemies = [enemy]
	transition._overlay.modulate.a = 1.0
	await transition._prepare_battle_art()
	for condition in [transition.last_art_preparation.cold_count == 2,
		cache.size() == 2, not transition._loading_bar.visible]:
		if condition:
			result.passed += 1
		else:
			result.failed += 1
	await transition._prepare_battle_art()
	if transition.last_art_preparation.cold_count == 0:
		result.passed += 1
	else:
		result.failed += 1
	team.heroes = saved_heroes
	game.pending_enemies = saved_enemies
	cache.clear()
	print("Character art cache: %d passed, %d failed" % [result.passed, result.failed])
	await process_frame
	quit(1 if result.failed else 0)
