# resources/events/events_daoist.gd
# 도교 이벤트 10종
const EventRes  = preload("res://resources/event_resource.gd")
const ChoiceRes = preload("res://resources/event_choice_resource.gd")

static func build_pool() -> Array:
	# _cosmic_remnant 제거 — ADD_HERO 이벤트. 영입은 Act1 trigger 로 일원화.
	return [
		_peach_of_immortality(), _immortal_duel(), _jade_scripture(),
		_celestial_feast(), _heavenly_bazaar(), _dragon_palace_summons(),
		_dao_purification(), _elixir_garden(),
		_vermilion_rebirth(), _eight_immortals(),
	]

static func _peach_of_immortality() -> Resource:
	# 재설계: 1번 복숭아 먹기 (HEAL), 2번 복숭아 훔쳐 팔기 (GOLD, 천상 분노 cost_hp)
	var e: Resource = EventRes.new()
	e.event_name = "event.daoist.peach_of_immortality.name"
	e.description = "event.daoist.peach_of_immortality.desc"
	e.bgm_type = "mysterious"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.daoist.peach_of_immortality.choice_1"
	ca.effect_type = ChoiceRes.EffectType.HEAL; ca.value = 40
	var cb: Resource = ChoiceRes.new(); cb.label = "event.daoist.peach_of_immortality.choice_2"
	# 복숭아 약탈 — GOLD, 천상 분노 cost_hp
	cb.effect_type = ChoiceRes.EffectType.GOLD; cb.value = 45; cb.cost_hp = 15
	e.choices = [ca, cb]; return e

static func _immortal_duel() -> Resource:
	# 다양화: 1번 TRIGGER_BATTLE (렐릭), 2번 항복 (선인의 가르침: HEAL + DRAW_UP MULTI, gold cost)
	var e: Resource = EventRes.new()
	e.event_name = "event.daoist.immortal_duel.name"
	e.description = "event.daoist.immortal_duel.desc"
	e.bgm_type = "fortune"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.daoist.immortal_duel.choice_1"
	ca.effect_type = ChoiceRes.EffectType.TRIGGER_BATTLE
	ca.encounter_tier = 0
	ca.reward_effect_type = ChoiceRes.EffectType.ADD_RELIC
	var cb: Resource = ChoiceRes.new(); cb.label = "event.daoist.immortal_duel.choice_2"
	# 항복 — 선인의 가르침 (HEAL + DRAW_UP, gold 사사례)
	cb.effect_type = ChoiceRes.EffectType.HEAL; cb.value = 25
	cb.secondary_effect_type = ChoiceRes.EffectType.DRAW_UP; cb.secondary_value = 1
	cb.cost_gold = 40
	e.choices = [ca, cb]; return e

static func _jade_scripture() -> Resource:
	# 재설계: 1번 옥경 공부 (DRAW_UP), 2번 경판을 깨고 옥 회수 (GOLD, 천상 분노 cost_hp)
	var e: Resource = EventRes.new()
	e.event_name = "event.daoist.jade_scripture.name"
	e.description = "event.daoist.jade_scripture.desc"
	e.bgm_type = "mysterious"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.daoist.jade_scripture.choice_1"
	ca.effect_type = ChoiceRes.EffectType.DRAW_UP; ca.value = 1
	var cb: Resource = ChoiceRes.new(); cb.label = "event.daoist.jade_scripture.choice_2"
	# 옥판 부수기 — GOLD, cost_hp
	cb.effect_type = ChoiceRes.EffectType.GOLD; cb.value = 40; cb.cost_hp = 10
	e.choices = [ca, cb]; return e

static func _celestial_feast() -> Resource:
	# 재설계: 1번 식사 (HEAL gold cost), 2번 금배 훔치기 (GOLD), 3번 술 한 잔 받음 (HEAL 소량)
	var e: Resource = EventRes.new()
	e.event_name = "event.daoist.celestial_feast.name"
	e.description = "event.daoist.celestial_feast.desc"
	e.bgm_type = "encounter"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.daoist.celestial_feast.choice_1"
	ca.effect_type = ChoiceRes.EffectType.HEAL; ca.value = 50; ca.cost_gold = 40
	var cb: Resource = ChoiceRes.new(); cb.label = "event.daoist.celestial_feast.choice_2"
	cb.effect_type = ChoiceRes.EffectType.GOLD; cb.value = 60
	var cc: Resource = ChoiceRes.new(); cc.label = "event.daoist.celestial_feast.choice_3"
	# 술 한 잔 — 소량 HEAL (천상의 환대)
	cc.effect_type = ChoiceRes.EffectType.HEAL; cc.value = 15
	e.choices = [ca, cb, cc]; return e

static func _heavenly_bazaar() -> Resource:
	# 재설계: 1번 정품 (gold), 2번 도박 (gold), 3번 상인 등쳐먹기 (GOLD, cost_hp)
	var e: Resource = EventRes.new()
	e.event_name = "event.daoist.heavenly_bazaar.name"
	e.description = "event.daoist.heavenly_bazaar.desc"
	e.bgm_type = "fortune"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.daoist.heavenly_bazaar.choice_1"
	ca.effect_type = ChoiceRes.EffectType.ADD_RELIC; ca.cost_gold = 80
	var cb: Resource = ChoiceRes.new(); cb.label = "event.daoist.heavenly_bazaar.choice_2"
	cb.effect_type = ChoiceRes.EffectType.ADD_RELIC_GAMBLE; cb.cost_gold = 30
	var cc: Resource = ChoiceRes.new(); cc.label = "event.daoist.heavenly_bazaar.choice_3"
	# 등쳐먹기 — GOLD, cost_hp (경비병에게 맞음)
	cc.effect_type = ChoiceRes.EffectType.GOLD; cc.value = 45; cc.cost_hp = 20
	e.choices = [ca, cb, cc]; return e

static func _dragon_palace_summons() -> Resource:
	# 재설계: 1번 임무 GOLD HP cost, 2번 임무 렐릭 HP cost, 3번 사양 (HEAL — 용궁 환대만)
	var e: Resource = EventRes.new()
	e.event_name = "event.daoist.dragon_palace_summons.name"
	e.description = "event.daoist.dragon_palace_summons.desc"
	e.bgm_type = "encounter"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.daoist.dragon_palace_summons.choice_1"
	ca.effect_type = ChoiceRes.EffectType.GOLD; ca.value = 90; ca.cost_hp = 25
	var cb: Resource = ChoiceRes.new(); cb.label = "event.daoist.dragon_palace_summons.choice_2"
	cb.effect_type = ChoiceRes.EffectType.ADD_RELIC; cb.cost_hp = 40
	var cc: Resource = ChoiceRes.new(); cc.label = "event.daoist.dragon_palace_summons.choice_3"
	# 사양 — 용궁 환대만 받음 (HEAL 소량)
	cc.effect_type = ChoiceRes.EffectType.HEAL; cc.value = 20
	e.choices = [ca, cb, cc]; return e

static func _dao_purification() -> Resource:
	# 다양화: 1번 MULTI(REMOVE_CARD + DRAW_UP), 2번 도교 사례금 (GOLD 환원)
	var e: Resource = EventRes.new()
	e.event_name = "event.daoist.dao_purification.name"
	e.description = "event.daoist.dao_purification.desc"
	e.bgm_type = "mysterious"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.daoist.dao_purification.choice_1"
	ca.effect_type = ChoiceRes.EffectType.REMOVE_CARD; ca.value = 1
	ca.secondary_effect_type = ChoiceRes.EffectType.DRAW_UP; ca.secondary_value = 1
	var cb: Resource = ChoiceRes.new(); cb.label = "event.daoist.dao_purification.choice_2"
	# 거절 — 도사가 작은 사례금 줌
	cb.effect_type = ChoiceRes.EffectType.GOLD; cb.value = 20
	e.choices = [ca, cb]; return e

static func _elixir_garden() -> Resource:
	# 재설계: 1번 영약 강행 (HEAL +40 cost_hp 15), 2번 영약 구매 (HEAL gold cost), 3번 정원 꽃 약탈 (GOLD, 정원사 분노 cost_hp)
	var e: Resource = EventRes.new()
	e.event_name = "event.daoist.elixir_garden.name"
	e.description = "event.daoist.elixir_garden.desc"
	e.bgm_type = "encounter"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.daoist.elixir_garden.choice_1"
	ca.effect_type = ChoiceRes.EffectType.HEAL; ca.value = 40; ca.cost_hp = 15
	var cb: Resource = ChoiceRes.new(); cb.label = "event.daoist.elixir_garden.choice_2"
	cb.effect_type = ChoiceRes.EffectType.HEAL; cb.value = 20; cb.cost_gold = 40
	var cc: Resource = ChoiceRes.new(); cc.label = "event.daoist.elixir_garden.choice_3"
	# 약초 약탈 — GOLD, cost_hp
	cc.effect_type = ChoiceRes.EffectType.GOLD; cc.value = 30; cc.cost_hp = 10
	e.choices = [ca, cb, cc]; return e

static func _vermilion_rebirth() -> Resource:
	# 다양화: GAMBLE → 확률 (60% 렐릭, 40% 부활-HEAL +50). 주작의 부활 의식.
	var e: Resource = EventRes.new()
	e.event_name = "event.daoist.vermilion_rebirth.name"
	e.description = "event.daoist.vermilion_rebirth.desc"
	e.bgm_type = "mysterious"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.daoist.vermilion_rebirth.choice_1"
	ca.effect_type = ChoiceRes.EffectType.ADD_RELIC
	ca.success_chance = 60
	ca.alt_effect_type = ChoiceRes.EffectType.HEAL; ca.alt_value = 50
	var cb: Resource = ChoiceRes.new(); cb.label = "event.daoist.vermilion_rebirth.choice_2"
	cb.effect_type = ChoiceRes.EffectType.HEAL; cb.value = 30
	e.choices = [ca, cb]; return e

# Phase 4 신규: 팔선의 시연 (확률 + 다중 보상 조합)
static func _eight_immortals() -> Resource:
	# 1번 50% (ADD_RELIC + GOLD +40), 50% HEAL +20
	# 2번 멀리서 술법 분석 (DRAW_UP — 일별만으로 깨달음)
	var e: Resource = EventRes.new()
	e.event_name = "event.daoist.eight_immortals.name"
	e.description = "event.daoist.eight_immortals.desc"
	e.bgm_type = "fortune"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.daoist.eight_immortals.choice_1"
	ca.effect_type = ChoiceRes.EffectType.ADD_RELIC
	ca.secondary_effect_type = ChoiceRes.EffectType.GOLD; ca.secondary_value = 40
	ca.success_chance = 50
	ca.alt_effect_type = ChoiceRes.EffectType.HEAL; ca.alt_value = 20
	var cb: Resource = ChoiceRes.new(); cb.label = "event.daoist.eight_immortals.choice_2"
	# 멀리서 술법 관찰 — DRAW_UP (눈으로만 보고 깨달음)
	cb.effect_type = ChoiceRes.EffectType.DRAW_UP; cb.value = 1
	e.choices = [ca, cb]; return e
