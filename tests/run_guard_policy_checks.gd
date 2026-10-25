extends SceneTree

const Guard = preload("res://tools/guard_decision_policy.gd")
const Base = preload("res://tools/synergy_decision_policy.gd")
const Fixture = preload("res://tests/test_card_revision_runtime.gd")
const Catalog = preload("res://resources/card_catalog.gd")
const Profile = preload("res://resources/balance/small_number_profile.gd")
const Sim = preload("res://tools/simulate_small_number_battles.gd")
const Campaign = preload("res://tools/campaign_bot.gd")
var _cards := {}
var _passed := 0
var _failed := 0

func _init() -> void: call_deferred("_run")

func _check(ok: bool, label: String) -> void:
	if ok: _passed += 1
	else:
		_failed += 1
		print("FAIL: " + label)

func _card(hero: String, slug: String, live: bool) -> Resource:
	var source: Resource = _cards["card.%s.%s.name" % [hero, slug]]
	return Profile.candidate_pair(source).base if live else source.duplicate(true)

func _queue(bm: Object, current: String = "yi_sun_sin") -> void:
	bm._current_actor_id = "hero:" + current
	bm._turn_queue_at.clear()
	bm._turn_queue_at[bm._current_actor_id] = 0.0
	bm._turn_queue_at["enemy:0"] = 1.0
	for hero in bm.team_mgr.get_living_heroes():
		hero.speed = 1
		if hero.hero_id != current: bm._turn_queue_at["hero:" + hero.hero_id] = 2.0
	bm._enemies[0].speed = 1

func _run() -> void:
	AudioServer.set_bus_mute(0, true)
	OS.set_environment("STSL_LEGACY_COMBAT", "1")
	for card in Catalog.get_all_cards(): _cards[card.card_name] = card
	var fixture := Fixture.new()
	for live in [false, true]:
		var divisor := 10 if live else 1
		var bm = fixture._battle(["genghis_khan", "yi_sun_sin", "joan_of_arc"])
		bm.combat_unit_divisor = divisor
		for hero in bm.team_mgr.heroes:
			hero.max_hp = 1000 / divisor
			bm.team_mgr._hero_hp[hero.hero_id] = 1000 / divisor
			bm._hero_status[hero.hero_id] = {}
		_queue(bm)
		var intent: Resource = bm._enemies[0].intent_pattern[0]
		intent.value = 100 / divisor
		intent.target = Fixture.Intent.TargetType.ALL
		_check(Guard.forecast(bm).supported, "simple single enemy supported")
		_check(Guard.forecast(bm).threat.yi_sun_sin == 10.0, "undiscounted next AOE")
		bm._hero_status.yi_sun_sin.vulnerable = 1
		bm._hero_status.joan_of_arc.vulnerable = 1
		_check(Guard.forecast(bm).threat.yi_sun_sin == 10.0, "acting hero vulnerable1 expires before enemy")
		_check(Guard.forecast(bm).threat.joan_of_arc == 15.0, "ally vulnerability remains when enemy comes first")
		bm._hero_status.yi_sun_sin.clear()
		bm._hero_status.joan_of_arc.clear()
		bm._hero_status.joan_of_arc.exiled = 1
		_check(Guard.forecast(bm).threat.joan_of_arc == 10.0, "ALL still threatens exiled heroes")
		intent.target = Fixture.Intent.TargetType.RANDOM
		_check(Guard.forecast(bm).threat.joan_of_arc == 0.0, "ordinary single target excludes exiled")
		bm._enemy_status[0] = {"taunt": 1, "taunt_source": "joan_of_arc"}
		_check(Guard.forecast(bm).threat.joan_of_arc == 10.0, "living forced taunter can be exiled")
		_check(Guard.forecast(bm).threat.yi_sun_sin == 0.0, "forced target removes expected share elsewhere")
		bm._enemy_status[0].clear()
		intent.target = Fixture.Intent.TargetType.LAST_ATTACKER
		bm._last_attacker[0] = "joan_of_arc"
		_check(Guard.forecast(bm).threat.joan_of_arc == 10.0, "known last attacker overrides ordinary pool")
		bm._last_attacker.clear()
		bm._hero_status.joan_of_arc.clear()
		intent.target = Fixture.Intent.TargetType.ALL
		var buff := Fixture.Intent.new()
		buff.action_type = Fixture.Intent.ActionType.BUFF
		buff.status_type = "strength"
		buff.value = 20 / divisor
		bm._enemies[0].intent_pattern = [buff, intent]
		_check(Guard.forecast(bm).threat.yi_sun_sin > 0.0, "reserve sees attack after preparation")
		var normal: float = Guard.forecast(bm).threat.yi_sun_sin
		bm._enemy_status[0].weak = 1
		_check(Guard.forecast(bm).threat.yi_sun_sin == normal, "weak1 expires during enemy preparation")
		bm._enemy_status[0].clear()
		bm._enemies[0].intent_pattern = [intent]
		var charge := _card("yi_sun_sin", "charge_stance", live)
		bm._hero_block.yi_sun_sin = 300 / divisor
		_check(Guard.evaluate(bm, charge, 0, "yi_sun_sin").score > Base.evaluate(bm, charge, 0, "yi_sun_sin").score, "surplus block penalty refunded exactly once")
		bm._hero_block.yi_sun_sin = 40 / divisor
		_check(is_equal_approx(Guard.evaluate(bm, charge, 0, "yi_sun_sin").score, Base.evaluate(bm, charge, 0, "yi_sun_sin").score), "needed block consumption retains full marginal cost")
		var synthetic := Fixture.Card.new()
		synthetic.owner_id = "yi_sun_sin"
		synthetic.cost = 1
		var block := Fixture.Effect.new()
		block.effect_type = Fixture.Effect.EffectType.BLOCK
		block.value = 80 / divisor
		synthetic.effects = [block, charge.effects[0]]
		bm._hero_block.yi_sun_sin = 0
		_check(Guard.evaluate(bm, synthetic, 0, "yi_sun_sin").score < Base.evaluate(bm, synthetic, 0, "yi_sun_sin").score, "effect-order ledger charges consumption of newly granted block")
		synthetic.effects = [block, block.duplicate(true)]
		_check(Guard.evaluate(bm, synthetic, 0, "yi_sun_sin").score < Base.evaluate(bm, synthetic, 0, "yi_sun_sin").score, "second grant does not fill same guard deficit twice")
		var payoff := Fixture.Intent.new()
		payoff.action_type = Fixture.Intent.ActionType.CHARGE_UP
		payoff.charge_turns = 1
		payoff.payoff_intents = [intent, intent.duplicate(true)]
		bm._enemies[0].intent_pattern = [payoff]
		bm._hero_status.yi_sun_sin.counter_pending = 1
		_check(Guard.forecast(bm).threat.yi_sun_sin == 15.0, "counter mitigation applied once across composite hits")
		bm._hero_status.yi_sun_sin.clear()
		bm._enemy_status[0] = {"duel_lock": 1, "duel_lock_owner": "yi_sun_sin"}
		_check(Guard.forecast(bm).threat.yi_sun_sin == 30.0, "duel incoming amplification included")
		bm._enemy_status[0].clear()
		var debuff := Fixture.Intent.new()
		debuff.action_type = Fixture.Intent.ActionType.DEBUFF
		debuff.status_type = "vulnerable"
		payoff.payoff_intents = [debuff, intent]
		_check(not Guard.forecast(bm).supported, "unsupported debuff-before-charge-hit falls back")
		bm._enemies[0].intent_pattern = [intent]
		var strike := _card("yi_sun_sin", "strike", live)
		bm.deck_mgr._heroes.yi_sun_sin.hand.assign([strike])
		bm.deck_mgr._heroes.yi_sun_sin.energy = 3
		for key in ["stun", "enthrall", "double_action"]:
			bm._enemy_status[0][key] = 1
			_check(not Guard.forecast(bm).supported, "unsupported " + key + " falls back")
			_check(Guard.choose(bm, "yi_sun_sin").card == Base.choose(bm, "yi_sun_sin").card, "fallback preserves v1 choice:" + key)
			bm._enemy_status[0].clear()
		_check(Guard.choose(bm, "yi_sun_sin", func(_card: Resource) -> bool: return false).card == null, "campaign safety predicate honored")
		_check(Campaign._shared_policy_allowed("guard-aware", bm), "guard policy explicit campaign opt-in")
		bm._enemies[0].mythology = "buddhist"
		_check(not Campaign._shared_policy_allowed("guard-aware", bm), "existing Buddhist karma gate retained")
		bm._enemies[0].mythology = ""
		bm._enemies[0].time_limit_turns = 1
		_check(not Guard.forecast(bm).supported, "automatic turn-limit strength growth falls back")
		bm._enemies[0].time_limit_turns = 0
		var shield := _card("joan_of_arc", "last_shield", live)
		bm.team_mgr._hero_hp.joan_of_arc = 50 / divisor
		_check(Guard.evaluate(bm, shield, 0, "yi_sun_sin").score <= -999, "guard adjustment cannot lift fatal sacrifice gate")
		bm._hero_status.yi_sun_sin.vulnerable = 2
		_check(Guard.forecast(bm).threat.yi_sun_sin == 15.0, "vulnerable2 remains after active hero turn ends")
		bm._hero_status.yi_sun_sin.clear()
		bm._enemy_status[0] = {"taunt": 1, "taunt_source": "joan_of_arc"}
		intent.target = Fixture.Intent.TargetType.RANDOM
		bm._enemies[0].intent_pattern = [buff, intent]
		_check(Guard.forecast(bm).threat.yi_sun_sin > 0, "taunt1 expires during preparation rather than forcing future attack")
		bm._enemy_status[0].clear()
		intent.target = Fixture.Intent.TargetType.ALL
		bm._enemies[0].intent_pattern = [intent]
		bm._turn_queue_at.erase("enemy:0")
		_check(not Guard.forecast(bm).supported, "missing attack within bounded queue falls back")
		_queue(bm)
		var before := JSON.stringify(Sim._snapshot(bm, "check", "", 0)) + JSON.stringify(bm._turn_queue_at)
		seed(2468)
		var expected := randi()
		seed(2468)
		Guard.choose(bm, "yi_sun_sin")
		_check(randi() == expected, "v2 choice preserves RNG")
		_check(JSON.stringify(Sim._snapshot(bm, "check", "", 0)) + JSON.stringify(bm._turn_queue_at) == before, "v2 choice leaves state and queue untouched")
		fixture._free(bm)
		bm = fixture._battle(["napoleon", "joan_of_arc"])
		bm.combat_unit_divisor = divisor
		for hero in bm.team_mgr.heroes:
			hero.max_hp = 1000 / divisor
			bm.team_mgr._hero_hp[hero.hero_id] = 1000 / divisor
			bm._hero_status[hero.hero_id] = {}
		_queue(bm, "joan_of_arc")
		bm._enemies[0].intent_pattern[0].value = 100 / divisor
		bm._enemies[0].intent_pattern[0].target = Fixture.Intent.TargetType.ALL
		bm.team_mgr._hero_hp.joan_of_arc -= 50 / divisor
		var touch := _card("joan_of_arc", "holy_touch", live)
		var no_morale: float = Guard.evaluate(bm, touch, 0, "joan_of_arc").score - Base.evaluate(bm, touch, 0, "joan_of_arc").score
		bm._hero_status.napoleon.morale = 5
		_check(Guard.evaluate(bm, touch, 0, "joan_of_arc").score - Base.evaluate(bm, touch, 0, "joan_of_arc").score > no_morale, "overflow ledger uses runtime holy-war amplified healing")
		fixture._free(bm)
		bm = fixture._battle(["yi_sun_sin"], 2)
		_check(not Guard.forecast(bm).supported, "multiple enemies do not share one fictitious block pool")
		bm.deck_mgr._heroes.yi_sun_sin.hand.assign([_card("yi_sun_sin", "strike", live)])
		bm.deck_mgr._heroes.yi_sun_sin.energy = 3
		var fallback := Guard.choose(bm, "yi_sun_sin")
		var reference := Base.choose(bm, "yi_sun_sin")
		_check(fallback.card == reference.card and fallback.target == reference.target, "multi-enemy fallback exactly preserves v1 selection")
		fixture._free(bm)
	print("Guard policy checks: %d passed, %d failed" % [_passed, _failed])
	quit(0 if _failed == 0 and _passed == 74 else 1)
