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
var TestHeroRegistry = preload("res://tests/test_hero_registry.gd")
var TestCardEffectsEngine = preload("res://tests/test_card_effects_engine.gd")
var TestCardPoolDistribution = preload("res://tests/test_card_pool_distribution.gd")
var TestLocaleManager = preload("res://tests/test_locale_manager.gd")
var TestCardScene = preload("res://tests/test_card_scene.gd")
var TestEffectDisplayText = preload("res://tests/test_effect_display_text.gd")
var TestPowerCards = preload("res://tests/test_power_cards.gd")
var TestEnemyCounters = preload("res://tests/test_enemy_counters.gd")
var TestRevive = preload("res://tests/test_revive.gd")
var TestTauntSystem = preload("res://tests/test_taunt_system.gd")
var TestRecruitSystem = preload("res://tests/test_recruit_system.gd")
var TestEncounterWeighting = preload("res://tests/test_encounter_weighting.gd")
var TestEnemyMechanics = preload("res://tests/test_enemy_mechanics.gd")
var TestEnemyPatternsV2 = preload("res://tests/test_enemy_patterns_v2.gd")
var TestEventIntegration = preload("res://tests/test_event_integration.gd")
var TestLightningBeam = preload("res://tests/test_lightning_beam.gd")
var TestIceShards = preload("res://tests/test_ice_shards.gd")
var TestFireBlast = preload("res://tests/test_fire_blast.gd")
var TestDebuffHex = preload("res://tests/test_debuff_hex.gd")
var TestCharmKiss = preload("res://tests/test_charm_kiss.gd")
var TestPoisonSplash = preload("res://tests/test_poison_splash.gd")
var TestDeathDissolve = preload("res://tests/test_death_dissolve.gd")
var TestReviveBlessing = preload("res://tests/test_revive_blessing.gd")
var TestHealBlessing = preload("res://tests/test_heal_blessing.gd")
var TestBloodSpray = preload("res://tests/test_blood_spray.gd")
var TestHolyStrike = preload("res://tests/test_holy_strike.gd")
var TestArrowShot = preload("res://tests/test_arrow_shot.gd")
var TestExplosionBlast = preload("res://tests/test_explosion_blast.gd")
var TestBluntSmash = preload("res://tests/test_blunt_smash.gd")
var TestBulletShot = preload("res://tests/test_bullet_shot.gd")
var TestDamagePipeline = preload("res://tests/test_damage_pipeline.gd")

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
		TestHeroRegistry.new(),
		TestCardEffectsEngine.new(),
		TestCardPoolDistribution.new(),
		TestLocaleManager.new(),
		TestCardScene.new(),
		TestEffectDisplayText.new(),
		TestPowerCards.new(),
		TestEnemyCounters.new(),
		TestRevive.new(),
		TestTauntSystem.new(),
		TestRecruitSystem.new(),
		TestEncounterWeighting.new(),
		TestEnemyMechanics.new(),
		TestEnemyPatternsV2.new(),
		TestEventIntegration.new(),
		TestLightningBeam.new(),
		TestIceShards.new(),
		TestFireBlast.new(),
		TestDebuffHex.new(),
		TestCharmKiss.new(),
		TestPoisonSplash.new(),
		TestDeathDissolve.new(),
		TestReviveBlessing.new(),
		TestHealBlessing.new(),
		TestBloodSpray.new(),
		TestHolyStrike.new(),
		TestArrowShot.new(),
		TestExplosionBlast.new(),
		TestBluntSmash.new(),
		TestBulletShot.new(),
		TestDamagePipeline.new(),
	]
	for suite in suites:
		var result: Dictionary = suite.run_all()
		total_passed += result.passed
		total_failed += result.failed
	print("\n=== Results: %d passed, %d failed ===" % [total_passed, total_failed])
	suites.clear()
	quit(1 if total_failed > 0 else 0)
