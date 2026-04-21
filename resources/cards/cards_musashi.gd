# resources/cards/cards_musashi.gd
# 미야모토 무사시 카드 15장 — HP 1000 스케일 기준
# 아키타입: 이도류(DMG × 2) / 결투(enemy_count==1 조건) / 무심(hand_size==0 조건)
const CardRes = preload("res://resources/card_resource.gd")
const EffRes  = preload("res://resources/effect_resource.gd")

static func starter_deck() -> Array:
	var cards: Array = []
	for _i in range(3):
		cards.append(_slash())
	for _i in range(2):
		cards.append(_dodge())
	return cards

static func pool() -> Array:
	return [
		_niten_strike(), _observe(), _patience(),
		_duel(), _empty_mind(), _two_sword_dance(),
		_lone_stance(), _focused_cut(), _void_step(),
		_mushin_slash(), _earthly_cut(), _thousand_cuts(),
		_gorin_no_sho(),
	]

# ─────────────────────────────────────────
# 시작덱 (2종)
# ─────────────────────────────────────────

static func _slash() -> Resource:
	var c := CardRes.new()
	c.card_name = "참격"; c.owner_id = "musashi"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "attack"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.DAMAGE
	e.value = 100; e.base_value = 100; e.target = "SINGLE"
	c.effects = [e]; return c

static func _dodge() -> Resource:
	var c := CardRes.new()
	c.card_name = "회피"; c.owner_id = "musashi"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "idle"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.BLOCK
	e.value = 80; e.base_value = 80; e.target = "SELF"
	c.effects = [e]; return c

# ─────────────────────────────────────────
# 풀 카드 13장
# ─────────────────────────────────────────

static func _niten_strike() -> Resource:
	# 이도류 — COMMON, 1코, 공격, 이도류: DMG 50 × 2
	var c := CardRes.new()
	c.card_name = "이도류"; c.owner_id = "musashi"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "attack"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.DAMAGE
	e.value = 50; e.base_value = 50; e.target = "SINGLE"; e.hit_count = 2
	c.effects = [e]; return c

static func _observe() -> Resource:
	# 관찰 — COMMON, 0코, 기술: DRAW 2
	var c := CardRes.new()
	c.card_name = "관찰"; c.owner_id = "musashi"
	c.cost = 0; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "idle"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.DRAW
	e.value = 2; e.base_value = 2
	c.effects = [e]; return c

static func _patience() -> Resource:
	# 인내 — COMMON, 0코, 기술: BLOCK 40 + DRAW 1
	var c := CardRes.new()
	c.card_name = "인내"; c.owner_id = "musashi"
	c.cost = 0; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "idle"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.BLOCK
	ea.value = 40; ea.base_value = 40; ea.target = "SELF"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.DRAW
	eb.value = 1; eb.base_value = 1
	c.effects = [ea, eb]; return c

static func _duel() -> Resource:
	# 결투 — UNCOMMON, 1코, 공격, 결투: DMG 100/160 (적 1명일 때 160)
	var c := CardRes.new()
	c.card_name = "결투"; c.owner_id = "musashi"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "attack"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.CONDITIONAL_DMG
	e.value = 100; e.base_value = 100; e.bonus_value = 160; e.base_bonus_value = 160
	e.target = "SINGLE"; e.status_type = "enemy_count_1"
	c.effects = [e]; return c

static func _empty_mind() -> Resource:
	# 무심 — UNCOMMON, 1코, 공격, 무심: DMG 80/160 (손패 0일 때 160)
	var c := CardRes.new()
	c.card_name = "무심"; c.owner_id = "musashi"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "attack"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.CONDITIONAL_DMG
	e.value = 80; e.base_value = 80; e.bonus_value = 160; e.base_bonus_value = 160
	e.target = "SINGLE"; e.status_type = "hand_size_0"
	c.effects = [e]; return c

static func _two_sword_dance() -> Resource:
	# 이도류 춤 — UNCOMMON, 2코, 공격, 이도류: DMG 70 × 2
	var c := CardRes.new()
	c.card_name = "이도류 춤"; c.owner_id = "musashi"
	c.cost = 2; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "attack"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.DAMAGE
	e.value = 70; e.base_value = 70; e.target = "SINGLE"; e.hit_count = 2
	c.effects = [e]; return c

static func _lone_stance() -> Resource:
	# 독고 자세 — UNCOMMON, 0코, 기술: BLOCK 60 (결투 조건 활성화 힌트)
	var c := CardRes.new()
	c.card_name = "독고 자세"; c.owner_id = "musashi"
	c.cost = 0; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.BLOCK
	e.value = 60; e.base_value = 60; e.target = "SELF"
	c.effects = [e]; return c

static func _focused_cut() -> Resource:
	# 집중 베기 — RARE, 1코, 공격, 이도류: DMG 60 × 2 + DRAW 1
	var c := CardRes.new()
	c.card_name = "집중 베기"; c.owner_id = "musashi"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "attack"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 60; ea.base_value = 60; ea.target = "SINGLE"; ea.hit_count = 2
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.DRAW
	eb.value = 1; eb.base_value = 1
	c.effects = [ea, eb]; return c

static func _void_step() -> Resource:
	# 허공 발걸음 — RARE, 0코, 기술: BLOCK 80 + DRAW 1
	var c := CardRes.new()
	c.card_name = "허공 발걸음"; c.owner_id = "musashi"
	c.cost = 0; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.BLOCK
	ea.value = 80; ea.base_value = 80; ea.target = "SELF"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.DRAW
	eb.value = 1; eb.base_value = 1
	c.effects = [ea, eb]; return c

static func _mushin_slash() -> Resource:
	# 무심검 — RARE, 2코, 공격, 무심: DMG 120/250 ALL (손패 0일 때 250)
	var c := CardRes.new()
	c.card_name = "무심검"; c.owner_id = "musashi"
	c.cost = 2; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "attack"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.CONDITIONAL_DMG
	e.value = 120; e.base_value = 120; e.bonus_value = 250; e.base_bonus_value = 250
	e.target = "ALL"; e.status_type = "hand_size_0"
	c.effects = [e]; return c

static func _earthly_cut() -> Resource:
	# 지의 베기 — RARE, 1코, 공격, 결투: DMG 130/200 (적 1명일 때 200) + WEAK 1
	var c := CardRes.new()
	c.card_name = "지의 베기"; c.owner_id = "musashi"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "attack"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.CONDITIONAL_DMG
	ea.value = 130; ea.base_value = 130; ea.bonus_value = 200; ea.base_bonus_value = 200
	ea.target = "SINGLE"; ea.status_type = "enemy_count_1"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.APPLY_STATUS
	eb.value = 1; eb.base_value = 1; eb.target = "SINGLE"; eb.status_type = "weak"
	c.effects = [ea, eb]; return c

static func _thousand_cuts() -> Resource:
	# 천의 베기 — LEGENDARY, 2코, 공격, 이도류: DMG 80 × 3
	var c := CardRes.new()
	c.card_name = "천의 베기"; c.owner_id = "musashi"
	c.cost = 2; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.LEGENDARY; c.play_animation = "attack"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.DAMAGE
	e.value = 80; e.base_value = 80; e.target = "SINGLE"; e.hit_count = 3
	c.effects = [e]; return c

static func _gorin_no_sho() -> Resource:
	# 오륜의 검 — DIVINE, 1코, 공격, 결투+무심: DMG 200/400 (적 1명+손패 0일 때 400)
	var c := CardRes.new()
	c.card_name = "오륜의 검"; c.owner_id = "musashi"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.DIVINE; c.play_animation = "attack"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.CONDITIONAL_DMG
	e.value = 200; e.base_value = 200; e.bonus_value = 400; e.base_bonus_value = 400
	e.target = "SINGLE"; e.status_type = "enemy_count_1"
	c.effects = [e]; return c
