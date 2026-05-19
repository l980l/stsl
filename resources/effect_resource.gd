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
	SACRIFICE_PAYOFF,     # power.sacrifice_bank 읽기 → (뱅크/100) × value dmg 또는 block (status_type="block")
	CHARM_TO_DAMAGE,      # 대상 적 charm 스택 소비 → 스택당 bonus_value dmg
	MULTI_HIT_RANDOM,     # 랜덤 적에게 hit_count회 value 피해 (같은 적 반복 가능)
	DAMAGE_PER_STATUS_TYPE, # 대상 적의 디버프 종류 수(weak/vuln/poison/charm) × value 피해
	DRAW_PER_ENTHRALL,    # 이 카드 사용 중 반함(enthrall) 발동 횟수 × value 드로우 (클레오 입맞춤)
	DAMAGE_PER_CHARMED_ENEMY, # 현재 charm 스택 보유 적 수 × value 피해 (황금 왕좌)
	BUFF_SPEED,      # 영웅 speed +value, bonus_value 턴 일정 지속 (SELF/ALL_ALLIES/ALLY)
	DEBUFF_SPEED,    # 적 speed -value, bonus_value 턴 일정 지속 (SINGLE/ALL)
	MARK_ENEMY,      # 영웅이 적에게 마킹 — 적 status.marked_by 에 owner_id 추가. 모든 영웅 공격 치명타 확률 +30%.
	COUNTER_REFLECT, # 보스 CHARGE_UP + counter_window 활성 → 차지 무효 + stun. 그 외 → counter_pending 부여 (다음 공격 50% 반감 + 100% 반사).
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
@export var damage_type: String = ""  # DAMAGE 계열 시각 타입. "" → slash fallback. slash/blunt/projectile/bullet/explosive/poison/curse/holy_strike/holy_slash/holy_bolt/holy_blunt/holy_fire

const _STATUS_NAME_KEYS := {
	"weak":          "status.weak.name",
	"vulnerable":    "status.vulnerable.name",
	"morale":        "status.morale.name",
	"charm":         "status.charm.name",
	"strength":      "status.strength.name",
	"taunt":         "status.taunt.name",
}

func display_text(override_value: int = -1) -> String:
	# override_value >= 0 면 데미지 표시에 그 값 사용 (UI 가 buff/debuff 적용한 효과 데미지).
	# DAMAGE / CONDITIONAL_DMG 등 데미지 계열만 override 의미 있음.
	var v: int = override_value if override_value >= 0 else value
	match effect_type:
		EffectType.DAMAGE:
			var hit_str: String = ""
			if hit_count > 1:
				hit_str = " ×%d" % hit_count
			var _dmg_key: String = "effect.damage.all.text" if target == "ALL" else "effect.damage.single.text"
			return TranslationServer.translate(_dmg_key) % [v, hit_str]
		EffectType.BLOCK:
			return TranslationServer.translate("effect.block.text") % value
		EffectType.BLOCK_ALL:
			return TranslationServer.translate("effect.block_all.text") % value
		EffectType.FORMATION_BLOCK:
			return TranslationServer.translate("effect.formation_block.text") % value
		EffectType.APPLY_STATUS:
			if status_type == "poison":
				var _pk: String = "effect.apply_status_poison.all.text" if target == "ALL" else "effect.apply_status_poison.single.text"
				return TranslationServer.translate(_pk) % (value * 10)
			elif status_type == "power.every_nth_attack_bonus":
				var fmt: String = TranslationServer.translate("power.every_nth_attack_bonus.label")
				return fmt % [bonus_value, value] if fmt.contains("%") else fmt
			elif status_type.begins_with("power."):
				var fmt: String = TranslationServer.translate(status_type + ".label")
				return fmt % value if fmt.contains("%") else fmt
			else:
				var st_key: String = _STATUS_NAME_KEYS.get(status_type, "")
				var st_name: String = tr(st_key) if st_key else status_type
				var _label: String = "%s %d" % [st_name, value]
				var _wk: String = "effect.apply_status.all.text" if target == "ALL" else "effect.apply_status.single.text"
				return TranslationServer.translate(_wk) % _label
		EffectType.DRAW:        return TranslationServer.translate("effect.draw.text") % value
		EffectType.ENERGY:      return TranslationServer.translate("effect.energy.text") % value
		EffectType.HEAL:        return TranslationServer.translate("effect.heal.text") % value
		EffectType.HEAL_ALL:    return TranslationServer.translate("effect.heal_all.text") % value
		EffectType.GAIN_MORALE: return TranslationServer.translate("effect.gain_morale.text") % value
		EffectType.CONSUME_MORALE: return TranslationServer.translate("effect.consume_morale.text") % bonus_value
		EffectType.POISON_BURST:
			if target == "ALL":
				return TranslationServer.translate("effect.poison_burst_all.text")
			return TranslationServer.translate("effect.poison_burst.text")
		EffectType.COUNTER_BLOCK:  return TranslationServer.translate("effect.counter_block.text") % value
		EffectType.COST_NEXT:      return TranslationServer.translate("effect.cost_next.text") % value
		EffectType.CONDITIONAL_DMG:
			var cond_key: String = _STATUS_NAME_KEYS.get(status_type, "")
			var cond_name: String
			if status_type == "poison" or status_type == "has_poison":
				cond_name = tr("effect.condition.has_poison")
			elif status_type.begins_with("has_poison_"):
				var n := status_type.trim_prefix("has_poison_").to_int()
				cond_name = tr("effect.condition.has_poison_n").replace("%d", str(n))
			elif status_type.begins_with("has_debuffs_"):
				var n := status_type.trim_prefix("has_debuffs_").to_int()
				cond_name = tr("effect.condition.has_debuffs").replace("%d", str(n))
			elif status_type == "has_morale":
				cond_name = tr("effect.condition.has_morale")
			elif status_type.begins_with("has_morale_"):
				var n := status_type.trim_prefix("has_morale_").to_int()
				cond_name = tr("effect.condition.has_morale_n").replace("%d", str(n))
			elif status_type == "low_hp":
				cond_name = tr("effect.condition.low_hp")
			elif status_type == "very_low_hp":
				cond_name = tr("effect.condition.very_low_hp")
			elif status_type.begins_with("hand_size_"):
				var n := status_type.trim_prefix("hand_size_").to_int()
				cond_name = tr("effect.condition.hand_size_n").replace("%d", str(n))
			elif status_type.begins_with("enemy_count_"):
				var n := status_type.trim_prefix("enemy_count_").to_int()
				cond_name = tr("effect.condition.enemy_count_n").replace("%d", str(n))
			elif status_type.begins_with("enemy_hp_below_"):
				var n := status_type.trim_prefix("enemy_hp_below_").to_int()
				cond_name = tr("effect.condition.enemy_hp_below").replace("%d", str(n))
			elif cond_key:
				cond_name = tr(cond_key)
			else:
				cond_name = status_type
			return TranslationServer.translate("effect.conditional_dmg.text") % [value, cond_name, bonus_value]
		EffectType.SUMMON_TOKEN:   return TranslationServer.translate("effect.summon_token.text") % value
		EffectType.CHARM:
			var _ck: String = "effect.charm.all.text" if target == "ALL" else "effect.charm.text"
			var _ct: String = TranslationServer.translate(_ck) % value
			if condition.begins_with("enemy_hp_below_"):
				var _n: int = condition.trim_prefix("enemy_hp_below_").to_int()
				var _cond: String = tr("effect.condition.enemy_hp_below").replace("%d", str(_n))
				_ct = _cond + ": " + _ct
			return _ct
		EffectType.REVIVE:              return TranslationServer.translate("effect.revive.text") % value
		EffectType.SACRIFICE_HP:        return TranslationServer.translate("effect.sacrifice_hp.text") % value
		EffectType.COST_ZERO_TURN:      return TranslationServer.translate("effect.cost_zero_turn.text")
		EffectType.BLOCK_PER_CARDS_PLAYED: return TranslationServer.translate("effect.block_per_cards_played.text") % value
		EffectType.ON_KILL_DRAW:        return TranslationServer.translate("effect.on_kill_draw.text") % value
		EffectType.PURGE_STATUS:
			var _psk: String = "effect.purge_status.all.text" if target == "ALL" else "effect.purge_status.single.text"
			return TranslationServer.translate(_psk)
		EffectType.PER_DRAW_DMG:        return TranslationServer.translate("effect.per_draw_dmg.text") % value
		EffectType.DAMAGE_PER_BLOCK:     return TranslationServer.translate("effect.damage_per_block.text") % value
		EffectType.DAMAGE_PER_DEAD_ALLY: return TranslationServer.translate("effect.damage_per_dead_ally.text") % value
		EffectType.DOUBLE_NEXT_DAMAGE:   return TranslationServer.translate("effect.double_next_damage.text")
		EffectType.DISCARD_PICK_DRAW:    return TranslationServer.translate("effect.discard_pick_draw.text") % value
		EffectType.MORALE_TO_BLOCK:      return TranslationServer.translate("effect.morale_to_block.text")
		EffectType.DAMAGE_PER_HAND_SIZE: return TranslationServer.translate("effect.damage_per_hand_size.text") % value
		EffectType.DAMAGE_PER_TOKEN:     return TranslationServer.translate("effect.damage_per_token.text") % value
		EffectType.HEAL_PER_DEAD_ALLY:
			var _hpk: String = "effect.heal_per_dead_ally.all.text" if target == "ALL" else "effect.heal_per_dead_ally.single.text"
			return TranslationServer.translate(_hpk) % value
		EffectType.ENERGY_TO_DAMAGE:     return TranslationServer.translate("effect.energy_to_damage.text") % value
		EffectType.STATUS_DOUBLE:
			var _sdk: String = "effect.status_double.all.text" if target == "ALL" else "effect.status_double.single.text"
			return TranslationServer.translate(_sdk)
		EffectType.SACRIFICE_PAYOFF:
			if status_type == "block":
				return TranslationServer.translate("effect.sacrifice_payoff.block.text") % value
			return TranslationServer.translate("effect.sacrifice_payoff.text") % value
		EffectType.CHARM_TO_DAMAGE:
			return TranslationServer.translate("effect.charm_to_damage.text") % bonus_value
		EffectType.MULTI_HIT_RANDOM:
			return TranslationServer.translate("effect.multi_hit_random.text") % [hit_count, value]
		EffectType.DAMAGE_PER_STATUS_TYPE:
			return TranslationServer.translate("effect.damage_per_status_type.text") % value
		EffectType.DRAW_PER_ENTHRALL:
			return TranslationServer.translate("effect.draw_per_enthrall.text") % value
		EffectType.DAMAGE_PER_CHARMED_ENEMY:
			return TranslationServer.translate("effect.damage_per_charmed_enemy.text") % value
		EffectType.BUFF_SPEED:
			var _bsk: String
			match target:
				"SELF": _bsk = "effect.buff_speed.self.text"
				"ALL_ALLIES": _bsk = "effect.buff_speed.all_allies.text"
				_: _bsk = "effect.buff_speed.ally.text"
			return TranslationServer.translate(_bsk) % [value, bonus_value]
		EffectType.DEBUFF_SPEED:
			var _dsk: String = "effect.debuff_speed.all.text" if target == "ALL" else "effect.debuff_speed.single.text"
			return TranslationServer.translate(_dsk) % [value, bonus_value]
		EffectType.MARK_ENEMY:
			return TranslationServer.translate("effect.mark_enemy.text")
		EffectType.COUNTER_REFLECT:
			return "다음 공격 50% 반감 + 100% 반사 (차지 보스 → 무효 + 기절)"
	return ""
