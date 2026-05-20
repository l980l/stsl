# resources/cards/cards_yi_sun_sin.gd
# 이순신 카드 — starter 10 + pool 30 (거북선 10 / 학익진 10 / 필사즉생 10)
# 거북선: block_per_turn + every_nth_attack_bonus Amplifier → DAMAGE_PER_TOKEN/EXHAUST Payoff
# 학익진: draw_per_turn + block_per_turn Amplifier → FORMATION_BLOCK Payoff
# 필사즉생: morale_per_turn + block_per_turn Amplifier → 저HP 조건 Payoff
const CardRes = preload("res://resources/card_resource.gd")
const EffRes  = preload("res://resources/effect_resource.gd")
const CommonRes = preload("res://resources/cards/cards_common.gd")

static func starter_deck() -> Array:
	var cards: Array = []
	for _i in range(4):
		cards.append(_strike())
	for _i in range(4):
		cards.append(_defend())
	cards.append(_shield())
	cards.append(_counter_strike())
	cards.append(CommonRes.counter("yi_sun_sin"))
	return cards

static func pool() -> Array:
	return [
		# ── 거북선 10 (F×3 / A×2 / P×2 / C×2 / Chaos×1) ──
		_turtle_shield(), _turtle_ship_charge(), _counter(),              # F
		_turtle_power(), _cannon_rhythm(),                                # A
		_volley_fire(), _fleet_fire(),                                    # P
		_consecutive_defense(), _charge_stance(),                         # C
		_iron_ram(),                                                      # Chaos
		# ── 학익진 10 (F×3 / A×2 / P×2 / C×2 / Chaos×1) ──
		_formation_bond(), _formation_boost(), _discipline(),             # F
		_fleet_command(), _formation_strength(),                          # A
		_hold_formation(), _command_instinct(),                           # P
		_naval_training(), _regroup(),                                    # C
		_strict_training(),                                               # Chaos
		# ── 필사즉생 10 (F×3 / A×2 / P×2 / C×2 / Chaos×1) ──
		_miraculous_recovery(), _all_in(), _last_stand(),                 # F
		_death_resolve(), _fighting_spirit(),                             # A
		_death_or_glory(), _crisis_breakthrough(),                        # P
		_decisive_strike(), _bloody_battle(),                             # C
		_phoenix(),                                                       # Chaos
		# speed buff team (학익진 추가)
		_turtleship_drill(),
		# 이순신 토큰 소스 (거북선 — 함포 일제사·수륙 협공 활성화)
		_naval_muster(),
		# 교차 영웅 — 팀 사기 소모 → 팀 방어 (CONSUME_TEAM_MORALE)
		_united_bulwark(),
		# 카운터 (universal) — 거북선 역공 빌드용 드래프트 카드
		CommonRes.counter("yi_sun_sin"),
		]

static func _turtleship_drill() -> Resource:
	# 거북선 점호 — RARE, 2코, SKILL, 학익진: 파티 전원 speed +4 (4턴)
	var c := CardRes.new()
	c.card_name = "card.yi_sun_sin.turtleship_drill.name"; c.owner_id = "yi_sun_sin"
	c.cost = 2; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	c.archetype = ["card.yi_sun_sin.formation_bond.archetype"]  # 학익진
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.BUFF_SPEED
	e.value = 4; e.base_value = 4
	e.bonus_value = 4; e.base_bonus_value = 4
	e.target = "ALL_ALLIES"
	c.effects = [e]; return c

static func _united_bulwark() -> Resource:
	# 연합 방벽 — RARE, 2코, SKILL, 교차 영웅: 생존 영웅 각 사기 2 소모 → 소모 1당 팀 전체 방어 30
	# archetype 무소속 — 교차 영웅 카드는 단일 아키타입에 속하지 않음
	var c := CardRes.new()
	c.card_name = "card.yi_sun_sin.united_bulwark.name"; c.owner_id = "yi_sun_sin"; c.cost = 2
	c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.CONSUME_TEAM_MORALE
	e.value = 2; e.base_value = 2
	e.bonus_value = 30; e.base_bonus_value = 30
	c.effects = [e]; return c

static func _naval_muster() -> Resource:
	# 수군 소집 — UNCOMMON, 1코, SKILL, 거북선: SUMMON_TOKEN 2 + BLOCK 40 (이순신 토큰 소스)
	var c := CardRes.new()
	c.card_name = "card.yi_sun_sin.naval_muster.name"; c.owner_id = "yi_sun_sin"; c.cost = 1
	c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	c.archetype = ["card.yi_sun_sin.turtle_shield.archetype"]
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.SUMMON_TOKEN; ea.value = 2; ea.base_value = 2
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.BLOCK; eb.value = 40; eb.base_value = 40; eb.target = "SELF"
	c.effects = [ea, eb]; return c

# ─────────────────────────────────────────
# 시작덱 (4종)
# ─────────────────────────────────────────

static func _strike() -> Resource:
	var c := CardRes.new()
	c.card_name = "card.yi_sun_sin.strike.name"; c.owner_id = "yi_sun_sin"; c.cost = 1
	c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "attack"
	c.archetype = ["card.yi_sun_sin.strike.archetype"]
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.DAMAGE; e.value = 100; e.base_value = 100; e.target = "SINGLE"
	e.damage_type = "slash"
	c.effects = [e]; return c

static func _defend() -> Resource:
	var c := CardRes.new()
	c.card_name = "card.yi_sun_sin.defend.name"; c.owner_id = "yi_sun_sin"; c.cost = 1
	c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "idle"
	c.archetype = ["card.yi_sun_sin.defend.archetype"]
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.BLOCK; e.value = 125; e.base_value = 125; e.target = "SELF"
	c.effects = [e]; return c

static func _shield() -> Resource:
	# COMMON, 1코, SKILL: BLOCK 70 + DRAW 1 (시작덱 F)
	var c := CardRes.new()
	c.card_name = "card.yi_sun_sin.shield.name"; c.owner_id = "yi_sun_sin"; c.cost = 1
	c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "idle"
	c.archetype = ["card.yi_sun_sin.shield.archetype"]
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.BLOCK; ea.value = 45; ea.base_value = 45
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.DRAW; eb.value = 1; eb.base_value = 1
	c.effects = [ea, eb]; return c

static func _counter_strike() -> Resource:
	# COMMON, 1코, ATTACK: BLOCK 50 + DMG 50 (시작덱 F)
	var c := CardRes.new()
	c.card_name = "card.yi_sun_sin.counter_strike.name"; c.owner_id = "yi_sun_sin"; c.cost = 1
	c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "attack"
	c.archetype = ["card.yi_sun_sin.counter_strike.archetype"]
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.BLOCK; ea.value = 50; ea.base_value = 50
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.DAMAGE; eb.value = 50; eb.base_value = 50; eb.target = "SINGLE"
	eb.damage_type = "slash"
	c.effects = [ea, eb]; return c

# ─────────────────────────────────────────
# 거북선 10 — block_per_turn + every_nth_attack_bonus 스파인
# ─────────────────────────────────────────

static func _turtle_shield() -> Resource:
	# [F] 거북선 방패 — COMMON, 1코, SKILL RETAIN: BLOCK 80
	var c := CardRes.new()
	c.card_name = "card.yi_sun_sin.turtle_shield.name"; c.owner_id = "yi_sun_sin"; c.cost = 1
	c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "idle"
	c.archetype = ["card.yi_sun_sin.turtle_shield.archetype"]
	c.is_retain = true
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.BLOCK; e.value = 80; e.base_value = 80
	c.effects = [e]; return c

static func _turtle_ship_charge() -> Resource:
	# [F] 거북선 돌격 — UNCOMMON, 2코, ATTACK: DMG 170 + COUNTER_BLOCK 60
	var c := CardRes.new()
	c.card_name = "card.yi_sun_sin.turtle_ship_charge.name"; c.owner_id = "yi_sun_sin"; c.cost = 2
	c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "attack"
	c.archetype = ["card.yi_sun_sin.turtle_ship_charge.archetype"]
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE; ea.value = 170; ea.base_value = 170; ea.target = "SINGLE"
	ea.damage_type = "blunt"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.COUNTER_BLOCK; eb.value = 60; eb.base_value = 60; eb.target = "SINGLE"
	eb.damage_type = "blunt"
	c.effects = [ea, eb]; return c

static func _counter() -> Resource:
	# [F] 반격 — UNCOMMON, 1코, ATTACK: COUNTER_BLOCK 100 + BLOCK 40
	var c := CardRes.new()
	c.card_name = "card.yi_sun_sin.counter.name"; c.owner_id = "yi_sun_sin"; c.cost = 1
	c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "attack"
	c.archetype = ["card.yi_sun_sin.counter.archetype"]
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.COUNTER_BLOCK; ea.value = 100; ea.base_value = 100; ea.target = "SINGLE"
	ea.damage_type = "blunt"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.BLOCK; eb.value = 40; eb.base_value = 40
	c.effects = [ea, eb]; return c

static func _turtle_power() -> Resource:
	# [A] 거북의 권능 — RARE, 1코, POWER: 매 턴 시작 시 BLOCK +50
	var c := CardRes.new()
	c.card_name = "card.yi_sun_sin.turtle_power.name"; c.owner_id = "yi_sun_sin"; c.cost = 1
	c.card_type = CardRes.CardType.POWER
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	c.archetype = ["card.yi_sun_sin.turtle_power.archetype"]
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.APPLY_STATUS
	e.status_type = "power.block_per_turn"; e.value = 60; e.base_value = 60; e.target = "SELF"
	c.effects = [e]; return c

static func _cannon_rhythm() -> Resource:
	# [A] 포격의 리듬 — RARE, 2코, POWER: 4번째 공격 카드마다 160 추가 피해
	var c := CardRes.new()
	c.card_name = "card.yi_sun_sin.cannon_rhythm.name"; c.owner_id = "yi_sun_sin"; c.cost = 2
	c.card_type = CardRes.CardType.POWER
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	c.archetype = ["card.yi_sun_sin.cannon_rhythm.archetype"]
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.APPLY_STATUS
	e.status_type = "power.every_nth_attack_bonus"; e.value = 160; e.base_value = 160; e.target = "SELF"
	e.bonus_value = 4; e.base_bonus_value = 4
	c.effects = [e]; return c

static func _volley_fire() -> Resource:
	# [P] 일제 사격 — RARE, 2코, ATTACK: DMG 85 ALL + BLOCK_ALL 60
	var c := CardRes.new()
	c.card_name = "card.yi_sun_sin.volley_fire.name"; c.owner_id = "yi_sun_sin"; c.cost = 2
	c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "attack"
	c.archetype = ["card.yi_sun_sin.volley_fire.archetype"]
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE; ea.value = 85; ea.base_value = 85; ea.target = "ALL"
	ea.damage_type = "explosive"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.BLOCK_ALL; eb.value = 60; eb.base_value = 60
	c.effects = [ea, eb]; return c

static func _fleet_fire() -> Resource:
	# [P] 함포 일제사 — RARE, 2코, ATTACK: 팀 전체 토큰 수 × 45 피해 ALL (교차 영웅 — 나폴레옹·칭기즈칸 토큰 정산)
	# 이순신 단독 토큰 소스가 없어 DAMAGE_PER_TOKEN(owner 전용)에선 무효였음 → 팀 토큰 참조로 전환
	var c := CardRes.new()
	c.card_name = "card.yi_sun_sin.fleet_fire.name"; c.owner_id = "yi_sun_sin"; c.cost = 2
	c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "attack"
	c.archetype = ["card.yi_sun_sin.fleet_fire.archetype"]
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.DAMAGE_PER_TEAM_TOKEN
	e.value = 45; e.base_value = 45; e.target = "ALL"
	e.damage_type = "explosive"
	c.effects = [e]; return c

static func _consecutive_defense() -> Resource:
	# [C] 연속 방어 — UNCOMMON, 1코, SKILL: BLOCK 60 + COST_NEXT -1
	var c := CardRes.new()
	c.card_name = "card.yi_sun_sin.consecutive_defense.name"; c.owner_id = "yi_sun_sin"; c.cost = 1
	c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	c.archetype = ["card.yi_sun_sin.consecutive_defense.archetype"]
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.BLOCK; ea.value = 60; ea.base_value = 60
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.COST_NEXT; eb.value = 1; eb.base_value = 1
	c.effects = [ea, eb]; return c

static func _charge_stance() -> Resource:
	# [C] 돌격 태세 — RARE, 1코, ATTACK: DMG 100 + COUNTER_BLOCK 50
	var c := CardRes.new()
	c.card_name = "card.yi_sun_sin.charge_stance.name"; c.owner_id = "yi_sun_sin"; c.cost = 1
	c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "attack"
	c.archetype = ["card.yi_sun_sin.charge_stance.archetype"]
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE; ea.value = 100; ea.base_value = 100; ea.target = "SINGLE"
	ea.damage_type = "blunt"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.COUNTER_BLOCK; eb.value = 50; eb.base_value = 50
	eb.damage_type = "blunt"
	c.effects = [ea, eb]; return c

static func _iron_ram() -> Resource:
	# [Chaos] 철갑 충격 — LEGENDARY, 2코, ATTACK EXHAUST: DMG 150 ALL + BLOCK_ALL 80
	var c := CardRes.new()
	c.card_name = "card.yi_sun_sin.iron_ram.name"; c.owner_id = "yi_sun_sin"; c.cost = 2
	c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.LEGENDARY; c.play_animation = "attack"
	c.archetype = ["card.yi_sun_sin.iron_ram.archetype"]
	c.is_exhaust = true
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE; ea.value = 150; ea.base_value = 150; ea.target = "ALL"
	ea.damage_type = "explosive"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.BLOCK_ALL; eb.value = 80; eb.base_value = 80
	c.effects = [ea, eb]; return c

# ─────────────────────────────────────────
# 학익진 10 — draw_per_turn + block_per_turn 스파인
# ─────────────────────────────────────────

static func _formation_bond() -> Resource:
	# [F] 진형 결속 — COMMON, 1코, SKILL INNATE: FORMATION_BLOCK 45
	var c := CardRes.new()
	c.card_name = "card.yi_sun_sin.formation_bond.name"; c.owner_id = "yi_sun_sin"; c.cost = 1
	c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "idle"
	c.archetype = ["card.yi_sun_sin.formation_bond.archetype"]
	c.is_innate = true
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.FORMATION_BLOCK; e.value = 45; e.base_value = 45
	c.effects = [e]; return c

static func _formation_boost() -> Resource:
	# [F] 진형 강화 — UNCOMMON, 1코, SKILL: FORMATION_BLOCK 40
	var c := CardRes.new()
	c.card_name = "card.yi_sun_sin.formation_boost.name"; c.owner_id = "yi_sun_sin"; c.cost = 1
	c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	c.archetype = ["card.yi_sun_sin.formation_boost.archetype"]
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.FORMATION_BLOCK; e.value = 70; e.base_value = 70
	c.effects = [e]; return c

static func _discipline() -> Resource:
	# [F] 군기 진작 — COMMON, 1코, SKILL: GAIN_MORALE 2 + BLOCK 20 (adj=0.96)
	var c := CardRes.new()
	c.card_name = "card.yi_sun_sin.discipline.name"; c.owner_id = "yi_sun_sin"; c.cost = 1
	c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "idle"
	c.archetype = ["card.yi_sun_sin.discipline.archetype"]
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.GAIN_MORALE; ea.value = 2; ea.base_value = 2
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.BLOCK; eb.value = 20; eb.base_value = 20
	c.effects = [ea, eb]; return c

static func _fleet_command() -> Resource:
	# [A] 함대 지휘 — RARE, 1코, POWER: 매 턴 시작 시 DRAW 1 추가
	var c := CardRes.new()
	c.card_name = "card.yi_sun_sin.fleet_command.name"; c.owner_id = "yi_sun_sin"; c.cost = 2
	c.card_type = CardRes.CardType.POWER
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	c.archetype = ["card.yi_sun_sin.fleet_command.archetype", "card.yi_sun_sin.miraculous_recovery.archetype"]
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.APPLY_STATUS
	e.status_type = "power.draw_per_turn"; e.value = 1; e.base_value = 1; e.target = "SELF"
	var es := EffRes.new()
	es.effect_type = EffRes.EffectType.SACRIFICE_HP; es.value = 30; es.base_value = 30
	c.effects = [e, es]; return c

static func _formation_strength() -> Resource:
	# [A] 진형의 힘 — RARE, 2코, POWER: 매 턴 시작 시 BLOCK +15 ALL
	var c := CardRes.new()
	c.card_name = "card.yi_sun_sin.formation_strength.name"; c.owner_id = "yi_sun_sin"; c.cost = 2
	c.card_type = CardRes.CardType.POWER
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	c.archetype = ["card.yi_sun_sin.formation_strength.archetype"]
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.APPLY_STATUS
	e.status_type = "power.block_per_turn"; e.value = 100; e.base_value = 100; e.target = "SELF"
	c.effects = [e]; return c

static func _hold_formation() -> Resource:
	# [P] 진형 사수 — RARE, 2코, SKILL: BLOCK_ALL 120 + DRAW 1 (팀원 3명 조건)
	var c := CardRes.new()
	c.card_name = "card.yi_sun_sin.hold_formation.name"; c.owner_id = "yi_sun_sin"; c.cost = 2
	c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	c.archetype = ["card.yi_sun_sin.hold_formation.archetype"]
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.BLOCK_ALL; ea.value = 120; ea.base_value = 120
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.DRAW; eb.value = 1; eb.base_value = 1
	eb.condition = "team_count_3"
	c.effects = [ea, eb]; return c

static func _command_instinct() -> Resource:
	# [P] 지휘 본능 — LEGENDARY, 2코, SKILL: FORMATION_BLOCK 125 + GAIN_MORALE 2
	var c := CardRes.new()
	c.card_name = "card.yi_sun_sin.command_instinct.name"; c.owner_id = "yi_sun_sin"; c.cost = 2
	c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.LEGENDARY; c.play_animation = "idle"
	c.archetype = ["card.yi_sun_sin.command_instinct.archetype"]
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.FORMATION_BLOCK; ea.value = 125; ea.base_value = 125
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.GAIN_MORALE; eb.value = 2; eb.base_value = 2
	c.effects = [ea, eb]; return c

static func _naval_training() -> Resource:
	# [C] 수군 훈련 — UNCOMMON, 1코, SKILL: DRAW 1 + FORMATION_BLOCK 30
	var c := CardRes.new()
	c.card_name = "card.yi_sun_sin.naval_training.name"; c.owner_id = "yi_sun_sin"; c.cost = 1
	c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	c.archetype = ["card.yi_sun_sin.naval_training.archetype"]
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DRAW; ea.value = 1; ea.base_value = 1
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.FORMATION_BLOCK; eb.value = 30; eb.base_value = 30
	c.effects = [ea, eb]; return c

static func _regroup() -> Resource:
	# [C] 전열 정비 — UNCOMMON, 1코, SKILL: HEAL_ALL 30 + GAIN_MORALE 1
	var c := CardRes.new()
	c.card_name = "card.yi_sun_sin.regroup.name"; c.owner_id = "yi_sun_sin"; c.cost = 1
	c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	c.archetype = ["card.yi_sun_sin.regroup.archetype"]
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.HEAL_ALL; ea.value = 30; ea.base_value = 30
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.GAIN_MORALE; eb.value = 1; eb.base_value = 1
	c.effects = [ea, eb]; return c

static func _strict_training() -> Resource:
	# [Chaos] 엄정한 훈련 — RARE, 2코, SKILL: DRAW 2 + HEAL_ALL 40 (카오스 드로우 스윙)
	var c := CardRes.new()
	c.card_name = "card.yi_sun_sin.strict_training.name"; c.owner_id = "yi_sun_sin"; c.cost = 2
	c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	c.archetype = ["card.yi_sun_sin.strict_training.archetype"]
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DRAW; ea.value = 2; ea.base_value = 2
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.HEAL_ALL; eb.value = 40; eb.base_value = 40
	c.effects = [ea, eb]; return c

# ─────────────────────────────────────────
# 필사즉생 10 — morale_per_turn + 저HP 조건 스파인
# ─────────────────────────────────────────

static func _miraculous_recovery() -> Resource:
	# [F] 기사회생 — COMMON, 1코, SKILL: HEAL 75 SELF
	var c := CardRes.new()
	c.card_name = "card.yi_sun_sin.miraculous_recovery.name"; c.owner_id = "yi_sun_sin"; c.cost = 1
	c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "idle"
	c.archetype = ["card.yi_sun_sin.miraculous_recovery.archetype"]
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.HEAL; e.value = 75; e.base_value = 75; e.target = "SELF"
	c.effects = [e]; return c

static func _all_in() -> Resource:
	# [F] 이판사판 — UNCOMMON, 1코, ATTACK: SACRIFICE_HP 60 + DMG 188
	var c := CardRes.new()
	c.card_name = "card.yi_sun_sin.all_in.name"; c.owner_id = "yi_sun_sin"; c.cost = 1
	c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "attack"
	c.archetype = ["card.yi_sun_sin.all_in.archetype"]
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.SACRIFICE_HP; ea.value = 60; ea.base_value = 60; ea.target = "SELF"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.DAMAGE; eb.value = 150; eb.base_value = 150; eb.target = "SINGLE"
	eb.damage_type = "slash"
	c.effects = [ea, eb]; return c

static func _last_stand() -> Resource:
	# [F] 배수진 — RARE, 1코, SKILL: SACRIFICE_HP 80 + BLOCK 280
	var c := CardRes.new()
	c.card_name = "card.yi_sun_sin.last_stand.name"; c.owner_id = "yi_sun_sin"; c.cost = 1
	c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	c.archetype = ["card.yi_sun_sin.last_stand.archetype"]
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.SACRIFICE_HP; ea.value = 80; ea.base_value = 80; ea.target = "SELF"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.BLOCK; eb.value = 200; eb.base_value = 200
	c.effects = [ea, eb]; return c

static func _death_resolve() -> Resource:
	# [A] 죽음의 결의 — UNCOMMON, 1코, POWER: 매 턴 시작 시 사기 +2
	var c := CardRes.new()
	c.card_name = "card.yi_sun_sin.death_resolve.name"; c.owner_id = "yi_sun_sin"; c.cost = 1
	c.card_type = CardRes.CardType.POWER
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	c.archetype = ["card.yi_sun_sin.death_resolve.archetype"]
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.APPLY_STATUS
	e.status_type = "power.morale_per_turn"; e.value = 1; e.base_value = 1; e.target = "SELF"
	var es := EffRes.new()
	es.effect_type = EffRes.EffectType.SACRIFICE_HP; es.value = 5; es.base_value = 5
	c.effects = [e, es]; return c

static func _fighting_spirit() -> Resource:
	# [A] 투지 — RARE, 1코, SKILL: 현재 사기 스택 × 50 방어도 (필사즉생 아키 사기 자원화)
	var c := CardRes.new()
	c.card_name = "card.yi_sun_sin.fighting_spirit.name"; c.owner_id = "yi_sun_sin"; c.cost = 1
	c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	c.archetype = ["card.yi_sun_sin.fighting_spirit.archetype"]
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.MORALE_TO_BLOCK; e.value = 50; e.base_value = 50
	c.effects = [e]; return c

static func _death_or_glory() -> Resource:
	# [P] 필사즉생 — LEGENDARY, 1코, ATTACK: CONDITIONAL_DMG (low_hp: 200 / else: 100)
	var c := CardRes.new()
	c.card_name = "card.yi_sun_sin.death_or_glory.name"; c.owner_id = "yi_sun_sin"; c.cost = 1
	c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.LEGENDARY; c.play_animation = "attack"
	c.archetype = ["card.yi_sun_sin.death_or_glory.archetype"]
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.CONDITIONAL_DMG
	e.value = 100; e.base_value = 100
	e.bonus_value = 200; e.base_bonus_value = 200
	e.status_type = "low_hp"; e.target = "SINGLE"
	e.damage_type = "slash"
	c.effects = [e]; return c

static func _crisis_breakthrough() -> Resource:
	# [P] 위기 돌파 — RARE, 2코, ATTACK: CONDITIONAL_DMG (very_low_hp: 340 / else: 120)
	var c := CardRes.new()
	c.card_name = "card.yi_sun_sin.crisis_breakthrough.name"; c.owner_id = "yi_sun_sin"; c.cost = 2
	c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "attack"
	c.archetype = ["card.yi_sun_sin.crisis_breakthrough.archetype"]
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.CONDITIONAL_DMG
	e.value = 120; e.base_value = 120
	e.bonus_value = 340; e.base_bonus_value = 340
	e.status_type = "very_low_hp"; e.target = "SINGLE"
	e.damage_type = "blunt"
	c.effects = [e]; return c

static func _decisive_strike() -> Resource:
	# [C] 사지결단 — RARE, 1코, ATTACK: CONDITIONAL_DMG (low_hp: 150 / else: 80) + low_hp 시 BLOCK 40
	# 중복 다양화: 필사즉생 low_hp 조건 카드 중 Connector 슬롯 — 위기에 공방 일체로 차별화
	var c := CardRes.new()
	c.card_name = "card.yi_sun_sin.decisive_strike.name"; c.owner_id = "yi_sun_sin"; c.cost = 1
	c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "attack"
	c.archetype = ["card.yi_sun_sin.decisive_strike.archetype"]
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.CONDITIONAL_DMG
	e.value = 80; e.base_value = 80
	e.bonus_value = 150; e.base_bonus_value = 150
	e.status_type = "low_hp"; e.target = "SINGLE"
	e.damage_type = "slash"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.BLOCK
	eb.value = 40; eb.base_value = 40; eb.target = "SELF"
	eb.condition = "low_hp"
	c.effects = [e, eb]; return c

static func _bloody_battle() -> Resource:
	# [C] 혈전 — RARE, 1코, ATTACK: CONDITIONAL_DMG (low_hp: 120 / else: 70) + BLOCK 40
	var c := CardRes.new()
	c.card_name = "card.yi_sun_sin.bloody_battle.name"; c.owner_id = "yi_sun_sin"; c.cost = 1
	c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "attack"
	c.archetype = ["card.yi_sun_sin.bloody_battle.archetype"]
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.CONDITIONAL_DMG
	ea.value = 70; ea.base_value = 70
	ea.bonus_value = 120; ea.base_bonus_value = 120
	ea.status_type = "low_hp"; ea.target = "SINGLE"
	ea.damage_type = "slash"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.BLOCK; eb.value = 40; eb.base_value = 40
	c.effects = [ea, eb]; return c

static func _phoenix() -> Resource:
	# [Chaos] 불사조 — LEGENDARY, 2코, SKILL: HEAL 140 SELF + DRAW 1 (low_hp 조건)
	var c := CardRes.new()
	c.card_name = "card.yi_sun_sin.phoenix.name"; c.owner_id = "yi_sun_sin"; c.cost = 2
	c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.LEGENDARY; c.play_animation = "idle"
	c.archetype = ["card.yi_sun_sin.phoenix.archetype"]
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.HEAL; ea.value = 140; ea.base_value = 140; ea.target = "SELF"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.DRAW; eb.value = 1; eb.base_value = 1
	eb.condition = "low_hp"
	c.effects = [ea, eb]; return c
