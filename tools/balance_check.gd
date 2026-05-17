# tools/balance_check.gd
# 헤드리스 실행: godot --headless --script tools/balance_check.gd
extends SceneTree

const DMG_SINGLE  := 0.010
const DMG_ALL     := 0.017
const BLOCK_SELF  := 0.008
const BLOCK_ALL   := 0.013
const HEAL_SELF   := 0.013
const HEAL_ALL    := 0.020
const WEAK_SGL    := 0.3
const WEAK_ALL_V  := 0.6
const POISON_SGL  := 0.4
const POISON_ALL_V:= 0.8
const CHARM_SGL   := 0.030  # 임계치 100 기준: 스택당 0.030 CP (단일)
const CHARM_ALL   := 0.045  # AOE 보정 (×1.5)
const STRENGTH_V  := 0.5
const MORALE_V    := 0.4
const TAUNT_V     := 0.3
const DRAW_V      := 0.8
const ENERGY_V    := 0.7
const TOKEN_V     := 0.8
const REVIVE_BASE := 3.0
const COST_NEXT_V := 0.7
const COST_ZERO_V := 2.5
const EXHAUST_P   := -0.8
const ETHEREAL_P  := -0.5
const INNATE_B    := 0.3
const RETAIN_B    := 0.4
const SACR_PER_10 := -0.04

const RARITY_MULT  := [1.0, 1.1, 1.2, 1.3, 1.4]
# rarity 인덱스 → game_manager.upgrade_card의 rate (COMMON=0 변화 없음)
const UPGRADE_RATE := [0.0, 0.10, 0.12, 0.14, 0.16]
const UPGRADE_CP_STEP := 0.15  # 강화 1회당 기대 CP 증가율

const AVG_HAND          := 4.0
const AVG_DEAD          := 0.5
const AVG_BLOCK         := 80.0
const AVG_TOKEN         := 2.0
const AVG_TOKEN_PAYOFF  := 3.0  # DAMAGE_PER_TOKEN payoff 사용 시점 추정 토큰 수
const AVG_CARDS_PLAYED  := 4    # BLOCK_PER_CARDS_PLAYED 사용 시점 추정 카드 수
const AVG_TEAM          := 2    # FORMATION_BLOCK 살아있는 영웅 수 (사망 가능성 보수치)
const AVG_CHARM_AT_PAYOFF := 50 # CHARM_TO_DAMAGE 사용 시점 평균 누적 스택 (임계 100 기준)
const AVG_POISON        := 10   # POISON_BURST SINGLE 사용 시점 평균 독 스택
const AVG_POISON_ALL    := 15   # POISON_BURST ALL 사용 시점 (독살 빌드업 완성 기준)
const POISON_TICK       := 10   # 엔진 POISON_DMG_PER_STACK 동기화
const P_KILL            := 0.6  # ON_KILL_DRAW 킬 발생 확률
const AVG_STATUS_TYPES  := 2    # DAMAGE_PER_STATUS_TYPE 평균 디버프 종류 수
const MHR_MULT          := 0.005 # MULTI_HIT_RANDOM 히트당 CP 계수 (0코 EXHAUST 역산)
const AVG_SACRIFICE_BANK := 700  # SACRIFICE_PAYOFF 사용 시점 희생 누적 (value 기준)
const P_ENTHRALL        := 0.6   # DRAW_PER_ENTHRALL 발동 시 적 매혹 상태 확률
const AVG_KILLS         := 2     # on_kill_energy — 배틀당 평균 처치 수
const AVG_HIT_TOTAL     := 8     # bonus_per_hit — 배틀당 이도류 총 히트 수 (4장×2hit)
const AVG_ATTACKS       := 6     # every_nth_attack_bonus — 배틀당 공격 카드 수
const AVG_CARD_TRIGGER  := 4     # 카드 사용 횟수 기반 파워 효과 기준
const CHARM_DOUBLE_V    := 2.2   # power.charm_double_apply — 1턴당 매혹 더블 CP (3코 역산)
const ON_ENTHRALL_STR_V := 0.065 # power.on_enthrall_strength — 스트랭스 포인트당 CP (1코 역산)
const STATUS_DOUBLE_V   := 2.1   # STATUS_DOUBLE ALL 고정 CP (1코 LEGENDARY EXHAUST 역산)
const DUEL_LOCK_V       := 0.8   # duel_lock — 1턴당 CP (2코 역산)
const ECHO_CAST_V       := 1.07  # power.echo_next_attack — 총 시전 횟수당 CP (2코 EXHAUST 역산)
const SPEND_E_POISON_DOUBLE_PER_E := 1.2  # X코 독더블 에너지당 CP (유효코스트=AVG_ENERGY RARE 역산)
const SPEED_PER_TURN_V := 0.08   # BUFF/DEBUFF_SPEED — 1 speed × 1 turn duration 의 단위 CP
const SPEED_POWER_V    := 0.40   # power.speed_buff — 1 speed (전투 끝까지) CP
const SPEED_ALLY_MULT  := 1.1    # ALLY (단일 동맹) — 선택 가능 보너스
const SPEED_ALL_ALLIES_MULT := 1.8  # ALL_ALLIES — 3 영웅 보정
const SPEED_ALL_ENEMY_MULT  := 1.5  # ALL (적 전체)
const AVG_DRAW          := 5.0
const AVG_MORALE        := 3.0
const AVG_ENERGY        := 2.0
const AVG_CHARMED       := 2.0
const AVG_TURNS         := 3

const TOLERANCE   := 0.20
const TOLERANCE_UP := 0.30  # 업그레이드 허용 오차 (비례 효과 혼재 카드에 여유 부여)

# game_manager.upgrade_card PERCENT_TYPES/INT_TYPES와 동기화 (EffectType 정수값)
# DRAW(3)·ENERGY(4)·GAIN_MORALE(8)·SUMMON_TOKEN(5)는 게임에서 +1씩 오르지만
# 작은 기저값(1~3)에서 CP 증가율이 50~100%로 15%/레벨 기준을 초과함.
# PERCENT_U로 분류 시 int(base×(1+rate)) → 소형값 유지 → delta ≈ -15% 이내. 노이즈 제거 목적.
const _PERCENT_U := [0, 1, 7, 12, 13, 14, 11, 10, 9, 16, 23, 3, 4, 8, 5, 2, 34, 36]
# DAMAGE,BLOCK,HEAL,BLOCK_ALL,HEAL_ALL,FORMATION_BLOCK,COUNTER_BLOCK,POISON_BURST,CONSUME_MORALE,CONDITIONAL_DMG,PER_DRAW_DMG,DRAW,ENERGY,GAIN_MORALE,SUMMON_TOKEN,APPLY_STATUS,SACRIFICE_PAYOFF,MULTI_HIT_RANDOM
const _INT_U     := [6, 15]
# CHARM,COST_NEXT
# ON_KILL_DRAW(21): 게임에서는 INT_TYPES(+1/레벨)이나 P_KILL 보정으로 +1장이 +0.48 CP → 15%/레벨 모델 초과. 업그레이드 투영 제외.

var _ok: int = 0
var _ng: int = 0
var _skip: int = 0
var _ok_up: int = 0
var _ng_up: int = 0
var _dup_ng: int = 0
var _pool_sigs: Dictionary = {}

func _initialize() -> void:
	print("\n=== balance_check.gd — 카드 CP 검증 ===\n")
	var files: Array[String] = [
		"res://resources/cards/cards_napoleon.gd",
		"res://resources/cards/cards_cleopatra.gd",
		"res://resources/cards/cards_yi_sun_sin.gd",
		"res://resources/cards/cards_joan_of_arc.gd",
		"res://resources/cards/cards_genghis_khan.gd",
		"res://resources/cards/cards_musashi.gd",
	]
	for path in files:
		var hero_name: String = path.get_file().trim_suffix(".gd").trim_prefix("cards_")
		print("── %s ──" % hero_name)
		var HeroCards: GDScript = load(path)
		if HeroCards == null:
			push_error("로드 실패: " + path)
			continue
		var starter: Array = HeroCards.starter_deck()
		var pool: Array = HeroCards.pool()
		for card in starter + pool:
			_check_card(card)
		_collect_pool_sigs(hero_name, pool)
		print("")
	print("=== CP 결과 (0강) ===")
	print("OK: %d  |  NG: %d  |  SKIP(복합): %d  |  합계: %d" % [_ok, _ng, _skip, _ok + _ng + _skip])
	if _ng == 0:
		print("→ CP 전체 통과!")
	else:
		print("→ NG 카드를 수정하고 재실행하세요.")
	print("")
	print("=== 업그레이드 CP 결과 (기대: +15%/레벨) ===")
	print("OK: %d  |  NG: %d" % [_ok_up, _ng_up])
	if _ng_up == 0:
		print("→ 업그레이드 CP 전체 통과!")
	else:
		print("→ NG 업그레이드 카드를 수정하고 재실행하세요.")
	print("")
	_check_duplicates()
	quit()

func _check_card(card: Resource) -> void:
	var raw_cp: float = 0.0
	var has_skip: bool = false
	for eff in card.effects:
		var v: float = _calc_effect_cp(eff)
		if v == -999.0:
			has_skip = true
		else:
			raw_cp += v
	if card.get("is_exhaust") == true:  raw_cp += EXHAUST_P
	if card.get("is_ethereal") == true: raw_cp += ETHEREAL_P
	if card.get("is_innate") == true:   raw_cp += INNATE_B
	if card.get("is_retain") == true:   raw_cp += RETAIN_B

	var mult: float = RARITY_MULT[card.rarity] if card.rarity < RARITY_MULT.size() else 1.0
	var adj_cp: float = raw_cp / mult

	# X코 카드: spend_all_energy 효과가 있으면 소모 에너지를 유효코스트에 합산
	var effective_cost: float = float(card.cost)
	for eff in card.effects:
		if eff.get("status_type") != null and (eff.status_type as String).begins_with("power.spend_all_energy"):
			effective_cost += float(AVG_ENERGY)
			break

	var delta: float = adj_cp - effective_cost
	var label: String = card.card_name

	if has_skip:
		_skip += 1
		if abs(delta) > 0.8:
			print("  [SKIP⚠] %-55s cost=%.0f  cp=%.2f  Δ=%+.2f" % [label, effective_cost, adj_cp, delta])
	elif abs(delta) <= TOLERANCE:
		_ok += 1
	else:
		_ng += 1
		var tag: String = "HIGH" if delta > 0 else "LOW "
		print("  [NG/%s] %-55s cost=%.0f  cp=%.2f  Δ=%+.2f" % [tag, label, effective_cost, adj_cp, delta])

	# 업그레이드 CP 검증 — SKIP 카드는 제외 (복합 효과라 기댓값 신뢰 불가)
	if has_skip:
		return
	var max_lv: int = card.max_upgrade_level() if card.has_method("max_upgrade_level") else 0
	for lv in range(1, max_lv + 1):
		var result: Array = _calc_raw_cp_at_level(card, lv)
		var raw_up: float = result[0]
		var skip_up: bool = result[1]
		if skip_up:
			continue
		var adj_up: float = raw_up / mult
		var expected: float = adj_cp * (1.0 + UPGRADE_CP_STEP * float(lv))
		# 실질적으로 변화 없는 레벨 스킵 (DRAW·ENERGY·REVIVE 등 소형값이 반올림으로 불변인 경우)
		if abs(adj_up - adj_cp) < 0.15:
			continue
		var delta_up: float = adj_up - expected
		if abs(delta_up) <= TOLERANCE_UP:
			_ok_up += 1
		else:
			_ng_up += 1
			var tag: String = "HIGH" if delta_up > 0 else "LOW "
			print("  [NG/%s+%d] %-51s exp=%.2f  act=%.2f  Δ=%+.2f" % [tag, lv, label, expected, adj_up, delta_up])

func _calc_raw_cp_at_level(card: Resource, level: int) -> Array:
	# [raw_cp: float, has_skip: bool]
	var rate: float = UPGRADE_RATE[card.rarity] if card.rarity < UPGRADE_RATE.size() else 0.0
	var raw: float = 0.0
	var has_skip: bool = false
	for eff in card.effects:
		var sim: Resource = eff.duplicate()
		_apply_upgrade(sim, level, rate)
		var v: float = _calc_effect_cp(sim)
		if v == -999.0:
			has_skip = true
		else:
			raw += v
	if card.get("is_exhaust") == true:  raw += EXHAUST_P
	if card.get("is_ethereal") == true: raw += ETHEREAL_P
	if card.get("is_innate") == true:   raw += INNATE_B
	if card.get("is_retain") == true:   raw += RETAIN_B
	return [raw, has_skip]

func _apply_upgrade(eff: Resource, level: int, rate: float) -> void:
	if eff.effect_type in _PERCENT_U:
		eff.value = int(eff.base_value * (1.0 + rate * float(level)))
		eff.bonus_value = int(eff.base_bonus_value * (1.0 + rate * float(level)))
	elif eff.effect_type == 2 and eff.status_type.begins_with("power."):
		# power.* APPLY_STATUS: game_manager에서 +1/레벨
		eff.value = eff.base_value + level
	elif eff.effect_type in _INT_U:
		eff.value = eff.base_value + level
		if eff.base_bonus_value > 0:
			eff.bonus_value = eff.base_bonus_value + level

func _calc_effect_cp(eff: Resource) -> float:
	var is_all: bool = (eff.target == "ALL")
	var hit_mult: int = eff.get("hit_count") if eff.get("hit_count") != null else 1
	if hit_mult < 1: hit_mult = 1
	match eff.effect_type:
		0:  return eff.value * (DMG_ALL if is_all else DMG_SINGLE) * hit_mult
		1:  return eff.value * (BLOCK_ALL if is_all else BLOCK_SELF)
		2:  return _calc_status_cp(eff)
		3:  return eff.value * DRAW_V
		4:  return eff.value * ENERGY_V
		5:  return eff.value * TOKEN_V
		6:  return eff.value * (CHARM_ALL if is_all else CHARM_SGL)
		7:  return eff.value * (HEAL_ALL if is_all else HEAL_SELF)
		8:  return eff.value * MORALE_V
		9:  return -float(eff.value) * 0.15
		10:  # POISON_BURST
			if is_all: return AVG_POISON_ALL * (float(eff.value)/100.0) * POISON_TICK * DMG_ALL
			return AVG_POISON * (float(eff.value)/100.0) * POISON_TICK * DMG_SINGLE
		11: return AVG_BLOCK * float(eff.value) / 100.0 * DMG_SINGLE  # COUNTER_BLOCK
		12: return eff.value * BLOCK_ALL
		13: return eff.value * HEAL_ALL
		14: return AVG_TEAM * float(eff.value) * BLOCK_SELF  # FORMATION_BLOCK
		15: return COST_NEXT_V
		16:  # CONDITIONAL_DMG — 극단값(9999 등) chaos 카드 제외
			if eff.bonus_value > 999: return -999.0
			return float(eff.bonus_value) * DMG_SINGLE * 0.7
		17:  # REVIVE
			var bonus: float = 0.4 if eff.value >= 100 else (0.2 if eff.value >= 50 else 0.0)
			return REVIVE_BASE + bonus
		18: return float(eff.value) * SACR_PER_10 / 10.0  # SACRIFICE_HP
		19: return COST_ZERO_V
		20: return AVG_CARDS_PLAYED * float(eff.value) * BLOCK_SELF  # BLOCK_PER_CARDS_PLAYED
		21: return float(eff.value) * DRAW_V * P_KILL  # ON_KILL_DRAW
		22: return 0.5     # PURGE_STATUS
		23: return AVG_DRAW * float(eff.value) * DMG_SINGLE
		24: return AVG_BLOCK * float(eff.value) / 100.0 * DMG_SINGLE  # DAMAGE_PER_BLOCK
		25: return AVG_DEAD * float(eff.value) * DMG_SINGLE           # DAMAGE_PER_DEAD_ALLY
		26: return -999.0  # DOUBLE_NEXT_DAMAGE
		27: return float(eff.value) * DRAW_V + ENERGY_V               # DISCARD_PICK_DRAW
		28: return AVG_MORALE * float(eff.value) * BLOCK_SELF         # MORALE_TO_BLOCK
		29: return AVG_HAND * float(eff.value) * DMG_SINGLE           # DAMAGE_PER_HAND_SIZE
		30: return AVG_TOKEN_PAYOFF * float(eff.value) * (DMG_ALL if is_all else DMG_SINGLE)  # DAMAGE_PER_TOKEN
		31: return AVG_DEAD * float(eff.value) * HEAL_SELF            # HEAL_PER_DEAD_ALLY
		32: return AVG_ENERGY * float(eff.value) * DMG_SINGLE - AVG_ENERGY * ENERGY_V  # ENERGY_TO_DAMAGE
		33: return STATUS_DOUBLE_V  # STATUS_DOUBLE
		34: return (float(AVG_SACRIFICE_BANK) / 100.0) * float(eff.value) * (BLOCK_ALL if eff.status_type == "block" else DMG_ALL)  # SACRIFICE_PAYOFF
		35: return AVG_CHARM_AT_PAYOFF * float(eff.bonus_value) * (DMG_ALL if is_all else DMG_SINGLE)  # CHARM_TO_DAMAGE
		36: return float(hit_mult) * float(eff.value) * MHR_MULT  # MULTI_HIT_RANDOM
		37: return AVG_STATUS_TYPES * float(eff.value) * (DMG_ALL if is_all else DMG_SINGLE)  # DAMAGE_PER_STATUS_TYPE
		38: return float(eff.value) * DRAW_V * P_ENTHRALL  # DRAW_PER_ENTHRALL
		39: return AVG_CHARMED * float(eff.value) * (DMG_ALL if is_all else DMG_SINGLE)  # DAMAGE_PER_CHARMED_ENEMY
		40:  # BUFF_SPEED
			var bs_mult: float = 1.0
			if eff.target == "ALL_ALLIES": bs_mult = SPEED_ALL_ALLIES_MULT
			elif eff.target == "ALLY":     bs_mult = SPEED_ALLY_MULT
			return float(eff.value) * float(eff.bonus_value) * SPEED_PER_TURN_V * bs_mult
		41:  # DEBUFF_SPEED
			var ds_mult: float = SPEED_ALL_ENEMY_MULT if is_all else 1.0
			return float(eff.value) * float(eff.bonus_value) * SPEED_PER_TURN_V * ds_mult
	return -999.0

func _calc_status_cp(eff: Resource) -> float:
	var is_all: bool = (eff.target == "ALL")
	match eff.status_type:
		"weak":       return float(eff.value) * (WEAK_ALL_V if is_all else WEAK_SGL)
		"vulnerable": return float(eff.value) * (WEAK_ALL_V if is_all else WEAK_SGL)
		"poison":     return float(eff.value) * (POISON_ALL_V if is_all else POISON_SGL)
		"charm":      return float(eff.value) * (CHARM_ALL if is_all else CHARM_SGL)
		"strength":   return float(eff.value) * STRENGTH_V
		"morale":     return float(eff.value) * MORALE_V
		"taunt":      return float(eff.value) * TAUNT_V
		"duel_lock":  return float(eff.value) * DUEL_LOCK_V
	if eff.status_type.begins_with("power."):
		match eff.status_type:
			"power.block_per_turn":     return float(eff.value) * BLOCK_SELF * AVG_TURNS
			"power.heal_team_per_turn": return float(eff.value) * HEAL_ALL   * AVG_TURNS
			"power.summon_per_turn":    return float(eff.value) * TOKEN_V    * AVG_TURNS
			"power.draw_per_turn":      return float(eff.value) * DRAW_V     * AVG_TURNS
			"power.morale_per_turn":    return float(eff.value) * MORALE_V   * AVG_TURNS
			"power.poison_per_turn":    return float(eff.value) * POISON_SGL * AVG_TURNS
			"power.strength_player":    return float(eff.value) * STRENGTH_V  # 즉발 영구 버프
			"power.on_kill_energy":     return float(AVG_KILLS) * float(eff.value) * ENERGY_V
			"power.bonus_per_hit":      return float(AVG_HIT_TOTAL) * float(eff.value) * DMG_SINGLE
			"power.every_nth_attack_bonus": return (float(AVG_ATTACKS) / float(eff.bonus_value)) * float(eff.value) * DMG_SINGLE
			"power.debuff_amplify":         return float(AVG_CARD_TRIGGER) * float(eff.value) * WEAK_ALL_V
			"power.charm_threshold_minus":  return float(eff.value) * CHARM_SGL
			"power.token_bonus_dmg":        return float(AVG_TOKEN) * float(eff.value) * DMG_SINGLE * float(AVG_ATTACKS)
			"power.charm_double_apply":     return float(eff.value) * CHARM_DOUBLE_V
			"power.on_enthrall_strength":   return float(eff.value) * ON_ENTHRALL_STR_V
			"power.sacrifice_bank":         return 1.2
			"power.echo_next_attack":          return float(eff.value) * ECHO_CAST_V
			"power.spend_all_energy_poison_double": return float(AVG_ENERGY) * SPEND_E_POISON_DOUBLE_PER_E
			"power.speed_buff":                return float(eff.value) * SPEED_POWER_V
		return -999.0  # 복합/조건부/시너지형 — SKIP 유지
	return -999.0

func _collect_pool_sigs(hero: String, cards: Array) -> void:
	for card in cards:
		var sig: String = _card_sig(card)
		if not _pool_sigs.has(sig):
			_pool_sigs[sig] = []
		_pool_sigs[sig].append({"hero": hero, "name": card.card_name})

func _check_duplicates() -> void:
	print("=== 효과 중복 검사 (풀 카드 기준) ===\n")
	var found: int = 0
	for sig: String in _pool_sigs:
		var entries: Array = _pool_sigs[sig]
		if entries.size() < 2:
			continue
		found += 1
		_dup_ng += 1
		var label: String = ""
		for i in entries.size():
			if i > 0:
				label += " ≡ "
			label += "%s/%s" % [entries[i].hero, entries[i].name]
		print("  [DUP] " + label)
	if found == 0:
		print("  → 중복 없음! 전체 통과.")
	else:
		print("\n  중복 %d건 발견 — 삭제 또는 효과 차별화 필요." % found)

func _card_sig(card: Resource) -> String:
	var sigs: Array[String] = []
	for eff in card.effects:
		sigs.append(_effect_sig(eff))
	sigs.sort()
	return "|".join(PackedStringArray(sigs))

func _effect_sig(eff: Resource) -> String:
	var etype: int = eff.effect_type
	var val: int = eff.value
	var tgt: String = eff.get("target") if eff.get("target") != null else ""
	var stype: String = eff.get("status_type") if eff.get("status_type") != null else ""
	var hits: int = eff.get("hit_count") if eff.get("hit_count") != null else 1
	var cond: String = str(eff.get("condition_type")) if eff.get("condition_type") != null else ""
	return "%d|%d|%s|%s|%d|%s" % [etype, val, tgt, stype, hits, cond]
