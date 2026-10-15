extends SceneTree

func _initialize() -> void:
	var policy = load("res://tools/campaign_bot.gd")
	var restored_ids: Array = policy._integer_ids(JSON.parse_string("[24, 59]"))
	var restored_node_ok: bool = 24 in restored_ids and 59 in restored_ids
	var ok: bool = policy._budget_pick([180.0, 288.0, 180.0, 180.0], [1, 2, 1, 1], 3) != 1
	ok = ok and restored_node_ok
	ok = ok and policy._budget_pick([180.0, 45.0], [1, 0], 1) == 1
	ok = ok and policy._budget_pick([-10.0, 0.0], [1, 1], 3) == -1
	ok = ok and policy._budget_pick([10.0], [2], 1) == -1
	ok = ok and policy._budget_pick([180.0, 288.0], [1, 2], 2) == 1
	ok = ok and not policy._input_matches_turn(2, 1, "hero:napoleon", "hero:napoleon", true)
	ok = ok and not policy._input_matches_turn(2, 2, "", "hero:napoleon", true)
	ok = ok and not policy._input_matches_turn(2, 2, "hero:napoleon", "hero:napoleon", false)
	ok = ok and policy._input_matches_turn(2, 2, "hero:napoleon", "hero:napoleon", true)
	var effect = load("res://resources/effect_resource.gd").new()
	ok = ok and policy._cleanse_value({"poison_dmg": 4, "poison_dur": 3}, 10) == 360.0
	ok = ok and policy._cleanse_value({"poison_dmg": 40, "poison_dur": 3}, 1) == 360.0
	ok = ok and policy._cleanse_value({"poison_dmg": 4, "poison_dur": 0}, 10) == 0.0
	ok = ok and policy._cleanse_value({"weak": 1, "vulnerable": 1}, 10) == 100.0
	ok = ok and policy._guard_demand(0.0, 0, 100) == 10.0
	ok = ok and policy._guard_demand(20.0, 12, 100) == 18.0
	ok = ok and policy._guard_demand(0.0, 20, 100) == 0.0
	effect.effect_type = effect.EffectType.BLOCK
	ok = ok and not policy._karma_damage_risk(effect)
	effect.damage_type = "slash"
	ok = ok and policy._karma_damage_risk(effect)
	effect.damage_type = ""
	effect.status_type = "poison"
	ok = ok and policy._karma_damage_risk(effect)
	effect.status_type = ""
	effect.effect_type = effect.EffectType.COUNTER_REFLECT
	ok = ok and policy._karma_damage_risk(effect)
	effect.effect_type = effect.EffectType.SUMMON_TOKEN
	ok = ok and policy._karma_damage_risk(effect)
	print("Campaign energy-budget, input and karma policy: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
