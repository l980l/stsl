extends RefCounted

const BM = preload("res://autoload/battle_manager.gd")
const TM = preload("res://autoload/team_manager.gd")
const DM = preload("res://autoload/deck_manager.gd")
const Card = preload("res://resources/card_resource.gd")
const Effect = preload("res://resources/effect_resource.gd")
const Hero = preload("res://resources/hero_resource.gd")
const Enemy = preload("res://resources/enemy_resource.gd")
const Intent = preload("res://resources/intent_resource.gd")
var passed := 0
var failed := 0

func _check(ok: bool, label: String) -> void:
	if ok:
		passed += 1
	else:
		failed += 1
		print("  FAIL: v3 " + label)

func _battle(ids: Array = ["napoleon", "musashi"], enemy_count: int = 1):
	var bm = BM.new()
	bm.team_mgr = TM.new()
	bm.deck_mgr = DM.new()
	bm._test_disable_crit = true
	for id in ids:
		var hero = Hero.new()
		hero.hero_id = id
		hero.max_hp = 1000
		bm.team_mgr.add_hero(hero)
	var enemies: Array = []
	for _i in range(enemy_count):
		var enemy = Enemy.new()
		enemy.max_hp = 5000
		enemy.signatures_enabled = false
		var intent = Intent.new()
		intent.action_type = Intent.ActionType.ATTACK
		intent.value = 100
		enemy.intent_pattern = [intent]
		enemies.append(enemy)
	bm.setup_battle(enemies)
	return bm

func _free(bm) -> void:
	bm.deck_mgr.free()
	bm.team_mgr.free()
	bm.free()

func _card(owner_id: String, type: int, value: int):
	var card = Card.new()
	card.owner_id = owner_id
	var effect = Effect.new()
	effect.effect_type = type
	effect.value = value
	card.effects = [effect]
	return card

func run_all() -> Dictionary:
	var bm = _battle()
	var draw_card = _card("musashi", Effect.EffectType.DRAW, 1)
	bm.deck_mgr._heroes["musashi"]["draw"].append(draw_card)
	bm._apply_card_effects(draw_card, 0)
	_check(bm.deck_mgr.get_hand("musashi").size() == 1 and bm.deck_mgr.get_hand("napoleon").is_empty(), "draw belongs to second hero")
	bm._apply_card_effects(_card("musashi", Effect.EffectType.ENERGY, 1), 0)
	_check(bm.deck_mgr.get_energy("musashi") == 1 and bm.deck_mgr.get_energy("napoleon") == 0, "energy belongs to second hero")
	bm._hero_status["musashi"] = {"strength": 10}
	var attack = _card("musashi", Effect.EffectType.DAMAGE, 100)
	attack.effects[0].hit_count = 2
	bm._apply_card_effects(attack, 0)
	_check(bm.get_enemy_hp(0) == 4780, "normal strength applies to every hit")
	_check(bm.estimate_effect_damage(attack.effects[0], "musashi", 0) == 110, "strength preview matches")
	bm.deck_mgr.get_hand("musashi").clear()
	bm.deck_mgr._heroes["napoleon"]["hand"].append(attack)
	_check(bm._evaluate_condition("hand_size_0", attack), "empty hand uses owner not first hero")
	_free(bm)
	bm = _battle(["napoleon"])
	bm._enemy_status[0]["weak"] = 1
	bm._run_one_enemy_turn(0, true)
	_check(bm.team_mgr.get_current_hp("napoleon") == 925, "weak one affects next attack")
	_check(bm._enemy_status[0].get("weak", 0) == 0, "weak expires after attack")
	_free(bm)
	bm = _battle(["napoleon"])
	bm._enemies[0].mythology = "buddhist"
	bm._enemies[0].signatures_enabled = true
	bm._enemy_hp[0] = 1000
	bm._deal_damage_to_enemy(0, 900)
	bm._apply_status_to_enemy(0, "poison", 100)
	bm._tick_enemy_poison(0)
	_check(bm.team_mgr.get_current_hp("napoleon") == 750, "poison death includes damage and karma hooks")
	_free(bm)
	return {"passed": passed, "failed": failed}
