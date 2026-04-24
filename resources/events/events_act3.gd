# resources/events/events_act3.gd
const EventRes  = preload("res://resources/event_resource.gd")
const ChoiceRes = preload("res://resources/event_choice_resource.gd")

static func build_pool() -> Array:
	return [
		_odin_ravens(), _yggdrasil_fruit(), _ragnarok_prophecy(),
		_valhalla_invitation(), _mimirs_well(), _dragon_gold(),
		_rune_stone(), _thor_hammer_mark(), _frost_giant_corpse(),
		_freyja_tears(),
	]

static func _odin_ravens() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "event.act3.odin_ravens.name"; e.description = "event.act3.odin_ravens.desc"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.act3.odin_ravens.choice_1"
	ca.effect_type = ChoiceRes.EffectType.DRAW_UP; ca.value = 1; ca.cost_hp = 12
	var cb: Resource = ChoiceRes.new(); cb.label = "event.act3.odin_ravens.choice_2"
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _yggdrasil_fruit() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "event.act3.yggdrasil_fruit.name"; e.description = "event.act3.yggdrasil_fruit.desc"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.act3.yggdrasil_fruit.choice_1"
	ca.effect_type = ChoiceRes.EffectType.HEAL; ca.value = 40; ca.cost_gold = 50
	var cb: Resource = ChoiceRes.new(); cb.label = "event.act3.yggdrasil_fruit.choice_2"
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _ragnarok_prophecy() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "event.act3.ragnarok_prophecy.name"; e.description = "event.act3.ragnarok_prophecy.desc"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.act3.ragnarok_prophecy.choice_1"
	ca.effect_type = ChoiceRes.EffectType.ADD_RELIC_GAMBLE
	var cb: Resource = ChoiceRes.new(); cb.label = "event.act3.ragnarok_prophecy.choice_2"
	cb.effect_type = ChoiceRes.EffectType.NONE; cb.cost_hp = 15
	e.choices = [ca, cb]; return e

static func _valhalla_invitation() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "event.act3.valhalla_invitation.name"; e.description = "event.act3.valhalla_invitation.desc"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.act3.valhalla_invitation.choice_1"
	ca.effect_type = ChoiceRes.EffectType.ADD_HERO
	var cb: Resource = ChoiceRes.new(); cb.label = "event.act3.valhalla_invitation.choice_2"
	cb.effect_type = ChoiceRes.EffectType.GOLD; cb.value = 25
	e.choices = [ca, cb]; return e

static func _mimirs_well() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "event.act3.mimirs_well.name"; e.description = "event.act3.mimirs_well.desc"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.act3.mimirs_well.choice_1"
	ca.effect_type = ChoiceRes.EffectType.REMOVE_CARD; ca.value = 1; ca.cost_hp = 20
	var cb: Resource = ChoiceRes.new(); cb.label = "event.act3.mimirs_well.choice_2"
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _dragon_gold() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "event.act3.dragon_gold.name"; e.description = "event.act3.dragon_gold.desc"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.act3.dragon_gold.choice_1"
	ca.effect_type = ChoiceRes.EffectType.GOLD; ca.value = 60; ca.cost_hp = 10
	var cb: Resource = ChoiceRes.new(); cb.label = "event.act3.dragon_gold.choice_2"
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _rune_stone() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "event.act3.rune_stone.name"; e.description = "event.act3.rune_stone.desc"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.act3.rune_stone.choice_1"
	ca.effect_type = ChoiceRes.EffectType.ADD_RELIC; ca.cost_gold = 120
	var cb: Resource = ChoiceRes.new(); cb.label = "event.act3.rune_stone.choice_2"
	cb.effect_type = ChoiceRes.EffectType.GOLD; cb.value = 20
	e.choices = [ca, cb]; return e

static func _thor_hammer_mark() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "event.act3.thor_hammer_mark.name"; e.description = "event.act3.thor_hammer_mark.desc"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.act3.thor_hammer_mark.choice_1"
	ca.effect_type = ChoiceRes.EffectType.DRAW_UP; ca.value = 1; ca.cost_gold = 40
	var cb: Resource = ChoiceRes.new(); cb.label = "event.act3.thor_hammer_mark.choice_2"
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _frost_giant_corpse() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "event.act3.frost_giant_corpse.name"; e.description = "event.act3.frost_giant_corpse.desc"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.act3.frost_giant_corpse.choice_1"
	ca.effect_type = ChoiceRes.EffectType.ADD_RELIC_GAMBLE; ca.cost_hp = 25
	var cb: Resource = ChoiceRes.new(); cb.label = "event.act3.frost_giant_corpse.choice_2"
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _freyja_tears() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "event.act3.freyja_tears.name"; e.description = "event.act3.freyja_tears.desc"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.act3.freyja_tears.choice_1"
	ca.effect_type = ChoiceRes.EffectType.HEAL; ca.value = 25
	var cb: Resource = ChoiceRes.new(); cb.label = "event.act3.freyja_tears.choice_2"
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e
