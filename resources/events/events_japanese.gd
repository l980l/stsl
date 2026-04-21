# resources/events/events_japanese.gd
# 일본 신화 이벤트 10종
const EventRes  = preload("res://resources/event_resource.gd")
const ChoiceRes = preload("res://resources/event_choice_resource.gd")

static func build_pool() -> Array:
	return [
		_ise_shrine_blessing(), _oni_shogi(), _yuki_onna_blizzard(),
		_tengu_training(), _shrine_omamori(), _tanuki_illusion(),
		_kappa_river_crossing(), _shuten_doji_feast(), _fujisan_spirit(),
		_amaterasu_return(),
	]

static func _ise_shrine_blessing() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "이세 신궁의 축복"
	e.description = "신성한 기운이 감도는 신궁에서 아마테라스의 사자가 나타난다. '경건한 마음으로 오셨군요.'"
	var ca: Resource = ChoiceRes.new(); ca.label = "신궁에 제물을 바친다 (골드 -30)"
	ca.effect_type = ChoiceRes.EffectType.HEAL; ca.value = 50; ca.cost_gold = 30
	var cb: Resource = ChoiceRes.new(); cb.label = "기도만 드린다"
	cb.effect_type = ChoiceRes.EffectType.HEAL; cb.value = 20
	e.choices = [ca, cb]; return e

static func _oni_shogi() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "오니의 장기"
	e.description = "거대한 오니가 장기판을 내밀며 말한다. '이기면 보물을 주지. 지면 대가를 치러야 해.'"
	var ca: Resource = ChoiceRes.new(); ca.label = "장기 대결을 받아들인다 (도박)"
	ca.effect_type = ChoiceRes.EffectType.ADD_RELIC_GAMBLE
	var cb: Resource = ChoiceRes.new(); cb.label = "정중히 거절한다"
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _yuki_onna_blizzard() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "유키온나의 눈보라"
	e.description = "하얀 여인이 손을 내밀며 속삭인다. '당신의 온기를 조금만 나눠주세요. 대신 보상을 드릴게요.'"
	var ca: Resource = ChoiceRes.new(); ca.label = "온기를 나눠준다 (HP -20)"
	ca.effect_type = ChoiceRes.EffectType.GOLD; ca.value = 80; ca.cost_hp = 20
	var cb: Resource = ChoiceRes.new(); cb.label = "유물을 건네준다 (HP -35)"
	cb.effect_type = ChoiceRes.EffectType.ADD_RELIC; cb.cost_hp = 35
	var cc: Resource = ChoiceRes.new(); cc.label = "거절하고 달아난다"
	cc.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb, cc]; return e

static func _tengu_training() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "텐구의 수련"
	e.description = "산중에서 만난 텐구가 말한다. '약한 기술을 버리고 진정한 힘을 얻으시오.'"
	var ca: Resource = ChoiceRes.new(); ca.label = "수련을 받는다 (카드 1장 제거)"
	ca.effect_type = ChoiceRes.EffectType.REMOVE_CARD; ca.value = 1
	var cb: Resource = ChoiceRes.new(); cb.label = "거절한다"
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _shrine_omamori() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "신사의 오마모리"
	e.description = "오래된 신사에서 신관이 부적을 꺼낸다. '이 오마모리가 당신을 지켜드릴 것입니다.'"
	var ca: Resource = ChoiceRes.new(); ca.label = "부적을 구입한다 (골드 -50)"
	ca.effect_type = ChoiceRes.EffectType.ADD_RELIC; ca.cost_gold = 50
	var cb: Resource = ChoiceRes.new(); cb.label = "오래된 부적을 집어든다 (도박, 골드 -20)"
	cb.effect_type = ChoiceRes.EffectType.ADD_RELIC_GAMBLE; cb.cost_gold = 20
	var cc: Resource = ChoiceRes.new(); cc.label = "그냥 지나친다"
	cc.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb, cc]; return e

static func _tanuki_illusion() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "너구리의 환술"
	e.description = "너구리가 상인으로 변장하여 나타난다. '특별한 물건이 있소. 단, 정체를 알면 안 되오.'"
	var ca: Resource = ChoiceRes.new(); ca.label = "물건을 구입한다 (도박, 골드 -40)"
	ca.effect_type = ChoiceRes.EffectType.ADD_RELIC_GAMBLE; ca.cost_gold = 40
	var cb: Resource = ChoiceRes.new(); cb.label = "정체를 폭로한다"
	cb.effect_type = ChoiceRes.EffectType.GOLD; cb.value = 50
	e.choices = [ca, cb]; return e

static func _kappa_river_crossing() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "갓파의 강 건너기"
	e.description = "강가에서 갓파가 외친다. '나와 씨름을 하면 강을 건너게 해주지. 지면 대가를 치러야 해.'"
	var ca: Resource = ChoiceRes.new(); ca.label = "씨름을 받아들인다 (도박)"
	ca.effect_type = ChoiceRes.EffectType.ADD_RELIC_GAMBLE
	var cb: Resource = ChoiceRes.new(); cb.label = "우회로를 찾는다"
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _shuten_doji_feast() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "슈텐도지의 주연"
	e.description = "요괴 두목이 술잔을 건네며 말한다. '함께 마시면 친구가 되어주지. 동료도 한 명 줄 수 있어.'"
	var ca: Resource = ChoiceRes.new(); ca.label = "함께 마신다 (HP -30)"
	ca.effect_type = ChoiceRes.EffectType.ADD_HERO; ca.cost_hp = 30
	var cb: Resource = ChoiceRes.new(); cb.label = "술만 챙긴다"
	cb.effect_type = ChoiceRes.EffectType.GOLD; cb.value = 70
	var cc: Resource = ChoiceRes.new(); cc.label = "거절한다"
	cc.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb, cc]; return e

static func _fujisan_spirit() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "후지산의 영기"
	e.description = "산꼭대기에서 신비로운 기운이 흘러내린다. 깊이 흡수하면 지식이 열릴 것 같다."
	var ca: Resource = ChoiceRes.new(); ca.label = "영기를 흡수한다 (HP -15)"
	ca.effect_type = ChoiceRes.EffectType.DRAW_UP; ca.value = 1; ca.cost_hp = 15
	var cb: Resource = ChoiceRes.new(); cb.label = "그냥 바라본다"
	cb.effect_type = ChoiceRes.EffectType.HEAL; cb.value = 25
	e.choices = [ca, cb]; return e

static func _amaterasu_return() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "아마테라스의 귀환"
	e.description = "동굴에서 태양신이 나오며 세상이 밝아진다. 눈부신 빛이 당신들을 감싼다."
	var ca: Resource = ChoiceRes.new(); ca.label = "빛을 받아들인다"
	ca.effect_type = ChoiceRes.EffectType.HEAL; ca.value = 45
	var cb: Resource = ChoiceRes.new(); cb.label = "빛을 담아간다 (도박)"
	cb.effect_type = ChoiceRes.EffectType.ADD_RELIC_GAMBLE
	e.choices = [ca, cb]; return e
