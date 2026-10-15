class_name TestEnemySmallNumbers
extends RefCounted

const EnemySmallNumbers = preload("res://resources/balance/enemy_small_numbers.gd")
const MonsterCatalog = preload("res://resources/monster_catalog.gd")
const GreekAct1 = preload("res://resources/enemies/greek/greek_act1.gd")
const GreekAct3 = preload("res://resources/enemies/greek/greek_act3.gd")
const DaoistAct3 = preload("res://resources/enemies/daoist/daoist_act3.gd")
const BuddhistNormals = preload("res://resources/enemies/buddhist/buddhist_normals.gd")
const IntentRes = preload("res://resources/intent_resource.gd")
const CombatScale = preload("res://resources/balance/combat_scale.gd")

var passed := 0
var failed := 0

func run_all() -> Dictionary:
	test_convert_scales_complete_boss_graph()
	test_convert_preserves_non_hp_values()
	test_sacrifice_keeps_independent_hp_cost()
	test_catalog_uses_live_profile_for_every_enemy()
	return {"passed": passed, "failed": failed}

func _assert(condition: bool, message: String) -> void:
	if condition:
		passed += 1
		print("  PASS: " + message)
	else:
		failed += 1
		print("  FAIL: " + message)

func test_convert_scales_complete_boss_graph() -> void:
	print("[TestEnemySmallNumbers] complete boss graph")
	var source: Resource = GreekAct1.hydra(null)
	var scaled: Resource = EnemySmallNumbers.convert(source)
	var unit := 10 if CombatScale.enabled() else 1
	_assert(scaled != source and EnemySmallNumbers.is_converted(scaled) == CombatScale.enabled(), "conversion returns an appropriately marked clone")
	_assert(source.max_hp == 4500 and scaled.max_hp == 4500 / unit, "max HP conversion does not change source")
	_assert(scaled.charm_resistance == 20 / unit, "charm resistance conversion")
	var p0: Resource = scaled.phase_patterns[0][0]
	var poison: Resource = scaled.phase_patterns[2][5]
	var charge: Resource = scaled.phase_patterns[2][2]
	_assert(p0.value == 180 / unit, "phase attack conversion")
	_assert(poison.status_type == "vulnerable" and poison.value == 2, "vulnerable stack count remains 2")
	_assert(charge.action_type == IntentRes.ActionType.CHARGE_UP and charge.charge_turns == 2, "charge duration remains 2")
	_assert(charge.payoff_intents[0].value == 260 / unit and charge.payoff_intents[1].value == 40 / unit, "nested payoff attack/poison are converted")

func test_convert_preserves_non_hp_values() -> void:
	print("[TestEnemySmallNumbers] dimensions")
	var source: Resource = GreekAct3.kronos(null)
	var scaled: Resource = EnemySmallNumbers.convert(source)
	var double_action: Dictionary = scaled.phase_buffs[2][0]
	_assert(double_action.get("status") == "double_action" and int(double_action.get("value")) == 5, "phase action count remains 5")
	var source_summoner: Resource = DaoistAct3.jade_emperor(null)
	var summoner: Resource = EnemySmallNumbers.convert(source_summoner)
	var summon: Resource = _find_action(summoner, IntentRes.ActionType.SUMMON)
	_assert(summon != null and summon.value == 2, "summon count remains 2")

func test_sacrifice_keeps_independent_hp_cost() -> void:
	print("[TestEnemySmallNumbers] sacrifice dimensions")
	var scaled: Resource = EnemySmallNumbers.convert(BuddhistNormals.ashura_warrior(null))
	var sacrifice: Resource = scaled.intent_pattern[0]
	_assert(sacrifice.value == CombatScale.amount(5), "sacrifice strength gain is converted")
	var expected_hp_cost := 5 if CombatScale.enabled() else -1
	_assert(sacrifice.small_sacrifice_hp_cost == expected_hp_cost, "sacrifice HP cost remains independently scaled")
	var copied: Resource = EnemySmallNumbers.convert(scaled)
	_assert(copied.intent_pattern[0].small_sacrifice_hp_cost == expected_hp_cost, "sacrifice HP cost survives repeated conversion")

func test_catalog_uses_live_profile_for_every_enemy() -> void:
	print("[TestEnemySmallNumbers] catalog coverage")
	var catalog: Array = MonsterCatalog.get_all_monsters()
	_assert(catalog.size() >= 120, "catalog exposes normals, elites and bosses (%d)" % catalog.size())
	var all_marked := true
	var valid_hp := true
	for enemy in catalog:
		all_marked = all_marked and EnemySmallNumbers.is_converted(enemy)
		valid_hp = valid_hp and enemy.max_hp > 0 and enemy.max_hp <= (520 if CombatScale.enabled() else 5200)
	_assert(all_marked == CombatScale.enabled(), "catalog conversion follows live/legacy mode")
	_assert(valid_hp, "all catalog enemies have valid HP for the selected mode")

func _find_action(enemy: Resource, action_type: int) -> Resource:
	for pattern in enemy.phase_patterns:
		if pattern is Array:
			for intent in pattern:
				if intent.action_type == action_type:
					return intent
	for intent in enemy.intent_pattern:
		if intent.action_type == action_type:
			return intent
	return null
