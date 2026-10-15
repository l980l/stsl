# resources/event_resource.gd
class_name EventResource
extends Resource

const CombatScale = preload("res://resources/balance/combat_scale.gd")

@export var event_name: String = ""
@export var description: String = ""
@export var choices: Array = []  # Array[EventChoiceResource]
@export var bgm_type: String = "encounter"  # mysterious / dark / encounter / fortune

# Event factories retain authored literals and normalize only combat HP at the
# final factory boundary. Gold, cards, draws, chance and encounter tiers are
# deliberately not combat units.
static func scale_pool_for_combat(pool: Array) -> Array:
	if not CombatScale.enabled():
		return pool
	for event in pool:
		if event == null or event.has_meta("stsl_combat_scaled"):
			continue
		for choice in event.choices:
			_scale_choice(choice)
		event.set_meta("stsl_combat_scaled", true)
	return pool

static func _scale_choice(choice: Resource) -> void:
	if choice == null:
		return
	choice.cost_hp = CombatScale.amount(choice.cost_hp)
	choice.value = _scale_effect_value(choice.effect_type, choice.value)
	choice.secondary_value = _scale_effect_value(choice.secondary_effect_type, choice.secondary_value)
	choice.alt_value = _scale_effect_value(choice.alt_effect_type, choice.alt_value)
	choice.reward_value = _scale_effect_value(choice.reward_effect_type, choice.reward_value)

static func _scale_effect_value(effect_type: int, value: int) -> int:
	return CombatScale.amount(value) if effect_type == EventChoiceResource.EffectType.HEAL else value
