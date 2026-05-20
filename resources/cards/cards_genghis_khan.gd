# resources/cards/cards_genghis_khan.gd
# 칭기즈칸 카드 — starter 10 + pool 30 (기동 12 / 몽골 기병 10 / 약탈 8)
# 기동: draw_per_turn + BLOCK_PER_CARDS_PLAYED 스파인
# 몽골 기병: summon_per_turn + token_bonus_dmg → DAMAGE_PER_TOKEN Payoff
# 약탈: draw_per_turn + ON_KILL_DRAW Payoff
const CardRes = preload("res://resources/card_resource.gd")
const EffRes  = preload("res://resources/effect_resource.gd")
const CommonRes = preload("res://resources/cards/cards_common.gd")

static func starter_deck() -> Array:
	var cards: Array = []
	for _i in range(4):
		cards.append(_strike())
	for _i in range(4):
		cards.append(_defend())
	cards.append(_horse_thrust())
	cards.append(_rider_call())
	cards.append(CommonRes.counter("genghis_khan"))
	return cards

static func pool() -> Array:
	return [
		# ── 기동 12 (F×4 / A×2 / P×3 / C×2 / Chaos×1) ──
		_quick_strike(), _sprint(), _horse_charge(), _desert_cavalry(),    # F
		_khans_fury(), _mobility_power(),                                   # A
		_endless_march(), _red_horizon(), _great_decree(),                  # P
		_signal_horn(), _flanking(),                                        # C
		_genghis_fury(),                                                    # Chaos
		# ── 몽골 기병 10 (F×3 / A×2 / P×2 / C×2 / Chaos×1) ──
		_cavalry_summon(), _arrow_shower(), _horde_advance(),               # F
		_war_horse_power(), _khans_banner(),                                # A
		_horde_volley(), _ten_thousand_army(),                              # P
		_cavalry_retreat(), _cavalry_encirclement(),                        # C
		_plunderers_instinct(),                                             # Chaos
		# ── 약탈 8 (F×3 / A×1 / P×1 / C×2 / Chaos×1) ──
		_plunder(), _hunters_bow(), _spoils_collection(),                   # F (노획 = 마킹)
		_executioners_bounty(),                                             # A
		_massacre_khan(),                                                   # P
		_khans_treasury(), _war_tribute(),                                  # C
		_khans_gamble(),                                                    # Chaos
		# speed buff long (기동 추가)
		_cavalry_charge_speed(),
		]

static func _cavalry_charge_speed() -> Resource:
	# 기마 돌격 — RARE, 1코, SKILL, 기동: 본인 speed +6 (3턴) — 나폴레옹 전격 진군 (+5/3턴) 의 RARE 상위
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.cavalry_charge_speed.name"; c.owner_id = "genghis_khan"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	c.archetype = ["card.genghis_khan.horse_charge.archetype"]  # 기동
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.BUFF_SPEED
	e.value = 6; e.base_value = 6
	e.bonus_value = 3; e.base_bonus_value = 3
	e.target = "SELF"
	c.effects = [e]; return c

# ─────────────────────────────────────────
# 시작덱 (4종)
# ─────────────────────────────────────────

static func _strike() -> Resource:
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.strike.name"; c.owner_id = "genghis_khan"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "attack"
	c.archetype = ["card.genghis_khan.strike.archetype"]
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.DAMAGE
	e.value = 100; e.base_value = 100; e.target = "SINGLE"; e.damage_type = "slash"
	c.effects = [e]; return c

static func _defend() -> Resource:
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.defend.name"; c.owner_id = "genghis_khan"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "idle"
	c.archetype = ["card.genghis_khan.defend.archetype"]
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.BLOCK
	e.value = 125; e.base_value = 125; e.target = "SELF"
	c.effects = [e]; return c

static func _horse_thrust() -> Resource:
	# [starter] 기마 돌격 — COMMON, 1코, ATTACK, 기동: DMG 60 + STRENGTH 1 SELF
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.horse_thrust.name"; c.owner_id = "genghis_khan"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "attack"
	c.archetype = ["card.genghis_khan.horse_thrust.archetype"]
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 60; ea.base_value = 60; ea.target = "SINGLE"; ea.damage_type = "slash"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.APPLY_STATUS
	eb.status_type = "strength"; eb.value = 1; eb.base_value = 1; eb.target = "SELF"
	c.effects = [ea, eb]; return c

static func _rider_call() -> Resource:
	# [starter] 기마 소환 — COMMON, 1코, SKILL, 몽골 기병: SUMMON_TOKEN 1
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.rider_call.name"; c.owner_id = "genghis_khan"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "idle"
	c.archetype = ["card.genghis_khan.rider_call.archetype"]
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.SUMMON_TOKEN
	e.value = 1; e.base_value = 1
	c.effects = [e]; return c

# ─────────────────────────────────────────
# 기동 12 — draw_per_turn + BLOCK_PER_CARDS_PLAYED 스파인
# ─────────────────────────────────────────

static func _quick_strike() -> Resource:
	# [F] 급습 — COMMON, 0코, ATTACK: DMG 20
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.swift_raid.name"; c.owner_id = "genghis_khan"
	c.cost = 0; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "attack"
	c.archetype = ["card.genghis_khan.swift_raid.archetype"]
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.DAMAGE
	e.value = 20; e.base_value = 20; e.target = "SINGLE"; e.damage_type = "slash"
	c.effects = [e]; return c

static func _sprint() -> Resource:
	# [F] 기마 도하 — UNCOMMON, 2코, SKILL: DRAW 2 + ENERGY 1
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.cavalry_crossing.name"; c.owner_id = "genghis_khan"
	c.cost = 2; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	c.archetype = ["card.genghis_khan.cavalry_crossing.archetype"]
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DRAW; ea.value = 2; ea.base_value = 2
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.ENERGY; eb.value = 1; eb.base_value = 1
	c.effects = [ea, eb]; return c

static func _horse_charge() -> Resource:
	# [F] 돌격 — UNCOMMON, 1코, ATTACK: DMG 50 + DRAW 1
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.horse_charge.name"; c.owner_id = "genghis_khan"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "attack"
	c.archetype = ["card.genghis_khan.horse_charge.archetype"]
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 50; ea.base_value = 50; ea.target = "SINGLE"; ea.damage_type = "blunt"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.DRAW; eb.value = 1; eb.base_value = 1
	c.effects = [ea, eb]; return c

static func _desert_cavalry() -> Resource:
	# [F] 사막 기마 — UNCOMMON, 1코, ATTACK: 이번 턴 드로우 수 × DMG 25
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.desert_cavalry.name"; c.owner_id = "genghis_khan"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "attack"
	c.archetype = ["card.genghis_khan.desert_cavalry.archetype"]
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.PER_DRAW_DMG
	e.value = 25; e.base_value = 25; e.target = "SINGLE"; e.damage_type = "blunt"
	c.effects = [e]; return c

static func _khans_fury() -> Resource:
	# [A] 칸의 분노 — UNCOMMON, 1코, POWER: 매 턴 시작 시 DRAW +1
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.khans_fury.name"; c.owner_id = "genghis_khan"
	c.cost = 2; c.card_type = CardRes.CardType.POWER
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	c.archetype = ["card.genghis_khan.khans_fury.archetype"]
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.APPLY_STATUS
	e.status_type = "power.draw_per_turn"; e.value = 1; e.base_value = 1; e.target = "SELF"
	var es := EffRes.new()
	es.effect_type = EffRes.EffectType.SACRIFICE_HP; es.value = 10; es.base_value = 10
	c.effects = [e, es]; return c

static func _mobility_power() -> Resource:
	# [A] 기동의 권능 — RARE, 1코, POWER: 매 턴 시작 시 BLOCK +15
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.mobility_power.name"; c.owner_id = "genghis_khan"
	c.cost = 1; c.card_type = CardRes.CardType.POWER
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	c.archetype = ["card.genghis_khan.mobility_power.archetype"]
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.APPLY_STATUS
	e.status_type = "power.block_per_turn"; e.value = 55; e.base_value = 55; e.target = "SELF"
	c.effects = [e]; return c

static func _endless_march() -> Resource:
	# [P] 만리 원정 — RARE, 2코, SKILL: 이번 턴 사용 카드 수 × BLOCK 20
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.long_march.name"; c.owner_id = "genghis_khan"
	c.cost = 2; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	c.archetype = ["card.genghis_khan.long_march.archetype"]
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.BLOCK_PER_CARDS_PLAYED
	e.value = 75; e.base_value = 75
	c.effects = [e]; return c

static func _red_horizon() -> Resource:
	# [P] 붉은 지평선 — LEGENDARY, 1코, ATTACK EXHAUST: DMG 110 + ON_KILL_DRAW 2
	# 희귀도 보강: 약탈 아키타입 처치-드로우 핵심 카드 — 전설 승급
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.red_horizon.name"; c.owner_id = "genghis_khan"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.LEGENDARY; c.play_animation = "attack"
	c.archetype = ["card.genghis_khan.red_horizon.archetype", "card.genghis_khan.loot.archetype"]
	c.is_exhaust = true
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 110; ea.base_value = 110; ea.target = "SINGLE"; ea.damage_type = "slash"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.ON_KILL_DRAW
	eb.value = 2; eb.base_value = 2
	c.effects = [ea, eb]; return c

static func _great_decree() -> Resource:
	# [P] 대칸의 명령 — LEGENDARY, 2코, SKILL: 이번 턴 남은 카드 비용 0
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.great_khans_command.name"; c.owner_id = "genghis_khan"
	c.cost = 2; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.LEGENDARY; c.play_animation = "idle"
	c.archetype = ["card.genghis_khan.great_khans_command.archetype"]
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.COST_ZERO_TURN
	c.effects = [e]; return c

static func _signal_horn() -> Resource:
	# [C] 신호 나팔 — UNCOMMON, 2코, SKILL: DRAW 2 + GAIN_MORALE 1
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.signal_horn.name"; c.owner_id = "genghis_khan"
	c.cost = 2; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	c.archetype = ["card.genghis_khan.signal_horn.archetype"]
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DRAW; ea.value = 2; ea.base_value = 2
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.GAIN_MORALE; eb.value = 1; eb.base_value = 1
	c.effects = [ea, eb]; return c

static func _flanking() -> Resource:
	# [C] 측면 우회 — UNCOMMON, 1코, ATTACK: DMG 35 ALL + VULN 1 ALL
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.flanking.name"; c.owner_id = "genghis_khan"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "attack"
	c.archetype = ["card.genghis_khan.flanking.archetype"]
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 35; ea.base_value = 35; ea.target = "ALL"; ea.damage_type = "blunt"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.APPLY_STATUS
	eb.status_type = "vulnerable"; eb.value = 1; eb.base_value = 1; eb.target = "ALL"
	c.effects = [ea, eb]; return c

static func _genghis_fury() -> Resource:
	# [Chaos] 징기스의 분노 — RARE, 1코, ATTACK EXHAUST: DMG 120 ALL blunt
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.genghis_fury.name"; c.owner_id = "genghis_khan"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "attack"
	c.archetype = ["card.genghis_khan.genghis_fury.archetype"]
	c.is_exhaust = true
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.DAMAGE
	e.hit_count = 1; e.value = 120; e.base_value = 120; e.target = "ALL"; e.damage_type = "blunt"
	c.effects = [e]; return c

# ─────────────────────────────────────────
# 몽골 기병 10 — summon_per_turn + token_bonus_dmg 스파인
# ─────────────────────────────────────────

static func _cavalry_summon() -> Resource:
	# [F] 기병 소집 — COMMON, 1코, SKILL: SUMMON_TOKEN 1 + BLOCK 20 SELF
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.cavalry_summon.name"; c.owner_id = "genghis_khan"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "idle"
	c.archetype = ["card.genghis_khan.cavalry_summon.archetype"]
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.SUMMON_TOKEN; ea.value = 1; ea.base_value = 1
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.BLOCK; eb.value = 20; eb.base_value = 20
	c.effects = [ea, eb]; return c

static func _arrow_shower() -> Resource:
	# [F] 화살 세례 — COMMON, 1코, ATTACK: DMG 60 ALL
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.arrow_volley.name"; c.owner_id = "genghis_khan"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "attack"
	c.archetype = ["card.genghis_khan.arrow_volley.archetype"]
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.DAMAGE
	e.value = 60; e.base_value = 60; e.target = "ALL"; e.damage_type = "projectile"
	c.effects = [e]; return c

static func _horde_advance() -> Resource:
	# [F] 호드 진군 — UNCOMMON, 1코, ATTACK: DMG 25 ALL + SUMMON_TOKEN 1
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.horde_advance.name"; c.owner_id = "genghis_khan"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "attack"
	c.archetype = ["card.genghis_khan.horde_advance.archetype"]
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 25; ea.base_value = 25; ea.target = "ALL"; ea.damage_type = "blunt"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.SUMMON_TOKEN; eb.value = 1; eb.base_value = 1
	c.effects = [ea, eb]; return c

static func _war_horse_power() -> Resource:
	# [A] 군마의 권능 — DIVINE, 2코, POWER: 매 턴 시작 시 SUMMON_TOKEN 1
	# 희귀도 보강: 몽골 기병 토큰 자동생성 엔진 — 칭기즈칸 유일 DIVINE 카드로 승급
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.war_horse_power.name"; c.owner_id = "genghis_khan"
	c.cost = 2; c.card_type = CardRes.CardType.POWER
	c.rarity = CardRes.Rarity.DIVINE; c.play_animation = "idle"
	c.archetype = ["card.genghis_khan.war_horse_power.archetype"]
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.APPLY_STATUS
	e.status_type = "power.summon_per_turn"; e.value = 1; e.base_value = 1; e.target = "SELF"
	var es := EffRes.new()
	es.effect_type = EffRes.EffectType.SACRIFICE_HP; es.value = 5; es.base_value = 5
	c.effects = [e, es]; return c

static func _khans_banner() -> Resource:
	# [A] 칸의 깃발 — RARE, 1코, POWER: 토큰 1개당 피해 +8 (DAMAGE_PER_TOKEN 보너스)
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.khans_banner.name"; c.owner_id = "genghis_khan"
	c.cost = 1; c.card_type = CardRes.CardType.POWER
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	c.archetype = ["card.genghis_khan.khans_banner.archetype"]
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.APPLY_STATUS
	e.status_type = "power.token_bonus_dmg"; e.value = 8; e.base_value = 8; e.target = "SELF"
	c.effects = [e]; return c

static func _horde_volley() -> Resource:
	# [P] 토큰 일제 사격 — LEGENDARY, 2코, ATTACK: 살아있는 토큰 수 × DMG 40 ALL
	# 희귀도 보강: 몽골 기병 아키타입의 토큰 정산 핵심 카드 — 전설 승급
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.horde_volley.name"; c.owner_id = "genghis_khan"
	c.cost = 2; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.LEGENDARY; c.play_animation = "attack"
	c.archetype = ["card.genghis_khan.horde_volley.archetype"]
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.DAMAGE_PER_TOKEN
	e.value = 50; e.base_value = 50; e.target = "ALL"; e.damage_type = "projectile"
	c.effects = [e]; return c

static func _ten_thousand_army() -> Resource:
	# [P] 천만의 군세 — LEGENDARY, 2코, SKILL: SUMMON_TOKEN 3 + BLOCK 20
	# 희귀도 보강: 몽골 기병 토큰 대량 전개 카드 — 전설 승급
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.ten_thousand_army.name"; c.owner_id = "genghis_khan"
	c.cost = 2; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.LEGENDARY; c.play_animation = "idle"
	c.archetype = ["card.genghis_khan.ten_thousand_army.archetype"]
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.SUMMON_TOKEN; ea.value = 3; ea.base_value = 3
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.BLOCK; eb.value = 20; eb.base_value = 20
	c.effects = [ea, eb]; return c

static func _cavalry_retreat() -> Resource:
	# [C] 기병 후퇴 — UNCOMMON, 1코, SKILL: BLOCK_ALL 85
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.cavalry_retreat.name"; c.owner_id = "genghis_khan"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	c.archetype = ["card.genghis_khan.cavalry_retreat.archetype"]
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.BLOCK_ALL; e.value = 85; e.base_value = 85
	c.effects = [e]; return c

static func _cavalry_encirclement() -> Resource:
	# [C] 기병 포위망 — UNCOMMON, 1코, SKILL: BLOCK_ALL 35 + SUMMON_TOKEN 1 (몽골 기병 전열 보호)
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.cavalry_encirclement.name"; c.owner_id = "genghis_khan"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	c.archetype = ["card.genghis_khan.cavalry_encirclement.archetype"]
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.BLOCK_ALL; ea.value = 35; ea.base_value = 35
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.SUMMON_TOKEN; eb.value = 1; eb.base_value = 1
	c.effects = [ea, eb]; return c

static func _plunderers_instinct() -> Resource:
	# [Chaos] 약탈자의 본능 — RARE, 0코, ATTACK EXHAUST: 랜덤 적 4회 × DMG 40
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.plunderers_instinct.name"; c.owner_id = "genghis_khan"
	c.cost = 0; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "attack"
	c.archetype = ["card.genghis_khan.plunderers_instinct.archetype"]
	c.is_exhaust = true
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.MULTI_HIT_RANDOM
	e.hit_count = 4; e.value = 40; e.base_value = 40; e.damage_type = "blunt"
	c.effects = [e]; return c

# ─────────────────────────────────────────
# 약탈 8 — draw_per_turn + ON_KILL_DRAW 스파인
# ─────────────────────────────────────────

static func _plunder() -> Resource:
	# [F] 노획 — COMMON, 1코, SKILL: 적 1마리 마킹 + DRAW 1
	# 마킹된 적: 모든 영웅 공격 치명타 확률 +30%
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.loot.name"; c.owner_id = "genghis_khan"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "idle"
	c.archetype = ["card.genghis_khan.loot.archetype"]
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.MARK_ENEMY
	ea.target = "SINGLE"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.DRAW; eb.value = 1; eb.base_value = 1
	c.effects = [ea, eb]; return c

static func _hunters_bow() -> Resource:
	# [F] 처형대 — UNCOMMON, 1코, ATTACK: 적 HP 30% 이하 시 DMG 170, 아닐 때 DMG 80
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.execution_ground.name"; c.owner_id = "genghis_khan"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "attack"
	c.archetype = ["card.genghis_khan.execution_ground.archetype"]
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.CONDITIONAL_DMG
	e.value = 80; e.base_value = 80; e.bonus_value = 170; e.base_bonus_value = 170
	e.status_type = "enemy_hp_below_30"; e.target = "SINGLE"; e.damage_type = "slash"
	c.effects = [e]; return c

static func _spoils_collection() -> Resource:
	# [F] 전리품 배분 — UNCOMMON, 1코, SKILL: DRAW 1 + HEAL_ALL 15
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.spoils_distribution.name"; c.owner_id = "genghis_khan"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	c.archetype = ["card.genghis_khan.spoils_distribution.archetype"]
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DRAW; ea.value = 1; ea.base_value = 1
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.HEAL_ALL; eb.value = 15; eb.base_value = 15
	c.effects = [ea, eb]; return c

static func _executioners_bounty() -> Resource:
	# [A] 처형 현상금 — RARE, 1코, POWER: 적 처치마다 에너지 +1
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.executioners_bounty.name"; c.owner_id = "genghis_khan"
	c.cost = 1; c.card_type = CardRes.CardType.POWER
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	c.archetype = ["card.genghis_khan.executioners_bounty.archetype"]
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.APPLY_STATUS
	e.status_type = "power.on_kill_energy"; e.value = 1; e.base_value = 1; e.target = "SELF"
	c.effects = [e]; return c

static func _massacre_khan() -> Resource:
	# [P] 학살의 칸 — LEGENDARY, 2코, ATTACK: DMG 160 + ON_KILL_DRAW 2
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.massacre_khan.name"; c.owner_id = "genghis_khan"
	c.cost = 2; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.LEGENDARY; c.play_animation = "attack"
	c.archetype = ["card.genghis_khan.massacre_khan.archetype"]
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 160; ea.base_value = 160; ea.target = "SINGLE"; ea.damage_type = "slash"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.ON_KILL_DRAW; eb.value = 2; eb.base_value = 2
	c.effects = [ea, eb]; return c

static func _khans_treasury() -> Resource:
	# [C] 칸의 보고 — COMMON, 1코, SKILL: GAIN_MORALE 2 + BLOCK 30 SELF
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.khans_treasury.name"; c.owner_id = "genghis_khan"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "idle"
	c.archetype = ["card.genghis_khan.khans_treasury.archetype"]
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.GAIN_MORALE; ea.value = 2; ea.base_value = 2
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.BLOCK; eb.value = 30; eb.base_value = 30; eb.target = "SELF"
	c.effects = [ea, eb]; return c

static func _war_tribute() -> Resource:
	# [C] 전쟁의 대가 — UNCOMMON, 2코, ATTACK: DMG 70 ALL + DRAW 1
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.war_tribute.name"; c.owner_id = "genghis_khan"
	c.cost = 2; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "attack"
	c.archetype = ["card.genghis_khan.war_tribute.archetype"]
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 70; ea.base_value = 70; ea.target = "ALL"; ea.damage_type = "blunt"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.DRAW; eb.value = 1; eb.base_value = 1
	c.effects = [ea, eb]; return c

static func _khans_gamble() -> Resource:
	# [Chaos] 칸의 도박 — RARE, 2코, SKILL EXHAUST: DRAW 3 + ENERGY 1
	var c := CardRes.new()
	c.card_name = "card.genghis_khan.khans_gamble.name"; c.owner_id = "genghis_khan"
	c.cost = 2; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	c.archetype = ["card.genghis_khan.khans_gamble.archetype"]
	c.is_exhaust = true
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DRAW; ea.value = 3; ea.base_value = 3
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.ENERGY; eb.value = 1; eb.base_value = 1
	c.effects = [ea, eb]; return c
