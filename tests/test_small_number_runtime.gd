extends "res://tests/test_card_revision_runtime.gd"

func run_all() -> Dictionary:
	var bm = _battle(["cleopatra"])
	_check(bm.combat_unit_divisor == 1 and bm._combat_literal(25) == 25, "legacy literal helper defaults to identity")
	bm.combat_unit_divisor = 10
	_check(bm._combat_literal(0) == 0 and bm._combat_literal(5) == 1 and bm._combat_literal(25) == 3, "positive half-up integer literals")
	bm._enemy_status[0]["charm_resistance"] = 2
	bm._apply_status_to_enemy(0, "charm", 11)
	_check(bm._enemy_status[0].get("enthrall", 0) == 0, "small charm remains below 10 plus 2 threshold")
	_check(bm.will_enthrall_enemy(0, 1), "small charm preview matches threshold")
	bm._apply_status_to_enemy(0, "charm", 1)
	_check(bm._enemy_status[0].get("enthrall", 0) == 1 and bm._enemy_status[0].charm == 0, "small charm triggers exactly at 12")
	_free(bm)
	bm = _battle(["napoleon", "yi_sun_sin"])
	bm._apply_card_effects(_card("napoleon", Effect.EffectType.GAIN_MORALE, 3), 0)
	_check(bm._hero_block.napoleon == 15 and bm._hero_block.yi_sun_sin == 15, "default-unit morale synergy preserves legacy block15")
	_free(bm)
	bm = _battle(["napoleon", "yi_sun_sin"])
	bm.combat_unit_divisor = 10
	bm._apply_card_effects(_card("napoleon", Effect.EffectType.GAIN_MORALE, 3), 0)
	_check(bm._hero_status.napoleon.morale == 3, "morale count is not scaled")
	_check(bm._hero_block.napoleon == 2 and bm._hero_block.yi_sun_sin == 2, "morale synergy rounds total 15 to 2, not each stack")
	_free(bm)
	bm = _battle(["joan_of_arc"])
	bm.combat_unit_divisor = 10
	bm._hero_status["joan_of_arc"] = {"sacrifice_bank": 15}
	var payoff = _card("joan_of_arc", Effect.EffectType.SACRIFICE_PAYOFF, 12)
	bm._apply_card_effects(payoff, 0)
	_check(bm.get_enemy_hp(0) == 4988, "denominator-only contract: bank15 / small denominator10 * payoff12")
	_free(bm)
	return {"passed": passed, "failed": failed}

func run_detached_token_tests() -> Dictionary:
	var bm = _battle(["cleopatra"])
	var legacy_did: bool = await bm._run_token_attacks("cleopatra", 2)
	_check(legacy_did and bm.get_enemy_hp(0) == 4950, "detached two-token legacy damage executes without a scene timer")
	bm.combat_unit_divisor = 10
	var small_did: bool = await bm._run_token_attacks("cleopatra", 2)
	_check(small_did and bm.get_enemy_hp(0) == 4944, "detached small two-token damage retains actual runtime amount3 per token")
	_free(bm)
	return {"passed": passed, "failed": failed}
