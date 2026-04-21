# resources/events/events_chinese.gd
# 중국 신화 이벤트 10종
const EventRes  = preload("res://resources/event_resource.gd")
const ChoiceRes = preload("res://resources/event_choice_resource.gd")

static func build_pool() -> Array:
	return [
		_queen_mother_peach(), _monkey_king_challenge(), _tang_monk_scripture(),
		_eight_immortals_feast(), _celestial_market(), _dragon_king_invitation(),
		_lu_dongbin_sword(), _jade_emperor_envoy(), _shennong_herbs(),
		_phoenix_rebirth(),
	]

static func _queen_mother_peach() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "서왕모의 복숭아나무"
	e.description = "곤륜산 깊숙이 3000년에 한 번 열린다는 불로불사의 복숭아가 달려 있다."
	var ca: Resource = ChoiceRes.new(); ca.label = "복숭아를 따 먹는다"
	ca.effect_type = ChoiceRes.EffectType.HEAL; ca.value = 40
	var cb: Resource = ChoiceRes.new(); cb.label = "그냥 지나친다"
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _monkey_king_challenge() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "손오공의 도전"
	e.description = "원숭이가 우쭐대며 말한다. '내 여의봉을 피하면 뭔가 주지. 피하지 못하면 대가를 치러야 해.'"
	var ca: Resource = ChoiceRes.new(); ca.label = "도전을 받아들인다 (도박)"
	ca.effect_type = ChoiceRes.EffectType.ADD_RELIC_GAMBLE
	var cb: Resource = ChoiceRes.new(); cb.label = "거절한다"
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _tang_monk_scripture() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "당삼장의 경전"
	e.description = "서역에서 돌아온 스님이 경전을 펼쳐 보인다. '이 경전을 읽으면 깨달음을 얻을 수 있소.'"
	var ca: Resource = ChoiceRes.new(); ca.label = "경전을 탐독한다"
	ca.effect_type = ChoiceRes.EffectType.DRAW_UP; ca.value = 1
	var cb: Resource = ChoiceRes.new(); cb.label = "감사히 거절한다"
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _eight_immortals_feast() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "팔선의 연회"
	e.description = "하늘에서 내려온 여덟 신선이 잔치를 열고 당신을 초대한다."
	var ca: Resource = ChoiceRes.new(); ca.label = "잔치에 참여한다 (골드 -40)"
	ca.effect_type = ChoiceRes.EffectType.HEAL; ca.value = 50; ca.cost_gold = 40
	var cb: Resource = ChoiceRes.new(); cb.label = "술을 가져간다"
	cb.effect_type = ChoiceRes.EffectType.GOLD; cb.value = 60
	var cc: Resource = ChoiceRes.new(); cc.label = "그냥 지나친다"
	cc.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb, cc]; return e

static func _celestial_market() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "천계 시장"
	e.description = "구름 위 하늘 시장에 도착했다. 선인들이 기이한 물건을 팔고 있다."
	var ca: Resource = ChoiceRes.new(); ca.label = "고가 유물을 구입한다 (골드 -80)"
	ca.effect_type = ChoiceRes.EffectType.ADD_RELIC; ca.cost_gold = 80
	var cb: Resource = ChoiceRes.new(); cb.label = "불량품을 집어든다 (도박, 골드 -30)"
	cb.effect_type = ChoiceRes.EffectType.ADD_RELIC_GAMBLE; cb.cost_gold = 30
	var cc: Resource = ChoiceRes.new(); cc.label = "그냥 구경만 한다"
	cc.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb, cc]; return e

static func _dragon_king_invitation() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "용왕의 용궁 초대"
	e.description = "바다 아래에서 용왕의 사자가 나타난다. '왕께서 보물창고를 열어주신다 하셨습니다.'"
	var ca: Resource = ChoiceRes.new(); ca.label = "초대에 응한다 (HP -25)"
	ca.effect_type = ChoiceRes.EffectType.GOLD; ca.value = 90; ca.cost_hp = 25
	var cb: Resource = ChoiceRes.new(); cb.label = "보물 하나만 요청한다 (HP -40)"
	cb.effect_type = ChoiceRes.EffectType.ADD_RELIC; cb.cost_hp = 40
	var cc: Resource = ChoiceRes.new(); cc.label = "정중히 거절한다"
	cc.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb, cc]; return e

static func _lu_dongbin_sword() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "여동빈의 검술 수련"
	e.description = "검을 든 노인이 말한다. '내 검술을 전수해드릴까요? 약한 기술은 버려야 해요.'"
	var ca: Resource = ChoiceRes.new(); ca.label = "수련을 받는다 (카드 1장 제거)"
	ca.effect_type = ChoiceRes.EffectType.REMOVE_CARD; ca.value = 1
	var cb: Resource = ChoiceRes.new(); cb.label = "감사히 거절한다"
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _jade_emperor_envoy() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "옥황상제의 사자"
	e.description = "황금 갑옷의 천사가 하늘에서 내려온다. '황제 폐하의 명으로 당신들을 돕겠습니다.'"
	var ca: Resource = ChoiceRes.new(); ca.label = "사자의 도움을 받는다"
	ca.effect_type = ChoiceRes.EffectType.ADD_HERO
	var cb: Resource = ChoiceRes.new(); cb.label = "일의 귀찮음을 피한다"
	cb.effect_type = ChoiceRes.EffectType.GOLD; cb.value = 50
	e.choices = [ca, cb]; return e

static func _shennong_herbs() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "신농의 약초"
	e.description = "황소 머리의 신인이 약초를 잔뜩 지고 있다. '이 약초를 드시오. 치료도 되고 독도 될 수 있소.'"
	var ca: Resource = ChoiceRes.new(); ca.label = "약초를 먹는다 (HP -15)"
	ca.effect_type = ChoiceRes.EffectType.HEAL; ca.value = 40; ca.cost_hp = 15
	var cb: Resource = ChoiceRes.new(); cb.label = "좋은 약초만 고른다 (골드 -40)"
	cb.effect_type = ChoiceRes.EffectType.HEAL; cb.value = 20; cb.cost_gold = 40
	var cc: Resource = ChoiceRes.new(); cc.label = "거절한다"
	cc.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb, cc]; return e

static func _phoenix_rebirth() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "봉황의 부활"
	e.description = "불꽃 속에서 아름다운 새가 솟아오른다. 깃털 하나가 당신 앞에 떨어진다."
	var ca: Resource = ChoiceRes.new(); ca.label = "깃털을 가져간다 (도박)"
	ca.effect_type = ChoiceRes.EffectType.ADD_RELIC_GAMBLE
	var cb: Resource = ChoiceRes.new(); cb.label = "깃털을 바람에 돌려보낸다"
	cb.effect_type = ChoiceRes.EffectType.HEAL; cb.value = 30
	e.choices = [ca, cb]; return e
