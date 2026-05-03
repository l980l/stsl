# resources/cards/cards_yi_sun_sin.gd
# 이순신 카드 — starter 10 + pool 30 (거북선 10 / 학익진 10 / 필사즉생 10)
const CardRes = preload("res://resources/card_resource.gd")
const EffRes  = preload("res://resources/effect_resource.gd")

# ───────────────────────────────────────────
# 시작덱 (풀 카드에 포함되지 않음)
# ───────────────────────────────────────────

static func starter_deck() -> Array:
	var cards: Array = []
	for _i in range(4):
		cards.append(_strike())
	for _i in range(4):
		cards.append(_defend())
	cards.append(_shield())
	cards.append(_counter_strike())
	return cards

# ───────────────────────────────────────────
# 풀 카드 40장
# ───────────────────────────────────────────

static func pool() -> Array:
	return [
		# ── 거북선 10 ──
		_turtle_ship_charge(), _counter(), _turtle_shield(),
		_naval_maneuver(), _consecutive_defense(), _charge_stance(),
		_volley_fire(), _fleet_command(), _warriors_resolve(), _indomitable(),
		# ── 학익진 10 ──
		_formation_boost(), _naval_training(), _strict_training(),
		_morale_boost(), _discipline(), _hold_formation(),
		_regroup(), _command_instinct(), _formation_bond(), _discard_focus(),
		# ── 필사즉생 10 ──
		_last_stand(), _death_or_glory(), _decisive_strike(),
		_all_in(), _miraculous_recovery(), _crisis_breakthrough(),
		_death_charge(), _bloody_battle(), _war_drum(), _phoenix(),
	]

# ───────────────────────────────────────────
# 시작덱 함수 (4종)
# ───────────────────────────────────────────

static func _strike() -> Resource:
	# 스트라이크 — COMMON, 1코, ATTACK: DMG 100
	var c := CardRes.new()
	c.card_name = "card.yi_sun_sin.strike.name"; c.owner_id = "yi_sun_sin"; c.cost = 1
	c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "attack"
	c.archetype = "card.yi_sun_sin.strike.archetype"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.DAMAGE; e.value = 100; e.base_value = 100; e.target = "SINGLE"
	e.damage_type = "slash"
	c.effects = [e]; return c

static func _defend() -> Resource:
	# 디펜드 — COMMON, 1코, SKILL: BLOCK 125 SELF
	var c := CardRes.new()
	c.card_name = "card.yi_sun_sin.defend.name"; c.owner_id = "yi_sun_sin"; c.cost = 1
	c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "idle"
	c.archetype = "card.yi_sun_sin.defend.archetype"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.BLOCK; e.value = 125; e.base_value = 125; e.target = "SELF"
	c.effects = [e]; return c

static func _shield() -> Resource:
	var c := CardRes.new()
	c.card_name = "card.yi_sun_sin.shield.name"; c.owner_id = "yi_sun_sin"; c.cost = 1
	c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.COMMON
	c.play_animation = "idle"
	c.archetype = "card.yi_sun_sin.shield.archetype"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.BLOCK; e.value = 125; e.base_value = 125
	c.effects = [e]; return c

static func _counter_strike() -> Resource:
	var c := CardRes.new()
	c.card_name = "card.yi_sun_sin.counter_strike.name"; c.owner_id = "yi_sun_sin"; c.cost = 1
	c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.COMMON
	c.play_animation = "attack"
	c.archetype = "card.yi_sun_sin.counter_strike.archetype"
	var e1 := EffRes.new()
	e1.effect_type = EffRes.EffectType.BLOCK; e1.value = 50; e1.base_value = 50
	var e2 := EffRes.new()
	e2.effect_type = EffRes.EffectType.DAMAGE; e2.value = 50; e2.base_value = 50; e2.target = "SINGLE"
	e2.damage_type = "slash"
	c.effects = [e1, e2]; return c

# ───────────────────────────────────────────
# v1 카드 (#1 ~ #15)
# ───────────────────────────────────────────

# #1 거북선 돌격 — UNCOMMON, cost 2, ATTACK, 거북선
static func _turtle_ship_charge() -> Resource:
	var c := CardRes.new()
	c.card_name = "card.yi_sun_sin.turtle_ship_charge.name"; c.owner_id = "yi_sun_sin"; c.cost = 2
	c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.UNCOMMON
	c.play_animation = "attack"
	c.archetype = "card.yi_sun_sin.turtle_ship_charge.archetype"
	var e1 := EffRes.new()
	e1.effect_type = EffRes.EffectType.DAMAGE; e1.value = 170; e1.base_value = 170; e1.target = "SINGLE"
	e1.damage_type = "blunt"
	var e2 := EffRes.new()
	e2.effect_type = EffRes.EffectType.COUNTER_BLOCK; e2.value = 60; e2.base_value = 60; e2.target = "SINGLE"
	e2.damage_type = "blunt"
	c.effects = [e1, e2]; return c

# #2 반격 — UNCOMMON, cost 1, ATTACK, 거북선
static func _counter() -> Resource:
	var c := CardRes.new()
	c.card_name = "card.yi_sun_sin.counter.name"; c.owner_id = "yi_sun_sin"; c.cost = 1
	c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.UNCOMMON
	c.play_animation = "attack"
	c.archetype = "card.yi_sun_sin.counter.archetype"
	var e1 := EffRes.new()
	e1.effect_type = EffRes.EffectType.COUNTER_BLOCK; e1.value = 100; e1.base_value = 100; e1.target = "SINGLE"
	e1.damage_type = "blunt"
	var e2 := EffRes.new()
	e2.effect_type = EffRes.EffectType.BLOCK; e2.value = 40; e2.base_value = 40
	c.effects = [e1, e2]; return c


# #4 거북선 방패 — COMMON, cost 1, SKILL, 거북선 [RETAIN]
static func _turtle_shield() -> Resource:
	var c := CardRes.new()
	c.card_name = "card.yi_sun_sin.turtle_shield.name"; c.owner_id = "yi_sun_sin"; c.cost = 1
	c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.COMMON
	c.play_animation = "idle"
	c.archetype = "card.yi_sun_sin.turtle_shield.archetype"
	c.is_retain = true
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.BLOCK; e.value = 80; e.base_value = 80
	c.effects = [e]; return c


# #6 진형 강화 — UNCOMMON, cost 1, SKILL, 학익진
static func _formation_boost() -> Resource:
	var c := CardRes.new()
	c.card_name = "card.yi_sun_sin.formation_boost.name"; c.owner_id = "yi_sun_sin"; c.cost = 1
	c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.UNCOMMON
	c.play_animation = "idle"
	c.archetype = "card.yi_sun_sin.formation_boost.archetype"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.FORMATION_BLOCK; e.value = 40; e.base_value = 40
	c.effects = [e]; return c

# #7 수군 훈련 — UNCOMMON, cost 1, SKILL, 학익진
static func _naval_training() -> Resource:
	var c := CardRes.new()
	c.card_name = "card.yi_sun_sin.naval_training.name"; c.owner_id = "yi_sun_sin"; c.cost = 1
	c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.UNCOMMON
	c.play_animation = "idle"
	c.archetype = "card.yi_sun_sin.naval_training.archetype"
	var e1 := EffRes.new()
	e1.effect_type = EffRes.EffectType.BLOCK; e1.value = 50; e1.base_value = 50
	var e2 := EffRes.new()
	e2.effect_type = EffRes.EffectType.DRAW; e2.value = 1; e2.base_value = 1
	c.effects = [e1, e2]; return c


# #9 엄정한 훈련 — RARE, cost 1, SKILL, 학익진
static func _strict_training() -> Resource:
	var c := CardRes.new()
	c.card_name = "card.yi_sun_sin.strict_training.name"; c.owner_id = "yi_sun_sin"; c.cost = 1
	c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.RARE
	c.play_animation = "idle"
	c.archetype = "card.yi_sun_sin.strict_training.archetype"
	var e1 := EffRes.new()
	e1.effect_type = EffRes.EffectType.DRAW; e1.value = 1; e1.base_value = 1
	var e2 := EffRes.new()
	e2.effect_type = EffRes.EffectType.BLOCK; e2.value = 40; e2.base_value = 40
	c.effects = [e1, e2]; return c

# #10 배수진 — RARE, cost 1, SKILL, 필사즉생
static func _last_stand() -> Resource:
	var c := CardRes.new()
	c.card_name = "card.yi_sun_sin.last_stand.name"; c.owner_id = "yi_sun_sin"; c.cost = 1
	c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.RARE
	c.play_animation = "idle"
	c.archetype = "card.yi_sun_sin.last_stand.archetype"
	var e1 := EffRes.new()
	e1.effect_type = EffRes.EffectType.HEAL; e1.value = -80; e1.base_value = -80; e1.target = "SELF"
	var e2 := EffRes.new()
	e2.effect_type = EffRes.EffectType.BLOCK; e2.value = 280; e2.base_value = 280
	c.effects = [e1, e2]; return c

# #11 필사즉생 — LEGENDARY, cost 1, ATTACK, 필사즉생
static func _death_or_glory() -> Resource:
	var c := CardRes.new()
	c.card_name = "card.yi_sun_sin.death_or_glory.name"; c.owner_id = "yi_sun_sin"; c.cost = 1
	c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.LEGENDARY
	c.play_animation = "attack"
	c.archetype = "card.yi_sun_sin.death_or_glory.archetype"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.CONDITIONAL_DMG
	e.value = 100; e.base_value = 100
	e.bonus_value = 200; e.base_bonus_value = 200
	e.status_type = "low_hp"; e.target = "SINGLE"
	e.damage_type = "slash"
	c.effects = [e]; return c

# #12 불굴 — UNCOMMON, cost 2, SKILL, 필사즉생
static func _indomitable() -> Resource:
	var c := CardRes.new()
	c.card_name = "card.yi_sun_sin.indomitable.name"; c.owner_id = "yi_sun_sin"; c.cost = 2
	c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.UNCOMMON
	c.play_animation = "idle"
	c.archetype = "card.yi_sun_sin.indomitable.archetype"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.HEAL_ALL; e.value = 100; e.base_value = 100
	c.effects = [e]; return c

# #13 해군 기동 — COMMON, cost 0, SKILL, 거북선
static func _naval_maneuver() -> Resource:
	var c := CardRes.new()
	c.card_name = "card.yi_sun_sin.naval_maneuver.name"; c.owner_id = "yi_sun_sin"; c.cost = 0
	c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.COMMON
	c.play_animation = "idle"
	c.archetype = "card.yi_sun_sin.naval_maneuver.archetype"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.BLOCK; e.value = 20; e.base_value = 20
	c.effects = [e]; return c



# ───────────────────────────────────────────
# v2 카드 (#16 ~ #40)
# ───────────────────────────────────────────


# #17 연속 방어 — UNCOMMON, cost 1, SKILL, 거북선
static func _consecutive_defense() -> Resource:
	var c := CardRes.new()
	c.card_name = "card.yi_sun_sin.consecutive_defense.name"; c.owner_id = "yi_sun_sin"; c.cost = 1
	c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.UNCOMMON
	c.play_animation = "idle"
	c.archetype = "card.yi_sun_sin.consecutive_defense.archetype"
	var e1 := EffRes.new()
	e1.effect_type = EffRes.EffectType.BLOCK; e1.value = 60; e1.base_value = 60
	var e2 := EffRes.new()
	e2.effect_type = EffRes.EffectType.COST_NEXT; e2.value = 1; e2.base_value = 1
	c.effects = [e1, e2]; return c


# #19 돌격 태세 — RARE, cost 1, ATTACK, 거북선
# DAMAGE 100 + 방어도 150 이상 시 COUNTER_BLOCK 50% 조건부 발동
static func _charge_stance() -> Resource:
	var c := CardRes.new()
	c.card_name = "card.yi_sun_sin.charge_stance.name"; c.owner_id = "yi_sun_sin"; c.cost = 1
	c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.RARE
	c.play_animation = "attack"
	c.archetype = "card.yi_sun_sin.charge_stance.archetype"
	var e1 := EffRes.new()
	e1.effect_type = EffRes.EffectType.DAMAGE; e1.value = 100; e1.base_value = 100; e1.target = "SINGLE"
	e1.damage_type = "blunt"
	var e2 := EffRes.new()
	e2.effect_type = EffRes.EffectType.COUNTER_BLOCK
	e2.value = 50; e2.base_value = 50
	e2.status_type = "block_threshold_150"
	e2.damage_type = "blunt"
	c.effects = [e1, e2]; return c





# #24 사기 고취 — UNCOMMON, cost 1, SKILL, 학익진
static func _morale_boost() -> Resource:
	var c := CardRes.new()
	c.card_name = "card.yi_sun_sin.morale_boost.name"; c.owner_id = "yi_sun_sin"; c.cost = 1
	c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.UNCOMMON
	c.play_animation = "idle"
	c.archetype = "card.yi_sun_sin.morale_boost.archetype"
	var e1 := EffRes.new()
	e1.effect_type = EffRes.EffectType.BLOCK_ALL; e1.value = 50; e1.base_value = 50
	var e2 := EffRes.new()
	e2.effect_type = EffRes.EffectType.GAIN_MORALE; e2.value = 1; e2.base_value = 1
	c.effects = [e1, e2]; return c

# #25 군기 진작 — COMMON, cost 1, SKILL, 학익진
static func _discipline() -> Resource:
	var c := CardRes.new()
	c.card_name = "card.yi_sun_sin.discipline.name"; c.owner_id = "yi_sun_sin"; c.cost = 1
	c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.COMMON
	c.play_animation = "idle"
	c.archetype = "card.yi_sun_sin.discipline.archetype"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.FORMATION_BLOCK; e.value = 30; e.base_value = 30
	c.effects = [e]; return c

# #26 진형 사수 — RARE, cost 2, SKILL, 학익진
# BLOCK_ALL 90 + 팀원 3명 이상이면 DRAW 1 조건부 발동
static func _hold_formation() -> Resource:
	var c := CardRes.new()
	c.card_name = "card.yi_sun_sin.hold_formation.name"; c.owner_id = "yi_sun_sin"; c.cost = 2
	c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.RARE
	c.play_animation = "idle"
	c.archetype = "card.yi_sun_sin.hold_formation.archetype"
	var e1 := EffRes.new()
	e1.effect_type = EffRes.EffectType.BLOCK_ALL; e1.value = 120; e1.base_value = 120
	var e2 := EffRes.new()
	e2.effect_type = EffRes.EffectType.DRAW; e2.value = 1; e2.base_value = 1
	e2.status_type = "team_count_3"
	c.effects = [e1, e2]; return c

# #27 전열 정비 — UNCOMMON, cost 1, SKILL, 학익진
static func _regroup() -> Resource:
	var c := CardRes.new()
	c.card_name = "card.yi_sun_sin.regroup.name"; c.owner_id = "yi_sun_sin"; c.cost = 1
	c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.UNCOMMON
	c.play_animation = "idle"
	c.archetype = "card.yi_sun_sin.regroup.archetype"
	var e1 := EffRes.new()
	e1.effect_type = EffRes.EffectType.HEAL_ALL; e1.value = 30; e1.base_value = 30
	var e2 := EffRes.new()
	e2.effect_type = EffRes.EffectType.GAIN_MORALE; e2.value = 1; e2.base_value = 1
	c.effects = [e1, e2]; return c

# #28 함대 지휘 — RARE, cost 1, SKILL, 학익진
static func _fleet_command() -> Resource:
	var c := CardRes.new()
	c.card_name = "card.yi_sun_sin.fleet_command.name"; c.owner_id = "yi_sun_sin"; c.cost = 1
	c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.RARE
	c.play_animation = "idle"
	c.archetype = "card.yi_sun_sin.fleet_command.archetype"
	var e1 := EffRes.new()
	e1.effect_type = EffRes.EffectType.FORMATION_BLOCK; e1.value = 50; e1.base_value = 50
	var e2 := EffRes.new()
	e2.effect_type = EffRes.EffectType.DRAW; e2.value = 1; e2.base_value = 1
	c.effects = [e1, e2]; return c

# #29 일제 사격 — RARE, cost 2, ATTACK, 학익진
static func _volley_fire() -> Resource:
	var c := CardRes.new()
	c.card_name = "card.yi_sun_sin.volley_fire.name"; c.owner_id = "yi_sun_sin"; c.cost = 2
	c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.RARE
	c.play_animation = "attack"
	c.archetype = "card.yi_sun_sin.volley_fire.archetype"
	var e1 := EffRes.new()
	e1.effect_type = EffRes.EffectType.DAMAGE; e1.value = 85; e1.base_value = 85; e1.target = "ALL"
	e1.damage_type = "explosive"
	var e2 := EffRes.new()
	e2.effect_type = EffRes.EffectType.BLOCK_ALL; e2.value = 60; e2.base_value = 60
	c.effects = [e1, e2]; return c

# #30 지휘 본능 — LEGENDARY, cost 2, SKILL, 학익진
static func _command_instinct() -> Resource:
	var c := CardRes.new()
	c.card_name = "card.yi_sun_sin.command_instinct.name"; c.owner_id = "yi_sun_sin"; c.cost = 2
	c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.LEGENDARY
	c.play_animation = "idle"
	c.archetype = "card.yi_sun_sin.command_instinct.archetype"
	var e1 := EffRes.new()
	e1.effect_type = EffRes.EffectType.FORMATION_BLOCK; e1.value = 60; e1.base_value = 60
	var e2 := EffRes.new()
	e2.effect_type = EffRes.EffectType.GAIN_MORALE; e2.value = 2; e2.base_value = 2
	var e3 := EffRes.new()
	e3.effect_type = EffRes.EffectType.DRAW; e3.value = 1; e3.base_value = 1
	c.effects = [e1, e2, e3]; return c

# #31 진형 결속 — COMMON, cost 0, SKILL, 학익진 [INNATE]
static func _formation_bond() -> Resource:
	var c := CardRes.new()
	c.card_name = "card.yi_sun_sin.formation_bond.name"; c.owner_id = "yi_sun_sin"; c.cost = 0
	c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.COMMON
	c.play_animation = "idle"
	c.archetype = "card.yi_sun_sin.formation_bond.archetype"
	c.is_innate = true
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.FORMATION_BLOCK; e.value = 20; e.base_value = 20
	c.effects = [e]; return c

# #32 사지결단 — RARE, cost 1, ATTACK, 필사즉생
static func _decisive_strike() -> Resource:
	var c := CardRes.new()
	c.card_name = "card.yi_sun_sin.decisive_strike.name"; c.owner_id = "yi_sun_sin"; c.cost = 1
	c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.RARE
	c.play_animation = "attack"
	c.archetype = "card.yi_sun_sin.decisive_strike.archetype"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.CONDITIONAL_DMG
	e.value = 80; e.base_value = 80
	e.bonus_value = 150; e.base_bonus_value = 150
	e.status_type = "low_hp"; e.target = "SINGLE"
	e.damage_type = "slash"
	c.effects = [e]; return c

# #33 이판사판 — UNCOMMON, cost 1, ATTACK, 필사즉생
static func _all_in() -> Resource:
	var c := CardRes.new()
	c.card_name = "card.yi_sun_sin.all_in.name"; c.owner_id = "yi_sun_sin"; c.cost = 1
	c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.UNCOMMON
	c.play_animation = "attack"
	c.archetype = "card.yi_sun_sin.all_in.archetype"
	var e1 := EffRes.new()
	e1.effect_type = EffRes.EffectType.HEAL; e1.value = -60; e1.base_value = -60; e1.target = "SELF"
	var e2 := EffRes.new()
	e2.effect_type = EffRes.EffectType.DAMAGE; e2.value = 188; e2.base_value = 188; e2.target = "SINGLE"
	e2.damage_type = "slash"
	c.effects = [e1, e2]; return c

# #34 기사회생 — COMMON, cost 1, SKILL, 필사즉생
static func _miraculous_recovery() -> Resource:
	var c := CardRes.new()
	c.card_name = "card.yi_sun_sin.miraculous_recovery.name"; c.owner_id = "yi_sun_sin"; c.cost = 1
	c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.COMMON
	c.play_animation = "idle"
	c.archetype = "card.yi_sun_sin.miraculous_recovery.archetype"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.HEAL; e.value = 75; e.base_value = 75; e.target = "SELF"
	c.effects = [e]; return c

# #35 위기 돌파 — RARE, cost 2, ATTACK, 필사즉생
# HP≤30% 조건 (very_low_hp)
static func _crisis_breakthrough() -> Resource:
	var c := CardRes.new()
	c.card_name = "card.yi_sun_sin.crisis_breakthrough.name"; c.owner_id = "yi_sun_sin"; c.cost = 2
	c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.RARE
	c.play_animation = "attack"
	c.archetype = "card.yi_sun_sin.crisis_breakthrough.archetype"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.CONDITIONAL_DMG
	e.value = 120; e.base_value = 120
	e.bonus_value = 340; e.base_bonus_value = 340
	e.status_type = "very_low_hp"; e.target = "SINGLE"
	e.damage_type = "blunt"
	c.effects = [e]; return c

# #36 사즉생 돌격 — UNCOMMON, cost 2, ATTACK, 필사즉생
static func _death_charge() -> Resource:
	var c := CardRes.new()
	c.card_name = "card.yi_sun_sin.death_charge.name"; c.owner_id = "yi_sun_sin"; c.cost = 2
	c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.UNCOMMON
	c.play_animation = "attack"
	c.archetype = "card.yi_sun_sin.death_charge.archetype"
	var e1 := EffRes.new()
	e1.effect_type = EffRes.EffectType.HEAL; e1.value = -50; e1.base_value = -50; e1.target = "SELF"
	var e2 := EffRes.new()
	e2.effect_type = EffRes.EffectType.DAMAGE; e2.value = 245; e2.base_value = 245; e2.target = "SINGLE"
	e2.damage_type = "blunt"
	var e3 := EffRes.new()
	e3.effect_type = EffRes.EffectType.BLOCK; e3.value = 50; e3.base_value = 50
	c.effects = [e1, e2, e3]; return c

# #37 혈전 — RARE, cost 1, ATTACK, 필사즉생
# CONDITIONAL_DMG (HP≤50%→120 / else→70) + BLOCK 40
static func _bloody_battle() -> Resource:
	var c := CardRes.new()
	c.card_name = "card.yi_sun_sin.bloody_battle.name"; c.owner_id = "yi_sun_sin"; c.cost = 1
	c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.RARE
	c.play_animation = "attack"
	c.archetype = "card.yi_sun_sin.bloody_battle.archetype"
	var e1 := EffRes.new()
	e1.effect_type = EffRes.EffectType.CONDITIONAL_DMG
	e1.value = 70; e1.base_value = 70
	e1.bonus_value = 120; e1.base_bonus_value = 120
	e1.status_type = "low_hp"; e1.target = "SINGLE"
	e1.damage_type = "slash"
	var e2 := EffRes.new()
	e2.effect_type = EffRes.EffectType.BLOCK; e2.value = 40; e2.base_value = 40
	c.effects = [e1, e2]; return c

# #38 독전 — UNCOMMON, cost 1, ATTACK, 필사즉생
# CONSUME_MORALE 1 → DMG 130 SINGLE
static func _war_drum() -> Resource:
	var c := CardRes.new()
	c.card_name = "card.yi_sun_sin.war_drum.name"; c.owner_id = "yi_sun_sin"; c.cost = 1
	c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.UNCOMMON
	c.play_animation = "attack"
	c.archetype = "card.yi_sun_sin.war_drum.archetype"
	var e1 := EffRes.new()
	e1.effect_type = EffRes.EffectType.CONSUME_MORALE
	e1.value = 1; e1.base_value = 1
	var e2 := EffRes.new()
	e2.effect_type = EffRes.EffectType.DAMAGE; e2.value = 130; e2.base_value = 130; e2.target = "SINGLE"
	e2.damage_type = "blunt"
	c.effects = [e1, e2]; return c

# #39 전사의 각오 — RARE, cost 2, POWER, 필사즉생
# 권능: 매 턴 시작 시 BLOCK +20
static func _warriors_resolve() -> Resource:
	var c := CardRes.new()
	c.card_name = "card.yi_sun_sin.warriors_resolve.name"; c.owner_id = "yi_sun_sin"; c.cost = 2
	c.card_type = CardRes.CardType.POWER
	c.rarity = CardRes.Rarity.RARE
	c.play_animation = "idle"
	c.archetype = "card.yi_sun_sin.warriors_resolve.archetype"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.APPLY_STATUS
	e.status_type = "power.block_per_turn"
	e.value = 20; e.base_value = 20
	c.effects = [e]; return c

# #40 불사조 — LEGENDARY, cost 2, SKILL, 필사즉생
# HEAL 140 + HP≤50% 조건 시 DRAW 1 추가
static func _phoenix() -> Resource:
	var c := CardRes.new()
	c.card_name = "card.yi_sun_sin.phoenix.name"; c.owner_id = "yi_sun_sin"; c.cost = 2
	c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.LEGENDARY
	c.play_animation = "idle"
	c.archetype = "card.yi_sun_sin.phoenix.archetype"
	var e1 := EffRes.new()
	e1.effect_type = EffRes.EffectType.HEAL; e1.value = 140; e1.base_value = 140; e1.target = "SELF"
	var e2 := EffRes.new()
	e2.effect_type = EffRes.EffectType.DRAW; e2.value = 1; e2.base_value = 1
	e2.status_type = "low_hp"
	c.effects = [e1, e2]; return c

static func _discard_focus() -> Resource:
	# 결단의 정리 — UNCOMMON, 2코, 기술: 손패 1장 소진 → DRAW 2장 + 에너지 +1
	var c := CardRes.new()
	c.card_name = "card.yi_sun_sin.discard_focus.name"; c.owner_id = "yi_sun_sin"
	c.cost = 2; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	c.archetype = "card.yi_sun_sin.discard_focus.archetype"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.DISCARD_PICK_DRAW
	e.value = 2; e.base_value = 2
	c.effects = [e]; return c
