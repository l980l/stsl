extends "res://tests/test_card_revision_runtime.gd"

const Catalog = preload("res://resources/card_catalog.gd")
const GM = preload("res://autoload/game_manager.gd")
var _definitions: Dictionary = {}

func _find(key: String, upgraded: bool = false):
	var card = _definitions[key].duplicate(true)
	if upgraded:
		var gm = GM.new()
		gm.upgrade_card(card)
		gm.free()
	return card

func _apply(bm, key: String, upgraded: bool = false, target: int = 0, ally: String = ""):
	var card = _find(key, upgraded)
	bm._apply_card_effects(card, target, ally)
	return card

func run_all() -> Dictionary:
	super.run_all()
	for card in Catalog.get_all_cards():
		_definitions[card.card_name] = card
	var gm = GM.new()
	var pool_total := 0
	for id in Catalog.HERO_ORDER:
		var source = Catalog._HERO_CARDS[id]
		var deck: Array = source.starter_deck()
		pool_total += source.pool().size()
		_check(deck.size() == 10, id + " starts with ten cards")
		var common := 0
		var unique := 0
		var counters := 0
		for card in deck:
			if card.card_name.ends_with(".strike.name") or card.card_name.ends_with(".defend.name"):
				common += 1
			elif card.card_name == "card.counter.name":
				counters += 1
				_check(card.cost == 2 and card.is_retain and card.is_exhaust, id + " retains/exhausts counter")
			else:
				unique += 1
		_check(common == 4 and unique == 5 and counters == 1, id + " starter composition")
	_check(pool_total == 189, "reward registrations remain 189")
	for card in Catalog.get_all_cards():
		if not card.has_explicit_upgrade:
			continue
		var upgraded = card.duplicate(true)
		gm.upgrade_card(upgraded)
		var changed: bool = upgraded.cost != card.cost
		for i in range(card.effects.size()):
			var original = card.effects[i]
			var after = upgraded.effects[i]
			changed = changed or original.value != after.value or original.bonus_value != after.bonus_value or original.rule_params != after.rule_params
		_check(changed, "declared upgrade changes " + card.card_name)
	gm.free()
	_test_resources()
	_test_owner_and_limits()
	_test_powers_and_death()
	_test_cost_and_save()
	_test_speed_and_counter()
	_test_descriptions()
	return {"passed": passed, "failed": failed}

func _test_resources() -> void:
	var bm = _battle(["napoleon", "yi_sun_sin", "genghis_khan"], 2)
	bm._hero_status["napoleon"] = {"morale": 2, "tokens": 6}
	_apply(bm, "card.napoleon.victory_proclamation.name")
	_check(bm.get_enemy_hp(0) == 4820 and bm.get_hero_status("napoleon").morale == 0, "victory consumes exactly two morale")
	_apply(bm, "card.napoleon.victory_proclamation.name", true)
	_check(bm.get_enemy_hp(0) == 4700, "upgraded victory fallback 120")
	_apply(bm, "card.napoleon.legion_charge.name")
	_check(bm.get_enemy_hp(0) == 4400 and bm.get_hero_status("napoleon").tokens == 4, "legion spends two soldiers for 300")
	bm._hero_status["genghis_khan"] = {"tokens": 6}
	_apply(bm, "card.genghis_khan.horde_volley.name", false)
	_check(bm.get_enemy_hp(0) == 4210 and bm.get_enemy_hp(1) == 4810 and bm.get_hero_status("genghis_khan").tokens == 3, "volley spends once and hits every enemy")
	bm._hero_block["yi_sun_sin"] = 500
	_apply(bm, "card.yi_sun_sin.counter.name")
	_check(bm.get_enemy_hp(0) == 4030 and bm.get_hero_block("yi_sun_sin") == 420, "counter block consumption caps at 80")
	_apply(bm, "card.yi_sun_sin.turtle_ship_charge.name", true)
	_check(bm.get_enemy_hp(0) == 3700 and bm.get_hero_block("yi_sun_sin") == 320, "upgraded turtle spends max100 for330")
	bm._hero_status["napoleon"]["morale"] = 99
	var cannon = _find("card.napoleon.allied_bombardment.name")
	_check(bm.estimate_effect_damage(cannon.effects[0], "napoleon", 0) == 280, "team morale preview includes base and cap")
	bm._apply_card_effects(cannon, 0)
	_check(bm.get_enemy_hp(0) == 3420 and bm.get_hero_status("napoleon").morale == 99, "team morale capped and unspent")
	bm._hero_status["yi_sun_sin"] = {"morale": 2}
	bm._hero_status["genghis_khan"]["morale"] = 0
	_apply(bm, "card.yi_sun_sin.united_bulwark.name")
	_check(bm.get_hero_block("napoleon") == 110 and bm.get_hero_block("yi_sun_sin") == 430 and bm.get_hero_status("yi_sun_sin").morale == 1, "team bulwark consumes one per living owner")
	_free(bm)
	bm = _battle(["genghis_khan"])
	bm._register_power("power.echo_next_attack", "genghis_khan", 1)
	bm.deck_mgr._heroes["genghis_khan"]["cards_played_this_turn"] = 3
	var filler = _find("card.genghis_khan.horse_thrust.name")
	bm.deck_mgr._heroes["genghis_khan"]["draw"] = [filler, filler.duplicate(true)]
	_apply(bm, "card.genghis_khan.horse_charge.name")
	_check(bm.deck_mgr.get_hand("genghis_khan").size() == 1 and bm.get_enemy_hp(0) == 4880, "echo preserves card damage and shared once-turn draw limit")
	_free(bm)
	bm = _battle(["cleopatra"], 2)
	bm._apply_status_to_enemy(0, "poison", 25)
	_apply(bm, "card.cleopatra.poison_ritual.name")
	_check(bm.get_enemy_hp(0) == 4910 and bm.get_enemy_status(0).poison_dmg == 0, "ritual base40 plus poison50 and consumes")
	bm._apply_status_to_enemy(0, "poison", 20)
	bm._apply_status_to_enemy(0, "weak", 1)
	_apply(bm, "card.cleopatra.isis_judgment.name", true)
	_check(bm.get_enemy_status(0).poison_dmg == 50 and bm.get_enemy_status(0).weak == 2 and bm.get_enemy_status(1).get("poison_dmg", 0) == 0, "judgment boosts existing poison and extends existing debuffs")
	_apply(bm, "card.cleopatra.poison_throne.name")
	_check(bm.get_enemy_hp(0) == 4710, "throne counts poison as a type")
	bm._enemy_status[0] = {"charm": 80}
	_apply(bm, "card.cleopatra.charm_execution.name")
	_check(bm.get_enemy_hp(0) == 4390 and bm.get_enemy_status(0).charm == 20, "execution base80 and capped charm240")
	_free(bm)

func _test_owner_and_limits() -> void:
	var bm = _battle(["napoleon", "musashi", "genghis_khan"])
	_apply(bm, "card.musashi.guard_stance.name")
	_apply(bm, "card.musashi.guard_stance.name")
	_apply(bm, "card.musashi.niten_starter.name")
	_check(bm.get_enemy_hp(0) == 4880, "stance duplicates do not stack; only first hit gets20")
	_apply(bm, "card.musashi.niten_starter.name")
	_check(bm.get_enemy_hp(0) == 4780, "first hit reservation consumed")
	bm.deck_mgr._heroes["napoleon"]["hand"].append(_find("card.napoleon.war_bugle.name"))
	_apply(bm, "card.musashi.void_sword.name")
	_check(bm.get_enemy_hp(0) == 4610, "void sword ignores another hero hand")
	_apply(bm, "card.musashi.flying_swallow.name")
	_apply(bm, "card.musashi.flying_swallow.name")
	_check(bm.deck_mgr.get_energy("musashi") == 1 and bm.deck_mgr.get_energy("napoleon") == 0, "refund max once to second hero")
	bm._hero_status["musashi"] = {"weak": 2, "vulnerable": 2}
	_apply(bm, "card.musashi.clear_wind.name")
	_check(not bm.get_hero_status("musashi").has("weak") and not bm.get_hero_status("musashi").has("vulnerable"), "clear wind cleanses empty owner")
	bm.deck_mgr._heroes["genghis_khan"]["cards_played_this_turn"] = 3
	var filler = _find("card.genghis_khan.horse_thrust.name")
	bm.deck_mgr._heroes["genghis_khan"]["draw"].append(filler)
	bm.deck_mgr._heroes["genghis_khan"]["draw"].append(filler.duplicate(true))
	_apply(bm, "card.genghis_khan.horse_charge.name")
	_apply(bm, "card.genghis_khan.horse_charge.name")
	_check(bm.deck_mgr.get_hand("genghis_khan").size() == 1, "third-card draw max once to third hero")
	_apply(bm, "card.genghis_khan.long_march.name")
	_check(bm.get_hero_block("genghis_khan") == 60, "march excludes itself")
	_apply(bm, "card.musashi.meditation.name")
	_check(bm._pending_discard_pick.is_empty(), "meditation works on empty own hand")
	bm.deck_mgr._heroes["musashi"]["hand"].append(_find("card.musashi.void_sword.name"))
	_apply(bm, "card.musashi.meditation.name")
	_check(bm.get_pending_discard_owner() == "musashi" and bm.is_discard_pick_optional(), "meditation requests own optional discard")
	bm.resolve_pending_discard_pick(null)
	_check(bm.deck_mgr.get_hand("musashi").size() == 1, "skip preserves hand")
	_apply(bm, "card.musashi.meditation.name")
	bm.resolve_pending_discard_pick(bm.deck_mgr.get_hand("musashi")[0])
	_check(bm.deck_mgr.get_hand("musashi").is_empty(), "selection removes only selected owner card")
	_free(bm)

func _test_powers_and_death() -> void:
	var bm = _battle(["napoleon", "joan_of_arc", "genghis_khan"], 2)
	_apply(bm, "card.napoleon.emperors_power.name", true)
	_check(bm.get_hero_status("napoleon").get("morale", 0) == 1, "upgraded morale power immediate one")
	bm._trigger_active_powers("player_turn_start", {"hero_id": "joan_of_arc"})
	_check(bm.get_hero_status("napoleon").get("morale", 0) == 1, "morale power waits for owner turn")
	bm._trigger_active_powers("player_turn_start", {"hero_id": "napoleon"})
	_check(bm.get_hero_status("napoleon").morale == 2, "morale power adds one next owner turn")
	_apply(bm, "card.joan_of_arc.crusaders_faith.name", true)
	_apply(bm, "card.joan_of_arc.crusaders_faith.name")
	_apply(bm, "card.joan_of_arc.martyr_strength.name")
	_check(bm._hero_strength("joan_of_arc") == 34, "distinct powers add but lower duplicate does not overwrite")
	for hero in bm.team_mgr.heroes:
		bm.team_mgr.take_damage(hero.hero_id, 500)
	bm._hero_status["napoleon"]["morale"] = 0
	_apply(bm, "card.joan_of_arc.angel_wings.name", true)
	for _turn in range(4):
		bm._trigger_active_powers("player_turn_start", {"hero_id": "joan_of_arc"})
	_check(bm.team_mgr.get_current_hp("napoleon") == 660, "wings heals exactly immediate plus three owner turns")
	_check(not bm._active_powers.has("power.limited_team_heal:joan_of_arc"), "limited heal expires")
	bm._hero_status["joan_of_arc"]["sacrifice_bank"] = 250
	_apply(bm, "card.joan_of_arc.martyrs_light.name")
	_check(bm.get_hero_status("joan_of_arc").sacrifice_bank == 100 and bm.get_hero_block("napoleon") == 210, "sacrifice payout spends capped150")
	bm.team_mgr.take_damage("joan_of_arc", 9999)
	_apply(bm, "card.napoleon.hussar_charge.name")
	var revive = _find("card.joan_of_arc.miracle_revive.name")
	revive.owner_id = "napoleon"
	bm._apply_card_effects(revive, -1, "joan_of_arc")
	_check(bm.team_mgr.get_current_hp("joan_of_arc") == 300 and bm.get_hero_status("joan_of_arc").get("sacrifice_bank", 0) == 0, "revive restores30percent and clears sacrifice")
	_apply(bm, "card.genghis_khan.executioners_bounty.name")
	bm._enemy_hp = [50, 50]
	_apply(bm, "card.genghis_khan.horde_volley.name")
	_check(bm.deck_mgr.get_energy("genghis_khan") == 0, "no kill means no bounty")
	bm._enemy_hp = [1, 1]
	_apply(bm, "card.genghis_khan.horde_volley.name")
	_check(bm.deck_mgr.get_energy("genghis_khan") == 1, "multi-kill bounty grants energy once to owner")
	_free(bm)
	bm = _battle(["napoleon", "joan_of_arc"])
	bm.team_mgr.take_damage("joan_of_arc", 980)
	_apply(bm, "card.joan_of_arc.altar_flame.name", false, -1, "napoleon")
	_check(not bm.team_mgr.is_alive("joan_of_arc") and bm.get_hero_block("napoleon") == 0, "lethal sacrifice stops follow-up ally block")
	_check(bm.get_hero_status("joan_of_arc").get("sacrifice_bank", 0) == 20, "sacrifice records actual lost HP")
	_free(bm)

func _test_cost_and_save() -> void:
	var bm = _battle(["napoleon", "genghis_khan"])
	bm.deck_mgr.start_hero_turn("napoleon")
	var attack = _find("card.napoleon.allied_bombardment.name")
	var skill = _find("card.napoleon.war_bugle.name")
	bm.deck_mgr._heroes["napoleon"]["hand"] = [skill, attack]
	bm.deck_mgr.reserve_cost_reduction("napoleon", 1, 2)
	bm.deck_mgr.reserve_cost_reduction("napoleon", 1, 2)
	bm.deck_mgr.reserve_cost_reduction("napoleon", 1, 1, true)
	_check(bm.deck_mgr.get_effective_cost("napoleon", attack) == 1, "general/attack discounts max not sum")
	bm.deck_mgr.play_card(skill)
	_check(bm.deck_mgr.get_effective_cost("napoleon", attack) == 1, "skill does not consume attack reservation")
	bm.deck_mgr.play_card(attack)
	_check(bm.deck_mgr.get_effective_cost("napoleon", attack) == 2, "applicable reservations consumed separately")
	_free(bm)
	var dm = DM.new()
	var old: Dictionary = {"version": 3, "full_deck": [{"card_name": "card.counter.name", "owner_id": "musashi", "cost": 3, "upgrade_level": 1, "effects": []}]}
	dm.from_dict(old)
	var restored = dm.get_full_deck()[0]
	_check(restored.cost == 2 and restored.is_retain and restored.is_exhaust and restored.effects[0].value == 80, "old save restores revised upgraded counter")
	var again = DM.new()
	again.from_dict(dm.to_dict())
	_check(again.get_full_deck().size() == 1 and again.get_full_deck()[0].owner_id == "musashi", "save retains exact deck composition and owner")
	dm.free()
	again.free()

func _test_descriptions() -> void:
	var locale := TranslationServer.get_locale()
	for language in ["ko", "en"]:
		TranslationServer.set_locale(language)
		for card in Catalog.get_all_cards():
			if not card.has_explicit_upgrade:
				continue
			for effect in card.effects:
				if effect.rule_id != "":
					var text: String = effect.display_text()
					_check(text != "" and not "effect.v3." in text and not "{" in text, language + " readable " + effect.rule_id)
	TranslationServer.set_locale(locale)

func _test_speed_and_counter() -> void:
	var bm = _battle(["napoleon", "musashi", "genghis_khan"])
	var base_speed: int = bm._hero_effective_speed("genghis_khan")
	_apply(bm, "card.genghis_khan.cavalry_charge_speed.name", true)
	_check(bm._hero_effective_speed("genghis_khan") == base_speed + 14, "upgraded short speed uses14")
	bm._phase_hero_post("genghis_khan")
	_check(bm._hero_effective_speed("genghis_khan") == base_speed + 14, "short speed skips current end")
	bm._phase_hero_post("genghis_khan")
	_check(bm._hero_effective_speed("genghis_khan") == base_speed + 14, "short speed lasts first subsequent end")
	bm._phase_hero_post("genghis_khan")
	_check(bm._hero_effective_speed("genghis_khan") == base_speed, "short speed expires second subsequent end")
	var queue_before: float = bm._turn_queue_at["hero:musashi"]
	_apply(bm, "card.musashi.swift_blade.name", true)
	_apply(bm, "card.musashi.swift_blade.name")
	for _turn in range(5):
		bm._phase_hero_post("musashi")
	_check(bm._hero_effective_speed("musashi") == bm.team_mgr.get_hero("musashi").speed + 9, "permanent speed retains highest named power")
	_check(bm._turn_queue_at["hero:musashi"] < queue_before, "speed change adjusts queued delay")
	_apply(bm, "card.napoleon.emperors_power.name")
	_apply(bm, "card.napoleon.emperors_power.name", true)
	bm._trigger_active_powers("player_turn_start", {"hero_id": "napoleon"})
	_check(bm.get_hero_status("napoleon").morale == 2, "recasting same morale power never doubles its rate")
	var counter = _find("card.counter.name")
	counter.owner_id = "musashi"
	bm._apply_card_effects(counter, -1)
	bm._apply_card_effects(counter, -1)
	_check(bm.get_hero_status("musashi").counter_pending == 1, "reflect reservation does not stack")
	_free(bm)
