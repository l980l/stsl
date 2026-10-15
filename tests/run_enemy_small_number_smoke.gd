extends SceneTree

# Bounded live-combat smoke test for the enemy small-number boundary.  This is
# deliberately not a win-rate or campaign-difficulty test: every catalog
# enemy is given the production BattleManager, three starter decks and at
# most eight enemy actions.  It fails on a missing live conversion or on an
# unexercised phase/card-counter/summon path, never on win/loss outcomes.
const MonsterCatalog = preload("res://resources/monster_catalog.gd")
const HeroRegistry = preload("res://resources/heroes/hero_registry.gd")
const BattleManager = preload("res://autoload/battle_manager.gd")
const TeamManager = preload("res://autoload/team_manager.gd")
const DeckManager = preload("res://autoload/deck_manager.gd")
const CardResource = preload("res://resources/card_resource.gd")
const EnemySmallNumbers = preload("res://resources/balance/enemy_small_numbers.gd")

const HERO_IDS := ["napoleon", "cleopatra", "yi_sun_sin"]
const MAX_ENEMY_TURNS := 8

func _init() -> void:
	AudioServer.set_bus_mute(0, true)
	call_deferred("_run")

func _run() -> void:
	seed(90210)
	var catalog: Array = MonsterCatalog.get_all_monsters()
	var completed := 0
	var phase_cases := 0
	var phase_reached := 0
	var counter_cases := 0
	var counter_fired := 0
	var summon_seen := 0
	var failed: Array[String] = []
	for enemy in catalog:
		var bm := _make_battle(enemy)
		if bm._enemies.is_empty() or not EnemySmallNumbers.is_converted(bm._enemies[0]):
			failed.append(str(enemy.enemy_name) + ": not converted at battle boundary")
			_free_battle(bm)
			continue
		if not enemy.phase_thresholds.is_empty():
			phase_cases += 1
			var threshold: float = float(enemy.phase_thresholds[0])
			# Land one integer below the ratio boundary.  A direct float product
			# can round to the wrong side for thresholds such as 0.66.
			var target_hp: int = max(1, int(floor(float(bm._enemies[0].max_hp) * threshold)) - 1)
			# Set the already-resolved HP just below the threshold and invoke the
			# production phase transition path.  This avoids mixing this coverage
			# assertion with deliberate defense-mode mitigation on several bosses.
			bm._enemy_hp[0] = target_hp
			bm._check_phase_transition(0)
			if bm._enemy_phase[0] > 0:
				phase_reached += 1
			else:
				failed.append("%s: phase did not transition (hp=%d max=%d threshold=%s)" % [enemy.enemy_name, bm._enemy_hp[0], bm._enemies[0].max_hp, str(threshold)])
		if not enemy.card_count_trigger.is_empty():
			counter_cases += 1
			var probe := CardResource.new()
			probe.card_type = int(enemy.card_count_trigger.get("card_type", -1))
			var threshold_count: int = int(enemy.card_count_trigger.get("threshold", 0))
			for _n in range(max(1, threshold_count)):
				bm._track_card_type_counters(probe)
			if int(bm._enemy_card_counters.get(0, {}).get("fired_count", 0)) > 0:
				counter_fired += 1
			else:
				failed.append(str(enemy.enemy_name) + ": card counter did not fire")
		var initial_enemy_count: int = bm._enemies.size()
		var executed := 0
		while bm.is_battle_active and executed < MAX_ENEMY_TURNS:
			await bm._execute_enemy_turn()
			executed += 1
		if bm._enemies.size() > initial_enemy_count:
			summon_seen += 1
		if executed > 0:
			completed += 1
		else:
			failed.append(str(enemy.enemy_name) + ": no enemy action executed")
		_free_battle(bm)
	var ok := failed.is_empty() and completed == catalog.size() and phase_reached == phase_cases and counter_fired == counter_cases and summon_seen > 0
	print("Enemy live smoke: catalog=%d, acted=%d, phase=%d/%d, counter=%d/%d, summon_cases=%d, cap=%d" % [catalog.size(), completed, phase_reached, phase_cases, counter_fired, counter_cases, summon_seen, MAX_ENEMY_TURNS])
	for item in failed:
		push_error(item)
	if summon_seen == 0:
		push_error("No live SUMMON action observed within bounded catalog smoke")
	quit(0 if ok else 1)

func _make_battle(enemy: Resource) -> Object:
	var bm := BattleManager.new()
	bm.turn_interval = 0.0
	bm._test_disable_crit = true
	bm.team_mgr = TeamManager.new()
	bm.deck_mgr = DeckManager.new()
	for hero_id in HERO_IDS:
		bm.team_mgr.add_hero(HeroRegistry.make_hero(hero_id))
		var card_module: GDScript = load("res://resources/cards/cards_%s.gd" % hero_id)
		for card in card_module.starter_deck():
			bm.deck_mgr.add_card_to_deck(card)
	bm.setup_battle([enemy])
	return bm

func _free_battle(bm: Object) -> void:
	bm.deck_mgr.free()
	bm.team_mgr.free()
	bm.free()
