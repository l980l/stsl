# resources/cards/cards_cleopatra.gd
# 클레오파트라 카드 40장 — HP 1000 스케일 기준
const CardRes = preload("res://resources/card_resource.gd")
const EffRes  = preload("res://resources/effect_resource.gd")

static func starter_deck() -> Array:
	var cards: Array = []
	for _i in range(2):
		cards.append(_venom_needle())
	for _i in range(2):
		cards.append(_royal_guard())
	return cards

static func pool() -> Array:
	return [
		# v1 카드 13장 (시작덱 제외)
		_poison_seed(), _isis_blessing(), _asp_fang(),
		_desert_poison_dance(), _cursed_gaze(), _temptation(),
		_nile_mist(), _serpent_grasp(), _pharaoh_poison(),
		_ramesses_shield(), _nile_fury(), _pharaoh_decree(),
		_cleopatras_kiss(),
		# v2 추가 카드 25장
		_poison_fog_spray(), _wax_trap(), _sandstorm(),
		_nile_blessing(), _snake_gaze(), _double_fang(),
		_tempting_eye(), _poison_feast(), _pharaoh_curse(),
		_nile_flow(), _snake_poison_dance(), _charming_language(),
		_desert_recipe(), _poison_judgment(), _isis_fury(),
		_poison_ritual(), _queens_embrace(), _curse_brand(),
		_nile_doom(), _charming_assault(), _pharaoh_fury(),
		_curse_crossroads(), _poison_throne(), _isis_judgment(),
		_sekhmet_curse(),
	]

# ─────────────────────────────────────────
# 시작덱 (2종)
# ─────────────────────────────────────────

static func _venom_needle() -> Resource:
	# 독침 — COMMON, 1코, ATTACK, 독살: DMG 80 + POISON 3
	var c := CardRes.new()
	c.card_name = TranslationServer.translate("card.cleopatra.venom_needle.name"); c.owner_id = "cleopatra"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "attack"
	c.archetype = TranslationServer.translate("card.cleopatra.venom_needle.archetype")
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 80; ea.base_value = 80; ea.target = "SINGLE"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.APPLY_STATUS
	eb.status_type = "poison"; eb.value = 3; eb.base_value = 3; eb.target = "SINGLE"
	c.effects = [ea, eb]; return c

static func _royal_guard() -> Resource:
	# 왕실 방어 — COMMON, 1코, SKILL, 저주: BLOCK 80
	var c := CardRes.new()
	c.card_name = TranslationServer.translate("card.cleopatra.royal_guard.name"); c.owner_id = "cleopatra"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "idle"
	c.archetype = TranslationServer.translate("card.cleopatra.royal_guard.archetype")
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.BLOCK
	e.value = 80; e.base_value = 80
	c.effects = [e]; return c

# ─────────────────────────────────────────
# v1 풀 카드 13장
# ─────────────────────────────────────────

static func _poison_seed() -> Resource:
	# 독의 씨앗 — COMMON, 1코, ATTACK, 독살: DMG 80 + POISON 2 ALL
	var c := CardRes.new()
	c.card_name = TranslationServer.translate("card.cleopatra.poison_seed.name"); c.owner_id = "cleopatra"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "attack"
	c.archetype = TranslationServer.translate("card.cleopatra.poison_seed.archetype")
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 80; ea.base_value = 80; ea.target = "SINGLE"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.APPLY_STATUS
	eb.status_type = "poison"; eb.value = 2; eb.base_value = 2; eb.target = "ALL"
	c.effects = [ea, eb]; return c

static func _isis_blessing() -> Resource:
	# 이시스의 가호 — COMMON, 0코, SKILL, 조종: DRAW 1 + ENERGY+1
	var c := CardRes.new()
	c.card_name = TranslationServer.translate("card.cleopatra.isis_blessing.name"); c.owner_id = "cleopatra"
	c.cost = 0; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "idle"
	c.archetype = TranslationServer.translate("card.cleopatra.isis_blessing.archetype")
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DRAW
	ea.value = 1; ea.base_value = 1
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.ENERGY
	eb.value = 1; eb.base_value = 1
	c.effects = [ea, eb]; return c

static func _asp_fang() -> Resource:
	# 아스프의 독니 — UNCOMMON, 1코, ATTACK, 독살: POISON 8
	var c := CardRes.new()
	c.card_name = TranslationServer.translate("card.cleopatra.asp_fang.name"); c.owner_id = "cleopatra"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "attack"
	c.archetype = TranslationServer.translate("card.cleopatra.asp_fang.archetype")
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.APPLY_STATUS
	e.status_type = "poison"; e.value = 8; e.base_value = 8; e.target = "SINGLE"
	c.effects = [e]; return c

static func _desert_poison_dance() -> Resource:
	# 사막의 독무 — UNCOMMON, 1코, ATTACK, 독살: DMG 60 ALL + POISON 3 ALL
	var c := CardRes.new()
	c.card_name = TranslationServer.translate("card.cleopatra.desert_poison_dance.name"); c.owner_id = "cleopatra"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "attack"
	c.archetype = TranslationServer.translate("card.cleopatra.desert_poison_dance.archetype")
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 60; ea.base_value = 60; ea.target = "ALL"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.APPLY_STATUS
	eb.status_type = "poison"; eb.value = 3; eb.base_value = 3; eb.target = "ALL"
	c.effects = [ea, eb]; return c

static func _cursed_gaze() -> Resource:
	# 저주의 시선 — UNCOMMON, 1코, SKILL, 저주: WEAK 2 + VULNERABLE 2
	var c := CardRes.new()
	c.card_name = TranslationServer.translate("card.cleopatra.cursed_gaze.name"); c.owner_id = "cleopatra"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	c.archetype = TranslationServer.translate("card.cleopatra.cursed_gaze.archetype")
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.APPLY_STATUS
	ea.status_type = "weak"; ea.value = 2; ea.base_value = 2; ea.target = "SINGLE"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.APPLY_STATUS
	eb.status_type = "vulnerable"; eb.value = 2; eb.base_value = 2; eb.target = "SINGLE"
	c.effects = [ea, eb]; return c

static func _temptation() -> Resource:
	# 유혹 — UNCOMMON, 1코, SKILL, 조종: CHARM 1 (SINGLE)
	var c := CardRes.new()
	c.card_name = TranslationServer.translate("card.cleopatra.temptation.name"); c.owner_id = "cleopatra"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	c.archetype = TranslationServer.translate("card.cleopatra.temptation.archetype")
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.CHARM
	e.value = 1; e.base_value = 1; e.target = "SINGLE"
	c.effects = [e]; return c

static func _nile_mist() -> Resource:
	# 나일의 안개 — RARE, 2코, ATTACK, 독살: POISON 5 ALL
	var c := CardRes.new()
	c.card_name = TranslationServer.translate("card.cleopatra.nile_mist.name"); c.owner_id = "cleopatra"
	c.cost = 2; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "attack"
	c.archetype = TranslationServer.translate("card.cleopatra.nile_mist.archetype")
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.APPLY_STATUS
	e.status_type = "poison"; e.value = 5; e.base_value = 5; e.target = "ALL"
	c.effects = [e]; return c

static func _serpent_grasp() -> Resource:
	# 독사의 마수 — RARE, 1코, ATTACK, 독살: 독 있으면 DMG 160 / 없으면 DMG 80
	var c := CardRes.new()
	c.card_name = TranslationServer.translate("card.cleopatra.serpent_grasp.name"); c.owner_id = "cleopatra"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "attack"
	c.archetype = TranslationServer.translate("card.cleopatra.serpent_grasp.archetype")
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.CONDITIONAL_DMG
	e.value = 80; e.base_value = 80
	e.bonus_value = 160; e.base_bonus_value = 160
	e.status_type = "has_poison"; e.target = "SINGLE"
	c.effects = [e]; return c

static func _pharaoh_poison() -> Resource:
	# 파라오의 독 — RARE, 2코, ATTACK, 저주: DMG 120 + POISON 5 + VULNERABLE 1
	var c := CardRes.new()
	c.card_name = TranslationServer.translate("card.cleopatra.pharaoh_poison.name"); c.owner_id = "cleopatra"
	c.cost = 2; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "attack"
	c.archetype = TranslationServer.translate("card.cleopatra.pharaoh_poison.archetype")
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 120; ea.base_value = 120; ea.target = "SINGLE"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.APPLY_STATUS
	eb.status_type = "poison"; eb.value = 5; eb.base_value = 5; eb.target = "SINGLE"
	var ec := EffRes.new()
	ec.effect_type = EffRes.EffectType.APPLY_STATUS
	ec.status_type = "vulnerable"; ec.value = 1; ec.base_value = 1; ec.target = "SINGLE"
	c.effects = [ea, eb, ec]; return c

static func _ramesses_shield() -> Resource:
	# 람세스의 방패 — RARE, 1코, SKILL, 저주: BLOCK 130
	var c := CardRes.new()
	c.card_name = TranslationServer.translate("card.cleopatra.ramesses_shield.name"); c.owner_id = "cleopatra"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	c.archetype = TranslationServer.translate("card.cleopatra.ramesses_shield.archetype")
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.BLOCK
	e.value = 130; e.base_value = 130
	c.effects = [e]; return c

static func _nile_fury() -> Resource:
	# 나일의 분노 — LEGENDARY, 1코, ATTACK, 독살: POISON_BURST (×3 = 300 단위)
	var c := CardRes.new()
	c.card_name = TranslationServer.translate("card.cleopatra.nile_fury.name"); c.owner_id = "cleopatra"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.LEGENDARY; c.play_animation = "attack"
	c.archetype = TranslationServer.translate("card.cleopatra.nile_fury.archetype")
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.POISON_BURST
	e.value = 300; e.base_value = 300; e.target = "SINGLE"
	c.effects = [e]; return c

static func _pharaoh_decree() -> Resource:
	# 파라오의 명 — LEGENDARY, 1코, SKILL, 조종: BLOCK 110 + DRAW 2
	var c := CardRes.new()
	c.card_name = TranslationServer.translate("card.cleopatra.pharaoh_decree.name"); c.owner_id = "cleopatra"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.LEGENDARY; c.play_animation = "idle"
	c.archetype = TranslationServer.translate("card.cleopatra.pharaoh_decree.archetype")
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.BLOCK
	ea.value = 110; ea.base_value = 110
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.DRAW
	eb.value = 2; eb.base_value = 2
	c.effects = [ea, eb]; return c

static func _cleopatras_kiss() -> Resource:
	# 클레오파트라의 입맞춤 — DIVINE, 2코, SKILL, 조종: CHARM 1 ALL + POISON 3 ALL (0강)
	var c := CardRes.new()
	c.card_name = TranslationServer.translate("card.cleopatra.cleopatras_kiss.name"); c.owner_id = "cleopatra"
	c.cost = 2; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.DIVINE; c.play_animation = "idle"
	c.archetype = TranslationServer.translate("card.cleopatra.cleopatras_kiss.archetype")
	var e1 := EffRes.new()
	e1.effect_type = EffRes.EffectType.CHARM
	e1.value = 1; e1.base_value = 1; e1.target = "ALL"
	var e2 := EffRes.new()
	e2.effect_type = EffRes.EffectType.APPLY_STATUS
	e2.status_type = "poison"; e2.value = 3; e2.base_value = 3; e2.target = "ALL"
	c.effects = [e1, e2]; return c

# ─────────────────────────────────────────
# v2 추가 카드 25장
# ─────────────────────────────────────────

static func _poison_fog_spray() -> Resource:
	# 독안개 살포 — COMMON, 1코, ATTACK, 독살: DMG 60 + POISON 2 ALL
	var c := CardRes.new()
	c.card_name = TranslationServer.translate("card.cleopatra.poison_fog_spray.name"); c.owner_id = "cleopatra"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "attack"
	c.archetype = TranslationServer.translate("card.cleopatra.poison_fog_spray.archetype")
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 60; ea.base_value = 60; ea.target = "SINGLE"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.APPLY_STATUS
	eb.status_type = "poison"; eb.value = 2; eb.base_value = 2; eb.target = "ALL"
	c.effects = [ea, eb]; return c

static func _wax_trap() -> Resource:
	# 밀납의 덫 — COMMON, 0코, SKILL, 조종: COST_NEXT -1
	var c := CardRes.new()
	c.card_name = TranslationServer.translate("card.cleopatra.wax_trap.name"); c.owner_id = "cleopatra"
	c.cost = 0; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "idle"
	c.archetype = TranslationServer.translate("card.cleopatra.wax_trap.archetype")
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.COST_NEXT
	e.value = 1; e.base_value = 1
	c.effects = [e]; return c

static func _sandstorm() -> Resource:
	# 모래 폭풍 — COMMON, 1코, SKILL, 저주: WEAK 1 ALL
	var c := CardRes.new()
	c.card_name = TranslationServer.translate("card.cleopatra.sandstorm.name"); c.owner_id = "cleopatra"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "idle"
	c.archetype = TranslationServer.translate("card.cleopatra.sandstorm.archetype")
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.APPLY_STATUS
	e.status_type = "weak"; e.value = 1; e.base_value = 1; e.target = "ALL"
	c.effects = [e]; return c

static func _nile_blessing() -> Resource:
	# 나일의 축복 — COMMON, 0코, SKILL, 조종: DRAW 2
	var c := CardRes.new()
	c.card_name = TranslationServer.translate("card.cleopatra.nile_blessing.name"); c.owner_id = "cleopatra"
	c.cost = 0; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "idle"
	c.archetype = TranslationServer.translate("card.cleopatra.nile_blessing.archetype")
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.DRAW
	e.value = 2; e.base_value = 2
	c.effects = [e]; return c

static func _snake_gaze() -> Resource:
	# 뱀의 눈빛 — COMMON, 1코, SKILL, 저주: VULNERABLE 2
	var c := CardRes.new()
	c.card_name = TranslationServer.translate("card.cleopatra.snake_gaze.name"); c.owner_id = "cleopatra"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "idle"
	c.archetype = TranslationServer.translate("card.cleopatra.snake_gaze.archetype")
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.APPLY_STATUS
	e.status_type = "vulnerable"; e.value = 2; e.base_value = 2; e.target = "SINGLE"
	c.effects = [e]; return c

static func _double_fang() -> Resource:
	# 이중 독니 — COMMON, 2코, ATTACK, 독살: DMG 80 + POISON 8 (2회 적용 합산)
	var c := CardRes.new()
	c.card_name = TranslationServer.translate("card.cleopatra.double_fang.name"); c.owner_id = "cleopatra"
	c.cost = 2; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "attack"
	c.archetype = TranslationServer.translate("card.cleopatra.double_fang.archetype")
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 80; ea.base_value = 80; ea.target = "SINGLE"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.APPLY_STATUS
	eb.status_type = "poison"; eb.value = 8; eb.base_value = 8; eb.target = "SINGLE"
	c.effects = [ea, eb]; return c

static func _tempting_eye() -> Resource:
	# 유혹의 눈길 — UNCOMMON, 1코, SKILL, 조종: CHARM 1 + COST_NEXT -1
	var c := CardRes.new()
	c.card_name = TranslationServer.translate("card.cleopatra.tempting_eye.name"); c.owner_id = "cleopatra"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	c.archetype = TranslationServer.translate("card.cleopatra.tempting_eye.archetype")
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.CHARM
	ea.value = 1; ea.base_value = 1; ea.target = "SINGLE"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.COST_NEXT
	eb.value = 1; eb.base_value = 1
	c.effects = [ea, eb]; return c

static func _poison_feast() -> Resource:
	# 독의 향연 — UNCOMMON, 1코, ATTACK, 독살: DMG 100 + POISON 3
	var c := CardRes.new()
	c.card_name = TranslationServer.translate("card.cleopatra.poison_feast.name"); c.owner_id = "cleopatra"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "attack"
	c.archetype = TranslationServer.translate("card.cleopatra.poison_feast.archetype")
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 100; ea.base_value = 100; ea.target = "SINGLE"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.APPLY_STATUS
	eb.status_type = "poison"; eb.value = 3; eb.base_value = 3; eb.target = "SINGLE"
	c.effects = [ea, eb]; return c

static func _pharaoh_curse() -> Resource:
	# 파라오의 저주 — UNCOMMON, 1코, SKILL, 저주: WEAK 2 + POISON 2
	var c := CardRes.new()
	c.card_name = TranslationServer.translate("card.cleopatra.pharaoh_curse.name"); c.owner_id = "cleopatra"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	c.archetype = TranslationServer.translate("card.cleopatra.pharaoh_curse.archetype")
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.APPLY_STATUS
	ea.status_type = "weak"; ea.value = 2; ea.base_value = 2; ea.target = "SINGLE"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.APPLY_STATUS
	eb.status_type = "poison"; eb.value = 2; eb.base_value = 2; eb.target = "SINGLE"
	c.effects = [ea, eb]; return c

static func _nile_flow() -> Resource:
	# 나일의 흐름 — UNCOMMON, 0코, SKILL, 조종: ENERGY+1 + DRAW 1
	var c := CardRes.new()
	c.card_name = TranslationServer.translate("card.cleopatra.nile_flow.name"); c.owner_id = "cleopatra"
	c.cost = 0; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	c.archetype = TranslationServer.translate("card.cleopatra.nile_flow.archetype")
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.ENERGY
	ea.value = 1; ea.base_value = 1
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.DRAW
	eb.value = 1; eb.base_value = 1
	c.effects = [ea, eb]; return c

static func _snake_poison_dance() -> Resource:
	# 뱀의 독무 — UNCOMMON, 2코, ATTACK, 독살: POISON 6 ALL
	var c := CardRes.new()
	c.card_name = TranslationServer.translate("card.cleopatra.snake_poison_dance.name"); c.owner_id = "cleopatra"
	c.cost = 2; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "attack"
	c.archetype = TranslationServer.translate("card.cleopatra.snake_poison_dance.archetype")
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.APPLY_STATUS
	e.status_type = "poison"; e.value = 6; e.base_value = 6; e.target = "ALL"
	c.effects = [e]; return c

static func _charming_language() -> Resource:
	# 매혹의 언어 — UNCOMMON, 1코, SKILL, 조종: CHARM 1 + DRAW 1
	var c := CardRes.new()
	c.card_name = TranslationServer.translate("card.cleopatra.charming_language.name"); c.owner_id = "cleopatra"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	c.archetype = TranslationServer.translate("card.cleopatra.charming_language.archetype")
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.CHARM
	ea.value = 1; ea.base_value = 1; ea.target = "SINGLE"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.DRAW
	eb.value = 1; eb.base_value = 1
	c.effects = [ea, eb]; return c

static func _desert_recipe() -> Resource:
	# 사막의 약법 — UNCOMMON, 1코, SKILL, 저주: VULNERABLE 2 + DRAW 1
	var c := CardRes.new()
	c.card_name = TranslationServer.translate("card.cleopatra.desert_recipe.name"); c.owner_id = "cleopatra"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	c.archetype = TranslationServer.translate("card.cleopatra.desert_recipe.archetype")
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.APPLY_STATUS
	ea.status_type = "vulnerable"; ea.value = 2; ea.base_value = 2; ea.target = "SINGLE"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.DRAW
	eb.value = 1; eb.base_value = 1
	c.effects = [ea, eb]; return c

static func _poison_judgment() -> Resource:
	# 독의 심판 — UNCOMMON, 2코, ATTACK, 독살: 독 5 이상 DMG 140 / 미만 DMG 70
	var c := CardRes.new()
	c.card_name = TranslationServer.translate("card.cleopatra.poison_judgment.name"); c.owner_id = "cleopatra"
	c.cost = 2; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "attack"
	c.archetype = TranslationServer.translate("card.cleopatra.poison_judgment.archetype")
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.CONDITIONAL_DMG
	e.value = 70; e.base_value = 70
	e.bonus_value = 140; e.base_bonus_value = 140
	e.status_type = "has_poison_5"; e.target = "SINGLE"
	c.effects = [e]; return c

static func _isis_fury() -> Resource:
	# 이시스의 분노 — RARE, 2코, ATTACK, 저주: DMG 130 + WEAK 2 + VULNERABLE 2
	var c := CardRes.new()
	c.card_name = TranslationServer.translate("card.cleopatra.isis_fury.name"); c.owner_id = "cleopatra"
	c.cost = 2; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "attack"
	c.archetype = TranslationServer.translate("card.cleopatra.isis_fury.archetype")
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 130; ea.base_value = 130; ea.target = "SINGLE"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.APPLY_STATUS
	eb.status_type = "weak"; eb.value = 2; eb.base_value = 2; eb.target = "SINGLE"
	var ec := EffRes.new()
	ec.effect_type = EffRes.EffectType.APPLY_STATUS
	ec.status_type = "vulnerable"; ec.value = 2; ec.base_value = 2; ec.target = "SINGLE"
	c.effects = [ea, eb, ec]; return c

static func _poison_ritual() -> Resource:
	# 독살의 의식 — RARE, 1코, SKILL, 독살: POISON 4 ALL + POISON_BURST 계수 보너스
	var c := CardRes.new()
	c.card_name = TranslationServer.translate("card.cleopatra.poison_ritual.name"); c.owner_id = "cleopatra"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	c.archetype = TranslationServer.translate("card.cleopatra.poison_ritual.archetype")
	var e1 := EffRes.new()
	e1.effect_type = EffRes.EffectType.APPLY_STATUS
	e1.status_type = "poison"; e1.value = 4; e1.base_value = 4; e1.target = "ALL"
	var e2 := EffRes.new()
	e2.effect_type = EffRes.EffectType.POISON_BURST
	e2.value = 50; e2.base_value = 50  # +0.5 배율 = 50 (100 단위)
	e2.status_type = "burst_bonus"     # 영구 보너스 마커
	e2.target = "ALL"
	c.effects = [e1, e2]; return c

static func _queens_embrace() -> Resource:
	# 여왕의 포옹 — RARE, 2코, SKILL, 조종: CHARM 1 ALL + DRAW 2
	var c := CardRes.new()
	c.card_name = TranslationServer.translate("card.cleopatra.queens_embrace.name"); c.owner_id = "cleopatra"
	c.cost = 2; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	c.archetype = TranslationServer.translate("card.cleopatra.queens_embrace.archetype")
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.CHARM
	ea.value = 1; ea.base_value = 1; ea.target = "ALL"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.DRAW
	eb.value = 2; eb.base_value = 2
	c.effects = [ea, eb]; return c

static func _curse_brand() -> Resource:
	# 저주의 낙인 — RARE, 1코, SKILL, 저주: WEAK 3 + VULNERABLE 3 + POISON 2
	var c := CardRes.new()
	c.card_name = TranslationServer.translate("card.cleopatra.curse_brand.name"); c.owner_id = "cleopatra"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	c.archetype = TranslationServer.translate("card.cleopatra.curse_brand.archetype")
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.APPLY_STATUS
	ea.status_type = "weak"; ea.value = 3; ea.base_value = 3; ea.target = "SINGLE"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.APPLY_STATUS
	eb.status_type = "vulnerable"; eb.value = 3; eb.base_value = 3; eb.target = "SINGLE"
	var ec := EffRes.new()
	ec.effect_type = EffRes.EffectType.APPLY_STATUS
	ec.status_type = "poison"; ec.value = 2; ec.base_value = 2; ec.target = "SINGLE"
	c.effects = [ea, eb, ec]; return c

static func _nile_doom() -> Resource:
	# 나일의 파멸 — RARE, 2코, ATTACK, 독살: 독 10 이상 DMG 200 / 미만 DMG 100
	var c := CardRes.new()
	c.card_name = TranslationServer.translate("card.cleopatra.nile_doom.name"); c.owner_id = "cleopatra"
	c.cost = 2; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "attack"
	c.archetype = TranslationServer.translate("card.cleopatra.nile_doom.archetype")
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.CONDITIONAL_DMG
	e.value = 100; e.base_value = 100
	e.bonus_value = 200; e.base_bonus_value = 200
	e.status_type = "has_poison_10"; e.target = "SINGLE"
	c.effects = [e]; return c

static func _charming_assault() -> Resource:
	# 매혹의 강습 — RARE, 1코, ATTACK, 조종: CHARM 1 + DMG 100
	var c := CardRes.new()
	c.card_name = TranslationServer.translate("card.cleopatra.charming_assault.name"); c.owner_id = "cleopatra"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "attack"
	c.archetype = TranslationServer.translate("card.cleopatra.charming_assault.archetype")
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.CHARM
	ea.value = 1; ea.base_value = 1; ea.target = "SINGLE"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.DAMAGE
	eb.value = 100; eb.base_value = 100; eb.target = "SINGLE"
	c.effects = [ea, eb]; return c

static func _pharaoh_fury() -> Resource:
	# 파라오의 분노 — RARE, 3코, ATTACK, 저주: DMG 150 ALL + WEAK 2 ALL
	var c := CardRes.new()
	c.card_name = TranslationServer.translate("card.cleopatra.pharaoh_fury.name"); c.owner_id = "cleopatra"
	c.cost = 3; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "attack"
	c.archetype = TranslationServer.translate("card.cleopatra.pharaoh_fury.archetype")
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 150; ea.base_value = 150; ea.target = "ALL"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.APPLY_STATUS
	eb.status_type = "weak"; eb.value = 2; eb.base_value = 2; eb.target = "ALL"
	c.effects = [ea, eb]; return c

static func _curse_crossroads() -> Resource:
	# 저주의 교차로 — RARE, 2코, SKILL, 저주: WEAK 2 + VULNERABLE 2 ALL + POISON 3 ALL
	var c := CardRes.new()
	c.card_name = TranslationServer.translate("card.cleopatra.curse_crossroads.name"); c.owner_id = "cleopatra"
	c.cost = 2; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	c.archetype = TranslationServer.translate("card.cleopatra.curse_crossroads.archetype")
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.APPLY_STATUS
	ea.status_type = "weak"; ea.value = 2; ea.base_value = 2; ea.target = "ALL"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.APPLY_STATUS
	eb.status_type = "vulnerable"; eb.value = 2; eb.base_value = 2; eb.target = "ALL"
	var ec := EffRes.new()
	ec.effect_type = EffRes.EffectType.APPLY_STATUS
	ec.status_type = "poison"; ec.value = 3; ec.base_value = 3; ec.target = "ALL"
	c.effects = [ea, eb, ec]; return c

static func _poison_throne() -> Resource:
	# 독의 왕좌 — LEGENDARY, 2코, POWER, 독살: 매 턴 시작 시 모든 독 스택 +1
	var c := CardRes.new()
	c.card_name = TranslationServer.translate("card.cleopatra.poison_throne.name"); c.owner_id = "cleopatra"
	c.cost = 2; c.card_type = CardRes.CardType.POWER
	c.rarity = CardRes.Rarity.LEGENDARY; c.play_animation = "idle"
	c.archetype = TranslationServer.translate("card.cleopatra.poison_throne.archetype")
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.APPLY_STATUS
	e.status_type = "poison_per_turn"  # battle_manager 턴 시작 시 처리
	e.value = 1; e.base_value = 1; e.target = "ALL"
	c.effects = [e]; return c

static func _isis_judgment() -> Resource:
	# 이시스의 심판 — LEGENDARY, 2코, ATTACK, 저주: 디버프 3종 이상 시 DMG 180
	var c := CardRes.new()
	c.card_name = TranslationServer.translate("card.cleopatra.isis_judgment.name"); c.owner_id = "cleopatra"
	c.cost = 2; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.LEGENDARY; c.play_animation = "attack"
	c.archetype = TranslationServer.translate("card.cleopatra.isis_judgment.archetype")
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.CONDITIONAL_DMG
	e.value = 0; e.base_value = 0
	e.bonus_value = 180; e.base_bonus_value = 180
	e.status_type = "has_debuffs_3"; e.target = "SINGLE"
	c.effects = [e]; return c

static func _sekhmet_curse() -> Resource:
	# 세케메트의 저주 — DIVINE, 3코, SKILL, 저주: WEAK 3 ALL + VULNERABLE 3 ALL + POISON 4 ALL (0강)
	var c := CardRes.new()
	c.card_name = TranslationServer.translate("card.cleopatra.sekhmet_curse.name"); c.owner_id = "cleopatra"
	c.cost = 3; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.DIVINE; c.play_animation = "idle"
	c.archetype = TranslationServer.translate("card.cleopatra.sekhmet_curse.archetype")
	var e1 := EffRes.new()
	e1.effect_type = EffRes.EffectType.APPLY_STATUS
	e1.status_type = "weak"; e1.value = 3; e1.base_value = 3; e1.target = "ALL"
	var e2 := EffRes.new()
	e2.effect_type = EffRes.EffectType.APPLY_STATUS
	e2.status_type = "vulnerable"; e2.value = 3; e2.base_value = 3; e2.target = "ALL"
	var e3 := EffRes.new()
	e3.effect_type = EffRes.EffectType.APPLY_STATUS
	e3.status_type = "poison"; e3.value = 4; e3.base_value = 4; e3.target = "ALL"
	c.effects = [e1, e2, e3]; return c
