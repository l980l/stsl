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
	e.event_name = "오딘의 까마귀"; e.description = "후긴과 무닌이 어깨에 내려앉아 지혜를 속삭인다."
	var ca: Resource = ChoiceRes.new(); ca.label = "귀를 기울인다 (HP -12)"
	ca.effect_type = ChoiceRes.EffectType.DRAW_UP; ca.value = 1; ca.cost_hp = 12
	var cb: Resource = ChoiceRes.new(); cb.label = "쫓아낸다"
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _yggdrasil_fruit() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "유그드라실의 열매"; e.description = "세계수 가지에서 신성한 열매가 떨어졌다."
	var ca: Resource = ChoiceRes.new(); ca.label = "먹는다 (골드 -50)"
	ca.effect_type = ChoiceRes.EffectType.HEAL; ca.value = 40; ca.cost_gold = 50
	var cb: Resource = ChoiceRes.new(); cb.label = "지나친다"
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _ragnarok_prophecy() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "라그나로크의 예언"; e.description = "종말의 징조가 하늘에 새겨진다. 도박이지만 기회다."
	var ca: Resource = ChoiceRes.new(); ca.label = "받아들인다"
	ca.effect_type = ChoiceRes.EffectType.ADD_RELIC_GAMBLE
	var cb: Resource = ChoiceRes.new(); cb.label = "거부한다 (HP -15)"
	cb.effect_type = ChoiceRes.EffectType.NONE; cb.cost_hp = 15
	e.choices = [ca, cb]; return e

static func _valhalla_invitation() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "발할라 초대장"; e.description = "용감한 전사에게 발할라의 문이 열렸다."
	var ca: Resource = ChoiceRes.new(); ca.label = "합류한다 (영웅 획득)"
	ca.effect_type = ChoiceRes.EffectType.ADD_HERO
	var cb: Resource = ChoiceRes.new(); cb.label = "거절한다 (골드 +25)"
	cb.effect_type = ChoiceRes.EffectType.GOLD; cb.value = 25
	e.choices = [ca, cb]; return e

static func _mimirs_well() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "미미르의 샘"; e.description = "지혜의 샘 앞에 섰다. 오딘도 한쪽 눈을 바쳤다."
	var ca: Resource = ChoiceRes.new(); ca.label = "마신다 (카드 1장 제거)"
	ca.effect_type = ChoiceRes.EffectType.REMOVE_CARD; ca.value = 1; ca.cost_hp = 20
	var cb: Resource = ChoiceRes.new(); cb.label = "지나친다"
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _dragon_gold() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "드래곤의 금화"; e.description = "니드호그의 둥지에서 금화가 쏟아져 나온다."
	var ca: Resource = ChoiceRes.new(); ca.label = "집는다 (HP -10)"
	ca.effect_type = ChoiceRes.EffectType.GOLD; ca.value = 60; ca.cost_hp = 10
	var cb: Resource = ChoiceRes.new(); cb.label = "놔둔다"
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _rune_stone() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "룬 스톤"; e.description = "고대 룬 문자가 새겨진 돌이 빛난다."
	var ca: Resource = ChoiceRes.new(); ca.label = "해독한다 (골드 -120)"
	ca.effect_type = ChoiceRes.EffectType.ADD_RELIC; ca.cost_gold = 120
	var cb: Resource = ChoiceRes.new(); cb.label = "문양을 그린다 (골드 +20)"
	cb.effect_type = ChoiceRes.EffectType.GOLD; cb.value = 20
	e.choices = [ca, cb]; return e

static func _thor_hammer_mark() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "토르의 망치 자국"; e.description = "묠니르가 남긴 신성한 흔적이다. 배움의 기회."
	var ca: Resource = ChoiceRes.new(); ca.label = "새긴다 (골드 -40)"
	ca.effect_type = ChoiceRes.EffectType.DRAW_UP; ca.value = 1; ca.cost_gold = 40
	var cb: Resource = ChoiceRes.new(); cb.label = "지나친다"
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _frost_giant_corpse() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "얼음 거인의 시체"; e.description = "쓰러진 요툰의 유해에서 뭔가 빛난다."
	var ca: Resource = ChoiceRes.new(); ca.label = "뒤진다 (HP -25)"
	ca.effect_type = ChoiceRes.EffectType.ADD_RELIC_GAMBLE; ca.cost_hp = 25
	var cb: Resource = ChoiceRes.new(); cb.label = "무시한다"
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _freyja_tears() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "프레이야의 눈물"; e.description = "황금 눈물방울이 땅에 떨어져 있다. 강력한 여신의 슬픔."
	var ca: Resource = ChoiceRes.new(); ca.label = "집어든다 (HP +25)"
	ca.effect_type = ChoiceRes.EffectType.HEAL; ca.value = 25
	var cb: Resource = ChoiceRes.new(); cb.label = "놔둔다"
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e
