extends SceneTree

const Policy = preload("res://tools/synergy_decision_policy.gd")
const Fixture = preload("res://tests/test_card_revision_runtime.gd")
const Profile = preload("res://resources/balance/small_number_profile.gd")
const Catalog = preload("res://resources/card_catalog.gd")
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

func _run() -> void:
	AudioServer.set_bus_mute(0, true)
	OS.set_environment("STSL_LEGACY_COMBAT", "1")
	for card in Catalog.get_all_cards(): _cards[card.card_name] = card
	var fixture := Fixture.new()
	for live in [false, true]:
		var divisor := 10 if live else 1
		var bm = fixture._battle(["genghis_khan", "joan_of_arc", "yi_sun_sin"], 2)
		_check(not Campaign._shared_policy_allowed("corrected", bm), "existing campaign default unchanged")
		_check(Campaign._shared_policy_allowed("synergy-aware", bm), "campaign explicitly opts in")
		bm._enemies[1].mythology = "buddhist"
		_check(not Campaign._shared_policy_allowed("synergy-aware", bm), "living Buddhist enemies retain established karma policy")
		bm._enemy_alive[1] = false
		_check(Campaign._shared_policy_allowed("synergy-aware", bm), "dead Buddhist does not gate remaining non-Buddhist enemies")
		bm._enemies[1].mythology = ""
		bm._enemy_alive[1] = true
		bm.combat_unit_divisor = divisor
		for hero in bm.team_mgr.heroes:
			hero.max_hp = 1000 / divisor
			bm.team_mgr._hero_hp[hero.hero_id] = 1000 / divisor
			bm._hero_status[hero.hero_id] = {}
		for enemy in bm._enemies:
			enemy.intent_pattern[0].value = 100 / divisor
		var raid := _card("genghis_khan", "swift_raid", live)
		var strike := _card("genghis_khan", "strike", live)
		var hand: Dictionary = bm.deck_mgr._heroes.genghis_khan
		hand.energy = 3
		hand.hand.assign([strike, raid])
		_check(Policy.choose(bm, "genghis_khan").card == raid, "opening before regular attack")
		var snapshot := JSON.stringify(Sim._snapshot(bm, "check", "", 0))
		seed(4321)
		var expected := randi()
		seed(4321)
		Policy.choose(bm, "genghis_khan")
		_check(randi() == expected, "choice does not consume RNG")
		_check(JSON.stringify(Sim._snapshot(bm, "check", "", 0)) == snapshot, "choice leaves combat and deck unchanged")
		bm._hero_status.genghis_khan["taunt"] = 1
		bm._hero_status.genghis_khan["taunt_source"] = 1
		_check(Policy.choose(bm, "genghis_khan").target == 1, "forced enemy target")
		bm._enemy_alive[1] = false
		bm._enemy_hp[1] = 0
		_check(Policy.choose(bm, "genghis_khan").target == 0, "dead taunt source ignored")
		bm._hero_status.genghis_khan.clear()
		hand.hand.assign([strike])
		hand.energy = 0
		_check(Policy.choose(bm, "genghis_khan").card == null, "unaffordable excluded")
		hand.energy = 3
		_check(Policy.choose(bm, "genghis_khan").card == strike, "no wait for unknown future combo")
		bm._hero_status.genghis_khan.silence = 1
		_check(Policy.choose(bm, "genghis_khan").is_empty(), "silence skips input")
		bm._hero_status.genghis_khan.clear()
		var shield := _card("joan_of_arc", "last_shield", live)
		bm.team_mgr._hero_hp.joan_of_arc = 50 / divisor
		_check(Policy.evaluate(bm, shield, 0, "yi_sun_sin").score < 0.0, "fatal printed sacrifice blocked")
		var power := _card("joan_of_arc", "martyr_strength", live)
		_check(Policy.evaluate(bm, power, 0, "joan_of_arc").score < 0.0, "fatal rule sacrifice blocked")
		bm.team_mgr._hero_hp.joan_of_arc = 1000 / divisor
		var prepare := _card("yi_sun_sin", "consecutive_defense", live)
		var attack := _card("yi_sun_sin", "charge_stance", live)
		attack.cost = 2 # setup discount makes this newly affordable at energy2
		var state: Dictionary = bm.deck_mgr._heroes.yi_sun_sin
		state.hand.assign([prepare, attack])
		bm._hero_block.yi_sun_sin = 60 / divisor
		state.energy = 2
		var combo: float = Policy.evaluate(bm, prepare, 0, "yi_sun_sin").score
		state.energy = 1
		_check(combo > Policy.evaluate(bm, prepare, 0, "yi_sun_sin").score, "only affordable followup earns setup premium")
		_check(Policy.evaluate(bm, prepare, 0, "yi_sun_sin").reason != "discount_before_attack", "discount cannot pay beyond remaining energy")
		state.energy = 3
		var transfer := _card("yi_sun_sin", "formation_boost", live)
		state.hand.assign([transfer])
		bm.team_mgr._hero_hp.joan_of_arc = 100 / divisor
		bm._enemies[0].intent_pattern[0].target = 0 # LOWEST_HP
		_check(Policy.choose(bm, "yi_sun_sin").ally == "joan_of_arc", "transfer targets threatened ally")
		_check(Policy.incoming(bm, "joan_of_arc") == 10.0, "incoming uses same small unit scale")
		_check(Policy.incoming(bm, "yi_sun_sin") == 0.0, "does not charge every hero full single-target damage")
		_check(Policy.choose(bm, "yi_sun_sin", func(_card: Resource) -> bool: return false).card == null, "caller safety gate cannot be bypassed")
		var retreat := _card("genghis_khan", "cavalry_retreat", live)
		bm._hero_status.genghis_khan.tokens = 2
		bm._enemies[0].intent_pattern[0].action_type = 1 # BUFF: no immediate threat
		var peaceful: float = Policy.evaluate(bm, retreat, 0, "genghis_khan").score
		bm._enemies[0].intent_pattern[0].action_type = 0 # ATTACK
		bm._enemies[0].intent_pattern[0].target = 3 # ALL
		bm._enemies[0].intent_pattern[0].value = 1000 / divisor
		_check(Policy.evaluate(bm, retreat, 0, "genghis_khan").score > peaceful, "spend soldiers for imminent team defense not idle accumulation")
		var counter: Resource = preload("res://resources/cards/cards_common.gd").counter("genghis_khan")
		if live: counter = Profile.candidate_pair(counter).base
		_check(Policy.evaluate(bm, counter, 0, "genghis_khan").score > 0.0, "ordinary attack still values counter mitigation and reflection")
		bm._active_powers["power.strength_player:joan_of_arc"] = {"params": {"sources": {power.card_name: int(power.effects[0].rule_params.amount)}}}
		_check(Policy.evaluate(bm, power, 0, "joan_of_arc").score < 0.0, "do not repay HP for already registered sacrifice power")
		fixture._free(bm)
		bm = fixture._battle(["cleopatra", "musashi", "joan_of_arc"])
		bm.combat_unit_divisor = divisor
		var seed_card := _card("cleopatra", "poison_seed", live)
		var party := _card("cleopatra", "poison_party", live)
		var cleo: Dictionary = bm.deck_mgr._heroes.cleopatra
		cleo.hand.assign([party, seed_card])
		cleo.energy = 3
		var with_combo: float = Policy.evaluate(bm, seed_card, 0, "cleopatra").score
		cleo.energy = 2
		_check(with_combo > Policy.evaluate(bm, seed_card, 0, "cleopatra").score, "poison setup premium requires affordable payoff")
		bm._enemy_status[0].poison_dmg = 20 / divisor
		bm._enemy_status[0].poison_dur = 2
		var tick: Resource = party.effects[1]
		var tick_only := party.duplicate(true)
		tick_only.effects.assign([tick])
		var unblocked_tick: float = Policy.evaluate(bm, tick_only, 0, "cleopatra").score
		bm._enemy_block[0] = 9999
		_check(Policy.evaluate(bm, tick_only, 0, "cleopatra").score == unblocked_tick, "poison payoff bypasses block in evaluation")
		var execution := _card("cleopatra", "charm_execution", live)
		bm._enemy_status[0].charm = 100 / divisor
		_check(Policy.evaluate(bm, execution, 0, "cleopatra").score < 0.0, "preserve crossed enthrall threshold")
		var reload_card := _card("musashi", "empty_state", live)
		var musashi: Dictionary = bm.deck_mgr._heroes.musashi
		musashi.energy = 3
		musashi.hand.assign([reload_card])
		var empty_value: float = Policy.evaluate(bm, reload_card, 0, "musashi").score
		musashi.hand.append(_card("musashi", "strike", live))
		_check(empty_value > Policy.evaluate(bm, reload_card, 0, "musashi").score, "empty reload values actual last-card reward")
		var steps := _card("joan_of_arc", "martyrdom_steps", live)
		var payoff := _card("joan_of_arc", "saints_revelation", live)
		var joan: Dictionary = bm.deck_mgr._heroes.joan_of_arc
		joan.energy = 3
		bm._hero_status.joan_of_arc = {"sacrifice_bank": 50 / divisor}
		joan.hand.assign([steps])
		var no_payoff: float = Policy.evaluate(bm, steps, 0, "joan_of_arc").score
		joan.hand.append(payoff)
		_check(no_payoff > Policy.evaluate(bm, steps, 0, "joan_of_arc").score, "bank draw accounts for affordable competing payoff")
		bm._pending_discard_pick = {"optional": true, "draw_count": 0}
		_check(Policy.discard_choice(bm, "joan_of_arc") == null, "skip unrewarded optional discard")
		bm._pending_discard_pick.draw_count = 2
		_check(Policy.discard_choice(bm, "joan_of_arc") in joan.hand, "rewarded discard selects a real hand card")
		fixture._free(bm)
	print("Synergy decision checks: %d passed, %d failed" % [_passed, _failed])
	quit(0 if _failed == 0 and _passed == 60 else 1)
