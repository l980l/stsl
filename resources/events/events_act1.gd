# resources/data/events_act1.gd
const EventRes  = preload("res://resources/event_resource.gd")
const ChoiceRes = preload("res://resources/event_choice_resource.gd")

static func build_pool() -> Array:
	return [
		_golden_chest(), _wounded_warrior(), _ancient_library(),
		_cursed_altar(), _companion_encounter(), _prometheus_fire(),
		_heracles_trial(), _circe_magic(), _hades_contract(),
		_hermes_gamble(), _devils_deal(),
	]

static func _golden_chest() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = TranslationServer.translate("event.act1.golden_chest.name"); e.description = TranslationServer.translate("event.act1.golden_chest.desc")
	var ca: Resource = ChoiceRes.new(); ca.label = TranslationServer.translate("event.act1.golden_chest.choice_1")
	ca.effect_type = ChoiceRes.EffectType.GOLD; ca.value = 30
	var cb: Resource = ChoiceRes.new(); cb.label = TranslationServer.translate("event.act1.golden_chest.choice_2")
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _wounded_warrior() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = TranslationServer.translate("event.act1.wounded_warrior.name"); e.description = TranslationServer.translate("event.act1.wounded_warrior.desc")
	var ca: Resource = ChoiceRes.new(); ca.label = TranslationServer.translate("event.act1.wounded_warrior.choice_1")
	ca.effect_type = ChoiceRes.EffectType.HEAL; ca.value = 15; ca.cost_gold = 20
	var cb: Resource = ChoiceRes.new(); cb.label = TranslationServer.translate("event.act1.wounded_warrior.choice_2")
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _ancient_library() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = TranslationServer.translate("event.act1.ancient_library.name")
	e.description = TranslationServer.translate("event.act1.ancient_library.desc")
	var ca: Resource = ChoiceRes.new(); ca.label = TranslationServer.translate("event.act1.ancient_library.choice_1")
	ca.effect_type = ChoiceRes.EffectType.DRAW_UP; ca.value = 1; ca.cost_hp = 5
	var cb: Resource = ChoiceRes.new(); cb.label = TranslationServer.translate("event.act1.ancient_library.choice_2")
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _cursed_altar() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = TranslationServer.translate("event.act1.cursed_altar.name"); e.description = TranslationServer.translate("event.act1.cursed_altar.desc")
	var ca: Resource = ChoiceRes.new(); ca.label = TranslationServer.translate("event.act1.cursed_altar.choice_1")
	ca.effect_type = ChoiceRes.EffectType.REMOVE_CARD; ca.value = 1
	var cb: Resource = ChoiceRes.new(); cb.label = TranslationServer.translate("event.act1.cursed_altar.choice_2")
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _companion_encounter() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = TranslationServer.translate("event.act1.companion_encounter.name"); e.description = TranslationServer.translate("event.act1.companion_encounter.desc")
	var ca: Resource = ChoiceRes.new(); ca.label = TranslationServer.translate("event.act1.companion_encounter.choice_1")
	ca.effect_type = ChoiceRes.EffectType.ADD_HERO
	var cb: Resource = ChoiceRes.new(); cb.label = TranslationServer.translate("event.act1.companion_encounter.choice_2")
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _prometheus_fire() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = TranslationServer.translate("event.act1.prometheus_fire.name")
	e.description = TranslationServer.translate("event.act1.prometheus_fire.desc")
	var ca: Resource = ChoiceRes.new(); ca.label = TranslationServer.translate("event.act1.prometheus_fire.choice_1")
	ca.effect_type = ChoiceRes.EffectType.DRAW_UP; ca.value = 1; ca.cost_hp = 20
	var cb: Resource = ChoiceRes.new(); cb.label = TranslationServer.translate("event.act1.prometheus_fire.choice_2")
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _heracles_trial() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = TranslationServer.translate("event.act1.heracles_trial.name"); e.description = TranslationServer.translate("event.act1.heracles_trial.desc")
	var ca: Resource = ChoiceRes.new(); ca.label = TranslationServer.translate("event.act1.heracles_trial.choice_1")
	ca.effect_type = ChoiceRes.EffectType.GOLD; ca.value = 60; ca.cost_hp = 25
	var cb: Resource = ChoiceRes.new(); cb.label = TranslationServer.translate("event.act1.heracles_trial.choice_2")
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _circe_magic() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = TranslationServer.translate("event.act1.circe_magic.name"); e.description = TranslationServer.translate("event.act1.circe_magic.desc")
	var ca: Resource = ChoiceRes.new(); ca.label = TranslationServer.translate("event.act1.circe_magic.choice_1")
	ca.effect_type = ChoiceRes.EffectType.HEAL; ca.value = 25; ca.cost_gold = 50
	var cb: Resource = ChoiceRes.new(); cb.label = TranslationServer.translate("event.act1.circe_magic.choice_2")
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _hades_contract() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = TranslationServer.translate("event.act1.hades_contract.name")
	e.description = TranslationServer.translate("event.act1.hades_contract.desc")
	var ca: Resource = ChoiceRes.new(); ca.label = TranslationServer.translate("event.act1.hades_contract.choice_1")
	ca.effect_type = ChoiceRes.EffectType.ADD_RELIC; ca.cost_hp = 30
	var cb: Resource = ChoiceRes.new(); cb.label = TranslationServer.translate("event.act1.hades_contract.choice_2")
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _hermes_gamble() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = TranslationServer.translate("event.act1.hermes_gamble.name"); e.description = TranslationServer.translate("event.act1.hermes_gamble.desc")
	var ca: Resource = ChoiceRes.new(); ca.label = TranslationServer.translate("event.act1.hermes_gamble.choice_1")
	ca.effect_type = ChoiceRes.EffectType.GOLD; ca.value = 50
	var cb: Resource = ChoiceRes.new(); cb.label = TranslationServer.translate("event.act1.hermes_gamble.choice_2")
	cb.effect_type = ChoiceRes.EffectType.REMOVE_CARD; cb.value = 1
	e.choices = [ca, cb]; return e

static func _devils_deal() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = TranslationServer.translate("event.act1.devils_deal.name")
	e.description = TranslationServer.translate("event.act1.devils_deal.desc")
	var ca: Resource = ChoiceRes.new(); ca.label = TranslationServer.translate("event.act1.devils_deal.choice_1")
	ca.effect_type = ChoiceRes.EffectType.ADD_RELIC_GAMBLE
	var cb: Resource = ChoiceRes.new(); cb.label = TranslationServer.translate("event.act1.devils_deal.choice_2")
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e
