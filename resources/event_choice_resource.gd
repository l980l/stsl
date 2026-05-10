# resources/event_choice_resource.gd
class_name EventChoiceResource
extends Resource

# 기본 효과 + 신규 효과
# - TRIGGER_BATTLE: 선택 즉시 전투 진입. 승리 시 reward_effect_type/reward_value 적용
# - ADD_CARD: card_id로 지정한 카드를 덱에 추가
# - MULTI: effect_type + secondary_effect_type 두 가지를 동시에 적용
enum EffectType {
	NONE,
	GOLD,
	HEAL,
	DRAW_UP,
	REMOVE_CARD,
	ADD_RELIC,
	ADD_HERO,
	ADD_RELIC_GAMBLE,
	TRIGGER_BATTLE,
	ADD_CARD,
	MULTI,
}

@export var label: String = ""
@export var effect_type: EffectType = EffectType.NONE
@export var value: int = 0
@export var cost_gold: int = 0
@export var cost_hp: int = 0

# 다중 효과 (MULTI 또는 보조 효과로 사용)
@export var secondary_effect_type: EffectType = EffectType.NONE
@export var secondary_value: int = 0

# 확률 효과 (0 또는 100이면 비활성. success_chance% 확률로 effect, 실패 시 alt_*)
@export_range(0, 100, 5) var success_chance: int = 0
@export var alt_effect_type: EffectType = EffectType.NONE
@export var alt_value: int = 0

# TRIGGER_BATTLE 보상 (승리 시 적용)
# encounter_tier: 0=보통(현재 floor), 1=엘리트급
@export_range(0, 1) var encounter_tier: int = 0
@export var reward_effect_type: EffectType = EffectType.NONE
@export var reward_value: int = 0

# ADD_CARD: 추가할 카드 리소스 경로 (예: "res://resources/cards/strike.tres")
@export var card_id: String = ""

# 조건부 선택지 — 비어있지 않으면 해당 영웅 보유 시에만 활성화
@export var required_hero_id: String = ""
