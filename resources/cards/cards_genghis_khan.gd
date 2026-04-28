# resources/cards/cards_genghis_khan.gd
# 칭기즈칸 카드 40장 (v1 15장 + v2 25장) — HP 1000 스케일 기준
# 아키타입: 기동(Rush) / 몽골 기병(Horde) / 약탈(Plunder)
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
		_cavalry_charge(), _scout(), _arrow_volley(),
		_ambush(), _supply_cut(), _encirclement(),
		_mingens_order(), _poison_arrow(), _steppe_storm(),
		_conquerors_ambition(), _long_march(), _great_khans_command(),
		_genghis_fury(),
		# v2 25장
		_light_cavalry_sprint(), _swift_raid(), _loot(),
		_victory_spoils(), _cavalry_assault(), _rear_disruption(),
		_cavalry_crossing(), _lightning_sprint(), _execution_ground(),
		_spoils_distribution(), _plunder_flame(), _rapid_fire(),
		_wind_legion(), _cavalry_encirclement(), _iron_breakthrough(),
		_desert_cavalry(), _territory_expansion(), _red_horizon(),
		_genghis_territory(), _submission(), _poison_arrow_rain(),
		_thousand_mile_army(), _steppe_terror(), _war_tribute(),
		_great_steppe_siege(),
		_steppe_lord(),
		# M6-5c 신규
		_soul_strike(), _berserk_blow(),
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
	c.effects = [e]; return c

static func _defend() -> Resource:
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.defend.name"; c.owner_id = "genghis_khan"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "idle"
	c.archetype = "card.genghis_khan.defend.archetype"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.BLOCK
	e.value = 80; e.base_value = 80; e.target = "SELF"
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
	c.effects = [e]; return c

static func _scout() -> Resource:
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.scout.name"; c.owner_id = "genghis_khan"
	c.cost = 0; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "idle"
	c.archetype = "card.genghis_khan.scout.archetype"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.DRAW
	e.value = 2; e.base_value = 2
	c.effects = [e]; return c

static func _arrow_volley() -> Resource:
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.arrow_volley.name"; c.owner_id = "genghis_khan"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "attack"
	c.archetype = "card.genghis_khan.arrow_volley.archetype"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.DAMAGE
	e.value = 55; e.base_value = 55; e.target = "ALL"
	c.effects = [e]; return c

static func _ambush() -> Resource:
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.ambush.name"; c.owner_id = "genghis_khan"
	c.cost = 0; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "attack"
	c.archetype = "card.genghis_khan.ambush.archetype"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.DAMAGE
	e.value = 70; e.base_value = 70; e.target = "SINGLE"
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
	eb.effect_type = EffRes.EffectType.ENERGY
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
	ea.value = 60; ea.base_value = 60; ea.target = "ALL"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.APPLY_STATUS
	eb.value = 1; eb.base_value = 1; eb.target = "ALL"; eb.status_type = "weak"
	c.effects = [ea, eb]; return c

static func _mingens_order() -> Resource:
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.mingens_order.name"; c.owner_id = "genghis_khan"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
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
	ea.value = 60; ea.base_value = 60; ea.target = "ALL"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.APPLY_STATUS
	eb.value = 2; eb.base_value = 2; eb.target = "ALL"; eb.status_type = "poison"
	c.effects = [ea, eb]; return c

static func _steppe_storm() -> Resource:
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.steppe_storm.name"; c.owner_id = "genghis_khan"
	c.cost = 2; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "attack"
	c.archetype = "card.genghis_khan.steppe_storm.archetype"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.DAMAGE
	e.value = 80; e.base_value = 80; e.target = "ALL"
	c.effects = [e]; return c

static func _conquerors_ambition() -> Resource:
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.conquerors_ambition.name"; c.owner_id = "genghis_khan"
	c.cost = 0; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "attack"
	c.archetype = "card.genghis_khan.conquerors_ambition.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 80; ea.base_value = 80; ea.target = "SINGLE"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.DRAW
	eb.value = 1; eb.base_value = 1
	c.effects = [ea, eb]; return c

static func _long_march() -> Resource:
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.long_march.name"; c.owner_id = "genghis_khan"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	c.archetype = "card.genghis_khan.long_march.archetype"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.BLOCK_PER_CARDS_PLAYED
	e.value = 30; e.base_value = 30
	c.effects = [e]; return c

static func _great_khans_command() -> Resource:
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.great_khans_command.name"; c.owner_id = "genghis_khan"
	c.cost = 2; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.LEGENDARY; c.play_animation = "idle"
	c.archetype = "card.genghis_khan.great_khans_command.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DRAW
	ea.value = 3; ea.base_value = 3
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.COST_ZERO_TURN
	eb.value = 0; eb.base_value = 0
	c.effects = [ea, eb]; return c

static func _genghis_fury() -> Resource:
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.genghis_fury.name"; c.owner_id = "genghis_khan"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.DIVINE; c.play_animation = "attack"
	c.archetype = "card.genghis_khan.genghis_fury.archetype"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.DAMAGE
	e.value = 60; e.base_value = 60; e.target = "ALL"; e.hit_count = 2
	c.effects = [e]; return c

# ─────────────────────────────────────────
# v2 풀 카드 25장
# ─────────────────────────────────────────

static func _light_cavalry_sprint() -> Resource:
	# 경기병 질주 — COMMON, 1코, 공격, 기동: DMG 80 + DRAW 1
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.light_cavalry_sprint.name"; c.owner_id = "genghis_khan"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "attack"
	c.archetype = "card.genghis_khan.light_cavalry_sprint.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 80; ea.base_value = 80; ea.target = "SINGLE"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.DRAW
	eb.value = 1; eb.base_value = 1
	c.effects = [ea, eb]; return c

static func _swift_raid() -> Resource:
	# 급습 — COMMON, 0코, 공격, 기동: DMG 60
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.swift_raid.name"; c.owner_id = "genghis_khan"
	c.cost = 0; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "attack"
	c.archetype = "card.genghis_khan.swift_raid.archetype"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.DAMAGE
	e.value = 60; e.base_value = 60; e.target = "SINGLE"
	c.effects = [e]; return c

static func _loot() -> Resource:
	# 노획 — COMMON, 1코, 기술, 약탈: DRAW 1 + ENERGY+1
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.loot.name"; c.owner_id = "genghis_khan"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "idle"
	c.archetype = "card.genghis_khan.loot.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DRAW
	ea.value = 1; ea.base_value = 1
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.ENERGY
	eb.value = 1; eb.base_value = 1
	c.effects = [ea, eb]; return c

static func _victory_spoils() -> Resource:
	# 승리의 전리품 — COMMON, 0코, 기술, 약탈: DRAW 2
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.victory_spoils.name"; c.owner_id = "genghis_khan"
	c.cost = 0; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "idle"
	c.archetype = "card.genghis_khan.victory_spoils.archetype"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.DRAW
	e.value = 2; e.base_value = 2
	c.effects = [e]; return c

static func _cavalry_assault() -> Resource:
	# 기병대 습격 — COMMON, 1코, 공격, 몽골 기병: DMG 50 ALL
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.cavalry_assault.name"; c.owner_id = "genghis_khan"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "attack"
	c.archetype = "card.genghis_khan.cavalry_assault.archetype"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.DAMAGE
	e.value = 50; e.base_value = 50; e.target = "ALL"
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
	ea.value = 45; ea.base_value = 45; ea.target = "ALL"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.APPLY_STATUS
	eb.value = 1; eb.base_value = 1; eb.target = "ALL"; eb.status_type = "vulnerable"
	c.effects = [ea, eb]; return c

static func _cavalry_crossing() -> Resource:
	# 기마 도하 — UNCOMMON, 1코, 기술, 기동: DRAW 2 + ENERGY+1
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.cavalry_crossing.name"; c.owner_id = "genghis_khan"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
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
	ea.value = 90; ea.base_value = 90; ea.target = "SINGLE"
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
	e.bonus_value = 200; e.base_bonus_value = 200
	e.status_type = "enemy_hp_below_30"; e.target = "SINGLE"
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
	ea.value = 2; ea.base_value = 2
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.HEAL_ALL
	eb.value = 50; eb.base_value = 50
	c.effects = [ea, eb]; return c

static func _plunder_flame() -> Resource:
	# 약탈의 불길 — UNCOMMON, 1코, 공격, 약탈: DMG 100 + DRAW 1
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.plunder_flame.name"; c.owner_id = "genghis_khan"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "attack"
	c.archetype = "card.genghis_khan.plunder_flame.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 100; ea.base_value = 100; ea.target = "SINGLE"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.DRAW
	eb.value = 1; eb.base_value = 1
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
	e.value = 40; e.base_value = 40; e.target = "ALL"; e.hit_count = 2
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
	ea.value = 55; ea.base_value = 55; ea.target = "ALL"
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
	ea.value = 60; ea.base_value = 60; ea.target = "ALL"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.BLOCK
	eb.value = 50; eb.base_value = 50; eb.target = "SELF"
	c.effects = [ea, eb]; return c

static func _iron_breakthrough() -> Resource:
	# 무간 돌파 — UNCOMMON, 2코, 공격, 몽골 기병: DMG 80 ALL + WEAK 1 ALL
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.iron_breakthrough.name"; c.owner_id = "genghis_khan"
	c.cost = 2; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "attack"
	c.archetype = "card.genghis_khan.iron_breakthrough.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 80; ea.base_value = 80; ea.target = "ALL"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.APPLY_STATUS
	eb.value = 1; eb.base_value = 1; eb.target = "ALL"; eb.status_type = "weak"
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
	e.value = 30; e.base_value = 30; e.target = "SINGLE"
	c.effects = [e]; return c

static func _territory_expansion() -> Resource:
	# 영토 확장 — RARE, 1코, 기술, 약탈: DRAW 2 + ENERGY+2
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.territory_expansion.name"; c.owner_id = "genghis_khan"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	c.archetype = "card.genghis_khan.territory_expansion.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DRAW
	ea.value = 2; ea.base_value = 2
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.ENERGY
	eb.value = 2; eb.base_value = 2
	c.effects = [ea, eb]; return c

static func _red_horizon() -> Resource:
	# 붉은 지평선 — RARE, 1코, 공격, 약탈: DMG 110 + 처치 시 DRAW 2
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.red_horizon.name"; c.owner_id = "genghis_khan"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "attack"
	c.archetype = "card.genghis_khan.red_horizon.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 110; ea.base_value = 110; ea.target = "SINGLE"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.ON_KILL_DRAW
	eb.value = 2; eb.base_value = 2
	c.effects = [ea, eb]; return c

static func _genghis_territory() -> Resource:
	# 징기스의 영토 — RARE, 2코, 기술, 약탈: DRAW 3 + ENERGY+1 + BLOCK_ALL 50
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.genghis_territory.name"; c.owner_id = "genghis_khan"
	c.cost = 2; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	c.archetype = "card.genghis_khan.genghis_territory.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DRAW
	ea.value = 3; ea.base_value = 3
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.ENERGY
	eb.value = 1; eb.base_value = 1
	var ec := EffRes.new()
	ec.effect_type = EffRes.EffectType.BLOCK_ALL
	ec.value = 50; ec.base_value = 50
	c.effects = [ea, eb, ec]; return c

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
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.APPLY_STATUS
	eb.value = 1; eb.base_value = 1; eb.target = "SINGLE"; eb.status_type = "weak"
	var ec := EffRes.new()
	ec.effect_type = EffRes.EffectType.APPLY_STATUS
	ec.value = 1; ec.base_value = 1; ec.target = "SINGLE"; ec.status_type = "weak"
	ec.condition = "enemy_hp_below_50"
	c.effects = [ea, eb, ec]; return c

static func _poison_arrow_rain() -> Resource:
	# 독 화살비 — RARE, 1코, 공격, 몽골 기병: DMG 55 ALL + POISON 3 ALL
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.poison_arrow_rain.name"; c.owner_id = "genghis_khan"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "attack"
	c.archetype = "card.genghis_khan.poison_arrow_rain.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 55; ea.base_value = 55; ea.target = "ALL"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.APPLY_STATUS
	eb.value = 3; eb.base_value = 3; eb.target = "ALL"; eb.status_type = "poison"
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
	c.effects = [e]; return c

static func _steppe_terror() -> Resource:
	# 대초원의 위협 — RARE, 1코, 공격, 몽골 기병: DMG 65 ALL + POISON 1 ALL + WEAK 1 ALL
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.steppe_terror.name"; c.owner_id = "genghis_khan"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "attack"
	c.archetype = "card.genghis_khan.steppe_terror.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 65; ea.base_value = 65; ea.target = "ALL"
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
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.DRAW
	eb.value = 1; eb.base_value = 1
	c.effects = [ea, eb]; return c

static func _great_steppe_siege() -> Resource:
	# 대초원의 포위 — LEGENDARY, 2코, 공격, 약탈: DMG 150 ALL + DRAW 3
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.great_steppe_siege.name"; c.owner_id = "genghis_khan"
	c.cost = 2; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.LEGENDARY; c.play_animation = "attack"
	c.archetype = "card.genghis_khan.great_steppe_siege.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 150; ea.base_value = 150; ea.target = "ALL"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.DRAW
	eb.value = 3; eb.base_value = 3
	c.effects = [ea, eb]; return c

# #41 초원의 군주 — RARE, cost 2, POWER, 약탈: 매 턴 드로우 +1
static func _steppe_lord() -> Resource:
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.steppe_lord.name"; c.owner_id = "genghis_khan"
	c.cost = 2; c.card_type = CardRes.CardType.POWER
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	c.archetype = "card.genghis_khan.steppe_lord.archetype"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.APPLY_STATUS
	e.status_type = "power.draw_per_turn"
	e.value = 1; e.base_value = 1
	c.effects = [e]; return c

static func _soul_strike() -> Resource:
	# 영혼 베기 — UNCOMMON, 1코, 기술: 다음 피해 효과 ×2
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.soul_strike.name"; c.owner_id = "genghis_khan"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	c.archetype = "card.genghis_khan.soul_strike.archetype"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.DOUBLE_NEXT_DAMAGE
	e.value = 0; e.base_value = 0
	c.effects = [e]; return c

static func _berserk_blow() -> Resource:
	# 광폭한 일격 — RARE, 0코, 공격: 남은 에너지 × 6 피해 + 에너지 소진 (placeholder)
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.berserk_blow.name"; c.owner_id = "genghis_khan"
	c.cost = 0; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "attack"
	c.archetype = "card.genghis_khan.berserk_blow.archetype"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.ENERGY_TO_DAMAGE
	e.value = 6; e.base_value = 6; e.target = "SINGLE"
	c.effects = [e]; return c
