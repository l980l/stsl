# resources/data/cards_yi_sun_sin.gd
const CardRes = preload("res://resources/card_resource.gd")
const EffRes  = preload("res://resources/effect_resource.gd")

static func starter_deck() -> Array:
	var cards: Array = []
	for _i in range(2):
		cards.append(_shield())
	for _i in range(2):
		cards.append(_counterattack())
	return cards

static func pool() -> Array:
	return [
		_turtle_ship_charge(), _counter(), _iron_armor(),
		_crane_wing(), _last_stand(), _noryang_battle(),
		_formation_boost(), _naval_training(), _hansan_victory(),
		_indomitable(), _strict_training(), _turtle_shield(),
		_death_or_glory(), _naval_maneuver(),
	]

static func _shield() -> Resource:
	var c := CardRes.new()
	c.card_name = "방패"; c.owner_id = "yi_sun_sin"; c.cost = 1; c.play_animation = "idle"
	var e := EffRes.new(); e.effect_type = EffRes.EffectType.BLOCK; e.value = 7
	c.effects = [e]; return c

static func _counterattack() -> Resource:
	var c := CardRes.new()
	c.card_name = "역공"; c.owner_id = "yi_sun_sin"; c.cost = 1; c.play_animation = "attack"
	var ea := EffRes.new(); ea.effect_type = EffRes.EffectType.BLOCK; ea.value = 3
	var eb := EffRes.new(); eb.effect_type = EffRes.EffectType.DAMAGE; eb.value = 3; eb.target = "SINGLE"
	c.effects = [ea, eb]; return c

static func _turtle_ship_charge() -> Resource:
	var c := CardRes.new()
	c.card_name = "거북선 돌격"; c.owner_id = "yi_sun_sin"; c.cost = 2; c.play_animation = "attack"
	var ea := EffRes.new(); ea.effect_type = EffRes.EffectType.DAMAGE; ea.value = 6; ea.target = "SINGLE"
	var eb := EffRes.new(); eb.effect_type = EffRes.EffectType.COUNTER_BLOCK; eb.value = 60; eb.target = "SINGLE"
	c.effects = [ea, eb]; return c

static func _counter() -> Resource:
	var c := CardRes.new()
	c.card_name = "반격"; c.owner_id = "yi_sun_sin"; c.cost = 1; c.play_animation = "attack"
	var e := EffRes.new(); e.effect_type = EffRes.EffectType.COUNTER_BLOCK; e.value = 100; e.target = "SINGLE"
	c.effects = [e]; return c

static func _iron_armor() -> Resource:
	var c := CardRes.new()
	c.card_name = "철갑"; c.owner_id = "yi_sun_sin"; c.cost = 1; c.play_animation = "idle"
	var e := EffRes.new(); e.effect_type = EffRes.EffectType.BLOCK; e.value = 14
	c.effects = [e]; return c

static func _crane_wing() -> Resource:
	var c := CardRes.new()
	c.card_name = "학익진"; c.owner_id = "yi_sun_sin"; c.cost = 2; c.play_animation = "idle"
	var e := EffRes.new(); e.effect_type = EffRes.EffectType.BLOCK_ALL; e.value = 5
	c.effects = [e]; return c

static func _last_stand() -> Resource:
	var c := CardRes.new()
	c.card_name = "배수진"; c.owner_id = "yi_sun_sin"; c.cost = 1; c.play_animation = "idle"
	var ea := EffRes.new(); ea.effect_type = EffRes.EffectType.HEAL; ea.value = -8
	var eb := EffRes.new(); eb.effect_type = EffRes.EffectType.BLOCK; eb.value = 18
	c.effects = [ea, eb]; return c

static func _noryang_battle() -> Resource:
	var c := CardRes.new()
	c.card_name = "노량 해전"; c.owner_id = "yi_sun_sin"; c.cost = 2; c.play_animation = "attack"
	var e := EffRes.new(); e.effect_type = EffRes.EffectType.DAMAGE; e.value = 24; e.target = "SINGLE"
	c.effects = [e]; return c

static func _formation_boost() -> Resource:
	var c := CardRes.new()
	c.card_name = "진형 강화"; c.owner_id = "yi_sun_sin"; c.cost = 1; c.play_animation = "idle"
	var e := EffRes.new(); e.effect_type = EffRes.EffectType.FORMATION_BLOCK; e.value = 5
	c.effects = [e]; return c

static func _naval_training() -> Resource:
	var c := CardRes.new()
	c.card_name = "수군 훈련"; c.owner_id = "yi_sun_sin"; c.cost = 1; c.play_animation = "idle"
	var ea := EffRes.new(); ea.effect_type = EffRes.EffectType.BLOCK; ea.value = 5
	var eb := EffRes.new(); eb.effect_type = EffRes.EffectType.DRAW; eb.value = 1
	c.effects = [ea, eb]; return c

static func _hansan_victory() -> Resource:
	var c := CardRes.new()
	c.card_name = "한산대첩"; c.owner_id = "yi_sun_sin"; c.cost = 3; c.play_animation = "attack"
	var ea := EffRes.new(); ea.effect_type = EffRes.EffectType.DAMAGE; ea.value = 8; ea.target = "ALL"
	var eb := EffRes.new(); eb.effect_type = EffRes.EffectType.BLOCK_ALL; eb.value = 8
	c.effects = [ea, eb]; return c

static func _indomitable() -> Resource:
	var c := CardRes.new()
	c.card_name = "불굴"; c.owner_id = "yi_sun_sin"; c.cost = 2; c.play_animation = "idle"
	var e := EffRes.new(); e.effect_type = EffRes.EffectType.HEAL_ALL; e.value = 12
	c.effects = [e]; return c

static func _strict_training() -> Resource:
	var c := CardRes.new()
	c.card_name = "엄정한 훈련"; c.owner_id = "yi_sun_sin"; c.cost = 1; c.play_animation = "idle"
	var ea := EffRes.new(); ea.effect_type = EffRes.EffectType.DRAW; ea.value = 2
	var eb := EffRes.new(); eb.effect_type = EffRes.EffectType.BLOCK; eb.value = 4
	c.effects = [ea, eb]; return c

static func _turtle_shield() -> Resource:
	var c := CardRes.new()
	c.card_name = "거북선 방패"; c.owner_id = "yi_sun_sin"; c.cost = 1; c.play_animation = "idle"
	var e := EffRes.new(); e.effect_type = EffRes.EffectType.BLOCK; e.value = 8
	c.effects = [e]; return c

static func _death_or_glory() -> Resource:
	var c := CardRes.new()
	c.card_name = "필사즉생"; c.owner_id = "yi_sun_sin"; c.cost = 1; c.play_animation = "attack"
	var e := EffRes.new(); e.effect_type = EffRes.EffectType.DAMAGE; e.value = 10; e.target = "SINGLE"
	c.effects = [e]; return c

static func _naval_maneuver() -> Resource:
	var c := CardRes.new()
	c.card_name = "해군 기동"; c.owner_id = "yi_sun_sin"; c.cost = 0; c.play_animation = "idle"
	var e := EffRes.new(); e.effect_type = EffRes.EffectType.BLOCK; e.value = 3
	c.effects = [e]; return c
