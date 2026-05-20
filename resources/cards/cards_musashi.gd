# resources/cards/cards_musashi.gd
# 미야모토 무사시 카드 — starter 10 + pool 30 (이도류 10 / 결투 10 / 무심 10)
# 이도류: 2히트 스파인 + bonus_per_hit/every_nth Amplifier + MULTI_HIT_RANDOM Chaos
# 결투: enemy_count_1 조건 + strength_player Amplifier + 운명의 결투 Chaos
# 무심: hand_size_0 조건 + echo_next_attack Amplifier + 공허의 전환 Counter
const CardRes = preload("res://resources/card_resource.gd")
const EffRes  = preload("res://resources/effect_resource.gd")
const CommonRes = preload("res://resources/cards/cards_common.gd")

static func starter_deck() -> Array:
	var cards: Array = []
	for _i in range(4):
		cards.append(_strike())
	for _i in range(4):
		cards.append(_defend())
	cards.append(_niten_starter())
	cards.append(_guard_stance())
	cards.append(CommonRes.counter("musashi"))
	return cards

static func pool() -> Array:
	return [
		# ── 이도류 10 (F×3 / A×2 / P×2 / C×2 / Chaos×1) ──
		_niten_slash(), _whirlwind_cut(), _twin_blades_basic(),  # F
		_twin_sword_power(), _rhythm_of_strikes(),               # A
		_flying_swallow(), _five_rings_sword(),                  # P
		_twin_dragon(), _steel_strike(),                         # C
		_demon_swordsman(),                                      # Chaos
		# ── 결투 10 (F×3 / A×2 / P×2 / C×2 / Chaos×1) ──
		_blood_path(), _peak_aim(), _courage(),                  # F
		_swordsmans_resolve(), _blade_polish(),                  # A
		_single_cut(), _final_duel(),                            # P
		_torrent(), _peerless_cut(),                             # C
		_fate_duel(),                                            # Chaos
		# ── 무심 10 (F×3 / A×2 / P×2 / C×2 / Chaos×1) ──
		_meditation(), _empty_state(), _void_sword(),            # F
		_mushin_power(), _empty_guard(),                         # A
		_mushin_blade(), _clear_wind(),                          # P
		_mushin_burst(), _void_guard(),                          # C
		_five_rings_realm(),                                     # Chaos
		# speed buff power (무심 추가)
		_swift_blade(),
		]

static func _swift_blade() -> Resource:
	# 신속의 검 — RARE, 2코, POWER, 무심: 전투 시작 시 본인 power.speed_buff +6 (전투 끝까지)
	var c := CardRes.new()
	c.card_name = "card.musashi.swift_blade.name"; c.owner_id = "musashi"
	c.cost = 2; c.card_type = CardRes.CardType.POWER
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	c.archetype = ["card.musashi.meditation.archetype"]  # 무심
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.APPLY_STATUS
	e.status_type = "power.speed_buff"
	e.value = 6; e.base_value = 6
	e.target = "SELF"
	c.effects = [e]; return c

# ─────────────────────────────────────────
# 시작덱 (4종)
# ─────────────────────────────────────────

static func _strike() -> Resource:
	var c := CardRes.new()
	c.card_name = "card.musashi.strike.name"; c.owner_id = "musashi"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "attack"
	c.archetype = ["card.musashi.strike.archetype"]
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.DAMAGE
	e.value = 100; e.base_value = 100; e.target = "SINGLE"
	e.damage_type = "slash"
	c.effects = [e]; return c

static func _defend() -> Resource:
	var c := CardRes.new()
	c.card_name = "card.musashi.defend.name"; c.owner_id = "musashi"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "idle"
	c.archetype = ["card.musashi.defend.archetype"]
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.BLOCK
	e.value = 125; e.base_value = 125; e.target = "SELF"
	c.effects = [e]; return c

static func _niten_starter() -> Resource:
	# 이도 입문 — COMMON, 1코, ATTACK, 이도류: DMG 50 ×2
	var c := CardRes.new()
	c.card_name = "card.musashi.niten_starter.name"; c.owner_id = "musashi"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "attack"
	c.archetype = ["card.musashi.niten_starter.archetype"]
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.DAMAGE
	e.value = 50; e.base_value = 50; e.target = "SINGLE"; e.hit_count = 2
	e.damage_type = "slash"
	c.effects = [e]; return c

static func _guard_stance() -> Resource:
	# 방어 자세 — COMMON, 1코, SKILL, 결투: BLOCK 75 + STRENGTH 1 (시작덱 Foundation)
	var c := CardRes.new()
	c.card_name = "card.musashi.guard_stance.name"; c.owner_id = "musashi"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "idle"
	c.archetype = ["card.musashi.guard_stance.archetype"]
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.BLOCK
	ea.value = 75; ea.base_value = 75; ea.target = "SELF"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.APPLY_STATUS
	eb.status_type = "strength"; eb.value = 1; eb.base_value = 1; eb.target = "SELF"
	c.effects = [ea, eb]; return c

# ─────────────────────────────────────────
# 이도류 10 — 2히트 스파인
# ─────────────────────────────────────────

static func _niten_slash() -> Resource:
	# [F] 이도 베기 — COMMON, 1코, 공격: DMG 60 ×2
	var c := CardRes.new()
	c.card_name = "card.musashi.niten_slash.name"; c.owner_id = "musashi"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "attack"
	c.archetype = ["card.musashi.niten_slash.archetype"]
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.DAMAGE
	e.value = 60; e.base_value = 60; e.target = "SINGLE"; e.hit_count = 2
	e.damage_type = "slash"
	c.effects = [e]; return c

static func _whirlwind_cut() -> Resource:
	# [F] 선풍참 — COMMON, 1코, 공격: DMG 40 ×2 + BLOCK 40
	var c := CardRes.new()
	c.card_name = "card.musashi.whirlwind_cut.name"; c.owner_id = "musashi"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "attack"
	c.archetype = ["card.musashi.whirlwind_cut.archetype"]
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 40; ea.base_value = 40; ea.target = "SINGLE"; ea.hit_count = 2
	ea.damage_type = "slash"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.BLOCK
	eb.value = 40; eb.base_value = 40; eb.target = "SELF"
	c.effects = [ea, eb]; return c

static func _twin_blades_basic() -> Resource:
	# [F] 쌍도 기초 — UNCOMMON, 1코, 공격: DMG 65 ×2 + VULNERABLE 1
	var c := CardRes.new()
	c.card_name = "card.musashi.twin_blades_basic.name"; c.owner_id = "musashi"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "attack"
	c.archetype = ["card.musashi.twin_blades_basic.archetype"]
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 50; ea.base_value = 50; ea.target = "SINGLE"; ea.hit_count = 2
	ea.damage_type = "slash"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.APPLY_STATUS
	eb.status_type = "vulnerable"; eb.value = 1; eb.base_value = 1; eb.target = "SINGLE"
	c.effects = [ea, eb]; return c

static func _twin_sword_power() -> Resource:
	# [A] 쌍검 권능 — UNCOMMON, 1코, 파워: 히트당 피해 +15
	var c := CardRes.new()
	c.card_name = "card.musashi.twin_sword_power.name"; c.owner_id = "musashi"
	c.cost = 1; c.card_type = CardRes.CardType.POWER
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	c.archetype = ["card.musashi.twin_sword_power.archetype"]
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.APPLY_STATUS
	e.status_type = "power.bonus_per_hit"; e.value = 15; e.base_value = 15; e.target = "SELF"
	c.effects = [e]; return c

static func _rhythm_of_strikes() -> Resource:
	# [A] 연격의 박자 — RARE, 2코, 파워: 3번째 DAMAGE 효과마다 추가 피해 120
	var c := CardRes.new()
	c.card_name = "card.musashi.rhythm_of_strikes.name"; c.owner_id = "musashi"
	c.cost = 2; c.card_type = CardRes.CardType.POWER
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	c.archetype = ["card.musashi.rhythm_of_strikes.archetype"]
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.APPLY_STATUS
	e.status_type = "power.every_nth_attack_bonus"; e.value = 120; e.base_value = 120; e.target = "SELF"
	e.bonus_value = 3; e.base_bonus_value = 3
	c.effects = [e]; return c

static func _flying_swallow() -> Resource:
	# [P] 비연참 — UNCOMMON, 1코, 공격: DMG 30 ×2 + 에너지 +1 (bonus_per_hit 스파인 페이오프)
	var c := CardRes.new()
	c.card_name = "card.musashi.flying_swallow.name"; c.owner_id = "musashi"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "attack"
	c.archetype = ["card.musashi.flying_swallow.archetype"]
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 30; ea.base_value = 30; ea.target = "SINGLE"; ea.hit_count = 2
	ea.damage_type = "slash"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.ENERGY
	eb.value = 1; eb.base_value = 1
	c.effects = [ea, eb]; return c

static func _five_rings_sword() -> Resource:
	# [P] 오륜의 검 — LEGENDARY, 2코, 공격: DMG 120 ×2 (every_nth 카운터 페이오프)
	var c := CardRes.new()
	c.card_name = "card.musashi.five_rings_sword.name"; c.owner_id = "musashi"
	c.cost = 2; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.LEGENDARY; c.play_animation = "attack"
	c.archetype = ["card.musashi.five_rings_sword.archetype"]
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.DAMAGE
	e.value = 120; e.base_value = 120; e.target = "SINGLE"; e.hit_count = 2
	e.damage_type = "slash"
	c.effects = [e]; return c

static func _twin_dragon() -> Resource:
	# [C] 쌍룡섬 — RARE, 2코, 공격: DMG 80 ×2 + BLOCK 80
	var c := CardRes.new()
	c.card_name = "card.musashi.twin_dragon.name"; c.owner_id = "musashi"
	c.cost = 2; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "attack"
	c.archetype = ["card.musashi.twin_dragon.archetype"]
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 80; ea.base_value = 80; ea.target = "SINGLE"; ea.hit_count = 2
	ea.damage_type = "slash"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.BLOCK
	eb.value = 80; eb.base_value = 80; eb.target = "SELF"
	c.effects = [ea, eb]; return c

static func _steel_strike() -> Resource:
	# [C] 강철 일격 — UNCOMMON, 1코, 공격: 현재 BLOCK × 120% 피해 (방어도 활용 카운터)
	var c := CardRes.new()
	c.card_name = "card.musashi.steel_strike.name"; c.owner_id = "musashi"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "attack"
	c.archetype = ["card.musashi.steel_strike.archetype"]
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.DAMAGE_PER_BLOCK
	e.value = 120; e.base_value = 120; e.target = "SINGLE"
	e.damage_type = "slash"
	c.effects = [e]; return c

static func _demon_swordsman() -> Resource:
	# [Chaos] 검귀의 광기 — RARE, 0코, 공격: 랜덤 적에게 5회 30씩, EXHAUST
	var c := CardRes.new()
	c.card_name = "card.musashi.demon_swordsman.name"; c.owner_id = "musashi"
	c.cost = 0; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "attack"
	c.archetype = ["card.musashi.demon_swordsman.archetype"]
	c.is_exhaust = true
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.MULTI_HIT_RANDOM
	e.value = 30; e.base_value = 30; e.hit_count = 5
	e.damage_type = "slash"
	c.effects = [e]; return c

# ─────────────────────────────────────────
# 결투 10 — 1대1 조건 + strength 스파인
# ─────────────────────────────────────────

static func _blood_path() -> Resource:
	# [F] 혈로 개척 — UNCOMMON, 1코, 공격: 적 1명 → 180 + strength 1 / 복수 → 100
	# 중복 다양화: 결투 enemy_count_1 카드 중 Foundation 슬롯 — 1대1 시 strength 적립으로 엔진 역할 부여
	var c := CardRes.new()
	c.card_name = "card.musashi.blood_path.name"; c.owner_id = "musashi"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "attack"
	c.archetype = ["card.musashi.blood_path.archetype"]
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.CONDITIONAL_DMG
	e.value = 100; e.base_value = 100
	e.bonus_value = 180; e.base_bonus_value = 180
	e.target = "SINGLE"; e.status_type = "enemy_count_1"
	e.damage_type = "slash"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.APPLY_STATUS
	eb.status_type = "strength"; eb.value = 1; eb.base_value = 1; eb.target = "SELF"
	eb.condition = "enemy_count_1"
	c.effects = [e, eb]; return c

static func _peak_aim() -> Resource:
	# [F] 정점의 겨냥 — COMMON, 1코, 공격: 적 1명 → 140 / 복수 → 90
	var c := CardRes.new()
	c.card_name = "card.musashi.peak_aim.name"; c.owner_id = "musashi"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "attack"
	c.archetype = ["card.musashi.peak_aim.archetype"]
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.CONDITIONAL_DMG
	e.value = 90; e.base_value = 90
	e.bonus_value = 140; e.base_bonus_value = 140
	e.target = "SINGLE"; e.status_type = "enemy_count_1"
	e.damage_type = "slash"
	c.effects = [e]; return c

static func _courage() -> Resource:
	# [F] 담력 — COMMON, 1코, 방어: BLOCK 115
	var c := CardRes.new()
	c.card_name = "card.musashi.courage.name"; c.owner_id = "musashi"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "idle"
	c.archetype = ["card.musashi.courage.archetype"]
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.BLOCK
	e.value = 115; e.base_value = 115; e.target = "SELF"
	c.effects = [e]; return c

static func _swordsmans_resolve() -> Resource:
	# [A] 검사의 결의 — UNCOMMON, 1코, 파워: strength +2
	var c := CardRes.new()
	c.card_name = "card.musashi.swordsmans_resolve.name"; c.owner_id = "musashi"
	c.cost = 1; c.card_type = CardRes.CardType.POWER
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	c.archetype = ["card.musashi.swordsmans_resolve.archetype"]
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.APPLY_STATUS
	e.status_type = "power.strength_player"; e.value = 2; e.base_value = 2; e.target = "SELF"
	c.effects = [e]; return c

static func _blade_polish() -> Resource:
	# [A] 도검 연마 — UNCOMMON, 0코, 기술: strength +3, EXHAUST (선투자 버스트)
	var c := CardRes.new()
	c.card_name = "card.musashi.blade_polish.name"; c.owner_id = "musashi"
	c.cost = 0; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	c.archetype = ["card.musashi.blade_polish.archetype"]
	c.is_exhaust = true
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.APPLY_STATUS
	e.status_type = "power.strength_player"; e.value = 2; e.base_value = 2; e.target = "SELF"
	var es := EffRes.new()
	es.effect_type = EffRes.EffectType.SACRIFICE_HP; es.value = 30; es.base_value = 30
	c.effects = [e, es]; return c

static func _single_cut() -> Resource:
	# [P] 일도양단 — RARE, 2코, 공격: 적 1명 → 340 / 복수 → 160 (strength 정산)
	var c := CardRes.new()
	c.card_name = "card.musashi.single_cut.name"; c.owner_id = "musashi"
	c.cost = 2; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "attack"
	c.archetype = ["card.musashi.single_cut.archetype"]
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.CONDITIONAL_DMG
	e.value = 160; e.base_value = 160
	e.bonus_value = 340; e.base_bonus_value = 340
	e.target = "SINGLE"; e.status_type = "enemy_count_1"
	e.damage_type = "slash"
	c.effects = [e]; return c

static func _final_duel() -> Resource:
	# [P] 마지막 결투 — RARE, 2코, 공격: 적 1명 → 350 + VULN2 / 160, EXHAUST
	var c := CardRes.new()
	c.card_name = "card.musashi.final_duel.name"; c.owner_id = "musashi"
	c.cost = 2; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "attack"
	c.archetype = ["card.musashi.final_duel.archetype"]
	c.is_exhaust = true
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.CONDITIONAL_DMG
	ea.value = 160; ea.base_value = 160
	ea.bonus_value = 350; ea.base_bonus_value = 350
	ea.target = "SINGLE"; ea.status_type = "enemy_count_1"
	ea.damage_type = "slash"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.APPLY_STATUS
	eb.value = 2; eb.base_value = 2; eb.target = "SINGLE"; eb.status_type = "vulnerable"
	eb.condition = "enemy_count_1"
	c.effects = [ea, eb]; return c

static func _torrent() -> Resource:
	# [C] 격류 — UNCOMMON, 1코, 공격: 적 1명 → 140 + VULN1 / 100 (1대1 카운터)
	var c := CardRes.new()
	c.card_name = "card.musashi.torrent.name"; c.owner_id = "musashi"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "attack"
	c.archetype = ["card.musashi.torrent.archetype"]
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.CONDITIONAL_DMG
	ea.value = 100; ea.base_value = 100
	ea.bonus_value = 140; ea.base_bonus_value = 140
	ea.target = "SINGLE"; ea.status_type = "enemy_count_1"
	ea.damage_type = "slash"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.APPLY_STATUS
	eb.value = 1; eb.base_value = 1; eb.target = "SINGLE"; eb.status_type = "vulnerable"
	eb.condition = "enemy_count_1"
	c.effects = [ea, eb]; return c

static func _peerless_cut() -> Resource:
	# [C] 무쌍 베기 — RARE, 1코, 공격: 적 1명 → 150 + WEAK1 / 90 (디버프 세팅)
	var c := CardRes.new()
	c.card_name = "card.musashi.peerless_cut.name"; c.owner_id = "musashi"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "attack"
	c.archetype = ["card.musashi.peerless_cut.archetype"]
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.CONDITIONAL_DMG
	ea.value = 90; ea.base_value = 90
	ea.bonus_value = 150; ea.base_bonus_value = 150
	ea.target = "SINGLE"; ea.status_type = "enemy_count_1"
	ea.damage_type = "slash"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.APPLY_STATUS
	eb.value = 1; eb.base_value = 1; eb.target = "SINGLE"; eb.status_type = "weak"
	eb.condition = "enemy_count_1"
	c.effects = [ea, eb]; return c

static func _fate_duel() -> Resource:
	# [Chaos] 운명의 결투 — RARE, 2코, 기술: 타겟 적과 3턴 결투 (상호 피해 +50%)
	var c := CardRes.new()
	c.card_name = "card.musashi.fate_duel.name"; c.owner_id = "musashi"
	c.cost = 2; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	c.archetype = ["card.musashi.fate_duel.archetype"]
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.APPLY_STATUS
	e.status_type = "duel_lock"; e.value = 3; e.base_value = 3; e.target = "SINGLE"
	c.effects = [e]; return c

# ─────────────────────────────────────────
# 무심 10 — 빈 손 조건 + echo 스파인
# ─────────────────────────────────────────

static func _meditation() -> Resource:
	# [F] 명상 — UNCOMMON, 1코, 기술: DRAW 1 + BLOCK 40
	var c := CardRes.new()
	c.card_name = "card.musashi.meditation.name"; c.owner_id = "musashi"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	c.archetype = ["card.musashi.meditation.archetype"]
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DRAW
	ea.value = 1; ea.base_value = 1
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.BLOCK
	eb.value = 40; eb.base_value = 40; eb.target = "SELF"
	c.effects = [ea, eb]; return c

static func _empty_state() -> Resource:
	# [F] 무아지경 — RARE, 1코, 기술: DRAW 1 + hand=0 → BLOCK 70 추가
	var c := CardRes.new()
	c.card_name = "card.musashi.empty_state.name"; c.owner_id = "musashi"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	c.archetype = ["card.musashi.empty_state.archetype"]
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.BLOCK
	ea.value = 70; ea.base_value = 70; ea.target = "SELF"
	ea.condition = "hand_size_0"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.DRAW
	eb.value = 1; eb.base_value = 1
	c.effects = [ea, eb]; return c

static func _void_sword() -> Resource:
	# [F] 공허의 검 — COMMON, 1코, 공격: hand=0 → 150 / 75
	var c := CardRes.new()
	c.card_name = "card.musashi.void_sword.name"; c.owner_id = "musashi"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "attack"
	c.archetype = ["card.musashi.void_sword.archetype"]
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.CONDITIONAL_DMG
	e.value = 75; e.base_value = 75
	e.bonus_value = 150; e.base_bonus_value = 150
	e.target = "SINGLE"; e.status_type = "hand_size_0"
	e.damage_type = "holy_slash"
	c.effects = [e]; return c

static func _mushin_power() -> Resource:
	# [A] 무심의 권능 — RARE, 2코, 기술 EXHAUST: 다음 공격 카드 2회 추가시전 (총 3회)
	var c := CardRes.new()
	c.card_name = "card.musashi.mushin_power.name"; c.owner_id = "musashi"
	c.cost = 2; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	c.archetype = ["card.musashi.mushin_power.archetype"]
	c.is_exhaust = true
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.APPLY_STATUS
	e.status_type = "power.echo_next_attack"; e.value = 3; e.base_value = 3; e.target = "SELF"
	c.effects = [e]; return c

static func _empty_guard() -> Resource:
	# [A] 공수처 — UNCOMMON, 1코, 기술: BLOCK 75 + WEAK 1 (공격·방어 자세 → 적 약화)
	var c := CardRes.new()
	c.card_name = "card.musashi.empty_guard.name"; c.owner_id = "musashi"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	c.archetype = ["card.musashi.empty_guard.archetype"]
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.BLOCK
	ea.value = 75; ea.base_value = 75; ea.target = "SELF"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.APPLY_STATUS
	eb.status_type = "weak"; eb.value = 1; eb.base_value = 1; eb.target = "SINGLE"
	c.effects = [ea, eb]; return c

static func _mushin_blade() -> Resource:
	# [P] 무심검 — DIVINE, 0코, 공격: hand=0 → 100 / 30, ETHEREAL
	var c := CardRes.new()
	c.card_name = "card.musashi.mushin_blade.name"; c.owner_id = "musashi"
	c.cost = 0; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.DIVINE; c.play_animation = "attack"
	c.archetype = ["card.musashi.mushin_blade.archetype"]
	c.is_ethereal = true
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.CONDITIONAL_DMG
	e.value = 30; e.base_value = 30
	e.bonus_value = 100; e.base_bonus_value = 100
	e.target = "SINGLE"; e.status_type = "hand_size_0"
	e.damage_type = "holy_slash"
	c.effects = [e]; return c

static func _clear_wind() -> Resource:
	# [P] 청풍명월 — RARE, 2코, 공격: hand=0 → 250 + POISON2 / 120 (무심 대형 정산)
	var c := CardRes.new()
	c.card_name = "card.musashi.clear_wind.name"; c.owner_id = "musashi"
	c.cost = 2; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "attack"
	c.archetype = ["card.musashi.clear_wind.archetype"]
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.CONDITIONAL_DMG
	ea.value = 120; ea.base_value = 120
	ea.bonus_value = 250; ea.base_bonus_value = 250
	ea.target = "SINGLE"; ea.status_type = "hand_size_0"
	ea.damage_type = "holy_slash"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.APPLY_STATUS
	eb.value = 20; eb.base_value = 20; eb.target = "SINGLE"; eb.status_type = "poison"
	eb.condition = "hand_size_0"
	c.effects = [ea, eb]; return c

static func _mushin_burst() -> Resource:
	# [C] 무심 방출 — UNCOMMON, 0코, 기술 EXHAUST: BLOCK 40 + ENERGY 1 (무심 빈손 유지 + 연계 가속)
	var c := CardRes.new()
	c.card_name = "card.musashi.mushin_burst.name"; c.owner_id = "musashi"
	c.cost = 0; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	c.archetype = ["card.musashi.mushin_burst.archetype"]
	c.is_exhaust = true
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.BLOCK
	ea.value = 40; ea.base_value = 40; ea.target = "SELF"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.ENERGY
	eb.value = 1; eb.base_value = 1
	c.effects = [ea, eb]; return c

static func _void_guard() -> Resource:
	# [C] 공허의 방패 — UNCOMMON, 1코, 기술: 상태이상 전부 제거 후 BLOCK 60
	var c := CardRes.new()
	c.card_name = "card.musashi.void_guard.name"; c.owner_id = "musashi"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	c.archetype = ["card.musashi.void_guard.archetype"]
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.PURGE_STATUS; ea.target = "SELF"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.BLOCK; eb.value = 60; eb.base_value = 60
	c.effects = [ea, eb]; return c

static func _five_rings_realm() -> Resource:
	# [Chaos] 오륜의 경지 — LEGENDARY, 2코, 기술: hand=0 → COST_ZERO_TURN + DRAW 1, EXHAUST
	var c := CardRes.new()
	c.card_name = "card.musashi.five_rings_realm.name"; c.owner_id = "musashi"
	c.cost = 2; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.LEGENDARY; c.play_animation = "idle"
	c.archetype = ["card.musashi.five_rings_realm.archetype"]
	c.is_exhaust = true
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.COST_ZERO_TURN
	ea.value = 0; ea.base_value = 0
	ea.condition = "hand_size_0"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.DRAW
	eb.value = 1; eb.base_value = 1
	c.effects = [ea, eb]; return c
