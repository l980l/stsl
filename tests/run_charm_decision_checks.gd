extends SceneTree

const Policy = preload("res://tools/charm_decision_policy.gd")
const Fixture = preload("res://tests/test_card_revision_runtime.gd")
const Catalog = preload("res://resources/card_catalog.gd")
const Profile = preload("res://resources/balance/small_number_profile.gd")
var _failed := 0
var _passed := 0

func _init() -> void:
	call_deferred("_run")

func _check(ok: bool, label: String) -> void:
	if ok:
		_passed += 1
	else:
		_failed += 1
		print("FAIL: " + label)

func _run() -> void:
	AudioServer.set_bus_mute(0, true)
	OS.set_environment("STSL_LEGACY_COMBAT", "1")
	var cards := {}
	for card in Catalog.get_all_cards():
		cards[card.card_name] = card
	var fixture := Fixture.new()
	for live in [false, true]:
		var divisor := 10 if live else 1
		var bm = fixture._battle(["cleopatra"], 2)
		bm.combat_unit_divisor = divisor
		var consume: Resource = cards["card.cleopatra.charm_execution.name"].duplicate(true)
		var charm: Resource = cards["card.cleopatra.temptation.name"].duplicate(true)
		var defend: Resource = cards["card.cleopatra.defend.name"].duplicate(true)
		if live:
			consume = Profile.candidate_pair(consume).base
			charm = Profile.candidate_pair(charm).base
			defend = Profile.candidate_pair(defend).base
		var state: Dictionary = bm.deck_mgr._heroes.cleopatra
		state.energy = 3
		state.hand.assign([consume, charm, defend])
		bm._enemy_status[0]["charm"] = 80 / divisor
		_check(Policy.choose(bm, "cleopatra", "hand_order").card == consume, "baseline keeps hand order")
		_check(Policy.choose(bm, "cleopatra", "consume_first").card == consume, "spend policy consumes existing stacks")
		_check(Policy.choose(bm, "cleopatra", "threshold_aware").card == charm, "finish enthrall before consume")
		bm._enemy_status[0]["enthrall"] = 1
		_check(Policy.choose(bm, "cleopatra", "threshold_aware").card == consume, "existing enthrall allows consumption")
		bm._enemy_status[0]["enthrall"] = 0
		bm._enemy_status[0]["charm"] = 100 / divisor
		state.hand.assign([consume, defend])
		_check(Policy.choose(bm, "cleopatra", "threshold_aware").card == defend, "preserve already crossed threshold")
		state.hand.assign([consume])
		_check(Policy.choose(bm, "cleopatra", "threshold_aware").card == null, "explicit finite wait for enemy turn")
		bm._enemy_status[0]["charm"] = 10 / divisor
		_check(Policy.choose(bm, "cleopatra", "threshold_aware").card == consume, "no indefinite wait for unknown future draws")
		state.hand.assign([consume, charm])
		bm._enemy_status[0]["charm_resistance"] = 20 / divisor
		bm._enemy_status[0]["charm"] = 60 / divisor
		_check(not Policy.would_enthrall(bm, charm, 0), "resistance included")
		bm._active_powers["power.charm_double_apply:cleopatra"] = {"value": 2}
		_check(Policy.would_enthrall(bm, charm, 0), "actual power value2 means triple stacks")
		bm._active_powers.clear()
		bm._enemy_status[1]["charm"] = 100 / divisor
		bm._enemy_status[0]["charm"] = 0
		_check(Policy.choose(bm, "cleopatra", "threshold_aware").card == consume, "other target threshold does not hold first target")
		bm._hero_status.cleopatra = {"taunt": 1, "taunt_source": 1}
		_check(Policy.target_for(bm, consume) == 1, "single target respects live taunt source")
		state.hand.assign([consume])
		_check(Policy.choose(bm, "cleopatra", "threshold_aware").card == null, "hold uses actual forced target")
		bm._enemy_alive[1] = false
		bm._enemy_hp[1] = 0
		_check(Policy.target_for(bm, consume) == 0, "dead taunt source is ignored")
		bm._hero_status.cleopatra.clear()
		var all_charm: Resource = cards["card.cleopatra.nile_whisper.name"].duplicate(true)
		if live:
			all_charm = Profile.candidate_pair(all_charm).base
		bm._enemy_alive[1] = true
		bm._enemy_hp[1] = 5000
		bm._enemy_status[1]["charm"] = 90 / divisor
		_check(not Policy.would_enthrall(bm, all_charm, 0), "ALL charm evaluates first target independently")
		_check(Policy.would_enthrall(bm, all_charm, 1), "ALL charm can finish second target")
		state.energy = 0
		_check(Policy.choose(bm, "cleopatra", "threshold_aware").is_empty(), "unaffordable cards excluded")
		fixture._free(bm)
	print("Charm decision checks: %d passed, %d failed" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)
