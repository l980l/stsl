extends SceneTree

const V = preload("res://tests/surtr_policy_variants.gd")
const Base = preload("res://tools/synergy_decision_policy.gd")
const Fixture = preload("res://tests/test_card_revision_runtime.gd")
const Catalog = preload("res://resources/card_catalog.gd")
const Profile = preload("res://resources/balance/small_number_profile.gd")
const Sim = preload("res://tools/simulate_small_number_battles.gd")
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
		var bm = fixture._battle(["genghis_khan", "yi_sun_sin", "joan_of_arc"])
		bm.combat_unit_divisor = divisor
		for hero in bm.team_mgr.heroes:
			hero.max_hp = 1000 / divisor
			bm.team_mgr._hero_hp[hero.hero_id] = 1000 / divisor
			bm._hero_status[hero.hero_id] = {}
		var intent: Resource = bm._enemies[0].intent_pattern[0]
		intent.value = 100 / divisor
		intent.target = 2 # RANDOM
		_check(is_equal_approx(Base.incoming(bm, "yi_sun_sin"), 10.0 / 3), "original expected random share")
		_check(is_equal_approx(V.demand(bm, "yi_sun_sin", "random_risk"), 10.0), "risk arm uses possible full random hit")
		intent.target = 3 # ALL
		_check(V.demand(bm, "yi_sun_sin", "random_risk") == Base.incoming(bm, "yi_sun_sin"), "risk arm does not inflate AOE")
		var charge := _card("yi_sun_sin", "charge_stance", live)
		bm._hero_block.yi_sun_sin = 300 / divisor
		_check(V._adjustment(bm, charge, "yi_sun_sin", "marginal_guard") > 0, "spending surplus block is not immediate HP loss")
		bm._hero_block.yi_sun_sin = 40 / divisor
		_check(is_equal_approx(V._adjustment(bm, charge, "yi_sun_sin", "marginal_guard"), 0.0), "spending needed block keeps opportunity cost")
		var transfer := _card("yi_sun_sin", "formation_boost", live)
		bm._hero_block.yi_sun_sin = 300 / divisor
		bm.deck_mgr._heroes.yi_sun_sin.hand.assign([transfer])
		bm.deck_mgr._heroes.yi_sun_sin.energy = 3
		_check(V.choose(bm, "yi_sun_sin", "no_block_spend").ally == "yi_sun_sin", "self-transfer is allowed when it spends zero block")
		bm.team_mgr._hero_hp.joan_of_arc = 50 / divisor
		_check(V.choose(bm, "yi_sun_sin", "legacy_ally").ally == "joan_of_arc", "legacy target uses lowest HP nonowner")
		bm.deck_mgr._heroes.yi_sun_sin.hand.assign([charge])
		_check(V.choose(bm, "yi_sun_sin", "no_block_spend").card == null, "positive own block attack conversion vetoed")
		var buff := Fixture.Intent.new()
		buff.action_type = Fixture.Intent.ActionType.BUFF
		buff.status_type = "strength"
		buff.value = 20 / divisor
		bm._enemies[0].intent_pattern = [buff, intent]
		_check(Base.incoming(bm, "genghis_khan") == 0.0, "original preparation blindness reproduced")
		_check(V.demand(bm, "genghis_khan", "prepare_guard") > 0.0, "prepared guard sees authored attack through buff")
		var retreat := _card("genghis_khan", "cavalry_retreat", live)
		bm._hero_status.genghis_khan.tokens = 2
		bm.deck_mgr._heroes.genghis_khan.hand.assign([retreat])
		bm.deck_mgr._heroes.genghis_khan.energy = 3
		_check(Base.evaluate(bm, retreat, 0, "genghis_khan").score < 0, "ordinary negative score is not a safety sentinel")
		_check(V.choose(bm, "genghis_khan", "prepare_guard").card == retreat, "forecast can rescue originally negative guard choice")
		var before := JSON.stringify(Sim._snapshot(bm, "check", "", 0))
		seed(9876)
		var expected := randi()
		seed(9876)
		for mode in V.MODES: V.choose(bm, "genghis_khan", mode)
		_check(randi() == expected, "all diagnostic choices preserve RNG")
		_check(JSON.stringify(Sim._snapshot(bm, "check", "", 0)) == before, "diagnostic choices do not mutate combat")
		fixture._free(bm)
	print("Surtr policy checks: %d passed, %d failed" % [_passed, _failed])
	quit(0 if _failed == 0 and _passed == 28 else 1)
