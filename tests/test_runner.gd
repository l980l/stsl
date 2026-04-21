# tests/test_runner.gd
extends SceneTree

var TestResources = preload("res://tests/test_resources.gd")
var TestTeamManager = preload("res://tests/test_team_manager.gd")
var TestDeckManager = preload("res://tests/test_deck_manager.gd")
var TestBattleManager = preload("res://tests/test_battle_manager.gd")
var TestMapGenerator = preload("res://tests/test_map_generator.gd")
var TestGameManager = preload("res://tests/test_game_manager.gd")
var TestEnemies = preload("res://tests/test_enemies.gd")
var TestEvent = preload("res://tests/test_event.gd")
var TestHeroes = preload("res://tests/test_heroes.gd")
var TestRelics = preload("res://tests/test_relics.gd")
var TestSave = preload("res://tests/test_save.gd")
var TestProgressManager = preload("res://tests/test_progress_manager.gd")
var TestChapterSystem = preload("res://tests/test_chapter_system.gd")

func _init() -> void:
	var total_passed: int = 0
	var total_failed: int = 0
	var suites: Array = [
		TestResources.new(),
		TestTeamManager.new(),
		TestDeckManager.new(),
		TestBattleManager.new(),
		TestMapGenerator.new(),
		TestGameManager.new(),
		TestEnemies.new(),
		TestEvent.new(),
		TestHeroes.new(),
		TestRelics.new(),
		TestSave.new(),
		TestProgressManager.new(),
		TestChapterSystem.new(),
	]
	for suite in suites:
		var result: Dictionary = suite.run_all()
		total_passed += result.passed
		total_failed += result.failed
	print("\n=== Results: %d passed, %d failed ===" % [total_passed, total_failed])
	quit(1 if total_failed > 0 else 0)
