# Small-integer card rules shared by gameplay and comparison harnesses.
class_name SmallNumberProfile
extends RefCounted

const EffectRes = preload("res://resources/effect_resource.gd")

const UNIT_DIVISOR := 10
const PROFILE_ID := "small-integers-v2"
const PROFILE_META := "stsl_small_number_profile_v2"

# HP-like values scale down. Counts, costs, turns, percentages, speeds and
# target flags intentionally remain on their existing scale.
const HP_VALUE_EFFECTS := [
	EffectRes.EffectType.DAMAGE,
	EffectRes.EffectType.BLOCK,
	EffectRes.EffectType.HEAL,
	EffectRes.EffectType.BLOCK_ALL,
	EffectRes.EffectType.HEAL_ALL,
	EffectRes.EffectType.FORMATION_BLOCK,
	EffectRes.EffectType.CONDITIONAL_DMG,
	EffectRes.EffectType.PER_DRAW_DMG,
	EffectRes.EffectType.DAMAGE_PER_DEAD_ALLY,
	EffectRes.EffectType.DAMAGE_PER_HAND_SIZE,
	EffectRes.EffectType.DAMAGE_PER_TOKEN,
	EffectRes.EffectType.DAMAGE_PER_TEAM_MORALE,
	EffectRes.EffectType.DAMAGE_PER_TEAM_TOKEN,
	EffectRes.EffectType.HEAL_PER_DEAD_ALLY,
	EffectRes.EffectType.ENERGY_TO_DAMAGE,
	EffectRes.EffectType.SACRIFICE_PAYOFF,
	EffectRes.EffectType.DAMAGE_PER_STATUS_TYPE,
	EffectRes.EffectType.DAMAGE_PER_CHARMED_ENEMY,
	EffectRes.EffectType.MULTI_HIT_RANDOM,
	EffectRes.EffectType.BLOCK_PER_CARDS_PLAYED,
	EffectRes.EffectType.MORALE_TO_BLOCK,
	EffectRes.EffectType.SACRIFICE_HP,
]

const HP_POWER_STATUS := {
	"power.poison_per_turn": true,
	"power.block_per_turn": true,
	"power.heal_team_per_turn": true,
	"power.limited_team_heal": true,
	"power.strength_player": true,
	"power.bonus_per_hit": true,
	"power.every_nth_attack_bonus": true,
	"power.token_bonus_dmg": true,
	"power.on_enthrall_strength": true,
	"power.charm_threshold_minus": true,
}

static func candidate_pair(card: Resource, game_manager: Object = null) -> Dictionary:
	var base_actual := card.duplicate(true)
	var upgraded_actual := card.duplicate(true)
	var owns_manager := game_manager == null
	var manager: Object = game_manager if game_manager != null else load("res://autoload/game_manager.gd").new()
	manager.upgrade_card(upgraded_actual)
	if is_candidate(card):
		if owns_manager:
			manager.free()
		return {"base": base_actual, "upgraded": upgraded_actual, "unsupported_fields": [], "hazards": []}
	var base := candidate_from_actual_card(base_actual)
	var upgraded := candidate_from_actual_card(upgraded_actual)
	_apply_candidate_rounding_tuning(base, upgraded)
	_apply_monotonic_upgrade_guard(base, upgraded)
	if owns_manager:
		manager.free()
	return {
		"base": base,
		"upgraded": upgraded,
		"unsupported_fields": _unique_strings(_unsupported_fields(base_actual) + _unsupported_fields(upgraded_actual)),
		"hazards": _unique_strings(_hazards(base_actual) + _hazards(upgraded_actual)),
	}

static func candidate_catalog_pairs(game_manager: Object = null) -> Array:
	var result: Array = []
	for card in load("res://resources/card_catalog.gd").get_all_cards():
		result.append(candidate_pair(card, game_manager))
	return result

# Finalize legacy-authored data once, installing explicit integer upgrades.
# Build the upgrade before marking the base so GameManager uses the legacy
# authoring rule exactly once rather than reapplying percentages to small data.
static func live_card(card: Resource) -> Resource:
	if is_candidate(card):
		return card
	var pair := candidate_pair(card)
	var base: Resource = pair.base
	var upgraded: Resource = pair.upgraded
	base.has_explicit_upgrade = true
	base.upgrade_cost = upgraded.cost
	for i in range(base.effects.size()):
		var effect: Resource = base.effects[i]
		var next: Resource = upgraded.effects[i]
		effect.base_value = effect.value
		effect.base_bonus_value = effect.bonus_value
		effect.upgrade_value = next.value
		effect.upgrade_bonus_value = next.bonus_value
		effect.upgrade_target = next.target
		effect.upgrade_rule_params = next.rule_params.duplicate(true)
	return base

# Public conversion entry point for a real-scale resource. Passing an already
# profiled card is idempotent: it returns a fresh clone without scaling again.
static func candidate_from_actual_card(card: Resource) -> Resource:
	var candidate := card.duplicate(true)
	if is_candidate(card) or card.has_meta("stsl_small_number_profile_v1"):
		candidate.combat_unit_version = 2
		candidate.set_meta(PROFILE_META, true)
		return candidate
	for effect in candidate.effects:
		_convert_effect(effect)
	candidate.set_meta(PROFILE_META, true)
	candidate.combat_unit_version = 2
	return candidate

static func is_candidate(card: Resource) -> bool:
	return card != null and (card.combat_unit_version == 2 or card.has_meta(PROFILE_META))

static func is_upgrade_meaningful(base: Resource, upgraded: Resource) -> bool:
	return _candidate_signature(base) != _candidate_signature(upgraded)

static func _convert_effect(effect: Resource) -> void:
	# Preserve distinct poison gates instead of rounding both to 1.
	if effect.status_type == "has_poison_5":
		effect.status_type = "has_poison_1"
	elif effect.status_type == "has_poison_10":
		effect.status_type = "has_poison_2"
	var scale_value := _effect_value_is_hp_like(effect)
	if scale_value:
		effect.value = _small(effect.value)
		effect.base_value = _small(effect.base_value)
		effect.upgrade_value = _small_optional(effect.upgrade_value)
	if _effect_bonus_is_hp_like(effect):
		effect.bonus_value = _small(effect.bonus_value)
		effect.base_bonus_value = _small(effect.base_bonus_value)
		effect.upgrade_bonus_value = _small_optional(effect.upgrade_bonus_value)
	_convert_rule_params(effect.rule_id, effect.rule_params)
	_convert_rule_params(effect.rule_id, effect.upgrade_rule_params)

static func _effect_value_is_hp_like(effect: Resource) -> bool:
	if effect.effect_type in HP_VALUE_EFFECTS:
		return true
	if effect.effect_type == EffectRes.EffectType.APPLY_STATUS:
		return effect.status_type == "poison" or effect.status_type == "strength" or HP_POWER_STATUS.has(effect.status_type)
	if effect.effect_type == EffectRes.EffectType.CHARM:
		return true
	return false

static func _effect_bonus_is_hp_like(effect: Resource) -> bool:
	if effect.effect_type in [
		EffectRes.EffectType.CONDITIONAL_DMG,
		EffectRes.EffectType.CONSUME_MORALE,
		EffectRes.EffectType.CONSUME_TEAM_MORALE,
	]:
		return true
	# Rule damage cards use bonus_value as a damage-per-stack coefficient.
	return effect.rule_id in [
		"debuff_cash_damage", "marked_cash_all", "duel_status_damage",
		"morale_spend_damage",
		"other_card_this_turn_damage",
		"consume_own_tokens",
		"consume_own_tokens_all",
		"team_morale_damage",
		"team_token_damage",
		"damage_per_debuff_type",
	]

static func _convert_rule_params(rule_id: String, params: Dictionary) -> void:
	if params.is_empty():
		return
	match rule_id:
		"resource_to_block": _scale_keys(params, ["base", "per_resource"])
		"poison_seed_spread": _scale_keys(params, ["seed", "spread"])
		"charm_to_block": _scale_keys(params, ["consume_cap", "block_cap"])
		"guard_attack_discount": _scale_keys(params, ["threshold"])
		"block_transfer": _scale_keys(params, ["consume_cap", "base"])
		"formation_drill", "empty_reload": _scale_keys(params, ["block"])
		"heal_if_enemy_debuff": _scale_keys(params, ["amount"])
		"overflow_heal": _scale_keys(params, ["heal", "block_cap"])
		"block_to_heal", "bank_draw", "block_multi_hit": _scale_keys(params, ["consume_cap"])
		"duel_preparation": _scale_keys(params, ["amount", "solo_amount"])
		"consume_own_block":
			_scale_keys(params, ["consume_cap"])
			# Runtime consumes this as a direct float ratio. Keep it as 1.5
			# until a display-only percentage representation has a matching runtime.
		"consume_own_tokens", "consume_own_tokens_all":
			_scale_keys(params, ["multiplier"])
		"team_token_damage", "team_morale_damage":
			_scale_keys(params, ["cap"])
		"consume_charm_damage":
			_scale_keys(params, ["consume_cap"])
		"formation_block":
			_scale_keys(params, ["base", "per_other_ally"])
		"heal_ally_if_owner_hp_below", "block_ally_if_owner_survives", "next_attack_first_hit_bonus", "discard_up_to_one_for_block", "block_if_target_survives":
			_scale_keys(params, ["amount"])
		"delayed_team_heal", "poison_existing_all_bonus":
			_scale_keys(params, ["amount"])
		"revive_or_heal":
			_scale_keys(params, ["heal"])
		"sacrifice_then_power":
			_scale_keys(params, ["sacrifice", "amount"])
		"sacrifice_bank_payoff", "sacrifice_bank_team_block":
			_scale_keys(params, ["consume_cap", "base"])
		"team_block_consume_morale":
			_scale_keys(params, ["base", "per_morale"])
		"block_per_prior_card":
			_scale_keys(params, ["per_card", "cap"])
		_:
			pass

static func _scale_keys(params: Dictionary, keys: Array) -> void:
	for key in keys:
		if params.has(key) and (params[key] is int or params[key] is float):
			params[key] = _small_number(float(params[key]))

static func _small(value: int) -> int:
	return _small_number(float(value)) if value > 0 else value

static func _small_optional(value: int) -> int:
	return _small(value) if value >= 0 else value

static func _small_number(value: float) -> int:
	if value <= 0.0:
		return int(value)
	return max(1, int(floor(value / float(UNIT_DIVISOR) + 0.5)))

static func _apply_monotonic_upgrade_guard(base: Resource, upgraded: Resource) -> void:
	# A rounded profile must not invent several upgrades merely because one
	# original-scale field changed inside a multi-effect card. Only when the
	# *entire candidate* would remain identical do we add one fixed small-unit
	# step to its first meaningful HP-like field.
	if _candidate_signature(base) != _candidate_signature(upgraded):
		return
	# Avoid turning a larger self-sacrifice into the only visible benefit of an
	# upgrade. A candidate-only tuning may instead preserve the original upgrade
	# on the paired heal/block/damage effect.
	for index in range(mini(base.effects.size(), upgraded.effects.size())):
		var base_effect: Resource = base.effects[index]
		var upgraded_effect: Resource = upgraded.effects[index]
		if base_effect.effect_type == EffectRes.EffectType.SACRIFICE_HP:
			continue
		if base_effect.effect_type == EffectRes.EffectType.APPLY_STATUS and base_effect.status_type in ["power.poison_per_turn", "power.block_per_turn", "power.heal_team_per_turn"]:
			# Do not double a permanent 1/turn power just to retain its tiny
			# authored upgrade. Give one fixed extra point every fifth trigger.
			upgraded_effect.rule_params["upgrade_tick_period"] = 5
			upgraded_effect.rule_params["upgrade_tick_bonus"] = 1
			return
		if _effect_value_is_hp_like(base_effect) and base_effect.value > 0:
			upgraded_effect.value = base_effect.value + 1
			return
		if _effect_bonus_is_hp_like(base_effect) and base_effect.bonus_value > 0:
			upgraded_effect.bonus_value = base_effect.bonus_value + 1
			return

# These cards sit on discrete ten-to-one rounding boundaries. Keep the
# candidate close to the real-scale outcome while assigning the small upgrade
# to the effect that retains the card's intended role. The live factory and
# comparison harness both consume this same tuning table.
static func _apply_candidate_rounding_tuning(base: Resource, upgraded: Resource) -> void:
	# New authored synergy contracts have exact integer upgrades; old per-card
	# compensation must not assume their former effect order or effect count.
	if base.has_meta("archetype_synergy_revision"):
		return
	match base.card_name:
		"card.cleopatra.nile_mist.name":
			# Preserve poison 1; a single +1 block is a meaningful defensive
			# upgrade without doubling three rounds of poison damage.
			upgraded.effects[0].value = base.effects[0].value
			upgraded.effects[1].value = base.effects[1].value + 1
		"card.cleopatra.poison_purge.name":
			# Improve the cleanse's scope rather than recurring poison 2 -> 3.
			upgraded.effects[0].target = "ALL"
			upgraded.effects[1].value = base.effects[1].value
		"card.cleopatra.venom_needle.name":
			# Original V3 poison is 15 in both grades. Rounding it to 2
			# increased recurring damage by a third; compensate poison1 with
			# one immediate damage instead (three ticks: 10/12 vs 10.5/12.5).
			base.effects[0].value = 7
			upgraded.effects[0].value = 9
			base.effects[1].value = 1
			upgraded.effects[1].value = 1
		"card.cleopatra.nile_fury.name":
			# Real legacy upgrade leaves random-hit65 unchanged and poison10
			# becomes11, NOT hit72. Use a fixed hit upgrade instead of doubling DOT.
			base.effects[0].value = 6
			upgraded.effects[0].value = 7
			base.effects[1].value = 1
			upgraded.effects[1].value = 1
		"card.cleopatra.nile_whisper.name":
			# 25/26 has no nearest-integer upgrade at this scale. Bias the
			# pair down/up (2 -> 3) so the upgrade survives without a +2 jump.
			base.effects[0].value = 2
			upgraded.effects[0].value = 3
		"card.joan_of_arc.holy_purification.name":
			# Same 25/27 boundary: preserve a one-point healing upgrade.
			base.effects[1].value = 2
			upgraded.effects[1].value = 3
		"card.joan_of_arc.martyrs_will.name":
			# Never turn sacrifice 5 into 6. Put the visible upgrade on healing;
			# 5 sacrifice + 8 heal remains within one small unit of the 21 net HP.
			upgraded.effects[0].value = base.effects[0].value
			upgraded.effects[1].value = base.effects[1].value + 1
		"card.joan_of_arc.martyr_strength.name":
			# 18/23 strength rounds to 2 in both grades. Keep sacrifice stable
			# and retain the meaningful upgrade on the resulting strength amount.
			upgraded.effects[0].rule_params.amount = base.effects[0].rule_params.amount + 1
		"card.musashi.whirlwind_cut.name":
			# 40/43 damage x2 rounds to 4 either way. Preserve that total and
			# express the upgrade as one additional block point.
			upgraded.effects[0].value = base.effects[0].value
			upgraded.effects[1].value = base.effects[1].value + 1
		"card.genghis_khan.desert_cavalry.name":
			for effect in [base.effects[0], upgraded.effects[0]]:
				effect.rule_id = "paired_draw_damage"
				effect.value = 0
				effect.rule_params = {"per_pair": 5, "per_odd": 2, "upgrade_bonus": 0}
			upgraded.effects[0].rule_params.upgrade_bonus = 1

static func _candidate_signature(card: Resource) -> String:
	var effects: Array = []
	for effect in card.effects:
		effects.append({
			"type": effect.effect_type,
			"value": effect.value,
			"bonus": effect.bonus_value,
			"target": effect.target,
			"status": effect.status_type,
			"hits": effect.hit_count,
			"condition": effect.condition,
			"damage_type": effect.damage_type,
			"params": effect.rule_params,
		})
	return JSON.stringify({"cost": card.cost, "flags": [card.is_exhaust, card.is_retain, card.is_innate, card.is_ethereal], "effects": effects})

# Numeric rule parameters not listed here are intentionally left untouched.
# Callers can surface this list in proposal review before enabling a runtime.
static func _unsupported_fields(card: Resource) -> Array:
	var fields: Array = []
	for effect_index in range(card.effects.size()):
		var effect: Resource = card.effects[effect_index]
		for params_name in ["rule_params", "upgrade_rule_params"]:
			var params: Dictionary = effect.get(params_name)
			for key in params:
				if (params[key] is int or params[key] is float) and not _known_numeric_param(effect.rule_id, effect.status_type, key):
					fields.append("%s[%d].%s.%s" % [card.card_name, effect_index, params_name, key])
	return fields

static func _known_numeric_param(rule_id: String, status_type: String, key: String) -> bool:
	if status_type in ["power.poison_per_turn", "power.block_per_turn", "power.heal_team_per_turn"] and key in ["upgrade_tick_period", "upgrade_tick_bonus"]:
		return true
	if key in ["turns", "count", "consume", "threshold", "draw", "max_discard", "per_turn_limit", "hp_percent", "revive_percent", "bonus_value"]:
		return true
	if status_type == "power.morale_per_turn" and key == "immediate_morale":
		return true
	match rule_id:
		"morale_if_survives", "morale_attack_discount", "opening_status": return key == "amount"
		"resource_to_block": return key in ["consume_cap", "per_resource", "base"]
		"recruit_or_draw": return key == "tokens"
		"poison_seed_spread": return key in ["seed", "spread"]
		"curse_weave": return key in ["weak", "vulnerable"]
		"debuff_cash_damage": return key == "consume_cap"
		"charm_to_block": return key in ["consume_cap", "block_per_charm", "block_cap"]
		"guard_attack_discount": return key == "amount"
		"block_transfer": return key in ["consume_cap", "base"]
		"formation_drill", "empty_reload": return key in ["block", "fallback_draw"]
		"heal_if_enemy_debuff": return key == "amount"
		"overflow_heal": return key in ["heal", "block_cap"]
		"block_to_heal", "bank_draw", "block_multi_hit": return key in ["consume_cap", "bonus_draw"]
		"combo_energy_once": return key in ["normal", "combo"]
		"marked_scout": return key == "marked_draw"
		"duel_preparation": return key in ["amount", "solo_amount"]
		"consume_own_block": return key in ["consume_cap", "multiplier"]
		"consume_own_tokens", "consume_own_tokens_all": return key in ["consume_cap", "consume", "multiplier"]
		"team_token_damage", "team_morale_damage": return key in ["cap"]
		"consume_charm_damage": return key == "consume_cap"
		"formation_block": return key in ["base", "per_other_ally"]
		"heal_ally_if_owner_hp_below", "block_ally_if_owner_survives", "next_attack_first_hit_bonus", "discard_up_to_one_for_block", "block_if_target_survives", "delayed_team_heal", "poison_existing_all_bonus": return key == "amount"
		"revive_or_heal": return key == "heal"
		"sacrifice_then_power": return key in ["sacrifice", "amount"]
		"sacrifice_bank_payoff", "sacrifice_bank_team_block": return key in ["consume_cap", "base"]
		"team_block_consume_morale": return key in ["base", "per_morale", "morale_per_hero"]
		"block_per_prior_card": return key in ["per_card", "cap"]
		"damage_per_debuff_type": return key == "cap"
		"poison_burst_multiplier": return key == "multiplier"
		"next_attack_cost_reduction", "next_cards_cost_reduction", "hand_empty_energy_once": return key == "amount"
	return false

static func _hazards(card: Resource) -> Array:
	var hazards: Array = []
	for effect in card.effects:
		if effect.effect_type == EffectRes.EffectType.DAMAGE_PER_BLOCK:
			hazards.append(card.card_name + ": DAMAGE_PER_BLOCK remains a percentage coefficient")
		if effect.rule_id == "consume_own_block" and effect.rule_params.has("multiplier"):
			hazards.append(card.card_name + ": consume_own_block multiplier remains a runtime float ratio")
	return hazards

static func _unique_strings(values: Array) -> Array:
	var unique: Array = []
	for value in values:
		if not unique.has(value):
			unique.append(value)
	return unique
