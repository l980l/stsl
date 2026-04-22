# resources/cards/cards_musashi.gd
# 미야모토 무사시 카드 40장 (v1 15장 + v2 25장) — HP 1000 스케일 기준
# 아키타입: 이도류(hit_count=2) / 결투(enemy_count_1 조건) / 무심(hand_size_0 조건)
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
		_niten_slash(), _sword_study(),
		_two_sword_form(), _shield_break(), _meditation(), _blood_path(),
		_rapid_strike(), _empty_state(), _single_cut(),
		_afterimage_cut(), _strategy_path(), _five_rings_sword(),
		_mushin_blade(),
		# v2 25장
		_niten_slash2(), _whirlwind_cut(), _peak_aim(), _courage(),
		_void_sword(), _release(),
		_sword_extreme(), _flying_swallow(), _asura_cut(),
		_battle_gaze(), _torrent(), _zen_realm(), _empty_guard(), _detach(),
		_fierce_niten(), _twin_dragon(), _thousand_mile_cut(),
		_peerless_cut(), _forward_cut(), _final_duel(),
		_void_void(), _clear_wind(), _undying(),
		_spirit_sword(), _five_rings_realm(),
	]

# ─────────────────────────────────────────
# 시작덱 (2종)
# ─────────────────────────────────────────

static func _strike() -> Resource:
	var c := CardRes.new()
	c.card_name = "스트라이크"; c.owner_id = "musashi"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "attack"
	c.archetype = "이도류"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.DAMAGE
	e.value = 100; e.base_value = 100; e.target = "SINGLE"
	c.effects = [e]; return c

static func _defend() -> Resource:
	var c := CardRes.new()
	c.card_name = "디펜드"; c.owner_id = "musashi"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "idle"
	c.archetype = "결투"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.BLOCK
	e.value = 80; e.base_value = 80; e.target = "SELF"
	c.effects = [e]; return c

# ─────────────────────────────────────────
# v1 풀 카드 13장
# ─────────────────────────────────────────

static func _niten_slash() -> Resource:
	# 이도 베기 — COMMON, 1코, 공격, 이도류: DMG 60 × 2
	var c := CardRes.new()
	c.card_name = "이도 베기"; c.owner_id = "musashi"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "attack"
	c.archetype = "이도류"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.DAMAGE
	e.value = 60; e.base_value = 60; e.target = "SINGLE"; e.hit_count = 2
	c.effects = [e]; return c

static func _sword_study() -> Resource:
	# 검기 수련 — COMMON, 0코, 기술, 무심: DRAW 1
	var c := CardRes.new()
	c.card_name = "검기 수련"; c.owner_id = "musashi"
	c.cost = 0; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "idle"
	c.archetype = "무심"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.DRAW
	e.value = 1; e.base_value = 1
	c.effects = [e]; return c

static func _two_sword_form() -> Resource:
	# 쌍도류 격 — UNCOMMON, 1코, 공격, 이도류: DMG 65 × 2
	var c := CardRes.new()
	c.card_name = "쌍도류 격"; c.owner_id = "musashi"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "attack"
	c.archetype = "이도류"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.DAMAGE
	e.value = 65; e.base_value = 65; e.target = "SINGLE"; e.hit_count = 2
	c.effects = [e]; return c

static func _shield_break() -> Resource:
	# 방패 격파 — UNCOMMON, 1코, 공격, 결투: DMG 120 + VULNERABLE 1
	var c := CardRes.new()
	c.card_name = "방패 격파"; c.owner_id = "musashi"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "attack"
	c.archetype = "결투"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 120; ea.base_value = 120; ea.target = "SINGLE"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.APPLY_STATUS
	eb.value = 1; eb.base_value = 1; eb.target = "SINGLE"; eb.status_type = "vulnerable"
	c.effects = [ea, eb]; return c

static func _meditation() -> Resource:
	# 명상 — UNCOMMON, 1코, 기술, 무심: DRAW 2 + BLOCK 50
	var c := CardRes.new()
	c.card_name = "명상"; c.owner_id = "musashi"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	c.archetype = "무심"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DRAW
	ea.value = 2; ea.base_value = 2
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.BLOCK
	eb.value = 50; eb.base_value = 50; eb.target = "SELF"
	c.effects = [ea, eb]; return c

static func _blood_path() -> Resource:
	# 혈로 개척 — UNCOMMON, 1코, 공격, 결투: 적 1마리 DMG 180 / 복수 DMG 100
	var c := CardRes.new()
	c.card_name = "혈로 개척"; c.owner_id = "musashi"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "attack"
	c.archetype = "결투"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.CONDITIONAL_DMG
	e.value = 100; e.base_value = 100
	e.bonus_value = 180; e.base_bonus_value = 180
	e.target = "SINGLE"; e.status_type = "enemy_count_1"
	c.effects = [e]; return c

static func _rapid_strike() -> Resource:
	# 연격 — RARE, 1코, 공격, 이도류: DMG 55 × 2 + POISON 2
	var c := CardRes.new()
	c.card_name = "연격"; c.owner_id = "musashi"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "attack"
	c.archetype = "이도류"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 55; ea.base_value = 55; ea.target = "SINGLE"; ea.hit_count = 2
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.APPLY_STATUS
	eb.value = 2; eb.base_value = 2; eb.target = "SINGLE"; eb.status_type = "poison"
	c.effects = [ea, eb]; return c

static func _empty_state() -> Resource:
	# 무아지경 — RARE, 1코, 기술, 무심: hand_size_0 → DRAW 3 + BLOCK 80 / DRAW 1
	# 비DRAW 조건 효과를 DRAW보다 먼저 배치해 hand_size_0 평가 정확성 확보
	var c := CardRes.new()
	c.card_name = "무아지경"; c.owner_id = "musashi"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	c.archetype = "무심"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.BLOCK
	ea.value = 80; ea.base_value = 80; ea.target = "SELF"
	ea.condition = "hand_size_0"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.DRAW
	eb.value = 2; eb.base_value = 2
	eb.condition = "hand_size_0"
	var ec := EffRes.new()
	ec.effect_type = EffRes.EffectType.DRAW
	ec.value = 1; ec.base_value = 1
	c.effects = [ea, eb, ec]; return c

static func _single_cut() -> Resource:
	# 일도양단 — RARE, 2코, 공격, 결투: 적 1마리 DMG 280 / 복수 DMG 160
	var c := CardRes.new()
	c.card_name = "일도양단"; c.owner_id = "musashi"
	c.cost = 2; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "attack"
	c.archetype = "결투"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.CONDITIONAL_DMG
	e.value = 160; e.base_value = 160
	e.bonus_value = 280; e.base_bonus_value = 280
	e.target = "SINGLE"; e.status_type = "enemy_count_1"
	c.effects = [e]; return c

static func _afterimage_cut() -> Resource:
	# 잔영 참 — RARE, 1코, 공격, 이도류: DMG 50 × 2 + BLOCK 60
	var c := CardRes.new()
	c.card_name = "잔영 참"; c.owner_id = "musashi"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "attack"
	c.archetype = "이도류"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 50; ea.base_value = 50; ea.target = "SINGLE"; ea.hit_count = 2
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.BLOCK
	eb.value = 60; eb.base_value = 60; eb.target = "SELF"
	c.effects = [ea, eb]; return c

static func _strategy_path() -> Resource:
	# 병법의 길 — RARE, 1코, 기술, 무심: DRAW 2 (다음 공격 DMG+30 미구현)
	var c := CardRes.new()
	c.card_name = "병법의 길"; c.owner_id = "musashi"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	c.archetype = "무심"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.DRAW
	e.value = 2; e.base_value = 2
	c.effects = [e]; return c

static func _five_rings_sword() -> Resource:
	# 오륜의 검 — LEGENDARY, 2코, 공격, 이도류: DMG 90 × 2
	var c := CardRes.new()
	c.card_name = "오륜의 검"; c.owner_id = "musashi"
	c.cost = 2; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.LEGENDARY; c.play_animation = "attack"
	c.archetype = "이도류"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.DAMAGE
	e.value = 90; e.base_value = 90; e.target = "SINGLE"; e.hit_count = 2
	c.effects = [e]; return c

static func _mushin_blade() -> Resource:
	# 무심검(無心劍) — DIVINE, 0코, 공격, 무심: hand_size_0 → DMG 350 / DMG 150
	var c := CardRes.new()
	c.card_name = "무심검(無心劍)"; c.owner_id = "musashi"
	c.cost = 0; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.DIVINE; c.play_animation = "attack"
	c.archetype = "무심"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.CONDITIONAL_DMG
	e.value = 150; e.base_value = 150
	e.bonus_value = 350; e.base_bonus_value = 350
	e.target = "SINGLE"; e.status_type = "hand_size_0"
	c.effects = [e]; return c

# ─────────────────────────────────────────
# v2 풀 카드 25장
# ─────────────────────────────────────────

static func _niten_slash2() -> Resource:
	# 이도 참격 — COMMON, 1코, 공격, 이도류: DMG 60 × 2
	var c := CardRes.new()
	c.card_name = "이도 참격"; c.owner_id = "musashi"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "attack"
	c.archetype = "이도류"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.DAMAGE
	e.value = 60; e.base_value = 60; e.target = "SINGLE"; e.hit_count = 2
	c.effects = [e]; return c

static func _whirlwind_cut() -> Resource:
	# 선풍참 — COMMON, 1코, 공격, 이도류: DMG 55 × 2 + BLOCK 40
	var c := CardRes.new()
	c.card_name = "선풍참"; c.owner_id = "musashi"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "attack"
	c.archetype = "이도류"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 55; ea.base_value = 55; ea.target = "SINGLE"; ea.hit_count = 2
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.BLOCK
	eb.value = 40; eb.base_value = 40; eb.target = "SELF"
	c.effects = [ea, eb]; return c

static func _peak_aim() -> Resource:
	# 정점의 겨냥 — COMMON, 1코, 공격, 결투: 적 1마리 DMG 140 / 복수 DMG 90
	var c := CardRes.new()
	c.card_name = "정점의 겨냥"; c.owner_id = "musashi"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "attack"
	c.archetype = "결투"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.CONDITIONAL_DMG
	e.value = 90; e.base_value = 90
	e.bonus_value = 140; e.base_bonus_value = 140
	e.target = "SINGLE"; e.status_type = "enemy_count_1"
	c.effects = [e]; return c

static func _courage() -> Resource:
	# 담력 — COMMON, 1코, 방어, 결투: BLOCK 90
	var c := CardRes.new()
	c.card_name = "담력"; c.owner_id = "musashi"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "idle"
	c.archetype = "결투"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.BLOCK
	e.value = 90; e.base_value = 90; e.target = "SELF"
	c.effects = [e]; return c

static func _void_sword() -> Resource:
	# 공허의 검 — COMMON, 1코, 공격, 무심: hand_size_0 → DMG 200 / DMG 100
	var c := CardRes.new()
	c.card_name = "공허의 검"; c.owner_id = "musashi"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "attack"
	c.archetype = "무심"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.CONDITIONAL_DMG
	e.value = 100; e.base_value = 100
	e.bonus_value = 200; e.base_bonus_value = 200
	e.target = "SINGLE"; e.status_type = "hand_size_0"
	c.effects = [e]; return c

static func _release() -> Resource:
	# 내려놓음 — COMMON, 1코, 기술, 무심: DRAW 2
	var c := CardRes.new()
	c.card_name = "내려놓음"; c.owner_id = "musashi"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.COMMON; c.play_animation = "idle"
	c.archetype = "무심"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.DRAW
	e.value = 2; e.base_value = 2
	c.effects = [e]; return c

static func _sword_extreme() -> Resource:
	# 도류 극의 — UNCOMMON, 1코, 공격, 이도류: DMG 65 × 2 + VULNERABLE 1
	var c := CardRes.new()
	c.card_name = "도류 극의"; c.owner_id = "musashi"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "attack"
	c.archetype = "이도류"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 65; ea.base_value = 65; ea.target = "SINGLE"; ea.hit_count = 2
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.APPLY_STATUS
	eb.value = 1; eb.base_value = 1; eb.target = "SINGLE"; eb.status_type = "vulnerable"
	c.effects = [ea, eb]; return c

static func _flying_swallow() -> Resource:
	# 비연참 — UNCOMMON, 1코, 공격, 이도류: DMG 70 × 2 + ENERGY+1
	var c := CardRes.new()
	c.card_name = "비연참"; c.owner_id = "musashi"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "attack"
	c.archetype = "이도류"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 70; ea.base_value = 70; ea.target = "SINGLE"; ea.hit_count = 2
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.ENERGY
	eb.value = 1; eb.base_value = 1
	c.effects = [ea, eb]; return c

static func _asura_cut() -> Resource:
	# 수라 참 — UNCOMMON, 1코, 공격, 결투: 적 1마리 DMG 160 / 복수 DMG 100
	var c := CardRes.new()
	c.card_name = "수라 참"; c.owner_id = "musashi"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "attack"
	c.archetype = "결투"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.CONDITIONAL_DMG
	e.value = 100; e.base_value = 100
	e.bonus_value = 160; e.base_bonus_value = 160
	e.target = "SINGLE"; e.status_type = "enemy_count_1"
	c.effects = [e]; return c

static func _battle_gaze() -> Resource:
	# 결전의 눈빛 — UNCOMMON, 1코, 기술, 결투: 적 1마리 → DRAW 2 + BLOCK 80 / DRAW 1
	var c := CardRes.new()
	c.card_name = "결전의 눈빛"; c.owner_id = "musashi"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	c.archetype = "결투"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.BLOCK
	ea.value = 80; ea.base_value = 80; ea.target = "SELF"
	ea.condition = "enemy_count_1"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.DRAW
	eb.value = 1; eb.base_value = 1
	eb.condition = "enemy_count_1"
	var ec := EffRes.new()
	ec.effect_type = EffRes.EffectType.DRAW
	ec.value = 1; ec.base_value = 1
	c.effects = [ea, eb, ec]; return c

static func _torrent() -> Resource:
	# 격류 — UNCOMMON, 1코, 공격, 결투: 적 1마리 DMG 170 + VULNERABLE 1 / DMG 100
	var c := CardRes.new()
	c.card_name = "격류"; c.owner_id = "musashi"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "attack"
	c.archetype = "결투"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.CONDITIONAL_DMG
	ea.value = 100; ea.base_value = 100
	ea.bonus_value = 170; ea.base_bonus_value = 170
	ea.target = "SINGLE"; ea.status_type = "enemy_count_1"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.APPLY_STATUS
	eb.value = 1; eb.base_value = 1; eb.target = "SINGLE"; eb.status_type = "vulnerable"
	eb.condition = "enemy_count_1"
	c.effects = [ea, eb]; return c

static func _zen_realm() -> Resource:
	# 선의 경지 — UNCOMMON, 1코, 기술, 무심: DRAW 2 + hand_size_0이면 BLOCK 100 추가
	var c := CardRes.new()
	c.card_name = "선의 경지"; c.owner_id = "musashi"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	c.archetype = "무심"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.BLOCK
	ea.value = 100; ea.base_value = 100; ea.target = "SELF"
	ea.condition = "hand_size_0"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.DRAW
	eb.value = 2; eb.base_value = 2
	c.effects = [ea, eb]; return c

static func _empty_guard() -> Resource:
	# 공수처 — UNCOMMON, 1코, 기술, 무심: DRAW 1 + BLOCK 80
	var c := CardRes.new()
	c.card_name = "공수처"; c.owner_id = "musashi"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	c.archetype = "무심"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DRAW
	ea.value = 1; ea.base_value = 1
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.BLOCK
	eb.value = 80; eb.base_value = 80; eb.target = "SELF"
	c.effects = [ea, eb]; return c

static func _detach() -> Resource:
	# 탈속 — UNCOMMON, 0코, 기술, 무심: DRAW 1
	var c := CardRes.new()
	c.card_name = "탈속"; c.owner_id = "musashi"
	c.cost = 0; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "idle"
	c.archetype = "무심"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.DRAW
	e.value = 1; e.base_value = 1
	c.effects = [e]; return c

static func _fierce_niten() -> Resource:
	# 맹렬한 이도 — RARE, 1코, 공격, 이도류: DMG 75 × 2 + POISON 2
	var c := CardRes.new()
	c.card_name = "맹렬한 이도"; c.owner_id = "musashi"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "attack"
	c.archetype = "이도류"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 75; ea.base_value = 75; ea.target = "SINGLE"; ea.hit_count = 2
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.APPLY_STATUS
	eb.value = 2; eb.base_value = 2; eb.target = "SINGLE"; eb.status_type = "poison"
	c.effects = [ea, eb]; return c

static func _twin_dragon() -> Resource:
	# 쌍룡섬 — RARE, 2코, 공격, 이도류: DMG 80 × 2 + BLOCK 80
	var c := CardRes.new()
	c.card_name = "쌍룡섬"; c.owner_id = "musashi"
	c.cost = 2; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "attack"
	c.archetype = "이도류"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 80; ea.base_value = 80; ea.target = "SINGLE"; ea.hit_count = 2
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.BLOCK
	eb.value = 80; eb.base_value = 80; eb.target = "SELF"
	c.effects = [ea, eb]; return c

static func _thousand_mile_cut() -> Resource:
	# 천리 베기 — RARE, 1코, 공격, 이도류: DMG 65 × 2 + DRAW 1
	var c := CardRes.new()
	c.card_name = "천리 베기"; c.owner_id = "musashi"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "attack"
	c.archetype = "이도류"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.DAMAGE
	ea.value = 65; ea.base_value = 65; ea.target = "SINGLE"; ea.hit_count = 2
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.DRAW
	eb.value = 1; eb.base_value = 1
	c.effects = [ea, eb]; return c

static func _peerless_cut() -> Resource:
	# 무쌍 베기 — RARE, 1코, 공격, 결투: 적 1마리 DMG 200 + WEAK 1 / DMG 120
	var c := CardRes.new()
	c.card_name = "무쌍 베기"; c.owner_id = "musashi"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "attack"
	c.archetype = "결투"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.CONDITIONAL_DMG
	ea.value = 120; ea.base_value = 120
	ea.bonus_value = 200; ea.base_bonus_value = 200
	ea.target = "SINGLE"; ea.status_type = "enemy_count_1"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.APPLY_STATUS
	eb.value = 1; eb.base_value = 1; eb.target = "SINGLE"; eb.status_type = "weak"
	eb.condition = "enemy_count_1"
	c.effects = [ea, eb]; return c

static func _forward_cut() -> Resource:
	# 선검후참 — RARE, 1코, 공격, 결투: 적 1마리 DMG 180 + BLOCK 60 / DMG 110 + BLOCK 30
	var c := CardRes.new()
	c.card_name = "선검후참"; c.owner_id = "musashi"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "attack"
	c.archetype = "결투"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.BLOCK
	ea.value = 30; ea.base_value = 30; ea.target = "SELF"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.BLOCK
	eb.value = 30; eb.base_value = 30; eb.target = "SELF"
	eb.condition = "enemy_count_1"
	var ec := EffRes.new()
	ec.effect_type = EffRes.EffectType.CONDITIONAL_DMG
	ec.value = 110; ec.base_value = 110
	ec.bonus_value = 180; ec.base_bonus_value = 180
	ec.target = "SINGLE"; ec.status_type = "enemy_count_1"
	c.effects = [ea, eb, ec]; return c

static func _final_duel() -> Resource:
	# 마지막 결투 — RARE, 2코, 공격, 결투: 적 1마리 DMG 300 + VULNERABLE 2 / DMG 160
	var c := CardRes.new()
	c.card_name = "마지막 결투"; c.owner_id = "musashi"
	c.cost = 2; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "attack"
	c.archetype = "결투"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.CONDITIONAL_DMG
	ea.value = 160; ea.base_value = 160
	ea.bonus_value = 300; ea.base_bonus_value = 300
	ea.target = "SINGLE"; ea.status_type = "enemy_count_1"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.APPLY_STATUS
	eb.value = 2; eb.base_value = 2; eb.target = "SINGLE"; eb.status_type = "vulnerable"
	eb.condition = "enemy_count_1"
	c.effects = [ea, eb]; return c

static func _void_void() -> Resource:
	# 허허실실 — RARE, 1코, 기술, 무심: hand_size_0 → DRAW 3 + HEAL 80 + ENERGY+1 / DRAW 2
	var c := CardRes.new()
	c.card_name = "허허실실"; c.owner_id = "musashi"
	c.cost = 1; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	c.archetype = "무심"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.HEAL
	ea.value = 80; ea.base_value = 80; ea.target = "SELF"
	ea.condition = "hand_size_0"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.ENERGY
	eb.value = 1; eb.base_value = 1
	eb.condition = "hand_size_0"
	var ec := EffRes.new()
	ec.effect_type = EffRes.EffectType.DRAW
	ec.value = 1; ec.base_value = 1
	ec.condition = "hand_size_0"
	var ed := EffRes.new()
	ed.effect_type = EffRes.EffectType.DRAW
	ed.value = 2; ed.base_value = 2
	c.effects = [ea, eb, ec, ed]; return c

static func _clear_wind() -> Resource:
	# 청풍명월 — RARE, 1코, 공격, 무심: hand_size_0 → DMG 250 + POISON 2 / DMG 120
	var c := CardRes.new()
	c.card_name = "청풍명월"; c.owner_id = "musashi"
	c.cost = 1; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "attack"
	c.archetype = "무심"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.CONDITIONAL_DMG
	ea.value = 120; ea.base_value = 120
	ea.bonus_value = 250; ea.base_bonus_value = 250
	ea.target = "SINGLE"; ea.status_type = "hand_size_0"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.APPLY_STATUS
	eb.value = 2; eb.base_value = 2; eb.target = "SINGLE"; eb.status_type = "poison"
	eb.condition = "hand_size_0"
	c.effects = [ea, eb]; return c

static func _undying() -> Resource:
	# 불생불멸 — RARE, 2코, 기술, 무심: hand_size_0 → DRAW 4 + BLOCK_ALL 80 / DRAW 2 + BLOCK_ALL 40
	var c := CardRes.new()
	c.card_name = "불생불멸"; c.owner_id = "musashi"
	c.cost = 2; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.RARE; c.play_animation = "idle"
	c.archetype = "무심"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.BLOCK_ALL
	ea.value = 40; ea.base_value = 40
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.BLOCK_ALL
	eb.value = 40; eb.base_value = 40
	eb.condition = "hand_size_0"
	var ec := EffRes.new()
	ec.effect_type = EffRes.EffectType.DRAW
	ec.value = 2; ec.base_value = 2
	ec.condition = "hand_size_0"
	var ed := EffRes.new()
	ed.effect_type = EffRes.EffectType.DRAW
	ed.value = 2; ed.base_value = 2
	c.effects = [ea, eb, ec, ed]; return c

static func _spirit_sword() -> Resource:
	# 영혼의 검 — UNCOMMON, 2코, 공격, 결투: 적 1마리 DMG 260 / 복수 DMG 140
	var c := CardRes.new()
	c.card_name = "영혼의 검"; c.owner_id = "musashi"
	c.cost = 2; c.card_type = CardRes.CardType.ATTACK
	c.rarity = CardRes.Rarity.UNCOMMON; c.play_animation = "attack"
	c.archetype = "결투"
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.CONDITIONAL_DMG
	e.value = 140; e.base_value = 140
	e.bonus_value = 260; e.base_bonus_value = 260
	e.target = "SINGLE"; e.status_type = "enemy_count_1"
	c.effects = [e]; return c

static func _five_rings_realm() -> Resource:
	# 오륜의 경지 — LEGENDARY, 2코, 기술, 무심: hand_size_0 → COST_ZERO_TURN + DRAW 3 / DRAW 3
	var c := CardRes.new()
	c.card_name = "오륜의 경지"; c.owner_id = "musashi"
	c.cost = 2; c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.LEGENDARY; c.play_animation = "idle"
	c.archetype = "무심"
	var ea := EffRes.new()
	ea.effect_type = EffRes.EffectType.COST_ZERO_TURN
	ea.value = 0; ea.base_value = 0
	ea.condition = "hand_size_0"
	var eb := EffRes.new()
	eb.effect_type = EffRes.EffectType.DRAW
	eb.value = 3; eb.base_value = 3
	c.effects = [ea, eb]; return c
