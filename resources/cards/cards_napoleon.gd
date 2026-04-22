# resources/cards/cards_napoleon.gd
# 나폴레옹 카드 40장 — HP 1000 스케일 기준
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
		# v1 카드 13장 (시작덱 제외)
		_swift_advance(), _line_reform(), _hussar_charge(),
		_grand_armee_shield(), _salvo(), _marshal_appointment(),
		_arcole_breakthrough(), _artillery_volley(), _jena_surprise(),
		_borodino_bombardment(), _total_assault_order(), _emperors_command(),
		_emperors_spirit(),
		# v2 추가 카드 25장
		_advance_order(), _trench_construction(), _scout_patrol(),
		_drum_beat(), _charge_bugle(), _cavalry_threat(),
		_guard_charge(), _breakthrough_advance(), _commanders_eye(),
		_supply_line_secured(), _artillery_gather(), _mobile_firing(),
		_bridgehead_capture(), _imperial_artillery(), _imperial_infantry_call(),
		_austerlitz_maneuver(), _waterloo_resolve(), _eagle_standard(),
		_victory_proclamation(), _great_army_siege(), _emperors_encirclement(),
		_one_man_army(), _strategic_retreat(), _emperors_assault(),
		_empire_glory(),
	]

# ─────────────────────────────────────────
# 시작덱 (2종)
# ─────────────────────────────────────────

static func _strike() -> Resource:
	# 스트라이크 — COMMON, 1코, ATTACK, 돌격: DMG 100
	var c := CardRes.new()
	c.card_name = "스트라이크"; c.owner_id = "napoleon"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "attack"
	c.archetype = "돌격"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.DAMAGE
	e.value = 100; e.base_value = 100; e.target = "SINGLE"
	c.effects = [e]; return c

static func _defend() -> Resource:
	# 디펜드 — COMMON, 1코, SKILL, 군단: BLOCK 80
	var c := CardRes.new()
	c.card_name = "디펜드"; c.owner_id = "napoleon"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "idle"
	c.archetype = "군단"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.BLOCK
	e.value = 80; e.base_value = 80; e.target = "SELF"
	c.effects = [e]; return c

# ─────────────────────────────────────────
# v1 풀 카드 13장
# ─────────────────────────────────────────

static func _swift_advance() -> Resource:
	# 신속 기동 — COMMON, 1코, ATTACK, 돌격: DMG 100 + MORALE+1
	var c := CardRes.new()
	c.card_name = "신속 기동"; c.owner_id = "napoleon"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "attack"
	c.archetype = "돌격"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 100; ea.base_value = 100; ea.target = "SINGLE"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.GAIN_MORALE
	eb.value = 1; eb.base_value = 1
	c.effects = [ea, eb]; return c

static func _line_reform() -> Resource:
	# 전열 재편 — COMMON, 0코, SKILL, 지휘: DRAW 1
	var c := CardRes.new()
	c.card_name = "전열 재편"; c.owner_id = "napoleon"
	c.cost = 0; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "idle"
	c.archetype = "지휘"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.DRAW
	e.value = 1; e.base_value = 1
	c.effects = [e]; return c

static func _hussar_charge() -> Resource:
	# 경기병 돌격 — UNCOMMON, 1코, ATTACK, 돌격: DMG 120 + MORALE+1
	var c := CardRes.new()
	c.card_name = "경기병 돌격"; c.owner_id = "napoleon"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "attack"
	c.archetype = "돌격"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 120; ea.base_value = 120; ea.target = "SINGLE"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.GAIN_MORALE
	eb.value = 1; eb.base_value = 1
	c.effects = [ea, eb]; return c

static func _grand_armee_shield() -> Resource:
	# 그랑다르메의 방패 — UNCOMMON, 1코, SKILL, 군단: BLOCK 110
	var c := CardRes.new()
	c.card_name = "그랑다르메의 방패"; c.owner_id = "napoleon"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	c.archetype = "군단"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.BLOCK
	e.value = 110; e.base_value = 110; e.target = "SELF"
	c.effects = [e]; return c

static func _salvo() -> Resource:
	# 살보 사격 — UNCOMMON, 1코, ATTACK, 돌격: DMG 100 + ENERGY+1
	var c := CardRes.new()
	c.card_name = "살보 사격"; c.owner_id = "napoleon"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "attack"
	c.archetype = "돌격"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 100; ea.base_value = 100; ea.target = "SINGLE"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.ENERGY
	eb.value = 1; eb.base_value = 1
	c.effects = [ea, eb]; return c

static func _marshal_appointment() -> Resource:
	# 원수 서임 — UNCOMMON, 1코, SKILL, 지휘: DRAW 2 + MORALE+1
	var c := CardRes.new()
	c.card_name = "원수 서임"; c.owner_id = "napoleon"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	c.archetype = "지휘"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DRAW
	ea.value = 2; ea.base_value = 2
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.GAIN_MORALE
	eb.value = 1; eb.base_value = 1
	c.effects = [ea, eb]; return c

static func _arcole_breakthrough() -> Resource:
	# 아르콜레 돌파 — RARE, 1코, ATTACK, 돌격: DMG 100 + BLOCK 80
	var c := CardRes.new()
	c.card_name = "아르콜레 돌파"; c.owner_id = "napoleon"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "attack"
	c.archetype = "돌격"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 100; ea.base_value = 100; ea.target = "SINGLE"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.BLOCK
	eb.value = 80; eb.base_value = 80; eb.target = "SELF"
	c.effects = [ea, eb]; return c

static func _artillery_volley() -> Resource:
	# 포병 일제사격 — RARE, 1코, ATTACK, 군단: DMG 80 ALL
	var c := CardRes.new()
	c.card_name = "포병 일제사격"; c.owner_id = "napoleon"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "attack"
	c.archetype = "군단"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.DAMAGE
	e.value = 80; e.base_value = 80; e.target = "ALL"
	c.effects = [e]; return c

static func _jena_surprise() -> Resource:
	# 예나의 기습 — RARE, 1코, ATTACK, 돌격: DMG 100 + POISON 3
	var c := CardRes.new()
	c.card_name = "예나의 기습"; c.owner_id = "napoleon"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "attack"
	c.archetype = "돌격"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 100; ea.base_value = 100; ea.target = "SINGLE"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.APPLY_STATUS
	eb.status_type = "poison"; eb.value = 3; eb.base_value = 3; eb.target = "SINGLE"
	c.effects = [ea, eb]; return c

static func _borodino_bombardment() -> Resource:
	# 보로디노 포격 — RARE, 2코, ATTACK, 군단: CONDITIONAL_DMG (사기 있으면 DMG 200 / 없으면 140)
	var c := CardRes.new()
	c.card_name = "보로디노 포격"; c.owner_id = "napoleon"
	c.cost = 2; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "attack"
	c.archetype = "군단"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.CONDITIONAL_DMG
	e.value = 140; e.base_value = 140
	e.bonus_value = 200; e.base_bonus_value = 200
	e.status_type = "has_morale"; e.target = "SINGLE"
	c.effects = [e]; return c

static func _total_assault_order() -> Resource:
	# 총공세 명령 — RARE, 1코, SKILL, 지휘: MORALE+2 + DRAW 1
	var c := CardRes.new()
	c.card_name = "총공세 명령"; c.owner_id = "napoleon"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	c.archetype = "지휘"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.GAIN_MORALE
	ea.value = 2; ea.base_value = 2
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.DRAW
	eb.value = 1; eb.base_value = 1
	c.effects = [ea, eb]; return c

static func _emperors_command() -> Resource:
	# 황제의 명령 — LEGENDARY, 2코, ATTACK, 지휘: DMG 80 ALL + MORALE+2
	var c := CardRes.new()
	c.card_name = "황제의 명령"; c.owner_id = "napoleon"
	c.cost = 2; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.LEGENDARY; c.play_animation = "attack"
	c.archetype = "지휘"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 80; ea.base_value = 80; ea.target = "ALL"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.GAIN_MORALE
	eb.value = 2; eb.base_value = 2
	c.effects = [ea, eb]; return c

static func _emperors_spirit() -> Resource:
	# 황제의 기개 — DIVINE, 0코, ATTACK, 돌격: CONSUME_MORALE(3)→DMG 300 + WEAK 1
	var c := CardRes.new()
	c.card_name = "황제의 기개"; c.owner_id = "napoleon"
	c.cost = 0; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.DIVINE; c.play_animation = "attack"
	c.archetype = "돌격"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.CONSUME_MORALE
	ea.value = 3; ea.base_value = 3
	ea.bonus_value = 300; ea.base_bonus_value = 300; ea.target = "SINGLE"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.APPLY_STATUS
	eb.status_type = "weak"; eb.value = 1; eb.base_value = 1; eb.target = "SINGLE"
	c.effects = [ea, eb]; return c

# ─────────────────────────────────────────
# v2 추가 카드 25장
# ─────────────────────────────────────────

static func _advance_order() -> Resource:
	# 전진 명령 — COMMON, 1코, ATTACK, 돌격: DMG 100 + MORALE+1
	var c := CardRes.new()
	c.card_name = "전진 명령"; c.owner_id = "napoleon"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "attack"
	c.archetype = "돌격"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 100; ea.base_value = 100; ea.target = "SINGLE"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.GAIN_MORALE
	eb.value = 1; eb.base_value = 1
	c.effects = [ea, eb]; return c

static func _trench_construction() -> Resource:
	# 참호 구축 — COMMON, 1코, SKILL, 군단: BLOCK 80
	var c := CardRes.new()
	c.card_name = "참호 구축"; c.owner_id = "napoleon"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "idle"
	c.archetype = "군단"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.BLOCK
	e.value = 80; e.base_value = 80; e.target = "SELF"
	c.effects = [e]; return c

static func _scout_patrol() -> Resource:
	# 척후 정찰 — COMMON, 0코, SKILL, 지휘: DRAW 1 + ENERGY+1
	var c := CardRes.new()
	c.card_name = "척후 정찰"; c.owner_id = "napoleon"
	c.cost = 0; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "idle"
	c.archetype = "지휘"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DRAW
	ea.value = 1; ea.base_value = 1
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.ENERGY
	eb.value = 1; eb.base_value = 1
	c.effects = [ea, eb]; return c

static func _drum_beat() -> Resource:
	# 북소리 — COMMON, 0코, SKILL, 군단: MORALE+1
	var c := CardRes.new()
	c.card_name = "북소리"; c.owner_id = "napoleon"
	c.cost = 0; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "idle"
	c.archetype = "군단"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.GAIN_MORALE
	e.value = 1; e.base_value = 1
	c.effects = [e]; return c

static func _charge_bugle() -> Resource:
	# 진격 나팔 — COMMON, 1코, SKILL, 지휘: DRAW 1 + MORALE+1
	var c := CardRes.new()
	c.card_name = "진격 나팔"; c.owner_id = "napoleon"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "idle"
	c.archetype = "지휘"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DRAW
	ea.value = 1; ea.base_value = 1
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.GAIN_MORALE
	eb.value = 1; eb.base_value = 1
	c.effects = [ea, eb]; return c

static func _cavalry_threat() -> Resource:
	# 기병 위협 — COMMON, 1코, ATTACK, 돌격: DMG 100
	var c := CardRes.new()
	c.card_name = "기병 위협"; c.owner_id = "napoleon"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "attack"
	c.archetype = "돌격"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.DAMAGE
	e.value = 100; e.base_value = 100; e.target = "SINGLE"
	c.effects = [e]; return c

static func _guard_charge() -> Resource:
	# 근위대 돌격 — UNCOMMON, 1코, ATTACK, 군단: SUMMON_TOKEN 1 + DMG 80
	var c := CardRes.new()
	c.card_name = "근위대 돌격"; c.owner_id = "napoleon"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "attack"
	c.archetype = "군단"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.SUMMON_TOKEN
	ea.value = 1; ea.base_value = 1
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.DAMAGE
	eb.value = 80; eb.base_value = 80; eb.target = "SINGLE"
	c.effects = [ea, eb]; return c

static func _breakthrough_advance() -> Resource:
	# 전선 돌파 — UNCOMMON, 1코, ATTACK, 돌격: DMG 110 + COST_NEXT -1
	var c := CardRes.new()
	c.card_name = "전선 돌파"; c.owner_id = "napoleon"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "attack"
	c.archetype = "돌격"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 110; ea.base_value = 110; ea.target = "SINGLE"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.COST_NEXT
	eb.value = 1; eb.base_value = 1
	c.effects = [ea, eb]; return c

static func _commanders_eye() -> Resource:
	# 지휘관의 눈 — UNCOMMON, 1코, SKILL, 지휘: DRAW 2 + ENERGY+1
	var c := CardRes.new()
	c.card_name = "지휘관의 눈"; c.owner_id = "napoleon"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	c.archetype = "지휘"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DRAW
	ea.value = 2; ea.base_value = 2
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.ENERGY
	eb.value = 1; eb.base_value = 1
	c.effects = [ea, eb]; return c

static func _supply_line_secured() -> Resource:
	# 보급선 확보 — UNCOMMON, 0코, SKILL, 지휘: DRAW 1 + MORALE+1
	var c := CardRes.new()
	c.card_name = "보급선 확보"; c.owner_id = "napoleon"
	c.cost = 0; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	c.archetype = "지휘"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DRAW
	ea.value = 1; ea.base_value = 1
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.GAIN_MORALE
	eb.value = 1; eb.base_value = 1
	c.effects = [ea, eb]; return c

static func _artillery_gather() -> Resource:
	# 포병 집결 — UNCOMMON, 1코, SKILL, 군단: SUMMON_TOKEN 1 + BLOCK 60
	var c := CardRes.new()
	c.card_name = "포병 집결"; c.owner_id = "napoleon"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	c.archetype = "군단"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.SUMMON_TOKEN
	ea.value = 1; ea.base_value = 1
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.BLOCK
	eb.value = 60; eb.base_value = 60; eb.target = "SELF"
	c.effects = [ea, eb]; return c

static func _mobile_firing() -> Resource:
	# 기동 사격 — UNCOMMON, 1코, ATTACK, 돌격: DMG 100 + MORALE+1 + ENERGY+1
	var c := CardRes.new()
	c.card_name = "기동 사격"; c.owner_id = "napoleon"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "attack"
	c.archetype = "돌격"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 100; ea.base_value = 100; ea.target = "SINGLE"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.GAIN_MORALE
	eb.value = 1; eb.base_value = 1
	var ec := EffRes.new()
	ec.effect_type = EffRes.EffectType.ENERGY
	ec.value = 1; ec.base_value = 1
	c.effects = [ea, eb, ec]; return c

static func _bridgehead_capture() -> Resource:
	# 교두보 점령 — UNCOMMON, 2코, SKILL, 군단: BLOCK_ALL 60
	var c := CardRes.new()
	c.card_name = "교두보 점령"; c.owner_id = "napoleon"
	c.cost = 2; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	c.archetype = "군단"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.BLOCK_ALL
	e.value = 60; e.base_value = 60
	c.effects = [e]; return c

static func _imperial_artillery() -> Resource:
	# 황실 포병대 — UNCOMMON, 1코, ATTACK, 군단: DMG 80 + MORALE+1
	var c := CardRes.new()
	c.card_name = "황실 포병대"; c.owner_id = "napoleon"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "attack"
	c.archetype = "군단"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 80; ea.base_value = 80; ea.target = "SINGLE"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.GAIN_MORALE
	eb.value = 1; eb.base_value = 1
	c.effects = [ea, eb]; return c

static func _imperial_infantry_call() -> Resource:
	# 제국 보병 소집 — RARE, 2코, SKILL, 군단: SUMMON_TOKEN 2
	var c := CardRes.new()
	c.card_name = "제국 보병 소집"; c.owner_id = "napoleon"
	c.cost = 2; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	c.archetype = "군단"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.SUMMON_TOKEN
	e.value = 2; e.base_value = 2
	c.effects = [e]; return c

static func _austerlitz_maneuver() -> Resource:
	# 아우스터리츠 기동 — RARE, 1코, ATTACK, 돌격: DMG 100 + BLOCK 60 + MORALE+1
	var c := CardRes.new()
	c.card_name = "아우스터리츠 기동"; c.owner_id = "napoleon"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "attack"
	c.archetype = "돌격"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 100; ea.base_value = 100; ea.target = "SINGLE"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.BLOCK
	eb.value = 60; eb.base_value = 60; eb.target = "SELF"
	var ec := EffRes.new()
	ec.effect_type = EffRes.EffectType.GAIN_MORALE
	ec.value = 1; ec.base_value = 1
	c.effects = [ea, eb, ec]; return c

static func _waterloo_resolve() -> Resource:
	# 워털루 이전의 결의 — RARE, 1코, SKILL, 지휘: DRAW 2 + MORALE+2
	var c := CardRes.new()
	c.card_name = "워털루 이전의 결의"; c.owner_id = "napoleon"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	c.archetype = "지휘"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DRAW
	ea.value = 2; ea.base_value = 2
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.GAIN_MORALE
	eb.value = 2; eb.base_value = 2
	c.effects = [ea, eb]; return c

static func _eagle_standard() -> Resource:
	# 독수리 군기 — RARE, 2코, SKILL, 군단: SUMMON_TOKEN 1 + BLOCK_ALL 70
	var c := CardRes.new()
	c.card_name = "독수리 군기"; c.owner_id = "napoleon"
	c.cost = 2; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	c.archetype = "군단"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.SUMMON_TOKEN
	ea.value = 1; ea.base_value = 1
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.BLOCK_ALL
	eb.value = 70; eb.base_value = 70
	c.effects = [ea, eb]; return c

static func _victory_proclamation() -> Resource:
	# 승리의 포고 — RARE, 1코, ATTACK, 지휘: CONDITIONAL_DMG (MORALE 2 이상이면 150 / 미만 100)
	var c := CardRes.new()
	c.card_name = "승리의 포고"; c.owner_id = "napoleon"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "attack"
	c.archetype = "지휘"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.CONDITIONAL_DMG
	e.value = 100; e.base_value = 100
	e.bonus_value = 150; e.base_bonus_value = 150
	e.status_type = "has_morale_2"; e.target = "SINGLE"
	c.effects = [e]; return c

static func _great_army_siege() -> Resource:
	# 대육군 포위전 — RARE, 2코, ATTACK, 군단: DMG 80 ALL (토큰×60 추가 피해는 battle_manager 처리)
	var c := CardRes.new()
	c.card_name = "대육군 포위전"; c.owner_id = "napoleon"
	c.cost = 2; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "attack"
	c.archetype = "군단"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.DAMAGE
	e.value = 80; e.base_value = 80; e.target = "ALL"
	c.effects = [e]; return c

static func _emperors_encirclement() -> Resource:
	# 황제의 포위령 — RARE, 1코, SKILL, 지휘: COST_NEXT -2 + DRAW 1
	var c := CardRes.new()
	c.card_name = "황제의 포위령"; c.owner_id = "napoleon"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	c.archetype = "지휘"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.COST_NEXT
	ea.value = 2; ea.base_value = 2
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.DRAW
	eb.value = 1; eb.base_value = 1
	c.effects = [ea, eb]; return c

static func _one_man_army() -> Resource:
	# 일기당천 — RARE, 1코, ATTACK, 돌격: CONSUME_MORALE(1)→DMG 150 + ENERGY+1
	var c := CardRes.new()
	c.card_name = "일기당천"; c.owner_id = "napoleon"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "attack"
	c.archetype = "돌격"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.CONSUME_MORALE
	ea.value = 1; ea.base_value = 1
	ea.bonus_value = 150; ea.base_bonus_value = 150; ea.target = "SINGLE"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.ENERGY
	eb.value = 1; eb.base_value = 1
	c.effects = [ea, eb]; return c

static func _strategic_retreat() -> Resource:
	# 전략적 후퇴 — LEGENDARY, 1코, SKILL, 지휘: DRAW 3 + MORALE+2 + BLOCK_ALL 60
	var c := CardRes.new()
	c.card_name = "전략적 후퇴"; c.owner_id = "napoleon"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.LEGENDARY; c.play_animation = "idle"
	c.archetype = "지휘"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DRAW
	ea.value = 3; ea.base_value = 3
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.GAIN_MORALE
	eb.value = 2; eb.base_value = 2
	var ec := EffRes.new()
	ec.effect_type = EffRes.EffectType.BLOCK_ALL
	ec.value = 60; ec.base_value = 60
	c.effects = [ea, eb, ec]; return c

static func _emperors_assault() -> Resource:
	# 황제의 돌격 — LEGENDARY, 2코, ATTACK, 돌격: CONSUME_MORALE(2)→DMG 250 + BLOCK 100
	var c := CardRes.new()
	c.card_name = "황제의 돌격"; c.owner_id = "napoleon"
	c.cost = 2; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.LEGENDARY; c.play_animation = "attack"
	c.archetype = "돌격"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.CONSUME_MORALE
	ea.value = 2; ea.base_value = 2
	ea.bonus_value = 250; ea.base_bonus_value = 250; ea.target = "SINGLE"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.BLOCK
	eb.value = 100; eb.base_value = 100; eb.target = "SELF"
	c.effects = [ea, eb]; return c

static func _empire_glory() -> Resource:
	# 제국의 영광 — DIVINE, 0코, POWER, 군단: SUMMON_TOKEN 1 (지속 효과는 battle_manager 처리)
	var c := CardRes.new()
	c.card_name = "제국의 영광"; c.owner_id = "napoleon"
	c.cost = 0; c.card_type = CardRes.CardType.POWER
	c.rarity = CardRes.Rarity.DIVINE; c.play_animation = "idle"
	c.archetype = "군단"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.SUMMON_TOKEN
	e.value = 1; e.base_value = 1
	c.effects = [e]; return c
