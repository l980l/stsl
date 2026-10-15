class_name TestSmallNumberProgression
extends RefCounted

const HeroRegistry = preload("res://resources/heroes/hero_registry.gd")
const SaveManagerClass = preload("res://autoload/save_manager.gd")
const Relics = preload("res://resources/relics/relics.gd")
const EventsAct1 = preload("res://resources/events/events_act1.gd")
const EventsDaoist = preload("res://resources/events/events_daoist.gd")

var passed := 0
var failed := 0

func run_all() -> Dictionary:
	test_hero_registry_uses_small_hp()
	test_legacy_save_hp_migrates_in_memory_once()
	test_event_hp_rewards_and_costs_scale_but_gold_does_not()
	test_relic_combat_values_scale_and_run_strength_does_not()
	return {"passed": passed, "failed": failed}

func _assert(condition: bool, message: String) -> void:
	if condition:
		passed += 1
		print("  PASS: " + message)
	else:
		failed += 1
		push_error("  FAIL: " + message)

func test_hero_registry_uses_small_hp() -> void:
	for hero_id in HeroRegistry.all_hero_ids():
		_assert(HeroRegistry.make_hero(hero_id).max_hp == 100, "%s starts at 100 HP" % hero_id)

func test_legacy_save_hp_migrates_in_memory_once() -> void:
	var legacy := {
		"version": 2,
		"team_manager": {
			"heroes": [
				{"hero_id": "napoleon", "max_hp": 1000, "current_hp": 750},
				{"hero_id": "cleopatra", "max_hp": 1000, "current_hp": 0},
			],
		},
	}
	var migrated := SaveManagerClass.prepare_for_load(legacy)
	var heroes: Array = migrated["team_manager"]["heroes"]
	_assert(heroes[0]["max_hp"] == 100 and heroes[0]["current_hp"] == 75, "legacy max/current HP convert 1000/750 -> 100/75")
	_assert(heroes[1]["current_hp"] == 0, "zero HP remains zero")
	_assert(legacy["team_manager"]["heroes"][0]["max_hp"] == 1000, "migration does not mutate source save data")
	_assert(migrated["combat_unit_version"] == SaveManagerClass.COMBAT_UNIT_VERSION, "migrated data gets unit marker")
	var second := SaveManagerClass.prepare_for_load(migrated)
	_assert(second["team_manager"]["heroes"][0]["max_hp"] == 100, "marked small-unit save is not scaled twice")

func test_event_hp_rewards_and_costs_scale_but_gold_does_not() -> void:
	var wounded = _event_by_name(EventsAct1.build_pool(), "event.act1.wounded_warrior.name")
	_assert(wounded != null, "Act 1 wounded warrior exists")
	var heal_choice: Resource = wounded.choices[0]
	var loot_choice: Resource = wounded.choices[1]
	_assert(heal_choice.value == 2 and heal_choice.cost_gold == 20, "event heal 15 -> 2 while gold cost remains 20")
	_assert(loot_choice.value == 20 and loot_choice.cost_hp == 1, "event gold 20 remains while HP cost 5 -> 1")
	var peach = _event_by_name(EventsDaoist.build_pool(), "event.daoist.peach_of_immortality.name")
	_assert(peach.choices[0].value == 4 and peach.choices[1].cost_hp == 2, "event heal 40 -> 4 and HP cost 15 -> 2")

func test_relic_combat_values_scale_and_run_strength_does_not() -> void:
	var pool := Relics.build_pool()
	var artifact := _relic_by_name(pool, "relic.ancient_artifact.name")
	var scarab := _relic_by_name(pool, "relic.scarab_talisman.name")
	var blood_stone := _relic_by_name(pool, "relic.blood_stone.name")
	var rune := _relic_by_name(pool, "relic.rune_of_fate.name")
	var poison_vial := _relic_by_name(pool, "relic.poison_vial.name")
	var bracelet := _relic_by_name(pool, "relic.serpent_bracelet.name")
	var tengu := _relic_by_name(pool, "relic.tengu_feather.name")
	var whip := _relic_by_name(pool, "relic.conquerors_whip.name")
	var scroll := Relics._make_sacred_scroll(2)
	_assert(artifact.value == 2, "relic max HP 15 -> 2")
	_assert(scarab.value == 4, "relic poison 40 -> 4")
	_assert(blood_stone.value == 1 and blood_stone.condition_value == 1, "damage threshold 5 -> 1 while energy remains 1")
	_assert(rune.value == 1, "run-strength coefficient stays legacy-scale for aggregate conversion")
	_assert(poison_vial.value == 1, "empty-status poison vial scales legacy poison 3 to 1")
	_assert(bracelet.value == 1 and bracelet.bonus_value == 1, "empty-status serpent bracelet scales both poison amounts")
	_assert(rune.display_description_key() == "relic.rune_of_fate.small.desc", "kill strength uses the small-unit explanation")
	_assert(tengu.display_description_key() == "relic.tengu_feather.small.desc", "battle strength uses the small-unit explanation")
	_assert(whip.display_description_key() == "relic.conquerors_whip.small.desc", "per-hit strength uses the small-unit explanation")
	_assert(scroll.value == 2 and scroll.condition_value == 2, "draw count and turn number stay unchanged")
	_assert(artifact.format_description("Team Max HP +15") == "Team Max HP +2", "relic display replaces scaled HP literal")

func _event_by_name(pool: Array, event_name: String) -> Resource:
	for event in pool:
		if event.event_name == event_name:
			return event
	return null

func _relic_by_name(pool: Array, relic_name: String) -> Resource:
	for relic in pool:
		if relic.relic_name == relic_name:
			return relic
	return null
