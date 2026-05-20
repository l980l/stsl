# resources/cards/cards_cleopatra.gd
# 클레오파트라 카드 — starter 10 + pool 30 (독살 12 / 저주 10 / 조종 8)
# 독살: 독 축적 스파인 + poison_per_turn/poison_double Amplifier + MULTI_HIT_RANDOM Chaos
# 저주: 디버프 복합 + block_per_turn/debuff_amplify Amplifier + STATUS_DOUBLE Payoff
# 조종: 매혹 빌드업(임계 100/저항 120) + on_enthrall 트리거(입맞춤·뱀의 의식) + CHARM_TO_DAMAGE/황금 왕좌 Payoff
const CardRes = preload("res://resources/card_resource.gd")
const EffRes  = preload("res://resources/effect_resource.gd")
const CommonRes = preload("res://resources/cards/cards_common.gd")

static func starter_deck() -> Array:
	var cards: Array = []
	for _i in range(4):
		cards.append(_strike())
	for _i in range(4):
		cards.append(_defend())
	cards.append(_venom_needle())
	cards.append(_royal_guard())
	cards.append(CommonRes.counter("cleopatra"))
	return cards

static func pool() -> Array:
	return [
		# ── 독살 12 (F×4 / A×2 / P×3 / C×2 / Chaos×1) ──
		_poison_seed(), _asp_fang(), _nile_mist(), _poison_feast(),  # F
		_serpent_power(), _pharaoh_venom(),                          # A
		_poison_ritual(), _pharaohs_plague(), _poison_throne(),       # P
		_poison_party(), _poison_purge(),                            # C
		_nile_fury(),                                                # Chaos
		# ── 저주 10 (F×3 / A×2 / P×2 / C×2 / Chaos×1) ──
		_cursed_gaze(), _sandstorm(), _snake_gaze(),                 # F
		_ramesses_shield(), _isis_wrath(),                           # A
		_curse_brand(), _isis_judgment(),                            # P
		_desert_recipe(), _pharaoh_fury(),                           # C
		_venom_bloom(),                                              # Chaos
		# ── 조종 8 (F×3 / A×1 / P×3 / Chaos×1) ──
		_temptation(), _nile_whisper(), _cleopatras_kiss(),          # F
		_queens_dignity(),                                           # A
		_charming_perfume(), _charm_execution(), _serpent_ritual(),  # P
		_golden_throne(),                                            # Chaos
		# speed debuff (조종 추가)
		_seductive_stillness(),
		]

static func _seductive_stillness() -> Resource:
	# 유혹의 정체 — UNCOMMON, 1코, SKILL, 조종: 적 1명 speed -5 (3턴)
	var c := CardRes.new()
	c.card_name = "card.cleopatra.seductive_stillness.name"; c.owner_id = "cleopatra"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	c.archetype = ["card.cleopatra.temptation.archetype"]  # 조종
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.DEBUFF_SPEED
	e.value = 5; e.base_value = 5
	e.bonus_value = 3; e.base_bonus_value = 3
	e.target = "SINGLE"
	c.effects = [e]; return c

# ─────────────────────────────────────────
# 시작덱 (4종)
# ─────────────────────────────────────────

static func _strike() -> Resource:
	var c := CardRes.new()
	c.card_name = "card.cleopatra.strike.name"; c.owner_id = "cleopatra"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "attack"
	c.archetype = ["card.cleopatra.strike.archetype"]
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.DAMAGE
	e.value = 100; e.base_value = 100; e.target = "SINGLE"
	e.damage_type = "slash"
	c.effects = [e]; return c

static func _defend() -> Resource:
	var c := CardRes.new()
	c.card_name = "card.cleopatra.defend.name"; c.owner_id = "cleopatra"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "idle"
	c.archetype = ["card.cleopatra.defend.archetype"]
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.BLOCK
	e.value = 125; e.base_value = 125; e.target = "SELF"
	c.effects = [e]; return c

static func _venom_needle() -> Resource:
	# 독침 — COMMON, 1코, ATTACK, 독살: DMG 60 + POISON 1 (시작덱 Foundation)
	var c := CardRes.new()
	c.card_name = "card.cleopatra.venom_needle.name"; c.owner_id = "cleopatra"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "attack"
	c.archetype = ["card.cleopatra.venom_needle.archetype"]
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 60; ea.base_value = 60; ea.target = "SINGLE"
	ea.damage_type = "poison"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.APPLY_STATUS
	eb.status_type = "poison"; eb.value = 10; eb.base_value = 10; eb.target = "SINGLE"
	c.effects = [ea, eb]; return c

static func _royal_guard() -> Resource:
	# 왕실 방어 — COMMON, 1코, SKILL, 저주: BLOCK 80 + POISON 1 (시작덱 Foundation)
	var c := CardRes.new()
	c.card_name = "card.cleopatra.royal_guard.name"; c.owner_id = "cleopatra"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "idle"
	c.archetype = ["card.cleopatra.royal_guard.archetype", "card.cleopatra.strike.archetype"]
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.BLOCK
	ea.value = 80; ea.base_value = 80
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.APPLY_STATUS
	eb.status_type = "poison"; eb.value = 10; eb.base_value = 10; eb.target = "SINGLE"
	c.effects = [ea, eb]; return c

# ─────────────────────────────────────────
# 독살 12 — 독 축적 스파인
# ─────────────────────────────────────────

static func _poison_seed() -> Resource:
	# [F] 독의 씨앗 — COMMON, 1코, ATTACK: DMG 20 + POISON 1 ALL
	var c := CardRes.new()
	c.card_name = "card.cleopatra.poison_seed.name"; c.owner_id = "cleopatra"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "attack"
	c.archetype = ["card.cleopatra.poison_seed.archetype"]
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 20; ea.base_value = 20; ea.target = "SINGLE"
	ea.damage_type = "poison"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.APPLY_STATUS
	eb.status_type = "poison"; eb.value = 10; eb.base_value = 10; eb.target = "ALL"
	c.effects = [ea, eb]; return c

static func _asp_fang() -> Resource:
	# [F] 아스프의 독니 — UNCOMMON, 1코, ATTACK: POISON 3 SINGLE
	var c := CardRes.new()
	c.card_name = "card.cleopatra.asp_fang.name"; c.owner_id = "cleopatra"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "attack"
	c.archetype = ["card.cleopatra.asp_fang.archetype"]
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.APPLY_STATUS
	e.status_type = "poison"; e.value = 30; e.base_value = 30; e.target = "SINGLE"
	c.effects = [e]; return c

static func _nile_mist() -> Resource:
	# [F] 나일의 안개 — RARE, 1코, SKILL: POISON 1 ALL + BLOCK 40 SELF
	var c := CardRes.new()
	c.card_name = "card.cleopatra.nile_mist.name"; c.owner_id = "cleopatra"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	c.archetype = ["card.cleopatra.nile_mist.archetype"]
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.APPLY_STATUS
	ea.status_type = "poison"; ea.value = 10; ea.base_value = 10; ea.target = "ALL"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.BLOCK
	eb.value = 40; eb.base_value = 40; eb.target = "SELF"
	c.effects = [ea, eb]; return c

static func _poison_feast() -> Resource:
	# [F] 독의 향연 — UNCOMMON, 1코, ATTACK: DMG 20 + POISON 2
	var c := CardRes.new()
	c.card_name = "card.cleopatra.poison_feast.name"; c.owner_id = "cleopatra"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "attack"
	c.archetype = ["card.cleopatra.poison_feast.archetype"]
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 20; ea.base_value = 20; ea.target = "SINGLE"
	ea.damage_type = "poison"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.APPLY_STATUS
	eb.status_type = "poison"; eb.value = 20; eb.base_value = 20; eb.target = "SINGLE"
	c.effects = [ea, eb]; return c

static func _serpent_power() -> Resource:
	# [A] 독사의 권능 — RARE, 1코, POWER: 매 턴 POISON 2 ALL
	var c := CardRes.new()
	c.card_name = "card.cleopatra.serpent_power.name"; c.owner_id = "cleopatra"
	c.cost = 1; c.card_type = CardRes.CardType.POWER
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	c.archetype = ["card.cleopatra.serpent_power.archetype"]
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.APPLY_STATUS
	e.status_type = "power.poison_per_turn"; e.value = 10; e.base_value = 10; e.target = "SELF"
	c.effects = [e]; return c

static func _pharaoh_venom() -> Resource:
	# [A] 파라오의 독력 — RARE, 0코, SKILL: 남은 에너지 소모, 에너지당 독 부여량 ×2 / 강화: +1스택
	var c := CardRes.new()
	c.card_name = "card.cleopatra.pharaoh_venom.name"; c.owner_id = "cleopatra"
	c.cost = 0; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	c.archetype = ["card.cleopatra.pharaoh_venom.archetype"]
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.APPLY_STATUS
	e.status_type = "power.spend_all_energy_poison_double"; e.value = 0; e.base_value = 0; e.target = "SELF"
	c.effects = [e]; return c

static func _poison_ritual() -> Resource:
	# [P] 독살의 의식 — RARE, 1코, SKILL: POISON_BURST SINGLE (독 스택 즉시 피해 + 초기화)
	var c := CardRes.new()
	c.card_name = "card.cleopatra.poison_ritual.name"; c.owner_id = "cleopatra"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	c.archetype = ["card.cleopatra.poison_ritual.archetype"]
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.POISON_BURST
	e.value = 100; e.base_value = 100; e.target = "SINGLE"
	e.damage_type = "poison"
	c.effects = [e]; return c

static func _pharaohs_plague() -> Resource:
	# [P] 파라오의 역병 — LEGENDARY, 2코, SKILL: POISON_BURST ALL (전체 독 즉시 폭발, 독살 크로스 페이오프)
	var c := CardRes.new()
	c.card_name = "card.cleopatra.pharaohs_plague.name"; c.owner_id = "cleopatra"
	c.cost = 2; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.LEGENDARY; c.play_animation = "idle"
	c.archetype = ["card.cleopatra.pharaohs_plague.archetype"]
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.POISON_BURST
	e.value = 100; e.base_value = 100; e.target = "ALL"
	e.damage_type = "poison"
	c.effects = [e]; return c

static func _poison_throne() -> Resource:
	# [P] 독의 옥좌 — LEGENDARY, 2코, ATTACK: 디버프 종류당 피해 80 (크로스 아키 페이오프)
	var c := CardRes.new()
	c.card_name = "card.cleopatra.poison_throne.name"; c.owner_id = "cleopatra"
	c.cost = 2; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.LEGENDARY; c.play_animation = "attack"
	c.archetype = ["card.cleopatra.poison_throne.archetype"]
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.DAMAGE_PER_STATUS_TYPE
	e.value = 130; e.base_value = 130; e.target = "SINGLE"
	e.damage_type = "poison"
	c.effects = [e]; return c

static func _poison_party() -> Resource:
	# [C] 독의 잔치 — UNCOMMON, 2코, ATTACK: DMG 80 ALL + POISON 1 ALL
	var c := CardRes.new()
	c.card_name = "card.cleopatra.poison_party.name"; c.owner_id = "cleopatra"
	c.cost = 2; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "attack"
	c.archetype = ["card.cleopatra.poison_party.archetype"]
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 80; ea.base_value = 80; ea.target = "ALL"
	ea.damage_type = "poison"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.APPLY_STATUS
	eb.status_type = "poison"; eb.value = 10; eb.base_value = 10; eb.target = "ALL"
	c.effects = [ea, eb]; return c

static func _poison_purge() -> Resource:
	# [C] 독의 정화 — UNCOMMON, 2코, SKILL: 아군 디버프 제거 SELF + POISON 2 ALL
	var c := CardRes.new()
	c.card_name = "card.cleopatra.poison_purge.name"; c.owner_id = "cleopatra"
	c.cost = 2; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	c.archetype = ["card.cleopatra.poison_purge.archetype"]
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.PURGE_STATUS
	ea.target = "SELF"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.APPLY_STATUS
	eb.status_type = "poison"; eb.value = 20; eb.base_value = 20; eb.target = "ALL"
	c.effects = [ea, eb]; return c

static func _nile_fury() -> Resource:
	# [Chaos] 나일의 분노 — RARE, 2코, ATTACK: 랜덤 적 5회 30씩 + POISON 1 ALL
	var c := CardRes.new()
	c.card_name = "card.cleopatra.nile_fury.name"; c.owner_id = "cleopatra"
	c.cost = 2; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "attack"
	c.archetype = ["card.cleopatra.nile_fury.archetype"]
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.MULTI_HIT_RANDOM
	ea.value = 65; ea.base_value = 65; ea.hit_count = 5
	ea.damage_type = "poison"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.APPLY_STATUS
	eb.status_type = "poison"; eb.value = 10; eb.base_value = 10; eb.target = "ALL"
	c.effects = [ea, eb]; return c

# ─────────────────────────────────────────
# 저주 10 — 디버프 복합 스파인
# ─────────────────────────────────────────

static func _cursed_gaze() -> Resource:
	# [F] 저주의 시선 — UNCOMMON, 1코, SKILL: WEAK 1 ALL + VULN 1 SINGLE
	var c := CardRes.new()
	c.card_name = "card.cleopatra.cursed_gaze.name"; c.owner_id = "cleopatra"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	c.archetype = ["card.cleopatra.cursed_gaze.archetype"]
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.APPLY_STATUS
	ea.status_type = "weak"; ea.value = 1; ea.base_value = 1; ea.target = "ALL"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.APPLY_STATUS
	eb.status_type = "vulnerable"; eb.value = 1; eb.base_value = 1; eb.target = "SINGLE"
	c.effects = [ea, eb]; return c

static func _sandstorm() -> Resource:
	# [F] 모래폭풍 — COMMON, 1코, ATTACK: DMG 30 ALL + WEAK 1 ALL
	var c := CardRes.new()
	c.card_name = "card.cleopatra.sandstorm.name"; c.owner_id = "cleopatra"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "attack"
	c.archetype = ["card.cleopatra.sandstorm.archetype"]
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 30; ea.base_value = 30; ea.target = "ALL"
	ea.damage_type = "curse"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.APPLY_STATUS
	eb.status_type = "weak"; eb.value = 1; eb.base_value = 1; eb.target = "ALL"
	c.effects = [ea, eb]; return c

static func _snake_gaze() -> Resource:
	# [F] 뱀의 눈빛 — COMMON, 1코, SKILL: VULNERABLE 3 SINGLE
	var c := CardRes.new()
	c.card_name = "card.cleopatra.snake_gaze.name"; c.owner_id = "cleopatra"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "idle"
	c.archetype = ["card.cleopatra.snake_gaze.archetype"]
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.APPLY_STATUS
	e.status_type = "vulnerable"; e.value = 3; e.base_value = 3; e.target = "SINGLE"
	c.effects = [e]; return c

static func _ramesses_shield() -> Resource:
	# [A] 람세스의 방패 — RARE, 1코, POWER: 매 턴 BLOCK +12
	var c := CardRes.new()
	c.card_name = "card.cleopatra.ramesses_shield.name"; c.owner_id = "cleopatra"
	c.cost = 1; c.card_type = CardRes.CardType.POWER
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	c.archetype = ["card.cleopatra.ramesses_shield.archetype"]
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.APPLY_STATUS
	e.status_type = "power.block_per_turn"; e.value = 45; e.base_value = 45; e.target = "SELF"
	c.effects = [e]; return c

static func _isis_wrath() -> Resource:
	# [A] 이시스의 진노 — RARE, 2코, POWER: 디버프 부여 시 +1 스택 추가
	var c := CardRes.new()
	c.card_name = "card.cleopatra.isis_wrath.name"; c.owner_id = "cleopatra"
	c.cost = 2; c.card_type = CardRes.CardType.POWER
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	c.archetype = ["card.cleopatra.isis_wrath.archetype"]
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.APPLY_STATUS
	e.status_type = "power.debuff_amplify"; e.value = 1; e.base_value = 1; e.target = "SELF"
	c.effects = [e]; return c

static func _curse_brand() -> Resource:
	# [P] 저주의 낙인 — RARE, 1코, SKILL: DMG 40 + WEAK 1 + VULN 1 + POISON 1 (독의 옥좌 세팅)
	var c := CardRes.new()
	c.card_name = "card.cleopatra.curse_brand.name"; c.owner_id = "cleopatra"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	c.archetype = ["card.cleopatra.curse_brand.archetype", "card.cleopatra.strike.archetype"]
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 40; ea.base_value = 40; ea.target = "SINGLE"
	ea.damage_type = "curse"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.APPLY_STATUS
	eb.status_type = "weak"; eb.value = 1; eb.base_value = 1; eb.target = "SINGLE"
	var ec := EffRes.new()
	ec.effect_type = EffRes.EffectType.APPLY_STATUS
	ec.status_type = "vulnerable"; ec.value = 1; ec.base_value = 1; ec.target = "SINGLE"
	var ed := EffRes.new()
	ed.effect_type = EffRes.EffectType.APPLY_STATUS
	ed.status_type = "poison"; ed.value = 10; ed.base_value = 10; ed.target = "SINGLE"
	c.effects = [ea, eb, ec, ed]; return c

static func _isis_judgment() -> Resource:
	# [P] 이시스의 심판 — LEGENDARY, 1코, SKILL EXHAUST: STATUS_DOUBLE ALL (전체 디버프 ×2, 한 게임당 1회)
	var c := CardRes.new()
	c.card_name = "card.cleopatra.isis_judgment.name"; c.owner_id = "cleopatra"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.LEGENDARY; c.play_animation = "idle"
	c.archetype = ["card.cleopatra.isis_judgment.archetype"]
	c.is_exhaust = true
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.STATUS_DOUBLE
	e.value = 0; e.base_value = 0; e.target = "ALL"
	c.effects = [e]; return c

static func _desert_recipe() -> Resource:
	# [C] 사막의 비책 — UNCOMMON, 2코, SKILL: DISCARD_PICK_DRAW 2 (버리고 2드로우+에너지)
	var c := CardRes.new()
	c.card_name = "card.cleopatra.desert_recipe.name"; c.owner_id = "cleopatra"
	c.cost = 2; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	c.archetype = ["card.cleopatra.desert_recipe.archetype"]
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.DISCARD_PICK_DRAW
	e.value = 2; e.base_value = 2
	c.effects = [e]; return c

static func _pharaoh_fury() -> Resource:
	# [C] 파라오의 분노 — RARE, 2코, ATTACK: DMG 100 ALL + WEAK 1 ALL (광역 반격)
	var c := CardRes.new()
	c.card_name = "card.cleopatra.pharaoh_fury.name"; c.owner_id = "cleopatra"
	c.cost = 2; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "attack"
	c.archetype = ["card.cleopatra.pharaoh_fury.archetype"]
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 100; ea.base_value = 100; ea.target = "ALL"
	ea.damage_type = "curse"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.APPLY_STATUS
	eb.status_type = "weak"; eb.value = 1; eb.base_value = 1; eb.target = "ALL"
	c.effects = [ea, eb]; return c

static func _venom_bloom() -> Resource:
	# [Chaos] 독꽃의 만개 — RARE, 2코, ATTACK: DMG 40 ALL + POISON 2 ALL (독 폭발 세팅)
	var c := CardRes.new()
	c.card_name = "card.cleopatra.venom_bloom.name"; c.owner_id = "cleopatra"
	c.cost = 2; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "attack"
	c.archetype = ["card.cleopatra.venom_bloom.archetype"]
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 40; ea.base_value = 40; ea.target = "ALL"
	ea.damage_type = "poison"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.APPLY_STATUS
	eb.status_type = "poison"; eb.value = 20; eb.base_value = 20; eb.target = "ALL"
	c.effects = [ea, eb]; return c

# ─────────────────────────────────────────
# 조종 8 — 매혹 자원화 스파인
# ─────────────────────────────────────────

static func _temptation() -> Resource:
	# [F] 유혹 — UNCOMMON, 1코, SKILL: CHARM 30 SINGLE
	var c := CardRes.new()
	c.card_name = "card.cleopatra.temptation.name"; c.owner_id = "cleopatra"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	c.archetype = ["card.cleopatra.temptation.archetype"]
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.CHARM
	e.value = 30; e.base_value = 30; e.target = "SINGLE"
	c.effects = [e]; return c

static func _nile_whisper() -> Resource:
	# [F] 나일의 속삭임 — UNCOMMON, 1코, SKILL: CHARM 25 ALL (광역 빌드업)
	var c := CardRes.new()
	c.card_name = "card.cleopatra.nile_whisper.name"; c.owner_id = "cleopatra"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	c.archetype = ["card.cleopatra.nile_whisper.archetype"]
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.CHARM
	e.value = 25; e.base_value = 25; e.target = "ALL"
	c.effects = [e]; return c

static func _cleopatras_kiss() -> Resource:
	# [F] 클레오의 입맞춤 — DIVINE, 2코, SKILL: CHARM 60 SINGLE + 반함 시 카드 2장 드로우
	var c := CardRes.new()
	c.card_name = "card.cleopatra.cleopatras_kiss.name"; c.owner_id = "cleopatra"
	c.cost = 2; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.DIVINE; c.play_animation = "idle"
	c.archetype = ["card.cleopatra.cleopatras_kiss.archetype"]
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.CHARM
	ea.value = 60; ea.base_value = 60; ea.target = "SINGLE"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.DRAW_PER_ENTHRALL
	eb.value = 2; eb.base_value = 2
	c.effects = [ea, eb]; return c

static func _queens_dignity() -> Resource:
	# [A] 여왕의 위엄 — RARE, 1코, POWER: 매혹 임계치 -20
	var c := CardRes.new()
	c.card_name = "card.cleopatra.queens_dignity.name"; c.owner_id = "cleopatra"
	c.cost = 1; c.card_type = CardRes.CardType.POWER
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	c.archetype = ["card.cleopatra.queens_dignity.archetype"]
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.APPLY_STATUS
	e.status_type = "power.charm_threshold_minus"; e.value = 40; e.base_value = 40; e.target = "SELF"
	c.effects = [e]; return c

static func _charming_perfume() -> Resource:
	# [P] 매혹의 향기 — RARE, 3코, SKILL EXHAUST: 2턴 동안 매혹 부여 시 스택 ×2
	var c := CardRes.new()
	c.card_name = "card.cleopatra.charming_perfume.name"; c.owner_id = "cleopatra"
	c.cost = 3; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	c.archetype = ["card.cleopatra.charming_perfume.archetype"]
	c.is_exhaust = true
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.APPLY_STATUS
	e.status_type = "power.charm_double_apply"; e.value = 2; e.base_value = 2; e.target = "SELF"
	c.effects = [e]; return c

static func _charm_execution() -> Resource:
	# [P] 매혹의 처형 — RARE, 2코, ATTACK: 적 매혹 스택 소비 → 스택당 2 피해 (100스택=200)
	var c := CardRes.new()
	c.card_name = "card.cleopatra.charm_execution.name"; c.owner_id = "cleopatra"
	c.cost = 2; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "attack"
	c.archetype = ["card.cleopatra.charm_execution.archetype", "card.cleopatra.defend.archetype"]
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.CHARM_TO_DAMAGE
	e.bonus_value = 5; e.base_bonus_value = 5; e.target = "SINGLE"
	e.damage_type = "curse"
	c.effects = [e]; return c

static func _serpent_ritual() -> Resource:
	# [P] 뱀의 의식 — LEGENDARY, 1코, POWER: 반함 발동 시마다 strength +20 영구
	var c := CardRes.new()
	c.card_name = "card.cleopatra.serpent_ritual.name"; c.owner_id = "cleopatra"
	c.cost = 1; c.card_type = CardRes.CardType.POWER
	c.rarity = CardRes.Rarity.LEGENDARY; c.play_animation = "idle"
	c.archetype = ["card.cleopatra.serpent_ritual.archetype"]
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.APPLY_STATUS
	e.status_type = "power.on_enthrall_strength"; e.value = 20; e.base_value = 20; e.target = "SELF"
	c.effects = [e]; return c

static func _golden_throne() -> Resource:
	# [Chaos] 황금 왕좌 — LEGENDARY, 2코, ATTACK, EXHAUST: 모든 적에 150 dmg + 매혹된 적 1마리당 추가 20 dmg ALL
	var c := CardRes.new()
	c.card_name = "card.cleopatra.golden_throne.name"; c.owner_id = "cleopatra"
	c.cost = 2; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.LEGENDARY; c.play_animation = "attack"
	c.archetype = ["card.cleopatra.golden_throne.archetype", "card.cleopatra.defend.archetype"]
	c.is_exhaust = true
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 150; ea.base_value = 150; ea.target = "ALL"
	ea.damage_type = "curse"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.DAMAGE_PER_CHARMED_ENEMY
	eb.value = 20; eb.base_value = 20; eb.target = "ALL"
	eb.damage_type = "curse"
	c.effects = [ea, eb]; return c
