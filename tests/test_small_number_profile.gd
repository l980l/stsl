class_name TestSmallNumberProfile
extends RefCounted

const Profile = preload("res://resources/balance/small_number_profile.gd")
const Catalog = preload("res://resources/card_catalog.gd")
const GameManagerClass = preload("res://autoload/game_manager.gd")
const CardRes = preload("res://resources/card_resource.gd")
const EffectRes = preload("res://resources/effect_resource.gd")

var passed := 0
var failed := 0

func run_all() -> Dictionary:
	_test_catalog_pair_coverage_and_preservation()
	_test_dimensional_conversion_rules()
	_test_upgrade_monotonicity_and_idempotence()
	_test_unknown_numeric_params_are_reported()
	return {"passed": passed, "failed": failed}

func _check(ok: bool, label: String) -> void:
	if ok:
		passed += 1
	else:
		failed += 1
		print("  FAIL: small profile " + label)

func _card(owner_id: String, card_name: String) -> Resource:
	for card in Catalog.get_all_cards():
		if card.owner_id == owner_id and card.card_name == card_name:
			return card
	return null

func _test_catalog_pair_coverage_and_preservation() -> void:
	var originals: Array = Catalog.get_all_cards()
	var first_value: int = originals[0].effects[0].value
	var manager := GameManagerClass.new()
	var pairs := Profile.candidate_catalog_pairs(manager)
	manager.free()
	_check(originals.size() == 216, "catalog has 216 owner/name cards")
	_check(pairs.size() == originals.size(), "every catalog card has one small-number pair")
	_check(originals[0].effects[0].value == first_value, "profile does not mutate catalog resources")
	for index in range(pairs.size()):
		var source: Resource = originals[index]
		var pair: Dictionary = pairs[index]
		var base: Resource = pair.base
		var upgraded: Resource = pair.upgraded
		_check(Profile.is_candidate(base) and Profile.is_candidate(upgraded), "pair %d is explicitly marked as comparison data" % index)
		_check(base.card_name == source.card_name and base.owner_id == source.owner_id, "pair %d preserves identifiers" % index)
		_check(base.cost == source.cost and base.is_exhaust == source.is_exhaust and base.is_retain == source.is_retain and base.is_innate == source.is_innate and base.is_ethereal == source.is_ethereal, "pair %d preserves cost and flags" % index)
		_check(upgraded.upgrade_level == 1, "pair %d contains actual one-upgrade baseline" % index)
		_check(Profile.is_upgrade_meaningful(base, upgraded), "pair %d keeps a gameplay-meaningful candidate upgrade" % index)

func _test_dimensional_conversion_rules() -> void:
	var manager := GameManagerClass.new()
	var counter: Dictionary = Profile.candidate_pair(_card("yi_sun_sin", "card.yi_sun_sin.counter.name"), manager)
	var counter_effect: Resource = counter.base.effects[0]
	_check(counter_effect.value == 6, "damage value scales by ten")
	_check(counter_effect.rule_params.consume_cap == 8, "consume-own-block cap scales by ten")
	_check(counter_effect.rule_params.multiplier == 1.5, "block multiplier retains the runtime float ratio")

	var volley: Dictionary = Profile.candidate_pair(_card("yi_sun_sin", "card.yi_sun_sin.volley_fire.name"), manager)
	var volley_effect: Resource = volley.base.effects[0]
	_check(volley_effect.value == 10 and volley_effect.bonus_value == 2, "team-token base and damage coefficient scale")
	_check(volley_effect.rule_params.cap == 18, "team-token damage cap scales")

	var needle: Dictionary = Profile.candidate_pair(_card("cleopatra", "card.cleopatra.venom_needle.name"), manager)
	_check(needle.base.effects[0].value == 7 and needle.upgraded.effects[0].value == 9, "needle compensates lower poison with one direct damage")
	_check(needle.base.effects[1].value == 1 and needle.upgraded.effects[1].value == 1, "needle avoids rounding 15 poison up to 20 legacy units")
	var gaze: Dictionary = Profile.candidate_pair(_card("cleopatra", "card.cleopatra.cursed_gaze.name"), manager)
	_check(gaze.base.effects[0].value == 1 and gaze.base.effects[1].value == 1, "weak and vulnerable counts stay integral counts")

	var block_ratio: Dictionary = Profile.candidate_pair(_card("musashi", "card.musashi.steel_strike.name"), manager)
	for effect in block_ratio.base.effects:
		if effect.effect_type == EffectRes.EffectType.DAMAGE_PER_BLOCK:
			_check(effect.value == 120, "damage-per-block percentage stays a percentage")
	var coefficient_card := CardRes.new()
	coefficient_card.card_name = "test.small_profile.coefficients"
	coefficient_card.owner_id = "cleopatra"
	var poison_burst := EffectRes.new()
	poison_burst.effect_type = EffectRes.EffectType.POISON_BURST
	poison_burst.value = 200
	poison_burst.base_value = 200
	var charm_payoff := EffectRes.new()
	charm_payoff.effect_type = EffectRes.EffectType.CHARM_TO_DAMAGE
	charm_payoff.bonus_value = 2
	charm_payoff.base_bonus_value = 2
	coefficient_card.effects = [poison_burst, charm_payoff]
	var coefficient_pair: Dictionary = Profile.candidate_pair(coefficient_card, manager)
	_check(coefficient_pair.base.effects[0].value == 200, "poison burst percentage stays a percentage")
	_check(coefficient_pair.base.effects[1].bonus_value == 2, "charm payoff coefficient stays when charm and damage both scale")

	var horse_thrust: Dictionary = Profile.candidate_pair(_card("genghis_khan", "card.genghis_khan.horse_thrust.name"), manager)
	_check(horse_thrust.base.effects[0].bonus_value == 11 and horse_thrust.upgraded.effects[0].bonus_value == 13, "other-card damage bonus scales as a damage coefficient")

	var nile_fury: Dictionary = Profile.candidate_pair(_card("cleopatra", "card.cleopatra.nile_fury.name"), manager)
	_check(nile_fury.base.effects[0].value == 6 and nile_fury.upgraded.effects[0].value == 7 and nile_fury.upgraded.effects[1].value == 1, "nile fury uses fixed damage upgrade without doubling poison")
	var nile_whisper: Dictionary = Profile.candidate_pair(_card("cleopatra", "card.cleopatra.nile_whisper.name"), manager)
	_check(nile_whisper.base.effects[0].value == 2 and nile_whisper.upgraded.effects[0].value == 3, "nile whisper uses a discrete 2-to-3 charm upgrade")
	var purification: Dictionary = Profile.candidate_pair(_card("joan_of_arc", "card.joan_of_arc.holy_purification.name"), manager)
	_check(purification.base.effects[1].value == 2 and purification.upgraded.effects[1].value == 3, "holy purification uses a discrete 2-to-3 heal upgrade")
	var martyrs: Dictionary = Profile.candidate_pair(_card("joan_of_arc", "card.joan_of_arc.martyrs_will.name"), manager)
	_check(martyrs.upgraded.effects[0].value == 5 and martyrs.upgraded.effects[1].value == 8, "martyr upgrade never increases self-sacrifice")
	var martyr_strength: Dictionary = Profile.candidate_pair(_card("joan_of_arc", "card.joan_of_arc.martyr_strength.name"), manager)
	_check(martyr_strength.base.effects[0].rule_params.amount == 2 and martyr_strength.upgraded.effects[0].rule_params.amount == 3, "martyr strength preserves a beneficial power upgrade without increasing sacrifice")
	var whirlwind: Dictionary = Profile.candidate_pair(_card("musashi", "card.musashi.whirlwind_cut.name"), manager)
	_check(whirlwind.upgraded.effects[0].value == 4 and whirlwind.upgraded.effects[1].value == 5, "whirlwind upgrade preserves two-hit damage and improves block")
	var desert: Dictionary = Profile.candidate_pair(_card("genghis_khan", "card.genghis_khan.desert_cavalry.name"), manager)
	_check(desert.base.effects[0].rule_id == "paired_draw_damage" and desert.upgraded.effects[0].rule_params.upgrade_bonus == 1, "desert cavalry uses integer pairs and a fixed one-damage upgrade")
	manager.free()

func _test_upgrade_monotonicity_and_idempotence() -> void:
	var card := CardRes.new()
	card.card_name = "test.small_profile.monotonic"
	card.owner_id = "napoleon"
	card.has_explicit_upgrade = true
	var effect := EffectRes.new()
	effect.effect_type = EffectRes.EffectType.DAMAGE
	effect.value = 14
	effect.base_value = 14
	effect.upgrade_value = 15
	var unchanged_effect := EffectRes.new()
	unchanged_effect.effect_type = EffectRes.EffectType.DAMAGE
	unchanged_effect.value = 14
	unchanged_effect.base_value = 14
	card.effects = [effect, unchanged_effect]
	var pair: Dictionary = Profile.candidate_pair(card)
	_check(pair.base.effects[0].value == 1, "half-up baseline conversion is integer")
	_check(pair.upgraded.effects[0].value == 2, "meaningful real upgrade cannot disappear after rounding")
	_check(pair.upgraded.effects[1].value == 1, "rounding guard does not boost unrelated effects")
	var twice: Resource = Profile.candidate_from_actual_card(pair.base)
	_check(twice.effects[0].value == pair.base.effects[0].value and twice != pair.base, "candidate conversion is idempotent by clone and profile marker")
	_check(card.effects[0].value == 14 and card.upgrade_level == 0, "synthetic source remains real-scale and unupgraded")

func _test_unknown_numeric_params_are_reported() -> void:
	var card := CardRes.new()
	card.card_name = "test.small_profile.unknown_param"
	card.owner_id = "napoleon"
	var effect := EffectRes.new()
	effect.effect_type = EffectRes.EffectType.APPLY_STATUS
	effect.rule_id = "unknown_rule"
	effect.rule_params = {"unmapped_number": 77}
	card.effects = [effect]
	var pair: Dictionary = Profile.candidate_pair(card)
	_check(pair.unsupported_fields.size() == 1, "every unsupported numeric parameter is reported")
	_check(pair.unsupported_fields[0].contains("unmapped_number"), "unsupported report includes the exact parameter key")
	var known_card := CardRes.new()
	known_card.card_name = "test.small_profile.known_count"
	known_card.owner_id = "napoleon"
	var known_effect := EffectRes.new()
	known_effect.effect_type = EffectRes.EffectType.APPLY_STATUS
	known_effect.rule_id = "next_cards_cost_reduction"
	known_effect.rule_params = {"amount": 1, "count": 2}
	known_card.effects = [known_effect]
	var known_pair: Dictionary = Profile.candidate_pair(known_card)
	_check(known_pair.unsupported_fields.is_empty(), "known cost-reduction counts stay unchanged without an unsupported warning")
