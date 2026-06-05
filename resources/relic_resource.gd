# resources/relic_resource.gd
class_name RelicResource
extends Resource

enum TriggerType {
	PASSIVE,            # 런 시작 시 1회 적용 (최대 HP 등)
	BATTLE_START,       # 전투 시작
	PLAYER_TURN_START,  # 플레이어 턴 시작
	PLAYER_TURN_END,    # 플레이어 턴 종료
	ON_HERO_DAMAGED,    # 영웅 피해 시
}

enum EffectType {
	HEAL, ENERGY, DRAW, APPLY_STATUS_ENEMY, MAX_HP, RECOVER_CARD,
	GAIN_MORALE, COST_REDUCTION, BLOCK,
	DAMAGE_HERO, RUN_STRENGTH,
	BUFF_SPEED_TEAM,    # BATTLE_START — 모든 영웅 power.speed_buff = value (전투 끝까지)
	TIME_HOURGLASS,     # PLAYER_TURN_END — 매 영웅 차례 종료 시 counter++, condition_value 배수마다 모든 영웅 speed_buff += value 누적
}

@export var relic_name: String = ""
@export var description: String = ""
@export var trigger: TriggerType = TriggerType.PASSIVE
@export var effect_type: EffectType = EffectType.HEAL
@export var value: int = 0
@export var owner_hero_id: String = ""  # "" = 공용. 특정 id = 해당 캐릭터 전용
@export var bonus_value: int = 0        # 전용 캐릭터 생존 시 value 대신 사용
@export var status_type: String = ""    # APPLY_STATUS_ENEMY: 부여할 상태이상 ("poison", "weak", 등)
@export var condition_value: int = 0    # ON_HERO_DAMAGED: 최소 피해량 조건
@export var is_cursed: bool = false
@export var penalty_trigger: TriggerType = TriggerType.PASSIVE
@export var penalty_effect_type: EffectType = EffectType.DAMAGE_HERO
@export var penalty_value: int = 0

# 스토리 단서용 i18n lore 키 — relic_name("relic.X.name") → "relic.X.lore" 파생.
# 호출부에서 tr() 후 키 원문/빈값이면 생략 (lore 미존재 유물 안전).
func lore_key() -> String:
	if relic_name.ends_with(".name"):
		return relic_name.trim_suffix(".name") + ".lore"
	return ""
