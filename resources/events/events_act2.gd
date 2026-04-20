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
	e.event_name = "사자의 서"; e.description = "죽은 자에게 주어지는 주문서가 놓여 있다. 지식이 담겨 있지만 읽는 것은 고통스럽다."
	var ca: Resource = ChoiceRes.new(); ca.label = "읽는다 (HP -15)"
	ca.effect_type = ChoiceRes.EffectType.DRAW_UP; ca.value = 1; ca.cost_hp = 15
	var cb: Resource = ChoiceRes.new(); cb.label = "무시"
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _anubis_judgment() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "아누비스의 심판"; e.description = "아누비스가 저울 위에 심장을 올려놓는다. 깨끗한 심장은 가볍다."
	var ca: Resource = ChoiceRes.new(); ca.label = "심장을 바친다 (카드 1장 제거)"
	ca.effect_type = ChoiceRes.EffectType.REMOVE_CARD; ca.value = 1
	var cb: Resource = ChoiceRes.new(); cb.label = "도망친다 (HP -10)"
	cb.effect_type = ChoiceRes.EffectType.NONE; cb.cost_hp = 10
	e.choices = [ca, cb]; return e

static func _scarab_beetle() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "스카라베 풍뎅이"; e.description = "황금빛 딱정벌레가 굴러가고 있다. 성스러운 것이라 하지만 가치가 있어 보인다."
	var ca: Resource = ChoiceRes.new(); ca.label = "잡는다 (골드 +40)"
	ca.effect_type = ChoiceRes.EffectType.GOLD; ca.value = 40
	var cb: Resource = ChoiceRes.new(); cb.label = "놓아준다"
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _pharaoh_tomb() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "파라오의 무덤"; e.description = "봉인된 석관이 놓여 있다. 위험한 저주가 걸려 있지만 그 안에는 보물이 있을 것이다."
	var ca: Resource = ChoiceRes.new(); ca.label = "연다 (HP -35)"
	ca.effect_type = ChoiceRes.EffectType.ADD_RELIC; ca.cost_hp = 35
	var cb: Resource = ChoiceRes.new(); cb.label = "봉인을 존중한다 (골드 +15)"
	cb.effect_type = ChoiceRes.EffectType.GOLD; cb.value = 15
	e.choices = [ca, cb]; return e

static func _nile_flood() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "나일강의 범람"; e.description = "나일강이 넘쳐흘러 주변을 적신다. 농경신의 축복이라 하지만 여정을 지연시킨다."
	var ca: Resource = ChoiceRes.new(); ca.label = "강물로 씻는다 (HP +30, 골드 -40)"
	ca.effect_type = ChoiceRes.EffectType.HEAL; ca.value = 30; ca.cost_gold = 40
	var cb: Resource = ChoiceRes.new(); cb.label = "지나친다"
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _thoth_wisdom() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "토트의 지혜"; e.description = "지식의 신 토트가 가르침을 제공한다. 배움은 대가를 요구한다."
	var ca: Resource = ChoiceRes.new(); ca.label = "가르침을 받는다 (골드 -60)"
	ca.effect_type = ChoiceRes.EffectType.DRAW_UP; ca.value = 1; ca.cost_gold = 60
	var cb: Resource = ChoiceRes.new(); cb.label = "거절한다"
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _bastet_cats() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "바스테트의 고양이"; e.description = "성스러운 고양이 무리가 길을 막고 있다. 바스테트의 가호를 받은 존재들이다."
	var ca: Resource = ChoiceRes.new(); ca.label = "먹이를 준다 (HP +15, 골드 -25)"
	ca.effect_type = ChoiceRes.EffectType.HEAL; ca.value = 15; ca.cost_gold = 25
	var cb: Resource = ChoiceRes.new(); cb.label = "쫓아낸다 (HP -8)"
	cb.effect_type = ChoiceRes.EffectType.NONE; cb.cost_hp = 8
	e.choices = [ca, cb]; return e

static func _oasis_merchant() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "오아시스 상인"; e.description = "사막 한가운데 오아시스에서 행상인을 만났다. 진귀한 물건을 팔고 있다."
	var ca: Resource = ChoiceRes.new(); ca.label = "렐릭 구매 (골드 -100)"
	ca.effect_type = ChoiceRes.EffectType.ADD_RELIC; ca.cost_gold = 100
	var cb: Resource = ChoiceRes.new(); cb.label = "약초 구매 (HP +25, 골드 -30)"
	cb.effect_type = ChoiceRes.EffectType.HEAL; cb.value = 25; cb.cost_gold = 30
	var cc: Resource = ChoiceRes.new(); cc.label = "지나간다"
	cc.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb, cc]; return e

static func _mummy_curse() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "미라의 저주"; e.description = "열린 석관에서 차가운 바람이 불어온다. 위험하지만 안에 무언가 있다."
	var ca: Resource = ChoiceRes.new(); ca.label = "용기를 낸다 (랜덤 렐릭)"
	ca.effect_type = ChoiceRes.EffectType.ADD_RELIC_GAMBLE
	var cb: Resource = ChoiceRes.new(); cb.label = "도망친다 (HP -20)"
	cb.effect_type = ChoiceRes.EffectType.NONE; cb.cost_hp = 20
	e.choices = [ca, cb]; return e

static func _ra_sunboat() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "라의 태양선"; e.description = "태양신 라의 황금 배가 눈앞에 나타난다. 동행을 제안하는 존재가 있다."
	var ca: Resource = ChoiceRes.new(); ca.label = "합류한다 (영웅 획득)"
	ca.effect_type = ChoiceRes.EffectType.ADD_HERO
	var cb: Resource = ChoiceRes.new(); cb.label = "거절한다 (골드 +20)"
	cb.effect_type = ChoiceRes.EffectType.GOLD; cb.value = 20
	e.choices = [ca, cb]; return e
