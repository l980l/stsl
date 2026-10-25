extends SceneTree

const Tempo = preload("res://tools/tempo_decision_policy.gd")
const Guard = preload("res://tools/guard_decision_policy.gd")
const Base = preload("res://tools/synergy_decision_policy.gd")
const Fixture = preload("res://tests/test_card_revision_runtime.gd")
const Sim = preload("res://tools/simulate_small_number_battles.gd")
const Campaign = preload("res://tools/campaign_bot.gd")
var _passed := 0
var _failed := 0

func _init() -> void: call_deferred("_run")

func _check(ok: bool, label: String) -> void:
	if ok: _passed += 1
	else:
		_failed += 1
		print("FAIL: " + label)

func _run() -> void:
	AudioServer.set_bus_mute(0, true)
	OS.set_environment("STSL_LEGACY_COMBAT", "1")
	var fixture := Fixture.new()
	var reference_score := -1.0
	for divisor in [1, 10]:
		var bm = fixture._battle(["musashi"], 2)
		bm.combat_unit_divisor = divisor
		bm._hero_status.musashi = {}
		bm.team_mgr._hero_hp.musashi = 1000 / divisor
		bm._hero_block.musashi = 0
		bm._current_actor_id = "hero:musashi"
		for enemy in bm._enemies:
			enemy.intent_pattern[0].value = 100 / divisor
		var attack: Resource = fixture._card("musashi", Fixture.Effect.EffectType.DAMAGE, 100 / divisor)
		attack.cost = 1
		attack.card_type = 0
		attack.effects[0].damage_type = "slash"
		attack.effects[0].target = "SINGLE"
		bm._enemy_hp = [600 / divisor, 400 / divisor]
		bm.deck_mgr._heroes.musashi.hand.assign([attack])
		bm.deck_mgr._heroes.musashi.energy = 3
		_check(Tempo.choose(bm, "musashi").target == 1, "focus lower HP instead of first slot")
		var normalized_score: float = Tempo.evaluate(bm, attack, 1, "musashi").score
		if reference_score < 0.0: reference_score = normalized_score
		_check(is_equal_approx(normalized_score, reference_score), "same physical state scores equally across unit systems")
		var poison: Resource = fixture._card("musashi", Fixture.Effect.EffectType.APPLY_STATUS, 10 / divisor)
		poison.effects[0].status_type = "poison"
		poison.effects[0].target = "SINGLE"
		poison.cost = 1
		bm.deck_mgr._heroes.musashi.hand.assign([poison])
		_check(Tempo.choose(bm, "musashi").target == 1, "status-only poison does not seed first slot by tie")
		bm.deck_mgr._heroes.musashi.hand.assign([attack])
		bm._enemy_hp[0] = 100 / divisor
		_check(Tempo.choose(bm, "musashi").target == 0, "immediate removal overrides low-slot bias")
		bm._hero_status.musashi.taunt = 2
		bm._hero_status.musashi.taunt_source = 1
		var lock: int = bm._get_taunt_lock_target("musashi")
		_check(lock == 1 and Tempo.choose(bm, "musashi").target == lock, "active target lock overrides lethal other target")
		bm._hero_status.musashi.clear()
		bm._enemy_status[1].clear()
		_check(Tempo.choose(bm, "musashi", func(_card: Resource) -> bool: return false).card == null, "safety predicate cannot be bypassed")
		bm._hero_status.musashi.silence = 1
		_check(Tempo.choose(bm, "musashi").is_empty(), "silence prevents choices")
		bm._hero_status.musashi.clear()
		var amp: Resource = fixture._card("musashi", Fixture.Effect.EffectType.APPLY_STATUS, 0)
		amp.effects[0].status_type = "power.spend_all_energy_poison_double"
		amp.cost = 0
		bm.deck_mgr._heroes.musashi.hand.assign([amp, attack])
		_check(Tempo.evaluate(bm, amp, 0, "musashi").score <= -999, "no unseeded energy sink")
		bm._enemy_status[1] = {"poison_dmg": 30 / divisor, "poison_dur": 2}
		_check(Tempo.evaluate(bm, amp, 0, "musashi").score > 0.0, "existing poison can be amplified")
		bm.deck_mgr._heroes.musashi.energy = 0
		_check(Tempo.evaluate(bm, amp, 0, "musashi").score <= -999, "zero energy amplification is not free power")
		bm.deck_mgr._heroes.musashi.energy = 3
		bm._enemy_hp[1] = 20 / divisor
		_check(Tempo.evaluate(bm, amp, 0, "musashi").score <= -999, "do not amplify already sufficient poison")
		bm._enemy_hp = [600 / divisor, 400 / divisor]
		bm._enemy_status[1].clear()
		var power: Resource = fixture._card("musashi", Fixture.Effect.EffectType.APPLY_STATUS, 20 / divisor)
		power.cost = 1
		power.card_type = 2
		power.effects[0].status_type = "power.bonus_per_hit"
		bm.deck_mgr._heroes.musashi.hand.assign([power, attack])
		var safe := Tempo.tempo_context(bm, "musashi")
		var setup: float = Tempo.evaluate(bm, power, 0, "musashi").score
		attack.effects[0].hit_count = 3
		var multi_hit_setup: float = Tempo.evaluate(bm, power, 0, "musashi").score
		_check(multi_hit_setup > setup, "multi-hit makes known setup more valuable")
		bm.deck_mgr._heroes.musashi.energy = 1
		_check(Tempo.evaluate(bm, power, 0, "musashi").score < multi_hit_setup, "setup cannot assume unaffordable current follow-up")
		bm.deck_mgr._heroes.musashi.pending_cost_reduction = 1
		bm.deck_mgr._heroes.musashi.cost_reduction_count = 1
		_check(Tempo._followup_cost(bm, power, attack) == 1, "setup consumes last general discount before follow-up")
		bm.deck_mgr._heroes.musashi.cost_reduction_count = 2
		_check(Tempo._followup_cost(bm, power, attack) == 0, "multi-use discount remains for follow-up")
		bm.deck_mgr._heroes.musashi.pending_cost_reduction = 0
		bm.deck_mgr._heroes.musashi.energy = 3
		bm.team_mgr._hero_hp.musashi = 100 / divisor
		var threatened := Tempo.tempo_context(bm, "musashi")
		_check(safe.horizon > threatened.horizon, "lethal current pressure removes speculative future horizon")
		var sacrifice: Resource = fixture._card("musashi", Fixture.Effect.EffectType.SACRIFICE_HP, 100 / divisor)
		_check(Tempo.evaluate(bm, sacrifice, 0, "musashi").score <= -999, "fatal sacrifice gate retained")
		bm.team_mgr._hero_hp.musashi = 1000 / divisor
		var before := JSON.stringify(Sim._snapshot(bm, "check", "", 0)) + JSON.stringify(bm._turn_queue_at)
		seed(9283)
		var expected := randi()
		seed(9283)
		Tempo.choose(bm, "musashi")
		_check(randi() == expected, "candidate preserves RNG")
		_check(JSON.stringify(Sim._snapshot(bm, "check", "", 0)) + JSON.stringify(bm._turn_queue_at) == before, "candidate preserves state/queue/piles")
		var draw_a: Resource = attack.duplicate(true)
		var draw_b: Resource = power.duplicate(true)
		bm.deck_mgr._heroes.musashi.draw.assign([draw_a, draw_b])
		var composition_before := Tempo.tempo_context(bm, "musashi")
		bm.deck_mgr._heroes.musashi.draw.reverse()
		_check(Tempo.tempo_context(bm, "musashi") == composition_before, "future draw order cannot change aggregate tempo context")
		_check(Campaign._shared_policy_allowed("tempo-aware", bm), "explicit campaign opt-in")
		bm._enemies[0].mythology = "buddhist"
		_check(not Campaign._shared_policy_allowed("tempo-aware", bm), "Buddhist campaign fallback preserved")
		bm._enemies[0].mythology = ""
		bm._enemy_alive[1] = false
		var old: Dictionary = Guard.choose(bm, "musashi")
		var current: Dictionary = Tempo.choose(bm, "musashi")
		_check(old == current, "single enemy delegates exactly to v2")
		fixture._free(bm)
	print("Tempo policy checks: %d passed, %d failed" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)
