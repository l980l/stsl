# resources/cards/cards_joan_of_arc.gd
# 잔다르크 카드 — starter 10 + pool 30 (신성 11 / 부활 10 / 순교 9)
# 신성: strength_player + echo_next_attack Amplifier → 강타 페이오프
# 부활: draw_per_turn + heal_team_per_turn Amplifier → REVIVE Payoff
# 순교: sacrifice_bank Amplifier → SACRIFICE_PAYOFF spine
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
		# ── 신성 11 (F×4 / A×2 / P×2 / C×2 / Chaos×1) ──
		_holy_bolt(), _orleans_charge(), _holy_wave(), _holy_fury(),   # F
		_crusaders_faith(), _divine_echo(),                             # A
		_archangels_wrath(), _divine_punishment(),                      # P
		_crusade(), _holy_judge(),                                      # C
		_oracle_light(),                                                # Chaos
		# ── 부활 10 (F×3 / A×2 / P×2 / C×2 / Chaos×1) ──
		_holy_touch(), _communion(), _hymn(),                           # F
		_guardian_angel(), _angel_wings(),                              # A
		_miracle_revive(), _joan_return(),                              # P
		_holy_purification(), _knights_oath(),                          # C
		_flag_of_orleans(),                                             # Chaos
		# ── 순교 9 (F×3 / A×2 / P×2 / C×1 / Chaos×1) ──
		_martyrs_will(), _altar_flame(), _martyrdom_steps(),            # F
		_passion_power(), _martyr_strength(),                           # A
		_saints_revelation(), _martyrs_light(),                         # P
		_last_shield(),                                                 # C
		_saints_flame(),                                                # Chaos
		# speed buff ally (축복 추가)
		_grace_of_spirit(),
	]

static func _grace_of_spirit() -> Resource:
	# 성령의 가호 — UNCOMMON, 1코, SKILL, 축복: 파티원 1명 speed +4 (3턴)
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.grace_of_spirit.name"; c.owner_id = "joan_of_arc"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	c.archetype = ["card.joan_of_arc.holy_touch.archetype"]  # 축복
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.BUFF_SPEED
	e.value = 4; e.base_value = 4
	e.bonus_value = 3; e.base_bonus_value = 3
	e.target = "ALLY"
	c.effects = [e]; return c

# ─────────────────────────────────────────
# 시작덱 (4종)
# ─────────────────────────────────────────

static func _strike() -> Resource:
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.strike.name"; c.owner_id = "joan_of_arc"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "attack"
	c.archetype = ["card.joan_of_arc.strike.archetype"]
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.DAMAGE
	e.value = 100; e.base_value = 100; e.target = "SINGLE"
	e.damage_type = "blunt"  # strike — 일반 둔기 베기
	c.effects = [e]; return c

static func _defend() -> Resource:
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.defend.name"; c.owner_id = "joan_of_arc"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "idle"
	c.archetype = ["card.joan_of_arc.defend.archetype"]
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.BLOCK
	e.value = 125; e.base_value = 125; e.target = "SELF"
	c.effects = [e]; return c

static func _holy_smite() -> Resource:
	# COMMON, 1코, ATTACK: DMG 80 divine + HEAL 20 SELF (시작덱 신성 F)
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.holy_smite.name"; c.owner_id = "joan_of_arc"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "attack"
	c.archetype = ["card.joan_of_arc.holy_smite.archetype"]
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 80; ea.base_value = 80; ea.target = "SINGLE"
	ea.damage_type = "holy_strike"  # holy_smite — 성스러운 일격
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.HEAL
	eb.value = 20; eb.base_value = 20; eb.target = "SELF"
	c.effects = [ea, eb]; return c

static func _shield_prayer() -> Resource:
	# COMMON, 1코, SKILL: BLOCK 80 SELF + HEAL 20 SELF (시작덱 부활 F)
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.shield_prayer.name"; c.owner_id = "joan_of_arc"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "idle"
	c.archetype = ["card.joan_of_arc.shield_prayer.archetype"]
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.BLOCK
	ea.value = 80; ea.base_value = 80; ea.target = "SELF"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.HEAL
	eb.value = 20; eb.base_value = 20; eb.target = "SELF"
	c.effects = [ea, eb]; return c

# ─────────────────────────────────────────
# 신성 11 — strength + echo 스파인
# ─────────────────────────────────────────

static func _holy_bolt() -> Resource:
	# [F] 신성 화살 — COMMON, 1코, ATTACK: DMG 70 divine + VULNERABLE 1
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.holy_bolt.name"; c.owner_id = "joan_of_arc"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "attack"
	c.archetype = ["card.joan_of_arc.holy_bolt.archetype"]
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 70; ea.base_value = 70; ea.target = "SINGLE"
	ea.damage_type = "holy_bolt"  # 빛의 화살
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.APPLY_STATUS
	eb.status_type = "vulnerable"; eb.value = 1; eb.base_value = 1; eb.target = "SINGLE"
	c.effects = [ea, eb]; return c

static func _orleans_charge() -> Resource:
	# [F] 오를레앙의 돌격 — UNCOMMON, 1코, ATTACK: DMG 110 divine SINGLE
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.orleans_charge.name"; c.owner_id = "joan_of_arc"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "attack"
	c.archetype = ["card.joan_of_arc.orleans_charge.archetype"]
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.DAMAGE
	e.value = 110; e.base_value = 110; e.target = "SINGLE"
	e.damage_type = "holy_blunt"  # orleans_charge — 성스러운 둔기
	c.effects = [e]; return c

static func _holy_wave() -> Resource:
	# [F] 신성의 물결 — UNCOMMON, 1코, ATTACK: DMG 65 ALL divine
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.holy_wave.name"; c.owner_id = "joan_of_arc"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "attack"
	c.archetype = ["card.joan_of_arc.holy_wave.archetype"]
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.DAMAGE
	e.value = 65; e.base_value = 65; e.target = "ALL"
	e.damage_type = "holy_strike"
	c.effects = [e]; return c

static func _holy_fury() -> Resource:
	# [F] 성스러운 분노 — RARE, 2코, ATTACK: DMG 140 ALL divine (강력 Foundation)
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.holy_fury.name"; c.owner_id = "joan_of_arc"
	c.cost = 2; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "attack"
	c.archetype = ["card.joan_of_arc.holy_fury.archetype"]
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.DAMAGE
	e.value = 140; e.base_value = 140; e.target = "ALL"
	e.damage_type = "holy_blunt"
	c.effects = [e]; return c

static func _crusaders_faith() -> Resource:
	# [A] 십자군의 신앙 — UNCOMMON, 1코, POWER: 영웅 strength +2 (매 공격 +2)
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.crusaders_faith.name"; c.owner_id = "joan_of_arc"
	c.cost = 1; c.card_type = CardRes.CardType.POWER
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	c.archetype = ["card.joan_of_arc.crusaders_faith.archetype"]
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.APPLY_STATUS
	e.status_type = "power.strength_player"; e.value = 2; e.base_value = 2; e.target = "SELF"
	var es := EffRes.new()
	es.effect_type = EffRes.EffectType.HEAL; es.value = 1; es.base_value = 1; es.target = "SELF"
	c.effects = [e, es]; return c

static func _divine_echo() -> Resource:
	# [A] 신의 가호 — RARE, 2코, POWER: 매 턴 방어도 15 + 매 턴 전체 회복 5
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.divine_echo.name"; c.owner_id = "joan_of_arc"
	c.cost = 2; c.card_type = CardRes.CardType.POWER
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	c.archetype = ["card.joan_of_arc.divine_echo.archetype", "card.joan_of_arc.holy_touch.archetype"]
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.APPLY_STATUS
	ea.status_type = "power.block_per_turn"; ea.value = 50; ea.base_value = 50; ea.target = "SELF"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.APPLY_STATUS
	eb.status_type = "power.heal_team_per_turn"; eb.value = 20; eb.base_value = 20; eb.target = "SELF"
	c.effects = [ea, eb]; return c

static func _archangels_wrath() -> Resource:
	# [P] 대천사의 분노 — RARE, 2코, ATTACK: DMG 120 ALL divine + HEAL_ALL 15
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.archangels_wrath.name"; c.owner_id = "joan_of_arc"
	c.cost = 2; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "attack"
	c.archetype = ["card.joan_of_arc.archangels_wrath.archetype", "card.joan_of_arc.holy_touch.archetype"]
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 120; ea.base_value = 120; ea.target = "ALL"
	ea.damage_type = "holy_blunt"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.HEAL_ALL
	eb.value = 15; eb.base_value = 15
	c.effects = [ea, eb]; return c

static func _divine_punishment() -> Resource:
	# [P] 신성한 징벌 — LEGENDARY, 2코, ATTACK: SAC 100 + DMG 120 ALL + WEAK 2 ALL
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.divine_punishment.name"; c.owner_id = "joan_of_arc"
	c.cost = 2; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.LEGENDARY; c.play_animation = "attack"
	c.archetype = ["card.joan_of_arc.divine_punishment.archetype", "card.joan_of_arc.martyrs_will.archetype"]
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.SACRIFICE_HP
	ea.value = 100; ea.base_value = 100
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.DAMAGE
	eb.value = 120; eb.base_value = 120; eb.target = "ALL"
	eb.damage_type = "holy_strike"  # divine_punishment — 성스러운 일격
	var ec := EffRes.new()
	ec.effect_type = EffRes.EffectType.APPLY_STATUS
	ec.status_type = "weak"; ec.value = 2; ec.base_value = 2; ec.target = "ALL"
	c.effects = [ea, eb, ec]; return c

static func _crusade() -> Resource:
	# [C] 십자군 — UNCOMMON, 2코, ATTACK: DMG 82 ALL + VULNERABLE 1 ALL
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.crusade.name"; c.owner_id = "joan_of_arc"
	c.cost = 2; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "attack"
	c.archetype = ["card.joan_of_arc.crusade.archetype"]
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 82; ea.base_value = 82; ea.target = "ALL"
	ea.damage_type = "holy_strike"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.APPLY_STATUS
	eb.status_type = "vulnerable"; eb.value = 1; eb.base_value = 1; eb.target = "ALL"
	c.effects = [ea, eb]; return c

static func _holy_judge() -> Resource:
	# [C] 신성 심판 — RARE, 2코, ATTACK: DMG 100 + WEAK 2 + VULNERABLE 2 SINGLE
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.holy_judge.name"; c.owner_id = "joan_of_arc"
	c.cost = 2; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "attack"
	c.archetype = ["card.joan_of_arc.holy_judge.archetype"]
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 100; ea.base_value = 100; ea.target = "SINGLE"
	ea.damage_type = "holy_strike"  # holy_judge — 성스러운 일격
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.APPLY_STATUS
	eb.status_type = "weak"; eb.value = 2; eb.base_value = 2; eb.target = "SINGLE"
	var ec := EffRes.new()
	ec.effect_type = EffRes.EffectType.APPLY_STATUS
	ec.status_type = "vulnerable"; ec.value = 2; ec.base_value = 2; ec.target = "SINGLE"
	c.effects = [ea, eb, ec]; return c

static func _oracle_light() -> Resource:
	# [Chaos] 신탁의 빛 — RARE, 1코, SKILL EXHAUST: SAC 60 + DRAW 3 (무작위 운명 카드 3장)
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.oracle_light.name"; c.owner_id = "joan_of_arc"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	c.archetype = ["card.joan_of_arc.oracle_light.archetype", "card.joan_of_arc.martyrs_will.archetype"]
	c.is_exhaust = true
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.SACRIFICE_HP
	ea.value = 60; ea.base_value = 60; ea.target = "SELF"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.DRAW
	eb.value = 3; eb.base_value = 3
	c.effects = [ea, eb]; return c

# ─────────────────────────────────────────
# 부활 10 — draw_per_turn + heal_team_per_turn 스파인
# ─────────────────────────────────────────

static func _holy_touch() -> Resource:
	# [F] 성녀의 손길 — COMMON, 1코, SKILL: HEAL 77 SELF
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.holy_touch.name"; c.owner_id = "joan_of_arc"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "idle"
	c.archetype = ["card.joan_of_arc.holy_touch.archetype"]
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.HEAL
	e.value = 77; e.base_value = 77; e.target = "SELF"
	c.effects = [e]; return c

static func _communion() -> Resource:
	# [F] 성찬 — COMMON, 1코, SKILL: HEAL 20 SELF + DRAW 1
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.communion.name"; c.owner_id = "joan_of_arc"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "idle"
	c.archetype = ["card.joan_of_arc.communion.archetype"]
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.HEAL
	ea.value = 20; ea.base_value = 20; ea.target = "SELF"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.DRAW
	eb.value = 1; eb.base_value = 1
	c.effects = [ea, eb]; return c

static func _hymn() -> Resource:
	# [F] 성가 — UNCOMMON, 1코, SKILL: HEAL_ALL 55
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.hymn.name"; c.owner_id = "joan_of_arc"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	c.archetype = ["card.joan_of_arc.hymn.archetype"]
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.HEAL_ALL
	e.value = 55; e.base_value = 55
	c.effects = [e]; return c

static func _guardian_angel() -> Resource:
	# [A] 수호 천사 — RARE, 1코, POWER: 매 턴 시작 시 팀 전체 회복 10
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.guardian_angel.name"; c.owner_id = "joan_of_arc"
	c.cost = 1; c.card_type = CardRes.CardType.POWER
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	c.archetype = ["card.joan_of_arc.guardian_angel.archetype", "card.joan_of_arc.holy_touch.archetype"]
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.APPLY_STATUS
	e.status_type = "power.heal_team_per_turn"; e.value = 20; e.base_value = 20; e.target = "SELF"
	c.effects = [e]; return c

static func _angel_wings() -> Resource:
	# [A] 천사의 날개 — RARE, 2코, POWER: 매 턴 시작 시 팀 전체 회복 20
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.angel_wings.name"; c.owner_id = "joan_of_arc"
	c.cost = 2; c.card_type = CardRes.CardType.POWER
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	c.archetype = ["card.joan_of_arc.angel_wings.archetype"]
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.APPLY_STATUS
	e.status_type = "power.heal_team_per_turn"; e.value = 40; e.base_value = 40; e.target = "SELF"
	c.effects = [e]; return c

static func _miracle_revive() -> Resource:
	# [P] 기적의 부활 — RARE, 2코, SKILL EXHAUST: REVIVE 30%
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.miracle_revive.name"; c.owner_id = "joan_of_arc"
	c.cost = 2; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	c.archetype = ["card.joan_of_arc.miracle_revive.archetype"]
	c.is_exhaust = true
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.REVIVE
	e.value = 30; e.base_value = 30
	c.effects = [e]; return c

static func _joan_return() -> Resource:
	# [P] 잔 다르크의 귀환 — LEGENDARY, 3코, SKILL: REVIVE 100% + HEAL_ALL 30
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.joan_return.name"; c.owner_id = "joan_of_arc"
	c.cost = 3; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.LEGENDARY; c.play_animation = "idle"
	c.archetype = ["card.joan_of_arc.joan_return.archetype"]
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.REVIVE
	ea.value = 100; ea.base_value = 100
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.HEAL_ALL
	eb.value = 30; eb.base_value = 30
	c.effects = [ea, eb]; return c

static func _holy_purification() -> Resource:
	# [C] 신성한 정화 — UNCOMMON, 1코, SKILL: PURGE_STATUS ALL + HEAL_ALL 25
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.holy_purification.name"; c.owner_id = "joan_of_arc"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	c.archetype = ["card.joan_of_arc.holy_purification.archetype"]
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.PURGE_STATUS
	ea.target = "ALL"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.HEAL_ALL
	eb.value = 25; eb.base_value = 25
	c.effects = [ea, eb]; return c

static func _knights_oath() -> Resource:
	# [C] 기사단의 맹세 — UNCOMMON, 1코, SKILL: 단일 적에게 도발 2턴 + BLOCK 50 SELF
	# 도발 = 그 적의 ATTACK 이 시전 영웅(잔다르크)을 강제 타겟.
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.knights_oath.name"; c.owner_id = "joan_of_arc"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	c.archetype = ["card.joan_of_arc.knights_oath.archetype"]
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.APPLY_STATUS
	ea.status_type = "taunt"; ea.value = 2; ea.base_value = 2; ea.target = "SINGLE"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.BLOCK
	eb.value = 50; eb.base_value = 50; eb.target = "SELF"
	c.effects = [ea, eb]; return c

static func _flag_of_orleans() -> Resource:
	# [Chaos] 신국의 깃발 — LEGENDARY, 2코, SKILL: HEAL_ALL 80 + BLOCK_ALL 80
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.flag_of_orleans.name"; c.owner_id = "joan_of_arc"
	c.cost = 2; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.LEGENDARY; c.play_animation = "idle"
	c.archetype = ["card.joan_of_arc.flag_of_orleans.archetype", "card.joan_of_arc.holy_touch.archetype"]
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.HEAL_ALL
	ea.value = 80; ea.base_value = 80
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.BLOCK_ALL
	eb.value = 80; eb.base_value = 80
	c.effects = [ea, eb]; return c

# ─────────────────────────────────────────
# 순교 9 — sacrifice_bank + SACRIFICE_PAYOFF 스파인
# ─────────────────────────────────────────

static func _martyrs_will() -> Resource:
	# [F] 순교의 의지 — UNCOMMON, 1코, SKILL: SACRIFICE 50 + HEAL_ALL 65
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.martyrs_will.name"; c.owner_id = "joan_of_arc"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	c.archetype = ["card.joan_of_arc.martyrs_will.archetype"]
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.SACRIFICE_HP
	ea.value = 50; ea.base_value = 50
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.HEAL_ALL
	eb.value = 65; eb.base_value = 65
	c.effects = [ea, eb]; return c

static func _altar_flame() -> Resource:
	# [F] 제단의 불꽃 — UNCOMMON, 1코, SKILL: SACRIFICE 50 + BLOCK_ALL 110
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.altar_flame.name"; c.owner_id = "joan_of_arc"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	c.archetype = ["card.joan_of_arc.altar_flame.archetype"]
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.SACRIFICE_HP
	ea.value = 50; ea.base_value = 50
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.BLOCK_ALL
	eb.value = 110; eb.base_value = 110
	c.effects = [ea, eb]; return c

static func _martyrdom_steps() -> Resource:
	# [F] 순교의 발걸음 — UNCOMMON, 1코, SKILL: SACRIFICE 100 + DRAW 2
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.martyrdom_steps.name"; c.owner_id = "joan_of_arc"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	c.archetype = ["card.joan_of_arc.martyrdom_steps.archetype"]
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.SACRIFICE_HP
	ea.value = 100; ea.base_value = 100
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.DRAW
	eb.value = 2; eb.base_value = 2
	c.effects = [ea, eb]; return c

static func _passion_power() -> Resource:
	# [A] 수난의 권능 — RARE, 1코, POWER: sacrifice_bank 활성화 (SACRIFICE_HP 누적 추적)
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.passion_power.name"; c.owner_id = "joan_of_arc"
	c.cost = 1; c.card_type = CardRes.CardType.POWER
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	c.archetype = ["card.joan_of_arc.passion_power.archetype"]
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.APPLY_STATUS
	e.status_type = "power.sacrifice_bank"; e.value = 0; e.base_value = 0; e.target = "SELF"
	c.effects = [e]; return c

static func _martyr_strength() -> Resource:
	# [A] 순교의 힘 — UNCOMMON, 1코, POWER: SACRIFICE_HP 40 + strength_player +3 (희생으로 얻는 힘)
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.martyr_strength.name"; c.owner_id = "joan_of_arc"
	c.cost = 1; c.card_type = CardRes.CardType.POWER
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	c.archetype = ["card.joan_of_arc.martyr_strength.archetype"]
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.SACRIFICE_HP; ea.value = 50; ea.base_value = 50
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.APPLY_STATUS
	eb.status_type = "power.strength_player"; eb.value = 3; eb.base_value = 3; eb.target = "SELF"
	c.effects = [ea, eb]; return c

static func _saints_revelation() -> Resource:
	# [P] 성흔의 결실 — RARE, 2코, ATTACK: sacrifice_bank/100 × 20 피해 (ALL)
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.saints_revelation.name"; c.owner_id = "joan_of_arc"
	c.cost = 2; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "attack"
	c.archetype = ["card.joan_of_arc.saints_revelation.archetype"]
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.SACRIFICE_PAYOFF
	e.value = 20; e.base_value = 20; e.target = "ALL"
	e.damage_type = "holy_strike"
	c.effects = [e]; return c

static func _martyrs_light() -> Resource:
	# [P] 순교자의 빛 — LEGENDARY, 2코, SKILL EXHAUST: sacrifice_bank/100 × 15 BLOCK_ALL
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.martyrs_light.name"; c.owner_id = "joan_of_arc"
	c.cost = 2; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.LEGENDARY; c.play_animation = "idle"
	c.archetype = ["card.joan_of_arc.martyrs_light.archetype"]
	c.is_exhaust = true
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.SACRIFICE_PAYOFF
	e.value = 35; e.base_value = 35; e.status_type = "block"; e.target = "ALL"
	c.effects = [e]; return c

static func _last_shield() -> Resource:
	# [C] 최후의 방패 — RARE, 1코, SKILL: SACRIFICE 100 + BLOCK_ALL 130
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.last_shield.name"; c.owner_id = "joan_of_arc"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	c.archetype = ["card.joan_of_arc.last_shield.archetype"]
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.SACRIFICE_HP
	ea.value = 100; ea.base_value = 100
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.BLOCK_ALL
	eb.value = 130; eb.base_value = 130
	c.effects = [ea, eb]; return c

static func _saints_flame() -> Resource:
	# [Chaos] 성녀의 화염 — DIVINE, 2코, ATTACK EXHAUST: SACRIFICE 80 + DMG 220 ALL divine
	var c := CardRes.new()
	c.card_name = "card.joan_of_arc.saints_flame.name"; c.owner_id = "joan_of_arc"
	c.cost = 2; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.DIVINE; c.play_animation = "attack"
	c.archetype = ["card.joan_of_arc.saints_flame.archetype", "card.joan_of_arc.strike.archetype"]
	c.is_exhaust = true
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.SACRIFICE_HP
	ea.value = 80; ea.base_value = 80
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.DAMAGE
	eb.value = 220; eb.base_value = 220; eb.target = "ALL"
	eb.damage_type = "holy_fire"  # saints_flame — 성스러운 화염
	c.effects = [ea, eb]; return c
