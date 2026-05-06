# resources/events/events_daoist.gd
# 도교 이벤트 10종
const EventRes  = preload("res://resources/event_resource.gd")
const ChoiceRes = preload("res://resources/event_choice_resource.gd")

static func build_pool() -> Array:
	return [
		_peach_of_immortality(), _immortal_duel(), _jade_scripture(),
		_celestial_feast(), _heavenly_bazaar(), _dragon_palace_summons(),
		_dao_purification(), _cosmic_remnant(), _elixir_garden(),
		_vermilion_rebirth(),
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
	var e: Resource = EventRes.new()
	e.event_name = "event.daoist.immortal_duel.name"
	e.description = "event.daoist.immortal_duel.desc"
	e.bgm_type = "fortune"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.daoist.immortal_duel.choice_1"
	ca.effect_type = ChoiceRes.EffectType.ADD_RELIC_GAMBLE
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
	var e: Resource = EventRes.new()
	e.event_name = "event.daoist.dao_purification.name"
	e.description = "event.daoist.dao_purification.desc"
	e.bgm_type = "mysterious"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.daoist.dao_purification.choice_1"
	ca.effect_type = ChoiceRes.EffectType.REMOVE_CARD; ca.value = 1
	var cb: Resource = ChoiceRes.new(); cb.label = "event.daoist.dao_purification.choice_2"
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _cosmic_remnant() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "event.daoist.cosmic_remnant.name"
	e.description = "event.daoist.cosmic_remnant.desc"
	e.bgm_type = "encounter"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.daoist.cosmic_remnant.choice_1"
	ca.effect_type = ChoiceRes.EffectType.ADD_HERO
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
	var e: Resource = EventRes.new()
	e.event_name = "event.daoist.vermilion_rebirth.name"
	e.description = "event.daoist.vermilion_rebirth.desc"
	e.bgm_type = "mysterious"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.daoist.vermilion_rebirth.choice_1"
	ca.effect_type = ChoiceRes.EffectType.ADD_RELIC_GAMBLE
	var cb: Resource = ChoiceRes.new(); cb.label = "event.daoist.vermilion_rebirth.choice_2"
	cb.effect_type = ChoiceRes.EffectType.HEAL; cb.value = 30
	e.choices = [ca, cb]; return e
