extends "res://tests/run_tempo_policy_checks.gd"

const Safe = preload("res://tools/tempo_survival_decision_policy.gd")

func _run() -> void:
	AudioServer.set_bus_mute(0, true)
	OS.set_environment("STSL_LEGACY_COMBAT", "1")
	var fixture := Fixture.new()
	for divisor in [1, 10]:
		var bm = fixture._battle(["musashi"], 2)
		bm.combat_unit_divisor = divisor
		bm._hero_status.musashi = {}
		bm._hero_block.musashi = 0
		bm._current_actor_id = "hero:musashi"
		bm.team_mgr.get_hero("musashi").max_hp = 1000 / divisor
		bm.team_mgr._hero_hp.musashi = 500 / divisor
		bm._enemy_hp = [330 / divisor, 380 / divisor]
		for enemy in bm._enemies: enemy.intent_pattern[0].value = 90 / divisor
		var attack: Resource = fixture._card("musashi", Fixture.Effect.EffectType.DAMAGE, 100 / divisor)
		attack.effects[0].damage_type = "slash"
		attack.effects[0].target = "SINGLE"
		attack.card_type = 0
		attack.cost = 1
		var shield: Resource = fixture._card("musashi", Fixture.Effect.EffectType.BLOCK, 80 / divisor)
		var heal = Fixture.Effect.new()
		heal.effect_type = Fixture.Effect.EffectType.HEAL
		heal.value = 20 / divisor
		heal.target = "SELF"
		shield.effects.append(heal)
		shield.cost = 1
		bm.deck_mgr._heroes.musashi.energy = 3
		bm.deck_mgr._heroes.musashi.hand.assign([attack, shield])
		_check(Tempo.choose(bm, "musashi").card == attack, "counterexample: v3 partial focus outbids useful shield")
		_check(Safe.choose(bm, "musashi").card == shield, "core utility protects guard from nonlethal progress")
		bm.deck_mgr._heroes.musashi.hand.assign([attack])
		bm._enemy_hp = [500 / divisor, 330 / divisor]
		_check(Safe.choose(bm, "musashi").target == 1, "same-card equal-core targets retain focus tie break")
		bm._enemy_hp = [10 / divisor, 380 / divisor]
		attack.effects[0].value = 90 / divisor
		_check(Tempo.choose(bm, "musashi").target == 0, "v3 overkill target reproducer")
		_check(Safe.choose(bm, "musashi").target == 1, "focus cannot override larger damage-capped core value")
		attack.effects[0].target = "ALL"
		var area0 := Safe.evaluate(bm, attack, 0, "musashi")
		var area1 := Safe.evaluate(bm, attack, 1, "musashi")
		_check(is_equal_approx(area0.score, area1.score) and area0.focus_score == area0.score, "area attack has no fake targeted removal tie bonus")
		attack.effects[0].target = "SINGLE"
		attack.effects[0].effect_type = Fixture.Effect.EffectType.CONDITIONAL_DMG
		var conditional := Safe.evaluate(bm, attack, 0, "musashi")
		_check(conditional.focus_score == conditional.score, "conditional damage is not a deterministic focus tie bonus")
		attack.effects[0].effect_type = Fixture.Effect.EffectType.DAMAGE
		var mixed = attack.effects[0].duplicate(true)
		mixed.target = "ALL"
		attack.effects.append(mixed)
		var mixed_value := Safe.evaluate(bm, attack, 0, "musashi")
		_check(mixed_value.focus_score == mixed_value.score, "mixed SINGLE/ALL card cannot reintroduce targeted kill bonus")
		attack.effects.pop_back()
		bm._hero_status.musashi.taunt = 2
		bm._hero_status.musashi.taunt_source = 0
		_check(Safe.choose(bm, "musashi").target == 0, "taunt lock preserved")
		bm._hero_status.musashi.clear()
		_check(Safe.choose(bm, "musashi", func(_c: Resource) -> bool: return false).card == null, "allowed predicate preserved")
		bm._hero_status.musashi.silence = 1
		_check(Safe.choose(bm, "musashi").is_empty(), "silence preserved")
		bm._hero_status.musashi.clear()
		var fatal: Resource = fixture._card("musashi", Fixture.Effect.EffectType.SACRIFICE_HP, 500 / divisor)
		_check(Safe.evaluate(bm, fatal, 0, "musashi").score <= -999, "fatal sacrifice gate preserved")
		var before := JSON.stringify(Sim._snapshot(bm, "check", "", 0)) + JSON.stringify(bm._turn_queue_at)
		seed(81819)
		var expected := randi()
		seed(81819)
		Safe.choose(bm, "musashi")
		_check(randi() == expected, "no RNG consumption")
		_check(JSON.stringify(Sim._snapshot(bm, "check", "", 0)) + JSON.stringify(bm._turn_queue_at) == before, "no state/queue/pile mutation")
		bm._enemy_alive[1] = false
		_check(Safe.choose(bm, "musashi") == Guard.choose(bm, "musashi"), "exact single-enemy fallback")
		fixture._free(bm)
	print("Tempo survival checks: %d passed, %d failed" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)
