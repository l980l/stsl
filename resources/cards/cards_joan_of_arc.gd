# resources/cards/cards_joan_of_arc.gd
# 잔다르크 카드 15장 — HP 1000 스케일 기준
# 아키타입: 신성(HEAL_ALL/버프) / 부활(REVIVE) / 순교(SACRIFICE_HP→팀 이득)
const CardRes = preload("res://resources/card_resource.gd")
const EffRes  = preload("res://resources/effect_resource.gd")

static func starter_deck() -> Array:
	var cards: Array = []
	for _i in range(3):
		cards.append(_strike())
	for _i in range(2):
		cards.append(_defend())
	return cards

static func pool() -> Array:
	return [
		_holy_touch(), _blessing_of_light(), _hymn(),
		_purifying_flame(), _self_sacrifice(), _orleans_charge(),
		_miracle_revive(), _divine_protection(), _holy_fury(),
		_martyrs_will(), _knights_oath(), _flag_of_orleans(),
		_saints_flame(),
	]

# ─────────────────────────────────────────
# 시작덱 (2종)
# ─────────────────────────────────────────

static func _strike() -> Resource:
	var c := CardRes.new()
	c.card_name = "스트라이크"; c.owner_id = "joan_of_arc"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "attack"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.DAMAGE
	e.value = 100; e.base_value = 100; e.target = "SINGLE"
	c.effects = [e]; return c

static func _defend() -> Resource:
	var c := CardRes.new()
	c.card_name = "디펜드"; c.owner_id = "joan_of_arc"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "idle"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.BLOCK
	e.value = 80; e.base_value = 80; e.target = "SELF"
	c.effects = [e]; return c

# ─────────────────────────────────────────
# 풀 카드 13장
# ─────────────────────────────────────────

static func _holy_touch() -> Resource:
	# 성녀의 손길 — COMMON, 1코, 기술, 신성: 자신 HEAL 80
	var c := CardRes.new()
	c.card_name = "성녀의 손길"; c.owner_id = "joan_of_arc"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "idle"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.HEAL
	e.value = 80; e.base_value = 80; e.target = "SELF"
	c.effects = [e]; return c

static func _blessing_of_light() -> Resource:
	# 축복의 빛 — COMMON, 0코, 기술, 신성: BLOCK 50 (자신)
	var c := CardRes.new()
	c.card_name = "축복의 빛"; c.owner_id = "joan_of_arc"
	c.cost = 0; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "idle"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.BLOCK
	e.value = 50; e.base_value = 50; e.target = "SELF"
	c.effects = [e]; return c

static func _hymn() -> Resource:
	# 성가 — UNCOMMON, 1코, 기술, 신성: HEAL_ALL 60
	var c := CardRes.new()
	c.card_name = "성가"; c.owner_id = "joan_of_arc"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.HEAL_ALL
	e.value = 60; e.base_value = 60
	c.effects = [e]; return c

static func _purifying_flame() -> Resource:
	# 정화의 불꽃 — UNCOMMON, 1코, 기술, 신성: BLOCK_ALL 60
	var c := CardRes.new()
	c.card_name = "정화의 불꽃"; c.owner_id = "joan_of_arc"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.BLOCK_ALL
	e.value = 60; e.base_value = 60
	c.effects = [e]; return c

static func _self_sacrifice() -> Resource:
	# 자기희생 — UNCOMMON, 0코, 기술, 순교: 자신 HP -80, HEAL_ALL 120
	var c := CardRes.new()
	c.card_name = "자기희생"; c.owner_id = "joan_of_arc"
	c.cost = 0; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.SACRIFICE_HP
	ea.value = 80; ea.base_value = 80
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.HEAL_ALL
	eb.value = 120; eb.base_value = 120
	c.effects = [ea, eb]; return c

static func _orleans_charge() -> Resource:
	# 오를레앙의 돌격 — UNCOMMON, 1코, 공격, 신성: DMG 120
	var c := CardRes.new()
	c.card_name = "오를레앙의 돌격"; c.owner_id = "joan_of_arc"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "attack"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.DAMAGE
	e.value = 120; e.base_value = 120; e.target = "SINGLE"
	c.effects = [e]; return c

static func _miracle_revive() -> Resource:
	# 기적의 부활 — RARE, 2코, 기술, 부활: 사망한 아군 HP 25%로 부활 (REVIVE)
	var c := CardRes.new()
	c.card_name = "기적의 부활"; c.owner_id = "joan_of_arc"
	c.cost = 2; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.REVIVE
	e.value = 25; e.base_value = 25
	c.effects = [e]; return c

static func _divine_protection() -> Resource:
	# 신의 가호 — RARE, 1코, 기술, 신성: HEAL_ALL 80 + BLOCK_ALL 50
	var c := CardRes.new()
	c.card_name = "신의 가호"; c.owner_id = "joan_of_arc"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.HEAL_ALL
	ea.value = 80; ea.base_value = 80
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.BLOCK_ALL
	eb.value = 50; eb.base_value = 50
	c.effects = [ea, eb]; return c

static func _holy_fury() -> Resource:
	# 성스러운 분노 — RARE, 2코, 공격, 신성: DMG 100 ALL
	var c := CardRes.new()
	c.card_name = "성스러운 분노"; c.owner_id = "joan_of_arc"
	c.cost = 2; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "attack"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.DAMAGE
	e.value = 100; e.base_value = 100; e.target = "ALL"
	c.effects = [e]; return c

static func _martyrs_will() -> Resource:
	# 순교의 의지 — RARE, 1코, 기술, 순교: 자신 HP -150, HEAL_ALL 200
	var c := CardRes.new()
	c.card_name = "순교의 의지"; c.owner_id = "joan_of_arc"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.SACRIFICE_HP
	ea.value = 150; ea.base_value = 150
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.HEAL_ALL
	eb.value = 200; eb.base_value = 200
	c.effects = [ea, eb]; return c

static func _knights_oath() -> Resource:
	# 기사단의 맹세 — RARE, 1코, 기술, 부활: HEAL 200 자신
	var c := CardRes.new()
	c.card_name = "기사단의 맹세"; c.owner_id = "joan_of_arc"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.HEAL
	e.value = 200; e.base_value = 200; e.target = "SELF"
	c.effects = [e]; return c

static func _flag_of_orleans() -> Resource:
	# 신국의 깃발 — LEGENDARY, 2코, 기술, 신성: HEAL_ALL 100 + BLOCK_ALL 80
	var c := CardRes.new()
	c.card_name = "신국의 깃발"; c.owner_id = "joan_of_arc"
	c.cost = 2; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.LEGENDARY; c.play_animation = "idle"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.HEAL_ALL
	ea.value = 100; ea.base_value = 100
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.BLOCK_ALL
	eb.value = 80; eb.base_value = 80
	c.effects = [ea, eb]; return c

static func _saints_flame() -> Resource:
	# 성녀의 화염 — DIVINE, 1코, 공격, 순교: 자신 HP -100 + DMG 250 ALL
	var c := CardRes.new()
	c.card_name = "성녀의 화염"; c.owner_id = "joan_of_arc"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.DIVINE; c.play_animation = "attack"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.SACRIFICE_HP
	ea.value = 100; ea.base_value = 100
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.DAMAGE
	eb.value = 250; eb.base_value = 250; eb.target = "ALL"
	c.effects = [ea, eb]; return c
