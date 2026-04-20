# resources/data/cards_cleopatra.gd
const CardRes = preload("res://resources/card_resource.gd")
const EffRes  = preload("res://resources/effect_resource.gd")

static func starter_deck() -> Array:
	var cards: Array = []
	for _i in range(2):
		cards.append(_poison_sting())
	for _i in range(2):
		cards.append(_royal_defense())
	return cards

static func pool() -> Array:
	return [
		_nile_mist(), _desert_poison_dance(), _asp_fang(),
		_nile_fury(), _serpent_grasp(), _pharaoh_poison(),
		_isis_blessing(), _nile_blessing(), _temptation(),
		_cursed_gaze(), _pharaoh_decree(), _ramesses_shield(),
		_alexandria_edict(), _poison_seed(),
	]

static func _poison_sting() -> Resource:
	var c := CardRes.new()
	c.card_name = "독침"; c.owner_id = "cleopatra"; c.cost = 1; c.play_animation = "attack"
	var ea := EffRes.new(); ea.effect_type = EffRes.EffectType.DAMAGE; ea.value = 3; ea.target = "SINGLE"
	var eb := EffRes.new(); eb.effect_type = EffRes.EffectType.APPLY_STATUS; eb.status_type = "poison"; eb.value = 3; eb.target = "SINGLE"
	c.effects = [ea, eb]; return c

static func _royal_defense() -> Resource:
	var c := CardRes.new()
	c.card_name = "왕실 방어"; c.owner_id = "cleopatra"; c.cost = 1; c.play_animation = "idle"
	var e := EffRes.new(); e.effect_type = EffRes.EffectType.BLOCK; e.value = 6
	c.effects = [e]; return c

static func _nile_mist() -> Resource:
	var c := CardRes.new()
	c.card_name = "나일의 안개"; c.owner_id = "cleopatra"; c.cost = 2; c.play_animation = "attack"
	var e := EffRes.new(); e.effect_type = EffRes.EffectType.APPLY_STATUS; e.status_type = "poison"; e.value = 3; e.target = "ALL"
	c.effects = [e]; return c

static func _desert_poison_dance() -> Resource:
	var c := CardRes.new()
	c.card_name = "사막의 독무"; c.owner_id = "cleopatra"; c.cost = 1; c.play_animation = "attack"
	var ea := EffRes.new(); ea.effect_type = EffRes.EffectType.DAMAGE; ea.value = 2; ea.target = "ALL"
	var eb := EffRes.new(); eb.effect_type = EffRes.EffectType.APPLY_STATUS; eb.status_type = "poison"; eb.value = 2; eb.target = "ALL"
	c.effects = [ea, eb]; return c

static func _asp_fang() -> Resource:
	var c := CardRes.new()
	c.card_name = "아스프의 독니"; c.owner_id = "cleopatra"; c.cost = 1; c.play_animation = "attack"
	var e := EffRes.new(); e.effect_type = EffRes.EffectType.APPLY_STATUS; e.status_type = "poison"; e.value = 8; e.target = "SINGLE"
	c.effects = [e]; return c

static func _nile_fury() -> Resource:
	var c := CardRes.new()
	c.card_name = "나일의 분노"; c.owner_id = "cleopatra"; c.cost = 1; c.play_animation = "attack"
	var e := EffRes.new(); e.effect_type = EffRes.EffectType.POISON_BURST; e.target = "SINGLE"
	c.effects = [e]; return c

static func _serpent_grasp() -> Resource:
	var c := CardRes.new()
	c.card_name = "독사의 마수"; c.owner_id = "cleopatra"; c.cost = 1; c.play_animation = "attack"
	var e := EffRes.new(); e.effect_type = EffRes.EffectType.CONDITIONAL_DMG; e.value = 2; e.bonus_value = 8; e.status_type = "poison"; e.target = "SINGLE"
	c.effects = [e]; return c

static func _pharaoh_poison() -> Resource:
	var c := CardRes.new()
	c.card_name = "파라오의 독"; c.owner_id = "cleopatra"; c.cost = 2; c.play_animation = "attack"
	var ea := EffRes.new(); ea.effect_type = EffRes.EffectType.DAMAGE; ea.value = 4; ea.target = "SINGLE"
	var eb := EffRes.new(); eb.effect_type = EffRes.EffectType.APPLY_STATUS; eb.status_type = "poison"; eb.value = 5; eb.target = "SINGLE"
	var ec := EffRes.new(); ec.effect_type = EffRes.EffectType.APPLY_STATUS; ec.status_type = "vulnerable"; ec.value = 1; ec.target = "SINGLE"
	c.effects = [ea, eb, ec]; return c

static func _isis_blessing() -> Resource:
	var c := CardRes.new()
	c.card_name = "이시스의 가호"; c.owner_id = "cleopatra"; c.cost = 0; c.play_animation = "idle"
	var ea := EffRes.new(); ea.effect_type = EffRes.EffectType.DRAW; ea.value = 1
	var eb := EffRes.new(); eb.effect_type = EffRes.EffectType.ENERGY; eb.value = 1
	c.effects = [ea, eb]; return c

static func _nile_blessing() -> Resource:
	var c := CardRes.new()
	c.card_name = "나일의 축복"; c.owner_id = "cleopatra"; c.cost = 1; c.play_animation = "idle"
	var e := EffRes.new(); e.effect_type = EffRes.EffectType.HEAL; e.value = 6
	c.effects = [e]; return c

static func _temptation() -> Resource:
	var c := CardRes.new()
	c.card_name = "유혹"; c.owner_id = "cleopatra"; c.cost = 1; c.play_animation = "idle"
	var e := EffRes.new(); e.effect_type = EffRes.EffectType.APPLY_STATUS; e.status_type = "charm"; e.value = 1; e.target = "SINGLE"
	c.effects = [e]; return c

static func _cursed_gaze() -> Resource:
	var c := CardRes.new()
	c.card_name = "저주의 시선"; c.owner_id = "cleopatra"; c.cost = 1; c.play_animation = "idle"
	var ea := EffRes.new(); ea.effect_type = EffRes.EffectType.APPLY_STATUS; ea.status_type = "weak"; ea.value = 2; ea.target = "SINGLE"
	var eb := EffRes.new(); eb.effect_type = EffRes.EffectType.APPLY_STATUS; eb.status_type = "vulnerable"; eb.value = 2; eb.target = "SINGLE"
	c.effects = [ea, eb]; return c

static func _pharaoh_decree() -> Resource:
	var c := CardRes.new()
	c.card_name = "파라오의 명"; c.owner_id = "cleopatra"; c.cost = 1; c.play_animation = "idle"
	var ea := EffRes.new(); ea.effect_type = EffRes.EffectType.BLOCK; ea.value = 8
	var eb := EffRes.new(); eb.effect_type = EffRes.EffectType.DRAW; eb.value = 2
	c.effects = [ea, eb]; return c

static func _ramesses_shield() -> Resource:
	var c := CardRes.new()
	c.card_name = "람세스의 방패"; c.owner_id = "cleopatra"; c.cost = 1; c.play_animation = "idle"
	var e := EffRes.new(); e.effect_type = EffRes.EffectType.BLOCK; e.value = 10
	c.effects = [e]; return c

static func _alexandria_edict() -> Resource:
	var c := CardRes.new()
	c.card_name = "알렉산드리아 칙령"; c.owner_id = "cleopatra"; c.cost = 2; c.play_animation = "idle"
	var e := EffRes.new(); e.effect_type = EffRes.EffectType.DRAW; e.value = 2
	c.effects = [e]; return c

static func _poison_seed() -> Resource:
	var c := CardRes.new()
	c.card_name = "독의 씨앗"; c.owner_id = "cleopatra"; c.cost = 1; c.play_animation = "attack"
	var ea := EffRes.new(); ea.effect_type = EffRes.EffectType.DAMAGE; ea.value = 3; ea.target = "SINGLE"
	var eb := EffRes.new(); eb.effect_type = EffRes.EffectType.APPLY_STATUS; eb.status_type = "poison"; eb.value = 1; eb.target = "ALL"
	c.effects = [ea, eb]; return c
