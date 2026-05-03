# resources/cards/cards_joan_of_arc.gd
# 잔다르크 카드 — starter 10 + pool 30 (신성공격 11 / 힐·부활 10 / 순교 9)
# CP 공식: DMG×0.010, BLOCK×0.008, HEAL×0.013, HEAL_ALL×0.020, BLOCK_ALL×0.013
const CardRes = preload("res://resources/card_resource.gd")
const EffRes  = preload("res://resources/effect_resource.gd")

static func starter_deck() -> Array:
	var cards: Array = []
	for _i in range(4):
		cards.append(_strike())
	for _i in range(4):
		cards.append(_defend())
	cards.append(_holy_smite())
	cards.append(_shield_prayer())
	return cards

static func pool() -> Array:
	return [
		# ── 신성공격 11 ──
		_holy_bolt(),
		_orleans_charge(), _holy_wave(), _martyrs_strike(), _crusade(),
		_holy_fury(), _holy_lance(), _holy_judge(), _divine_wrath(),
		_divine_punishment(), _archangels_wrath(),
		# ── 힐·부활 10 ──
		_holy_touch(), _communion(),
		_hymn(), _second_chance(), _holy_purification(), _angel_wings(),
		_knights_oath(), _flag_of_orleans(),
		_miracle_revive(), _joan_return(),
		# ── 순교 9 ──
		_martyrs_will(), _altar_flame(),
		_martyrdom_steps(), _holy_rage(),
		_last_shield(), _purifying_sacrifice(), _saints_vow(),
		_saints_flame(), _martyr_wrath(),
	]

# ─────────────────────────────────────────
# 시작덱 (4종)
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
	e.value = 125; e.base_value = 125; e.target = "SELF"
	c.effects = [e]; return c

static func _holy_smite() -> Resource:
	# COMMON, 1코, ATTACK: DMG 80 divine + HEAL 20 SELF (cp=1.06)
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.holy_smite.name"; c.owner_id = "joan_of_arc"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "attack"
	c.archetype = "card.joan_of_arc.holy_smite.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 80; ea.base_value = 80; ea.target = "SINGLE"
	ea.damage_type = "divine"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.HEAL
	eb.value = 20; eb.base_value = 20; eb.target = "SELF"
	c.effects = [ea, eb]; return c

static func _shield_prayer() -> Resource:
	# COMMON, 1코, SKILL: BLOCK 80 SELF + HEAL 20 SELF (cp=0.90)
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.shield_prayer.name"; c.owner_id = "joan_of_arc"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "idle"
	c.archetype = "card.joan_of_arc.shield_prayer.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.BLOCK
	ea.value = 80; ea.base_value = 80; ea.target = "SELF"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.HEAL
	eb.value = 20; eb.base_value = 20; eb.target = "SELF"
	c.effects = [ea, eb]; return c

# ─────────────────────────────────────────
# 신성공격 12장
# ─────────────────────────────────────────

static func _holy_bolt() -> Resource:
	# COMMON, 1코, ATTACK: DMG 70 divine + VULNERABLE 1 SINGLE (cp=1.0)
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.holy_bolt.name"; c.owner_id = "joan_of_arc"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "attack"
	c.archetype = "card.joan_of_arc.holy_bolt.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 70; ea.base_value = 70; ea.target = "SINGLE"
	ea.damage_type = "divine"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.APPLY_STATUS
	eb.status_type = "vulnerable"; eb.value = 1; eb.base_value = 1; eb.target = "SINGLE"
	c.effects = [ea, eb]; return c

static func _orleans_charge() -> Resource:
	# UNCOMMON, 1코, ATTACK: DMG 110 divine SINGLE (cp=1.0)
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.orleans_charge.name"; c.owner_id = "joan_of_arc"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "attack"
	c.archetype = "card.joan_of_arc.orleans_charge.archetype"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.DAMAGE
	e.value = 110; e.base_value = 110; e.target = "SINGLE"
	e.damage_type = "divine"
	c.effects = [e]; return c

static func _holy_wave() -> Resource:
	# UNCOMMON, 1코, ATTACK: DMG 65 ALL divine (cp=1.0)
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.holy_wave.name"; c.owner_id = "joan_of_arc"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "attack"
	c.archetype = "card.joan_of_arc.holy_wave.archetype"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.DAMAGE
	e.value = 65; e.base_value = 65; e.target = "ALL"
	e.damage_type = "divine"
	c.effects = [e]; return c

static func _martyrs_strike() -> Resource:
	# UNCOMMON, 1코, ATTACK: SACRIFICE 80 + DMG 150 divine SINGLE (cp=1.07)
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.martyrs_strike.name"; c.owner_id = "joan_of_arc"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "attack"
	c.archetype = "card.joan_of_arc.martyrs_strike.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.SACRIFICE_HP
	ea.value = 80; ea.base_value = 80
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.DAMAGE
	eb.value = 150; eb.base_value = 150; eb.target = "SINGLE"
	eb.damage_type = "divine"
	c.effects = [ea, eb]; return c

static func _crusade() -> Resource:
	# UNCOMMON, 2코, ATTACK: DMG 82 ALL + VULNERABLE 1 ALL (cp=1.81)
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.crusade.name"; c.owner_id = "joan_of_arc"
	c.cost = 2; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "attack"
	c.archetype = "card.joan_of_arc.crusade.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 82; ea.base_value = 82; ea.target = "ALL"
	ea.damage_type = "divine"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.APPLY_STATUS
	eb.status_type = "vulnerable"; eb.value = 1; eb.base_value = 1; eb.target = "ALL"
	c.effects = [ea, eb]; return c

static func _holy_fury() -> Resource:
	# RARE, 2코, ATTACK: DMG 140 ALL divine (cp=1.98)
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.holy_fury.name"; c.owner_id = "joan_of_arc"
	c.cost = 2; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "attack"
	c.archetype = "card.joan_of_arc.holy_fury.archetype"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.DAMAGE
	e.value = 140; e.base_value = 140; e.target = "ALL"
	e.damage_type = "divine"
	c.effects = [e]; return c

static func _holy_lance() -> Resource:
	# RARE, 2코, ATTACK: DMG 240 divine SINGLE (cp=2.0)
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.holy_lance.name"; c.owner_id = "joan_of_arc"
	c.cost = 2; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "attack"
	c.archetype = "card.joan_of_arc.holy_lance.archetype"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.DAMAGE
	e.value = 240; e.base_value = 240; e.target = "SINGLE"
	e.damage_type = "divine"
	c.effects = [e]; return c

static func _holy_judge() -> Resource:
	# RARE, 2코, ATTACK: DMG 100 + WEAK 2 + VULNERABLE 2 SINGLE (cp=1.83)
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.holy_judge.name"; c.owner_id = "joan_of_arc"
	c.cost = 2; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "attack"
	c.archetype = "card.joan_of_arc.holy_judge.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 100; ea.base_value = 100; ea.target = "SINGLE"
	ea.damage_type = "divine"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.APPLY_STATUS
	eb.status_type = "weak"; eb.value = 2; eb.base_value = 2; eb.target = "SINGLE"
	var ec := EffRes.new()
	ec.effect_type = EffRes.EffectType.APPLY_STATUS
	ec.status_type = "vulnerable"; ec.value = 2; ec.base_value = 2; ec.target = "SINGLE"
	c.effects = [ea, eb, ec]; return c

static func _divine_wrath() -> Resource:
	# RARE, 2코, ATTACK: DMG 60 ALL + WEAK 1 ALL + VULNERABLE 1 ALL (cp=1.85)
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.divine_wrath.name"; c.owner_id = "joan_of_arc"
	c.cost = 2; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "attack"
	c.archetype = "card.joan_of_arc.divine_wrath.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 60; ea.base_value = 60; ea.target = "ALL"
	ea.damage_type = "divine"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.APPLY_STATUS
	eb.status_type = "weak"; eb.value = 1; eb.base_value = 1; eb.target = "ALL"
	var ec := EffRes.new()
	ec.effect_type = EffRes.EffectType.APPLY_STATUS
	ec.status_type = "vulnerable"; ec.value = 1; ec.base_value = 1; ec.target = "ALL"
	c.effects = [ea, eb, ec]; return c

static func _divine_punishment() -> Resource:
	# LEGENDARY, 2코, ATTACK: SACRIFICE 100 + DMG 150 ALL + WEAK 2 ALL + VULNERABLE 2 ALL (cp=2.77)
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.divine_punishment.name"; c.owner_id = "joan_of_arc"
	c.cost = 2; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.LEGENDARY; c.play_animation = "attack"
	c.archetype = "card.joan_of_arc.divine_punishment.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.SACRIFICE_HP
	ea.value = 100; ea.base_value = 100
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.DAMAGE
	eb.value = 150; eb.base_value = 150; eb.target = "ALL"
	eb.damage_type = "divine"
	var ec := EffRes.new()
	ec.effect_type = EffRes.EffectType.APPLY_STATUS
	ec.status_type = "weak"; ec.value = 2; ec.base_value = 2; ec.target = "ALL"
	var ed := EffRes.new()
	ed.effect_type = EffRes.EffectType.APPLY_STATUS
	ed.status_type = "vulnerable"; ed.value = 2; ed.base_value = 2; ed.target = "ALL"
	c.effects = [ea, eb, ec, ed]; return c

static func _archangels_wrath() -> Resource:
	# LEGENDARY, 3코, ATTACK: DMG 200 ALL divine + WEAK 1 ALL (cp=3.08)
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.archangels_wrath.name"; c.owner_id = "joan_of_arc"
	c.cost = 3; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.LEGENDARY; c.play_animation = "attack"
	c.archetype = "card.joan_of_arc.archangels_wrath.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 200; ea.base_value = 200; ea.target = "ALL"
	ea.damage_type = "divine"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.APPLY_STATUS
	eb.status_type = "weak"; eb.value = 1; eb.base_value = 1; eb.target = "ALL"
	c.effects = [ea, eb]; return c

# ─────────────────────────────────────────
# 힐·부활 12장
# ─────────────────────────────────────────

static func _holy_touch() -> Resource:
	# COMMON, 1코, SKILL: HEAL 77 SELF (cp=1.0)
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.holy_touch.name"; c.owner_id = "joan_of_arc"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "idle"
	c.archetype = "card.joan_of_arc.holy_touch.archetype"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.HEAL
	e.value = 77; e.base_value = 77; e.target = "SELF"
	c.effects = [e]; return c

static func _communion() -> Resource:
	# COMMON, 1코, SKILL: HEAL 20 SELF + DRAW 1 (cp=1.06)
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.communion.name"; c.owner_id = "joan_of_arc"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "idle"
	c.archetype = "card.joan_of_arc.communion.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.HEAL
	ea.value = 20; ea.base_value = 20; ea.target = "SELF"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.DRAW
	eb.value = 1; eb.base_value = 1
	c.effects = [ea, eb]; return c

static func _hymn() -> Resource:
	# UNCOMMON, 1코, SKILL: HEAL_ALL 55 (cp=1.0)
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.hymn.name"; c.owner_id = "joan_of_arc"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	c.archetype = "card.joan_of_arc.hymn.archetype"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.HEAL_ALL
	e.value = 55; e.base_value = 55
	c.effects = [e]; return c

static func _second_chance() -> Resource:
	# UNCOMMON, 1코, SKILL: HEAL 70 LOWEST_HP + BLOCK 25 SELF (cp=1.01)
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.second_chance.name"; c.owner_id = "joan_of_arc"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	c.archetype = "card.joan_of_arc.second_chance.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.HEAL
	ea.value = 70; ea.base_value = 70; ea.target = "LOWEST_HP"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.BLOCK
	eb.value = 25; eb.base_value = 25; eb.target = "SELF"
	c.effects = [ea, eb]; return c

static func _holy_purification() -> Resource:
	# UNCOMMON, 1코, SKILL: PURGE_STATUS ALL + HEAL_ALL 25 (cp=0.91)
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.holy_purification.name"; c.owner_id = "joan_of_arc"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	c.archetype = "card.joan_of_arc.holy_purification.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.PURGE_STATUS
	ea.target = "ALL"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.HEAL_ALL
	eb.value = 25; eb.base_value = 25
	c.effects = [ea, eb]; return c

static func _angel_wings() -> Resource:
	# RARE, 1코, SKILL: INNATE + HEAL 70 SELF (cp=1.01, is_innate)
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.angel_wings.name"; c.owner_id = "joan_of_arc"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	c.archetype = "card.joan_of_arc.angel_wings.archetype"
	c.is_innate = true
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.HEAL
	e.value = 70; e.base_value = 70; e.target = "SELF"
	c.effects = [e]; return c

static func _knights_oath() -> Resource:
	# LEGENDARY, 2코, SKILL: HEAL 200 SELF (cp=2.0)
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.knights_oath.name"; c.owner_id = "joan_of_arc"
	c.cost = 2; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.LEGENDARY; c.play_animation = "idle"
	c.archetype = "card.joan_of_arc.knights_oath.archetype"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.HEAL
	e.value = 200; e.base_value = 200; e.target = "SELF"
	c.effects = [e]; return c

static func _flag_of_orleans() -> Resource:
	# LEGENDARY, 2코, SKILL: HEAL_ALL 80 + BLOCK_ALL 80 (cp=2.03)
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.flag_of_orleans.name"; c.owner_id = "joan_of_arc"
	c.cost = 2; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.LEGENDARY; c.play_animation = "idle"
	c.archetype = "card.joan_of_arc.flag_of_orleans.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.HEAL_ALL
	ea.value = 80; ea.base_value = 80
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.BLOCK_ALL
	eb.value = 80; eb.base_value = 80
	c.effects = [ea, eb]; return c

static func _miracle_revive() -> Resource:
	# RARE, 2코, SKILL: REVIVE 30% + EXHAUST (cp=1.70, is_exhaust)
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.miracle_revive.name"; c.owner_id = "joan_of_arc"
	c.cost = 2; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	c.archetype = "card.joan_of_arc.miracle_revive.archetype"
	c.is_exhaust = true
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.REVIVE
	e.value = 30; e.base_value = 30
	c.effects = [e]; return c

static func _joan_return() -> Resource:
	# LEGENDARY, 3코, SKILL: REVIVE 100% + HEAL_ALL 30 (cp=3.08)
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.joan_return.name"; c.owner_id = "joan_of_arc"
	c.cost = 3; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.LEGENDARY; c.play_animation = "idle"
	c.archetype = "card.joan_of_arc.joan_return.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.REVIVE
	ea.value = 100; ea.base_value = 100
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.HEAL_ALL
	eb.value = 30; eb.base_value = 30
	c.effects = [ea, eb]; return c

# ─────────────────────────────────────────
# 순교 11장
# ─────────────────────────────────────────

static func _martyrs_will() -> Resource:
	# UNCOMMON, 1코, SKILL: SACRIFICE 50 + HEAL_ALL 65 (cp=1.0)
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.martyrs_will.name"; c.owner_id = "joan_of_arc"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	c.archetype = "card.joan_of_arc.martyrs_will.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.SACRIFICE_HP
	ea.value = 50; ea.base_value = 50
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.HEAL_ALL
	eb.value = 65; eb.base_value = 65
	c.effects = [ea, eb]; return c

static func _altar_flame() -> Resource:
	# UNCOMMON, 1코, SKILL: SACRIFICE 50 + BLOCK_ALL 110 (cp=1.12)
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.altar_flame.name"; c.owner_id = "joan_of_arc"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	c.archetype = "card.joan_of_arc.altar_flame.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.SACRIFICE_HP
	ea.value = 50; ea.base_value = 50
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.BLOCK_ALL
	eb.value = 110; eb.base_value = 110
	c.effects = [ea, eb]; return c

static func _martyrdom_steps() -> Resource:
	# UNCOMMON, 1코, SKILL: SACRIFICE 100 + DRAW 2 (cp=1.09)
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.martyrdom_steps.name"; c.owner_id = "joan_of_arc"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	c.archetype = "card.joan_of_arc.martyrdom_steps.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.SACRIFICE_HP
	ea.value = 100; ea.base_value = 100
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.DRAW
	eb.value = 2; eb.base_value = 2
	c.effects = [ea, eb]; return c

static func _holy_rage() -> Resource:
	# UNCOMMON, 2코, ATTACK: SACRIFICE 300 + DMG 200 ALL divine (cp=2.0)
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.holy_rage.name"; c.owner_id = "joan_of_arc"
	c.cost = 2; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "attack"
	c.archetype = "card.joan_of_arc.holy_rage.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.SACRIFICE_HP
	ea.value = 300; ea.base_value = 300
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.DAMAGE
	eb.value = 200; eb.base_value = 200; eb.target = "ALL"
	eb.damage_type = "divine"
	c.effects = [ea, eb]; return c

static func _last_shield() -> Resource:
	# RARE, 1코, SKILL: SACRIFICE 100 + BLOCK_ALL 130 (cp=1.075)
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
	eb.value = 130; eb.base_value = 130
	c.effects = [ea, eb]; return c

static func _purifying_sacrifice() -> Resource:
	# RARE, 1코, SKILL: SACRIFICE 50 + PURGE_STATUS ALL + HEAL_ALL 50 (cp=1.08)
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.purifying_sacrifice.name"; c.owner_id = "joan_of_arc"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	c.archetype = "card.joan_of_arc.purifying_sacrifice.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.SACRIFICE_HP
	ea.value = 50; ea.base_value = 50
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.PURGE_STATUS
	eb.target = "ALL"
	var ec := EffRes.new()
	ec.effect_type = EffRes.EffectType.HEAL_ALL
	ec.value = 50; ec.base_value = 50
	c.effects = [ea, eb, ec]; return c

static func _saints_vow() -> Resource:
	# RARE, 2코, SKILL: SACRIFICE 200 + HEAL_ALL 103 + BLOCK_ALL 70 (cp=1.81)
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
	eb.value = 103; eb.base_value = 103
	var ec := EffRes.new()
	ec.effect_type = EffRes.EffectType.BLOCK_ALL
	ec.value = 70; ec.base_value = 70
	c.effects = [ea, eb, ec]; return c

static func _saints_flame() -> Resource:
	# DIVINE, 2코, ATTACK: SACRIFICE 250 + DMG 220 ALL divine (cp=1.96)
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.saints_flame.name"; c.owner_id = "joan_of_arc"
	c.cost = 2; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.DIVINE; c.play_animation = "attack"
	c.archetype = "card.joan_of_arc.saints_flame.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.SACRIFICE_HP
	ea.value = 250; ea.base_value = 250
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.DAMAGE
	eb.value = 220; eb.base_value = 220; eb.target = "ALL"
	eb.damage_type = "divine"
	c.effects = [ea, eb]; return c

static func _martyr_wrath() -> Resource:
	# UNCOMMON, 1코, ATTACK: DAMAGE_PER_DEAD_ALLY 220 divine SINGLE (cp=1.0)
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.martyr_wrath.name"; c.owner_id = "joan_of_arc"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "attack"
	c.archetype = "card.joan_of_arc.martyr_wrath.archetype"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.DAMAGE_PER_DEAD_ALLY
	e.value = 220; e.base_value = 220; e.target = "SINGLE"
	e.damage_type = "divine"
	c.effects = [e]; return c
