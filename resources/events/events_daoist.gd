# resources/events/events_daoist.gd
# 도교 이벤트 10종
const EventRes  = preload("res://resources/event_resource.gd")
const ChoiceRes = preload("res://resources/event_choice_resource.gd")

static func build_pool() -> Array:
	return [
		_peach_of_immortality(), _immortal_duel(), _jade_scripture(),
		_celestial_feast(), _heavenly_bazaar(), _dragon_palace_summons(),
		_dao_purification(), _cosmic_remnant(), _elixir_garden(),
		_vermilion_rebirth(), _eight_immortals(),
	]

static func _peach_of_immortality() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "event.daoist.peach_of_immortality.name"
	e.description = "event.daoist.peach_of_immortality.desc"
	e.bgm_type = "mysterious"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.daoist.peach_of_immortality.choice_1"
	ca.effect_type = ChoiceRes.EffectType.HEAL; ca.value = 40
	var cb: Resource = ChoiceRes.new(); cb.label = "event.daoist.peach_of_immortality.choice_2"
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _immortal_duel() -> Resource:
	# 다양화: GAMBLE → TRIGGER_BATTLE (선인과의 결투, 보통). 승리 시 렐릭 + 골드.
	var e: Resource = EventRes.new()
	e.event_name = "event.daoist.immortal_duel.name"
	e.description = "event.daoist.immortal_duel.desc"
	e.bgm_type = "fortune"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.daoist.immortal_duel.choice_1"
	ca.effect_type = ChoiceRes.EffectType.TRIGGER_BATTLE
	ca.encounter_tier = 0
	ca.reward_effect_type = ChoiceRes.EffectType.ADD_RELIC
	var cb: Resource = ChoiceRes.new(); cb.label = "event.daoist.immortal_duel.choice_2"
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _jade_scripture() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "event.daoist.jade_scripture.name"
	e.description = "event.daoist.jade_scripture.desc"
	e.bgm_type = "mysterious"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.daoist.jade_scripture.choice_1"
	ca.effect_type = ChoiceRes.EffectType.DRAW_UP; ca.value = 1
	var cb: Resource = ChoiceRes.new(); cb.label = "event.daoist.jade_scripture.choice_2"
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _celestial_feast() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "event.daoist.celestial_feast.name"
	e.description = "event.daoist.celestial_feast.desc"
	e.bgm_type = "encounter"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.daoist.celestial_feast.choice_1"
	ca.effect_type = ChoiceRes.EffectType.HEAL; ca.value = 50; ca.cost_gold = 40
	var cb: Resource = ChoiceRes.new(); cb.label = "event.daoist.celestial_feast.choice_2"
	cb.effect_type = ChoiceRes.EffectType.GOLD; cb.value = 60
	var cc: Resource = ChoiceRes.new(); cc.label = "event.daoist.celestial_feast.choice_3"
	cc.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb, cc]; return e

static func _heavenly_bazaar() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "event.daoist.heavenly_bazaar.name"
	e.description = "event.daoist.heavenly_bazaar.desc"
	e.bgm_type = "fortune"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.daoist.heavenly_bazaar.choice_1"
	ca.effect_type = ChoiceRes.EffectType.ADD_RELIC; ca.cost_gold = 80
	var cb: Resource = ChoiceRes.new(); cb.label = "event.daoist.heavenly_bazaar.choice_2"
	cb.effect_type = ChoiceRes.EffectType.ADD_RELIC_GAMBLE; cb.cost_gold = 30
	var cc: Resource = ChoiceRes.new(); cc.label = "event.daoist.heavenly_bazaar.choice_3"
	cc.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb, cc]; return e

static func _dragon_palace_summons() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "event.daoist.dragon_palace_summons.name"
	e.description = "event.daoist.dragon_palace_summons.desc"
	e.bgm_type = "encounter"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.daoist.dragon_palace_summons.choice_1"
	ca.effect_type = ChoiceRes.EffectType.GOLD; ca.value = 90; ca.cost_hp = 25
	var cb: Resource = ChoiceRes.new(); cb.label = "event.daoist.dragon_palace_summons.choice_2"
	cb.effect_type = ChoiceRes.EffectType.ADD_RELIC; cb.cost_hp = 40
	var cc: Resource = ChoiceRes.new(); cc.label = "event.daoist.dragon_palace_summons.choice_3"
	cc.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb, cc]; return e

static func _dao_purification() -> Resource:
	# 다양화: 단순 REMOVE_CARD → MULTI (REMOVE_CARD + DRAW_UP +1). 도교의 정화·각성.
	var e: Resource = EventRes.new()
	e.event_name = "event.daoist.dao_purification.name"
	e.description = "event.daoist.dao_purification.desc"
	e.bgm_type = "mysterious"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.daoist.dao_purification.choice_1"
	ca.effect_type = ChoiceRes.EffectType.REMOVE_CARD; ca.value = 1
	ca.secondary_effect_type = ChoiceRes.EffectType.DRAW_UP; ca.secondary_value = 1
	var cb: Resource = ChoiceRes.new(); cb.label = "event.daoist.dao_purification.choice_2"
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _cosmic_remnant() -> Resource:
	# 다양화: ADD_HERO 단일 → MULTI (영웅 + ADD_RELIC). 우주의 잔영 — 영웅과 유물을 동시에.
	var e: Resource = EventRes.new()
	e.event_name = "event.daoist.cosmic_remnant.name"
	e.description = "event.daoist.cosmic_remnant.desc"
	e.bgm_type = "encounter"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.daoist.cosmic_remnant.choice_1"
	ca.effect_type = ChoiceRes.EffectType.ADD_HERO
	ca.secondary_effect_type = ChoiceRes.EffectType.ADD_RELIC
	ca.cost_hp = 30  # 잔영을 받아내려면 대가 필요
	var cb: Resource = ChoiceRes.new(); cb.label = "event.daoist.cosmic_remnant.choice_2"
	cb.effect_type = ChoiceRes.EffectType.GOLD; cb.value = 50
	e.choices = [ca, cb]; return e

static func _elixir_garden() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "event.daoist.elixir_garden.name"
	e.description = "event.daoist.elixir_garden.desc"
	e.bgm_type = "encounter"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.daoist.elixir_garden.choice_1"
	ca.effect_type = ChoiceRes.EffectType.HEAL; ca.value = 40; ca.cost_hp = 15
	var cb: Resource = ChoiceRes.new(); cb.label = "event.daoist.elixir_garden.choice_2"
	cb.effect_type = ChoiceRes.EffectType.HEAL; cb.value = 20; cb.cost_gold = 40
	var cc: Resource = ChoiceRes.new(); cc.label = "event.daoist.elixir_garden.choice_3"
	cc.effect_type = ChoiceRes.EffectType.NONE
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
# 팔선의 술법을 본 자에게 영원의 가르침. 50% 렐릭+골드, 50% NONE.
static func _eight_immortals() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "event.daoist.eight_immortals.name"
	e.description = "event.daoist.eight_immortals.desc"
	e.bgm_type = "fortune"
	# 따라가본다: 50% (ADD_RELIC + GOLD +40), 50% (HEAL +20)
	var ca: Resource = ChoiceRes.new(); ca.label = "event.daoist.eight_immortals.choice_1"
	ca.effect_type = ChoiceRes.EffectType.ADD_RELIC
	ca.secondary_effect_type = ChoiceRes.EffectType.GOLD; ca.secondary_value = 40
	ca.success_chance = 50
	ca.alt_effect_type = ChoiceRes.EffectType.HEAL; ca.alt_value = 20
	# 무시한다
	var cb: Resource = ChoiceRes.new(); cb.label = "event.daoist.eight_immortals.choice_2"
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e
