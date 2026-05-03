# resources/events/events_act2.gd
const EventRes  = preload("res://resources/event_resource.gd")
const ChoiceRes = preload("res://resources/event_choice_resource.gd")

static func build_pool() -> Array:
	return [
		_book_of_the_dead(), _anubis_judgment(), _scarab_beetle(),
		_pharaoh_tomb(), _nile_flood(), _thoth_wisdom(),
		_bastet_cats(), _oasis_merchant(), _mummy_curse(),
		_ra_sunboat(),
	]

static func _book_of_the_dead() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "event.act2.book_of_the_dead.name"; e.description = "event.act2.book_of_the_dead.desc"
	e.bgm_type = "dark"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.act2.book_of_the_dead.choice_1"
	ca.effect_type = ChoiceRes.EffectType.DRAW_UP; ca.value = 1; ca.cost_hp = 15
	var cb: Resource = ChoiceRes.new(); cb.label = "event.act2.book_of_the_dead.choice_2"
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _anubis_judgment() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "event.act2.anubis_judgment.name"; e.description = "event.act2.anubis_judgment.desc"
	e.bgm_type = "dark"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.act2.anubis_judgment.choice_1"
	ca.effect_type = ChoiceRes.EffectType.REMOVE_CARD; ca.value = 1
	var cb: Resource = ChoiceRes.new(); cb.label = "event.act2.anubis_judgment.choice_2"
	cb.effect_type = ChoiceRes.EffectType.NONE; cb.cost_hp = 10
	e.choices = [ca, cb]; return e

static func _scarab_beetle() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "event.act2.scarab_beetle.name"; e.description = "event.act2.scarab_beetle.desc"
	e.bgm_type = "fortune"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.act2.scarab_beetle.choice_1"
	ca.effect_type = ChoiceRes.EffectType.GOLD; ca.value = 40
	var cb: Resource = ChoiceRes.new(); cb.label = "event.act2.scarab_beetle.choice_2"
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _pharaoh_tomb() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "event.act2.pharaoh_tomb.name"; e.description = "event.act2.pharaoh_tomb.desc"
	e.bgm_type = "dark"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.act2.pharaoh_tomb.choice_1"
	ca.effect_type = ChoiceRes.EffectType.ADD_RELIC; ca.cost_hp = 35
	var cb: Resource = ChoiceRes.new(); cb.label = "event.act2.pharaoh_tomb.choice_2"
	cb.effect_type = ChoiceRes.EffectType.GOLD; cb.value = 15
	e.choices = [ca, cb]; return e

static func _nile_flood() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "event.act2.nile_flood.name"; e.description = "event.act2.nile_flood.desc"
	e.bgm_type = "encounter"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.act2.nile_flood.choice_1"
	ca.effect_type = ChoiceRes.EffectType.HEAL; ca.value = 30; ca.cost_gold = 40
	var cb: Resource = ChoiceRes.new(); cb.label = "event.act2.nile_flood.choice_2"
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _thoth_wisdom() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "event.act2.thoth_wisdom.name"; e.description = "event.act2.thoth_wisdom.desc"
	e.bgm_type = "mysterious"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.act2.thoth_wisdom.choice_1"
	ca.effect_type = ChoiceRes.EffectType.DRAW_UP; ca.value = 1; ca.cost_gold = 60
	var cb: Resource = ChoiceRes.new(); cb.label = "event.act2.thoth_wisdom.choice_2"
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _bastet_cats() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "event.act2.bastet_cats.name"; e.description = "event.act2.bastet_cats.desc"
	e.bgm_type = "encounter"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.act2.bastet_cats.choice_1"
	ca.effect_type = ChoiceRes.EffectType.HEAL; ca.value = 15; ca.cost_gold = 25
	var cb: Resource = ChoiceRes.new(); cb.label = "event.act2.bastet_cats.choice_2"
	cb.effect_type = ChoiceRes.EffectType.NONE; cb.cost_hp = 8
	e.choices = [ca, cb]; return e

static func _oasis_merchant() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "event.act2.oasis_merchant.name"; e.description = "event.act2.oasis_merchant.desc"
	e.bgm_type = "encounter"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.act2.oasis_merchant.choice_1"
	ca.effect_type = ChoiceRes.EffectType.ADD_RELIC; ca.cost_gold = 100
	var cb: Resource = ChoiceRes.new(); cb.label = "event.act2.oasis_merchant.choice_2"
	cb.effect_type = ChoiceRes.EffectType.HEAL; cb.value = 25; cb.cost_gold = 30
	var cc: Resource = ChoiceRes.new(); cc.label = "event.act2.oasis_merchant.choice_3"
	cc.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb, cc]; return e

static func _mummy_curse() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "event.act2.mummy_curse.name"; e.description = "event.act2.mummy_curse.desc"
	e.bgm_type = "dark"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.act2.mummy_curse.choice_1"
	ca.effect_type = ChoiceRes.EffectType.ADD_RELIC_GAMBLE
	var cb: Resource = ChoiceRes.new(); cb.label = "event.act2.mummy_curse.choice_2"
	cb.effect_type = ChoiceRes.EffectType.NONE; cb.cost_hp = 20
	e.choices = [ca, cb]; return e

static func _ra_sunboat() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "event.act2.ra_sunboat.name"; e.description = "event.act2.ra_sunboat.desc"
	e.bgm_type = "encounter"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.act2.ra_sunboat.choice_1"
	ca.effect_type = ChoiceRes.EffectType.ADD_HERO
	var cb: Resource = ChoiceRes.new(); cb.label = "event.act2.ra_sunboat.choice_2"
	cb.effect_type = ChoiceRes.EffectType.GOLD; cb.value = 20
	e.choices = [ca, cb]; return e
