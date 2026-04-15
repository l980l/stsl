# resources/event_choice_resource.gd
class_name EventChoiceResource
extends Resource

enum EffectType { NONE, GOLD, HEAL, DRAW_UP, REMOVE_CARD, ADD_RELIC, ADD_HERO }

@export var label: String = ""
@export var effect_type: EffectType = EffectType.NONE
@export var value: int = 0
@export var cost_gold: int = 0
@export var cost_hp: int = 0
