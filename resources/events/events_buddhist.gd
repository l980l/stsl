# resources/events/events_buddhist.gd
# 불교 이벤트 10종
const EventRes  = preload("res://resources/event_resource.gd")
const ChoiceRes = preload("res://resources/event_choice_resource.gd")

static func build_pool() -> Array:
	return [
		_yama_toll(), _dharma_wheel(), _mara_illusion(),
		_monk_blessing(), _guanyin_mercy(), _buddha_prophecy(),
		_temple_trial(), _naga_king_test(), _arhat_joins(),
		_nirvana_gate(),
	]

static func _yama_toll() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "event.buddhist.yama_toll.name"
	e.description = "event.buddhist.yama_toll.desc"
	e.bgm_type = "dark"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.buddhist.yama_toll.choice_1"
	ca.effect_type = ChoiceRes.EffectType.GOLD; ca.value = 70; ca.cost_hp = 40
	var cb: Resource = ChoiceRes.new(); cb.label = "event.buddhist.yama_toll.choice_2"
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _dharma_wheel() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "event.buddhist.dharma_wheel.name"
	e.description = "event.buddhist.dharma_wheel.desc"
	e.bgm_type = "fortune"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.buddhist.dharma_wheel.choice_1"
	ca.effect_type = ChoiceRes.EffectType.GOLD; ca.value = 80
	var cb: Resource = ChoiceRes.new(); cb.label = "event.buddhist.dharma_wheel.choice_2"
	cb.effect_type = ChoiceRes.EffectType.HEAL; cb.value = 35
	var cc: Resource = ChoiceRes.new(); cc.label = "event.buddhist.dharma_wheel.choice_3"
	cc.effect_type = ChoiceRes.EffectType.ADD_RELIC_GAMBLE
	e.choices = [ca, cb, cc]; return e

static func _mara_illusion() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "event.buddhist.mara_illusion.name"
	e.description = "event.buddhist.mara_illusion.desc"
	e.bgm_type = "dark"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.buddhist.mara_illusion.choice_1"
	ca.effect_type = ChoiceRes.EffectType.REMOVE_CARD; ca.value = 1
	var cb: Resource = ChoiceRes.new(); cb.label = "event.buddhist.mara_illusion.choice_2"
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _monk_blessing() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "event.buddhist.monk_blessing.name"
	e.description = "event.buddhist.monk_blessing.desc"
	e.bgm_type = "mysterious"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.buddhist.monk_blessing.choice_1"
	ca.effect_type = ChoiceRes.EffectType.HEAL; ca.value = 30; ca.cost_gold = 50
	var cb: Resource = ChoiceRes.new(); cb.label = "event.buddhist.monk_blessing.choice_2"
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _guanyin_mercy() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "event.buddhist.guanyin_mercy.name"
	e.description = "event.buddhist.guanyin_mercy.desc"
	e.bgm_type = "encounter"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.buddhist.guanyin_mercy.choice_1"
	ca.effect_type = ChoiceRes.EffectType.HEAL; ca.value = 30
	var cb: Resource = ChoiceRes.new(); cb.label = "event.buddhist.guanyin_mercy.choice_2"
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _buddha_prophecy() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "event.buddhist.buddha_prophecy.name"
	e.description = "event.buddhist.buddha_prophecy.desc"
	e.bgm_type = "mysterious"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.buddhist.buddha_prophecy.choice_1"
	ca.effect_type = ChoiceRes.EffectType.ADD_RELIC
	var cb: Resource = ChoiceRes.new(); cb.label = "event.buddhist.buddha_prophecy.choice_2"
	cb.effect_type = ChoiceRes.EffectType.DRAW_UP; cb.value = 1
	e.choices = [ca, cb]; return e

static func _temple_trial() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "event.buddhist.temple_trial.name"
	e.description = "event.buddhist.temple_trial.desc"
	e.bgm_type = "fortune"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.buddhist.temple_trial.choice_1"
	ca.effect_type = ChoiceRes.EffectType.ADD_RELIC_GAMBLE
	var cb: Resource = ChoiceRes.new(); cb.label = "event.buddhist.temple_trial.choice_2"
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _naga_king_test() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "event.buddhist.naga_king_test.name"
	e.description = "event.buddhist.naga_king_test.desc"
	e.bgm_type = "encounter"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.buddhist.naga_king_test.choice_1"
	ca.effect_type = ChoiceRes.EffectType.GOLD; ca.value = 100; ca.cost_hp = 30
	var cb: Resource = ChoiceRes.new(); cb.label = "event.buddhist.naga_king_test.choice_2"
	cb.effect_type = ChoiceRes.EffectType.HEAL; cb.value = 20; cb.cost_gold = 60
	var cc: Resource = ChoiceRes.new(); cc.label = "event.buddhist.naga_king_test.choice_3"
	cc.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb, cc]; return e

static func _arhat_joins() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "event.buddhist.arhat_joins.name"
	e.description = "event.buddhist.arhat_joins.desc"
	e.bgm_type = "encounter"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.buddhist.arhat_joins.choice_1"
	ca.effect_type = ChoiceRes.EffectType.ADD_HERO
	var cb: Resource = ChoiceRes.new(); cb.label = "event.buddhist.arhat_joins.choice_2"
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _nirvana_gate() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "event.buddhist.nirvana_gate.name"
	e.description = "event.buddhist.nirvana_gate.desc"
	e.bgm_type = "dark"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.buddhist.nirvana_gate.choice_1"
	ca.effect_type = ChoiceRes.EffectType.ADD_RELIC_GAMBLE
	var cb: Resource = ChoiceRes.new(); cb.label = "event.buddhist.nirvana_gate.choice_2"
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e
