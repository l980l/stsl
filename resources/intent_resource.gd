# resources/intent_resource.gd
class_name IntentResource
extends Resource

enum ActionType { ATTACK, BUFF, DEBUFF, SPECIAL, PREPARE, HEAL_ALLY, BUFF_ALLY, COUNTER_PREPARE, MARK_TARGET, SACRIFICE, WARD, SUMMON, MIMIC, CHARGE_UP, DISPEL, FORM_SWITCH, CHANGE_AFFINITY, INFLICT_WEAKNESS }
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
# SACRIFICE 의 HP 비용은 value(strength gain)와 다른 차원이다. 작은 수치
# 변환 후에도 deep duplicate 에 보존되어야 하므로 metadata 대신 export 한다.
# -1은 기존 authored resource의 "value × 현재 HP 단위" fallback을 뜻한다.
@export var small_sacrifice_hp_cost: int = -1
