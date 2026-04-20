# resources/data/events_act1.gd
const EventRes  = preload("res://resources/event_resource.gd")
const ChoiceRes = preload("res://resources/event_choice_resource.gd")

static func build_pool() -> Array:
	return [
		_golden_chest(), _wounded_warrior(), _ancient_library(),
		_cursed_altar(), _companion_encounter(), _prometheus_fire(),
		_heracles_trial(), _circe_magic(), _hades_contract(),
		_hermes_gamble(), _devils_deal(),
	]

static func _golden_chest() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "황금 상자"; e.description = "낡은 황금 상자가 놓여 있다."
	var ca: Resource = ChoiceRes.new(); ca.label = "열기"
	ca.effect_type = ChoiceRes.EffectType.GOLD; ca.value = 30
	var cb: Resource = ChoiceRes.new(); cb.label = "무시"
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _wounded_warrior() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "상처 입은 전사"; e.description = "부상당한 병사가 치료를 요청한다."
	var ca: Resource = ChoiceRes.new(); ca.label = "치료 (골드 -20)"
	ca.effect_type = ChoiceRes.EffectType.HEAL; ca.value = 15; ca.cost_gold = 20
	var cb: Resource = ChoiceRes.new(); cb.label = "무시"
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _ancient_library() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "고대 도서관"
	e.description = "신비로운 지식이 담긴 도서관. 공부하면 지식을 얻지만 기력을 소모한다."
	var ca: Resource = ChoiceRes.new(); ca.label = "공부 (HP -5)"
	ca.effect_type = ChoiceRes.EffectType.DRAW_UP; ca.value = 1; ca.cost_hp = 5
	var cb: Resource = ChoiceRes.new(); cb.label = "무시"
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _cursed_altar() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "저주받은 제단"; e.description = "제단에 무언가를 바치면 강력한 유물을 얻을 수 있다."
	var ca: Resource = ChoiceRes.new(); ca.label = "카드 바치기 (덱에서 1장 제거)"
	ca.effect_type = ChoiceRes.EffectType.REMOVE_CARD; ca.value = 1
	var cb: Resource = ChoiceRes.new(); cb.label = "무시"
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _companion_encounter() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "동료 만남"; e.description = "역사 속 영웅이 합류를 요청한다."
	var ca: Resource = ChoiceRes.new(); ca.label = "합류시키기"
	ca.effect_type = ChoiceRes.EffectType.ADD_HERO
	var cb: Resource = ChoiceRes.new(); cb.label = "거절"
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _prometheus_fire() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "프로메테우스의 불"
	e.description = "제우스에게 불을 훔친 티탄이 불씨를 건넨다. 받겠는가?"
	var ca: Resource = ChoiceRes.new(); ca.label = "불씨를 받는다 (드로우 +1, HP -20)"
	ca.effect_type = ChoiceRes.EffectType.DRAW_UP; ca.value = 1; ca.cost_hp = 20
	var cb: Resource = ChoiceRes.new(); cb.label = "거절한다"
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _heracles_trial() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "헤라클레스의 시련"; e.description = "헤라클레스가 힘겨루기를 제안한다. 이기면 황금을 준다."
	var ca: Resource = ChoiceRes.new(); ca.label = "맞선다 (골드 +60, HP -25)"
	ca.effect_type = ChoiceRes.EffectType.GOLD; ca.value = 60; ca.cost_hp = 25
	var cb: Resource = ChoiceRes.new(); cb.label = "포기한다"
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _circe_magic() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "키르케의 마법"; e.description = "마법사 키르케가 황금을 받고 체력을 회복시켜 주겠다고 한다."
	var ca: Resource = ChoiceRes.new(); ca.label = "마법을 받는다 (HP +25, 골드 -50)"
	ca.effect_type = ChoiceRes.EffectType.HEAL; ca.value = 25; ca.cost_gold = 50
	var cb: Resource = ChoiceRes.new(); cb.label = "거절한다"
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _hades_contract() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "하데스의 계약"
	e.description = "저승의 신 하데스가 강력한 유물을 제시한다. 대신 생명력을 요구한다."
	var ca: Resource = ChoiceRes.new(); ca.label = "계약한다 (렐릭 획득, HP -30)"
	ca.effect_type = ChoiceRes.EffectType.ADD_RELIC; ca.cost_hp = 30
	var cb: Resource = ChoiceRes.new(); cb.label = "거절한다"
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _hermes_gamble() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "헤르메스의 도박"; e.description = "교활한 헤르메스가 황금과 덱 경량화 중 하나를 선택하라 한다."
	var ca: Resource = ChoiceRes.new(); ca.label = "황금을 받는다 (골드 +50)"
	ca.effect_type = ChoiceRes.EffectType.GOLD; ca.value = 50
	var cb: Resource = ChoiceRes.new(); cb.label = "덱을 가볍게 한다 (카드 1장 제거)"
	cb.effect_type = ChoiceRes.EffectType.REMOVE_CARD; cb.value = 1
	e.choices = [ca, cb]; return e

static func _devils_deal() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "악마의 거래"
	e.description = "어둠 속 제단에서 목소리가 들린다.\n'내 힘을 원하느냐? 대가는 네가 치르게 될 것이다.'\n50% 확률로 강력한 렐릭 또는 저주 렐릭을 얻는다."
	var ca: Resource = ChoiceRes.new(); ca.label = "받아들인다"
	ca.effect_type = ChoiceRes.EffectType.ADD_RELIC_GAMBLE
	var cb: Resource = ChoiceRes.new(); cb.label = "거절한다"
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e
