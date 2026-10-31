# Runtime conversion for authored enemy resources.  Enemy definitions remain
# in their original units so the legacy comparison tools can still construct
# them; the live battle boundary receives a deep, marked small-number clone.
class_name EnemySmallNumbers
extends RefCounted

const CombatScale = preload("res://resources/balance/combat_scale.gd")
const IntentRes = preload("res://resources/intent_resource.gd")

const PROFILE_META := "stsl_enemy_small_numbers_v1"

# Convert one complete enemy graph: regular intent patterns, phase patterns,
# charge payoff intents and death triggers are all part of the same battle
# object.  Counts, durations, speeds and percentage values deliberately stay
# untouched.
static func convert(enemy: Resource) -> Resource:
	if enemy == null:
		return null
	# Resource.duplicate() does not guarantee metadata preservation.  Inspect
	# the supplied object before cloning so catalog previews can safely pass
	# through BattleManager without a second ten-to-one conversion.
	if enemy.has_meta(PROFILE_META):
		var copy: Resource = enemy.duplicate(true)
		copy.set_meta(PROFILE_META, true)
		return copy
	var converted: Resource = enemy.duplicate(true)
	if not CombatScale.enabled():
		return converted
	converted.max_hp = CombatScale.amount(converted.max_hp)
	converted.charm_resistance = CombatScale.amount(converted.charm_resistance)
	var seen: Dictionary = {}
	_convert_intent_array(converted.intent_pattern, seen)
	for pattern in converted.phase_patterns:
		if pattern is Array:
			_convert_intent_array(pattern, seen)
	_convert_intent(converted.death_trigger, seen)
	if converted.card_count_trigger is Dictionary:
		_convert_intent(converted.card_count_trigger.get("intent"), seen)
	_convert_phase_buffs(converted.phase_buffs)
	converted.set_meta(PROFILE_META, true)
	return converted

static func is_converted(enemy: Resource) -> bool:
	return enemy != null and enemy.has_meta(PROFILE_META)

static func _convert_intent_array(intents: Array, seen: Dictionary) -> void:
	for intent in intents:
		_convert_intent(intent, seen)

static func _convert_intent(intent: Resource, seen: Dictionary) -> void:
	if intent == null:
		return
	var id := intent.get_instance_id()
	if seen.has(id):
		return
	seen[id] = true
	# SACRIFICE.value is a strength gain, but its HP cost is authored as
	# 10×value.  Rounding its strength and then deriving the cost would turn
	# 4 strength / 40 HP into 1 strength / 1 HP, so preserve the independently
	# scaled HP cost for BattleManager's runtime branch.
	if intent.action_type == IntentRes.ActionType.SACRIFICE:
		intent.small_sacrifice_hp_cost = CombatScale.amount(intent.value * 10)
	if _intent_value_is_hp_like(intent):
		intent.value = CombatScale.amount(intent.value)
	for payoff in intent.payoff_intents:
		_convert_intent(payoff, seen)

static func _intent_value_is_hp_like(intent: Resource) -> bool:
	match intent.action_type:
		IntentRes.ActionType.ATTACK, IntentRes.ActionType.HEAL_ALLY, IntentRes.ActionType.SACRIFICE:
			return true
		IntentRes.ActionType.BUFF, IntentRes.ActionType.BUFF_ALLY:
			return intent.status_type in ["block", "strength", "thorns"]
		IntentRes.ActionType.DEBUFF:
			return intent.status_type == "poison"
	return false

static func _convert_phase_buffs(phase_buffs: Array) -> void:
	for phase in phase_buffs:
		if not phase is Array:
			continue
		for buff in phase:
			if not buff is Dictionary:
				continue
			var status := str(buff.get("status", ""))
			if status in ["block", "strength", "poison"]:
				buff["value"] = CombatScale.amount(int(buff.get("value", 0)))
