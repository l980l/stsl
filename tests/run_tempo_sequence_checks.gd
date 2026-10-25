extends "res://tests/run_tempo_policy_checks.gd"

const Sequence = preload("res://tools/tempo_sequence_decision_policy.gd")

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
		bm._turn_queue_at = {"hero:musashi": 0.0, "enemy:0": 1.0, "enemy:1": 2.0}
		bm.team_mgr.get_hero("musashi").max_hp = 1000 / divisor
		bm.team_mgr._hero_hp.musashi = 500 / divisor
		bm._enemy_hp = [330 / divisor, 380 / divisor]
		for enemy in bm._enemies: enemy.intent_pattern[0].value = 90 / divisor
		var attack: Resource = fixture._card("musashi", Fixture.Effect.EffectType.DAMAGE, 100 / divisor)
		attack.effects[0].damage_type = "slash"
		attack.effects[0].target = "SINGLE"
		attack.cost = 1
		attack.card_type = 0
		var shield: Resource = fixture._card("musashi", Fixture.Effect.EffectType.BLOCK, 80 / divisor)
		shield.effects[0].target = "SELF"
		shield.cost = 1
		var heal = Fixture.Effect.new()
		heal.effect_type = Fixture.Effect.EffectType.HEAL
		heal.value = 20 / divisor
		heal.target = "SELF"
		shield.effects.append(heal)
		bm.deck_mgr._heroes.musashi.hand.assign([attack, shield])
		bm.deck_mgr._heroes.musashi.energy = 3
		_check(Sequence._exposed_attackers(bm, "musashi") == 2, "only current attacks before next owner counted")
		var saved_queue: Dictionary = bm._turn_queue_at.duplicate()
		bm._turn_queue_at = {"enemy:0": 0.0, "enemy:1": 1.0}
		_check(Sequence._exposed_attackers(bm, "musashi") == 0, "missing owner boundary fails closed")
		bm._turn_queue_at = saved_queue
		_check(Sequence.choose(bm, "musashi").card == shield, "jointly affordable restorative guard before nonlethal attack")
		_check(Sequence.choose(bm, "musashi", func(c: Resource) -> bool: return c == attack).card == attack, "callback excludes guard override")
		bm._hero_block.musashi = 1
		_check(Sequence.choose(bm, "musashi") == Tempo.choose(bm, "musashi"), "existing reserve leaves v3 unchanged")
		bm._hero_block.musashi = 0
		bm._enemies[1].intent_pattern[0].action_type = Fixture.Intent.ActionType.BUFF
		_check(Sequence.choose(bm, "musashi") == Tempo.choose(bm, "musashi"), "single attacker stays v3")
		bm._enemies[1].intent_pattern[0].action_type = Fixture.Intent.ActionType.ATTACK
		var second: Resource = attack.duplicate(true)
		var third: Resource = attack.duplicate(true)
		bm._enemy_hp[0] = 300 / divisor
		bm.deck_mgr._heroes.musashi.hand.assign([attack, second, third, shield])
		_check(Sequence._potential_removal(bm, "musashi", Callable()), "affordable visible three-attack removal recognized")
		_check(Sequence.choose(bm, "musashi") == Tempo.choose(bm, "musashi"), "preserve v3 when current hand can remove pressure")
		bm.deck_mgr._heroes.musashi.hand.assign([attack, shield])
		bm.deck_mgr._heroes.musashi.energy = 1
		_check(Sequence.choose(bm, "musashi") == Tempo.choose(bm, "musashi"), "cannot spend last energy on speculative guard-followup")
		bm.deck_mgr._heroes.musashi.energy = 3
		bm._enemy_hp[0] = 10 / divisor
		var power: Resource = fixture._card("musashi", Fixture.Effect.EffectType.APPLY_STATUS, 1)
		power.effects[0].status_type = "power.on_kill_energy_once"
		power.effects[0].target = "SELF"
		power.card_type = 2
		power.cost = 1
		bm.deck_mgr._heroes.musashi.hand.assign([attack, power])
		_check(Sequence.choose(bm, "musashi").card == power, "refund setup before visible same-card lethal")
		bm._turn_effect_uses.musashi = {"kill_energy": true}
		_check(Sequence.choose(bm, "musashi") == Tempo.choose(bm, "musashi"), "already-used once-per-turn refund cannot fund setup")
		bm._turn_effect_uses.clear()
		bm.deck_mgr._heroes.musashi.energy = 1
		_check(Sequence.choose(bm, "musashi").card == attack, "setup and lethal must both fit energy")
		bm.deck_mgr._heroes.musashi.energy = 3
		_check(Sequence.choose(bm, "musashi", func(c: Resource) -> bool: return c == attack).card == attack, "callback excludes refund setup")
		bm._hero_status.musashi.silence = 1
		_check(Sequence.choose(bm, "musashi").is_empty(), "silence preserved")
		bm._hero_status.musashi.clear()
		var before := JSON.stringify(Sim._snapshot(bm, "check", "", 0)) + JSON.stringify(bm._turn_queue_at) + JSON.stringify(bm._turn_effect_uses)
		seed(27011)
		var expected := randi()
		seed(27011)
		Sequence.choose(bm, "musashi")
		_check(randi() == expected, "no target or draw RNG consumption")
		_check(JSON.stringify(Sim._snapshot(bm, "check", "", 0)) + JSON.stringify(bm._turn_queue_at) + JSON.stringify(bm._turn_effect_uses) == before, "no live-state/queue/turn-use mutation")
		bm.is_player_turn = true
		var energy_before: int = bm.deck_mgr.get_energy("musashi")
		_check(bm.play_card(power, 0, "musashi"), "real runtime accepts supported refund setup")
		_check(bm.play_card(attack, 0, "musashi"), "real runtime accepts the jointly budgeted finisher")
		_check(bm.deck_mgr.get_energy("musashi") == energy_before - 1, "real setup+kill refunds setup cost without invented energy")
		bm._enemy_alive[1] = false
		_check(Sequence.choose(bm, "musashi") == Guard.choose(bm, "musashi"), "exact single-enemy guard-v2 fallback")
		fixture._free(bm)
	var team = fixture._battle(["musashi", "napoleon"], 2)
	team._current_actor_id = "hero:musashi"
	team.team_mgr._hero_alive.napoleon = false
	team.team_mgr._hero_hp.napoleon = 0
	_check(Sequence.choose(team, "musashi") == Tempo.choose(team, "musashi"), "team does not become solo rollout after an ally dies")
	fixture._free(team)
	print("Tempo sequence checks: %d passed, %d failed" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)
