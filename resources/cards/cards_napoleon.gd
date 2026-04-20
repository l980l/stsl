# resources/data/cards_napoleon.gd
const CardRes = preload("res://resources/card_resource.gd")
const EffRes  = preload("res://resources/effect_resource.gd")

static func starter_deck() -> Array:
	var cards: Array = []
	for _i in range(3):
		cards.append(_strike())
	for _i in range(2):
		cards.append(_defend())
	return cards

static func pool() -> Array:
	return [
		_austerlitz(), _artillery_volley(), _arcole_breakthrough(),
		_grand_armee_shield(), _jena_surprise(), _hussar_charge(),
		_emperors_command(), _emperors_spirit(), _marshal_appointment(),
		_borodino_bombardment(), _salvo(), _total_assault_order(),
		_line_reform(), _swift_advance(),
	]

static func _strike() -> Resource:
	var c := CardRes.new()
	c.card_name = "스트라이크"; c.owner_id = "napoleon"; c.cost = 1; c.play_animation = "attack"
	var e := EffRes.new(); e.effect_type = EffRes.EffectType.DAMAGE; e.value = 6; e.target = "SINGLE"
	c.effects = [e]; return c

static func _defend() -> Resource:
	var c := CardRes.new()
	c.card_name = "디펜드"; c.owner_id = "napoleon"; c.cost = 1; c.play_animation = "idle"
	var e := EffRes.new(); e.effect_type = EffRes.EffectType.BLOCK; e.value = 5
	c.effects = [e]; return c

static func _austerlitz() -> Resource:
	var c := CardRes.new()
	c.card_name = "아우스터리츠"; c.owner_id = "napoleon"; c.cost = 2; c.play_animation = "attack"
	var e := EffRes.new(); e.effect_type = EffRes.EffectType.DAMAGE; e.value = 9; e.target = "SINGLE"
	c.effects = [e]; return c

static func _artillery_volley() -> Resource:
	var c := CardRes.new()
	c.card_name = "포병 일제사격"; c.owner_id = "napoleon"; c.cost = 1; c.play_animation = "attack"
	var e := EffRes.new(); e.effect_type = EffRes.EffectType.DAMAGE; e.value = 4; e.target = "ALL"
	c.effects = [e]; return c

static func _arcole_breakthrough() -> Resource:
	var c := CardRes.new()
	c.card_name = "아르콜레 돌파"; c.owner_id = "napoleon"; c.cost = 1; c.play_animation = "attack"
	var ea := EffRes.new(); ea.effect_type = EffRes.EffectType.DAMAGE; ea.value = 5; ea.target = "SINGLE"
	var eb := EffRes.new(); eb.effect_type = EffRes.EffectType.BLOCK; eb.value = 5
	c.effects = [ea, eb]; return c

static func _grand_armee_shield() -> Resource:
	var c := CardRes.new()
	c.card_name = "그랑다르메의 방패"; c.owner_id = "napoleon"; c.cost = 1; c.play_animation = "idle"
	var e := EffRes.new(); e.effect_type = EffRes.EffectType.BLOCK; e.value = 8
	c.effects = [e]; return c

static func _jena_surprise() -> Resource:
	var c := CardRes.new()
	c.card_name = "예나의 기습"; c.owner_id = "napoleon"; c.cost = 1; c.play_animation = "attack"
	var ea := EffRes.new(); ea.effect_type = EffRes.EffectType.DAMAGE; ea.value = 3; ea.target = "SINGLE"
	var eb := EffRes.new(); eb.effect_type = EffRes.EffectType.APPLY_STATUS; eb.status_type = "poison"; eb.value = 2; eb.target = "SINGLE"
	c.effects = [ea, eb]; return c

static func _hussar_charge() -> Resource:
	var c := CardRes.new()
	c.card_name = "경기병 돌격"; c.owner_id = "napoleon"; c.cost = 1; c.play_animation = "attack"
	var ea := EffRes.new(); ea.effect_type = EffRes.EffectType.DAMAGE; ea.value = 8; ea.target = "SINGLE"
	var eb := EffRes.new(); eb.effect_type = EffRes.EffectType.GAIN_MORALE; eb.value = 1
	c.effects = [ea, eb]; return c

static func _emperors_command() -> Resource:
	var c := CardRes.new()
	c.card_name = "황제의 명령"; c.owner_id = "napoleon"; c.cost = 2; c.play_animation = "attack"
	var ea := EffRes.new(); ea.effect_type = EffRes.EffectType.DAMAGE; ea.value = 5; ea.target = "ALL"
	var eb := EffRes.new(); eb.effect_type = EffRes.EffectType.GAIN_MORALE; eb.value = 2
	c.effects = [ea, eb]; return c

static func _emperors_spirit() -> Resource:
	var c := CardRes.new()
	c.card_name = "황제의 기개"; c.owner_id = "napoleon"; c.cost = 0; c.play_animation = "attack"
	var e := EffRes.new(); e.effect_type = EffRes.EffectType.CONSUME_MORALE; e.value = 3; e.bonus_value = 20; e.target = "SINGLE"
	c.effects = [e]; return c

static func _marshal_appointment() -> Resource:
	var c := CardRes.new()
	c.card_name = "원수 서임"; c.owner_id = "napoleon"; c.cost = 1; c.play_animation = "idle"
	var ea := EffRes.new(); ea.effect_type = EffRes.EffectType.DRAW; ea.value = 2
	var eb := EffRes.new(); eb.effect_type = EffRes.EffectType.GAIN_MORALE; eb.value = 1
	c.effects = [ea, eb]; return c

static func _borodino_bombardment() -> Resource:
	var c := CardRes.new()
	c.card_name = "보로디노 포격"; c.owner_id = "napoleon"; c.cost = 2; c.play_animation = "attack"
	var e := EffRes.new(); e.effect_type = EffRes.EffectType.CONDITIONAL_DMG; e.value = 14; e.bonus_value = 20; e.status_type = "morale"; e.target = "SINGLE"
	c.effects = [e]; return c

static func _salvo() -> Resource:
	var c := CardRes.new()
	c.card_name = "살보 사격"; c.owner_id = "napoleon"; c.cost = 1; c.play_animation = "attack"
	var ea := EffRes.new(); ea.effect_type = EffRes.EffectType.DAMAGE; ea.value = 4; ea.target = "SINGLE"
	var eb := EffRes.new(); eb.effect_type = EffRes.EffectType.ENERGY; eb.value = 1
	c.effects = [ea, eb]; return c

static func _total_assault_order() -> Resource:
	var c := CardRes.new()
	c.card_name = "총공세 명령"; c.owner_id = "napoleon"; c.cost = 1; c.play_animation = "idle"
	var ea := EffRes.new(); ea.effect_type = EffRes.EffectType.GAIN_MORALE; ea.value = 2
	var eb := EffRes.new(); eb.effect_type = EffRes.EffectType.DRAW; eb.value = 1
	c.effects = [ea, eb]; return c

static func _line_reform() -> Resource:
	var c := CardRes.new()
	c.card_name = "전열 재편"; c.owner_id = "napoleon"; c.cost = 0; c.play_animation = "idle"
	var e := EffRes.new(); e.effect_type = EffRes.EffectType.DRAW; e.value = 1
	c.effects = [e]; return c

static func _swift_advance() -> Resource:
	var c := CardRes.new()
	c.card_name = "신속 기동"; c.owner_id = "napoleon"; c.cost = 1; c.play_animation = "attack"
	var e := EffRes.new(); e.effect_type = EffRes.EffectType.DAMAGE; e.value = 3; e.target = "SINGLE"
	c.effects = [e]; return c
