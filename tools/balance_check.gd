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
const CHARM_SGL   := 1.0
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

const RARITY_MULT := [1.0, 1.1, 1.2, 1.3, 1.4]

const AVG_HAND    := 4.0
const AVG_DEAD    := 0.5
const AVG_BLOCK   := 80.0
const AVG_TOKEN   := 2.0
const AVG_DRAW    := 5.0
const AVG_MORALE  := 3.0
const AVG_ENERGY  := 2.0

const TOLERANCE   := 0.20

var _ok: int = 0
var _ng: int = 0
var _skip: int = 0
var _dup_ng: int = 0
var _pool_sigs: Dictionary = {}  # sig_string -> Array of {hero, name}

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
	print("=== CP 결과 ===")
	print("OK: %d  |  NG: %d  |  SKIP(복합): %d  |  합계: %d" % [_ok, _ng, _skip, _ok + _ng + _skip])
	if _ng == 0:
		print("→ CP 전체 통과!")
	else:
		print("→ NG 카드를 수정하고 재실행하세요.")
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
	var delta: float = adj_cp - float(card.cost)
	var label: String = card.card_name

	if has_skip:
		_skip += 1
		if abs(delta) > 0.8:
			print("  [SKIP⚠] %-55s cost=%d  cp=%.2f  Δ=%+.2f" % [label, card.cost, adj_cp, delta])
	elif abs(delta) <= TOLERANCE:
		_ok += 1
	else:
		_ng += 1
		var tag: String = "HIGH" if delta > 0 else "LOW "
		print("  [NG/%s] %-55s cost=%d  cp=%.2f  Δ=%+.2f" % [tag, label, card.cost, adj_cp, delta])

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
		6:  return eff.value * CHARM_SGL
		7:  return eff.value * (HEAL_ALL if is_all else HEAL_SELF)
		8:  return eff.value * MORALE_V
		9:  return -float(eff.value) * 0.15
		10: return -999.0  # POISON_BURST
		11: return AVG_BLOCK * float(eff.value) / 100.0 * DMG_SINGLE  # COUNTER_BLOCK
		12: return eff.value * BLOCK_ALL  # BLOCK_ALL (상수가 already ALL 보정값)
		13: return eff.value * HEAL_ALL   # HEAL_ALL (상수가 already ALL 보정값)
		14: return -999.0  # FORMATION_BLOCK
		15: return COST_NEXT_V
		16: return float(eff.bonus_value) * DMG_SINGLE * 0.7  # CONDITIONAL_DMG
		17:  # REVIVE
			var bonus: float = 0.4 if eff.value >= 100 else (0.2 if eff.value >= 50 else 0.0)
			return REVIVE_BASE + bonus
		18: return float(eff.value) * SACR_PER_10 / 10.0  # SACRIFICE_HP
		19: return COST_ZERO_V
		20: return -999.0  # BLOCK_PER_CARDS_PLAYED
		21: return -999.0  # ON_KILL_DRAW
		22: return 0.5     # PURGE_STATUS
		23: return AVG_DRAW * float(eff.value) * DMG_SINGLE         # PER_DRAW_DMG
		24: return AVG_BLOCK * float(eff.value) / 100.0 * DMG_SINGLE # DAMAGE_PER_BLOCK
		25: return AVG_DEAD * float(eff.value) * DMG_SINGLE          # DAMAGE_PER_DEAD_ALLY
		26: return -999.0  # DOUBLE_NEXT_DAMAGE
		27: return float(eff.value) * DRAW_V + ENERGY_V  # DISCARD_PICK_DRAW
		28: return AVG_MORALE * float(eff.value) * BLOCK_SELF  # MORALE_TO_BLOCK
		29: return AVG_HAND * float(eff.value) * DMG_SINGLE    # DAMAGE_PER_HAND_SIZE
		30: return AVG_TOKEN * float(eff.value) * DMG_SINGLE   # DAMAGE_PER_TOKEN
		31: return AVG_DEAD * float(eff.value) * HEAL_SELF     # HEAL_PER_DEAD_ALLY
		32: return AVG_ENERGY * float(eff.value) * DMG_SINGLE - AVG_ENERGY * ENERGY_V  # ENERGY_TO_DAMAGE
		33: return -999.0  # STATUS_DOUBLE
	return -999.0

func _calc_status_cp(eff: Resource) -> float:
	var is_all: bool = (eff.target == "ALL")
	match eff.status_type:
		"weak":        return float(eff.value) * (WEAK_ALL_V if is_all else WEAK_SGL)
		"vulnerable":  return float(eff.value) * (WEAK_ALL_V if is_all else WEAK_SGL)
		"poison":      return float(eff.value) * (POISON_ALL_V if is_all else POISON_SGL)
		"charm":       return float(eff.value) * CHARM_SGL
		"strength":    return float(eff.value) * STRENGTH_V
		"morale":      return float(eff.value) * MORALE_V
		"taunt":       return float(eff.value) * TAUNT_V
	if eff.status_type.begins_with("power."):
		return -999.0
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
