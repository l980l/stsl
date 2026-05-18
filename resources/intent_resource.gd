# resources/intent_resource.gd
class_name IntentResource
extends Resource

enum ActionType { ATTACK, BUFF, DEBUFF, SPECIAL, PREPARE, HEAL_ALLY, BUFF_ALLY, COUNTER_PREPARE, MARK_TARGET, SACRIFICE, WARD, SUMMON, MIMIC, CHARGE_UP }
enum TargetType { LOWEST_HP, LAST_ATTACKER, RANDOM, ALL }

@export var action_type: ActionType = ActionType.ATTACK
@export var value: int = 0
@export var target: TargetType = TargetType.RANDOM
@export var condition: String = ""
@export var play_animation: String = ""
@export var status_type: String = "weak"  # DEBUFF 시 부여할 상태이상 키
@export var damage_type: String = ""  # ATTACK 시 파티클 분류 (slash/blunt/projectile/explosive/poison/curse/holy_strike/holy_slash/holy_bolt/holy_blunt/holy_fire/holy_arrow)
@export var duration: int = 0  # BUFF/DEBUFF 의 speed_bonus/speed_penalty 등 일정 기간 효과용. 0 이면 영구 누적 (기존 strength/weak 등)
# CHARGE_UP 전용 — N턴 숨고르기 후 페이오프 intents 순차 실행
@export var charge_turns: int = 0
@export var payoff_intents: Array = []  # Array[IntentResource]
