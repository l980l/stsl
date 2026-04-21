# resources/cards/cards_genghis_khan.gd
# 칭기즈칸 카드 15장 — HP 1000 스케일 기준
# 아키타입: 기동(0~1코 다수 플레이) / 몽골 기병(DMG ALL) / 약탈(처치 보상)
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
		_cavalry_charge(), _scout(), _arrow_volley(),
		_ambush(), _supply_cut(), _encirclement(),
		_mingens_order(), _poison_arrow(), _steppe_storm(),
		_conquerors_ambition(), _long_march(), _great_khans_command(),
		_genghis_fury(),
	]

# ─────────────────────────────────────────
# 시작덱 (2종)
# ─────────────────────────────────────────

static func _strike() -> Resource:
	var c := CardRes.new()
	c.card_name = "스트라이크"; c.owner_id = "genghis_khan"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "attack"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.DAMAGE
	e.value = 100; e.base_value = 100; e.target = "SINGLE"
	c.effects = [e]; return c

static func _defend() -> Resource:
	var c := CardRes.new()
	c.card_name = "디펜드"; c.owner_id = "genghis_khan"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "idle"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.BLOCK
	e.value = 80; e.base_value = 80; e.target = "SELF"
	c.effects = [e]; return c

# ─────────────────────────────────────────
# 풀 카드 13장
# ─────────────────────────────────────────

static func _cavalry_charge() -> Resource:
	# 기마 돌격 — COMMON, 1코, 공격, 몽골 기병: DMG 50 ALL
	var c := CardRes.new()
	c.card_name = "기마 돌격"; c.owner_id = "genghis_khan"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "attack"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.DAMAGE
	e.value = 50; e.base_value = 50; e.target = "ALL"
	c.effects = [e]; return c

static func _scout() -> Resource:
	# 정찰 — COMMON, 0코, 기술, 기동: DRAW 2
	var c := CardRes.new()
	c.card_name = "정찰"; c.owner_id = "genghis_khan"
	c.cost = 0; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "idle"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.DRAW
	e.value = 2; e.base_value = 2
	c.effects = [e]; return c

static func _arrow_volley() -> Resource:
	# 화살 세례 — UNCOMMON, 1코, 공격, 몽골 기병: DMG 55 ALL
	var c := CardRes.new()
	c.card_name = "화살 세례"; c.owner_id = "genghis_khan"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "attack"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.DAMAGE
	e.value = 55; e.base_value = 55; e.target = "ALL"
	c.effects = [e]; return c

static func _ambush() -> Resource:
	# 기습 — UNCOMMON, 0코, 공격, 기동: DMG 70 SINGLE
	var c := CardRes.new()
	c.card_name = "기습"; c.owner_id = "genghis_khan"
	c.cost = 0; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "attack"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.DAMAGE
	e.value = 70; e.base_value = 70; e.target = "SINGLE"
	c.effects = [e]; return c

static func _supply_cut() -> Resource:
	# 보급선 차단 — UNCOMMON, 1코, 기술, 기동/약탈: DRAW 1 + ENERGY+1
	var c := CardRes.new()
	c.card_name = "보급선 차단"; c.owner_id = "genghis_khan"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DRAW
	ea.value = 1; ea.base_value = 1
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.ENERGY
	eb.value = 1; eb.base_value = 1
	c.effects = [ea, eb]; return c

static func _encirclement() -> Resource:
	# 포위 전술 — UNCOMMON, 1코, 공격, 몽골 기병: DMG 60 ALL + WEAK 1 ALL
	var c := CardRes.new()
	c.card_name = "포위 전술"; c.owner_id = "genghis_khan"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "attack"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 60; ea.base_value = 60; ea.target = "ALL"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.APPLY_STATUS
	eb.value = 1; eb.base_value = 1; eb.target = "ALL"; eb.status_type = "weak"
	c.effects = [ea, eb]; return c

static func _mingens_order() -> Resource:
	# 천호장의 령 — RARE, 1코, 기술, 기동: DRAW 3
	var c := CardRes.new()
	c.card_name = "천호장의 령"; c.owner_id = "genghis_khan"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.DRAW
	e.value = 3; e.base_value = 3
	c.effects = [e]; return c

static func _poison_arrow() -> Resource:
	# 독화살 — RARE, 1코, 공격, 몽골 기병: DMG 60 ALL + POISON 2 ALL
	var c := CardRes.new()
	c.card_name = "독화살"; c.owner_id = "genghis_khan"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "attack"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 60; ea.base_value = 60; ea.target = "ALL"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.APPLY_STATUS
	eb.value = 2; eb.base_value = 2; eb.target = "ALL"; eb.status_type = "poison"
	c.effects = [ea, eb]; return c

static func _steppe_storm() -> Resource:
	# 초원의 폭풍 — RARE, 2코, 공격, 몽골 기병: DMG 80 ALL
	var c := CardRes.new()
	c.card_name = "초원의 폭풍"; c.owner_id = "genghis_khan"
	c.cost = 2; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "attack"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.DAMAGE
	e.value = 80; e.base_value = 80; e.target = "ALL"
	c.effects = [e]; return c

static func _conquerors_ambition() -> Resource:
	# 정복자의 야망 — RARE, 0코, 공격, 약탈: DMG 80 + DRAW 1
	var c := CardRes.new()
	c.card_name = "정복자의 야망"; c.owner_id = "genghis_khan"
	c.cost = 0; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "attack"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 80; ea.base_value = 80; ea.target = "SINGLE"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.DRAW
	eb.value = 1; eb.base_value = 1
	c.effects = [ea, eb]; return c

static func _long_march() -> Resource:
	# 만리 원정 — RARE, 1코, 기술, 기동: 이번 턴 카드 사용 횟수 × 30 BLOCK
	var c := CardRes.new()
	c.card_name = "만리 원정"; c.owner_id = "genghis_khan"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.BLOCK_PER_CARDS_PLAYED
	e.value = 30; e.base_value = 30
	c.effects = [e]; return c

static func _great_khans_command() -> Resource:
	# 대칸의 명령 — LEGENDARY, 2코, 기술, 기동: DRAW 3 + 이번 턴 코스트 0
	var c := CardRes.new()
	c.card_name = "대칸의 명령"; c.owner_id = "genghis_khan"
	c.cost = 2; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.LEGENDARY; c.play_animation = "idle"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DRAW
	ea.value = 3; ea.base_value = 3
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.COST_ZERO_TURN
	eb.value = 0; eb.base_value = 0
	c.effects = [ea, eb]; return c

static func _genghis_fury() -> Resource:
	# 징기스의 분노 — DIVINE, 1코, 공격, 몽골 기병: DMG 60 ALL × 2
	var c := CardRes.new()
	c.card_name = "징기스의 분노"; c.owner_id = "genghis_khan"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.DIVINE; c.play_animation = "attack"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.DAMAGE
	e.value = 60; e.base_value = 60; e.target = "ALL"; e.hit_count = 2
	c.effects = [e]; return c
