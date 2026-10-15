# Card definitions whose status keys require a BattleManager-specific resolution.
class_name TestCardContentEffects
extends RefCounted

const BattleManagerClass = preload("res://autoload/battle_manager.gd")
const TeamManagerClass = preload("res://autoload/team_manager.gd")
const DeckManagerClass = preload("res://autoload/deck_manager.gd")
const CardCatalog = preload("res://resources/card_catalog.gd")
const CardRes = preload("res://resources/card_resource.gd")
const EffectRes = preload("res://resources/effect_resource.gd")
const HeroRes = preload("res://resources/hero_resource.gd")
const EnemyRes = preload("res://resources/enemy_resource.gd")
const IntentRes = preload("res://resources/intent_resource.gd")
const GameManagerClass = preload("res://autoload/game_manager.gd")

var passed := 0
var failed := 0

func run_all() -> Dictionary:
	_test_pharaoh_venom_spends_owner_energy_and_poison_all_enemies()
	_test_pharaoh_venom_zero_energy_is_a_no_op()
	_test_pharaoh_venom_ignores_dead_enemies()
	_test_fate_duel_mutual_damage_and_expiry()
	_test_fate_duel_owner_identity_and_preview()
	_test_fate_duel_preview_matches_weak_and_vulnerable_damage()
	_test_upgraded_fate_duel_lasts_four_enemy_turns()
	return {"passed": passed, "failed": failed}

func _check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		print("  FAIL: card content " + label)

func _battle(hero_ids: Array, enemy_count: int = 1) -> BattleManagerClass:
	var battle := BattleManagerClass.new()
	battle._test_disable_crit = true
	battle.team_mgr = TeamManagerClass.new()
	battle.deck_mgr = DeckManagerClass.new()
	for hero_id in hero_ids:
		var hero := HeroRes.new()
		hero.hero_id = hero_id
		hero.max_hp = 1000
		battle.team_mgr.add_hero(hero)
	var enemies: Array = []
	for _i in range(enemy_count):
		var enemy := EnemyRes.new()
		enemy.max_hp = 1000
		enemy.signatures_enabled = false
		var intent := IntentRes.new()
		intent.action_type = IntentRes.ActionType.PREPARE
		enemy.intent_pattern = [intent]
		enemies.append(enemy)
	battle.setup_battle(enemies)
	battle.is_player_turn = true
	return battle

func _free(battle: BattleManagerClass) -> void:
	battle.deck_mgr.free()
	battle.team_mgr.free()
	battle.free()

func _catalog_card(owner_id: String, card_name: String) -> Resource:
	for card in CardCatalog.get_all_cards():
		if card.owner_id == owner_id and card.card_name == card_name:
			return card.duplicate(true)
	return null

func _attack_card(owner_id: String, amount: int) -> Resource:
	var card := CardRes.new()
	card.owner_id = owner_id
	card.card_type = CardRes.CardType.ATTACK
	var effect := EffectRes.new()
	effect.effect_type = EffectRes.EffectType.DAMAGE
	effect.value = amount
	effect.target = "SINGLE"
	card.effects = [effect]
	return card

func _test_pharaoh_venom_spends_owner_energy_and_poison_all_enemies() -> void:
	var battle := _battle(["cleopatra", "napoleon"], 3)
	var venom := _catalog_card("cleopatra", "card.cleopatra.pharaoh_venom.name")
	battle.deck_mgr.get_hand("cleopatra").append(venom)
	battle.deck_mgr.set_energy_h("cleopatra", 2)
	battle.deck_mgr.set_energy_h("napoleon", 3)
	battle._apply_status_to_enemy(0, "poison", 5)
	battle._apply_status_to_enemy(1, "poison", 5)

	_check(battle.play_card(venom, 0), "pharaoh venom can be played at zero card cost")
	_check(battle.deck_mgr.get_energy("cleopatra") == 0, "pharaoh venom spends only Cleopatra's remaining energy")
	_check(battle.deck_mgr.get_energy("napoleon") == 3, "pharaoh venom does not spend another hero's energy")
	_check(battle.get_enemy_status(0).get("poison_dmg", 0) == 20, "pharaoh venom scales existing poison by two per spent energy")
	_check(battle.get_enemy_status(1).get("poison_dmg", 0) == 20, "pharaoh venom scales every poisoned enemy")
	_check(battle.get_enemy_status(2).get("poison_dmg", 0) == 0, "pharaoh venom does not create poison on an unpoisoned enemy")
	_check(battle.get_enemy_status(0).get("poison_dur", 0) == 3, "pharaoh venom preserves existing poison duration")
	_check(not battle.get_all_active_powers().has("power.spend_all_energy_poison_double:cleopatra"), "pharaoh venom does not leave a persistent power")
	_free(battle)

func _test_pharaoh_venom_zero_energy_is_a_no_op() -> void:
	var battle := _battle(["cleopatra"], 2)
	var venom := _catalog_card("cleopatra", "card.cleopatra.pharaoh_venom.name")
	battle.deck_mgr.get_hand("cleopatra").append(venom)
	battle.deck_mgr.set_energy_h("cleopatra", 0)

	_check(battle.play_card(venom, 0), "pharaoh venom remains playable with no energy")
	_check(battle.deck_mgr.get_energy("cleopatra") == 0, "zero-energy pharaoh venom leaves energy at zero")
	_check(battle.get_enemy_status(0).get("poison_dmg", 0) == 0 and battle.get_enemy_status(1).get("poison_dmg", 0) == 0, "zero-energy pharaoh venom applies no poison")
	_free(battle)

func _test_pharaoh_venom_ignores_dead_enemies() -> void:
	var battle := _battle(["cleopatra"], 2)
	var venom := _catalog_card("cleopatra", "card.cleopatra.pharaoh_venom.name")
	battle.deck_mgr.get_hand("cleopatra").append(venom)
	battle.deck_mgr.set_energy_h("cleopatra", 1)
	battle._apply_status_to_enemy(0, "poison", 5)
	battle._apply_status_to_enemy(1, "poison", 5)
	battle._enemy_alive[1] = false

	_check(battle.play_card(venom, 0), "pharaoh venom can resolve with a dead enemy present")
	_check(battle.get_enemy_status(0).get("poison_dmg", 0) == 10, "pharaoh venom scales living enemy poison")
	_check(battle.get_enemy_status(1).get("poison_dmg", 0) == 5, "pharaoh venom leaves dead enemy poison untouched")
	_free(battle)

func _test_fate_duel_mutual_damage_and_expiry() -> void:
	var battle := _battle(["musashi"], 1)
	var duel := _catalog_card("musashi", "card.musashi.fate_duel.name")
	battle._apply_card_effects(duel, 0)

	_check(battle.get_enemy_status(0).get("duel_lock", 0) == 3, "fate duel records three enemy turns")
	battle._current_actor_id = "hero:musashi"
	battle._apply_card_effects(_attack_card("musashi", 100), 0)
	_check(battle.get_enemy_hp(0) == 850, "fate duel increases Musashi damage to the marked enemy by 50 percent")
	battle._deal_damage_to_hero("musashi", 100, "", false, 0)
	_check(battle.team_mgr.get_current_hp("musashi") == 850, "fate duel increases marked enemy damage to Musashi by 50 percent")

	for _turn in range(3):
		battle._run_one_enemy_turn(0, true)
	_check(battle.get_enemy_status(0).get("duel_lock", 0) == 0, "fate duel expires after three marked enemy turns")
	battle._apply_card_effects(_attack_card("musashi", 100), 0)
	_check(battle.get_enemy_hp(0) == 750, "expired fate duel no longer increases Musashi damage")
	_free(battle)

func _test_fate_duel_owner_identity_and_preview() -> void:
	var battle := _battle(["musashi", "napoleon"], 1)
	var duel := _catalog_card("musashi", "card.musashi.fate_duel.name")
	battle._apply_card_effects(duel, 0)
	var attack := _attack_card("musashi", 100)
	_check(battle.estimate_effect_damage(attack.effects[0], "musashi", 0) == 150, "duel preview matches Musashi's boosted damage")
	_check(battle.estimate_effect_damage(attack.effects[0], "napoleon", 0) == 100, "duel preview does not boost another hero")

	battle._current_actor_id = "hero:napoleon"
	battle._deal_damage_to_enemy(0, 100, "", false, "musashi")
	_check(battle.get_enemy_hp(0) == 850, "explicit Musashi source stays boosted during another hero turn")
	battle._deal_damage_to_enemy(0, 100, "", false, "napoleon")
	_check(battle.get_enemy_hp(0) == 750, "explicit non-duelist source is not boosted")
	battle._apply_status_to_enemy(0, "poison", 10)
	battle._tick_enemy_poison(0)
	_check(battle.get_enemy_hp(0) == 740, "duel does not amplify unrelated poison damage")
	_free(battle)

func _test_fate_duel_preview_matches_weak_and_vulnerable_damage() -> void:
	var battle := _battle(["musashi"], 1)
	var duel := _catalog_card("musashi", "card.musashi.fate_duel.name")
	var attack := _attack_card("musashi", 100)
	battle._apply_card_effects(duel, 0)
	battle._hero_status["musashi"] = {"weak": 1}
	battle._apply_status_to_enemy(0, "vulnerable", 1)
	var preview: int = battle.estimate_effect_damage(attack.effects[0], "musashi", 0)
	battle._current_actor_id = "hero:musashi"
	battle._apply_card_effects(attack, 0)
	var actual: int = 1000 - battle.get_enemy_hp(0)
	_check(preview == 150, "weak and vulnerable duel preview uses the same additive receiver modifiers")
	_check(actual == preview, "weak and vulnerable duel damage matches its preview")
	_free(battle)

func _test_upgraded_fate_duel_lasts_four_enemy_turns() -> void:
	var battle := _battle(["musashi"], 1)
	var duel := _catalog_card("musashi", "card.musashi.fate_duel.name")
	var game_manager := GameManagerClass.new()
	game_manager.upgrade_card(duel)
	game_manager.free()
	battle._apply_card_effects(duel, 0)
	_check(battle.get_enemy_status(0).get("duel_lock", 0) == 4, "upgraded fate duel records four enemy turns")
	for _turn in range(3):
		battle._run_one_enemy_turn(0, true)
	_check(battle.get_enemy_status(0).get("duel_lock", 0) == 1, "upgraded fate duel remains active after three enemy turns")
	battle._run_one_enemy_turn(0, true)
	_check(battle.get_enemy_status(0).get("duel_lock", 0) == 0, "upgraded fate duel expires after four enemy turns")
	_free(battle)
