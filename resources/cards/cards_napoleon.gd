# resources/cards/cards_napoleon.gd
# 나폴레옹 카드 — starter 10 + pool 30 (돌격 10 / 군단 12 / 지휘 8)
# 돌격: morale_per_turn + CONSUME_MORALE 스파인
# 군단: summon_per_turn + DAMAGE_PER_TOKEN 스파인
# 지휘: draw_per_turn + COST_ZERO 스파인
const CardRes = preload("res://resources/card_resource.gd")
const EffRes  = preload("res://resources/effect_resource.gd")

static func starter_deck() -> Array:
	var cards: Array = []
	for _i in range(4):
		cards.append(_strike())
	for _i in range(4):
		cards.append(_defend())
	cards.append(_war_bugle())
	cards.append(_swift_march())
	return cards

static func pool() -> Array:
	return [
		# ── 돌격 10 (F×3 / A×2 / P×2 / C×2 / Chaos×1) ──
		_cavalry_threat(), _hussar_charge(), _austerlitz_maneuver(),   # F
		_emperors_power(), _conquest_decree(),                          # A
		_one_man_army(), _emperors_assault(),                           # P
		_arcole_breakthrough(), _emperors_spirit(),                     # C
		_alps_crossing(),                                               # Chaos
		# ── 군단 12 (F×4 / A×2 / P×3 / C×2 / Chaos×1) ──
		_trench_construction(), _guard_charge(),
		_artillery_gather(), _imperial_infantry_call(),                 # F
		_emperors_legion(), _imperial_artillery(),                      # A
		_artillery_volley(), _borodino_bombardment(), _legion_charge(), # P
		_eagle_standard(), _grand_armee_shield(),                       # C
		_empire_glory(),                                                # Chaos
		# ── 지휘 8 (F×2 / A×2 / P×2 / C×1 / Chaos×1) ──
		_line_reform(), _charge_bugle(),                                # F
		_emperors_will(), _glory_shout(),                               # A
		_emperors_command(), _victory_proclamation(),                   # P
		_emperors_encirclement(),                                       # C
		_reconnaissance(),                                              # Chaos
	]

# ─────────────────────────────────────────
# 시작덱 (2종)
# ─────────────────────────────────────────

static func _strike() -> Resource:
	# 스트라이크 — COMMON, 1코, ATTACK, 돌격: DMG 100
	var c := CardRes.new()
	c.card_name = "card.napoleon.strike.name"; c.owner_id = "napoleon"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "attack"
	c.archetype = "card.napoleon.strike.archetype"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.DAMAGE
	e.value = 100; e.base_value = 100; e.target = "SINGLE"
	e.damage_type = "slash"
	c.effects = [e]; return c

static func _defend() -> Resource:
	# 디펜드 — COMMON, 1코, SKILL, 군단: BLOCK 80
	var c := CardRes.new()
	c.card_name = "card.napoleon.defend.name"; c.owner_id = "napoleon"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "idle"
	c.archetype = "card.napoleon.defend.archetype"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.BLOCK
	e.value = 125; e.base_value = 125; e.target = "SELF"
	c.effects = [e]; return c

static func _war_bugle() -> Resource:
	# 전투 나팔 — UNCOMMON, 1코, SKILL, 지휘: DRAW 1 + GAIN_MORALE 1
	var c := CardRes.new()
	c.card_name = "card.napoleon.war_bugle.name"; c.owner_id = "napoleon"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	c.archetype = "card.napoleon.war_bugle.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DRAW
	ea.value = 1; ea.base_value = 1
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.GAIN_MORALE
	eb.value = 1; eb.base_value = 1; eb.target = "SELF"
	c.effects = [ea, eb]; return c

static func _swift_march() -> Resource:
	# 신속 행군 — COMMON, 1코, ATTACK, 돌격: DMG 60 + GAIN_MORALE 1
	var c := CardRes.new()
	c.card_name = "card.napoleon.swift_march.name"; c.owner_id = "napoleon"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "attack"
	c.archetype = "card.napoleon.swift_march.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 60; ea.base_value = 60; ea.target = "SINGLE"
	ea.damage_type = "slash"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.GAIN_MORALE
	eb.value = 1; eb.base_value = 1; eb.target = "SELF"
	c.effects = [ea, eb]; return c

# ─────────────────────────────────────────
# v1 풀 카드 13장
# ─────────────────────────────────────────

static func _swift_advance() -> Resource:
	# 신속 기동 — COMMON, 1코, ATTACK, 돌격: DMG 50 + DRAW 1
	var c := CardRes.new()
	c.card_name = "card.napoleon.swift_advance.name"; c.owner_id = "napoleon"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "attack"
	c.archetype = "card.napoleon.swift_advance.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 50; ea.base_value = 50; ea.target = "SINGLE"
	ea.damage_type = "blunt"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.DRAW
	eb.value = 1; eb.base_value = 1
	c.effects = [ea, eb]; return c

static func _line_reform() -> Resource:
	# 전열 재편 — COMMON, 0코, SKILL, 지휘: DRAW 1, EXHAUST
	var c := CardRes.new()
	c.card_name = "card.napoleon.line_reform.name"; c.owner_id = "napoleon"
	c.cost = 0; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "idle"
	c.archetype = "card.napoleon.line_reform.archetype"
	c.is_exhaust = true
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.DRAW
	e.value = 1; e.base_value = 1
	c.effects = [e]; return c

static func _hussar_charge() -> Resource:
	# 경기병 돌격 — UNCOMMON, 1코, ATTACK, 돌격: DMG 70 + MORALE+1
	var c := CardRes.new()
	c.card_name = "card.napoleon.hussar_charge.name"; c.owner_id = "napoleon"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "attack"
	c.archetype = "card.napoleon.hussar_charge.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 70; ea.base_value = 70; ea.target = "SINGLE"
	ea.damage_type = "blunt"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.GAIN_MORALE
	eb.value = 1; eb.base_value = 1
	c.effects = [ea, eb]; return c

static func _grand_armee_shield() -> Resource:
	# 그랑다르메의 방패 — UNCOMMON, 1코, SKILL, 군단: BLOCK 100 + MORALE+1
	var c := CardRes.new()
	c.card_name = "card.napoleon.grand_armee_shield.name"; c.owner_id = "napoleon"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	c.archetype = "card.napoleon.grand_armee_shield.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.BLOCK
	ea.value = 100; ea.base_value = 100; ea.target = "SELF"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.GAIN_MORALE
	eb.value = 1; eb.base_value = 1
	c.effects = [ea, eb]; return c

static func _salvo() -> Resource:
	# 살보 사격 — UNCOMMON, 1코, ATTACK, 돌격: DMG 40 + ENERGY+1
	var c := CardRes.new()
	c.card_name = "card.napoleon.salvo.name"; c.owner_id = "napoleon"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "attack"
	c.archetype = "card.napoleon.salvo.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 40; ea.base_value = 40; ea.target = "SINGLE"
	ea.damage_type = "projectile"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.ENERGY
	eb.value = 1; eb.base_value = 1
	c.effects = [ea, eb]; return c

static func _marshal_appointment() -> Resource:
	# 원수 서임 — UNCOMMON, 1코, SKILL, 지휘: MORALE+3
	var c := CardRes.new()
	c.card_name = "card.napoleon.marshal_appointment.name"; c.owner_id = "napoleon"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	c.archetype = "card.napoleon.marshal_appointment.archetype"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.GAIN_MORALE
	e.value = 3; e.base_value = 3
	c.effects = [e]; return c

static func _arcole_breakthrough() -> Resource:
	# 아르콜레 돌파 — RARE, 1코, ATTACK, 돌격: DMG 80 + BLOCK 50
	var c := CardRes.new()
	c.card_name = "card.napoleon.arcole_breakthrough.name"; c.owner_id = "napoleon"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "attack"
	c.archetype = "card.napoleon.arcole_breakthrough.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 80; ea.base_value = 80; ea.target = "SINGLE"
	ea.damage_type = "blunt"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.BLOCK
	eb.value = 50; eb.base_value = 50; eb.target = "SELF"
	c.effects = [ea, eb]; return c

static func _artillery_volley() -> Resource:
	# 포병 일제사격 — RARE, 1코, ATTACK, 군단: DMG 80 ALL
	var c := CardRes.new()
	c.card_name = "card.napoleon.artillery_volley.name"; c.owner_id = "napoleon"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "attack"
	c.archetype = "card.napoleon.artillery_volley.archetype"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.DAMAGE
	e.value = 80; e.base_value = 80; e.target = "ALL"
	e.damage_type = "explosive"
	c.effects = [e]; return c


static func _borodino_bombardment() -> Resource:
	# 보로디노 포격 — RARE, 2코, ATTACK, 군단: CONDITIONAL_DMG (사기 있으면 DMG 340 / 없으면 140)
	var c := CardRes.new()
	c.card_name = "card.napoleon.borodino_bombardment.name"; c.owner_id = "napoleon"
	c.cost = 2; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "attack"
	c.archetype = "card.napoleon.borodino_bombardment.archetype"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.CONDITIONAL_DMG
	e.value = 140; e.base_value = 140
	e.bonus_value = 340; e.base_bonus_value = 340
	e.status_type = "has_morale"; e.target = "SINGLE"
	e.damage_type = "explosive"
	c.effects = [e]; return c


static func _emperors_command() -> Resource:
	# 황제의 명령 — LEGENDARY, 2코, ATTACK, 지휘: DMG 80 ALL + MORALE+2 [INNATE]
	var c := CardRes.new()
	c.card_name = "card.napoleon.emperors_command.name"; c.owner_id = "napoleon"
	c.cost = 2; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.LEGENDARY; c.play_animation = "attack"
	c.archetype = "card.napoleon.emperors_command.archetype"
	c.is_innate = true
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 80; ea.base_value = 80; ea.target = "ALL"
	ea.damage_type = "explosive"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.GAIN_MORALE
	eb.value = 2; eb.base_value = 2
	c.effects = [ea, eb]; return c

static func _emperors_spirit() -> Resource:
	# 황제의 기개 — DIVINE, 0코, ATTACK, 돌격: CONSUME_MORALE(3)→DMG 300 + WEAK 1
	var c := CardRes.new()
	c.card_name = "card.napoleon.emperors_spirit.name"; c.owner_id = "napoleon"
	c.cost = 0; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.DIVINE; c.play_animation = "attack"
	c.archetype = "card.napoleon.emperors_spirit.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.CONSUME_MORALE
	ea.value = 3; ea.base_value = 3
	ea.bonus_value = 300; ea.base_bonus_value = 300; ea.target = "SINGLE"
	ea.damage_type = "blunt"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.APPLY_STATUS
	eb.status_type = "weak"; eb.value = 1; eb.base_value = 1; eb.target = "SINGLE"
	c.effects = [ea, eb]; return c

# ─────────────────────────────────────────
# v2 추가 카드 25장
# ─────────────────────────────────────────


static func _trench_construction() -> Resource:
	# 참호 구축 — COMMON, 1코, SKILL, 군단: BLOCK 80 + MORALE+1
	var c := CardRes.new()
	c.card_name = "card.napoleon.trench_construction.name"; c.owner_id = "napoleon"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "idle"
	c.archetype = "card.napoleon.trench_construction.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.BLOCK
	ea.value = 80; ea.base_value = 80; ea.target = "SELF"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.GAIN_MORALE
	eb.value = 1; eb.base_value = 1
	c.effects = [ea, eb]; return c


static func _drum_beat() -> Resource:
	# 북소리 — COMMON, 0코, SKILL, 군단: MORALE+1, ETHEREAL
	var c := CardRes.new()
	c.card_name = "card.napoleon.drum_beat.name"; c.owner_id = "napoleon"
	c.cost = 0; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "idle"
	c.archetype = "card.napoleon.drum_beat.archetype"
	c.is_ethereal = true
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.GAIN_MORALE
	e.value = 1; e.base_value = 1
	c.effects = [e]; return c

static func _charge_bugle() -> Resource:
	# 진격 나팔 — COMMON, 1코, SKILL, 지휘: MORALE+2 + BLOCK 25
	var c := CardRes.new()
	c.card_name = "card.napoleon.charge_bugle.name"; c.owner_id = "napoleon"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "idle"
	c.archetype = "card.napoleon.charge_bugle.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.GAIN_MORALE
	ea.value = 2; ea.base_value = 2
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.BLOCK
	eb.value = 25; eb.base_value = 25; eb.target = "SELF"
	c.effects = [ea, eb]; return c

static func _cavalry_threat() -> Resource:
	# 기병 위협 — COMMON, 1코, ATTACK, 돌격: DMG 100
	var c := CardRes.new()
	c.card_name = "card.napoleon.cavalry_threat.name"; c.owner_id = "napoleon"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "attack"
	c.archetype = "card.napoleon.cavalry_threat.archetype"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.DAMAGE
	e.value = 100; e.base_value = 100; e.target = "SINGLE"
	e.damage_type = "blunt"
	c.effects = [e]; return c

static func _guard_charge() -> Resource:
	# 근위대 돌격 — UNCOMMON, 1코, ATTACK, 군단: SUMMON_TOKEN 1 + DMG 30
	var c := CardRes.new()
	c.card_name = "card.napoleon.guard_charge.name"; c.owner_id = "napoleon"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "attack"
	c.archetype = "card.napoleon.guard_charge.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.SUMMON_TOKEN
	ea.value = 1; ea.base_value = 1
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.DAMAGE
	eb.value = 30; eb.base_value = 30; eb.target = "SINGLE"
	eb.damage_type = "blunt"
	c.effects = [ea, eb]; return c

static func _breakthrough_advance() -> Resource:
	# 전선 돌파 — UNCOMMON, 1코, ATTACK, 돌격: DMG 40 + COST_NEXT -1
	var c := CardRes.new()
	c.card_name = "card.napoleon.breakthrough_advance.name"; c.owner_id = "napoleon"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "attack"
	c.archetype = "card.napoleon.breakthrough_advance.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 40; ea.base_value = 40; ea.target = "SINGLE"
	ea.damage_type = "blunt"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.COST_NEXT
	eb.value = 1; eb.base_value = 1
	c.effects = [ea, eb]; return c



static func _artillery_gather() -> Resource:
	# 포병 집결 — UNCOMMON, 1코, SKILL, 군단: SUMMON_TOKEN 1 + BLOCK 60
	var c := CardRes.new()
	c.card_name = "card.napoleon.artillery_gather.name"; c.owner_id = "napoleon"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	c.archetype = "card.napoleon.artillery_gather.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.SUMMON_TOKEN
	ea.value = 1; ea.base_value = 1
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.BLOCK
	eb.value = 60; eb.base_value = 60; eb.target = "SELF"
	c.effects = [ea, eb]; return c



static func _imperial_artillery() -> Resource:
	# 황실 포병대 — UNCOMMON, 1코, ATTACK, 군단: DMG 80 + VULNERABLE 1 SINGLE
	var c := CardRes.new()
	c.card_name = "card.napoleon.imperial_artillery.name"; c.owner_id = "napoleon"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "attack"
	c.archetype = "card.napoleon.imperial_artillery.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 80; ea.base_value = 80; ea.target = "SINGLE"
	ea.damage_type = "explosive"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.APPLY_STATUS
	eb.status_type = "vulnerable"; eb.value = 1; eb.base_value = 1; eb.target = "SINGLE"
	c.effects = [ea, eb]; return c

static func _imperial_infantry_call() -> Resource:
	# 제국 보병 소집 — RARE, 2코, SKILL, 군단: SUMMON_TOKEN 3
	var c := CardRes.new()
	c.card_name = "card.napoleon.imperial_infantry_call.name"; c.owner_id = "napoleon"
	c.cost = 2; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	c.archetype = "card.napoleon.imperial_infantry_call.archetype"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.SUMMON_TOKEN
	e.value = 3; e.base_value = 3
	c.effects = [e]; return c

static func _austerlitz_maneuver() -> Resource:
	# 아우스터리츠 기동 — RARE, 1코, ATTACK, 돌격: DMG 50 + BLOCK 30 + MORALE+1
	var c := CardRes.new()
	c.card_name = "card.napoleon.austerlitz_maneuver.name"; c.owner_id = "napoleon"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "attack"
	c.archetype = "card.napoleon.austerlitz_maneuver.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 50; ea.base_value = 50; ea.target = "SINGLE"
	ea.damage_type = "blunt"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.BLOCK
	eb.value = 30; eb.base_value = 30; eb.target = "SELF"
	var ec := EffRes.new()
	ec.effect_type = EffRes.EffectType.GAIN_MORALE
	ec.value = 1; ec.base_value = 1
	c.effects = [ea, eb, ec]; return c


static func _eagle_standard() -> Resource:
	# 독수리 군기 — RARE, 2코, SKILL, 군단: SUMMON_TOKEN 1 + BLOCK_ALL 92 [RETAIN]
	var c := CardRes.new()
	c.card_name = "card.napoleon.eagle_standard.name"; c.owner_id = "napoleon"
	c.cost = 2; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	c.archetype = "card.napoleon.eagle_standard.archetype"
	c.is_retain = true
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.SUMMON_TOKEN
	ea.value = 1; ea.base_value = 1
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.BLOCK_ALL
	eb.value = 92; eb.base_value = 92
	c.effects = [ea, eb]; return c

static func _victory_proclamation() -> Resource:
	# 승리의 포고 — RARE, 1코, ATTACK, 지휘: CONDITIONAL_DMG (MORALE 2 이상이면 150 / 미만 100)
	var c := CardRes.new()
	c.card_name = "card.napoleon.victory_proclamation.name"; c.owner_id = "napoleon"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "attack"
	c.archetype = "card.napoleon.victory_proclamation.archetype"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.CONDITIONAL_DMG
	e.value = 100; e.base_value = 100
	e.bonus_value = 150; e.base_bonus_value = 150
	e.status_type = "has_morale_2"; e.target = "SINGLE"
	e.damage_type = "blunt"
	c.effects = [e]; return c

static func _great_army_siege() -> Resource:
	# 대육군 포위전 — RARE, 2코, ATTACK, 군단: DMG 150 ALL
	var c := CardRes.new()
	c.card_name = "card.napoleon.great_army_siege.name"; c.owner_id = "napoleon"
	c.cost = 2; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "attack"
	c.archetype = "card.napoleon.great_army_siege.archetype"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.DAMAGE
	e.value = 150; e.base_value = 150; e.target = "ALL"
	e.damage_type = "explosive"
	c.effects = [e]; return c

static func _emperors_encirclement() -> Resource:
	# 황제의 포위령 — RARE, 1코, SKILL, 지휘: COST_NEXT -2 + BLOCK 50
	var c := CardRes.new()
	c.card_name = "card.napoleon.emperors_encirclement.name"; c.owner_id = "napoleon"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	c.archetype = "card.napoleon.emperors_encirclement.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.COST_NEXT
	ea.value = 2; ea.base_value = 2
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.BLOCK
	eb.value = 50; eb.base_value = 50; eb.target = "SELF"
	c.effects = [ea, eb]; return c

static func _one_man_army() -> Resource:
	# 일기당천 — RARE, 1코, ATTACK, 돌격: DMG 60 + CONSUME_MORALE(1)→DMG 150 + ENERGY+1
	var c := CardRes.new()
	c.card_name = "card.napoleon.one_man_army.name"; c.owner_id = "napoleon"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "attack"
	c.archetype = "card.napoleon.one_man_army.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.CONSUME_MORALE
	ea.value = 1; ea.base_value = 1
	ea.bonus_value = 150; ea.base_bonus_value = 150; ea.target = "SINGLE"
	ea.damage_type = "blunt"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.ENERGY
	eb.value = 1; eb.base_value = 1
	var ec := EffRes.new()
	ec.effect_type = EffRes.EffectType.DAMAGE
	ec.value = 60; ec.base_value = 60; ec.target = "SINGLE"
	ec.damage_type = "blunt"
	c.effects = [ea, eb, ec]; return c


static func _emperors_assault() -> Resource:
	# 황제의 돌격 — LEGENDARY, 2코, ATTACK, 돌격: DMG 200 + CONSUME_MORALE(2)→DMG 250 + BLOCK 100
	var c := CardRes.new()
	c.card_name = "card.napoleon.emperors_assault.name"; c.owner_id = "napoleon"
	c.cost = 2; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.LEGENDARY; c.play_animation = "attack"
	c.archetype = "card.napoleon.emperors_assault.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.CONSUME_MORALE
	ea.value = 2; ea.base_value = 2
	ea.bonus_value = 250; ea.base_bonus_value = 250; ea.target = "SINGLE"
	ea.damage_type = "blunt"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.BLOCK
	eb.value = 100; eb.base_value = 100; eb.target = "SELF"
	var ec := EffRes.new()
	ec.effect_type = EffRes.EffectType.DAMAGE
	ec.value = 200; ec.base_value = 200; ec.target = "SINGLE"
	ec.damage_type = "blunt"
	c.effects = [ea, eb, ec]; return c

static func _empire_glory() -> Resource:
	# 제국의 영광 — DIVINE, 0코, POWER, 군단: SUMMON_TOKEN 1, EXHAUST
	var c := CardRes.new()
	c.card_name = "card.napoleon.empire_glory.name"; c.owner_id = "napoleon"
	c.cost = 0; c.card_type = CardRes.CardType.POWER
	c.rarity = CardRes.Rarity.DIVINE; c.play_animation = "idle"
	c.archetype = "card.napoleon.empire_glory.archetype"
	c.is_exhaust = true
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.SUMMON_TOKEN
	e.value = 1; e.base_value = 1
	c.effects = [e]; return c

static func _legion_charge() -> Resource:
	# 군단의 진격 — UNCOMMON, 2코, 공격: 토큰 1개당 110 피해
	var c := CardRes.new()
	c.card_name = "card.napoleon.legion_charge.name"; c.owner_id = "napoleon"
	c.cost = 2; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "attack"
	c.archetype = "card.napoleon.legion_charge.archetype"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.DAMAGE_PER_TOKEN
	e.value = 110; e.base_value = 110; e.target = "SINGLE"
	e.damage_type = "blunt"
	c.effects = [e]; return c

static func _glory_shout() -> Resource:
	# 영광의 함성 — UNCOMMON, 1코, 기술: 사기 1당 BLOCK +10 + DRAW 1
	var c := CardRes.new()
	c.card_name = "card.napoleon.glory_shout.name"; c.owner_id = "napoleon"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	c.archetype = "card.napoleon.glory_shout.archetype"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.MORALE_TO_BLOCK
	ea.value = 10; ea.base_value = 10; ea.target = "SELF"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.DRAW
	eb.value = 1; eb.base_value = 1
	c.effects = [ea, eb]; return c

# ─────────────────────────────────────────
# v3 신규 카드 6장 (H6 재설계)
# ─────────────────────────────────────────

static func _emperors_power() -> Resource:
	# 황제의 권능 — UNCOMMON, 1코, POWER, 돌격 [A]: 매턴 사기+1
	var c := CardRes.new()
	c.card_name = "card.napoleon.emperors_power.name"; c.owner_id = "napoleon"
	c.cost = 1; c.card_type = CardRes.CardType.POWER
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	c.archetype = "card.napoleon.emperors_power.archetype"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.APPLY_STATUS
	e.status_type = "power.morale_per_turn"; e.value = 1; e.base_value = 1; e.target = "SELF"
	c.effects = [e]; return c

static func _conquest_decree() -> Resource:
	# 정복 칙령 — RARE, 1코, POWER, 돌격 [A]: 매턴 BLOCK+15
	var c := CardRes.new()
	c.card_name = "card.napoleon.conquest_decree.name"; c.owner_id = "napoleon"
	c.cost = 1; c.card_type = CardRes.CardType.POWER
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	c.archetype = "card.napoleon.conquest_decree.archetype"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.APPLY_STATUS
	e.status_type = "power.block_per_turn"; e.value = 15; e.base_value = 15; e.target = "SELF"
	c.effects = [e]; return c

static func _alps_crossing() -> Resource:
	# 알프스 횡단 — RARE, 0코, SKILL, 돌격 [Chaos]: SACRIFICE 40 + ENERGY 3 + DRAW 2, EXHAUST
	var c := CardRes.new()
	c.card_name = "card.napoleon.alps_crossing.name"; c.owner_id = "napoleon"
	c.cost = 0; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	c.archetype = "card.napoleon.alps_crossing.archetype"
	c.is_exhaust = true
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.SACRIFICE_HP
	ea.value = 40; ea.base_value = 40; ea.target = "SELF"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.ENERGY
	eb.value = 3; eb.base_value = 3
	var ec := EffRes.new()
	ec.effect_type = EffRes.EffectType.DRAW
	ec.value = 2; ec.base_value = 2
	c.effects = [ea, eb, ec]; return c

static func _emperors_legion() -> Resource:
	# 황제의 군단 — RARE, 1코, POWER, 군단 [A]: 매턴 토큰+1
	var c := CardRes.new()
	c.card_name = "card.napoleon.emperors_legion.name"; c.owner_id = "napoleon"
	c.cost = 1; c.card_type = CardRes.CardType.POWER
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	c.archetype = "card.napoleon.emperors_legion.archetype"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.APPLY_STATUS
	e.status_type = "power.summon_per_turn"; e.value = 1; e.base_value = 1; e.target = "SELF"
	c.effects = [e]; return c

static func _emperors_will() -> Resource:
	# 황제의 의지 — UNCOMMON, 1코, POWER, 지휘 [A]: 매턴 드로우+1
	var c := CardRes.new()
	c.card_name = "card.napoleon.emperors_will.name"; c.owner_id = "napoleon"
	c.cost = 1; c.card_type = CardRes.CardType.POWER
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	c.archetype = "card.napoleon.emperors_will.archetype"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.APPLY_STATUS
	e.status_type = "power.draw_per_turn"; e.value = 1; e.base_value = 1; e.target = "SELF"
	c.effects = [e]; return c

static func _reconnaissance() -> Resource:
	# 정찰 — UNCOMMON, 1코, SKILL, 지휘 [Chaos]: DRAW 2
	var c := CardRes.new()
	c.card_name = "card.napoleon.reconnaissance.name"; c.owner_id = "napoleon"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	c.archetype = "card.napoleon.reconnaissance.archetype"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.DRAW
	e.value = 2; e.base_value = 2
	c.effects = [e]; return c
