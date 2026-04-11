# resources/effect_resource.gd
class_name EffectResource
extends Resource

enum EffectType {
	DAMAGE,       # 피해
	BLOCK,        # 방어도
	APPLY_STATUS, # 상태이상 부여 (status_type 참조)
	DRAW,         # 카드 드로우
	ENERGY,       # 에너지 획득
	SUMMON_TOKEN, # 병사 토큰 소환 (나폴레옹)
	CHARM,        # 매혹 부여 (클레오파트라)
	HEAL,         # HP 회복
}

@export var effect_type: EffectType = EffectType.DAMAGE
@export var value: int = 0
@export var target: String = "SINGLE"   # SINGLE / ALL / SELF
@export var status_type: String = ""    # APPLY_STATUS 시 상태이상 종류
                                        # "poison","weak","vulnerable","taunt","strength"
