# resources/events/events_japanese.gd
# 일본 신화 이벤트 10종
const EventRes  = preload("res://resources/event_resource.gd")
const ChoiceRes = preload("res://resources/event_choice_resource.gd")

static func build_pool() -> Array:
	return [
		_ise_shrine_blessing(), _oni_shogi(), _yuki_onna_blizzard(),
		_tengu_training(), _shrine_omamori(), _tanuki_illusion(),
		_kappa_river_crossing(), _shuten_doji_feast(), _fujisan_spirit(),
		_amaterasu_return(),
	]

static func _ise_shrine_blessing() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = TranslationServer.translate("event.japanese.ise_shrine_blessing.name")
	e.description = TranslationServer.translate("event.japanese.ise_shrine_blessing.desc")
	var ca: Resource = ChoiceRes.new(); ca.label = TranslationServer.translate("event.japanese.ise_shrine_blessing.choice_1")
	ca.effect_type = ChoiceRes.EffectType.HEAL; ca.value = 50; ca.cost_gold = 30
	var cb: Resource = ChoiceRes.new(); cb.label = TranslationServer.translate("event.japanese.ise_shrine_blessing.choice_2")
	cb.effect_type = ChoiceRes.EffectType.HEAL; cb.value = 20
	e.choices = [ca, cb]; return e

static func _oni_shogi() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = TranslationServer.translate("event.japanese.oni_shogi.name")
	e.description = TranslationServer.translate("event.japanese.oni_shogi.desc")
	var ca: Resource = ChoiceRes.new(); ca.label = TranslationServer.translate("event.japanese.oni_shogi.choice_1")
	ca.effect_type = ChoiceRes.EffectType.ADD_RELIC_GAMBLE
	var cb: Resource = ChoiceRes.new(); cb.label = TranslationServer.translate("event.japanese.oni_shogi.choice_2")
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _yuki_onna_blizzard() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = TranslationServer.translate("event.japanese.yuki_onna_blizzard.name")
	e.description = TranslationServer.translate("event.japanese.yuki_onna_blizzard.desc")
	var ca: Resource = ChoiceRes.new(); ca.label = TranslationServer.translate("event.japanese.yuki_onna_blizzard.choice_1")
	ca.effect_type = ChoiceRes.EffectType.GOLD; ca.value = 80; ca.cost_hp = 20
	var cb: Resource = ChoiceRes.new(); cb.label = TranslationServer.translate("event.japanese.yuki_onna_blizzard.choice_2")
	cb.effect_type = ChoiceRes.EffectType.ADD_RELIC; cb.cost_hp = 35
	var cc: Resource = ChoiceRes.new(); cc.label = TranslationServer.translate("event.japanese.yuki_onna_blizzard.choice_3")
	cc.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb, cc]; return e

static func _tengu_training() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = TranslationServer.translate("event.japanese.tengu_training.name")
	e.description = TranslationServer.translate("event.japanese.tengu_training.desc")
	var ca: Resource = ChoiceRes.new(); ca.label = TranslationServer.translate("event.japanese.tengu_training.choice_1")
	ca.effect_type = ChoiceRes.EffectType.REMOVE_CARD; ca.value = 1
	var cb: Resource = ChoiceRes.new(); cb.label = TranslationServer.translate("event.japanese.tengu_training.choice_2")
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _shrine_omamori() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = TranslationServer.translate("event.japanese.shrine_omamori.name")
	e.description = TranslationServer.translate("event.japanese.shrine_omamori.desc")
	var ca: Resource = ChoiceRes.new(); ca.label = TranslationServer.translate("event.japanese.shrine_omamori.choice_1")
	ca.effect_type = ChoiceRes.EffectType.ADD_RELIC; ca.cost_gold = 50
	var cb: Resource = ChoiceRes.new(); cb.label = TranslationServer.translate("event.japanese.shrine_omamori.choice_2")
	cb.effect_type = ChoiceRes.EffectType.ADD_RELIC_GAMBLE; cb.cost_gold = 20
	var cc: Resource = ChoiceRes.new(); cc.label = TranslationServer.translate("event.japanese.shrine_omamori.choice_3")
	cc.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb, cc]; return e

static func _tanuki_illusion() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = TranslationServer.translate("event.japanese.tanuki_illusion.name")
	e.description = TranslationServer.translate("event.japanese.tanuki_illusion.desc")
	var ca: Resource = ChoiceRes.new(); ca.label = TranslationServer.translate("event.japanese.tanuki_illusion.choice_1")
	ca.effect_type = ChoiceRes.EffectType.ADD_RELIC_GAMBLE; ca.cost_gold = 40
	var cb: Resource = ChoiceRes.new(); cb.label = TranslationServer.translate("event.japanese.tanuki_illusion.choice_2")
	cb.effect_type = ChoiceRes.EffectType.GOLD; cb.value = 50
	e.choices = [ca, cb]; return e

static func _kappa_river_crossing() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = TranslationServer.translate("event.japanese.kappa_river_crossing.name")
	e.description = TranslationServer.translate("event.japanese.kappa_river_crossing.desc")
	var ca: Resource = ChoiceRes.new(); ca.label = TranslationServer.translate("event.japanese.kappa_river_crossing.choice_1")
	ca.effect_type = ChoiceRes.EffectType.ADD_RELIC_GAMBLE
	var cb: Resource = ChoiceRes.new(); cb.label = TranslationServer.translate("event.japanese.kappa_river_crossing.choice_2")
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _shuten_doji_feast() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = TranslationServer.translate("event.japanese.shuten_doji_feast.name")
	e.description = TranslationServer.translate("event.japanese.shuten_doji_feast.desc")
	var ca: Resource = ChoiceRes.new(); ca.label = TranslationServer.translate("event.japanese.shuten_doji_feast.choice_1")
	ca.effect_type = ChoiceRes.EffectType.ADD_HERO; ca.cost_hp = 30
	var cb: Resource = ChoiceRes.new(); cb.label = TranslationServer.translate("event.japanese.shuten_doji_feast.choice_2")
	cb.effect_type = ChoiceRes.EffectType.GOLD; cb.value = 70
	var cc: Resource = ChoiceRes.new(); cc.label = TranslationServer.translate("event.japanese.shuten_doji_feast.choice_3")
	cc.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb, cc]; return e

static func _fujisan_spirit() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = TranslationServer.translate("event.japanese.fujisan_spirit.name")
	e.description = TranslationServer.translate("event.japanese.fujisan_spirit.desc")
	var ca: Resource = ChoiceRes.new(); ca.label = TranslationServer.translate("event.japanese.fujisan_spirit.choice_1")
	ca.effect_type = ChoiceRes.EffectType.DRAW_UP; ca.value = 1; ca.cost_hp = 15
	var cb: Resource = ChoiceRes.new(); cb.label = TranslationServer.translate("event.japanese.fujisan_spirit.choice_2")
	cb.effect_type = ChoiceRes.EffectType.HEAL; cb.value = 25
	e.choices = [ca, cb]; return e

static func _amaterasu_return() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = TranslationServer.translate("event.japanese.amaterasu_return.name")
	e.description = TranslationServer.translate("event.japanese.amaterasu_return.desc")
	var ca: Resource = ChoiceRes.new(); ca.label = TranslationServer.translate("event.japanese.amaterasu_return.choice_1")
	ca.effect_type = ChoiceRes.EffectType.HEAL; ca.value = 45
	var cb: Resource = ChoiceRes.new(); cb.label = TranslationServer.translate("event.japanese.amaterasu_return.choice_2")
	cb.effect_type = ChoiceRes.EffectType.ADD_RELIC_GAMBLE
	e.choices = [ca, cb]; return e
