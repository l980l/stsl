# resources/effect_resource.gd
class_name EffectResource
extends Resource

enum EffectType {
	DAMAGE,          # 피해
	BLOCK,           # 방어도
	APPLY_STATUS,    # 상태이상 부여 (status_type 참조)
	DRAW,            # 카드 드로우
	ENERGY,          # 에너지 획득
	SUMMON_TOKEN,    # 병사 토큰 소환
	CHARM,           # 매혹 부여
	HEAL,            # HP 회복
	GAIN_MORALE,     # 사기 +value (나폴레옹)
	CONSUME_MORALE,  # 사기 value 소모 → 피해 bonus_value
	POISON_BURST,    # 대상 독 스택만큼 즉시 피해 + 독 초기화
	COUNTER_BLOCK,   # 피해 = 현재 방어도 × (value / 100)
	BLOCK_ALL,       # 팀 전체 BLOCK value
	HEAL_ALL,        # 팀 전체 HP value 회복
	FORMATION_BLOCK, # 생존 영웅 수 × value BLOCK
	COST_NEXT,       # 이번 턴 다음 카드 비용 -value
	CONDITIONAL_DMG, # 조건 충족 시 bonus_value, 아니면 value 피해. status_type=조건키
}

@export var effect_type: EffectType = EffectType.DAMAGE
@export var value: int = 0
@export var target: String = "SINGLE"       # SINGLE / ALL / SELF
@export var status_type: String = ""        # APPLY_STATUS 시 상태이상 종류: "poison","weak","vulnerable","taunt","strength"
@export var bonus_value: int = 0            # 조건부/추가 효과에 사용
@export var base_value: int = 0             # 0강 기준값. 강화 공식의 베이스.
@export var base_bonus_value: int = 0       # bonus_value의 0강 기준값.

func display_text() -> String:
	match effect_type:
		EffectType.DAMAGE:
			return "피해 %d%s" % [value, " (전체)" if target == "ALL" else ""]
		EffectType.BLOCK:
			return "방어 %d" % value
		EffectType.BLOCK_ALL:
			return "전체 방어 %d" % value
		EffectType.FORMATION_BLOCK:
			return "영웅수×%d 방어" % value
		EffectType.APPLY_STATUS:
			if status_type == "poison":
				return "독 %d 데미지" % (value * 10)
			var st_name: String = {"weak":"약화","vulnerable":"취약",
				"morale":"사기","charm":"매혹","strength":"강화","taunt":"도발"}.get(status_type, status_type)
			return "%s %d" % [st_name, value]
		EffectType.DRAW:        return "드로우 %d" % value
		EffectType.ENERGY:      return "에너지 +%d" % value
		EffectType.HEAL:        return "회복 %d" % value
		EffectType.HEAL_ALL:    return "전체 회복 %d" % value
		EffectType.GAIN_MORALE: return "사기 +%d" % value
		EffectType.CONSUME_MORALE: return "사기→피해 %d" % bonus_value
		EffectType.POISON_BURST:   return "독 즉발"
		EffectType.COUNTER_BLOCK:  return "방어도×%d%%" % value
		EffectType.COST_NEXT:      return "다음 비용 -%d" % value
		EffectType.CONDITIONAL_DMG: return "%d/%d(%s)" % [bonus_value, value, status_type]
		EffectType.SUMMON_TOKEN:   return "병사 소환"
		EffectType.CHARM:          return "매혹 %d" % value
	return ""
