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
	REVIVE,              # 사망한 아군 1명을 max_hp의 value% HP로 부활 (잔다르크)
	SACRIFICE_HP,        # 시전자 HP value만큼 즉시 소모 (방어도 무시). 순교 카드
	COST_ZERO_TURN,      # 이번 턴 남은 카드 비용 전부 0 (칭기즈칸 대칸의 명령)
	BLOCK_PER_CARDS_PLAYED, # 이번 턴 카드 사용 횟수 × value BLOCK (칭기즈칸 만리 원정)
	ON_KILL_DRAW,    # 적 처치 시 DRAW n (칭기즈칸 붉은 지평선)
	PURGE_STATUS,    # 아군 디버프(POISON/WEAK/VULNERABLE) 제거. target=SINGLE/ALL
	PER_DRAW_DMG,    # 이번 턴 드로우 카드 수 × value 데미지 (칭기즈칸 사막 기마)
	DAMAGE_PER_BLOCK,     # caster 현재 BLOCK × value/100 데미지
	DAMAGE_PER_DEAD_ALLY, # 사망 아군 수 × value 데미지
	DOUBLE_NEXT_DAMAGE,   # 다음 DAMAGE 효과 ×2 (power 슬롯 등록)
	DISCARD_PICK_DRAW,    # 핸드에서 1장 직접 선택 버림 → DRAW value장 + 에너지 +1
	MORALE_TO_BLOCK,      # caster morale × value BLOCK
	DAMAGE_PER_HAND_SIZE, # 손패 1장당 value 데미지
	DAMAGE_PER_TOKEN,     # caster 살아있는 토큰 수 × value 데미지
	HEAL_PER_DEAD_ALLY,   # 사망 아군 수 × value HP 회복. target=SINGLE/ALL
	ENERGY_TO_DAMAGE,     # 남은 에너지 × value 데미지 + 에너지 소진
	STATUS_DOUBLE,        # 대상 적 weak/vulnerable/poison/charm 스택 ×2
}

@export var effect_type: EffectType = EffectType.DAMAGE
@export var value: int = 0
@export var target: String = "SINGLE"       # SINGLE / ALL / SELF
@export var status_type: String = ""        # APPLY_STATUS 시 상태이상 종류: "poison","weak","vulnerable","taunt","strength"
@export var bonus_value: int = 0            # 조건부/추가 효과에 사용
@export var base_value: int = 0             # 0강 기준값. 강화 공식의 베이스.
@export var base_bonus_value: int = 0       # bonus_value의 0강 기준값.
@export var hit_count: int = 1              # DAMAGE 히트 횟수 (이도류, 징기스의 분노)
@export var condition: String = ""  # 빈 문자열=무조건 발동. "hand_size_0"등 조건 키 설정 시 조건 불충족이면 이 효과 스킵
@export var damage_type: String = ""  # DAMAGE 계열 시각 타입. "" → slash fallback. slash/blunt/projectile/explosive/poison/divine/curse

const _STATUS_NAME_KEYS := {
	"weak":       "status.weak.name",
	"vulnerable": "status.vulnerable.name",
	"morale":     "status.morale.name",
	"charm":      "status.charm.name",
	"strength":   "status.strength.name",
	"taunt":      "status.taunt.name",
}

func display_text() -> String:
	match effect_type:
		EffectType.DAMAGE:
			var hit_str: String = ""
			if hit_count > 1:
				hit_str = " ×%d" % hit_count
			var aoe_str: String = ""
			if target == "ALL":
				aoe_str = TranslationServer.translate("effect.aoe_suffix")
			return TranslationServer.translate("effect.damage.text") % [value, aoe_str, hit_str]
		EffectType.BLOCK:
			return TranslationServer.translate("effect.block.text") % value
		EffectType.BLOCK_ALL:
			return TranslationServer.translate("effect.block_all.text") % value
		EffectType.FORMATION_BLOCK:
			return TranslationServer.translate("effect.formation_block.text") % value
		EffectType.APPLY_STATUS:
			var _base: String
			if status_type == "poison":
				_base = TranslationServer.translate("effect.apply_status_poison.text") % [tr("status.poison.name"), value * 10]
			elif status_type.begins_with("power."):
				var fmt: String = TranslationServer.translate(status_type + ".label")
				_base = fmt % value if fmt.contains("%") else fmt
			else:
				var st_key: String = _STATUS_NAME_KEYS.get(status_type, "")
				var st_name: String = tr(st_key) if st_key else status_type
				_base = "%s %d" % [st_name, value]
			if target == "ALL":
				_base += TranslationServer.translate("effect.aoe_suffix")
			return _base
		EffectType.DRAW:        return TranslationServer.translate("effect.draw.text") % value
		EffectType.ENERGY:      return TranslationServer.translate("effect.energy.text") % value
		EffectType.HEAL:        return TranslationServer.translate("effect.heal.text") % value
		EffectType.HEAL_ALL:    return TranslationServer.translate("effect.heal_all.text") % value
		EffectType.GAIN_MORALE: return TranslationServer.translate("effect.gain_morale.text") % value
		EffectType.CONSUME_MORALE: return TranslationServer.translate("effect.consume_morale.text") % bonus_value
		EffectType.POISON_BURST:   return TranslationServer.translate("effect.poison_burst.text")
		EffectType.COUNTER_BLOCK:  return TranslationServer.translate("effect.counter_block.text") % value
		EffectType.COST_NEXT:      return TranslationServer.translate("effect.cost_next.text") % value
		EffectType.CONDITIONAL_DMG:
			var cond_key: String = _STATUS_NAME_KEYS.get(status_type, "")
			var cond_name: String
			if status_type == "poison":
				cond_name = tr("status.poison.name")
			elif cond_key:
				cond_name = tr(cond_key)
			else:
				cond_name = status_type
			return TranslationServer.translate("effect.conditional_dmg.text") % [bonus_value, value, cond_name]
		EffectType.SUMMON_TOKEN:   return TranslationServer.translate("effect.summon_token.text") % value
		EffectType.CHARM:          return TranslationServer.translate("effect.charm.text") % value
		EffectType.REVIVE:              return TranslationServer.translate("effect.revive.text") % value
		EffectType.SACRIFICE_HP:        return TranslationServer.translate("effect.sacrifice_hp.text") % value
		EffectType.COST_ZERO_TURN:      return TranslationServer.translate("effect.cost_zero_turn.text")
		EffectType.BLOCK_PER_CARDS_PLAYED: return TranslationServer.translate("effect.block_per_cards_played.text") % value
		EffectType.ON_KILL_DRAW:        return TranslationServer.translate("effect.on_kill_draw.text") % value
		EffectType.PURGE_STATUS:        return TranslationServer.translate("effect.purge_status.text")
		EffectType.PER_DRAW_DMG:        return TranslationServer.translate("effect.per_draw_dmg.text") % value
		EffectType.DAMAGE_PER_BLOCK:     return TranslationServer.translate("effect.damage_per_block.text") % value
		EffectType.DAMAGE_PER_DEAD_ALLY: return TranslationServer.translate("effect.damage_per_dead_ally.text") % value
		EffectType.DOUBLE_NEXT_DAMAGE:   return TranslationServer.translate("effect.double_next_damage.text")
		EffectType.DISCARD_PICK_DRAW:    return TranslationServer.translate("effect.discard_pick_draw.text") % value
		EffectType.MORALE_TO_BLOCK:      return TranslationServer.translate("effect.morale_to_block.text")
		EffectType.DAMAGE_PER_HAND_SIZE: return TranslationServer.translate("effect.damage_per_hand_size.text") % value
		EffectType.DAMAGE_PER_TOKEN:     return TranslationServer.translate("effect.damage_per_token.text") % value
		EffectType.HEAL_PER_DEAD_ALLY:   return TranslationServer.translate("effect.heal_per_dead_ally.text") % value
		EffectType.ENERGY_TO_DAMAGE:     return TranslationServer.translate("effect.energy_to_damage.text") % value
		EffectType.STATUS_DOUBLE:
			var _sd := TranslationServer.translate("effect.status_double.text")
			if target == "ALL":
				_sd += TranslationServer.translate("effect.aoe_suffix")
			return _sd
	return ""
