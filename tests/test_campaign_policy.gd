extends SceneTree

func _initialize() -> void:
	var policy = load("res://tools/campaign_bot.gd")
	var ok: bool = policy._budget_pick([180.0, 288.0, 180.0, 180.0], [1, 2, 1, 1], 3) != 1
	ok = ok and policy._budget_pick([180.0, 45.0], [1, 0], 1) == 1
	ok = ok and policy._budget_pick([-10.0, 0.0], [1, 1], 3) == -1
	ok = ok and policy._budget_pick([10.0], [2], 1) == -1
	ok = ok and policy._budget_pick([180.0, 288.0], [1, 2], 2) == 1
	ok = ok and not policy._input_matches_turn(2, 1, "hero:napoleon", "hero:napoleon", true)
	ok = ok and not policy._input_matches_turn(2, 2, "", "hero:napoleon", true)
	ok = ok and not policy._input_matches_turn(2, 2, "hero:napoleon", "hero:napoleon", false)
	ok = ok and policy._input_matches_turn(2, 2, "hero:napoleon", "hero:napoleon", true)
	var effect = load("res://resources/effect_resource.gd").new()
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
