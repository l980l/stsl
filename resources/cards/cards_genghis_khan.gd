# resources/cards/cards_genghis_khan.gd
# 칭기즈칸 카드 — starter 10 + pool 30 (기동 12 / 몽골 기병 10 / 약탈 8)
# 아키타입: 기동(Rush) / 몽골 기병(Horde) / 약탈(Plunder)
const CardRes = preload("res://resources/card_resource.gd")
const EffRes  = preload("res://resources/effect_resource.gd")

static func starter_deck() -> Array:
	var cards: Array = []
	for _i in range(4):
		cards.append(_strike())
	for _i in range(4):
		cards.append(_defend())
	cards.append(_horse_thrust())
	cards.append(_rider_call())
	return cards

static func pool() -> Array:
	return [
		# ── 기동 12 ──
		_cavalry_charge(), _scout(), _arrow_volley(),
		_ambush(), _supply_cut(), _encirclement(),
		_mingens_order(), _poison_arrow(), _conquerors_ambition(),
		_genghis_fury(), _swift_raid(), _rear_disruption(),
		# ── 몽골 기병 10 ──
		_cavalry_crossing(), _lightning_sprint(), _execution_ground(),
		_spoils_distribution(), _plunder_flame(), _rapid_fire(),
		_wind_legion(), _cavalry_encirclement(), _iron_breakthrough(),
		_desert_cavalry(),
		# ── 약탈 8 ──
		_territory_expansion(), _red_horizon(),
		_submission(), _poison_arrow_rain(),
		_thousand_mile_army(), _steppe_terror(), _war_tribute(),
		_great_steppe_siege(),
	]

# ─────────────────────────────────────────
# 시작덱 (2종)
# ─────────────────────────────────────────

static func _strike() -> Resource:
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.strike.name"; c.owner_id = "genghis_khan"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "attack"
	c.archetype = "card.genghis_khan.strike.archetype"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.DAMAGE
	e.value = 100; e.base_value = 100; e.target = "SINGLE"
	e.damage_type = "slash"
	c.effects = [e]; return c

static func _defend() -> Resource:
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.defend.name"; c.owner_id = "genghis_khan"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "idle"
	c.archetype = "card.genghis_khan.defend.archetype"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.BLOCK
	e.value = 125; e.base_value = 125; e.target = "SELF"
	c.effects = [e]; return c

static func _horse_thrust() -> Resource:
	# 기마 돌격 — COMMON, 1코, ATTACK, 기동: DMG 60 slash + STRENGTH 1 SELF
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.horse_thrust.name"; c.owner_id = "genghis_khan"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "attack"
	c.archetype = "card.genghis_khan.horse_thrust.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 60; ea.base_value = 60; ea.target = "SINGLE"
	ea.damage_type = "slash"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.APPLY_STATUS
	eb.status_type = "strength"; eb.value = 1; eb.base_value = 1; eb.target = "SELF"
	c.effects = [ea, eb]; return c

static func _rider_call() -> Resource:
	# 기마 소환 — COMMON, 1코, SKILL, 몽골 기병: SUMMON_TOKEN 1
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.rider_call.name"; c.owner_id = "genghis_khan"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "idle"
	c.archetype = "card.genghis_khan.rider_call.archetype"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.SUMMON_TOKEN
	e.value = 1; e.base_value = 1
	c.effects = [e]; return c

# ─────────────────────────────────────────
# v1 풀 카드 13장
# ─────────────────────────────────────────

static func _cavalry_charge() -> Resource:
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.cavalry_charge.name"; c.owner_id = "genghis_khan"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "attack"
	c.archetype = "card.genghis_khan.cavalry_charge.archetype"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.DAMAGE
	e.value = 50; e.base_value = 50; e.target = "ALL"
	e.damage_type = "blunt"
	c.effects = [e]; return c

static func _scout() -> Resource:
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.scout.name"; c.owner_id = "genghis_khan"
	c.cost = 0; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "idle"
	c.archetype = "card.genghis_khan.scout.archetype"
	c.is_exhaust = true
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.GAIN_MORALE
	e.value = 2; e.base_value = 2
	c.effects = [e]; return c

static func _arrow_volley() -> Resource:
	# 화살 일제사격 — UNCOMMON, 1코, ATTACK, 기동: DMG 40 ALL + MORALE+1
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.arrow_volley.name"; c.owner_id = "genghis_khan"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "attack"
	c.archetype = "card.genghis_khan.arrow_volley.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 40; ea.base_value = 40; ea.target = "ALL"
	ea.damage_type = "projectile"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.GAIN_MORALE
	eb.value = 1; eb.base_value = 1
	c.effects = [ea, eb]; return c

static func _ambush() -> Resource:
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.ambush.name"; c.owner_id = "genghis_khan"
	c.cost = 0; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "attack"
	c.archetype = "card.genghis_khan.ambush.archetype"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.DAMAGE
	e.value = 20; e.base_value = 20; e.target = "SINGLE"
	e.damage_type = "slash"
	c.effects = [e]; return c

static func _supply_cut() -> Resource:
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.supply_cut.name"; c.owner_id = "genghis_khan"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	c.archetype = "card.genghis_khan.supply_cut.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DRAW
	ea.value = 1; ea.base_value = 1
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.GAIN_MORALE
	eb.value = 1; eb.base_value = 1
	c.effects = [ea, eb]; return c

static func _encirclement() -> Resource:
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.encirclement.name"; c.owner_id = "genghis_khan"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "attack"
	c.archetype = "card.genghis_khan.encirclement.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 40; ea.base_value = 40; ea.target = "ALL"
	ea.damage_type = "blunt"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.APPLY_STATUS
	eb.value = 1; eb.base_value = 1; eb.target = "ALL"; eb.status_type = "weak"
	c.effects = [ea, eb]; return c

static func _mingens_order() -> Resource:
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.mingens_order.name"; c.owner_id = "genghis_khan"
	c.cost = 2; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	c.archetype = "card.genghis_khan.mingens_order.archetype"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.DRAW
	e.value = 3; e.base_value = 3
	c.effects = [e]; return c

static func _poison_arrow() -> Resource:
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.poison_arrow.name"; c.owner_id = "genghis_khan"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "attack"
	c.archetype = "card.genghis_khan.poison_arrow.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 30; ea.base_value = 30; ea.target = "ALL"
	ea.damage_type = "projectile"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.APPLY_STATUS
	eb.value = 1; eb.base_value = 1; eb.target = "ALL"; eb.status_type = "poison"
	c.effects = [ea, eb]; return c


static func _conquerors_ambition() -> Resource:
	# 정복자의 야망 — RARE, 1코, ATTACK, 기동: DMG 70 + MORALE+1
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.conquerors_ambition.name"; c.owner_id = "genghis_khan"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "attack"
	c.archetype = "card.genghis_khan.conquerors_ambition.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 70; ea.base_value = 70; ea.target = "SINGLE"
	ea.damage_type = "slash"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.GAIN_MORALE
	eb.value = 1; eb.base_value = 1
	c.effects = [ea, eb]; return c


static func _genghis_fury() -> Resource:
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.genghis_fury.name"; c.owner_id = "genghis_khan"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.DIVINE; c.play_animation = "attack"
	c.archetype = "card.genghis_khan.genghis_fury.archetype"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.DAMAGE
	e.value = 40; e.base_value = 40; e.target = "ALL"; e.hit_count = 2
	e.damage_type = "blunt"
	c.effects = [e]; return c

# ─────────────────────────────────────────
# v2 풀 카드 25장
# ─────────────────────────────────────────


static func _swift_raid() -> Resource:
	# 급습 — COMMON, 0코, 공격, 기동: DMG 60
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.swift_raid.name"; c.owner_id = "genghis_khan"
	c.cost = 0; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "attack"
	c.archetype = "card.genghis_khan.swift_raid.archetype"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.DAMAGE
	e.value = 15; e.base_value = 15; e.target = "SINGLE"
	e.damage_type = "slash"
	c.effects = [e]; return c


static func _rear_disruption() -> Resource:
	# 후방 교란 — COMMON, 1코, 공격, 몽골 기병: DMG 45 ALL + VULNERABLE 1 ALL
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.rear_disruption.name"; c.owner_id = "genghis_khan"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "attack"
	c.archetype = "card.genghis_khan.rear_disruption.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 30; ea.base_value = 30; ea.target = "ALL"
	ea.damage_type = "blunt"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.APPLY_STATUS
	eb.value = 1; eb.base_value = 1; eb.target = "ALL"; eb.status_type = "vulnerable"
	c.effects = [ea, eb]; return c

static func _cavalry_crossing() -> Resource:
	# 기마 도하 — UNCOMMON, 1코, 기술, 기동: DRAW 2 + ENERGY+1
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.cavalry_crossing.name"; c.owner_id = "genghis_khan"
	c.cost = 2; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	c.archetype = "card.genghis_khan.cavalry_crossing.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DRAW
	ea.value = 2; ea.base_value = 2
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.ENERGY
	eb.value = 1; eb.base_value = 1
	c.effects = [ea, eb]; return c

static func _lightning_sprint() -> Resource:
	# 낙뢰 질주 — UNCOMMON, 1코, 공격, 기동: DMG 90 + COST_NEXT -1
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.lightning_sprint.name"; c.owner_id = "genghis_khan"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "attack"
	c.archetype = "card.genghis_khan.lightning_sprint.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 60; ea.base_value = 60; ea.target = "SINGLE"
	ea.damage_type = "blunt"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.COST_NEXT
	eb.value = 1; eb.base_value = 1
	c.effects = [ea, eb]; return c

static func _execution_ground() -> Resource:
	# 처형대 — UNCOMMON, 1코, 공격, 약탈: 적 HP 30% 이하 DMG 200, 아닐 때 DMG 100
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.execution_ground.name"; c.owner_id = "genghis_khan"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "attack"
	c.archetype = "card.genghis_khan.execution_ground.archetype"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.CONDITIONAL_DMG
	e.value = 100; e.base_value = 100
	e.bonus_value = 170; e.base_bonus_value = 170
	e.status_type = "enemy_hp_below_30"; e.target = "SINGLE"
	e.damage_type = "slash"
	c.effects = [e]; return c

static func _spoils_distribution() -> Resource:
	# 전리품 배분 — UNCOMMON, 1코, 기술, 약탈: DRAW 2 + HEAL_ALL 50
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.spoils_distribution.name"; c.owner_id = "genghis_khan"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	c.archetype = "card.genghis_khan.spoils_distribution.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DRAW
	ea.value = 1; ea.base_value = 1
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.HEAL_ALL
	eb.value = 20; eb.base_value = 20
	c.effects = [ea, eb]; return c

static func _plunder_flame() -> Resource:
	# 약탈의 불길 — UNCOMMON, 1코, 공격, 약탈: DMG 80 SINGLE + POISON 1 ALL
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.plunder_flame.name"; c.owner_id = "genghis_khan"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "attack"
	c.archetype = "card.genghis_khan.plunder_flame.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 80; ea.base_value = 80; ea.target = "SINGLE"
	ea.damage_type = "explosive"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.APPLY_STATUS
	eb.status_type = "poison"; eb.value = 1; eb.base_value = 1; eb.target = "ALL"
	c.effects = [ea, eb]; return c

static func _rapid_fire() -> Resource:
	# 연사 — UNCOMMON, 1코, 공격, 몽골 기병: DMG 40 ALL × 2
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.rapid_fire.name"; c.owner_id = "genghis_khan"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "attack"
	c.archetype = "card.genghis_khan.rapid_fire.archetype"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.DAMAGE
	e.value = 35; e.base_value = 35; e.target = "ALL"; e.hit_count = 2
	e.damage_type = "projectile"
	c.effects = [e]; return c

static func _wind_legion() -> Resource:
	# 바람의 군단 — UNCOMMON, 1코, 공격, 몽골 기병: DMG 55 ALL + ENERGY+1
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.wind_legion.name"; c.owner_id = "genghis_khan"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "attack"
	c.archetype = "card.genghis_khan.wind_legion.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 35; ea.base_value = 35; ea.target = "ALL"
	ea.damage_type = "blunt"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.ENERGY
	eb.value = 1; eb.base_value = 1
	c.effects = [ea, eb]; return c

static func _cavalry_encirclement() -> Resource:
	# 기병 포위망 — UNCOMMON, 1코, 공격, 몽골 기병: DMG 60 ALL + BLOCK 50 SELF
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.cavalry_encirclement.name"; c.owner_id = "genghis_khan"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "attack"
	c.archetype = "card.genghis_khan.cavalry_encirclement.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 55; ea.base_value = 55; ea.target = "ALL"
	ea.damage_type = "blunt"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.BLOCK
	eb.value = 30; eb.base_value = 30; eb.target = "SELF"
	c.effects = [ea, eb]; return c

static func _iron_breakthrough() -> Resource:
	# 무간 돌파 — UNCOMMON, 2코, 공격, 몽골 기병: DMG 90 ALL + VULNERABLE 1 ALL
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.iron_breakthrough.name"; c.owner_id = "genghis_khan"
	c.cost = 2; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "attack"
	c.archetype = "card.genghis_khan.iron_breakthrough.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 90; ea.base_value = 90; ea.target = "ALL"
	ea.damage_type = "blunt"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.APPLY_STATUS
	eb.value = 1; eb.base_value = 1; eb.target = "ALL"; eb.status_type = "vulnerable"
	c.effects = [ea, eb]; return c

static func _desert_cavalry() -> Resource:
	# 사막 기마 — RARE, 1코, 기술, 기동: 이번 턴 드로우한 카드 수 × DMG 30
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.desert_cavalry.name"; c.owner_id = "genghis_khan"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "attack"
	c.archetype = "card.genghis_khan.desert_cavalry.archetype"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.PER_DRAW_DMG
	e.value = 25; e.base_value = 25; e.target = "SINGLE"
	e.damage_type = "blunt"
	c.effects = [e]; return c

static func _territory_expansion() -> Resource:
	# 영토 확장 — RARE, 1코, 기술, 약탈: DRAW 2 + ENERGY+2
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.territory_expansion.name"; c.owner_id = "genghis_khan"
	c.cost = 2; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	c.archetype = "card.genghis_khan.territory_expansion.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DRAW
	ea.value = 1; ea.base_value = 1
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.ENERGY
	eb.value = 2; eb.base_value = 2
	c.effects = [ea, eb]; return c

static func _red_horizon() -> Resource:
	# 붉은 지평선 — RARE, 1코, 공격, 약탈: DMG 110 + 처치 시 DRAW 2, EXHAUST
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.red_horizon.name"; c.owner_id = "genghis_khan"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "attack"
	c.archetype = "card.genghis_khan.red_horizon.archetype"
	c.is_exhaust = true
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 110; ea.base_value = 110; ea.target = "SINGLE"
	ea.damage_type = "slash"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.ON_KILL_DRAW
	eb.value = 2; eb.base_value = 2
	c.effects = [ea, eb]; return c


static func _submission() -> Resource:
	# 굴복 — RARE, 1코, 공격, 약탈: 적 HP 50% 이하 DMG 160 + WEAK 2, 아닐 때 DMG 100 + WEAK 1
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.submission.name"; c.owner_id = "genghis_khan"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "attack"
	c.archetype = "card.genghis_khan.submission.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.CONDITIONAL_DMG
	ea.value = 100; ea.base_value = 100
	ea.bonus_value = 160; ea.base_bonus_value = 160
	ea.status_type = "enemy_hp_below_50"; ea.target = "SINGLE"
	ea.damage_type = "slash"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.APPLY_STATUS
	eb.value = 1; eb.base_value = 1; eb.target = "SINGLE"; eb.status_type = "weak"
	c.effects = [ea, eb]; return c

static func _poison_arrow_rain() -> Resource:
	# 독 화살비 — RARE, 1코, 공격, 몽골 기병: DMG 55 ALL + POISON 3 ALL
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.poison_arrow_rain.name"; c.owner_id = "genghis_khan"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "attack"
	c.archetype = "card.genghis_khan.poison_arrow_rain.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 20; ea.base_value = 20; ea.target = "ALL"
	ea.damage_type = "projectile"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.APPLY_STATUS
	eb.value = 1; eb.base_value = 1; eb.target = "ALL"; eb.status_type = "poison"
	c.effects = [ea, eb]; return c

static func _thousand_mile_army() -> Resource:
	# 천리 원정군 — RARE, 2코, 공격, 몽골 기병: DMG 70 ALL × 2
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.thousand_mile_army.name"; c.owner_id = "genghis_khan"
	c.cost = 2; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "attack"
	c.archetype = "card.genghis_khan.thousand_mile_army.archetype"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.DAMAGE
	e.value = 70; e.base_value = 70; e.target = "ALL"; e.hit_count = 2
	e.damage_type = "blunt"
	c.effects = [e]; return c

static func _steppe_terror() -> Resource:
	# 대초원의 위협 — RARE, 1코, 공격, 몽골 기병: DMG 65 ALL + POISON 1 ALL + WEAK 1 ALL
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.steppe_terror.name"; c.owner_id = "genghis_khan"
	c.cost = 2; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "attack"
	c.archetype = "card.genghis_khan.steppe_terror.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 65; ea.base_value = 65; ea.target = "ALL"
	ea.damage_type = "blunt"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.APPLY_STATUS
	eb.value = 1; eb.base_value = 1; eb.target = "ALL"; eb.status_type = "poison"
	var ec := EffRes.new()
	ec.effect_type = EffRes.EffectType.APPLY_STATUS
	ec.value = 1; ec.base_value = 1; ec.target = "ALL"; ec.status_type = "weak"
	c.effects = [ea, eb, ec]; return c

static func _war_tribute() -> Resource:
	# 전쟁의 대가 — RARE, 2코, 공격, 약탈: DMG 100 ALL + DRAW 1
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.war_tribute.name"; c.owner_id = "genghis_khan"
	c.cost = 2; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "attack"
	c.archetype = "card.genghis_khan.war_tribute.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 100; ea.base_value = 100; ea.target = "ALL"
	ea.damage_type = "blunt"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.DRAW
	eb.value = 1; eb.base_value = 1
	c.effects = [ea, eb]; return c

static func _great_steppe_siege() -> Resource:
	# 대초원의 포위 — LEGENDARY, 2코, 공격, 약탈: DMG 80 ALL + DRAW 1, INNATE
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.great_steppe_siege.name"; c.owner_id = "genghis_khan"
	c.cost = 2; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.LEGENDARY; c.play_animation = "attack"
	c.archetype = "card.genghis_khan.great_steppe_siege.archetype"
	c.is_innate = true
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 80; ea.base_value = 80; ea.target = "ALL"
	ea.damage_type = "blunt"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.DRAW
	eb.value = 1; eb.base_value = 1
	c.effects = [ea, eb]; return c

