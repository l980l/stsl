# resources/events/events_korean.gd
# 한국 신화 이벤트 10종
const EventRes  = preload("res://resources/event_resource.gd")
const ChoiceRes = preload("res://resources/event_choice_resource.gd")

static func build_pool() -> Array:
	return [
		_death_reaper_visit(), _dokkaebi_hammer(), _gumiho_temptation(),
		_shaman_gut(), _samsin_blessing(), _dangun_prophecy(),
		_mountain_god_bet(), _sea_king_test(), _hero_joins(),
		_underworld_deal(),
	]

static func _death_reaper_visit() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "event.korean.death_reaper_visit.name"
	e.description = "event.korean.death_reaper_visit.desc"
	e.bgm_type = "dark"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.korean.death_reaper_visit.choice_1"
	ca.effect_type = ChoiceRes.EffectType.GOLD; ca.value = 70; ca.cost_hp = 40
	var cb: Resource = ChoiceRes.new(); cb.label = "event.korean.death_reaper_visit.choice_2"
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _dokkaebi_hammer() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "event.korean.dokkaebi_hammer.name"
	e.description = "event.korean.dokkaebi_hammer.desc"
	e.bgm_type = "fortune"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.korean.dokkaebi_hammer.choice_1"
	ca.effect_type = ChoiceRes.EffectType.GOLD; ca.value = 80
	var cb: Resource = ChoiceRes.new(); cb.label = "event.korean.dokkaebi_hammer.choice_2"
	cb.effect_type = ChoiceRes.EffectType.HEAL; cb.value = 35
	var cc: Resource = ChoiceRes.new(); cc.label = "event.korean.dokkaebi_hammer.choice_3"
	cc.effect_type = ChoiceRes.EffectType.ADD_RELIC_GAMBLE
	e.choices = [ca, cb, cc]; return e

static func _gumiho_temptation() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "event.korean.gumiho_temptation.name"
	e.description = "event.korean.gumiho_temptation.desc"
	e.bgm_type = "dark"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.korean.gumiho_temptation.choice_1"
	ca.effect_type = ChoiceRes.EffectType.REMOVE_CARD; ca.value = 1
	var cb: Resource = ChoiceRes.new(); cb.label = "event.korean.gumiho_temptation.choice_2"
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _shaman_gut() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "event.korean.shaman_gut.name"
	e.description = "event.korean.shaman_gut.desc"
	e.bgm_type = "mysterious"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.korean.shaman_gut.choice_1"
	ca.effect_type = ChoiceRes.EffectType.HEAL; ca.value = 30; ca.cost_gold = 50
	var cb: Resource = ChoiceRes.new(); cb.label = "event.korean.shaman_gut.choice_2"
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _samsin_blessing() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "event.korean.samsin_blessing.name"
	e.description = "event.korean.samsin_blessing.desc"
	e.bgm_type = "encounter"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.korean.samsin_blessing.choice_1"
	ca.effect_type = ChoiceRes.EffectType.HEAL; ca.value = 30
	var cb: Resource = ChoiceRes.new(); cb.label = "event.korean.samsin_blessing.choice_2"
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _dangun_prophecy() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "event.korean.dangun_prophecy.name"
	e.description = "event.korean.dangun_prophecy.desc"
	e.bgm_type = "mysterious"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.korean.dangun_prophecy.choice_1"
	ca.effect_type = ChoiceRes.EffectType.ADD_RELIC
	var cb: Resource = ChoiceRes.new(); cb.label = "event.korean.dangun_prophecy.choice_2"
	cb.effect_type = ChoiceRes.EffectType.DRAW_UP; cb.value = 1
	e.choices = [ca, cb]; return e

static func _mountain_god_bet() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "event.korean.mountain_god_bet.name"
	e.description = "event.korean.mountain_god_bet.desc"
	e.bgm_type = "fortune"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.korean.mountain_god_bet.choice_1"
	ca.effect_type = ChoiceRes.EffectType.ADD_RELIC_GAMBLE
	var cb: Resource = ChoiceRes.new(); cb.label = "event.korean.mountain_god_bet.choice_2"
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _sea_king_test() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "event.korean.sea_king_test.name"
	e.description = "event.korean.sea_king_test.desc"
	e.bgm_type = "encounter"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.korean.sea_king_test.choice_1"
	ca.effect_type = ChoiceRes.EffectType.GOLD; ca.value = 100; ca.cost_hp = 30
	var cb: Resource = ChoiceRes.new(); cb.label = "event.korean.sea_king_test.choice_2"
	cb.effect_type = ChoiceRes.EffectType.HEAL; cb.value = 20; cb.cost_gold = 60
	var cc: Resource = ChoiceRes.new(); cc.label = "event.korean.sea_king_test.choice_3"
	cc.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb, cc]; return e

static func _hero_joins() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "event.korean.hero_joins.name"
	e.description = "event.korean.hero_joins.desc"
	e.bgm_type = "encounter"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.korean.hero_joins.choice_1"
	ca.effect_type = ChoiceRes.EffectType.ADD_HERO
	var cb: Resource = ChoiceRes.new(); cb.label = "event.korean.hero_joins.choice_2"
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _underworld_deal() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "event.korean.underworld_deal.name"
	e.description = "event.korean.underworld_deal.desc"
	e.bgm_type = "dark"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.korean.underworld_deal.choice_1"
	ca.effect_type = ChoiceRes.EffectType.ADD_RELIC_GAMBLE
	var cb: Resource = ChoiceRes.new(); cb.label = "event.korean.underworld_deal.choice_2"
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e
