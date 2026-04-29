# resources/cards/cards_joan_of_arc.gd
# 잔다르크 카드 40장 — HP 1000 스케일 기준 (v1 15장 + v2 25장)
# 아키타입: 신성(HEAL_ALL/정화/방어) / 부활(REVIVE/위기 대응) / 순교(SACRIFICE_HP→팀 이득)
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
		# v1 13장
		_holy_touch(), _blessing_of_light(), _hymn(),
		_purifying_flame(), _self_sacrifice(), _orleans_charge(),
		_miracle_revive(), _divine_protection(), _holy_fury(),
		_martyrs_will(), _knights_oath(), _flag_of_orleans(),
		_saints_flame(),
		# v2 25장
		_holy_light(), _communion(), _revive_spark(), _divine_providence(), _small_sacrifice(),
		_sacrifice_cry(), _angel_wings(), _second_chance(), _revive_scroll(), _light_of_hope(),
		_holy_charge(), _blade_of_justice(), _martyrdom_steps(), _altar_flame(), _holy_rage(),
		_holy_purification(), _knights_guard(), _martyrs_legacy(), _revive_ritual(), _miracle_chain(),
		_last_shield(), _purifying_sacrifice(), _saints_vow(), _joan_return(), _holy_war(),
		_choir(),
		# M6-5c 신규
		_martyr_wrath(), _dead_blessing(),
	]

# ─────────────────────────────────────────
# 시작덱 (2종)
# ─────────────────────────────────────────

static func _strike() -> Resource:
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.strike.name"; c.owner_id = "joan_of_arc"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "attack"
	c.archetype = "card.joan_of_arc.strike.archetype"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.DAMAGE
	e.value = 100; e.base_value = 100; e.target = "SINGLE"
	e.damage_type = "divine"
	c.effects = [e]; return c

static func _defend() -> Resource:
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.defend.name"; c.owner_id = "joan_of_arc"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "idle"
	c.archetype = "card.joan_of_arc.defend.archetype"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.BLOCK
	e.value = 80; e.base_value = 80; e.target = "SELF"
	c.effects = [e]; return c

# ─────────────────────────────────────────
# v1 풀 카드 13장
# ─────────────────────────────────────────

static func _holy_touch() -> Resource:
	# 성녀의 손길 — COMMON, 1코, 기술, 신성: 자신 HEAL 80
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.holy_touch.name"; c.owner_id = "joan_of_arc"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "idle"
	c.archetype = "card.joan_of_arc.holy_touch.archetype"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.HEAL
	e.value = 80; e.base_value = 80; e.target = "SELF"
	c.effects = [e]; return c

static func _blessing_of_light() -> Resource:
	# 축복의 빛 — COMMON, 0코, 기술, 신성: BLOCK 50 (자신)
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.blessing_of_light.name"; c.owner_id = "joan_of_arc"
	c.cost = 0; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "idle"
	c.archetype = "card.joan_of_arc.blessing_of_light.archetype"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.BLOCK
	e.value = 50; e.base_value = 50; e.target = "SELF"
	c.effects = [e]; return c

static func _hymn() -> Resource:
	# 성가 — UNCOMMON, 1코, 기술, 신성: HEAL_ALL 60
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.hymn.name"; c.owner_id = "joan_of_arc"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	c.archetype = "card.joan_of_arc.hymn.archetype"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.HEAL_ALL
	e.value = 60; e.base_value = 60
	c.effects = [e]; return c

static func _purifying_flame() -> Resource:
	# 정화의 불꽃 — UNCOMMON, 1코, 기술, 신성: BLOCK_ALL 60
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.purifying_flame.name"; c.owner_id = "joan_of_arc"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	c.archetype = "card.joan_of_arc.purifying_flame.archetype"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.BLOCK_ALL
	e.value = 60; e.base_value = 60
	c.effects = [e]; return c

static func _self_sacrifice() -> Resource:
	# 자기희생 — UNCOMMON, 0코, 기술, 순교: 자신 HP -80, HEAL_ALL 120
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.self_sacrifice.name"; c.owner_id = "joan_of_arc"
	c.cost = 0; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	c.archetype = "card.joan_of_arc.self_sacrifice.archetype"
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
	c.card_name = "card.joan_of_arc.orleans_charge.name"; c.owner_id = "joan_of_arc"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "attack"
	c.archetype = "card.joan_of_arc.orleans_charge.archetype"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.DAMAGE
	e.value = 120; e.base_value = 120; e.target = "SINGLE"
	e.damage_type = "divine"
	c.effects = [e]; return c

static func _miracle_revive() -> Resource:
	# 기적의 부활 — RARE, 2코, 기술, 부활: 사망한 아군 HP 25%로 부활
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.miracle_revive.name"; c.owner_id = "joan_of_arc"
	c.cost = 2; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	c.archetype = "card.joan_of_arc.miracle_revive.archetype"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.REVIVE
	e.value = 25; e.base_value = 25
	c.effects = [e]; return c

static func _divine_protection() -> Resource:
	# 신의 가호 — RARE, 1코, 기술, 신성: HEAL_ALL 80 + BLOCK_ALL 50
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.divine_protection.name"; c.owner_id = "joan_of_arc"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	c.archetype = "card.joan_of_arc.divine_protection.archetype"
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
	c.card_name = "card.joan_of_arc.holy_fury.name"; c.owner_id = "joan_of_arc"
	c.cost = 2; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "attack"
	c.archetype = "card.joan_of_arc.holy_fury.archetype"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.DAMAGE
	e.value = 100; e.base_value = 100; e.target = "ALL"
	e.damage_type = "divine"
	c.effects = [e]; return c

static func _martyrs_will() -> Resource:
	# 순교의 의지 — RARE, 1코, 기술, 순교: 자신 HP -150, HEAL_ALL 200
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.martyrs_will.name"; c.owner_id = "joan_of_arc"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	c.archetype = "card.joan_of_arc.martyrs_will.archetype"
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
	c.card_name = "card.joan_of_arc.knights_oath.name"; c.owner_id = "joan_of_arc"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	c.archetype = "card.joan_of_arc.knights_oath.archetype"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.HEAL
	e.value = 200; e.base_value = 200; e.target = "SELF"
	c.effects = [e]; return c

static func _flag_of_orleans() -> Resource:
	# 신국의 깃발 — LEGENDARY, 2코, 기술, 신성: HEAL_ALL 100 + BLOCK_ALL 80
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.flag_of_orleans.name"; c.owner_id = "joan_of_arc"
	c.cost = 2; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.LEGENDARY; c.play_animation = "idle"
	c.archetype = "card.joan_of_arc.flag_of_orleans.archetype"
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
	c.card_name = "card.joan_of_arc.saints_flame.name"; c.owner_id = "joan_of_arc"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.DIVINE; c.play_animation = "attack"
	c.archetype = "card.joan_of_arc.saints_flame.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.SACRIFICE_HP
	ea.value = 100; ea.base_value = 100
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.DAMAGE
	eb.value = 250; eb.base_value = 250; eb.target = "ALL"
	eb.damage_type = "divine"
	c.effects = [ea, eb]; return c

# ─────────────────────────────────────────
# v2 추가 25장
# ─────────────────────────────────────────

# ── COMMON 6장 ──

static func _holy_light() -> Resource:
	# 성스러운 빛 — COMMON, 1코, 기술, 신성: BLOCK 80
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.holy_light.name"; c.owner_id = "joan_of_arc"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "idle"
	c.archetype = "card.joan_of_arc.holy_light.archetype"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.BLOCK
	e.value = 80; e.base_value = 80; e.target = "SELF"
	c.effects = [e]; return c

static func _communion() -> Resource:
	# 성찬 — COMMON, 1코, 기술, 신성: HEAL 60 + DRAW 1
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.communion.name"; c.owner_id = "joan_of_arc"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "idle"
	c.archetype = "card.joan_of_arc.communion.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.HEAL
	ea.value = 60; ea.base_value = 60; ea.target = "SELF"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.DRAW
	eb.value = 1; eb.base_value = 1
	c.effects = [ea, eb]; return c

static func _revive_spark() -> Resource:
	# 부활의 불씨 — COMMON, 1코, 기술, 부활: 가장 HP 낮은 아군 HEAL 100
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.revive_spark.name"; c.owner_id = "joan_of_arc"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "idle"
	c.archetype = "card.joan_of_arc.revive_spark.archetype"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.HEAL
	e.value = 100; e.base_value = 100; e.target = "LOWEST_HP"
	c.effects = [e]; return c

static func _divine_providence() -> Resource:
	# 신의 섭리 — COMMON, 0코, 기술, 부활: DRAW 1 + 팀원 HP 30% 이하 있으면 BLOCK_ALL 40
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.divine_providence.name"; c.owner_id = "joan_of_arc"
	c.cost = 0; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "idle"
	c.archetype = "card.joan_of_arc.divine_providence.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DRAW
	ea.value = 1; ea.base_value = 1
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.BLOCK_ALL
	eb.value = 40; eb.base_value = 40
	eb.condition = "team_hp_below_30"
	c.effects = [ea, eb]; return c

static func _small_sacrifice() -> Resource:
	# 작은 희생 — COMMON, 0코, 기술, 순교: 자신 HP -40, HEAL_ALL 70
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.small_sacrifice.name"; c.owner_id = "joan_of_arc"
	c.cost = 0; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "idle"
	c.archetype = "card.joan_of_arc.small_sacrifice.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.SACRIFICE_HP
	ea.value = 40; ea.base_value = 40
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.HEAL_ALL
	eb.value = 70; eb.base_value = 70
	c.effects = [ea, eb]; return c

static func _sacrifice_cry() -> Resource:
	# 희생의 함성 — COMMON, 1코, 기술, 순교: 자신 HP -60, 팀 MORALE+2
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.sacrifice_cry.name"; c.owner_id = "joan_of_arc"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "idle"
	c.archetype = "card.joan_of_arc.sacrifice_cry.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.SACRIFICE_HP
	ea.value = 60; ea.base_value = 60
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.GAIN_MORALE
	eb.value = 2; eb.base_value = 2
	c.effects = [ea, eb]; return c

# ── UNCOMMON 9장 ──

static func _angel_wings() -> Resource:
	# 천사의 날개 — UNCOMMON, 1코, 기술, 신성: HEAL_ALL 40 + BLOCK 50 자신
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.angel_wings.name"; c.owner_id = "joan_of_arc"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	c.archetype = "card.joan_of_arc.angel_wings.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.HEAL_ALL
	ea.value = 40; ea.base_value = 40
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.BLOCK
	eb.value = 50; eb.base_value = 50; eb.target = "SELF"
	c.effects = [ea, eb]; return c

static func _second_chance() -> Resource:
	# 두 번째 기회 — UNCOMMON, 1코, 기술, 부활: 가장 HP 낮은 아군 HEAL 120 + BLOCK 60 자신
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.second_chance.name"; c.owner_id = "joan_of_arc"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	c.archetype = "card.joan_of_arc.second_chance.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.HEAL
	ea.value = 120; ea.base_value = 120; ea.target = "LOWEST_HP"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.BLOCK
	eb.value = 60; eb.base_value = 60; eb.target = "SELF"
	c.effects = [ea, eb]; return c

static func _revive_scroll() -> Resource:
	# 부활의 서 — UNCOMMON, 2코, 기술, 부활: 사망한 아군 HP 20%로 부활
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.revive_scroll.name"; c.owner_id = "joan_of_arc"
	c.cost = 2; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	c.archetype = "card.joan_of_arc.revive_scroll.archetype"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.REVIVE
	e.value = 20; e.base_value = 20
	c.effects = [e]; return c

static func _light_of_hope() -> Resource:
	# 희망의 빛 — UNCOMMON, 1코, 기술, 부활: 가장 HP 낮은 아군 HEAL 150
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.light_of_hope.name"; c.owner_id = "joan_of_arc"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	c.archetype = "card.joan_of_arc.light_of_hope.archetype"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.HEAL
	e.value = 150; e.base_value = 150; e.target = "LOWEST_HP"
	c.effects = [e]; return c

static func _holy_charge() -> Resource:
	# 신성 충전 — UNCOMMON, 1코, 기술, 부활: DRAW 2 + HEAL 60 자신
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.holy_charge.name"; c.owner_id = "joan_of_arc"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	c.archetype = "card.joan_of_arc.holy_charge.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DRAW
	ea.value = 2; ea.base_value = 2
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.HEAL
	eb.value = 60; eb.base_value = 60; eb.target = "SELF"
	c.effects = [ea, eb]; return c

static func _blade_of_justice() -> Resource:
	# 정의의 칼날 — UNCOMMON, 1코, 공격, 순교: 자신 HP -80, DMG 180
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.blade_of_justice.name"; c.owner_id = "joan_of_arc"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "attack"
	c.archetype = "card.joan_of_arc.blade_of_justice.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.SACRIFICE_HP
	ea.value = 80; ea.base_value = 80
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.DAMAGE
	eb.value = 180; eb.base_value = 180; eb.target = "SINGLE"
	eb.damage_type = "divine"
	c.effects = [ea, eb]; return c

static func _martyrdom_steps() -> Resource:
	# 순교의 발걸음 — UNCOMMON, 1코, 기술, 순교: 자신 HP -60, DRAW 2
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.martyrdom_steps.name"; c.owner_id = "joan_of_arc"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	c.archetype = "card.joan_of_arc.martyrdom_steps.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.SACRIFICE_HP
	ea.value = 60; ea.base_value = 60
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.DRAW
	eb.value = 2; eb.base_value = 2
	c.effects = [ea, eb]; return c

static func _altar_flame() -> Resource:
	# 제단의 불꽃 — UNCOMMON, 1코, 기술, 순교: 자신 HP -80, BLOCK_ALL 100
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.altar_flame.name"; c.owner_id = "joan_of_arc"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	c.archetype = "card.joan_of_arc.altar_flame.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.SACRIFICE_HP
	ea.value = 80; ea.base_value = 80
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.BLOCK_ALL
	eb.value = 100; eb.base_value = 100
	c.effects = [ea, eb]; return c

static func _holy_rage() -> Resource:
	# 신성한 격노 — UNCOMMON, 2코, 공격, 순교: 자신 HP -120, DMG 200 ALL
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.holy_rage.name"; c.owner_id = "joan_of_arc"
	c.cost = 2; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "attack"
	c.archetype = "card.joan_of_arc.holy_rage.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.SACRIFICE_HP
	ea.value = 120; ea.base_value = 120
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.DAMAGE
	eb.value = 200; eb.base_value = 200; eb.target = "ALL"
	eb.damage_type = "divine"
	c.effects = [ea, eb]; return c

# ── RARE 9장 ──

static func _holy_purification() -> Resource:
	# 신성한 정화 — RARE, 1코, 기술, 신성: 팀 전원 상태이상 제거 + HEAL_ALL 50
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.holy_purification.name"; c.owner_id = "joan_of_arc"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	c.archetype = "card.joan_of_arc.holy_purification.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.PURGE_STATUS
	ea.target = "ALL"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.HEAL_ALL
	eb.value = 50; eb.base_value = 50
	c.effects = [ea, eb]; return c

static func _knights_guard() -> Resource:
	# 기사의 수호 — RARE, 1코, 기술, 부활: BLOCK_ALL 60 + 사망 아군 있으면 BLOCK_ALL +40
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.knights_guard.name"; c.owner_id = "joan_of_arc"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	c.archetype = "card.joan_of_arc.knights_guard.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.BLOCK_ALL
	ea.value = 60; ea.base_value = 60
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.BLOCK_ALL
	eb.value = 40; eb.base_value = 40
	eb.condition = "dead_ally_any"
	c.effects = [ea, eb]; return c

static func _martyrs_legacy() -> Resource:
	# 순교자의 유산 — RARE, 1코, 기술, 부활: 사망 아군 수 × HEAL_ALL 100
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.martyrs_legacy.name"; c.owner_id = "joan_of_arc"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	c.archetype = "card.joan_of_arc.martyrs_legacy.archetype"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.HEAL_ALL
	e.value = 100; e.base_value = 100
	e.status_type = "dead_ally_count"
	c.effects = [e]; return c

static func _revive_ritual() -> Resource:
	# 부활의 의식 — RARE, 2코, 기술, 부활: 사망한 아군 HP 35%로 부활 + BLOCK_ALL 50
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.revive_ritual.name"; c.owner_id = "joan_of_arc"
	c.cost = 2; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	c.archetype = "card.joan_of_arc.revive_ritual.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.REVIVE
	ea.value = 35; ea.base_value = 35
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.BLOCK_ALL
	eb.value = 50; eb.base_value = 50
	c.effects = [ea, eb]; return c

static func _miracle_chain() -> Resource:
	# 기적의 연쇄 — RARE, 1코, 기술, 부활: HEAL_ALL 60 + 사망 아군 있으면 DRAW 2
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.miracle_chain.name"; c.owner_id = "joan_of_arc"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	c.archetype = "card.joan_of_arc.miracle_chain.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.HEAL_ALL
	ea.value = 60; ea.base_value = 60
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.DRAW
	eb.value = 2; eb.base_value = 2
	eb.condition = "dead_ally_any"
	c.effects = [ea, eb]; return c

static func _last_shield() -> Resource:
	# 최후의 방패 — RARE, 1코, 기술, 순교: 자신 HP -100, BLOCK_ALL 140
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.last_shield.name"; c.owner_id = "joan_of_arc"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	c.archetype = "card.joan_of_arc.last_shield.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.SACRIFICE_HP
	ea.value = 100; ea.base_value = 100
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.BLOCK_ALL
	eb.value = 140; eb.base_value = 140
	c.effects = [ea, eb]; return c

static func _purifying_sacrifice() -> Resource:
	# 정화의 희생 — RARE, 1코, 기술, 순교: 자신 HP -80, 팀 전원 상태이상 제거, HEAL_ALL 60
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.purifying_sacrifice.name"; c.owner_id = "joan_of_arc"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	c.archetype = "card.joan_of_arc.purifying_sacrifice.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.SACRIFICE_HP
	ea.value = 80; ea.base_value = 80
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.PURGE_STATUS
	eb.target = "ALL"
	var ec := EffRes.new()
	ec.effect_type = EffRes.EffectType.HEAL_ALL
	ec.value = 60; ec.base_value = 60
	c.effects = [ea, eb, ec]; return c

static func _saints_vow() -> Resource:
	# 성녀의 맹약 — RARE, 2코, 기술, 순교: 자신 HP -200, HEAL_ALL 300, BLOCK_ALL 100
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.saints_vow.name"; c.owner_id = "joan_of_arc"
	c.cost = 2; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	c.archetype = "card.joan_of_arc.saints_vow.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.SACRIFICE_HP
	ea.value = 200; ea.base_value = 200
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.HEAL_ALL
	eb.value = 300; eb.base_value = 300
	var ec := EffRes.new()
	ec.effect_type = EffRes.EffectType.BLOCK_ALL
	ec.value = 100; ec.base_value = 100
	c.effects = [ea, eb, ec]; return c

# ── LEGENDARY 1장 ──

static func _joan_return() -> Resource:
	# 잔 다르크의 귀환 — LEGENDARY, 2코, 기술, 부활: REVIVE HP 50% + BLOCK_ALL 80 + DRAW 1
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.joan_return.name"; c.owner_id = "joan_of_arc"
	c.cost = 2; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.LEGENDARY; c.play_animation = "idle"
	c.archetype = "card.joan_of_arc.joan_return.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.REVIVE
	ea.value = 50; ea.base_value = 50
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.BLOCK_ALL
	eb.value = 80; eb.base_value = 80
	var ec := EffRes.new()
	ec.effect_type = EffRes.EffectType.DRAW
	ec.value = 1; ec.base_value = 1
	c.effects = [ea, eb, ec]; return c

# ── 성전 (RARE, 순교 시너지 트리거) ──

static func _holy_war() -> Resource:
	# 성전 — RARE, 1코, 기술, 순교: 자신 HP -80, HEAL_ALL 120 (성전 시너지 트리거)
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.holy_war.name"; c.owner_id = "joan_of_arc"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	c.archetype = "card.joan_of_arc.holy_war.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.SACRIFICE_HP
	ea.value = 80; ea.base_value = 80
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.HEAL_ALL
	eb.value = 120; eb.base_value = 120
	c.effects = [ea, eb]; return c

# #41 성가대 — RARE, cost 2, POWER, 신성: 매 턴 팀 전체 회복 +20
static func _choir() -> Resource:
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.choir.name"; c.owner_id = "joan_of_arc"
	c.cost = 2; c.card_type = CardRes.CardType.POWER
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	c.archetype = "card.joan_of_arc.choir.archetype"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.APPLY_STATUS
	e.status_type = "power.heal_team_per_turn"
	e.value = 20; e.base_value = 20
	c.effects = [e]; return c

static func _martyr_wrath() -> Resource:
	# 순교자의 분노 — UNCOMMON, 2코, 공격: 사망 아군 수 × 12 피해 (placeholder)
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.martyr_wrath.name"; c.owner_id = "joan_of_arc"
	c.cost = 2; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "attack"
	c.archetype = "card.joan_of_arc.martyr_wrath.archetype"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.DAMAGE_PER_DEAD_ALLY
	e.value = 12; e.base_value = 12; e.target = "SINGLE"
	e.damage_type = "divine"
	c.effects = [e]; return c

static func _dead_blessing() -> Resource:
	# 망자의 축복 — UNCOMMON, 1코, 기술: 사망 아군 수 × 8 HP 팀 전체 회복 (placeholder)
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.dead_blessing.name"; c.owner_id = "joan_of_arc"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	c.archetype = "card.joan_of_arc.dead_blessing.archetype"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.HEAL_PER_DEAD_ALLY
	e.value = 8; e.base_value = 8; e.target = "ALL"
	c.effects = [e]; return c
