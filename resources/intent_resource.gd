# resources/intent_resource.gd
class_name IntentResource
extends Resource

enum ActionType { ATTACK, BUFF, DEBUFF, SPECIAL, PREPARE, HEAL_ALLY, BUFF_ALLY, COUNTER_PREPARE, MARK_TARGET, SACRIFICE, WARD, SUMMON, MIMIC }
enum TargetType { LOWEST_HP, LAST_ATTACKER, RANDOM, ALL }

@export var action_type: ActionType = ActionType.ATTACK
@export var value: int = 0
@export var target: TargetType = TargetType.RANDOM
@export var condition: String = ""
@export var play_animation: String = ""
@export var status_type: String = "weak"  # DEBUFF 시 부여할 상태이상 키
@export var damage_type: String = ""  # ATTACK 시 파티클 분류 (slash/blunt/projectile/explosive/poison/divine/curse/fire/ice/lightning)
